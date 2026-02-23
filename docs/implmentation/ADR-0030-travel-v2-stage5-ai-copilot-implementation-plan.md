# Travel v2 Stage 5 (ADR-0030) — Implementation Plan (Local Workspace Draft)

**Status:** Planned  
**Date:** 2026-02-23  
**ADR:** [`ADR-0030`](../adrs/ADR-0030-travel-v2-stage5-ai-copilot-and-optimization-preview.md)  
**FR Baseline:** `FR-008` (Travel planner; staged expansion in progress)  
**Related:** [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md), ADR-0026, ADR-0027, ADR-0028, ADR-0029, ADR-0017, ADR-0012

---

## Purpose

This document is a docs-first implementation plan for **Travel v2 Stage 5** (AI copilot for inspiration + optimization previews with explicit apply).

It is intentionally stored in `docs/implmentation/` (local workspace planning/audit path used in recent ADR work) to provide a durable execution plan before paired PRs are opened in:

- `cortex-os-contracts`
- `cortex-os-backend`
- `cortex-os-frontend`

No runtime behavior is changed by this document alone.

---

## Summary

Stage 5 adds a Travel planner/copilot UX that can:

- generate inspiration ideas scoped to a trip/location/day
- generate a **day optimization preview** (reorder-first v1 + warnings + rationale)
- allow users to **explicitly apply** accepted changes through existing Travel mutation commands

The implementation remains **suggestion-first**:

- no autonomous AI writes
- no new "AI mutate travel" command
- failed AI calls must not block manual planning/routing/import flows

### Stage 5 v1 Defaults (Locked)

- **Apply behavior:** `Apply All Preview Changes` only
- **Optimization scope:** `reorder-first` (retime suggestions are informational only and not applyable in v1)
- **Preview freshness guard:** explicit response `applyGuard` payload validated before apply

---

## Scope

### In Scope (Stage 5 v1)

- New Travel AI planner preview commands:
  - `travel.aiSuggestIdeas`
  - `travel.optimizeDayPlanPreview`
- Structured preview payloads (suggestions, warnings, rationale, diff-style changes)
- Travel planner/copilot panel in the Travel workspace
- Explicit **apply-all** workflow using existing Travel CRUD/reorder/move/update commands
- Clear UI distinction between preview state and persisted state
- Contracts/backend/frontend docs sync and traceability updates when implementation starts
- Tests for command contracts, backend preview logic, frontend controller/apply flows

### Out of Scope (Stage 5 v1)

- Autonomous AI writes or background agent behavior
- New `travel.aiApply*` mutation commands
- Per-change selective apply UI
- Multi-day/global-trip optimization engine (Stage 5 targets **day-level preview** first)
- Applyable retiming / schedule-time rewrites (retime may appear as informational suggestion only)
- Calendar push (Stage 6 / ADR-0031)
- Provider-specific quality tuning beyond bounded prompt/schema validation
- Full generic chat integration (Stage 5 uses a dedicated Travel planner panel)

---

## Preconditions and Dependencies

### Hard Dependencies (per ADR/integration plan)

- **Stage 2 (ADR-0026)** itinerary semantics (day grouping, item ordering, flights/lodging/budget data model)
- **Stage 3 (ADR-0027)** route metrics/maps foundations (route day/leg compute, provider status, coordinate resolution)

### Optional/Value-Add Inputs (not required to ship Stage 5)

- **Stage 4A (ADR-0028)** manual import previews/commits can enrich trip context
- **Stage 4B (ADR-0029)** Gmail reservation imports can enrich logistics context

Stage 5 should still function if Stage 4A/4B data is absent.

### Existing Architectural Constraints

- Markdown/page model remains source of truth
- Travel AI results are previews only until explicit user apply
- Frontend must follow ADR-0017 hooks/controller governance
- TDD / interface-first / paired-PR protocol applies

---

## User-Facing Behaviors (Planned)

1. A user opens a trip in Travel and accesses a Planner/Copilot panel.
2. A user requests inspiration ideas for a trip, location, or day and receives structured suggestions with rationale.
3. A user requests a day optimization preview and receives:
   - proposed ordering changes (plus optional informational timing guidance)
   - warnings/constraint conflicts
   - route/efficiency summary deltas (when available)
   - rationale/explanation text
