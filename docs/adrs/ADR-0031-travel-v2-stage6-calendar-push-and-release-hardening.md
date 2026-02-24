# ADR-0031: Travel v2 Stage 6 — One-Way Calendar Push and Release Hardening

**Status:** IMPLEMENTED
**Date:** 2026-02-23
**Deciders:** Architecture review
**FR:** FR-008 (current baseline), FR-015, FR-026, FR-027 (integration touchpoints; travel FR expansion pending)
**Related:** ADR-0007 (schedule/calendar convergence), ADR-0012 (test strategy), ADR-0014 (Google Calendar integration), ADR-0017 (frontend hooks layer), ADR-0018 (DayFlow calendar workspace), ADR-0025 through ADR-0030 (Travel v2 stages 1-5), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md)

---

## Context

By Stage 6, Travel v2 is expected to include:

- structured travel entities
- itinerary + flights/lodging + budget
- map/routing
- imports (manual + Gmail)
- AI planning/optimization previews

The remaining major requirement is integration with the existing Calendar workspace without creating two competing sources of truth.

The agreed product behavior is:

- Travel remains the source of truth for trip itinerary planning
- Calendar receives a one-way projection/push for scheduled items

Stage 6 also serves as the release hardening gate for compatibility, export fallback behavior, and documentation/test evidence.

---

## Decision

Stage 6 delivers one-way Travel -> Calendar projection plus final hardening and rollout gates.

### 1) Calendar integration is one-way push (v1)

Travel itinerary items can create/update calendar entries, but Calendar edits do not synchronize back into Travel in Stage 6.

Travel remains canonical for:

- itinerary order
- travel-specific routing mode/leg choices
- travel planning metadata

### 2) Idempotent push behavior is required

Travel stores a calendar linkage field (for example `calendar_event_id`) so re-push actions can:

- create missing events
- update existing events (if user chooses overwrite)
- skip unchanged/already-linked entries

### 3) Push operates through existing calendar semantics

Calendar push must align with existing FR-015/FR-026 and Google sync permissions constraints from ADR-0014/ADR-0018.

Travel push should not bypass calendar permission rules or introduce ad hoc calendar state.

### 4) Stage 6 is the release hardening gate

Before Travel v2 rollout, Stage 6 includes:

- legacy compatibility verification (mixed `travel_card` + v2 data)
- RAG/search accessibility checks
- graceful-fail export UX checks (Google Maps Saved List unsupported path)
- API error handling and offline degradation checks
- docs/traceability/release sync completion

---

## Public Interface Additions (Stage 6)

Planned command:

- `travel.pushItemsToCalendar`

Response should report:

- created
- updated
- skipped
- errors

This enables deterministic frontend status messaging and retry flows.

---

## Release Hardening Gates

### Functional gates

1. Mixed legacy + v2 trip data loads and remains editable.
2. Imported reservations appear correctly in itinerary/budget and survive reload.
3. Travel items can be pushed to calendar with idempotent re-push behavior.
4. Google Maps export fallback path is explicit and user-actionable when Saved List export is unsupported.

### Reliability gates

1. Travel mutations remain index/RAG visible (parity with generic page mutation semantics).
2. Routing/import/Gmail/export network failures produce actionable UI errors without corrupting local trip data.
3. Offline mode supports local travel editing while disabling/retrying network-dependent features.

### Documentation gates

1. Contracts wiring matrix and changelog updated for all travel v2 commands.
2. `docs/functional_requirements.md` and `docs/traceability.md` synchronized for travel scope expansion.
3. `.system/MEMORY.md` and `docs/integration/002_RELEASE_PROCESS.md` updated with implementation and pin evidence.

---

## Exit Criteria (Stage 6 Done)

1. Users can one-way push itinerary items to Calendar and manage re-pushes safely.
2. Travel remains the source of truth; no implicit bi-directional sync behavior exists.
3. All release hardening gates above are green with test evidence.
4. Integration repo docs and submodule pins are synchronized after component PR merges.

---

## Consequences

### Positive

- Delivers practical calendar interoperability without bi-directional sync complexity
- Establishes a clear rollout gate for Travel v2 quality and documentation
- Preserves separation of concerns between Travel planning and Calendar scheduling

### Tradeoffs

- Calendar edits do not update Travel in v1
- Stage 6 bundles substantial QA/doc-sync work before rollout completion
