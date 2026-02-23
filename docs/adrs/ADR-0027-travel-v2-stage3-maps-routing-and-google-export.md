# ADR-0027: Travel v2 Stage 3 — Maps, Routing, and Google Maps Export

**Status:** ACCEPTED
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-008 (current baseline; travel FR expansion pending)  
**Related:** ADR-0006 (EAV/page model), ADR-0012 (test strategy), ADR-0015 (secure settings), ADR-0017 (frontend hooks layer), ADR-0025 (Stage 1 foundation), ADR-0026 (Stage 2 itinerary/budget), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md), [`ADR-0027 Stage 3 Implementation Spec`](../implementation/ADR-0027-stage3-travel-maps-routing-google-export-implementation.md)

---

## Implementation Plan

Execution and review details for the ADR-0027 Stage 3 batch release live in:

- [`ADR-0027 Stage 3 Implementation Spec`](../implementation/ADR-0027-stage3-travel-maps-routing-google-export-implementation.md)

This document is the review-facing delivery specification (interfaces, atoms, tests, rollout, and cross-repo PR matrix) used to cross-reference code review discussions back to the accepted ADR decision.

---

## Context

Travel v2 needs in-app map/routing behavior to approximate the interactive Wanderlog experience:

- map visualization of locations/items
- route lines and ETA totals
- mode switching (`car`, `walk`, `transit`)
- ordered export to Google Maps

Product decision for the first major release:

- **Google Routes/Maps** is the routing/map stack
- route planning is **manual order + in-app ETAs + route lines**
- no full auto optimizer in this stage

---

## Decision

Stage 3 introduces Google-backed routing and map rendering behind Cortex-owned abstractions.

### 1) Map renderer: Google Maps JS

Frontend Travel map view uses Google Maps JS for:

- marker rendering
- route polyline overlays
- viewport fit and focus interactions
- layer toggles (day/type filters)

### 2) Routing provider: Google Routes API (backend)

Backend computes routes via a travel routing adapter over Google Routes API and exposes travel-specific route commands.

Travel UI does not call Google APIs directly.

### 3) Transit routes are computed per leg and stitched

Because transit route support does not provide the same waypoint behavior as driving/walking for multi-stop day itineraries, Cortex computes transit routes per adjacent stop pair and stitches the result into one day route plan response.

### 4) Route caching is mandatory

To reduce cost and improve responsiveness, route results are cached by normalized keys (origin/destination/mode/time/options/provider version).

### 5) Google Maps export supports graceful fallback

Stage 3 provides an ordered export surface with:

- directions URL export (guaranteed)
- CSV/KML fallback (guaranteed)
- Saved List export target as experimental; unsupported responses must return explicit fallback actions

No silent failures are allowed.

---

## Public Interface Additions (Stage 3)

Planned commands:

- `travel.routeComputeLeg`
- `travel.routeComputeDay`
- `travel.exportGoogleMaps`

Expected `travel.exportGoogleMaps.target` values:

- `directions_urls`
- `saved_list_experimental`
- `my_maps_file`

The response model must support explicit unsupported/graceful-fail returns with fallback payloads.

---

## Operational / Cost Controls

- Google API keys stored via secure settings path (ADR-0015 alignment)
- quota and billing errors normalized into actionable backend error messages
- route recompute should be explicit or debounced; not every UI interaction may trigger network recomputation

---

## Exit Criteria (Stage 3 Done)

1. Users can view trip items on an embedded map and compute in-app routes for car/walk/transit.
2. Transit routing works for multi-stop itineraries via per-leg stitched responses.
3. Route cache is active and observable in backend logs/tests.
4. `Export to Google Maps` preserves sequence and supports graceful fallback for unsupported saved-list exports.
5. Backend/frontend/contracts documentation is synchronized for route and export command semantics.

---

## Consequences

### Positive

- Delivers the core interactive travel planning differentiator (map + routing)
- Keeps provider logic swappable behind backend travel commands later if needed
- Makes Stage 5 AI optimization previews materially useful

### Tradeoffs

- Introduces Google Maps billing/quota dependency
- Adds backend complexity for caching and transit leg stitching
- Requires robust error UX for unsupported export targets and provider failures
