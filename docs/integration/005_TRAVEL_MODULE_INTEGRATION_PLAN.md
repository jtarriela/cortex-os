# 005 Travel Module Integration Plan (Staged ADR Program)

**Status:** PROPOSED  
**Date:** 2026-02-23  
**Scope:** Integration-level execution plan and ADR map for Travel Module v2 (Wanderlog-style planning workspace on Cortex architecture)

---

## 1) Purpose

This document captures the agreed Travel Module v2 direction and organizes implementation into staged ADRs.

It is the integration-level source for:

- stage sequencing
- cross-repo coordination expectations (frontend/backend/contracts)
- direct ADR dependencies (existing + new)
- shared constraints (RAG, Gmail scan policy, Google Maps export fallback behavior)

This document is intentionally implementation-facing and should be read alongside the stage ADRs listed below.

---

## 2) Product Direction (Locked)

Travel v2 will preserve a card-based planning experience while upgrading Cortex travel into an interactive trip-planning workspace:

- `Trip -> Location -> Items` hierarchy (Wanderlog-inspired UX)
- markdown-preserving cards and linked research notes
- itinerary timeline view
- map + route planning view (car / walk / transit)
- flights + lodging + single-user budget/expenses
- AI support for planning/inspiration and route/day optimization previews
- user-triggered Gmail reservation scanning (suggestions -> user-approved import)
- Google Maps export in sequence, with graceful fallback when direct Saved List export is unsupported

---

## 3) Core Constraints (Cross-Cutting)

### 3.1 Architecture

- Cortex remains **local-first**
- Markdown files remain source of truth
- EAV/page model remains canonical (`pages` + typed props)
- New travel entities must be first-class pages (`trip_location`, `trip_item`, `trip_expense`)

### 3.2 RAG / Search Accessibility (Hard Requirement)

Travel data must be RAG/search accessible.

All Travel v2 mutation paths must match `vault_create_page` / `page_update_*` behavior by:

- persisting markdown/page data
- emitting page lifecycle events
- enqueueing index jobs
- processing bounded index work

This includes:

- travel CRUD
- travel import commit flows
- Gmail reservation import commit flows
- legacy `travel_card` migration conversions

### 3.3 AI Write Safety

AI-derived structured travel imports and optimization suggestions must be previewed before persistence.

- no silent AI writes
- user approves/edits candidates before commit
- optimization is preview/apply, not autonomous mutation

### 3.4 Gmail Privacy (v1)

Gmail scan is user-triggered only. Cortex stores/indexes:

- structured extracted reservation data
- optional sanitized snippets

Cortex does **not** index raw email bodies/attachments by default in v1.

### 3.5 Google Maps Export (v1)

Direct write to personal Google Maps Saved Lists is treated as experimental / likely unsupported.

v1 must support:

- ordered Google Maps directions URL export
- ordered text/CSV/KML fallback
- graceful-fail UX for unsupported Saved List export requests

---

## 4) Stage ADR Program (Implementation Stages)

The following ADRs define each implementation stage directly.

| Stage | Focus | ADR |
|------|-------|-----|
| Stage 1 | Foundation data model, CRUD, workspace projection, legacy migration, RAG indexing parity | [`ADR-0025`](../adrs/ADR-0025-travel-v2-stage1-foundation-rag-indexing-and-migration.md) |
| Stage 2 | Itinerary timeline, flights/lodging, single-user budget + expenses | [`ADR-0026`](../adrs/ADR-0026-travel-v2-stage2-itinerary-flights-lodging-budget.md) |
| Stage 3 | Google Maps renderer, Google Routes routing, route caching, Google Maps export | [`ADR-0027`](../adrs/ADR-0027-travel-v2-stage3-maps-routing-and-google-export.md) |
| Stage 4A | URL/text/screenshot import preview + commit (AI-assisted, user-approved) | [`ADR-0028`](../adrs/ADR-0028-travel-v2-stage4a-web-text-screenshot-import.md) |
| Stage 4B | User-triggered Gmail reservation scan + import commit | [`ADR-0029`](../adrs/ADR-0029-travel-v2-stage4b-gmail-reservation-scan.md) |
| Stage 5 | AI copilot (inspiration + optimization previews, explicit apply) | [`ADR-0030`](../adrs/ADR-0030-travel-v2-stage5-ai-copilot-and-optimization-preview.md) |
| Stage 6 | One-way calendar push + release hardening + rollout gates | [`ADR-0031`](../adrs/ADR-0031-travel-v2-stage6-calendar-push-and-release-hardening.md) |

---

## 5) Direct ADR References for This Plan

These ADRs are directly referenced by this travel program and should be treated as active constraints/dependencies.

### 5.1 Existing ADRs (Prerequisites / Constraints)

