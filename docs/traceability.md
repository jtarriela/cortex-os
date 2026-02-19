# Traceability Matrix

This document maps each functional requirement (FR) defined in `functional_requirements.md` to the repositories, files or modules that implement the requirement.  It also notes where tests should live.  Updating this matrix is part of the **Doc Sync Checklist** defined in `.system/DOC_SYNC_CHECKLIST.md`.

| FR ID | Repository & Location | Implementation Notes | Test Location (planned) |
|------|----------------------|----------------------|-------------------------|
| **FR‑001** | **Frontend:** `cortex-os-frontend/App.tsx` (Task actions & modal), `views/TasksIndex.tsx`, `CreateTaskModal.tsx` | Task CRUD logic is implemented in the frontend state; backend commands will persist tasks via IPC. | `cortex-os-frontend/tests/tasks.spec.tsx` and `cortex-os-backend/tests/tasks.rs` (to be written) |
| **FR‑002** | **Frontend:** `views/ProjectsIndex.tsx`, `views/ProjectDetail.tsx` | Projects are rendered and selected; state holds `selectedProjectId`【767791288689422†L120-L132】.  Backend will manage projects and milestones. | `frontend/tests/projects.spec.tsx`; `backend/tests/projects.rs` |
| **FR‑003** | **Frontend:** `views/NotesLibrary.tsx`; `types.ts` defines `Note`【267591510078076†L146-L153】 | Notes library lists notes and loads content on demand.  Backend will provide note storage (vault). | `frontend/tests/notes.spec.tsx`; `backend/tests/notes.rs` |
| **FR‑004** | **Frontend:** `App.tsx` view resolver for TodayDashboard & WeekDashboard【767791288689422†L107-L117】 | Dashboards display tasks/events; backend will supply calendar data. | `frontend/tests/dashboard.spec.tsx`; `backend/tests/calendar.rs` |
| **FR‑005** | **Frontend:** `components/CommandPalette.tsx`; keyboard shortcuts in `App.tsx`【767791288689422†L87-L103】 | Command palette invokes agent actions and navigation. | `frontend/tests/command_palette.spec.tsx` |
| **FR‑006** | **Frontend:** `Settings.tsx`; `AppState.features` field【767791288689422†L31-L40】 | Feature toggles enable/disable modules.  State update triggers conditional rendering. | `frontend/tests/settings.spec.tsx` |
| **FR‑007** | **Frontend:** `views/ProjectsIndex.tsx`, `views/ProjectDetail.tsx`, `views/NotesLibrary.tsx` | Detail views show selected project/note based on `selectedProjectId`/`selectedNoteId`【767791288689422†L120-L132】. | `frontend/tests/detail_views.spec.tsx` |
| **FR‑008** | **Frontend:** `views/Travel.tsx`; `types.ts` defines `Trip`【267591510078076†L156-L167】 | Travel view will list trips and load cards.  Backend to store trips in vault. | `frontend/tests/travel.spec.tsx`; `backend/tests/trips.rs` |
| **FR‑009** | **Frontend:** `views/Finance.tsx`; `types.ts` defines finance models【267591510078076†L170-L194】 | Finance view shows budgets, transactions and accounts.  Backend integrates with YNAB or manual data. | `frontend/tests/finance.spec.tsx`; `backend/tests/finance.rs` |
| **FR‑010** | **Frontend:** `views/Journal.tsx`; `types.ts` defines `JournalEntry`【267591510078076†L28-L34】 | Journal entries are created, edited and stored. | `frontend/tests/journal.spec.tsx`; `backend/tests/journal.rs` |
| **FR‑011** | **Frontend:** `views/Habits.tsx`; `types.ts` defines `Habit`【267591510078076†L36-L42】 | Habits are tracked with streak counts and completion dates. | `frontend/tests/habits.spec.tsx`; `backend/tests/habits.rs` |
| **FR‑012** | **Frontend:** `views/Goals.tsx`; `types.ts` defines `Goal`【267591510078076†L45-L54】 | Goals support progress tracking and optional link to projects. | `frontend/tests/goals.spec.tsx`; `backend/tests/goals.rs` |
| **FR‑013** | **Frontend:** `views/Meals.tsx`; `types.ts` defines `Meal` and `Recipe`【267591510078076†L56-L73】 | Meals and recipes stored in vault or remote. | `frontend/tests/meals.spec.tsx`; `backend/tests/meals.rs` |
| **FR‑014** | **Frontend:** `types.ts` defines AI models and settings【267591510078076†L218-L239】; `App.tsx` opens RightDrawer for AI focus | AI settings configured via settings page; commands will call backend agent manager. | `frontend/tests/ai.spec.tsx`; `backend/tests/agents.rs` |
| **FR‑015** | **Frontend:** calendar events types【267591510078076†L204-L215】; `views/TodayDashboard.tsx`, `views/WeekDashboard.tsx` | Integrates tasks and events into calendars. | `frontend/tests/calendar.spec.tsx`; `backend/tests/calendar.rs` |
| **FR‑016** | **Frontend:** theme toggling in `App.tsx` effect【767791288689422†L73-L85】 | Adds/removes `light` class on `<html>`; persists in settings. | `frontend/tests/theme.spec.tsx` |
| **FR‑017** | **Frontend:** layout components `LeftNav`, `TopBar`, `RightDrawer`【767791288689422†L170-L199】 | Provides responsive UI and collapsible navigation. | `frontend/tests/layout.spec.tsx` |
| **FR‑018** | **Frontend:** global keyboard handlers in `App.tsx`【767791288689422†L87-L103】 | Supports command palette toggle and modal dismissal. | `frontend/tests/keyboard.spec.tsx` |

### How to read this matrix

* **Repository & Location**: Where the requirement is implemented today.  For cross‑repo features (e.g., API contracts), list both frontend and backend modules.
* **Test Location (planned)**: Suggested test file locations.  These tests may not exist yet; create them when implementing features.
* When adding or modifying a requirement, update this matrix and link the new code.
