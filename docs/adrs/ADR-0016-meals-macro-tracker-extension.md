# ADR-0016: Meals Module Extension to Macro Tracking

**Status:** PROPOSED  
**Date:** 2026-02-20  
**Deciders:** Architecture review  
**FR:** FR-013  
**Related:** ADR-0002 (Meals & Recipes Module)

---

## Context

The current Meals module tracks meal assignments, recipes, and calories, but does not model macronutrients. Product feedback now requires extending this flow toward macro-aware planning (protein/carbs/fat) without breaking current meal-planner behavior.

This should remain backward-compatible with existing meal/recipe pages and avoid a schema migration that forces historical data rewrites.

## Decision

Extend the FR-013 domain in a staged way:

1. Add optional macro props to `meal` and `recipe` pages.
   - `protein_g?`
   - `carbs_g?`
   - `fat_g?`
   - `fiber_g?` (optional secondary metric)

2. Keep calories as-is and treat macro fields as additive metadata.
   - Existing pages without macro values remain valid.
   - Aggregations must handle missing macro fields safely.

3. Add per-profile daily macro targets in a follow-up settings slice.
   - Targets are optional and can be introduced independently from meal/recipe CRUD.

4. Deliver in two increments.
   - Increment A: capture + display macro values on recipes/meals and weekly totals.
   - Increment B: target-vs-actual visualization and macro-based planner feedback.

## Consequences

- Requires paired FE/BE/contracts updates when implementation starts:
  - contracts wiring matrix field additions for meal/recipe payloads and summary response shape
  - frontend type updates + Meals UI updates
  - backend summary command extension (`meals_get_nutrition_summary` or successor)
- No destructive data migration is required because fields are optional.
- Enables future nutrition features (macro goals, recommendations) while preserving current planner usage.

## Non-Goals (for this ADR)

- Barcode scanning / nutrition API ingestion
- Micronutrient tracking
- Medical or diet-prescription workflows
