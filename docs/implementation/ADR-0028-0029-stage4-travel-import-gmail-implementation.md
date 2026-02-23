# ADR-0028/0029 Stage 4 Implementation Spec — Travel Import (4A) + Gmail Reservation Scan (4B)

## Summary

This combined implementation spec covers:

- **ADR-0028 / Stage 4A**: Travel manual import preview/commit from `url`, `text`, and `image_base64`
- **ADR-0029 / Stage 4B**: User-triggered Gmail reservation scan/import preview/commit

It also incorporates ADR-0032 follow-on constraints for shared Google Calendar state safety:

- Gmail scope upgrade must preserve existing calendar sync metadata/state
- Calendar mutation flows used by Habits must remain regression-safe after Gmail upgrade

## 1) Scope and Non-Goals

### In Scope

- Stage 4A manual import preview/commit
- Stage 4B Gmail scan preview/commit (user-triggered only)
- Shared candidate schema, dedupe, provenance props, and commit engine semantics
- Google auth scope upgrade-on-demand (`calendar` -> `calendar_gmail`)
- Contracts/backend/frontend updates plus integration docs/traceability sync
- Regression coverage for ADR-0032 calendar-linked habit block behaviors after Gmail scope upgrade

### Non-Goals

- Background Gmail polling/watchers
- Raw Gmail body/attachment persistence or indexing
- Browser clipper/extension
- Autonomous import writes without user preview/commit
- Calendar command contract redesign (regression protection only)

## 2) Cross-Repo PR Matrix

### Merge Order / Gating

1. `cortex-os-contracts`
2. `cortex-os-backend`
3. `cortex-os-frontend`
4. `cortex-os` (integration pin/docs)

### Contracts (`cortex-os-contracts`)

Files:

- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`
- `contracts/CHANGELOG.md`

Changes:

- Add Travel Stage 4 commands:
  - `travel.importPreview`
  - `travel.importCommit`
  - `travel.gmailScanPreview`
  - `travel.gmailImportCommit`
- Document preview no-write guarantee, dedupe/provenance rules, and Gmail structured-data-first storage policy
- Add additive `integrations.googleAuth` scope profile note (`calendar` / `calendar_gmail`)
- Changelog entry `0.10.4`

### Backend (`cortex-os-backend`)

Files:

- `backend/crates/app/src/travel_import.rs` (new)
- `backend/crates/app/src/lib.rs`
- `backend/crates/core/src/lib.rs`
- `backend/crates/storage/src/settings.rs`
- `backend/crates/integrations/google_calendar/src/google/oauth.rs`
- `backend/crates/integrations/google_calendar/src/google/models.rs`

Changes:

- Stage 4 preview/commit commands + command registration
- Shared travel import preview/commit + Gmail scan helpers
- Gmail scope upgrade-on-demand auth flow
- Google auth merge behavior that preserves calendar sync metadata (`sync_tokens`, `cortex_calendar_id`, `last_synced_at`)
- Gmail feature flag check (`CORTEX_ENABLE_TRAVEL_GMAIL_SCAN`)

### Frontend (`cortex-os-frontend`)

Files:

- `frontend/hooks/useTravelImportController.ts` (new)
- `frontend/components/travel/TravelImportPanel.tsx` (new)
- `frontend/components/travel/TravelImportCandidateTable.tsx` (new)
- `frontend/components/travel/TravelGmailImportPanel.tsx` (new)
- `frontend/views/Travel.tsx`
- `frontend/services/backend.ts`
- `frontend/services/normalization.ts`
- `frontend/types.ts`
- `frontend/hooks/useSettingsController.ts`
- `frontend/views/Settings.tsx`

Changes:

- Add Travel `import` tab and controller-driven import workflows (ADR-0017 compliant)
- Add manual and Gmail preview/commit wrappers + UI
- Add Gmail upgrade-on-demand action in Settings and Travel
- Add `googleGmailConnected` integration setting and provenance field normalization

### Integration (`cortex-os`)

Files:

- `docs/implementation/ADR-0028-0029-stage4-travel-import-gmail-implementation.md`
- `docs/adrs/ADR-0028-travel-v2-stage4a-web-text-screenshot-import.md`
- `docs/adrs/ADR-0029-travel-v2-stage4b-gmail-reservation-scan.md`
- `docs/traceability.md`
- `.system/MEMORY.md`

Changes:

- Combined implementation spec and rollout notes
- ADR status transitions (implementation kickoff/closure)
- FR-008 traceability expansion for Stage 4
- Memory/progress + conflict hotspot reminders

## 3) Public Interfaces (Contract-First)

### New Travel Commands

#### `travel.importPreview` (`travel_import_preview`)

Request:

- `tripId`
- `sources[]` (`kind: 'url' | 'text' | 'image_base64'`)
- `options?` (`includeExpenses?`, `maxCandidates?`)

Response:

- `candidates[]`
- `warnings[]`
- `stats`
- `provider`
- `previewGeneratedAt`

#### `travel.importCommit` (`travel_import_commit`)

Request:

- `tripId`
- `approvedCandidates[]`
- `commitMode?`

Response:

- `results[]`
- `created`
- `skippedDuplicates`
- `warnings[]`

#### `travel.gmailScanPreview` (`travel_gmail_scan_preview`)

Request:

- `tripId`
- `startDate`
- `endDate`
- `maxMessages?`
- `queryOverride?`
- `includeAlreadyImported?`

Response:

- `candidates[]`
- `warnings[]`
- `scanStats`
- `messages[]` (sanitized metadata only)
- `previewGeneratedAt`

#### `travel.gmailImportCommit` (`travel_gmail_import_commit`)

Request:

- `tripId`
- `approvedCandidates[]`

Response:

- same shape as `travel.importCommit`

### Additive Google Integration Auth Change

#### `integrations_google_auth`

Add optional request field:

- `scopeProfile?: 'calendar' | 'calendar_gmail'`

Compatibility:

- Default remains calendar-only when omitted
- Existing Calendar connect flows remain unchanged

### Integration Settings / Auth State Additions

- `IntegrationSettings.googleGmailConnected: boolean`
- `GoogleAuthSettings.grantedScopes: string[]`

Critical behavior:

- Gmail scope upgrades must merge into existing Google auth/settings state without wiping calendar sync metadata

## 4) Backend Architecture

### `travel_import.rs` module responsibilities

- Source validation/normalization (`url`, `text`, `image_base64`)
- URL fetch + bounded HTML text extraction
- Deterministic preview candidate generation + schema structs (Stage 4 scaffolding)
- Gmail message list/metadata preview helpers (sanitized metadata only)
- Candidate dedupe/provenance helpers and hashing utilities
- Unit tests for parsing/query/sanitization helpers

### Preview / Commit semantics

#### Stage 4A preview

- Validates trip and sources
- Fetches URL text (bounded, timeout-limited)
- Normalizes text
- Validates image payloads (mime/size path)
- Returns preview candidates only; no page writes/index jobs

#### Stage 4A commit

- Revalidates edited candidates
- Creates pages in dependency order: locations -> items -> expenses
- Resolves link refs across created candidate IDs
- Applies provenance props + `import_dedupe_key`
- Enforces duplicate skip behavior (trip-scoped)
- Reuses existing travel helpers for markdown/index/event parity

#### Stage 4B Gmail scan preview

- Requires feature flag + Gmail scope
- User-triggered only
- Lists Gmail messages and reads metadata/sanitized text only (no attachments/raw-body persistence)
- Produces candidate preview + scan stats + hashed message refs
- Marks already-imported rows using dedupe/provenance

#### Stage 4B Gmail commit

- Reuses shared commit engine
- Enforces Gmail provenance expectations
- Persists structured travel entities only

### Google OAuth scope upgrade (ADR-0032-safe)

- `run_desktop_oauth_flow_with_scopes(scopes: &[&str])` added (compat wrapper retained)
- `integrations_google_auth` merges tokens/scopes into existing auth state
- Preserves calendar sync metadata and connection state during Gmail scope upgrades
- `integrations_update_settings` disconnect clears shared Google state and both calendar/Gmail flags

## 5) Frontend Architecture (ADR-0017 Compliant)

### Travel import controller hook

`frontend/hooks/useTravelImportController.ts`

Responsibilities:

- Manual source drafting (URLs, text, screenshots)
- Preview/commit orchestration for manual and Gmail flows
- Candidate selection/edit state
- Gmail scan date-range/query controls
- Gmail auth scope upgrade action
- Post-commit refresh of selected trip workspace

### Travel import UI composition

- `frontend/views/Travel.tsx` adds `import` tab
- `frontend/components/travel/TravelImportPanel.tsx` composes Stage 4A + 4B sections
- `frontend/components/travel/TravelImportCandidateTable.tsx` handles candidate review/edit/select
- `frontend/components/travel/TravelGmailImportPanel.tsx` handles Gmail status/scan/import

### Settings integrations update

- `frontend/hooks/useSettingsController.ts` adds `handleEnableTravelGmail()`
- `frontend/views/Settings.tsx` adds Gmail-for-Travel status/upgrade UI
- Existing Calendar connect/disconnect and sync controls remain intact

## 6) Persisted Provenance / Dedupe Props (Additive)

Applied to imported `trip_location`, `trip_item`, `trip_expense` as relevant:

- `source_kind`
- `import_dedupe_key`
- `source_url`
- `source_label`
- `source_snippet_sanitized`
- `source_message_ref` (hashed ref only)
- `source_sender`
- `source_subject`
- `source_message_date`
- `source_reservation_ref`
- `imported_at`

## 7) Testing Plan

### Backend

- Travel import source validation + preview helper tests
- Gmail query/sanitization/hash tests
- Commit engine/dedupe/link-resolution coverage
- Feature flag disabled behavior for Gmail scan
- Auth regression tests for Gmail scope upgrade preserving calendar sync metadata
- Calendar mutation regression tests (`calendar_reschedule_event`, `calendar_delete_event`) with habit-linked blocks after Gmail upgrade

### Frontend

- `frontend/tests/hooks/useTravelImportController.test.ts`
- `frontend/tests/backend.smoke.test.ts` (new Stage 4 wrappers + auth `scopeProfile`)
- `frontend/tests/settings_integrations.spec.tsx` (Gmail upgrade button path)
- `frontend/tests/hooks/useSettingsController.test.ts` (Gmail auth upgrade handler path)

### Manual acceptance

- Stage 4A preview no-write behavior, selective commit, indexing/search parity
- Stage 4B user-triggered Gmail scan, sanitized metadata previews, duplicate skip behavior
- ADR-0032 shared regression: Calendar/Habits-linked blocks still reschedule/delete correctly after Gmail scope upgrade

## 8) Merge-Conflict Hotspots / Coordination Notes

Shared files with elevated conflict risk (ADR-0032 + Stage 4 overlap):

- `backend/crates/app/src/lib.rs`
- `backend/crates/core/src/lib.rs`
- `backend/crates/storage/src/settings.rs`
- `frontend/types.ts`
- `frontend/services/backend.ts`
- `frontend/hooks/useSettingsController.ts`
- `frontend/views/Settings.tsx`
- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`
- `contracts/CHANGELOG.md`
- `docs/traceability.md`
- `.system/MEMORY.md`

Implementation guidance:

- Rebase component branches on latest `main` before review/merge
- Re-run Settings + calendar + habits regressions after rebase

## 9) Rollout and Verification

### Local validation (minimum)

- Contracts docs/changelog consistency checks
- Backend `cargo check` + targeted tests for travel import/auth regressions
- Frontend `tsc --noEmit` + targeted Vitest coverage for Stage 4 wrappers/hooks/settings

### Integration merge gate

- Cross-linked component PRs
- Traceability + MEMORY updates
- ADR-0028/0029 status transitions recorded
- Submodule pins + release process notes after component PR merges

## 10) Assumptions and Defaults

- Implementation spec is canonical in `docs/implementation/`
- `docs/implmentation/` may be used only for ad hoc audit artifacts when explicitly requested
- Gmail auth is a shared Google token scope upgrade, not a separate token store
- `integrations_google_auth` keeps default calendar-only behavior when `scopeProfile` is omitted
- Dedupe is trip-scoped via persisted `import_dedupe_key`
- Raw Gmail bodies/attachments are not persisted/indexed by default