4. The UI clearly marks the result as **Preview** (not yet applied).
5. The user can explicitly apply accepted optimization changes.
6. Applying suggestions uses existing Travel mutation commands (primarily `travel.reorderItems` in Stage 5 v1; no AI write command).
7. If AI provider calls fail, the rest of Travel (manual itinerary editing, maps, import, budget) continues to work.

---

## Interface/Contract Plan (Lock in `cortex-os-contracts` First)

Stage 5 requires **new preview commands** and structured response docs in the IPC wiring matrix. Names below follow ADR-0030.

### 1) `travel.aiSuggestIdeas` (new, preview-only)

#### Request (planned)

- `tripId: string`
- `locationId?: string`
- `dayDate?: string` (`YYYY-MM-DD`)
- `prompt?: string` (optional freeform user intent, e.g. "rainy day ideas")
- `constraints?: TravelAiIdeaConstraints`
- `maxSuggestions?: number` (bounded; backend clamps)

#### Response (planned)

- `responseMode: "full" | "degraded"` (`degraded` only when non-critical enrichment fails)
- `suggestions: TravelAiIdeaSuggestion[]`
- `warnings: string[]`
- `rationale?: string`
- `contextSummary?: string` (brief summary of what the AI considered)
- `provider?: string` (provider/model identifier or normalized label)
- `previewGeneratedAt: string` (ISO timestamp)

#### `TravelAiIdeaSuggestion` (planned fields)

- `id: string` (preview-local stable id)
- `title: string`
- `kind: "activity" | "food" | "sight" | "logistics" | "freeform"`
- `summary?: string`
- `recommendedDayDate?: string`
- `recommendedLocationId?: string`
- `estimatedDurationMinutes?: number`
- `estimatedCost?: number`
- `currency?: string`
- `tags?: string[]`
- `rationale?: string`
- `warnings?: string[]`
- `proposedItemDraft?: object` (bounded structure for optional "create item from idea" future compatibility; preview only)

#### Semantics

- Preview-only; no page writes, no index jobs
- Backend may use structured trip context + linked note/RAG snippets + imported reservation summaries
- Response must be schema-validated and bounded (size/count caps)
- Failure behavior (locked):
  - If the provider call fails or the AI payload cannot be validated, return a contract-compliant command error (no partial ideas response)
  - `responseMode="degraded"` is only for non-critical enrichment loss (e.g., RAG snippet fetch timeout) when core idea suggestions are still valid

### 2) `travel.optimizeDayPlanPreview` (new, preview-only)

#### Request (planned)

- `tripId: string`
- `dayDate: string` (`YYYY-MM-DD`)
- `itemIds?: string[]` (optional subset; defaults to routeable/plannable day items)
- `strategy?: "balanced" | "min_travel" | "relaxed" | "packed"` (backend may normalize unsupported values)
- `startTime?: string` (`HH:MM`, optional)
- `endTime?: string` (`HH:MM`, optional)
- `constraints?: TravelDayOptimizationConstraints`
- `includeRoutingMetrics?: boolean` (default `true`)

#### Stage 5 v1 request semantics (locked)

- Optimization is **reorder-first** for the selected day.
- `startTime` / `endTime` may influence ranking/rationale, but Stage 5 v1 does not produce applyable retime changes.
- If `itemIds` is omitted, backend targets the day’s plannable/routable items in current persisted order.

#### Response (planned)

- `dayDate: string`
- `responseMode: "full" | "degraded_deterministic"` (`degraded_deterministic` when deterministic preview succeeds but AI rationale/enrichment fails)
- `previewMode: "reorder_first_v1"`
- `basePlan: TravelDayPlanSnapshot`
- `proposedPlan: TravelDayPlanSnapshot`
- `changes: TravelDayOptimizationChange[]` (diff-style preview payload; v1 supports `reorder` + `note` only)
- `applyGuard: TravelDayOptimizationApplyGuard`
- `warnings: string[]`
- `constraintConflicts: string[]`
- `rationale?: string`
- `alternatives?: TravelDayOptimizationAlternative[]`
- `provider?: string`
- `previewGeneratedAt: string`

#### `TravelDayOptimizationChange` (diff-style)

Each change should be structured so the frontend can render a diff and map accepted changes to existing commands.

