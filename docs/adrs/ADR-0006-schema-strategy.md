# ADR-0006: Schema Strategy — EAV/Page Model as Canonical Production Schema

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** All (cross-cutting)
**Supersedes:** `backend/docs/backend_architecture/001_SCHEMA.md` (flat domain tables)
**Related:** AD-02, AD-03, `001_architecture.md` Section 2.3, `002_COLLECTIONS.md`, `003_TASKS_AND_PLANNING.md`

---

## Context

Two mutually exclusive database schemas exist in the project documentation:

### Schema A — EAV/Page Model (`docs/technical_architecture/001_architecture.md` Section 2.3)

Tables: `pages`, `page_props` (EAV), `page_tags`, `graph_edges`, `pages_fts`, `vec_chunks`, `chunks`, `revisions`, `collections`, `views`, `app_config`.

Design principle: "Everything is a Page." A task, a trip, and a journal entry are all `.md` files differentiated by `kind` in frontmatter. Properties are typed key/value pairs stored in an Entity-Attribute-Value table. A single `collection_query()` engine queries across all entity types using selectors and filters over the EAV index.

### Schema B — Flat Domain Tables (`backend/docs/backend_architecture/001_SCHEMA.md`)

Tables: `tasks`, `task_comments`, `projects`, `milestones`, `artifacts`, `project_columns`, `project_templates`, `notes`, `file_nodes`, `journal_entries`, `habits`, `habit_completions`, `goals`, `meals`, `recipes`, `workouts`, `travel`, `accounts`, `budgets`, `transactions`, `calendar_events`, `schedule_items`, `app_config`, `search_fts`.

Design principle: Mirror the frontend `types.ts` domain interfaces 1:1. Each domain has its own table with bespoke columns. The backend schema doc states: "These schemas are derived from the frontend `types.ts` definitions."

### The Conflict

These schemas are mutually exclusive. Schema A has no `tasks` table — tasks are rows in `pages` with `kind = 'task'` and properties in `page_props`. Schema B has no `pages` table — each domain has dedicated columns. Both cannot be the production schema.

## Decision

**The EAV/Page model (Schema A) is the canonical production schema.** Schema B is reclassified as a Phase 0 design artifact that documented the frontend's data model in SQL form. It will not be implemented.

## Rationale

1. **Thesis alignment:** The core invariant "Everything is a Page" (AD-02) requires a unified entity model. Domain-specific tables directly contradict this by creating N separate entity hierarchies.

2. **Collection engine dependency:** The `collection_query()` engine — the universal abstraction for all views — is designed to operate against `pages` + `page_props` with selector rules. Domain-specific tables would require N separate query implementations, one per domain.

3. **Schema evolution:** Adding a new domain (e.g., Reading, Recipes, Bookmarks) with EAV requires zero schema changes — just new `kind` values and collection definitions in `.cortex/collections/`. With flat tables, every new domain requires a new migration.

4. **Vault round-trip:** The EAV model maps directly to YAML frontmatter key/value pairs, enabling lossless `vault → index → vault` round-tripping. Flat tables encode domain assumptions (e.g., `tasks.project_id` as a foreign key) that don't exist in the Markdown representation.

5. **Hybrid safety:** The `frontmatter_json` column in `pages` preserves the full raw frontmatter as a JSON blob, so unknown/custom properties survive indexing without schema changes. This is lost with flat tables.

## Consequences

- **Backend `001_SCHEMA.md` is SUPERSEDED.** A deprecation header must be added pointing to this ADR and to `001_architecture.md` Section 2.3 as the canonical schema.
- **No domain-specific tables will be created.** Tasks, projects, journal entries, habits, goals, meals, workouts, travel, and finance are all `pages` rows with different `kind` values.
- **Frontend type normalization is the backend's responsibility.** The frontend sends domain-specific structures (e.g., `Task` with `dueDate`, `projectRef`). The backend normalizes these to `Page` + properties on write and denormalizes back to domain DTOs on read.
- **Sub-tables require Page model adaptation.** Schema B concepts like `task_comments`, `milestones`, `artifacts`, `project_columns`, `habit_completions`, and `recipes` need representation in the Page model. Options:
  - **Child pages:** A comment is a page with `kind: comment` and a `parent: <task_page_id>` relation. This is the recommended approach for comments, milestones, and recipes.
  - **Embedded data:** Small, non-standalone data (like `habit_completions` which are just date stamps) can be stored as a JSON array in a property or as entries in a dedicated lightweight table outside the Page model.
  - **Dedicated tables (exception):** `project_templates` are app configuration, not user content. They belong in `app_config` or a templates table, not in the Page model.
- **The `schedule_items` table is eliminated.** See ADR-0007 for the convergence of ScheduleItem and CalendarEvent under the Page model.

## Migration Path

1. **Phase 1:** Implement the EAV schema from `001_architecture.md` Section 2.3. No flat domain tables.
2. **Phase 1:** Build the normalization layer in `cortex_index` that maps YAML frontmatter to EAV rows.
3. **Phase 1:** Build the denormalization layer in `cortex_search` that projects EAV rows back into `CardDTO` (domain-specific property subsets per view configuration).
4. **Phase 1:** The IPC layer translates between frontend domain types and the Page model — the frontend never sees `page_props` directly.

## Enforcement

When `cortex_storage` is implemented, any PR that introduces a domain-specific SQL table (e.g., `CREATE TABLE tasks`) must be rejected with a reference to this ADR. The only permitted table additions are those in the EAV schema or justified system tables (e.g., `app_config`, `project_templates`).
