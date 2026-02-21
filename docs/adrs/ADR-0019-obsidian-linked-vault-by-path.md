# ADR-0019: Obsidian Linked Vault by Path (Metadata-First Sync + Indexed RAG)

**Status:** PROPOSED
**Date:** 2026-02-21
**Deciders:** Architecture review
**FR:** FR-003, FR-020, FR-023, FR-028
**Related:** ADR-0006 (EAV/Page schema), ADR-0015 (vault onboarding + save-commit indexing)

---

## Context

Users may want Cortex to operate on an existing Obsidian vault, including very large vaults (tens/hundreds of thousands of Markdown files). A clone-first strategy (`cp`/`rsync` mirror of the entire tree) creates scaling and reliability problems:

- duplicate disk usage
- expensive full-tree scans/copies on first link
- complex stale-state behavior under frequent edits
- unclear ownership semantics in read-only mode

We need a path-based integration model that:

1. links an existing Obsidian vault without full cloning
2. scales with large vaults
3. keeps read-only as the first safe mode
4. preserves Cortex search/RAG performance through indexed retrieval

---

## Decision

### 1) Link external Obsidian vault by absolute path (no full clone by default)

Cortex will support an additional **linked external source** in Settings:

- `Obsidian Link` toggle
- `Vault path` input
- optional include/exclude path selector (folders/files) before first import
- `Mode` selector (initially `read_only`)
- `Add` + `Sync now` + sync status UI

This linked source is distinct from the primary Cortex vault profile (ADR-0015). The primary vault still controls Cortex-owned writes and settings profile identity.

### 2) Read-only first (phase-safe)

Initial implementation is `read_only`:

- Obsidian -> Cortex sync allowed
- Cortex does not write, rename, or delete in linked Obsidian path
- editing a linked note in Cortex is blocked or redirected to "Save as Cortex note"

`read_write` may be added later with explicit conflict policy ADR follow-up.

### 2.1) Hash vs Embedding semantics (explicit)

- **Hash** is a change detector (`same`/`different`) used by sync/index queues.
- **Embedding** is a semantic vector used by retrieval ranking.
- Hash changes may trigger re-embed work; embeddings themselves are not used to detect file changes.

### 3) Metadata-first sync schema

The linked-vault pipeline stores metadata/state in DB, not full mirrored file copies.

#### `vault_link` (one row per linked external vault)

- `link_id` (PK)
- `provider` (`obsidian`)
- `root_path` (absolute canonical path)
- `mode` (`read_only` for v1)
- `enabled` (bool)
- `created_at`
- `updated_at`
- `last_scan_at`
- `last_error`

#### `vault_file_manifest` (one row per linked markdown file)

- `link_id` (FK)
- `rel_path` (canonical key within root)
- `size_bytes`
- `mtime_ns` (or ms, monotonic preference)
- `file_id` (inode/file-id where available, optional)
- `content_hash` (nullable/lazy)
- `exists` (bool)
- `deleted_at` (nullable)
- `last_seen_at`

#### `vault_file_index_state` (index freshness tracking)

- `link_id` (FK)
- `rel_path`
- `index_hash`
- `indexed_at`
- `embedding_status` (`pending|indexed|failed|skipped`)
- `parse_error` (nullable)

#### `sync_queue` (change processing queue)

- `queue_id` (PK)
- `link_id` (FK)
- `rel_path`
- `change_type` (`create|update|delete|rename`)
- `status` (`queued|processing|done|failed|skipped`)
- `attempts`
- `reason` (nullable)
- `enqueued_at`
- `updated_at`

### 4) Sync pipeline for large vaults

#### Initial link

1. Validate path + access + loop/symlink boundaries.
2. Metadata crawl for `.md` files only (`rel_path`, `size`, `mtime`, optional `file_id`) with include/exclude path filters applied.
3. First-link import computes content hashes and queues ingest for selected files.
4. Initial import workers run in parallel with bounded concurrency (do not saturate all system threads blindly).
5. UI shows phase progress (`scan -> hash -> parse/index -> embed`) and per-phase counts so users can wait explicitly.

