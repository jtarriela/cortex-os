# Phase 4 Regression Matrix + Gate Evidence

**Date:** 2026-02-19  
**Parent issue:** `cortex-os#8`  
**Scope:** AI, voice, HITL, privacy, vault onboarding/persistence, and cross-repo contract sync

## Regression Matrix

| Area | Check | Evidence | Result |
|------|-------|----------|--------|
| Vault onboarding | First-run setup requires create/select vault profile before app shell | `frontend/App.tsx`, `frontend/views/VaultSetup.tsx`, `backend/crates/app/src/lib.rs` (`vault_create`, `vault_select`, `vault_get_profile`) | PASS |
| Save commit semantics | Note edits mark dirty, debounce, flush on unload; backend enqueues indexing only after persisted commit | `frontend/stores/noteStore.ts`, `frontend/views/NotesLibrary.tsx`, `backend/crates/app/src/lib.rs` (`save_commit`, `enqueue_index_job`) | PASS |
| Incremental indexing | Hash unchanged => `skipped`, changed => queued/indexed, queue is observable | `backend/crates/storage/src/schema.rs` (`index_jobs`, `page_index_state`), `backend/crates/app/src/lib.rs` (`index_queue_status`) | PASS |
| Secure settings | API keys encrypted at rest; settings transport returns masked placeholders | `backend/crates/app/src/lib.rs` (`secret_store_*`, `settings_get`, `settings_update`) | PASS |
| AI provider routing | Backend adapter abstraction for OpenAI/Anthropic/Gemini/Ollama with normalized error envelope | `backend/crates/app/src/ai.rs`, `backend/crates/app/src/lib.rs` (`ai_chat`) | PASS |
| Stream resilience | `ai_stream_error` emitted with `requestId/error/provider/code` and frontend retry/cancel UX | `backend/crates/app/src/lib.rs`, `frontend/components/RightDrawer.tsx` | PASS |
| HITL queue | Morning Review list/edit/approve/reject + batch actions | `frontend/views/Settings.tsx`, `backend/crates/app/src/lib.rs` (`review_*`) | PASS |
| Usage dashboard | Token/cost range controls + grouped table in settings | `frontend/views/Settings.tsx`, `backend/crates/app/src/lib.rs` (`token_usage`) | PASS |
| RAG commands | `ai_rag_query` and `ai_suggest_links` command surface implemented | `backend/crates/app/src/lib.rs`, `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md` | PASS |
| Contract sync | Vault/secret/save-commit/RAG contract docs and changelog/version updated | `contracts/docs/CONVENTIONS.md`, `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`, `contracts/CHANGELOG.md`, `contracts/docs/VERSIONING.md` | PASS |

## Verification Runs

### Frontend (`cortex-os-frontend`)
- `npm test` -> PASS (13 files, 73 tests)
- `npm run lint` -> PASS
- `npm run build` -> PASS

### Backend (`cortex-os-backend`)
- `cargo check -p cortex-app` -> PASS
- `cargo test -p cortex-app` -> PASS
- `cargo test -p cortex-storage --test ai_phase4` -> PASS

## Remaining Risks

1. Provider adapters depend on runtime credentials/endpoints; credential-less environments fall back to deterministic response path.
2. Whisper/TTS transports are tier/provider-aware at the command layer, but full production model lifecycle/download UX remains a follow-up hardening concern.
3. Submodule pinning and merged SHA recording must be completed in release workflow after component PR merge.

## Gate Decision

**Go (conditional):** Functional Phase 4 gate criteria for onboarding/privacy/HITL/usage/contracts are implemented and regression evidence is green in workspace.  
**Condition:** Complete merged-PR SHA pinning in `docs/integration/002_RELEASE_PROCESS.md` once component repos merge.
