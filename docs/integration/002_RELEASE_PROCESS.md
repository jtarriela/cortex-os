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
| 2026-02-20 | Frontend projects-board bug sweep + docs sync | `4949303` | `3039b12` | `3d42185` | Frontend PR [#37](https://github.com/jtarriela/cortex-os-frontend/pull/37) merged: fixed `[Bug]` issues #27/#28/#30/#31/#32/#33/#34/#35, added project-create modal + filter diagnostics + master-task sort/group/task-create wiring, and synced FE architecture docs + FE memory. |
| 2026-02-20 | Week planner + task editor + trip setup reliability | `8f1f4c9` | `ec7f56e` | `3a6898d` | Week view now supports persisted drag/drop + explicit event edit/save; task modal now uses local draft with explicit save to prevent TipTap/tag reset loops; meals planner slot matching and in-context recipe creation flow are hardened; trip creation now captures destination/date/duration/optional budget; contracts docs updated for optional `travel.createTrip budget?` and ADR-0016 is added for future macro tracking. |
| 2026-02-19 | Phase 2 FR-027 hardening | `c6b17a7` | `14b0426` | `e257e5c` | Implemented real `integrations_trigger_sync` flow, fixed frontend lint errors, updated traceability + MEMORY. |
| 2026-02-19 | FR-027 reconciliation closure | `69d6bf9` | `14b0426` | `e257e5c` | Added outbound update/delete reconciliation in `integrations_trigger_sync`, timestamp conflict handling, and orphan Cortex-event cleanup. Updated traceability + MEMORY to close the FR-027 gap. |
| 2026-02-19 | FR-027 reconciliation hardening | `097cdc6` | `14b0426` | `e257e5c` | Removed 90-day bound from Cortex orphan sweep so delete propagation reconciles full history. |
| 2026-02-19 | Phase 3 epic closure (Search + State) | `ce863ad` | `544c7ef` | `5a90bcc` | Merged FE/BE/contracts Phase 3 PRs; pinned hybrid search + graph backend, domain Zustand stores/realtime/search UI polish, and IPC contract sync updates. |
| 2026-02-19 | Phase 4 closure implementation pass (workspace) | `9cfb41e` | `3f7a142` | `74136e0` | Local workspace implements vault onboarding + secure settings + save-commit indexing + RAG + Morning Review/usage UI + contracts 0.4.0 docs. **Pending:** merged component PRs and pinned SHAs. |
| 2026-02-19 | Phase 5 gap audit + ADR-0011 IMPLEMENTED | `26f5f37` | `1cb2041` | `756fff1` | Submodules initialized; all Phase 4 critical-path code confirmed in component main branches. ADR-0011 status table updated to IMPLEMENTED. Phase 5 epics filed (cortex-os#9-12). 73 frontend + 18 backend tests green. Open: Phase 2 issues (backend#6, frontend#3, contracts#2), Google Calendar E2E (ADR-0014). |
| 2026-02-20 | Phase 5 voice adapters pin sync (backend PR #28) | `4934ec1` | `85209f1` | `bd9e894` | Integration repo aligned to merged backend `main` commit from `cortex-os-backend#28` (provider-routed STT/TTS adapters). Cortex epic `cortex-os#14` closed after verification. |
| 2026-02-20 | Phase 5 card/file wiring + Google UX reliability | `c8fa5c6` | `8f6493f` | `9912069` | Merged FE/BE/contracts updates: canonical `vault_create_page`/`capture_save` payload alignment, markdown persistence for page/travel/capture/save flows, Travel cards UI rewiring, and surfaced Google integration errors with missing credential guidance. |
| 2026-02-20 | Phase 5 IPC casing + week-view stabilization | `4949303` | `5fc2f5e` | `3d42185` | Fixed Tauri command-arg casing drift (`collectionId`/`pageId`/`startDate` etc.), added reference-date week query in backend, improved Habits/Goals/Travel/WeekDashboard error surfacing, and added in-view recipe creation flow for weekly planner usability. |
