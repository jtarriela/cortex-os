# ADR-0020: Block-Based Editor for Projects & Tasks (TipTap Custom Extensions)

**Status:** APPROVED
**Date:** 2026-02-21
**Deciders:** Architecture review
**FR:** FR-002 (Project Management), FR-001 (Tasks), FR-003 (Notes/Wikilinks)
**Related:** ADR-0006 (EAV/Page schema), ADR-0011 (TipTap spike), ADR-0019 (Obsidian linked vault)

---

## Context

Project and task detail views currently use hardcoded templates and plain `<textarea>` inputs. Milestones are stored as a JSON array in `props.milestones`, separate from the page body. The architecture spec defines TipTap as a "Block-based WYSIWYG Markdown editor with custom node extensions," but the current implementation only uses StarterKit + TaskList + TaskItem with no custom extensions.

This creates several problems:

- Project content (description, milestones, linked references) is split across props and body with no unified editing surface
- No way to link to other pages (`[[wikilinks]]`) or embed page previews (`![[embeds]]`) inside the editor
- Templates are static and not composable — users can't mix block types freely
- No slash command system for block insertion (standard expectation from Notion/Obsidian users)

We need a block-based editing model where the TipTap body is the single source of truth for all structured content within a project or task page.

---

## Decision

### 1) Milestones migrate from props to body markdown

The project body becomes a TipTap-editable document containing both description text AND milestones as GFM task list items (`- [ ] milestone text`). Progress is computed from the body, not stored in props.

**Rationale:** Two sources of truth (props milestones + body text) creates sync conflicts. TipTap already has `TaskList` + `TaskItem` extensions that handle GFM checkboxes natively. Making the body the single editor surface eliminates the split.

### 2) WikiLink inline node extension (`[[Page Title]]`)

A custom TipTap inline node for page references:

- **Rendering:** Styled inline pill/chip with page title
- **Click:** Navigates to the linked page
- **Hover:** Floating preview card (title, kind badge, body excerpt)
- **Markdown syntax:** `[[target]]` or `[[target|display alias]]`
- **Serialization:** Custom `markdown-it` inline rule + custom serializer for `tiptap-markdown`

This node is `atom: true` (non-splittable, single unit) with attrs `{ target: string, alias: string | null }`.

**Backend integration:** The existing `extract_wikilinks` function in `search.rs` already parses `[[...]]` from page bodies and creates `wikilink` edges in `graph_edges`. This fires automatically on `page_update_body`. No backend changes needed.

### 3) Page Embed block node (`![[Page Title]]`)

A custom TipTap block-level node for inline page previews:

- **Rendering:** Card block within the editor showing title, kind badge, status, body excerpt
- **Click:** Navigates to full page
- **Markdown syntax:** `![[target]]` (line-level, follows Obsidian convention)
- **Distinction from wikilinks:** `!` prefix = embed (block), no prefix = link (inline). Mirrors `![]()` vs `[]()` in standard markdown.

This node is `atom: true`, `group: 'block'`, with attrs `{ target: string }`.

### 4) Slash command menu

Trigger on `/` at start of a line to show an insertable block menu:

| Command | Inserts |
|---------|---------|
| Heading 1/2/3 | Heading block |
| Task List | `- [ ]` task item |
| Link to page | `[[wikilink]]` via page search |
| Embed page | `![[embed]]` via page search |
| Code block | Fenced code block |
| Quote | Blockquote |
| Divider | Horizontal rule |

The link/embed commands open a page search sub-menu (uses existing `search_global` IPC).

---

## Consequences

### Positive

- Single editing surface (TipTap body) for all structured project content
- Composable blocks — users can freely mix text, milestones, links, embeds
- `[[wikilinks]]` enable cross-page navigation and graph edges for RAG/search
- `![[embeds]]` enable inline previews without leaving the editor context
- Slash command menu matches user expectations from Notion/Obsidian
- Markdown round-trip preserves all content for vault storage and Obsidian interop

### Risks

- `tiptap-markdown` custom plugin API may have edge cases with non-standard syntax
- Wikilink target resolution needs fuzzy matching (title changes break hard references)
- Page embed cards need data fetching inside the editor — potential performance concern with many embeds

### Mitigations

- Comprehensive round-trip tests for each custom node type
- Wikilink resolution uses existing FTS search (fuzzy by nature) + page_id fallback
- Embed cards lazy-load with intersection observer, cache results in Zustand store
