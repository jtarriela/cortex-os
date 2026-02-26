# ADR-0033: Cortex Markdown Frontmatter Parity + RAG Metadata Visibility

**Status:** ACCEPTED
**Date:** 2026-02-25
**Accepted:** 2026-02-25
**Deciders:** Architecture review
**FR:** FR-020, FR-023, FR-028
**Related:** ADR-0006 (schema strategy), ADR-0015 (vault onboarding + save-commit indexing), ADR-0019 (linked Obsidian vault), ADR-0022 (linked writeback)

---

## Context

Cortex stores structured page metadata in the local encrypted DB (`pages.props`) but many Cortex-managed markdown files are currently written as body-only markdown. This creates a local-first integrity gap:

- users cannot inspect important metadata (times, places, statuses, links) by opening the `.md` file
- markdown files are less portable/self-describing than intended by the architecture
- RAG/search chunking can miss metadata that only exists in DB props unless the body duplicates it

At the same time, query-time search/RAG performance depends on DB indexes and should remain filesystem-independent.

Linked Obsidian notes are a separate case: Cortex must preserve raw markdown round-trip semantics and conflict handling for linked source files.

---

## Decision

### 1) Canonical frontmatter for Cortex-managed markdown writes

Cortex will write **YAML frontmatter + markdown body** for Cortex-managed pages (create/update/save/projection flows), including user-visible metadata stored in DB props.

Required top-level frontmatter fields:

- `id` (Cortex `page_id`)
- `kind`
- `title`
- `created_at`
- `updated_at`
- selected/additive page props (user-visible metadata)

Cortex may also write a namespaced internal metadata block (for example `cortex:`) for operational markers, serializer versioning, or provenance flags, provided these do not create hash-churn loops.

### 2) Dual-write runtime model remains (DB-index query-time)

Cortex continues to use the DB (`pages`, `search_chunks`, vector index) as the query-time source for search/RAG and collection queries.

- **Markdown files**: portable, human-readable source artifact for local ownership and interoperability
- **DB index**: fast derived index for retrieval/query latency

This ADR does **not** require a full markdown-first runtime refactor.

### 3) Explicit backfill/repair for existing files

Existing Cortex-managed markdown files that lack frontmatter must be repairable via an **explicit audit/repair action** (preview first, then apply). Cortex should not silently rewrite large vaults on vault select/open.

### 4) Linked Obsidian files are excluded from canonical rewrite

For linked Obsidian notes (`source = linked_obsidian`), Cortex preserves raw markdown round-trip and conflict semantics. No canonical frontmatter rewrite is performed on linked source files.

### 5) RAG chunking must include selected structured metadata

Search/RAG chunk generation will incorporate a filtered projection of structured metadata (from DB props) into indexed chunk content so metadata-only facts (e.g., dates/locations/status) are retrievable even if absent from body text.

---

## Consequences

### Positive

- restores local-first transparency for Cortex-owned markdown
- improves markdown portability and user trust
- improves RAG/search recall for metadata-backed facts
- preserves fast DB-based retrieval latency
- avoids breaking linked Obsidian writeback semantics

### Risks

- more frequent markdown rewrites on prop-only updates
- potential conflicts when repairing files that users manually edited
- metadata noise in RAG chunks if projection is too broad

### Mitigations

- explicit audit/repair flow with conflict detection + skip-by-default
- filtered metadata projection/denylist in chunking
- stable serializer ordering/versioning for deterministic outputs

---

## Implementation Notes (Policy-Level)

- Backend should centralize canonical markdown serialization to avoid path-by-path drift.
- Commands that mutate metadata without body edits (calendar reschedule, habit sync, travel calendar projection, etc.) must still rewrite markdown.
- Contracts must document any new audit/repair IPCs if exposed via Tauri commands.
- Traceability/docs should record the dual-write guarantee and DB-backed query-time RAG behavior.