| ADR | Why It Is Directly Relevant | Primary Stages |
|-----|-----------------------------|----------------|
| [`ADR-0004`](../adrs/ADR-0004-ai-multimodal-features.md) | AI multimodal capabilities and backend AI integration direction support screenshot/image-assisted travel import and planning assistance | 4A, 5 |
| [`ADR-0005`](../adrs/ADR-0005-frontend-agent-actions.md) | HITL / action patterns inform travel AI suggestion and approval-first UX | 4A, 4B, 5 |
| [`ADR-0006`](../adrs/ADR-0006-schema-strategy.md) | EAV/page schema and "Everything is a Page" constraint for travel entities | 1-6 |
| [`ADR-0007`](../adrs/ADR-0007-schedule-calendar-convergence.md) | Calendar/schedule semantics affect Travel -> Calendar push mapping | 6 |
| [`ADR-0012`](../adrs/ADR-0012-test-strategy.md) | TDD-first execution and evidence expectations | 1-6 |
| [`ADR-0014`](../adrs/ADR-0014-google-calendar-integration.md) | Existing Google auth/calendar sync architecture and permissions model | 6 |
| [`ADR-0015`](../adrs/ADR-0015-vault-onboarding-and-secure-settings.md) | Save-commit/indexing semantics and secure settings (API keys/tokens) | 1, 3, 4A, 4B |
| [`ADR-0017`](../adrs/ADR-0017-frontend-hooks-layer.md) | Travel UI must be refactored to hook/controller architecture | 1-6 |
| [`ADR-0018`](../adrs/ADR-0018-dayflow-calendar-integration.md) | Calendar workspace + DayFlow integration constraints for one-way travel push UX coordination | 6 |
| [`ADR-0019`](../adrs/ADR-0019-obsidian-linked-vault-by-path.md) | Linked-vault indexing and local RAG behavior inform travel-linked research note access | 1, 4A, 5 |
| [`ADR-0022`](../adrs/ADR-0022-vault-workbench-linked-writeback.md) | Linked note editing/writeback and markdown preservation for travel research workflows | 1, 4A, 5 |

### 5.2 New Stage ADRs (This Program)

| ADR | Stage | Role |
|-----|-------|------|
| [`ADR-0025`](../adrs/ADR-0025-travel-v2-stage1-foundation-rag-indexing-and-migration.md) | Stage 1 | Data model + migration + RAG indexing baseline |
| [`ADR-0026`](../adrs/ADR-0026-travel-v2-stage2-itinerary-flights-lodging-budget.md) | Stage 2 | Core travel planning workflow parity (itinerary/logistics/budget) |
| [`ADR-0027`](../adrs/ADR-0027-travel-v2-stage3-maps-routing-and-google-export.md) | Stage 3 | Maps/routing provider decisions and export behavior |
| [`ADR-0028`](../adrs/ADR-0028-travel-v2-stage4a-web-text-screenshot-import.md) | Stage 4A | AI-assisted manual import pipeline (URL/text/screenshot) |
| [`ADR-0029`](../adrs/ADR-0029-travel-v2-stage4b-gmail-reservation-scan.md) | Stage 4B | Gmail reservation ingestion policy and APIs |
| [`ADR-0030`](../adrs/ADR-0030-travel-v2-stage5-ai-copilot-and-optimization-preview.md) | Stage 5 | AI planner/copilot suggestion flows |
| [`ADR-0031`](../adrs/ADR-0031-travel-v2-stage6-calendar-push-and-release-hardening.md) | Stage 6 | Calendar projection + release readiness gates |

---

## 6) Cross-Repo Delivery Shape (Paired PR Expectations)

### `cortex-os-contracts`

- travel v2 command rows and request/response schemas
- legacy `travel_create_card` / `travel_get_itinerary` compatibility notes
- Google routing/export caveats documented
- Gmail scan preview/commit contracts documented

### `cortex-os-backend`

- travel service/module implementation
- page/path-safe nested travel writes
- route provider adapters and cache
- import preview/commit (AI-assisted)
- Gmail scan/import
- calendar push command
- index queue parity for all travel mutations

### `cortex-os-frontend`

- `Travel.tsx` refactor to ADR-0017-compliant controllers/hooks
- workspace UI (hierarchy, itinerary, map, budget, reservations, planner AI)
- export UX and graceful-fail fallbacks
- Gmail scan review/import UX

### `cortex-os` (integration)

- this integration plan
- stage ADRs
- FR/traceability updates when implementation starts
- `.system/MEMORY.md` progress log updates
- submodule pinning and release log entries after component merges

---

## 7) Stage Sequencing and Gating Rules

1. **Stage 1 is required before all later stages**
   - because it introduces canonical data model, projection APIs, and RAG indexing parity
2. **Stage 3 depends on Stage 2 item/time semantics**
   - route computation needs ordered/day-grouped item data
3. **Stage 4A should precede Stage 4B**
   - shared preview/commit import pipeline can be reused for Gmail candidates
4. **Stage 5 depends on Stage 2 + Stage 3**
   - AI optimization previews need itinerary semantics and routing metrics
5. **Stage 6 is the release hardening gate**
   - calendar push, final compatibility handling, and rollout evidence

---

## 8) Planned Follow-On Doc Sync (Not Performed Yet)

This document and the stage ADRs establish the plan. The following artifacts should be updated when implementation begins and interfaces are finalized:

- `docs/functional_requirements.md` (expand FR-008 and/or add travel FRs)
- `docs/traceability.md` (new rows for travel routing/import/budget/calendar push/AI planner)
- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`
- `contracts/CHANGELOG.md`
- `.system/MEMORY.md`

---

## 9) Status Notes

- This is a planning/program artifact set (`PROPOSED` ADRs).
- No implementation files or contracts are changed by this document alone.
- Direct Google Maps Saved List export is not assumed feasible in v1; graceful fallback is mandatory.

