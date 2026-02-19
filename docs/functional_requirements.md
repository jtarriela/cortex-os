# Global Functional Requirements (FR)

This document defines the **functional requirements** for Cortex OS at the integration level. Each requirement is identified by a stable identifier (e.g. `FR-001`) and describes what the system **shall** do. These requirements are **sourced from the current frontend implementation** (Phase 0) and represent the features that the backend must support.

When the frontend or backend evolves, update this file and the corresponding traceability matrix.

## FR List

| ID | Requirement |
|----|-------------|
| **FR-001** | **Task management:** Users shall be able to create, view, update and delete tasks. Tasks have a title, optional description, status (`TODO`, `DOING`, `DONE`, `ARCHIVED`), priority (`HIGH`, `MEDIUM`, `LOW`, `NONE`), optional due date, optional project reference, optional linked note, optional assignee, task type category (e.g. `Project`, `Task`, `Bug`, `Dev`, `Work`), tags, comments, and creation date. Tasks can be organized on a Kanban board grouped by status. |
| **FR-002** | **Project management:** Users shall be able to manage projects with a title, optional description, status (`NOT_STARTED`, `ACTIVE`, `ON_HOLD`, `COMPLETED`, `ARCHIVED`), priority (`HIGH`, `MEDIUM`, `LOW`), date range, progress percentage (0-100), milestones (with toggle), and AI-generated image artifacts. Projects may reference multiple tasks. Projects can be created from templates (Software Project, Content Calendar, Blank). |
| **FR-003** | **Notes library:** Users shall be able to browse and view markdown notes in a vault-like file tree. Notes have an id, title, content, last modified date, tags, and a folder path. The file tree supports folders and files with expand/collapse navigation. |
| **FR-004** | **Today Dashboard:** The system shall provide a Today Dashboard showing: priority tasks (due today or overdue), today's schedule (time-blocked events and tasks), a habit tracker with daily check-off, a quick capture input, and day progress metrics. |
| **FR-005** | **Command palette:** Users shall be able to open a command palette (`Ctrl/Cmd + K`) to search across notes, tasks, and projects. Results are categorized by type. Quick actions include task creation and navigation to any entity. |
| **FR-006** | **Feature toggles:** The application shall allow enabling or disabling domain modules (Travel, Finance, Workouts, Journal, Habits, Goals, Meals) via a settings screen. Disabled modules are hidden from navigation. |
| **FR-007** | **Project and note detail views:** When selecting a project, users shall view its details including milestones, an embedded task board filtered to that project, and AI-generated artifacts. When selecting a note, users shall view its rendered content with an AI summary option in the context drawer. |
| **FR-008** | **Travel planner:** Users shall be able to manage trips as vault folders. Each trip has a destination, status (`Planning`, `Booked`, `Completed`), dates, budget, and cover image parsed from an `Overview.md` file. Trips contain child cards (markdown notes). Users can create new trips and add cards within a trip. |
| **FR-009** | **Personal finance:** Users shall be able to view budget summaries by month (with bar charts), view transaction history, manage manual accounts (Checking, Savings, Credit, Investment) with balances, and simulate CSV file imports. |
| **FR-010** | **Journal:** Users shall be able to write journal entries with date, content, mood (`Happy`, `Neutral`, `Sad`, `Stressed`, `Energetic`), and optional tags. Entries are displayed in reverse chronological order. |
| **FR-011** | **Habit tracking:** Users shall be able to define habits with daily or weekly frequency, track completion by date, maintain streak counts, and toggle completion for the current day. |
| **FR-012** | **Goal setting:** Users shall be able to set goals with a title, description, type (`MONTHLY`, `YEARLY`, `LONG_TERM`), progress percentage, target date, status (`IN_PROGRESS`, `COMPLETED`, `FAILED`), and optional link to a project. |
| **FR-013** | **Meal logging and recipes:** Users shall be able to record meals (Breakfast, Lunch, Dinner, Snack) with descriptions, optional recipe references, and calories. Recipes include title, ingredients list, instructions, calorie count, tags, and optional image. |
| **FR-014** | **AI integration:** Users shall be able to configure AI providers (Gemini, OpenAI, Claude) with API keys, select an active model, and interact via a chat panel in the right drawer. The AI supports agent actions: creating tasks, creating goals, adding journal entries, and searching the user's data. AI features include note summarization and image generation for project artifacts. |
| **FR-015** | **Calendar / Week view:** The system shall provide a weekly calendar view with 7-column day grid and hourly time slots. Calendar events support types (event, task, reminder, deep-work), start/end times, optional location, and optional linked notes or tasks. Users can add, update, drag, and delete events. |
| **FR-016** | **Theme switching:** Users shall be able to switch between dark and light modes. The UI applies theme via CSS custom properties. |
| **FR-017** | **Responsive navigation:** The application shall provide a collapsible left navigation bar (with icon-only collapsed mode), a top bar with search and AI access, and a right drawer for context-sensitive detail (note, task, project, or AI chat). |
| **FR-018** | **Keyboard shortcuts:** The system shall support `Ctrl/Cmd + K` for command palette and `Escape` to close modals and overlays. |
| **FR-019** | **Workout tracking:** Users shall be able to view workout history with name, date, exercise count, and duration. (Module is currently placeholder; full CRUD is planned.) |
| **FR-020** | **Local-first ownership:** The architecture is designed for local-first data ownership with Markdown vault files as the source of truth. In Phase 0, data is mocked in-memory. Backend implementation will persist data to encrypted local storage (SQLCipher) indexed from vault files. |
| **FR-021** | **PII Shield:** The system shall detect and redact PII before sending data to cloud AI providers. (Planned for Phase 4 backend implementation.) |
| **FR-022** | **Morning Review (HITL):** Users shall be able to review and approve AI-generated content before it is written to the vault. (Planned for Phase 4.) |
| **FR-023** | **Unified search:** Users shall be able to search across all content. Phase 0 supports naive text matching. Backend will implement FTS5 (keyword) and sqlite-vec (semantic) search. |
| **FR-024** | **AI voice interaction:** Users shall be able to use voice input (audio transcription via Gemini) and receive spoken AI responses (text-to-speech via Gemini). Voice settings include preferred voice selection (Puck, Charon, Kore, Fenrir, Zephyr) and auto-speak toggle. |
| **FR-025** | **Quick Capture:** Users shall be able to quickly capture text thoughts that are appended to a daily capture file (`Quick Capture/{date}.md`). Available from the Today Dashboard. |
| **FR-026** | **Schedule management:** Users shall be able to view today's schedule as a timeline of time-blocked items. Tasks can be added to the schedule with a start time and duration. |

### Notes

- FR-001 through FR-019 cover currently implemented features in the frontend (Phase 0).
- FR-020 through FR-023 describe architectural goals; partial Phase 0 implementations exist.
- FR-024 through FR-026 cover features implemented in Phase 0 frontend.
- All FRs are sourced from the frontend implementation as the current source of truth for features. Backend and contracts must implement the IPC commands to support these requirements.
