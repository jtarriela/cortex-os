# ADR-0011: Spike Gate Validation Plan

**Status:** IMPLEMENTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** All (prerequisite)
**Supersedes:** N/A
**Related:** `001_architecture.md` Section 11, ADR-0006

---

## Context

`001_architecture.md` Section 11 defines a mandatory Spike Gate — 6 technical validations that must pass before any feature development begins. As of Phase 0, none have been executed. The architecture doc itself notes at Section 12: "The Spike Gate validation (Tauri, SQLCipher, TipTap) has NOT been done."

The Spike Gate exists because the architecture makes assumptions about technology compatibility that have not been verified:

1. Can SQLCipher, FTS5, and sqlite-vec coexist in a single encrypted database?
2. Does Tauri v2 build and package on all target platforms?
3. Can TipTap round-trip Markdown with YAML frontmatter?

If any of these fail, the architecture may need significant revision.

## Decision

The Spike Gate is formalized as a structured validation plan with explicit acceptance criteria, execution order, and deliverables.

### Spike 1: Tauri v2 Scaffold

**Acceptance criteria:**
- `cargo tauri init` succeeds with Tauri v2 (stable)
- The scaffold builds and opens a window displaying a "Hello from Cortex" React component
- `cargo tauri build` produces a distributable package on macOS (arm64), Linux (x86_64)
- The Tauri process can invoke a simple Rust command from the frontend (`invoke("greet", { name: "test" })`)

**Deliverable:** A minimal `src-tauri/` directory in the backend repo with `main.rs`, `Cargo.toml`, and one command.

### Spike 2: SQLCipher Integration

**Acceptance criteria:**
- `rusqlite` compiles with the `bundled-sqlcipher` feature
- A Rust test creates an encrypted SQLite database, writes a row, closes, reopens with the password, and reads the row back
- Opening the database without the correct password returns an error
- The encrypted database file is not readable as plain SQLite

**Deliverable:** A test in `cortex_storage/tests/` demonstrating encryption/decryption.

### Spike 3: FTS5 Extension

**Acceptance criteria:**
- FTS5 virtual table is created inside a SQLCipher-encrypted database
- Text is inserted and ranked full-text search returns results ordered by relevance
- The `bm25()` ranking function works correctly

**Deliverable:** A test in `cortex_storage/tests/` demonstrating FTS5 within SQLCipher.

### Spike 4: sqlite-vec Extension

**Acceptance criteria:**
- The `sqlite-vec` extension loads inside a SQLCipher-encrypted database
- A `vec0` virtual table is created with `float[384]` embeddings
- Vector insertion and cosine similarity `knn` query return correct results
- The extension works on macOS (arm64) and Linux (x86_64)

**Deliverable:** A test in `cortex_storage/tests/` demonstrating sqlite-vec within SQLCipher.

### Spike 5: Combined Validation

**Acceptance criteria:**
- A single SQLCipher-encrypted database simultaneously contains:
  - A `pages` table with sample rows
  - A `pages_fts` FTS5 virtual table with indexed content
  - A `vec_chunks` sqlite-vec virtual table with sample embeddings
- Full-text search returns ranked results
- Vector similarity search returns nearest neighbors
- Both queries return correct results against the same dataset
- Database can be closed, reopened with password, and all data is intact

**Deliverable:** An integration test in `cortex_storage/tests/` that runs all three together.

### Spike 6: TipTap Basic Integration

**Acceptance criteria:**
- A TipTap editor component renders Markdown content (headings, lists, bold, code blocks)
- Content can be edited in WYSIWYG mode
- Content round-trips: Markdown → TipTap → Markdown produces equivalent output
- YAML frontmatter is preserved during round-trip (either parsed into a property panel or passed through as-is)

**Deliverable:** A React component in `frontend/src/editor/` with a minimal TipTap setup and a round-trip test.

## Execution Order

```
1. Spike 1 (Tauri scaffold)     — establishes the build pipeline
2. Spike 2 (SQLCipher)          — validates encryption
3. Spike 3 (FTS5)               — validates full-text search within encrypted DB
4. Spike 4 (sqlite-vec)         — validates vector search within encrypted DB
5. Spike 5 (Combined)           — validates all three coexist
6. Spike 6 (TipTap)             — validates editor integration (independent of DB spikes)
```

Spikes 2-4 can potentially be parallelized if multiple developers are available. Spike 6 is independent of Spikes 1-5 and can run in parallel.

## Gate Criteria

**All 6 spikes must pass before Phase 1 feature work begins.** If any spike fails:

- Document the failure in a new ADR explaining the root cause
- Evaluate alternative technologies (e.g., if sqlite-vec doesn't work with SQLCipher, evaluate `hnswlib` or `usearch` alternatives)
- The architecture doc must be updated to reflect the chosen alternative before feature work resumes

## Status Tracking

| Spike | Status | Date Completed | Notes |
|-------|--------|---------------|-------|
| 1. Tauri v2 scaffold | PASSED | 2026-02-19 | `cortex-os-backend#1` closed; `backend/crates/app/src/main.rs` scaffold + Tauri v2 window. Evidence: `.system/MEMORY.md` Phase 0.5 entry. |
| 2. SQLCipher integration | PASSED | 2026-02-19 | `backend/crates/storage/tests/spike_coexistence.rs::test_sqlcipher_encrypt_decrypt` green. |
| 3. FTS5 extension | PASSED | 2026-02-19 | `backend/crates/storage/tests/spike_coexistence.rs::test_fts5_in_encrypted_db` green. |
| 4. sqlite-vec extension | PASSED | 2026-02-19 | `backend/crates/storage/tests/spike_coexistence.rs::test_sqlite_vec_in_encrypted_db` green. |
| 5. Combined validation | PASSED | 2026-02-19 | `backend/crates/storage/tests/spike_coexistence.rs::test_sqlcipher_fts5_vec_coexistence` green. All three coexist in one encrypted DB. |
| 6. TipTap integration | PASSED | 2026-02-19 | `cortex-os-backend#2` / `cortex-os-frontend#7` merged; `frontend/tests/tiptap.spike.test.ts` (15 tests) green. Frontmatter round-trip confirmed via `gray-matter` + `tiptap-markdown`. | |

## Consequences

- **No feature PRs until gate passes.** Backend feature PRs (vault adapter, indexing pipeline, etc.) must be rejected until this ADR's status tracking shows all spikes as PASSED.
- **Build infrastructure first.** The spike deliverables become the foundation crates (`cortex_storage` tests, `src-tauri/` scaffold, TipTap component).
- **Platform matrix.** Spikes must pass on macOS (arm64) and Linux (x86_64) at minimum. Windows (x86_64) is optional for the gate but required before public release.
