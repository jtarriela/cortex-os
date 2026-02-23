# ADR-0022: Vault Workbench + Linked Obsidian Write-Back (CodeMirror Source-First)

**Status:** IMPLEMENTED
**Date:** 2026-02-22
**Accepted:** 2026-02-22
**Implemented:** 2026-02-23
**Deciders:** Architecture review
**FR:** FR-003, FR-023, FR-028, FR-029
**Related:** ADR-0015 (vault onboarding + save-commit indexing), ADR-0019 (linked vault by path), ADR-0020 (TipTap block editor scope)

---

## Context

ADR-0019 delivered linked Obsidian vault support in a read-only-first rollout with feature flags. That baseline was intentionally conservative:

- linked files could be indexed and viewed in Cortex
- linked note editing was blocked
- frontmatter/body normalization favored ingestion safety over exact source round-trip

Product direction now requires Cortex to act as a source-first markdown editor for linked vault notes, without requiring users to open Obsidian for normal edits.

The existing single-document Notes view (TipTap-first behavior) is not sufficient for this requirement because it does not provide:

- multi-tab file editing workflows
- direct linked-file write-back
- deterministic conflict handling for concurrent external edits
- markdown source fidelity guarantees for Obsidian-specific syntax and frontmatter

---

## Decision

### 1) Vault view becomes a tabbed Vault Workbench

The Notes center pane will use a tabbed model with:

- open file tabs
- active tab switching
- dirty-state indicators
- close-tab behavior that blocks silent loss for unsaved tabs
- keyboard-driven tab navigation and file search

### 2) Source-first editor uses CodeMirror (not TipTap)

Vault editing adopts CodeMirror markdown mode for source fidelity and Obsidian compatibility. TipTap remains in scope for project/task block editing (ADR-0020/ADR-0021 workflows) and is not removed from those surfaces.

### 3) Linked vault default mode is `read_write` for new links

`VaultLink.mode` supports:

- `read_only`
- `read_write`

New links default to `read_write` in Settings, with explicit warning text and a manual mode toggle per link.

### 4) Linked write-back uses optimistic concurrency and explicit conflict resolution

A new linked-note save contract is introduced:

- command: `obsidian.noteSave` / `obsidian_note_save`
- request: `{ page_id, base_hash, markdown }`
- response: `LinkedNoteSaveResult`
  - `saved`: `{ status: "saved", note, sourceHash }`
  - `conflict`: `{ status: "conflict", serverMarkdown, serverHash, message }`

Conflict policy is explicit and user-mediated:

- no silent overwrite
- no auto-merge
- no last-writer-wins fallback

UI presents an explicit merge modal with:

- use server version
- overwrite with my changes (retry against refreshed `base_hash`)

### 5) Linked markdown round-trip preserves raw source

Linked-note ingestion/write paths preserve raw markdown body/frontmatter content so Obsidian markdown constructs round-trip without lossy transformations.

### 6) Scope and safety guardrails remain strict

- markdown files only (`.md`)
- writes are constrained to validated linked root paths
- root-escape and symlink safety checks remain mandatory
- `read_only` mode continues to block linked writes and supports Save-as-Cortex-note fallback

---

## Implementation Status (2026-02-23)

Workspace implementation is complete under this ADR:

- Contracts delivered with `VaultLink.mode` expansion and `obsidian.noteSave` response union.
- Backend delivered `read_write` mode validation, linked note hash persistence, raw markdown preservation, and `obsidian_note_save` conflict flow.
- Frontend delivered Vault Workbench tabs, CodeMirror markdown editor, linked save conflict modal, and keyboard shortcuts (`Cmd/Ctrl+S`, `Cmd/Ctrl+W`, `Cmd/Ctrl+Shift+[`, `Cmd/Ctrl+Shift+]`, `Cmd/Ctrl+P`).
- Integration pins and release logs were synchronized in the workspace release process.

### Post-Implementation UX Refinement (2026-02-23)

The Vault Workbench received non-contract UX enhancements that remain within this ADR's scope:

- preview-first note mode with explicit `Preview` / `Edit Source` toggle (source editing still powers linked write-back)
- split explorer sections for `Cortex Files` and `Obsidian Files`, with folders collapsed by default
- rendered markdown preview support for clickable Obsidian wikilinks (same-tab navigation) with best-effort heading/block anchor scroll
- right-drawer note `Inspect` tab with linked source/index/sync metadata, exact backlinks, outgoing links, and conflict/version diagnostics backed by `search_graph_links` and `obsidian_note_inspect`

These changes improve operability and inspection/debuggability without altering ADR-0022 conflict policy or source-fidelity guarantees.

---

## Consequences

### Positive

- Cortex can edit linked Obsidian markdown directly with source fidelity.
- Users get a real multi-file markdown workflow in Vault view.
- Conflict handling is explicit and traceable, reducing accidental clobbering.
- Project/task block editing remains stable by keeping TipTap scoped to ADR-0020 surfaces.

### Risks

- More complex save-state and conflict UX in the notes workspace.
- Mode defaults (`read_write`) increase user impact of accidental writes.
- Source-fidelity expectations increase regression sensitivity for parser/normalization changes.

### Mitigations

- explicit read/write warning text in Settings
- conflict modal with deterministic retry semantics
- TDD coverage for tabs, linked-save conflicts, and raw markdown round-trip scenarios
- strict path validation and read-only enforcement retained server-side
