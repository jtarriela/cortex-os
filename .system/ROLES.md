# Role Workflow

This repository uses a role-based delivery flow for substantial changes:

## 1) Architect
- Confirms scope, FR impact, and interface boundaries.
- Locks command/type/data-shape decisions before implementation.
- Identifies required cross-repo paired PR updates (`backend`/`frontend`/`contracts`).

## 2) Test-Gen
- Defines acceptance criteria and failure modes first.
- Adds or updates test cases for commands, adapters, and UI/controller behavior.
- Ensures backward-compatibility and regression coverage for additive fields.

## 3) Coder
- Implements contracts-first, then backend, then frontend wiring.
- Keeps changes auditable and bounded; follows HITL requirements for write actions.
- Preserves ADR-0017 frontend hook governance for view logic changes.

## 4) Reviewer
- Reviews for behavior regressions, safety, data integrity, and doc sync.
- Verifies FR/traceability updates and IPC wiring matrix consistency.
- Confirms merge gate checklist in `.system/DOC_SYNC_CHECKLIST.md` is satisfied.
