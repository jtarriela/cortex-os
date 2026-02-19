# Phase 4 Beta Report (Foundation Slice)

**Date:** 2026-02-19  
**Epic:** [cortex-os#5](https://github.com/jtarriela/cortex-os/issues/5)

## 1) What Was Completed In This Slice

### Frontend (`cortex-os-frontend`)
- Migrated `services/aiService.ts` from frontend-direct Gemini SDK to backend IPC wrappers.
- Added backend AI facade calls in `services/backend.ts` (`ai_*`, `review_*`, `token_usage`).
- Added streaming listeners (`ai_stream_chunk`, `ai_stream_done`, `ai_stream_error`) and wired incremental rendering in `components/RightDrawer.tsx`.
- Added Ollama endpoint support in `views/Settings.tsx`.
- Removed `@google/genai` dependency.

### Backend (`cortex-os-backend`)
- Added AI IPC commands:
  - `ai_get_models`, `ai_chat`, `ai_summarize`, `ai_generate_image`, `ai_transcribe`, `ai_synthesize`, `ai_validate_key`
  - `review_list`, `review_approve`, `review_reject`, `token_usage`
- Added regex-based PII redaction in AI chat path for cloud routing.
- Added stream event emission for AI responses (`ai_stream_chunk`, `ai_stream_done`).
- Added SQLCipher migrations for Phase 4 tables:
  - `review_queue`
  - `usage_log`
- Updated AI settings model for Phase 4 frontend/backend shape alignment.
- Fixed Tauri `frontendDist` path for integration workspace builds (`backend/crates/app/tauri.conf.json`).

### Contracts (`cortex-os-contracts`)
- Updated AI command/event section in IPC wiring matrix for implemented command surface and stream events.

### Integration (`cortex-os`)
- Updated traceability + memory docs for Phase 4 foundation status.

## 2) Remaining Work (Not Yet Complete)

## Backend Remaining (`cortex-os-backend#8`)
- Real multi-provider implementations (OpenAI, Anthropic, Gemini, Ollama) instead of stubbed/mock response routing.
- Provider-agnostic `ToolDef` abstraction and provider-native tool translation.
- Full Whisper model integration (tiers, model management, real STT pipeline).
- Real TTS provider routing and WAV/PCM conversion path.
- Keychain-backed API key encryption/key rotation (currently not OS-keychain encrypted).
- RAG commands (`ai_rag_query`, `ai_suggest_links`) and relevance selection logic.
- `ai_stream_error` emitter from provider stream failures.

## Frontend Remaining (`cortex-os-frontend#5`)
- Morning Review UI (list/edit/approve/reject/batch actions).
- Token usage dashboard (charts, cost table/history).
- Provider model picker sourced fully from backend capabilities.
- UX polish for stream errors/retries/cancel flow.

## Contracts Remaining (`cortex-os-contracts#3`)
- Add missing specs for `ai_rag_query` and `ai_suggest_links`.
- Finalize AI settings command conventions and encrypted-key handling docs.
- Version bump/changelog completion for Phase 4 contract release.

## Integration Gate Remaining (`cortex-os#5`)
- Close all remaining FE/BE/contracts Phase 4 checklist items.
- Validate end-to-end gate criteria and regression coverage.

## 2.1) Critical Blocker From Usability Sessions

Observed in interactive testing:
- Users report that core actions feel non-functional because there is no explicit vault onboarding flow and no visible storage target setup.
- Result: app appears to “not save” or “not persist” in expected user mental model (Obsidian-style vault-first workflow).

Formalized in ADR:
- `docs/adrs/ADR-0015-vault-onboarding-and-secure-settings.md` (ACCEPTED)

Proposed product/architecture direction:
- Add a first-run **Vault Setup Splash**:
  - `Create Vault`
  - `Select Existing Vault`
- On create:
  - initialize Cortex vault folder structure
  - seed required system starter cards/pages
  - run initial indexing bootstrap
- On select:
  - validate structure
  - run migration checks
  - enqueue incremental reindex of missing/outdated items

Data/indexing behavior recommendation:
- Source of truth must be explicit (filesystem vault vs DB pages model) and documented.
- Initial vault creation:
  - create starter cards first
  - index in background queue with progress UI
- Ongoing edits:
  - reindex only changed card/chunks on **save commit** (not full vault)
  - debounce saves and use content-hash change detection
  - keep embedding/index jobs async to avoid UI stalls

Performance risk and mitigation:
- Full re-embedding on every save is too expensive and will degrade UX.
- Use incremental indexing queue + chunk-level dirty checks + provider rate limiting.

Delivery impact:
- This should be treated as a **blocking UX/system prerequisite** before Phase 4 gate closure, because without reliable vault onboarding/persistence semantics, AI and module workflows appear broken to end users.

## 3) Issue Closure Status

No Phase 4 epic issues were closed in this slice because their gate checklists are still partially incomplete:
- `cortex-os#5`
- `cortex-os-frontend#5`
- `cortex-os-backend#8`
- `cortex-os-contracts#3`

This slice is a **foundation** increment, not full epic closure.

## 3.1) Phase 4 Child Issue Breakdown (Created)

### Integration (`cortex-os`)
- [#7](https://github.com/jtarriela/cortex-os/issues/7) — Cross-Repo Rollout: Vault Onboarding + Secure Settings (ADR-0015)
- [#8](https://github.com/jtarriela/cortex-os/issues/8) — Gate Closure: Regression Matrix + End-to-End Usability Evidence

### Frontend (`cortex-os-frontend`)
- [#10](https://github.com/jtarriela/cortex-os-frontend/issues/10) — Vault Setup Splash + Create/Select Vault Flow
- [#11](https://github.com/jtarriela/cortex-os-frontend/issues/11) — Save-Commit UX + Dirty State + Autosave Semantics
- [#12](https://github.com/jtarriela/cortex-os-frontend/issues/12) — Morning Review UI (Approve/Reject/Edit + Batch)
- [#13](https://github.com/jtarriela/cortex-os-frontend/issues/13) — AI Usage Dashboard (Token + Cost)
- [#14](https://github.com/jtarriela/cortex-os-frontend/issues/14) — Provider/Model UI Finalization (Backend-Driven)

### Backend (`cortex-os-backend`)
- [#12](https://github.com/jtarriela/cortex-os-backend/issues/12) — Vault Profile Service + Create/Select Commands
- [#13](https://github.com/jtarriela/cortex-os-backend/issues/13) — Secret Encryption Service (Keychain + DEK Wrapping)
- [#14](https://github.com/jtarriela/cortex-os-backend/issues/14) — Save-Commit Triggered Incremental Indexing Queue
- [#15](https://github.com/jtarriela/cortex-os-backend/issues/15) — Real Multi-Provider LLM Adapters (OpenAI/Anthropic/Gemini/Ollama)
- [#16](https://github.com/jtarriela/cortex-os-backend/issues/16) — Voice Pipeline Hardening (Whisper tiers + TTS routing)
- [#17](https://github.com/jtarriela/cortex-os-backend/issues/17) — RAG Commands: `ai_rag_query` + `ai_suggest_links`

### Contracts (`cortex-os-contracts`)
- [#6](https://github.com/jtarriela/cortex-os-contracts/issues/6) — Vault Onboarding Command Specs (create/select/profile)
- [#7](https://github.com/jtarriela/cortex-os-contracts/issues/7) — Secret Storage Contract Conventions (encrypted fields + transport rules)
- [#8](https://github.com/jtarriela/cortex-os-contracts/issues/8) — Save-Commit + Incremental Indexing Contract/Event Specs
- [#9](https://github.com/jtarriela/cortex-os-contracts/issues/9) — RAG Command Specifications (`ai_rag_query`, `ai_suggest_links`)
- [#10](https://github.com/jtarriela/cortex-os-contracts/issues/10) — Contracts Release: Version 0.4.0 + Changelog

## 4) Verified Build/Test Results

### Frontend
- `npm test` ✅
- `npm run lint` ✅
- `npm run build` ✅

### Backend
- `cargo check -p cortex-app` ✅
- `cargo test -p cortex-storage` ✅
- `cargo test -p cortex-storage --test ai_phase4` ✅

### Full App Compile (Tauri)
- `cargo tauri build --no-bundle` from `backend/crates/app` ✅
- Output binary: `backend/target/release/cortex-app`

## 5) How To Compile + Usability Test Full App

## Prerequisites
- Node 20+
- Rust stable toolchain
- Tauri CLI installed (`cargo tauri --version`)
- Linux desktop/WebKit deps as listed in `docs/integration/000_LOCAL_DEV.md`

## A) Clean install
```bash
# from integration repo root
cd frontend && npm install
cd ../backend && cargo fetch
```

## B) Compile frontend + backend independently
```bash
# frontend compile
cd frontend
npm run lint
npm test
npm run build

# backend compile
cd ../backend
cargo check -p cortex-app
cargo test -p cortex-storage
```

## C) Compile full desktop app binary
```bash
cd backend/crates/app
cargo tauri build --no-bundle
# binary -> ../../target/release/cortex-app
```

## D) Run usability test session (interactive app)
```bash
# one command from repo root:
./scripts/usability-session.sh
```

Optional pass-through args to Tauri:
```bash
./scripts/usability-session.sh -- --verbose
```

## E) Manual usability checklist (minimum)
1. Open Settings → Intelligence: verify provider fields persist and model changes save.
2. Open AI drawer: send prompt, confirm streamed chunk rendering appears.
3. Use voice input and auto-speak toggles: verify transcription/synthesis responses return.
4. Trigger an AI write-intent phrase (e.g. “add task …”): verify queued response references Morning Review.
5. Re-open app and verify AI settings persistence.

## 6) Recommended Next PR Split

1. `Integration+FE+BE`: Vault Setup Splash (`create/select vault`) + first-run onboarding + persistence semantics doc.  
2. `BE`: incremental indexing queue (bootstrap + on-save reindex, hash-based dirty detection).  
3. `BE`: real provider adapters + keychain encryption + RAG commands.  
4. `FE`: Morning Review view + usage dashboard.  
5. `Contracts`: finalize remaining AI command specs + version bump.  
6. `Integration`: submodule SHA pinning PR and Phase 4 gate closure report.
