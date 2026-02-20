# ADR-0015: Vault Onboarding, Secure Settings Storage, and Incremental Reindex Semantics

**Status:** IMPLEMENTED
**Date:** 2026-02-19  
**Deciders:** Architecture review  
**FR:** FR-028  
**Related:** ADR-0006 (Page/EAV schema), ADR-0004 (AI), ADR-0013 (Voice), `docs/integration/003_PHASE4_REMAINING_REPORT.md`

---

## Context

Usability testing identified a blocking product gap: users do not see an explicit vault setup flow (`create/select vault`), so persistence behavior is unclear and the app feels non-functional.

Two related architecture gaps were also identified:

1. **Settings/API key security posture is incomplete for production.**
   - AI key fields currently live inside `AISettings` and are persisted in the SQLCipher DB.
   - While SQLCipher encrypts database contents at rest, current key management is still Phase-foundation level and not sufficient as a production secret-management model by itself.

2. **Incremental indexing trigger semantics are undefined.**
   - The system needs a strict definition of “save” to avoid ambiguous reindex behavior and expensive full re-embeds.

---

## Decision

### 1) Vault-first onboarding is mandatory in Phase 4 closure

Add a first-run/setup splash with:
- `Create Vault`
- `Select Existing Vault`

On **Create Vault**:
- create vault root and Cortex metadata directory/file (`.cortex/` profile)
- persist vault identity/config
- create required starter cards/pages
- enqueue initial indexing bootstrap

On **Select Existing Vault**:
- validate vault structure and Cortex metadata
- run schema/profile compatibility checks
- run incremental catch-up indexing for stale/missing index entries

### 2) Settings/preferences must persist in a vault-aware profile

User settings/preferences shall persist across sessions and be tied to the selected vault profile.

Persisted categories include:
- UI preferences
- integration settings
- AI settings (non-secret fields)
- vault-specific feature flags

### 3) API keys/secrets are stored encrypted at disk level (defense-in-depth)

AI key fields may remain in `AISettings` DTO for transport, but at rest they must be encrypted before storage using an application encryption service.

Required model:
- data encryption key (DEK) generated locally
- DEK protected by OS keychain-bound key material (platform keystore)
- encrypted secret blobs persisted in local storage (DB or `.cortex` secrets file)
- plaintext keys never logged; minimize plaintext lifetime in memory

Rationale:
- SQLCipher is necessary but not sufficient if key management is weak.
- Field-level encryption + keychain-backed key wrapping raises the bar and aligns with Phase 4 security goals.

### 4) “Save” is a persisted write commit, not merely a UI event

Incremental indexing is triggered only when a **save commit** succeeds.

Save commit sources:
- explicit save action (e.g., `Ctrl/Cmd+S`)
- autosave debounce after edit inactivity window
- blur/close action that flushes pending changes
- app shutdown flush of dirty buffers

Indexing trigger rule:
- after persistence ACK, compute canonical content hash
- if hash unchanged from last indexed hash: skip reindex
- if changed: enqueue incremental reindex job (changed card/chunks only)

Non-trigger events:
- focus/blur without persisted delta
- card open/close without changes
- transient editor state updates not yet committed

### 5) Indexing performance strategy

To avoid user-facing slowness:
- never run full-vault embeddings on ordinary saves
- use async background indexing queue
- use chunk-level dirty detection + content hashing
- debounce rapid edits and coalesce jobs per card
- expose lightweight indexing status/progress in UI

---

## Consequences

- Phase 4 scope explicitly includes vault onboarding and profile persistence semantics.
- A new vault profile contract (`.cortex`) is introduced as configuration/identity anchor.
- Secret storage implementation must be upgraded to encrypted-at-rest field handling with keychain integration.
- Indexing behavior becomes deterministic and testable through save-commit semantics.

---

## Implementation Notes (Phase 4)

Minimum commands/surfaces expected:
- `vault_create`
- `vault_select`
- `vault_get_profile`
- `settings_get` / `settings_update` (vault-scoped)
- `secret_set` / `secret_get` abstraction (backend-only exposure)
- `index_enqueue` internal queue APIs

Test expectations:
- first-run vault creation integration test
- vault selection compatibility/migration test
- settings persistence test by vault
- secret encryption/decryption round-trip tests
- save-commit indexing trigger tests (changed vs unchanged hash)

---

## Implementation Notes (Phase 5 Verification — 2026-02-19, cortex-os#10)

### Verified Present

**Backend (`crates/app/src/lib.rs`):**
- `vault_create` — validates path, calls `ensure_vault_structure()`, upserts profile, seeds starter "welcome" note card on first create
- `vault_select` — validates path has `.cortex/` marker via `ensure_vault_marker()`, upserts profile
- `vault_get_profile` — returns active `VaultProfile` or `None` (drives first-run gate)
- `save_commit` — persists page body, calls `enqueue_index_job()` + `process_index_jobs()`, emits `page_updated` event
- `index_queue_status` — queries `index_jobs` table; hash-dedup prevents redundant re-indexing
- `secret_set/get/delete` — encrypted secret store using `secret_store` table (SQLCipher AES-256 + per-secret DEK wrapping)

**Frontend:**
- `App.tsx` — gates on `vaultGetProfile()` at startup; renders `<VaultSetup>` if null
- `views/VaultSetup.tsx` — create/select flow wired to `vaultCreate` / `vaultSelect` IPC; path validation + error display
- `stores/noteStore.ts` — dirty-state flag, 1500ms debounce autosave, `saveCommit` IPC on flush

**Storage (schema V3):** `vault_profiles`, `secret_store`, `index_jobs`, `page_index_state` tables

### Test Evidence
- `frontend/tests/vault_setup.spec.tsx`: 3 tests (create vault, select vault, missing path error)
- `frontend/tests/domain_stores.spec.ts`: noteStore vault loading + note selection
- `backend/crates/storage/tests/ai_phase4.rs`: `vault_profiles_table_supports_active_selection`, `index_queue_tables_support_queued_and_skipped_rows`, `secret_store_table_roundtrip_rows_exist`

**Issue:** cortex-os#10 (closed)

## Enforcement

Any PR claiming Phase 4 closure without:
- vault onboarding (`create/select`)
- persisted user preferences by vault profile
- encrypted secret-at-rest model
- save-commit incremental indexing semantics

must be rejected as incomplete relative to this ADR.
