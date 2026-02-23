# ADR-0027 Stage 3 Implementation Spec — Travel Maps, Routing, and Google Export

**ADR:** [`ADR-0027`](../adrs/ADR-0027-travel-v2-stage3-maps-routing-and-google-export.md)  
**Status:** Execution kickoff (implementation started)  
**Date:** 2026-02-23  
**Parent issue:** `cortex-os#35`  
**Child issues:** `cortex-os-contracts#25`, `cortex-os-backend#41`, `cortex-os-frontend#50`

This document is the review-facing implementation specification for ADR-0027 Stage 3. It captures the concrete interfaces, architecture, test plan, rollout sequence, and cross-repo PR matrix so later code review can cross-reference design intent against implementation diffs.

---

## 1) Scope and Non-Goals

### In Scope (Stage 3)

- Embedded map rendering in Travel UI (Google Maps JS)
- Backend route computation (Google Routes API) for `car`, `walk`, `transit`
- Transit day-route stitching via per-leg routing and stitched day response
- Mandatory route cache (plus geocode cache supporting waypoint resolution)
- `Export to Google Maps` ordered export surface with explicit graceful fallback
- Settings → Integrations Travel Google key management (secure secret store backed)
- Contracts/docs/traceability synchronization across repos

### Non-Goals (Stage 3)

- Automatic route optimization / reordering (manual order is preserved)
- Guaranteed direct Google Saved List write integration (experimental target returns explicit fallback when unsupported)
- Frontend direct Google API calls for routing/geocoding (backend-only provider calls)

---

## 2) Cross-Repo PR Matrix (Batch Release)

| Repo | Issue | Branch | Responsibility | PR (to fill) |
|------|------:|--------|----------------|--------------|
| `cortex-os-contracts` | #25 | `codex/issue-25-adr-0027-stage3-travel-routing-export-contracts` | IPC command rows, request/response docs, fallback semantics, changelog | _TBD_ |
| `cortex-os-backend` | #41 | `codex/issue-41-adr-0027-stage3-travel-routing-backend` | Routes/geocoding adapters, cache, export generation, route/resolve commands | _TBD_ |
| `cortex-os-frontend` | #50 | `codex/issue-50-adr-0027-stage3-travel-maps-export-ui` | Travel map tab, routing/export hook + UI, settings keys UI, type/client updates | _TBD_ |
| `cortex-os` | #35 | `codex/issue-35-adr-0027-stage3-travel-maps-routing-export` | ADR cross-ref/status, MEMORY, FR/traceability, final pinning/release log | _TBD_ |

### Merge Order / Gating

1. Contracts PR merges first (authoritative interface surface)
2. Backend PR merges second (command implementation)
3. Frontend PR merges third (consumes stable backend/contracts surface)
4. Integration PR merges last (submodule pins + docs sync)

### Gating Rules

- Paired PRs must be cross-linked in all PR bodies
- ADR-0027 status change (`PROPOSED` -> `ACCEPTED`) lands in integration kickoff commit/PR
- Final integration PR cannot merge until contracts/backend/frontend PRs are merged and SHAs are pinned

---

## 3) Public Interfaces (Contract-First)

### New/Updated IPC Commands (Contracts Repo Canonical Docs)

Add the following Travel Stage 3 commands to `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`.

1. `travel.routeComputeLeg`
2. `travel.routeComputeDay`
3. `travel.exportGoogleMaps`
4. `travel.resolveMapWaypoints` (supporting command for explicit coordinate resolution)
5. `travel.getMapsProviderStatus`
6. `travel.getMapsJsConfig`

### `travel.exportGoogleMaps.target` values (ADR-aligned)

- `directions_urls`
- `saved_list_experimental`
- `my_maps_file`

### Request / Response Shape Intent (Summary)

#### `travel.routeComputeLeg`
- Request: `tripId`, `mode`, `from`, `to`, `departAt?`, `useCache?`
- Response: single-leg route summary (`distance`, `duration`, `polyline`, `warnings[]`, `cache`)

#### `travel.routeComputeDay`
- Request: `tripId`, `dayDate`, `mode`, `waypointItemIds[]`, `departAt?`, `useCache?`
- Response: ordered day route (`waypoints[]`, `legs[]`, `totals`, `stitchedTransit`, `warnings[]`, `cacheStats`)

#### `travel.exportGoogleMaps`
- Request: `tripId`, `target`, `dayDate?`, `waypointItemIds[]`, `mode?`, `exportName?`
- Response: explicit union result
  - success (`directions_urls`, file export metadata)
  - unsupported/graceful fallback (especially `saved_list_experimental`)

#### `travel.resolveMapWaypoints`
- Request: `tripId`, `entityRefs[]`, `overwriteExisting?`
- Response: per-entity result rows with `resolved | skipped | not_found | ambiguous | error`

