# ADR-0024: Finance Mode Selection in Settings + Manual Budgeting UI

**Status:** IMPLEMENTED
**Date:** 2026-02-23
**Deciders:** Architecture review
**FR:** FR-009
**Related:** ADR-0006 (EAV/page model), ADR-0017 (frontend hooks layer), ADR-0023 (YNAB view-only integration)

---

## Context

ADR-0023 introduced a view-only YNAB sync and analytics dashboard, but its initial UI placed YNAB connection (PAT entry) directly inside the Finance view.

Product direction changed:

- Finance module mode selection should be configured in **Settings → Life Modules**
- Finance mode should support **Manual** and **YNAB**
- YNAB authentication belongs in **Settings → Integrations**
- Entering **Finance → YNAB** without a configured YNAB integration should redirect the user to Integrations
- Manual finance mode should provide a simple, Notion-style budgeting template with minimal analysis

This ADR updates the frontend UX architecture while preserving the backend YNAB view-only sync/analyzer work from ADR-0023.

---

## Decision

### 1) Finance mode selection is controlled in Settings (Modules tab)

When the Finance module is enabled, Settings shows a finance mode selector:

- `MANUAL`
- `YNAB`

The Finance view reads this selected mode and renders the corresponding experience. The Finance view no longer owns primary mode selection UX.

### 2) YNAB auth/connect UX lives in Settings (Integrations tab)

YNAB PAT connect/disconnect controls are implemented in **Settings → Integrations**.

The Finance YNAB view remains responsible for:

- sync operations
- analytics display
- local dashboarding

It is not responsible for credential entry.

### 3) Finance → YNAB redirects to Integrations when not connected

If the user’s finance mode is `YNAB` and the YNAB integration is not connected (`hasToken=false`), the app redirects to:

- `Settings`
- `Integrations` tab selected

The Finance view may also show a fallback message/button pointing to Integrations.

### 4) Manual mode ships a basic monthly budget template (current month only)

Phase 1 manual budgeting scope is intentionally minimal:

- current-month budget page (`budget_month`)
- editable category rows (`name`, `planned`)
- monthly budget cap (`total_budget`)
- derived per-category actual spend from manual transactions/CSV imports
- basic metrics: planned, actual, remaining, unallocated, utilization

This provides a Notion-template-style planner without introducing a full ledger editor or advanced manual analytics in this pass.

### 5) Manual budgeting reuses existing page-centric primitives (no new IPC)

Implementation reuses:

- `finance_get_budget` (backend command returning/creating `budget_month`)
- generic page updates via `page_update_props`
- existing manual accounts and manual transaction collections
- `finance_get_summary` for lightweight rollups

No new backend IPC commands are added for this manual budgeting UI pass.

---

## Superseded ADR-0023 UI Decisions

This ADR supersedes the following ADR-0023 frontend UX decisions:

- “YNAB settings live in Finance view onboarding” (moved to Integrations)
- “No YNAB UI in Settings in phase 1” (now false; Settings Integrations hosts YNAB auth)

ADR-0023 remains valid for:

- YNAB backend sync architecture
- local `ynab_*` page schema
- CSV mirror approach
- analytics/tracker backend design

---

## Consequences

### Positive

- Clear separation of concerns: integrations/credentials in Settings, analysis in Finance
- Better UX for mode selection and onboarding
- Manual finance users get an immediately usable budgeting template
- No backend API churn for the manual budgeting UI pass

### Tradeoffs

- Finance mode selection is frontend state-driven (session-scoped unless persistence is added later)
- Manual budgeting remains intentionally lightweight (no full manual transaction entry workflow yet)

---

## Implementation Notes

- Added app-level finance mode state and Settings-tab navigation targeting
- Added YNAB PAT connect/disconnect controls to Settings Integrations
- Added Finance redirect behavior to Settings Integrations when YNAB mode lacks connection
- Added manual budget template editor/metrics in Finance manual mode using current `budget_month` page