#### Ongoing changes

1. Filesystem watcher enqueues changed paths.
2. Queue coalescing ensures one active queued job per file.
3. Periodic reconcile scan catches missed watcher events.
4. Background workers process queue with bounded concurrency/backpressure.
5. Hash is computed only for candidate-changed files (metadata/watcher indicated), not for every file on every cycle.

No full-vault reindex on ordinary edits.

---

## RAG Indexing Behavior for Linked Obsidian Vaults

RAG uses a two-stage model: cheap metadata detection + indexed retrieval.

### Stage A: Change detection (metadata only)

- compare manifest/index state with latest file metadata (`mtime`, `size`, optional `file_id`)
- if unchanged, skip file read and skip embedding
- if changed/unknown, enqueue ingest for that file

### Stage B: Ingest/index (content read for changed files only)

For queued files:

1. read file content from linked Obsidian path
2. parse frontmatter/body into Page model
3. update page row + search chunks
4. generate/update embeddings for changed chunks
5. upsert `vault_file_index_state.index_hash/indexed_at`

### Stage C: Query-time retrieval (no filesystem reads)

`ai_rag_query`/semantic retrieval should query DB indexes (`pages`, `search_chunks`, vector index). Query-time RAG must not read files from disk except explicit fallback diagnostics.

This keeps RAG latency stable even for very large linked vaults.

### Stage D: Embedding provider policy (AI settings)

Embeddings should be configurable in AI Settings with:

- `embeddingProvider` = `same_as_model | openai | gemini | ollama | hash`
- default: `same_as_model`

Default behavior:

- `same_as_model` attempts to use the same provider family and credential already configured for the active model.
- if provider embeddings are unavailable for that adapter, retrieval falls back to `hash` behavior with status surfaced in diagnostics.

Rationale:

- chat model and embedding model are separable, but defaulting to "same as model" reduces setup friction.
- explicit embedding provider selection is required for cost/performance/privacy control.

---

## Scaling Constraints and Guardrails

1. Initial scan/import may hash many files once; it must run as bounded parallel work with progress visibility.
2. Worker concurrency is capped; queue supports pause/resume and progress metrics.
3. After initial link, hash only candidate-changed files (watcher + metadata), not full-vault hash sweeps.
4. Embedding jobs are chunk-incremental and coalesced per file.
5. Very large files use size guards/chunk caps with error status surfaced in sync UI.
6. All paths are canonicalized and restricted under configured linked root.

---

## Planned IPC/Surface Additions (Contracts Follow-up Required)

- `obsidian_link_add(request: { root_path, mode }) -> VaultLink`
- `obsidian_link_list() -> VaultLink[]`
- `obsidian_link_remove(request: { link_id }) -> ()`
- `obsidian_link_set_mode(request: { link_id, mode }) -> VaultLink`
- `obsidian_sync_now(request: { link_id }) -> SyncRun`
- `obsidian_sync_status(request: { link_id, limit? }) -> SyncStatus`

Per AGENTS/protocol, backend command additions require paired PR updates in `cortex-os-contracts` wiring matrix and FE IPC client usage.

---

## Consequences

### Positive

- avoids full vault clone overhead
- scales better for large Obsidian datasets
- clear read-only safety boundary for v1
- preserves fast RAG via indexed retrieval
- clarifies first-import behavior and user-visible progress for large vaults
- supports embedding cost/privacy tradeoffs through provider selection

### Risks

- watcher reliability differences across OS/filesystems
- rename detection ambiguity without stable file IDs
- user confusion between primary Cortex vault vs linked Obsidian source

### Mitigations

- periodic reconcile scan + watcher coalescing
- optional hash fallback when metadata signals are ambiguous
- explicit UI labels: "Primary Cortex Vault" vs "Linked Obsidian Vault (Read-only)"