Stage 5 v1 uses a **typed union** (decision locked):

- `TravelDayOptimizationReorderChange`
- `TravelDayOptimizationNoteChange`

##### `TravelDayOptimizationReorderChange` (v1 applyable)

- `changeId: string`
- `changeType: "reorder"`
- `itemId: string`
- `beforeOrderIndex: number`
- `afterOrderIndex: number`
- `beforePrevItemId?: string`
- `afterPrevItemId?: string`
- `summary: string`
- `severity?: "info" | "warning"`
- `applyHints?: string[]`

##### `TravelDayOptimizationNoteChange` (v1 informational only)

- `changeId: string`
- `changeType: "note"`
- `summary: string`
- `severity?: "info" | "warning"`
- `appliable: false`
- `noteKind: "retime_deferred" | "constraint" | "missing_data" | "provider_degraded"`
- `itemId?: string`
- `details?: string`

#### `TravelDayOptimizationApplyGuard` (stale-preview protection, locked)

Returned with every optimization preview; frontend must validate before apply.

- `tripId: string`
- `dayDate: string`
- `sourceOrderedItemIds: string[]`
- `sourceItems: Array<{ itemId: string; locationId?: string; dayDate?: string; orderIndex?: number; startTime?: string; endTime?: string }>`
- `snapshotHash: string` (backend-generated deterministic hash over the source day subset)

#### Semantics

- Preview-only; no page writes, no direct mutations
- Must combine deterministic travel data (itinerary order, route metrics, known times) with AI rationale/suggestions
- Returns enough structure for:
  - visual preview diff
  - explicit apply via existing Travel commands
- Failure behavior (locked):
  - If deterministic day snapshot/diff generation fails, return a contract-compliant command error
  - If deterministic preview succeeds but AI rationale/enrichment fails, return success with `responseMode="degraded_deterministic"` and warnings
  - Stage 5 v1 may emit informational retime suggestions only as `note` changes; no applyable retime change type is returned

### 3) No new AI mutation command (explicit non-goal)

Contracts docs must explicitly note:

- Stage 5 **does not** add `travel.aiApply*` or equivalent write commands
- accepted suggestions are applied via standard Travel mutation IPC commands

### 4) Contracts Doc Updates Required

- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`
  - add rows for both new commands
  - document preview-only semantics
  - document explicit apply via existing commands
  - document failure/non-blocking behavior notes
- `contracts/CHANGELOG.md`
  - add Stage 5 command docs entry (version per contracts repo policy)

---

## Backend Design Plan (`cortex-os-backend`)

### High-Level Shape

Add a Travel AI planner service layer that builds **bounded previews** from existing Travel workspace/routing data.

Planned code organization (names may vary during implementation):

- `backend/crates/app/src/travel_ai.rs` or `travel_planner_ai.rs`
  - prompt/context assembly
  - schema validation for AI responses
  - preview result builders
- `backend/crates/app/src/lib.rs`
  - Tauri command handlers:
    - `travel_ai_suggest_ideas`
    - `travel_optimize_day_plan_preview`
- Reuse existing travel routing/import utilities where possible instead of duplicating logic

### Backend Data/Type Definitions to Add (planned)

- `TravelAiSuggestIdeasRequest/Response`
- `TravelOptimizeDayPlanPreviewRequest/Response`
- `TravelDayPlanSnapshot`
- `TravelDayOptimizationReorderChange`
- `TravelDayOptimizationNoteChange`
- `TravelDayOptimizationApplyGuard`
- `TravelDayOptimizationChange` (enum/union)

`TravelDayPlanSnapshot` should include at minimum:

- `orderedItemIds: string[]`
- `items: Array<{ itemId: string; title: string; locationId?: string; dayDate?: string; orderIndex?: number; startTime?: string; endTime?: string }>`
- `routeSummary?: { totalDistanceMeters?: number; totalDurationSeconds?: number; mode?: string }`

### Backend Responsibilities

#### A) Context hydration (read-only)

- Load trip workspace (`trip`, `locations`, `items`, `expenses`) as needed
- Filter to requested scope (trip/location/day)
- Extract day itinerary sequence and item timing metadata
- Optionally include imported reservation summaries/provenance (if present)
- Optionally include linked note/RAG snippets (bounded tokens/records)

#### B) Deterministic optimization baseline (for `optimizeDayPlanPreview`)

Before/alongside AI:

- compute baseline ordered day snapshot
- reuse existing Stage 3 route metrics where available (or compute route summary via existing internals)
- validate hard constraints (pinned times, non-movable items, missing coordinates, etc.)
- generate a deterministic candidate plan skeleton and measurable deltas

AI then augments:

- rationale/explanation
- alternative suggestions
- optional soft adjustments within constraints

This preserves predictable behavior and testability.

#### C) Preview diff generation

Generate a structured diff (`changes[]`) between base and proposed day plan:

- reorder changes (applyable in v1)
- informational notes for retime/constraint/provider issues (not applyable in v1)
- non-applicable suggestions surfaced as warnings/`note` changes (not silent drops)

Diff output should be deterministic for the same input snapshot and strategy (except provider-rationale text).

#### D) Freshness/apply guard generation (locked)

For `travel.optimizeDayPlanPreview`, backend returns `applyGuard` derived from the exact day subset used to compute the preview.

Frontend must treat the preview as stale if any of the following differ before apply:

- day ordered item ids
- item day/location/order fields
- item start/end time fields (even though retime is not applyable in v1, time changes can invalidate routing/rationale)
- `snapshotHash`

#### E) Safety and resilience

- Schema-validate AI output before mapping into response types
- Clamp list sizes / text lengths / optional fields
- Return warnings for partial degradation (e.g., missing coords, provider unavailable)
- Never persist travel pages from Stage 5 preview commands

### Backend Testing Plan (TDD)

#### Red tests first

- `travel.aiSuggestIdeas` returns preview-only structured result (no writes)
- `travel.optimizeDayPlanPreview` returns diff-style changes for reorder + informational-note cases
- `travel.optimizeDayPlanPreview` returns `reorder` + `note` change unions only (no applyable retime changes in v1)
- hard constraints are preserved (no illegal move suggestions)
- missing route data/coordinates produces warnings, not command failure (where applicable)
- provider/AI parse failure degrades gracefully (deterministic preview or structured error)
- `applyGuard.snapshotHash` is deterministic for the same source day snapshot
- preview commands do not enqueue indexing work / page mutations

#### Green implementation

- minimal command handlers + service wiring
- deterministic diff builder
- bounded AI response mapping

#### Refactor

- extract shared travel-day snapshot builders
- centralize schema validation/error normalization

---

## Frontend Design Plan (`cortex-os-frontend`)

### ADR-0017 Hook/Controller Compliance (Required)

Travel view changes must use controller hooks.

Planned additions:

- `frontend/hooks/useTravelPlannerCopilot.ts` (new)
  - owns planner request state (`ideas`, `optimizationPreview`, loading/error)
  - owns preview freshness validation (`applyGuard` check against current workspace day subset)
  - owns **apply-all** orchestration using existing travel mutation commands only
  - owns post-apply refresh + stale/applied state transitions
  - composes existing travel workspace + route planner hooks/data as needed
- `frontend/views/Travel.tsx`
  - integrates Planner/Copilot panel/tab via hook/controller
  - no direct backend service imports
- `frontend/tests/hooks/useTravelPlannerCopilot.test.ts`

Potential UI components (exact names may vary):

- `frontend/components/travel/TravelPlannerCopilotPanel.tsx`
- `frontend/components/travel/TravelIdeaSuggestionList.tsx`
- `frontend/components/travel/TravelOptimizationPreviewPanel.tsx`
- `frontend/components/travel/TravelOptimizationDiffList.tsx`

### UX/State Requirements

#### A) Preview clarity

- Show clear **Preview** badge/state before apply
- Distinguish persisted itinerary data from proposed changes
- Allow dismiss/reset preview without mutating trip data

#### B) Explicit apply flow (required)

Stage 5 v1 apply is locked to **Apply All Preview Changes** only. Per-change apply is deferred.

Apply flow:

1. Re-read current day subset from `useTravelWorkspace` state
2. Validate `applyGuard` (`sourceOrderedItemIds`, item field guards, `snapshotHash`) against current day subset
3. If guard fails: mark preview stale, block apply, prompt user to regenerate preview
4. Execute existing travel mutation commands in deterministic order (reorder-first v1)
5. Refresh workspace projection
6. Mark preview as applied or stale

Planned command usage examples:

- `travel.moveItem` for location/day/order metadata shifts
- `travel.reorderItems` for final ordering normalization

Stage 5 v1 default apply strategy (locked):

- Prefer a single `travel.reorderItems` call for same-day reorder previews when sufficient
- Use `travel.moveItem` only when backend preview includes location/day metadata changes in future phases (not expected in v1 reorder-first)
- Do not call `travel.updateItem` for retime suggestions in v1 (retime is informational-only)

No new AI write command is introduced.

#### C) Non-blocking failure behavior

- AI request errors surface inline in planner panel
- Manual Travel tabs/panels remain usable
- Apply failures report partial progress and keep manual editing available

### Frontend Testing Plan (TDD)

- Hook test: planner request state transitions (`idle -> loading -> preview/error`)
- Hook test: optimize preview state stores `applyGuard` and `previewMode="reorder_first_v1"`
- Hook test: apply-all flow uses existing travel mutation methods (not new AI write call)
- Hook test: stale-preview guard blocks apply and prompts preview regeneration
- View/component tests:
  - preview label/marker renders
  - warnings/conflicts render
  - informational `note` changes render as non-applyable rows
  - apply button gating (disabled without preview / while applying)
- Backend smoke test updates for new command wiring in `frontend/services/backend*`

---

## Apply Mapping Strategy (Preview -> Existing Mutations)

Stage 5 succeeds only if preview output can be **reliably applied** through existing Travel commands.

### Planned mapping approach

- Backend returns `changes[]` as typed union (`reorder` / `note` in v1) plus `applyGuard`
- Frontend converts changes into a sequenced mutation plan using existing APIs
- Frontend applies mutations in safe order:
  1. stale guard validation
  2. reorder normalization (`travel.reorderItems`)
  3. workspace refresh and preview invalidation

### Rules

- If a change cannot be mapped safely to existing commands, it must be presented as a warning/non-applicable note in preview
- No hidden best-effort writes for unsupported change shapes
- Apply action must be idempotent enough to retry after refresh when possible
- Stage 5 v1 applies only `changeType="reorder"`; `note` changes are display-only

---

## TDD Execution Plan by Repo (Paired PR Program)

### `cortex-os-contracts` (Interface-First)

#### Tasks

- Add wiring matrix rows for:
  - `travel.aiSuggestIdeas`
  - `travel.optimizeDayPlanPreview`
- Document preview-only semantics + explicit apply via standard travel mutation commands
- Add versioned changelog entry

#### Verification

- Field naming consistency (camelCase)
- Response docs include typed `changes[]` union, `applyGuard`, warnings, rationale, response mode semantics
- Explicit no-AI-write note included

### `cortex-os-backend`

#### Red (tests first)

- command result shape tests for both Stage 5 commands
- preview-only (no persistence) regression tests
- deterministic diff generation tests
- constraint preservation tests
- degraded mode/provider failure tests
- ideas command error vs degraded-enrichment semantics tests
- optimize command `degraded_deterministic` success semantics tests

#### Green

- command handlers in `crates/app/src/lib.rs`
- Travel AI preview service module + serializers
- reuse of travel workspace/routing internals for deterministic inputs

#### Refactor

- shared snapshot/diff utilities
- prompt/schema helpers extracted for maintainability

### `cortex-os-frontend`

#### Red (tests first)

- `useTravelPlannerCopilot` hook tests (request/apply/stale/error)
- UI tests for preview/apply/warnings display
- backend smoke tests for new command client wrappers
- client types/tests for `TravelDayOptimizationChange` union + `applyGuard`

#### Green

- backend service wrappers/types
- hook/controller
- planner panel UI integration in `Travel.tsx`

#### Refactor

- component extraction for diff/warnings lists
- shared type narrowing/normalization helpers

### `cortex-os` (integration docs)

Update when implementation begins / lands:

- `docs/functional_requirements.md` (FR-008 expansion for Travel AI planner preview/apply semantics)
- `docs/traceability.md` (Stage 5 commands, hook, UI, backend modules/tests)
- `.system/MEMORY.md` (active focus/progress + paired PR links + pinning follow-up)
- `docs/adrs/ADR-0030-*.md`
  - `PROPOSED -> ACCEPTED` when implementation starts
  - `ACCEPTED -> IMPLEMENTED` when shipped with evidence

---

## Suggested Atomic Delivery Sequence (<= ~50 LoC logic slices where feasible)

1. **Contracts atom 1**
   - Add `travel.aiSuggestIdeas` wiring row + preview semantics notes.
2. **Contracts atom 2**
   - Add `travel.optimizeDayPlanPreview` row + diff/change response docs + changelog.
3. **Backend atom 1**
   - Command scaffolds + stubbed preview responses behind tests (shape + no-write guarantees).
4. **Backend atom 2**
   - Day snapshot builder + deterministic diff generator for reorder-only previews.
5. **Backend atom 3**
   - AI rationale integration + schema validation + degraded warning path.
6. **Backend atom 4**
   - Idea suggestion preview command with bounded structured output.
7. **Frontend atom 1**
   - Service client wrappers + types + smoke tests.
8. **Frontend atom 2**
   - `useTravelPlannerCopilot` hook request state + preview rendering (stores `applyGuard`; no apply yet).
9. **Frontend atom 3**
   - Explicit apply-all flow mapped to existing travel mutation commands with stale-guard validation.
10. **Frontend atom 4**
   - UX polish for warnings/conflicts/stale preview handling.
11. **Integration doc-sync atom**
   - FR/traceability/MEMORY + ADR status updates + paired PR links.

---

## Validation / Evidence Expectations

Before marking ADR-0030 `IMPLEMENTED`, collect evidence from paired repos:

- Contracts docs updated (`002_IPC_WIRING_MATRIX.md`, `CHANGELOG.md`)
- Backend tests covering preview-only behavior + diff generation + degraded mode
- Frontend tests covering controller/apply flow + preview labeling
- Frontend tests covering stale-preview blocking and informational-only `note` changes
- Manual verification:
  - ideas preview works on a trip
  - optimize preview shows diff/warnings
  - apply path updates itinerary using standard commands
  - manual planning still works when AI provider is unavailable

---

## Risks and Mitigations

### Risk: AI output unpredictability breaks preview/apply mapping

- Mitigation: strict schema validation + bounded enums + backend-generated normalized `changes[]`

### Risk: Optimization preview suggests illegal/conflicting itinerary moves

- Mitigation: deterministic constraint checks before AI output is accepted; conflicts returned as warnings

### Risk: Apply flow becomes flaky due to stale data

- Mitigation: required `applyGuard` + `snapshotHash` validation before apply + re-fetch workspace + clear stale-preview UX

### Risk: Stage 5 scope expands into generic travel agent/chat

- Mitigation: keep Stage 5 to dedicated panel + two explicit commands only

---

## Exit Criteria Mapping (ADR-0030)

1. **Ideas/inspiration scoped to trip/location**
   - delivered by `travel.aiSuggestIdeas` + planner UI
2. **Optimization preview for day itinerary**
   - delivered by `travel.optimizeDayPlanPreview` + diff/warnings UI
3. **Accepted suggestions applied through standard travel mutations**
   - delivered by frontend apply orchestration using existing Travel commands
4. **UI distinguishes preview vs persisted**
   - delivered by explicit preview state/badges and post-apply refresh behavior
5. **Docs synchronized**
   - contracts/backend/frontend/integration docs updated with traceability and ADR status

---

## Notes for Implementation Kickoff

- This plan intentionally does **not** change ADR-0030 status yet.
- When coding starts, update ADR-0030 to `ACCEPTED` in the same PR set.
- If command names or response shapes differ during contract review, this plan should be updated first (docs-first correction) before deeper implementation proceeds.

---

## Assumptions and Defaults (Explicit)

- Stage 5 v1 ships a dedicated Travel planner panel, not generic chat integration.
- `travel.optimizeDayPlanPreview` is reorder-first only for applyable changes in v1.
- Retime suggestions, if generated, are informational-only and encoded as `note` changes.
- Frontend apply in v1 is **Apply All** only.
- Preview freshness is enforced via `applyGuard` comparison before apply; stale previews are never auto-applied.
- Manual Travel workflows remain available regardless of AI command failures.
