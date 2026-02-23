# ADR-0025: Travel v2 Stage 1 — Foundation, RAG Indexing Parity, and Legacy Migration

**Status:** PROPOSED  
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-008 (current baseline; travel FR expansion pending)  
**Related:** ADR-0006 (EAV/page model), ADR-0012 (test strategy), ADR-0015 (save/index semantics), ADR-0017 (frontend hooks layer), ADR-0019 (linked-vault indexing), ADR-0022 (Vault Workbench write-back), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md)

---

## Context

Current travel functionality is limited to:

- `trip` pages (overview)
- `travel_card` child pages
- thin travel-specific commands (`travel_create_trip`, `travel_create_card`, `travel_get_itinerary`)
- a monolithic frontend `Travel` view with direct data fetching logic

The architecture docs and travel product direction require a richer model:

- hierarchical travel planning (`Trip -> Location -> Items`)
- structured itinerary entities
- RAG-accessible travel content
- compatibility for existing `travel_card` data

A critical gap exists today: travel-specific mutations do not consistently follow the same indexing semantics as generic page mutations (`vault_create_page`, `page_update_*`, `save_commit`).

---

## Decision

Stage 1 establishes the Travel v2 foundation before feature parity work.

### 1) Introduce canonical Travel v2 page kinds

New page kinds:

- `trip_location`
- `trip_item`
- `trip_expense`

Existing:

- `trip` retained
- `travel_card` retained temporarily for legacy compatibility only

### 2) Adopt a dual-read, lazy-upgrade migration strategy

Travel workspace reads both:

- new v2 entities
- legacy `travel_card` pages

New writes go to v2 entities only. Legacy cards can be upgraded on demand or via batch helper.

### 3) Add a workspace projection API

Introduce a travel-specific workspace projection command (`travel.getWorkspace`) to return a normalized trip payload with:

- trip
- locations
- items
- expenses
- legacy cards (optional section)

This avoids frontend N+1 joins and ad hoc sorting logic.

### 4) Enforce RAG indexing parity for all travel mutations (hard requirement)

All Travel v2 mutation commands must:

- persist page + markdown
- emit page lifecycle events
- enqueue index jobs
- process bounded index jobs

This includes migration/conversion commands.

### 5) Refactor frontend Travel view to ADR-0017 controller pattern

Travel Stage 1 must create hook/controller boundaries (for example `useTravelWorkspace`, `useTravelTripGallery`) and remove direct `services/backend.ts` fetching from `Travel.tsx`.

---

## Public Interface Additions (Stage 1)

Planned new commands:

- `travel.getWorkspace`
- `travel.createLocation`
- `travel.updateLocation`
- `travel.reorderLocations`
- `travel.createItem`
- `travel.updateItem`
- `travel.moveItem`
- `travel.reorderItems`
- `travel.createExpense`
- `travel.updateExpense`
- `travel.deleteExpense`
- `travel.legacyMigrateCards`

Legacy compatibility commands remain available:

- `travel_create_trip`
- `travel_create_card`
- `travel_get_itinerary`

---

## Data and Migration Rules

### Path and storage rules

- Travel v2 entities remain markdown pages under the trip folder
- Nested folders are path-managed by travel-specific backend commands
- Generic `vault_create_page` is not expanded for path-controlled nested writes in this stage

### Legacy migration safety rules

- no destructive migration by default
- converted entities keep provenance (`source_kind=legacy_travel_card`, `legacy_card_id`)
- legacy source file remains until explicitly archived/deleted

---

## Exit Criteria (Stage 1 Done)

1. Travel workspace loads mixed legacy + v2 data without breaking existing trips.
2. Users can create/edit/reorder locations and items under a trip.
3. Travel mutations index content and become searchable/RAG-visible on the same semantics as generic page commands.
4. Frontend Travel view no longer performs data-fetching `useEffect` logic directly (ADR-0017 compliant controller extraction).
5. Backend/Frontend/Contracts docs for Stage 1 interfaces are synchronized.

---

## Consequences

### Positive

- Provides stable foundation for itinerary, routing, import, and AI planning
- Prevents later rework by solving model and indexing gaps first
- Preserves existing travel data during migration

### Tradeoffs

- Travel v1 and v2 compatibility adds temporary complexity
- Stage 1 ships limited visible UX gains relative to later stages

