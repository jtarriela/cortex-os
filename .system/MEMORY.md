
# MEMORY — Cortex OS (Integration)

## Current Focus
- **Phase 2 partial delivery for FR-027 is in progress.**
- Next action: complete full Google Calendar reconciliation semantics (update/delete propagation + conflict policy).

## System State (Facts Only)
- Integration repo acting as workspace root.
- Submodules: frontend, backend, contracts.
- Frontend: backend IPC is wired for core domains; settings integrations flow supports Google connect/calendar selection/sync trigger.
- Backend: Tauri app + SQLCipher storage + page repository implemented; Google OAuth + calendar list/create + incremental sync + outbound event creation are implemented.
- Contracts: IPC wiring matrix maintained in contracts repo; integration commands are documented.
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
- 27 FRs defined in `docs/functional_requirements.md` (FR-001 through FR-027)
- All sourced from frontend implementation
- FR-020 through FR-022: Architectural goals (local-first, PII shield, HITL) — not yet implemented

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
