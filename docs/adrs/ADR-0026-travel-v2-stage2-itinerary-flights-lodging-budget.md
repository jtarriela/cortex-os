# ADR-0026: Travel v2 Stage 2 — Itinerary, Flights/Lodging, and Single-User Budgeting

**Status:** PROPOSED  
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-008 (current baseline; travel FR expansion pending)  
**Related:** ADR-0006 (EAV/page model), ADR-0012 (test strategy), ADR-0017 (frontend hooks layer), ADR-0025 (Travel v2 Stage 1 foundation), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md)

---

## Context

After Stage 1, Travel v2 will have the canonical hierarchy and CRUD/projection foundation. Users still need the core planning workflow:

- itinerary/day planning
- flights and lodging logistics
- budget and expenses

The product direction is to ship a Wanderlog-style travel planner, but the initial budgeting scope is explicitly single-user (no tripmate split balances).

---

## Decision

Stage 2 delivers the first fully useful structured travel planning workflow on top of the Stage 1 model.

### 1) Itinerary timeline is a first-class workspace view

Travel UI adds a day/timeline itinerary view that groups `trip_item` pages by:

- `day_date`
- `start_time`
- `order_index`

Users can manually order and schedule items. This ordered structure becomes the basis for routing in Stage 3.

### 2) Flights and lodging are stored as typed `trip_item` variants (v1)

Instead of introducing separate page kinds in Stage 2, flights and lodging are modeled as `trip_item` with:

- `item_type=flight`
- `item_type=lodging`

This keeps the schema simpler while preserving structured fields in props.

### 3) Budgeting scope is single-user only

Stage 2 ships:

- trip-level budget target
- expense records (`trip_expense`)
- planned vs actual totals
- category summaries

Stage 2 does **not** include:

- tripmate balances
- split allocations
- settlement math

### 4) Budget analytics are travel-local, not YNAB-dependent

Travel budgeting is independent of Finance module YNAB/manual modes. Integration with Finance may come later, but Stage 2 rollups are computed from travel entities.

---

## Public Interface Additions (Stage 2)

Planned commands:

- `travel.getBudgetSummary`
- Stage 1 CRUD commands used for itinerary and logistics item updates (`travel.updateItem`, `travel.reorderItems`, etc.)

No AI, routing, or Gmail-specific APIs are introduced in this stage.

---

## UI/UX Scope (Stage 2)

Required Travel workspace sections:

- `Locations`
- `Itinerary`
- `Flights & Lodging`
- `Budget`

Required behaviors:

- create/edit flight item
- create/edit lodging item
- add expense linked to trip and optionally item/location
- view totals and category breakdowns
- move/reorder itinerary items within a day

---

## Data Validation Rules

- Flight/lodging times and dates must validate before save
- Expense amount must be non-negative numeric value (currency + amount stored separately)
- Itinerary ordering operations must produce deterministic `order_index` values

---

## Exit Criteria (Stage 2 Done)

1. A user can plan a trip using structured locations/items without relying on legacy cards.
2. Flights and lodging can be entered as structured `trip_item` records and shown in itinerary/logistics views.
3. Trip budget and expenses support planned vs actual rollups and category breakdowns.
4. All Stage 2 frontend logic is implemented through controller hooks (ADR-0017).
5. Backend, frontend, and contracts documentation are synchronized for Stage 2 behavior.

---

## Consequences

### Positive

- Delivers the first end-to-end structured travel planning workflow
- Creates strong inputs for routing (Stage 3) and AI optimization (Stage 5)
- Keeps budgeting scope intentionally manageable

### Tradeoffs

- `trip_item` props become denser due to flight/lodging variants
- Group travel budgeting and splits remain deferred

