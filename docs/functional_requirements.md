# Global Functional Requirements (FR)

This document defines the **functional requirements** for Cortex OS at the integration level.  Each requirement is identified by a stable identifier (e.g. `FR‑001`) and describes what the system **shall** do without specifying the implementation.  These requirements are the source of truth for all sub‑modules.  When the frontend or backend evolves, update this file and the corresponding traceability matrix.

## FR List

| ID | Requirement |
|----|-------------|
| **FR‑001** | **Task management:** Users shall be able to create, view, update and delete tasks.  Tasks have a title, optional description, status (`TODO`, `DOING`, `DONE`, `ARCHIVED`), priority (high/medium/low/none), optional due date, optional project reference, optional linked note, tags, comments and creation date【267591510078076†L92-L106】. |
| **FR‑002** | **Project management:** Users shall be able to manage projects consisting of a title, optional description, status, priority, date range, progress, milestones and associated artifacts.  Projects may reference multiple tasks and milestones【267591510078076†L116-L127】. |
| **FR‑003** | **Notes library:** Users shall be able to create, edit and organize markdown notes.  Notes have an id, title, content, last modified date, tags and a path (breadcrumb) representing folders【267591510078076†L146-L153】. |
| **FR‑004** | **Daily and weekly dashboards:** The system shall provide a **Today** dashboard and a **Week** dashboard showing upcoming tasks, calendar events and quick actions to create tasks【767791288689422†L107-L116】. |
| **FR‑005** | **Command palette:** Users shall be able to open a command palette (via `Ctrl/Cmd + K`) to quickly navigate, create tasks or invoke agent actions【767791288689422†L87-L103】. |
| **FR‑006** | **Feature toggles:** The application shall allow enabling or disabling modules such as Travel, Finance, Workouts, Journal, Habits, Goals and Meals via a settings screen【767791288689422†L31-L40】. |
| **FR‑007** | **Project and note detail views:** When selecting a project or note, users shall be able to view its details, edit content and navigate back to the list【767791288689422†L120-L132】【767791288689422†L131-L132】. |
| **FR‑008** | **Travel planner:** Users shall be able to manage trips. A trip contains destination, status (`Planning`, `Booked`, `Completed`), path (vault folder) and metadata (dates, budget, image and cards)【267591510078076†L156-L167】. |
| **FR‑009** | **Personal finance:** Users shall be able to view YNAB budgets by month, view transactions and manage manual accounts【267591510078076†L170-L194】. |
| **FR‑010** | **Journal:** Users shall be able to write journal entries containing date, content, mood and tags【267591510078076†L28-L34】. |
| **FR‑011** | **Habit tracking:** Users shall be able to track habits with daily or weekly frequency, maintain streak counts and mark completion dates【267591510078076†L36-L42】. |
| **FR‑012** | **Goal setting:** Users shall be able to set goals, describe them, categorize them (monthly/yearly/long‑term), monitor progress and associate them with projects【267591510078076†L45-L54】. |
| **FR‑013** | **Meal logging and recipes:** Users shall be able to record meals (breakfast/lunch/dinner/snack) with descriptions, optional recipe references and calories. They can also manage recipes with ingredients, instructions and optional image【267591510078076†L56-L73】. |
| **FR‑014** | **AI integration:** Users shall be able to configure AI providers (Gemini, OpenAI, Claude), choose an active model and enable voice or chat capabilities. Agent actions such as `ADD_TASK`, `ADD_GOAL`, `ADD_JOURNAL`, `ADD_NOTE`, `SEARCH_BRAIN` and navigation shall be supported【267591510078076†L218-L245】. |
| **FR‑015** | **Calendar integration:** Calendar events shall support events, tasks, reminders and deep‑work sessions with start/end times and optional linked notes or tasks【267591510078076†L204-L215】. |
| **FR‑016** | **Theme switching:** Users shall be able to switch between dark and light modes; the UI shall persist the selected theme across sessions【767791288689422†L73-L85】. |
| **FR‑017** | **Responsive navigation:** The application shall provide a collapsible left navigation bar, a top bar, and a right drawer for secondary content and AI interactions【767791288689422†L170-L199】. |
| **FR‑018** | **Accessibility and keyboard shortcuts:** The system shall provide keyboard shortcuts (e.g., `Ctrl/Cmd + K` for command palette, `Escape` to close modals) and accessible focus management【767791288689422†L87-L103】. |
| **FR‑019** | **Workout tracking:** Users shall be able to view a history of workouts, log new sessions, and monitor activity trends via charts. Workouts include metadata such as date, name, duration and exercise count. |

### Notes

*These requirements are derived from the current frontend implementation and may evolve as new features are added.*  Any change in functionality **must** update this list and the traceability matrix.