#### `travel.getMapsProviderStatus`
- Response: provider/key presence status only (no plaintext secrets)

#### `travel.getMapsJsConfig`
- Response: frontend-safe map loader config (Maps JS key + libraries)

### Additive Page Props for `trip_location` / `trip_item`

These props are additive and must be parsed in frontend normalization and respected by backend routing/resolution logic.

- `map_lat`
- `map_lng`
- `map_query`
- `map_formatted_address`
- `google_place_id`
- `map_resolved_at`
- `map_resolution_source` (`manual|google_geocoding`)
- `route_exclude`

### Frontend Type Additions (`frontend/types.ts`)

Add types for:

- `TravelRouteMode`
- `TravelRouteWaypoint`
- `TravelRouteLeg`
- `TravelRouteDayResult`
- `TravelGoogleExportResult` (union)
- `TravelWaypointResolveResult`
- `TravelMapsProviderStatus`
- `TravelMapsJsConfig`

Also extend `TripItem` / `TripLocation` with additive map-related fields.

---

## 4) Backend Architecture (`backend/crates/app/src/travel_routing.rs`)

### Module Layout

Create `backend/crates/app/src/travel_routing.rs` and keep `#[tauri::command]` wrappers in `backend/crates/app/src/lib.rs`, delegating to module helpers.

Suggested internal sections:

- command request/response structs
- cache key normalization helpers
- lazy SQLite table init (`ensure_travel_stage3_tables`)
- provider adapters (Routes + Geocoding)
- route normalization + transit stitching
- export builders (Directions URL, CSV, KML)
- error normalization helpers
- unit tests

### Provider Adapters (Backend-only)

- Google Routes API via `reqwest`
- Google Geocoding API via `reqwest`
- Frontend never calls these APIs directly

### Secret Store Keys (encrypted)

- `travel.google_maps_js_api_key`
- `travel.google_routes_api_key`
- `travel.google_geocoding_api_key`

### Cache Tables (app-owned, lazy-created)

Use app-owned SQLite tables created lazily in `travel_routing.rs` (same pattern as `search.rs`), not shared `cortex-storage` migrations for the initial Stage 3 slice.

#### `travel_route_cache`
Fields include:
- normalized request hash/key
- trip/mode/provider version metadata
- request JSON (normalized)
- response JSON (normalized)
- `created_at`, `expires_at`, `last_hit_at`
- `hit_count`

#### `travel_geocode_cache`
Fields include:
- normalized query hash/key
- normalized query string
- result JSON
- `created_at`, `expires_at`, `last_hit_at`
- `hit_count`

### TTL Defaults

- `transit`: 6 hours
- `car`, `walk`: 24 hours
- geocode cache: 30 days

### Route Compute Behavior

- Manual order is preserved exactly (no auto optimization)
- `transit` day routing computes per adjacent pair and stitches into one result (`stitchedTransit = true`)
- `car`/`walk` may use multi-leg computation but still preserve caller order
- Missing coordinates should produce actionable errors/warnings and point user to explicit waypoint resolution

### Export Behavior

#### `directions_urls`
- Guaranteed path
- Chunk by Google waypoint limit while preserving sequence
- Return ordered URL actions

#### `saved_list_experimental`
- Stage 3 initial implementation returns explicit unsupported/fallback response
- Must include fallback actions (directions URLs and/or `my_maps_file`)
- No silent failure

#### `my_maps_file`
- Backend writes CSV + KML under trip export folder
- Path convention: `Travel/Trips/<trip-slug>/Exports/GoogleMaps/`
- Response returns file metadata/path(s) and summary

### Error Normalization Taxonomy

Normalize provider and validation failures into actionable command error messages or structured fallback responses:

- missing credential
- invalid request / insufficient waypoints
- no route found
- provider timeout
- quota / billing / permission denied
- unsupported export target (structured fallback response, not thrown error)

---

## 5) Frontend Architecture (ADR-0017 Compliant)

### Hook / Controller Responsibilities

Add `frontend/hooks/useTravelRoutePlanner.ts` to own Stage 3 route/map/export state and side effects.

Responsibilities:

- selected route day and mode (`car|walk|transit`)
- route result state and stale-state detection after itinerary changes
- explicit `Resolve Coordinates` action
- explicit `Compute Route` / `Refresh Route` action (no automatic recompute by default)
- export action flows + fallback state handling
- provider status / map loader config fetch
- error/loading state for route/resolve/export/map init

`Travel.tsx` remains view-only orchestration and must not directly import `services/backend.ts`.

### Travel Map Tab Composition

Add `map` tab to the Travel view with companion components under `frontend/components/travel/`.

Suggested components:

- `TravelMapPanel.tsx`
- `TravelRouteControls.tsx`
- `TravelRouteSummary.tsx`
- `TravelExportPanel.tsx`
- `TravelWaypointResolver.tsx`

