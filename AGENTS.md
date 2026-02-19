
# Cortex OS — Agent Instructions (Integration Repo)

All agent instructions, protocols, and governance rules live in the **`.system/`** folder at the repository root.

This repository is the **integration/workspace repo**. It assembles:
- `frontend/` (submodule → `cortex-os-frontend`)
- `backend/` (submodule → `cortex-os-backend`)
- `contracts/` (submodule → `cortex-os-contracts`)

It is the **source of truth** for:
- System/integration documentation
- Global Functional Requirements (FR)
- Global traceability (FR → repo → code → tests)
- Local dev orchestration (compose/scripts)

---

## Quick Reference

| File | Purpose |
|------|---------|
| `AGENTS.md` | This file — agent onboarding + doc hierarchy |
| `.system/PROTOCOL.md` | Core development protocols (TDD, Interface-First) |
| `.system/ROLES.md` | Role-based workflow (Architect → Test-Gen → Coder → Reviewer) |
| `.system/DOC_SYNC_CHECKLIST.md` | Mandatory PR merge gate — integration-level doc sync |
| `.system/MEMORY.md` | Living system state + active ADRs + progress log |
| `docs/functional_requirements.md` | **[Source of Truth]** Global FRs |
| `docs/traceability.md` | **[Source of Truth]** FR → repo → code/tests mapping |

---

## Repository Layout

```text
cortex-os/
  frontend/    (submodule -> cortex-os-frontend)
  backend/     (submodule -> cortex-os-backend)
  contracts/   (submodule -> cortex-os-contracts)
  docs/        (system-level docs + FR/traceability)
  docker-compose.yml
  .gitmodules
  README.md
```

---

## Documentation Hierarchy

```text
docs/
├── functional_requirements.md               # [Source of Truth] Global FRs
├── traceability.md                          # [Source of Truth] FR -> repo -> code
├── integration/                             # [Runbooks] local dev, compose, release
│   ├── 000_LOCAL_DEV.md
│   ├── 001_DEPLOYMENT.md
│   └── 002_RELEASE_PROCESS.md               # submodule bump protocol
├── technical_architecture/                  # [Design] system-level architecture (original vision)
│   ├── 001_ARCHITECTURE_v1.md               # System architecture, data model, stack, conventions
│   ├── 002_COLLECTIONS.md                   # Collections & domain modules (schemas, views)
│   ├── 003_TASKS_AND_PLANNING.md            # Tasks, planning, projects & calendar
│   └── 004_AI_INTEGRATION.md               # AI/LLM gateway, RAG, PII shield, agentic roadmap
└── adrs/                                    # [ADRs] cross-cutting decisions only
    ├── ADR-0001-*.md
```

---

## Cross-Repo Contract Rules (Critical)

### 1. When you must open paired PRs
If you change any of the following, you MUST open linked PR(s):
* **Backend modifies `#[tauri::command]`**: Update `cortex-os-contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`.
* **Contracts change**: Update FE generated clients in `cortex-os-frontend` and BE handlers in `cortex-os-backend`.
* **Global FRs updated**: Update traceability in this repo (`docs/traceability.md`).

### 2. Integration Pinning
After merges, bump submodule SHAs in `cortex-os` and record in:
* `docs/integration/002_RELEASE_PROCESS.md`
* `.system/MEMORY.md`

---

## Before You Start
1. Read `.system/PROTOCOL.md` and `.system/ROLES.md`.
2. Check `docs/functional_requirements.md` + `docs/traceability.md`.
3. If work touches API/IPC → ensure a paired PR exists in `cortex-os-contracts`.
4. Follow `.system/DOC_SYNC_CHECKLIST.md` before merge.
