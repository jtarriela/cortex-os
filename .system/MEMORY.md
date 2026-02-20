
# MEMORY — Cortex OS (Integration)

## Current Focus
- **Phase 3 epic completion pass implemented (issue #4): search + state + secondary module persistence/analytics delivered across FE/BE/contracts.**
- **Phase 4 closure pass implemented (issue #5): vault onboarding, secure settings, save-commit indexing semantics, RAG commands, and frontend review/usage UX integrated.**
- **Phase 5 AI/Voice hardening implemented:** real OpenAI/Gemini STT/TTS adapters, provider-routed voice settings (`sttProvider`/`ttsProvider`), and contracts/docs sync for ADR-0004/0005/0013 (current STT default: online `gemini`; local Whisper deferred).

## System State (Facts Only)
- Integration repo acting as workspace root.
- Submodules: frontend, backend, contracts.
- Frontend: backend IPC is wired for core domains; app shell state now uses Zustand (`stores/appStore.ts`); realtime event subscription store (`stores/realtimeStore.ts`) invalidates active views on backend page events.
- Backend: Tauri app + SQLCipher storage + page repository implemented; Google OAuth + calendar list/create + incremental sync + outbound create/update/delete reconciliation are implemented; page mutation commands emit realtime events (`page_created`, `page_updated`, `page_deleted`).
- Contracts: IPC wiring matrix maintained in contracts repo; realtime event stream contract documented for Phase 3 foundation.
- Original architecture vision in `docs/technical_architecture/` (001–004). Frontend has diverged (domain-specific types instead of unified Page model; no Tauri yet; AI in frontend, not backend).

## Active ADRs

### Frontend-scoped (in `frontend/docs/frontend_architecture/000_OVERVIEW.md`)
- FE-AD-01: Global state in App.tsx useState (Zustand planned for Phase 3)
- FE-AD-02: In-memory mock service (backend wiring in Phase 1)
- FE-AD-03: Direct Gemini calls in frontend (moves to Rust backend in Phase 4)
- FE-AD-04: Domain-specific types, not "Page" model (backend normalizes internally)
- FE-AD-05: Feature flags for progressive module disclosure
- FE-AD-06: No router library (simple NavSection switch)

### Cross-cutting (in `docs/adrs/`)
- ADR-0001: Goals module — not in original vision, added in Phase 0 (ACCEPTED)
- ADR-0002: Meals/Recipes module — not in original vision, added in Phase 0 (ACCEPTED)
- ADR-0003: Journal with mood tracking — distinct from Notes/daily, added in Phase 0 (ACCEPTED)
- ADR-0004: AI multimodal features (Voice I/O + Image Gen) — not in original vision (ACCEPTED)
- ADR-0005: Frontend agent actions — direct tool-calling without HITL approval (ACCEPTED)
- ADR-0006: EAV/Page schema — canonical (supersedes backend 001_SCHEMA.md flat tables) (ACCEPTED)
- ADR-0007: Schedule → Calendar convergence (ACCEPTED)
- ADR-0008: BLOCKED task status required (ACCEPTED)
- ADR-0009: Workouts module deferred to Phase 4 (ACCEPTED)
- ADR-0011: Spike Gate — 6 validations before Phase 1 (ACCEPTED)
- ADR-0012: Test strategy — TDD-first (ACCEPTED)
- ADR-0013: Voice/Audio architecture — local Whisper + configurable TTS (ACCEPTED)
- ADR-0015: Vault onboarding + secure settings + incremental reindex semantics (**IMPLEMENTED** — Phase 5 verified; vault_create/select/profile, save_commit, index_queue_status, secret_set/get/delete confirmed wired)

## Roadmap — Issue Tracking

### Phase 0.5: Stabilization & Spike Gate (Pre-Alpha)
| Repo | Issue | Title |
|------|-------|-------|
| cortex-os | #1 | [Epic] Phase 0.5 — Spike Gate & Stabilization |
| cortex-os-backend | #1 | [Spike] Tauri v2 + SQLCipher + FTS5 + sqlite-vec |
| cortex-os-backend | #2 | [Spike] TipTap Markdown round-trip |
| cortex-os-frontend | #1 | [Epic] Phase 0.5 — Frontend Stabilization |
| cortex-os-contracts | #1 | [Epic] Phase 0.5 — Contracts Baseline |

### Phase 1: Alpha Foundation (Vault + Storage + IPC)
| Repo | Issue | Title |
|------|-------|-------|
| cortex-os | #2 | [Epic] Phase 1 — Alpha Foundation |
| cortex-os-backend | #3 | [Epic] Cargo Workspace + SQLCipher DB Layer |
| cortex-os-backend | #4 | [Epic] cortex_vault: Filesystem Adapter |
| cortex-os-backend | #5 | [Epic] Indexing Pipeline + Collection Engine |
| cortex-os-frontend | #2 | [Epic] IPC Migration (dataService → backend.ts) |
| cortex-os-contracts | #2 | [Epic] Page-Centric Command Specifications |

### Phase 2: Alpha (Domain Features + Planning)
| Repo | Issue | Title |
|------|-------|-------|
| cortex-os | #3 | [Epic] Phase 2 — Domain Features + Planning |
| cortex-os-backend | #6 | [Epic] Task Lifecycle + Calendar + Project Tracking |
| cortex-os-frontend | #3 | [Epic] TipTap Editor + Task Dependencies + Calendar |

### Phase 3: Beta Foundation (Search + State)
| Repo | Issue | Title |
|------|-------|-------|
| cortex-os | #4 | [Epic] Phase 3 — Search + State Management |
| cortex-os-backend | #7 | [Epic] Search Infrastructure + Graph + Secondary Modules |
| cortex-os-frontend | #4 | [Epic] Zustand Migration + Real-Time Events + Search |

### Phase 4: Beta (AI Backend + Privacy)
| Repo | Issue | Title |
|------|-------|-------|
| cortex-os | #5 | [Epic] Phase 4 — AI Backend + Privacy + Polish |
| cortex-os-backend | #8 | [Epic] cortex_ai: LLM Gateway + Voice + Privacy |
| cortex-os-frontend | #5 | [Epic] AI Frontend Migration + Streaming + Approval |
| cortex-os-contracts | #3 | [Epic] AI Command Specifications |

## Functional Requirements
- 28 FRs defined in `docs/functional_requirements.md` (FR-001 through FR-028)
- All sourced from frontend implementation
- FR-020 complete in backend foundation. FR-021/FR-022 now have Phase 4 foundation implementation (PII redaction + review queue); further provider hardening remains.

## Recent Progress (Append-only)
- 2026-02-19: Documentation initialization.
- 2026-02-19: Init docs evaluated against frontend implementation; moved from `docs/init_docs/` → `docs/technical_architecture/` (001–004). Frontend has: Goals, Meals, Journal, AI voice/image gen, feature flags — not all in original init docs. Frontend lacks: Tauri IPC, vault filesystem, TipTap editor, Zustand, collection engine, SQLCipher.
- 2026-02-19: Created `frontend/docs/frontend_architecture/` (6 files: 000-005). Updated `docs/functional_requirements.md` (26 FRs). Updated `docs/traceability.md` (26 rows). Updated `backend/docs/backend_architecture/` (000, 001, 002). Updated `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`.
- 2026-02-19: Created ADR-0001 through ADR-0005 in `docs/adrs/`. Annotated `docs/technical_architecture/` (001–004) with Phase 0 Reality divergence sections. Updated traceability with ADR cross-references.
- 2026-02-19: Full codebase evaluation. Created development roadmap: Phase 0.5 → Phase 1 → Phase 2 → Phase 3 → Phase 4. Created 21 GitHub epic issues across all 4 repos with gates, FR mapping, ADR references. Created labels (phase:*, epic, spike, gate, tech-debt, doc-sync, paired-pr, adr) across all repos. Updated MEMORY.md with roadmap issue tracking. Key findings: backend is 0% implemented (docs only), frontend ~70% Phase 0, contracts docs complete but no artifacts.
- 2026-02-19: Phase 0.5 Spike Gate backend (BE #1) complete. Cargo workspace created: crates/app (Tauri v2), crates/core (Page stub), crates/storage (SQLCipher+FTS5+sqlite-vec). 6 tests pass (2 unit + 4 integration). Evidence in `backend/docs/testing_strategy/001_TEST_EVIDENCE.md`. Branch: `codex/issue-1-spike-tauri-sqlcipher-fts5-vec`. devcontainer + docker-compose added to integration repo.
- 2026-02-19: Phase 0.5 Frontend stabilization (FE #1) complete. Added BLOCKED status (ADR-0008), converged ScheduleItem→CalendarEvent (ADR-0007), extracted Meals CRUD to dataService.ts (FR-013), Vitest 3 + RTL test infra (11 smoke tests green). Branch: `codex/issue-1-phase-0.5-frontend-stabilization`.
- 2026-02-19: Phase 0.5 Contracts baseline (Contracts #1) complete. Updated IPC wiring matrix: BLOCKED enum, deprecated schedule.* commands, added calendar.getToday + meals.update/delete + recipes.update/delete, error response convention. Created CHANGELOG.md. Merged to main.
- 2026-02-19: Phase 0.5 TipTap spike (BE #2) complete. 15 tests green: gray-matter round-trips YAML frontmatter; tiptap-markdown 0.9.0 round-trips body (headings, bold/italic, code, lists, links) in jsdom. Strip-and-reattach pattern confirmed. Packages: tiptap-markdown ✅, gray-matter ✅, @tiptap/extension-link not needed. FE PR #7 merged. TEST_EVIDENCE.md updated in backend main.
- 2026-02-19: **Phase 0.5 COMPLETE.** All 6 ADR-0011 Spike Gate validations passed. All PRs merged. Phase 1 unblocked.
- 2026-02-19: Phase 2 FR-027 hardening pass complete in workspace. Backend added real `integrations_trigger_sync` flow with OAuth token refresh, calendar discovery, Cortex calendar creation, inbound incremental pull to local `calendar_event` pages, and outbound creation for `sync_external` events. Frontend integrations flow updated and lint blockers resolved; tests expanded for sync/Settings behavior. Submodule commits: backend `c6b17a7`, frontend `14b0426`.
- 2026-02-19: FR-027 reconciliation completed in backend workspace branch. `integrations_trigger_sync` now does outbound updates/deletes, applies timestamp conflict policy (`local updated_at` vs Google `updated`), and removes orphaned Cortex events in Google via `cortex_page_id` correlation.
- 2026-02-19: Phase 3 foundation increment implemented for epic #4/#7. Frontend migrated shell state to Zustand (`frontend/stores/appStore.ts`), added realtime Tauri event subscriptions (`frontend/stores/realtimeStore.ts`), and enhanced command palette filtering/highlighting/related badges (`frontend/components/CommandPalette.tsx`) with new tests. Backend emits page lifecycle events from mutation commands in `backend/crates/app/src/lib.rs`. Contracts wiring matrix updated with Event Streams section.
- 2026-02-19: Phase 3 epic completion pass (workspace #4/#7/#4). Frontend added domain Zustand stores (`taskStore`, `projectStore`, `noteStore`) with optimistic CRUD and reduced prop drilling in `TasksIndex`, `ProjectsIndex`, `NotesLibrary`, and task modals; secondary polish shipped (Journal mood trend chart + date-window query, Goals progress summary chart, Finance month drill-down, Travel itinerary card loading). Backend added search provider extension with optional Ollama embeddings (hash fallback), semantic/graph commands, and secondary analytics commands (`journal_query`, `journal_mood_trends`, `habits_get_summary`, `goals_get_progress_summary`, `finance_get_summary`, `travel_get_itinerary`, `meals_get_nutrition_summary`). Contracts/backend/frontend docs and traceability updated; frontend+backend test suites green.
- 2026-02-19: Phase 4 foundation slice implemented for epic #5/#8/#3. Backend added AI command surface (`ai_get_models`, `ai_chat`, `ai_summarize`, `ai_generate_image`, `ai_transcribe`, `ai_synthesize`, `ai_validate_key`, `review_list`, `review_approve`, `review_reject`, `token_usage`), regex-based PII redaction, streaming events (`ai_stream_chunk`, `ai_stream_done`), and SQLCipher migrations for `review_queue` + `usage_log`. Frontend migrated `services/aiService.ts` from frontend-direct Gemini SDK to backend IPC wrappers, wired streaming chunks into `RightDrawer`, and added Ollama endpoint configuration in `Settings`. New tests pass: `frontend/tests/backend_ai.spec.ts`, `frontend/tests/ai_service_migration.spec.ts`, `backend/crates/storage/tests/ai_phase4.rs`.
- 2026-02-19: Phase 4 closure implementation pass complete in workspace. Backend now includes vault onboarding (`vault_create`, `vault_select`, `vault_get_profile`), encrypted secret store (`secret_set/get/delete` + masked settings transport), save-commit indexing queue (`save_commit`, `index_queue_status` with hash skip/coalescing), provider-adapter AI routing with normalized `ai_stream_error`, and RAG commands (`ai_rag_query`, `ai_suggest_links`). Frontend now gates startup on vault profile (`views/VaultSetup.tsx`), uses dirty/debounced note save commits with flush semantics (`stores/noteStore.ts`), and ships Settings-side Morning Review + token usage dashboard + backend-driven model/provider capability controls. Contracts docs updated for 0.4.0 surface/changelog.
- 2026-02-19: **Phase 5 Google Calendar E2E verification complete (cortex-os#12).** ADR-0014 core confirmed: `crates/integrations/google_calendar` compiles, Settings Integrations tab present, OAuth loopback/CSRF/sync implemented. 6 new smoke tests (`google::oauth::tests::*`, `google::models::tests::*`). Gaps deferred to backend#26: `disconnect_google`, `google_auth_status`, `set_calendar_color`.
- 2026-02-19: **Phase 5 Vault Onboarding verification complete (cortex-os#10).** ADR-0015 IMPLEMENTED — vault_create/select/profile, save_commit, index_queue_status, secret_set/get/delete confirmed wired. VaultSetup.tsx + App.tsx startup gate + noteStore 1500ms debounce autosave confirmed. Tests: vault_setup.spec.tsx (3), domain_stores.spec.ts, ai_phase4.rs (3 vault/index/secret tests).
- 2026-02-19: **Phase 5 gap audit complete.** Submodules initialized (were empty — root cause of broken UI). ADR gap analysis performed: all Phase 4 critical-path code confirmed present in component repo main branches (vault onboarding, VaultSetup.tsx, noteStore save-commit, secret encryption, index queue). 73 frontend tests + 18 backend storage tests all green. ADR-0011 status table retroactively updated to IMPLEMENTED (PR cortex-os#13). Phase 5 epics created: cortex-os#9 (spike gate), cortex-os#10 (vault onboarding), cortex-os#11 (EAV verification), cortex-os#12 (Google Calendar E2E). Open gaps deferred: Phase 2 issues (backend#6, frontend#3, contracts#2) still open; Google Calendar E2E (ADR-0014) unverified end-to-end. Submodule SHAs: backend `26f5f37`, frontend `1cb2041`, contracts `756fff1`.
- 2026-02-20: **Phase 5 Real AI Provider Adapters + Voice Pipeline completed (workspace pass).** Backend `cortex-app` routes `ai_transcribe` via `AISettings.stt_provider` (`local_whisper|openai|gemini`) and `ai_synthesize` via `AISettings.tts_provider` (`gemini|openai|local`) with real OpenAI/Gemini adapter transport in `crates/app/src/ai.rs`. **Follow-up policy update:** local Whisper runtime is deferred, and default STT is now online (`gemini`) until native runtime/model lifecycle implementation lands. Frontend `Settings` exposes STT/TTS provider selectors with provider-specific voice lists; backend/core `AISettings` includes provider fields. Contracts/docs updated (`002_IPC_WIRING_MATRIX.md`, `CONVENTIONS.md`, `CHANGELOG.md` 0.5.1). Verification: `cargo test -p cortex-app --lib`, `cargo test -p cortex-core`, `cargo test -p cortex-storage settings::tests::get_returns_default_when_missing`, `npm run lint`, and targeted Vitest AI/settings suites pass.
