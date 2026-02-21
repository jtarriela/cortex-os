
# MEMORY — Cortex OS (Integration)

## Current Focus
- **Calendar architecture consolidation accepted:** ADR-0018 is now ACCEPTED with execution epics `#23-#27` (adapter foundation, interaction parity, mixed editability, a11y/keyboard/responsive parity, performance/upgrade governance).
- **Phase 3 epic completion pass implemented (issue #4): search + state + secondary module persistence/analytics delivered across FE/BE/contracts.**
- **Phase 4 closure pass implemented (issue #5): vault onboarding, secure settings, save-commit indexing semantics, RAG commands, and frontend review/usage UX integrated.**
- **Phase 5 AI/Voice hardening implemented:** real OpenAI/Gemini STT/TTS adapters, provider-routed voice settings (`sttProvider`/`ttsProvider`), and contracts/docs sync for ADR-0004/0005/0013 (current STT default: online `gemini`; local Whisper deferred).
- **Phase 5 persistence/IPC alignment pass implemented:** `vault_create_page`/`capture_save` contract drift resolved, physical markdown writes added for page/travel/capture flows, Travel cards UI rewired to live state, and Google Settings now surfaces actionable integration errors.
- **Phase 5 runtime IPC casing stabilization pass in progress:** frontend invoke payloads are being standardized to Tauri command-argument camelCase (`collectionId`, `pageId`, `startDate`, etc.) with matching contracts documentation updates.

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
- ADR-0006: EAV/Page schema — canonical (supersedes backend 001_SCHEMA.md flat tables) (**IMPLEMENTED** — Phase 5 verification; no flat domain tables; CI-enforced by schema tests)
- ADR-0007: Schedule → Calendar convergence (ACCEPTED)
- ADR-0008: BLOCKED task status required (ACCEPTED)
- ADR-0009: Workouts module deferred to Phase 4 (ACCEPTED)
- ADR-0011: Spike Gate — 6 validations before Phase 1 (ACCEPTED)
- ADR-0012: Test strategy — TDD-first (ACCEPTED)
- ADR-0013: Voice/Audio architecture — local Whisper + configurable TTS (ACCEPTED)
- ADR-0015: Vault onboarding + secure settings + incremental reindex semantics (**IMPLEMENTED** — Phase 5 verified; vault_create/select/profile, save_commit, index_queue_status, secret_set/get/delete confirmed wired)
- ADR-0016: Meals macro-tracker extension roadmap (PROPOSED)
- ADR-0018: DayFlow calendar integration + centralized calendar workspace (ACCEPTED)

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

### Phase 5.1: Calendar Platform Integration (ADR-0018)
| Repo | Issue | Title |
|------|-------|-------|
| cortex-os | #23 | [Epic][ADR-0018] Calendar Workspace + DayFlow Adapter Foundation |
| cortex-os | #24 | [Epic][ADR-0018] Interaction Parity: External Task Drop + Drag/Resize |
| cortex-os | #25 | [Epic][ADR-0018] Mixed Editability + Google Permission Enforcement |
| cortex-os | #26 | [Epic][ADR-0018] Accessibility, Keyboard, and Responsive Parity |
| cortex-os | #27 | [Epic][ADR-0018] Performance Benchmarks + Upgrade Governance |
| cortex-os-frontend | #38 | [Child][ADR-0018][E23] Calendar Workspace + DayFlow Adapter Foundation (Frontend) |
| cortex-os-frontend | #39 | [Child][ADR-0018][E24] External Task Drop + Drag/Resize Parity (Frontend) |
| cortex-os-frontend | #40 | [Child][ADR-0018][E25] Mixed Editability + Google Permission UX (Frontend) |
| cortex-os-frontend | #41 | [Child][ADR-0018][E26] A11y + Keyboard + Responsive Parity (Frontend) |
| cortex-os-frontend | #42 | [Child][ADR-0018][E27] Performance Harness + DayFlow Upgrade Guardrails (Frontend) |
| cortex-os-backend | #29 | [Child][ADR-0018][E23] Calendar Range APIs + Workspace Support (Backend) |
| cortex-os-backend | #30 | [Child][ADR-0018][E24] Drag/Drop Persistence Semantics + Scheduling Paths (Backend) |
| cortex-os-backend | #31 | [Child][ADR-0018][E25] Permission Enforcement for Google-Sourced Events (Backend) |
| cortex-os-backend | #32 | [Child][ADR-0018][E26] Calendar IPC Stability for Keyboard/A11y Flows (Backend) |
| cortex-os-backend | #33 | [Child][ADR-0018][E27] Calendar Query/Sync Performance Baseline + Upgrade Safety (Backend) |
| cortex-os-contracts | #13 | [Child][ADR-0018][E23] Calendar Workspace Contract Baseline + Wiring Updates (Contracts) |
| cortex-os-contracts | #14 | [Child][ADR-0018][E24] External Drop/Drag Contract Clarifications (Contracts) |
| cortex-os-contracts | #15 | [Child][ADR-0018][E25] Mixed Editability Error Contract + Policy Mapping (Contracts) |
| cortex-os-contracts | #16 | [Child][ADR-0018][E26] Keyboard/A11y Interaction Contract + Drift Guard (Contracts) |
| cortex-os-contracts | #17 | [Child][ADR-0018][E27] Versioning + Compatibility Governance for Calendar Integration (Contracts) |

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
- 2026-02-19: **Phase 2 backend#6 closed (Task Lifecycle + Calendar + Project Tracking).** EAV generic commands satisfy all Phase 2 requirements — no domain-specific wrappers needed. Frontend calls `vault_create_page(kind:"task"|"project"|"calendar_event")`, `collection_query`, `page_update_props`, `vault_delete`, `calendar_get_today/week`, `calendar_add_from_task`. Contracts wiring matrix backend handler column updated. FR-001, FR-002, FR-004 marked Phase 2 IMPLEMENTED in traceability.
- 2026-02-19: **Phase 5 Google Calendar E2E verification complete (cortex-os#12).** ADR-0014 core confirmed: `crates/integrations/google_calendar` compiles, Settings Integrations tab present, OAuth loopback/CSRF/sync implemented. 6 new smoke tests (`google::oauth::tests::*`, `google::models::tests::*`). Gaps deferred to backend#26: `disconnect_google`, `google_auth_status`, `set_calendar_color`.
- 2026-02-19: **Phase 5 Vault Onboarding verification complete (cortex-os#10).** ADR-0015 IMPLEMENTED — vault_create/select/profile, save_commit, index_queue_status, secret_set/get/delete confirmed wired. VaultSetup.tsx + App.tsx startup gate + noteStore 1500ms debounce autosave confirmed. Tests: vault_setup.spec.tsx (3), domain_stores.spec.ts, ai_phase4.rs (3 vault/index/secret tests).
- 2026-02-19: **Phase 5 EAV verification complete (cortex-os#11).** ADR-0006 IMPLEMENTED — backend confirmed EAV-only (`pages` + `props` JSON column, no flat domain tables). Two schema CI-guard tests added (`no_flat_domain_tables_exist`, `pages_has_eav_columns_kind_and_props`). ADR-0006 updated with implementation notes (props-as-column vs props table deviation documented). Traceability FR-020 updated. All tests green.
- 2026-02-19: **Phase 5 gap audit complete.** Submodules initialized (were empty — root cause of broken UI). ADR gap analysis performed: all Phase 4 critical-path code confirmed present in component repo main branches (vault onboarding, VaultSetup.tsx, noteStore save-commit, secret encryption, index queue). 73 frontend tests + 18 backend storage tests all green. ADR-0011 status table retroactively updated to IMPLEMENTED (PR cortex-os#13). Phase 5 epics created: cortex-os#9 (spike gate), cortex-os#10 (vault onboarding), cortex-os#11 (EAV verification), cortex-os#12 (Google Calendar E2E). Open gaps deferred: Phase 2 issues (backend#6, frontend#3, contracts#2) still open; Google Calendar E2E (ADR-0014) unverified end-to-end. Submodule SHAs: backend `26f5f37`, frontend `1cb2041`, contracts `756fff1`.
- 2026-02-20: **Phase 5 Real AI Provider Adapters + Voice Pipeline completed (workspace pass).** Backend `cortex-app` routes `ai_transcribe` via `AISettings.stt_provider` (`local_whisper|openai|gemini`) and `ai_synthesize` via `AISettings.tts_provider` (`gemini|openai|local`) with real OpenAI/Gemini adapter transport in `crates/app/src/ai.rs`. **Follow-up policy update:** local Whisper runtime is deferred, and default STT is now online (`gemini`) until native runtime/model lifecycle implementation lands. Frontend `Settings` exposes STT/TTS provider selectors with provider-specific voice lists; backend/core `AISettings` includes provider fields. Contracts/docs updated (`002_IPC_WIRING_MATRIX.md`, `CONVENTIONS.md`, `CHANGELOG.md` 0.5.1). Verification: `cargo test -p cortex-app --lib`, `cargo test -p cortex-core`, `cargo test -p cortex-storage settings::tests::get_returns_default_when_missing`, `npm run lint`, and targeted Vitest AI/settings suites pass.
- 2026-02-20: **Integration pin sync after backend merge (`cortex-os-backend#28`).** `cortex-os` now tracks backend `4934ec1` on submodule `main` (voice provider adapters + routed STT/TTS). Release log updated in `docs/integration/002_RELEASE_PROCESS.md`; epic `cortex-os#14` closed.
- 2026-02-20: **Phase 5 card/file creation + Google UX reliability pass implemented (workspace).** Backend aligned IPC payload contracts (`vault_create_page` canonical `{ kind, props, body? }`, `capture_save` canonical `{ text }`), added markdown persistence for create/update/delete/save/travel/capture flows, and normalized travel status casing (`Planning|Booked|Completed`). Frontend rewired Travel Cards tab to live `tripCards` state and surfaced Google connect/list/sync credential/runtime failures in Settings with explicit `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` guidance. Contracts matrix and traceability docs updated for payload/side-effect alignment.
- 2026-02-20: **Integration pin sync after card/file + Google reliability merges.** `cortex-os` now tracks backend `c8fa5c6`, frontend `8f6493f`, contracts `9912069` on submodule `main`. Release log updated in `docs/integration/002_RELEASE_PROCESS.md` with FR-008/025/027/028 wiring and docs-sync details.
- 2026-02-20: **Runtime IPC command-arg casing fix pass implemented (workspace).** Frontend `services/backend.ts` now sends camelCase top-level invoke args expected by Tauri command parsing (`collectionId`, `pageId`, `taskId`, `tripId`, `startDate`, `endDate`, `projectId`, `itemId`, `editedJson`) and corresponding frontend smoke tests were updated. Backend week view query now accepts caller reference date for week windows (`calendar_get_week(start_date)` routed to `PageRepository::get_week_events(reference_date)`) with integration test coverage (`get_week_events_uses_reference_date_window`). UI reliability improvements added for Habits/Goals/Travel/WeekDashboard/Meals error surfacing and recipe-create flow.
- 2026-02-20: **Week planner/task editor/travel setup reliability pass implemented (workspace).** Frontend week view now supports drag-drop task scheduling with persisted refresh and an explicit event-detail save flow for date/time/location/description edits; task modal editing now uses local draft + explicit save to avoid per-keystroke persistence resets affecting TipTap/tags; Meals planner slot assignment now uses deterministic week-date mapping with in-context recipe creation flow; Travel new-trip flow now captures destination/date/duration/optional budget and derives itinerary days from trip metadata. Backend `travel_create_trip` now accepts optional `budget` and persists it into overview markdown + trip props. Contracts docs updated for `travel.createTrip budget?`; ADR-0016 added for future macro-tracking extension.
- 2026-02-20: **Frontend projects-board bug sweep merged + pinned.** Frontend PR `cortex-os-frontend#37` merged at `3039b12` (issues #27/#28/#30/#31/#32/#33/#34/#35): in-app project creation modal, project-filter diagnostics, functional master-task sort/group controls, and wired Projects-board task creation actions. Integration release log and traceability were updated alongside the submodule bump.
- 2026-02-20: **Task markdown/title persistence bug fixed and documented.** User-reported bug: TaskDetailModal edits appeared saved in-session but markdown/title did not persist to task cards after reload. Frontend fix shipped at `60daf9f`: `services/backend.ts` now sends task title via top-level `page_update_props.title` and persists markdown via `page_update_body` in the task update path; backend smoke regression coverage added. Integration docs updated (`docs/traceability.md`, `docs/integration/002_RELEASE_PROCESS.md`) and submodule pins refreshed.
- 2026-02-20: **ADR-0018 added (calendar platform evolution).** Proposed DayFlow integration with a centralized frontend calendar workspace that serves Day/Week/Month views, including continuous month navigation/scrolling, while preserving backend-owned Google OAuth/sync and two-way Cortex event reconciliation rules. FR-015 wording and traceability calendar notes were updated to reflect scope.
- 2026-02-20: **Integration pin sync for calendar hardening + ADR planning.** `cortex-os` now tracks backend `3680664`, frontend `a336452`, contracts `69b5609`; release log updated with calendar interaction hardening and ADR-0018 documentation sync.
- 2026-02-20: **ADR-0018 revised after upstream DayFlow source evaluation (`/Users/jdtarriela/proj/calendar`, `aca8f8f`).** Decision changed from direct migration to gated adoption with explicit checks for month virtualization performance, delta-based adapter sync, task/event drag semantics, Google mixed-permission policy, and a11y/keyboard/mobile parity. FR linkage expanded to include FR-017/FR-018.
- 2026-02-20: **ADR-0018 updated with DayFlow v3 boundary/plugin details.** Added explicit Preact core + React adapter content-slot boundary risks, mandatory plugin bootstrap (`@dayflow/plugin-drag`, `@dayflow/plugin-keyboard-shortcuts`), external HTML5 sidebar task-drop gate, and stronger mixed-editability requirement with upstream PR/fork path for per-event drag/resize permissions.
- 2026-02-20: **ADR-0018 risk reconciliation added.** Document now includes a risk-mitigation register (adapter complexity, Preact/React boundary, per-event permission model, upstream churn) with verification criteria and explicit fallback decisions.
- 2026-02-20: **ADR-0018 promoted to ACCEPTED and execution epics created.** GitHub epics opened in integration repo: `#23` (adapter foundation), `#24` (interaction parity/external drop), `#25` (mixed editability), `#26` (a11y/keyboard/responsive), `#27` (performance/upgrade governance).
- 2026-02-20: **Traceability plan updated for ADR-0018 execution.** `docs/traceability.md` now includes FR-row linkage updates (FR-001/015/017/018/027) and an explicit ADR-0018 Delivery Traceability table mapping epics -> FRs -> evidence targets.
- 2026-02-20: **ADR-0018 cross-repo child execution issues opened and linked.** Created 15 child issues across `cortex-os-frontend` (`#38-#42`), `cortex-os-backend` (`#29-#33`), and `cortex-os-contracts` (`#13-#17`) with detailed implementation instructions; parent epics `cortex-os#23-#27` now include child-checklist backlinks for bidirectional traceability.
- 2026-02-20: **ADR-0018 epic #23 completed (child execution closure).** Frontend child `cortex-os-frontend#38` closed at `9a213c5` (CalendarWorkspace hook, DayFlow adapter/plugin bootstrap, Week/Today controller wiring + tests). Backend child `cortex-os-backend#29` closed at `cd91dd7` (`calendar_get_range` command, storage range query, validation + integration tests). Contracts child `cortex-os-contracts#13` closed at `75f50e2` (IPC wiring matrix update, calendar range conventions/versioning/changelog sync). Parent epic `cortex-os#23` acceptance criteria were checked and closed with evidence links.
- 2026-02-20: **ADR-0018 E23 PR merge + integration pin sync complete.** Component PRs merged: `cortex-os-frontend#43` (`195e338`), `cortex-os-backend#34` (`9a4b77b`), `cortex-os-contracts#18` (`f28941b`). Integration repo submodules are pinned to these merged `main` SHAs; release log updated accordingly.
- 2026-02-20: **ADR-0018 epic #24 completed (E24 — Interaction Parity: External Task Drop + Drag/Resize).** Frontend child `cortex-os-frontend#39` closed at `f3a77f0`: `utils/calendarDropIntent.ts` maps DayFlow DOM `data-date`/time-grid offset to `DropIntent {date, allDay}`; `DayflowCalendarSurface.tsx` wires `onDrop` to `calendar.scheduleTask` (external drop) or `calendar.rescheduleEvent` (internal drag); `useDragDrop` updated with synchronous state and `dropEffect='copy'`; 143 tests green. Backend child `cortex-os-backend#30` closed at `b44f5d2`: `PageRepository::reschedule_event()` enforces read-only guard (FR-027); `calendar_schedule_task` and `calendar_reschedule_event` Tauri commands added; 4 TDD tests in `e24_drag_drop.rs`. Contracts child `cortex-os-contracts#14` closed at `ccff18e`: `calendar.scheduleTask` and `calendar.rescheduleEvent` rows + intent-mapping table added to IPC wiring matrix. Parent epic `cortex-os#24` closed. Submodules pinned: backend `b44f5d2`, frontend `f3a77f0`, contracts `ccff18e`.

- 2026-02-20: **ADR-0018 epic #24 frontend closure pass.** Frontend child `cortex-os-frontend#39` implemented externally mapped drag/drop via `calendarDropIntent` bounds checking against DayFlow DOM elements (`[data-date]` + `[data-timegrid="true"]`), preserving task/event update logic. Integration assertions added to `frontend/tests/calendar_sync.spec.ts` for task drop persistence correctness.
- 2026-02-20: **ADR-0018 epic #25 in review (E25 — Mixed Editability + Google Permission Enforcement).** Three PRs open: [contracts#20](https://github.com/jtarriela/cortex-os-contracts/pull/20) (`62717a3`): permission policy table + `readOnly` field + error semantics in IPC matrix. [backend#36](https://github.com/jtarriela/cortex-os-backend/pull/36) (`5db6632`): `is_read_only_event` helper, `update_calendar_event_props` + `delete_calendar_event` guarded storage methods, `calendar_event_is_editable` + `calendar_delete_event` IPC commands, 6 TDD tests in `e25_permissions.rs` (48 storage tests total). [frontend#45](https://github.com/jtarriela/cortex-os-frontend/pull/45) (`f2234f6`): `CalendarEvent.readOnly` field + adapter pipeline, `utils/calendarPermissions.ts` (`canEditEvent`/`canDeleteEvent`), pre-flight guards in all `useWeekDashboard` mutation paths (drag, resize, context-delete, DayFlow update/delete), `deleteCalendarEvent` routes through guarded command, visual state (opacity-60, cursor-not-allowed, tooltip), 10 new tests (153 total). ADR-0018 Gate 5 verification: per-event DayFlow drag/resize API unavailable upstream — guards applied at callback interception layer; no snap-back as steady-state UX. Pending SHA pin after merge.
- 2026-02-21: **ADR-0018 epic #27 implementation pass complete (E27 — Performance Benchmarks + Upgrade Governance) and moved to review.** Frontend child `cortex-os-frontend#42` now includes a reproducible DayFlow guardrail suite (`tests/perf/calendarMonthScroll.perf.test.ts`, `tests/calendar/dayflowAdapter.compat.spec.ts`, `tests/contracts/dayflowDependencyPolicy.spec.ts`) with CI step `npm run test:dayflow-guardrails`, plus upgrade checklist/PR template enforcement. Backend child `cortex-os-backend#33` adds migration `V4` calendar performance indexes (`idx_pages_calendar_kind_start_date`, `idx_pages_calendar_google_lookup`, `idx_pages_calendar_sync_source`), storage perf/query-plan harness (`crates/storage/tests/e27_performance.rs`), and bounded sync-run safeguards in `integrations_trigger_sync` with unit coverage (`enforce_sync_batch_limit_*`). Contracts child `cortex-os-contracts#17` adds calendar compatibility governance/checklists to `VERSIONING.md`, `CODEGEN.md`, and E27 notes in wiring matrix, with changelog version `0.6.1`. Integration traceability/ADR docs updated to reflect E27 in-review status; pending paired PR merge and SHA pin sync.
- 2026-02-21: **ADR-0018 epic #27 merged and pinned in integration repo.** Component PRs merged: `cortex-os-frontend#47` (`01e25af`), `cortex-os-backend#38` (`10c714b`), `cortex-os-contracts#22` (`821f2cc`). Integration release log/traceability/ADR gate statuses are now synchronized to completed, and the epic closure chain is complete: child issues `frontend#42`, `backend#33`, `contracts#17` and parent epic `cortex-os#27` closed.
