# ADR-0023: YNAB View-Only Integration + Local CSV Mirror + Budget Analyzer

**Status:** IMPLEMENTED
**Date:** 2026-02-23
**Deciders:** Architecture review
**FR:** FR-009
**Related:** ADR-0006 (EAV/page model), ADR-0017 (frontend hooks layer)

---

## Context

The Finance module exposed a YNAB-branded entry path but the actual behavior was placeholder-only:

- frontend `Finance` view displayed a “Connect YNAB” option
- frontend `useFinanceView` simulated YNAB connect via timeout
- backend finance commands supported manual accounts, CSV import, and generic local rollups only
- no YNAB API client, sync cursor, or local YNAB entity schema existed

Users need a local-first, view-only YNAB integration that:

- pulls budget/account/category/transaction data from YNAB
- stores normalized local copies for dashboards/analytics
- writes CSV mirrors to the active vault
- supports tracked spending categories and personal finance analysis metrics

Constraints:

- ADR-0006 requires domain persistence through the `pages` EAV model (no new flat finance tables)
- Finance frontend behavior must remain hook/controller driven (ADR-0017)
- finance IPC additions require contracts repo documentation updates

---

## Decision

### 1) YNAB integration is view-only (read path only)

Phase 1/initial implementation uses only YNAB `GET` endpoints and does not mutate YNAB budgets or transactions.

### 2) Authentication is PAT-first, OAuth-ready later

The implemented flow uses a YNAB Personal Access Token (PAT):

- token stored in encrypted backend secret store (`finance.ynab_pat`)
- token validated against `GET /budgets`
- frontend never reads the token back after save

OAuth is intentionally deferred, but sync/analytics logic is separated from token capture so an OAuth token provider can replace PAT later.

### 3) Local persistence is `pages` + CSV mirror

YNAB data is persisted locally in two forms:

- normalized `ynab_*` page kinds in the app database (canonical for local UI/analytics)
- CSV snapshots + manifests under the active vault (`Finance/YNAB/...`)

This preserves local analysis performance while providing file-based export/mirroring.

### 4) YNAB sync uses full export + delta requests

The backend sync engine uses:

- `GET /budgets` for token validation / budget cache
- `GET /budgets/{budget_id}` for full and delta sync, with `last_knowledge_of_server`

The implementation persists `last_knowledge_of_server` per budget and retries a full sync if delta sync fails.

### 5) YNAB entities are stored in dedicated `ynab_*` page kinds

Implemented local kinds:

- `ynab_budget`
- `ynab_account`
- `ynab_category_group`
- `ynab_category`
- `ynab_budget_month`
- `ynab_month_category`
- `ynab_payee`
- `ynab_transaction`
- `ynab_subtransaction`
- `ynab_scheduled_transaction`
- `ynab_scheduled_subtransaction`

All rows include YNAB source metadata (`ynab_budget_id`, `ynab_entity_id`, `ynab_synced_at`, `ynab_deleted`).

### 6) Money is stored in milliunits for YNAB-backed analytics

YNAB amounts are preserved in integer `*_milliunits` props. Decimal convenience fields are also written for easier UI mapping, but analytics is built from milliunits to avoid precision drift.

### 7) Budget analyzer supports whole-budget + tracked categories

The implementation computes and exposes:

- whole-budget monthly metrics (spending, budgeted, to-be-budgeted, savings rate, burn-rate projection, overspent count)
- tracked-category metrics for user-selected categories

Tracked-category targets default to YNAB `budgeted` amounts with optional local recurring overrides.

### 8) YNAB UX lives in Finance view (not Settings)

The YNAB connect/sync/analyzer controls are implemented directly in the Finance view and `useFinanceView` controller, minimizing coupling to the monolithic Settings integrations panel.

---

## Public Interface Additions (Implemented)

New finance IPC commands:

- `finance.ynabStatus`
- `finance.ynabConnectPat`
- `finance.ynabDisconnect`
- `finance.ynabSync`
- `finance.ynabGetTrackerConfig`
- `finance.ynabSaveTrackerConfig`
- `finance.ynabGetAnalytics`

Existing manual finance commands remain supported.

---

## Implementation Status (2026-02-23)

### Backend

- `backend/crates/app/src/ynab.rs` added with:
  - PAT-backed YNAB client calls
  - budget cache/status commands
  - full/delta sync (`last_knowledge_of_server`)
  - normalization into `ynab_*` page kinds
  - vault CSV mirror generation + `schema_manifest.json` + `sync_state.json`
  - tracked-category config storage in `settings`
  - local YNAB analytics computation
- `backend/crates/app/src/lib.rs` registers new YNAB finance commands
- `backend/crates/core/src/lib.rs` adds collection mappings for local YNAB page kinds

### Frontend

- `frontend/hooks/useFinanceView.ts` now performs real YNAB status/connect/sync/analytics/tracker flows
- `frontend/views/Finance.tsx` adds PAT connect, budget select, sync controls, tracked-category manager, and tracked metrics display
- `frontend/services/backend.ts` adds typed wrappers for all `finance_ynab_*` commands and local `ynab_*` collection readers
- `frontend/types.ts` adds YNAB status/sync/analytics/tracker interfaces
- `frontend/services/normalization.ts` adds YNAB collection IDs

### Contracts

- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md` documents `finance.ynab*` command surface
- `contracts/CHANGELOG.md` adds finance YNAB contract entry (`0.10.0`)

---

## Consequences

### Positive

- Replaces placeholder YNAB UI with a working local-first finance sync and analyzer flow
- Preserves existing manual finance mode
- Keeps YNAB data queryable from the same EAV/page infrastructure
- Produces portable local CSV mirrors and a generated schema manifest per synced budget

### Risks

- Sync logic currently lives in `backend/crates/app/src/ynab.rs` (single-crate implementation) and may need extraction/refinement as scope grows
- Delta sync correctness depends on YNAB payload behavior and local normalization assumptions
- Finance view now has more YNAB UI state and will benefit from further controller/component splitting over time

### Mitigations

- Delta sync falls back to full sync on failure
- CSV mirror includes `schema_manifest.json` with pinned YNAB OpenAPI version (`1.76.0`)
- Frontend service/hook smoke tests cover command wiring and controller regression path
