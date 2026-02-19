# 002 Release Process

This document tracks integration-level submodule pinning for Cortex OS.

## Pinning Protocol

1. Merge implementation PRs in component repos (`frontend`, `backend`, `contracts`).
2. In integration repo, bump submodule SHAs to merged commits.
3. Update `.system/MEMORY.md` with release progress.
4. Update `docs/traceability.md` if FR implementation status changed.
5. Commit integration repo with submodule pointer updates + doc sync.

## Release Log

| Date (UTC) | Scope | Backend SHA | Frontend SHA | Contracts SHA | Notes |
|------------|-------|-------------|--------------|---------------|-------|
| 2026-02-19 | Phase 2 FR-027 hardening | `c6b17a7` | `14b0426` | `e257e5c` | Implemented real `integrations_trigger_sync` flow, fixed frontend lint errors, updated traceability + MEMORY. |
| 2026-02-19 | FR-027 reconciliation closure | `69d6bf9` | `14b0426` | `e257e5c` | Added outbound update/delete reconciliation in `integrations_trigger_sync`, timestamp conflict handling, and orphan Cortex-event cleanup. Updated traceability + MEMORY to close the FR-027 gap. |
| 2026-02-19 | FR-027 reconciliation hardening | `097cdc6` | `14b0426` | `e257e5c` | Removed 90-day bound from Cortex orphan sweep so delete propagation reconciles full history. |
| 2026-02-19 | Phase 3 epic closure (Search + State) | `ce863ad` | `544c7ef` | `5a90bcc` | Merged FE/BE/contracts Phase 3 PRs; pinned hybrid search + graph backend, domain Zustand stores/realtime/search UI polish, and IPC contract sync updates. |
| 2026-02-19 | Phase 4 closure implementation pass (workspace) | `9cfb41e` | `3f7a142` | `74136e0` | Local workspace implements vault onboarding + secure settings + save-commit indexing + RAG + Morning Review/usage UI + contracts 0.4.0 docs. **Pending:** merged component PRs and pinned SHAs. |
