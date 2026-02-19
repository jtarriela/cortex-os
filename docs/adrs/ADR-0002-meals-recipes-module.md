# ADR-0002: Meals & Recipes Module

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Frontend implementation (Phase 0)
**FR:** FR-013
**Supersedes:** N/A

---

## Context

The original technical architecture defines no meal or recipe tracking capability. `002_COLLECTIONS.md` mentions "Recipes" as a hypothetical user-created collection example but does not include it as a shipped template.

During Phase 0, a Meals module was implemented for daily food logging with calorie tracking and a recipe library.

## Decision

Add a Meals & Recipes domain module to Cortex OS with:

- **Types:**
  - `Meal`: id, date, mealType (`BREAKFAST` | `LUNCH` | `DINNER` | `SNACK`), description, recipeId (optional), calories (optional)
  - `Recipe`: id, title, ingredients (`string[]`), instructions, calories, tags, imageUrl (optional)
- **View:** `Meals.tsx` -- date-grouped meal log + recipe library tab
- **Data:** In-view state management only (no exported `dataService` functions yet)
- **Feature flag:** `meals: boolean` (default ON)

## Consequences

- Backend needs two page kinds (`meal`, `recipe`) or a combined collection with type discriminator
- Calorie tracking implies aggregation queries (daily totals, weekly averages)
- Recipe library is a standalone sub-collection that meals reference
- Data service functions need to be extracted to `dataService.ts` for consistency with other modules
- Collection templates needed: `meals.json`, `recipes.json`

## Migration Path

Phase 1+: Extract meal/recipe CRUD to `dataService.ts`, then to Tauri IPC. Backend stores as Page model with `kind: meal` and `kind: recipe`. Collection templates define schemas, selectors, and default views (List by date for meals, Gallery for recipes).