### Explicit Recompute UX (Chosen Default)

- Route recomputation is explicit (`Compute` / `Refresh` button)
- UI marks route as stale when itinerary order/day/mode changes
- Cache metadata may be surfaced as a subtle status (e.g., “cached result”) for observability

### Settings → Integrations Travel Google Keys UI

Extend the existing Integrations panel to include Travel Google key setup:

- Maps JS API key (client-side loader key)
- Routes API key (backend routing)
- Geocoding API key (backend waypoint resolution; optional if shared)

Frontend writes via existing `secret_set` / `secret_delete`, and reads status via dedicated travel commands (`travel.getMapsProviderStatus` / `travel.getMapsJsConfig`) to avoid showing plaintext secrets.

### Google Maps JS Loading

Add frontend dependencies:

- `@googlemaps/js-api-loader`
- `@types/google.maps`

Load Maps JS only when map tab is needed; dedupe loads via a loader utility.

---

## 6) Testing Plan

### Backend Tests

- Cache key normalization determinism
- Route cache hit/miss/expiry behavior (`car|walk|transit`)
- Geocode cache behavior and waypoint resolution result statuses
- `travel.routeComputeDay` trip ownership validation + order preservation
- Transit stitching semantics (per-leg -> stitched day result)
- Export fallback semantics for `saved_list_experimental`
- CSV/KML file generation path + metadata
- Provider error normalization (quota/billing/missing-key/timeout)

### Frontend Tests

- `services/backend.ts` command names + camelCase request fields
- Travel normalization parses new map props into `TripItem`/`TripLocation`
- `useTravelRoutePlanner` explicit recompute (no automatic compute)
- stale-route transitions on itinerary/day/mode changes
- export fallback UI rendering and action availability
- Settings Integrations Travel key save/delete + provider status rendering
- `Travel.tsx` ADR-0017 compliance via hook-driven behavior (no direct service imports)

### Manual Acceptance Scenarios

1. Resolve coordinates for routeable itinerary items and render markers on map
2. Compute day routes for `car`, `walk`, `transit` and show route lines + ETA totals
3. Reorder items and confirm route is marked stale until explicit refresh
4. Export directions URLs with correct order preserved across chunked URLs
5. `saved_list_experimental` returns explicit unsupported + fallback actions
6. CSV/KML files are written under trip `Exports/GoogleMaps` and surfaced in UI

### Command Casing Validation

- Verify new commands and payload examples use runtime-validated camelCase invoke args in frontend docs/tests

---

## 7) Rollout and Verification

### Local Validation Commands (expected)

#### Contracts
- manual review of `002_IPC_WIRING_MATRIX.md` and `CHANGELOG.md` diffs

#### Backend
- `cargo test -p cortex-app <targeted travel routing tests>`
- `cargo test -p cortex-app --lib`
- `cargo check -p cortex-app`

#### Frontend
- `npm test -- tests/hooks/useTravelRoutePlanner.test.ts tests/settings_integrations.spec.tsx`
- `npm test -- tests/backend.smoke.test.ts`
- `npm run lint`
- `npm run build`

#### Integration
- verify submodule pins match merged component PR SHAs
- verify doc sync across `traceability`, `functional_requirements` (if changed), `MEMORY`, and release log

### PR Checklist Expectations (All PRs)

- tests added/updated and passing
- interfaces/contracts unchanged OR approved and documented in contracts PR
- paired PR links included
- ADR-0027 link included
- doc sync completed for repo scope
- traceability updated (integration PR)

---

## 8) Assumptions and Chosen Defaults

- **Coordinate strategy:** hybrid explicit waypoint resolve action (`travel.resolveMapWaypoints`) with additive coordinate props and optional manual edits
- **Export artifact strategy:** backend writes CSV/KML files to trip `Exports/GoogleMaps` folder and returns file metadata/paths
- **Recompute trigger strategy:** explicit compute/refresh button; route results become stale after itinerary/day/mode changes
- **Saved List experimental behavior:** structured unsupported/fallback response in Stage 3 initial release
- **Cache implementation:** app-owned lazy-created SQLite tables in backend app module (not `cortex-storage` migrations) unless TDD reveals a blocking constraint
- **Secret UX:** frontend does not display plaintext Travel keys; uses secret write/delete commands plus travel provider status/config read commands

---

## 9) Cross-Reference Notes for Reviewers

When reviewing code, cross-reference this spec against:

- ADR: `docs/adrs/ADR-0027-travel-v2-stage3-maps-routing-and-google-export.md`
- Contracts wiring matrix rows and changelog entries (contracts PR)
- Backend `travel_routing.rs` + `lib.rs` command registrations (backend PR)
- Frontend `useTravelRoutePlanner.ts`, Travel map components, and Settings Integrations updates (frontend PR)
- Integration traceability/release log/submodule pins (final integration PR)
