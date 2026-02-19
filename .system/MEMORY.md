
# MEMORY — Cortex OS (Integration)

## Current Focus
- Documentation reconciliation complete. Frontend is source of truth for features.
- Ready for Phase 1: Tauri IPC wiring (replace `dataService.ts` with `invoke()` calls).

## System State (Facts Only)
- Integration repo acting as workspace root.
- Submodules: frontend, backend, contracts.
- Frontend: Phase 0 — React 19 prototype with in-memory mock data, direct Gemini AI calls.
- Backend: Not yet implemented (architecture docs updated to match frontend features).
- Contracts: IPC wiring matrix updated with all frontend service endpoints.
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

## Functional Requirements
- 26 FRs defined in `docs/functional_requirements.md` (FR-001 through FR-026)
- All sourced from frontend implementation
- FR-020 through FR-022: Architectural goals (local-first, PII shield, HITL) — not yet implemented

## Recent Progress (Append-only)
- 2026-02-19: Documentation initialization.
- 2026-02-19: Init docs evaluated against frontend implementation; moved from `docs/init_docs/` → `docs/technical_architecture/` (001–004). Frontend has: Goals, Meals, Journal, AI voice/image gen, feature flags — not all in original init docs. Frontend lacks: Tauri IPC, vault filesystem, TipTap editor, Zustand, collection engine, SQLCipher.
- 2026-02-19: Created `frontend/docs/frontend_architecture/` (6 files: 000-005). Updated `docs/functional_requirements.md` (26 FRs). Updated `docs/traceability.md` (26 rows). Updated `backend/docs/backend_architecture/` (000, 001, 002). Updated `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`.
- 2026-02-19: Created ADR-0001 through ADR-0005 in `docs/adrs/`. Annotated `docs/technical_architecture/` (001–004) with Phase 0 Reality divergence sections. Updated traceability with ADR cross-references.
