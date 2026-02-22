# ADR-0014: Google Calendar Integration

## Status

**IMPLEMENTED** (2026-02-22) — Core OAuth/sync delivered with editable selected-calendar mirrors, source-event writeback, mirrored delete command, and progress telemetry.

## Phase 5 Verification Notes (2026-02-19, cortex-os#12)

### Verified Present
- `crates/integrations/google_calendar/` — compiles clean (`cargo check -p google_calendar` ✅)
- `oauth.rs` — RFC 8252 desktop loopback OAuth, CSRF state token, code exchange, token refresh
- `client.rs` — `GoogleCalendarClient` wrapper (list calendars, events CRUD)
- `sync.rs` — `SyncEngine` with incremental `syncToken`-based polling
- `models.rs` — serde-deserializable types for Google API responses
- Settings → Integrations tab — 4th tab in `Settings.tsx` with Connect/Sync UI
- IPC commands wired: `integrations_google_auth`, `integrations_google_calendars`, `integrations_trigger_sync`, `integrations_get_settings`, `integrations_update_settings`
- Storage: `integration_and_google_auth_roundtrip` test covers `GoogleAuthSettings` + `IntegrationSettings` persistence
- Phase 6 additions: `editable_calendars` settings, full-history initial sync behavior (no 90-day floor), `integrations_delete_mirrored_event`, `integrations_sync_progress` event payload, and calendar metadata response (`id/summary/backgroundColor/primary`)

### Smoke Test Evidence Added
- `google::oauth::tests::oauth_flow_requires_client_id_env_var` — verifies credential guard (no TCP/network)
- `google::oauth::tests::parse_callback_url_extracts_query_params` — verifies CSRF callback parsing
- `google::oauth::tests::parse_callback_url_rejects_empty_request` — rejects malformed requests
- `google::models::tests::google_event_deserializes_from_api_json` — full event + extendedProperties
- `google::models::tests::calendar_list_entry_deserializes_from_api_json` — calendar list with color
- `google::models::tests::google_event_all_day_uses_date_field` — all-day event variant

### Gaps Deferred to cortex-os-backend#26
| Command | Status |
|-|-|
| `integrations_disconnect_google` | Missing — revoke + page cleanup not implemented; only settings cleared |
| `integrations_google_auth_status` | Missing — covered partially by `integrations_get_settings` |
| `integrations_set_calendar_color` | Missing — no per-calendar color override |

## Context

Cortex OS provides a local Calendar and Week Planner (FR-015, FR-026) where tasks and events coexist on a unified timeline. The Week Planner features:

- A **sidebar** listing unscheduled tasks (backlog sorted by priority).
- A **7-column day grid** with hourly time slots.
- **Drag-to-schedule**: dragging a task from the sidebar onto a time slot sets its `scheduled` date and `start_time`, creating a time-blocked calendar entry per ADR-0007 (Schedule/Calendar Convergence).
- **Week/Month toggle**: the calendar grid supports switching between a weekly view (default) and a monthly view. Both views display synced events with the same color-coding and priority indicators.

The original architecture in `003_TASKS_AND_PLANNING.md` Section 3.4 scoped external calendar support as "Read-only CalDAV/ICS import", explicitly deferring two-way sync. However, the core scheduling UX — drag a task onto the planner, block the time — needs to reflect in the user's real calendar. Read-only sync breaks that loop. **Two-way sync is required.**

Additionally, users have multiple calendars within a single Google account (e.g. "Work", "Personal", "Birthdays"). Cortex must surface all of these and let users choose which to display, while keeping Cortex-originated events in a separate, dedicated calendar.

## Decision

We will implement Google Calendar integration as a **two-way sync** with multi-calendar support, a dedicated Cortex calendar, color-coding, and priority metadata on Cortex events.

### 1. Multi-Calendar Visibility

When a user connects a Google account, Cortex fetches the full calendar list via the Google Calendar API (`calendarList.list`). The user can then:

- See every calendar in the account (e.g. "Work", "Personal", "Holidays", shared calendars).
- Toggle which calendars are visible on the Week Planner.
- Each calendar's events appear on the grid with a distinct color (see Section 5).

Calendar list and visibility preferences are stored locally in the Cortex Vault settings.

### 2. Dedicated "Cortex" Calendar

On first sync, Cortex creates a new calendar named **"Cortex"** within the user's Google account (`calendars.insert`). All outbound events — tasks scheduled via drag-and-drop, Cortex-native events — are written to this calendar.

This keeps Cortex events separate from the user's existing calendars:

- Users can share, hide, or delete the Cortex calendar from Google's side without affecting other calendars.
- Other apps that read Google Calendar see Cortex events as a clean, identifiable source.
- The `google_calendar_id` for the Cortex calendar is stored in settings after creation.

### 3. Google OAuth Authentication

Cortex uses Google's **Desktop OAuth flow** with a loopback redirect per [RFC 8252](https://datatracker.ietf.org/doc/html/rfc8252) (OAuth 2.0 for Native Apps).

#### 3.1 Authentication Flow

```
User clicks "Connect Google Calendar" in Settings → Integrations
    │
    ▼
Backend: bind one-shot TCP listener on 127.0.0.1:<random_port>
    │
    ▼
Backend: open user's default browser (via tauri-plugin-shell) to:
    https://accounts.google.com/o/oauth2/v2/auth
      ?client_id=<CLIENT_ID>
      &redirect_uri=http://127.0.0.1:<port>/oauth/callback
      &response_type=code
      &scope=https://www.googleapis.com/auth/calendar
      &access_type=offline
      &prompt=consent
      &state=<CSRF_TOKEN>
    │
    ▼
User authenticates in browser, grants calendar permissions
    │
    ▼
Google redirects to: http://127.0.0.1:<port>/oauth/callback?code=...&state=...
    │
    ▼
Backend loopback server:
  1. Validates CSRF state token
  2. Returns HTML: "Authentication successful. You can close this tab."
  3. Exchanges code for tokens: POST https://oauth2.googleapis.com/token
  4. Stores access_token + refresh_token + expires_at in settings (key: "google_auth")
  5. Fetches account email via Google userinfo endpoint
  6. Closes the loopback listener
  7. Emits Tauri event "google_auth_complete" → { success, email }
    │
    ▼
Frontend: receives event, updates UI to "Connected as <email>"
```

Key parameters:
- `access_type=offline` — required to receive a refresh token.
- `prompt=consent` — forces a fresh refresh token on every authorization (needed for reconnect scenarios).
- `state=<UUIDv4>` — CSRF protection; validated on callback.

#### 3.2 Token Storage

Tokens are stored as a JSON blob in the `settings` table under key `google_auth`:

```rust
struct GoogleAuthSettings {
    access_token:       Option<String>,  // short-lived (~1 hour)
    refresh_token:      Option<String>,  // long-lived
    expires_at:         Option<i64>,     // unix timestamp (seconds)
    account_email:      Option<String>,  // for display in Settings UI
    cortex_calendar_id: Option<String>,  // the "Cortex" calendar we created
    last_synced_at:     Option<String>,  // ISO timestamp of last sync
}
```

The entire database is SQLCipher-encrypted (AES-256). **Tokens are never exposed to the frontend via IPC.** The frontend receives only a safe projection:

```rust
struct GoogleAuthStatus {
    is_connected:  bool,
    account_email: Option<String>,
    last_synced_at: Option<String>,
}
```

#### 3.3 Token Refresh

The backend refreshes expired access tokens transparently before any Google API call:

1. Check `expires_at` with a 60-second buffer.
2. If expired, `POST https://oauth2.googleapis.com/token` with `grant_type=refresh_token`.
3. Update `access_token` and `expires_at` in the settings table.
4. Return the fresh token to the calling API method.

This happens inside a `get_valid_access_token()` helper in `crates/integrations`. No frontend involvement.

#### 3.4 Client Credentials

Google classifies desktop apps as "public clients" — the client secret is embedded in the binary and is **not truly secret** (any user can extract it by decompiling). This is the accepted threat model per Google's documentation and RFC 8252.

Mitigation:
- `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are injected at build time via Rust `env!()` macros, keeping them out of source control.
- `.env` file (git-ignored) or CI secrets supply the values.
- The client secret alone cannot impersonate users (interactive consent is always required).

#### 3.5 Disconnect

When the user clicks "Disconnect":

1. Revoke the token via `POST https://oauth2.googleapis.com/revoke?token=<refresh_token>`.
2. Delete all Pages with `props.calendar_source = "google"` from the vault.
3. Clear the `google_auth` and `google_calendars` settings keys.
4. Return success even if the revocation API call fails (tokens invalidated locally).

#### 3.6 Security Summary

| Concern | Mitigation |
| ------- | ---------- |
| CSRF on callback | UUIDv4 `state` token generated per auth attempt, validated on callback |
| Loopback listener exposure | Auto-closes after one callback or 5-minute timeout; state token prevents injection |
| Token at rest | SQLCipher AES-256 database encryption |
| Token in transit (IPC) | Tokens never sent to frontend; only `GoogleAuthStatus` exposed |
| Client secret | Build-time injection via `env!()`; not in source control; public-client threat model accepted |
| Refresh token revocation | `disconnect_google` calls Google revoke endpoint + clears local storage |

### 4. Two-Way Sync

#### Inbound (Google → Cortex)

Events from all visible Google calendars are periodically fetched (polling with `syncToken` for incremental updates; webhook push as a future optimization). Each event is written to the Cortex Vault as a Page with `kind: event` and:

```yaml
calendar_source: google
google_event_id: <event_id>
google_calendar_id: <calendar_id>
google_calendar_name: "Work"
color: "#4285f4"
```

Inbound behavior is now **policy-based by selected calendar**:

- Calendars in `synced_calendars` but not `editable_calendars` remain read-only in Cortex.
- Calendars in `editable_calendars` are mirrored into task-style entities (task + linked note managed section + bridge metadata) and are writable from Cortex.
- Editable mirror changes write back to the original Google event in the source calendar.

#### Outbound (Cortex → Google)

When a task is dragged onto the Week Planner (setting `scheduled` + `start_time`) or a Cortex-native event is created/modified, the backend pushes the event to the **Cortex calendar** in Google via `events.insert` / `events.update` / `events.delete`.

The outbound event includes:

- Title, start/end times, description (from the Page body).
- An extended property `cortex_page_id` so Cortex can correlate on re-import.

`google_event_id` is written back to the Page frontmatter after creation to enable subsequent updates and deletes.

### 5. Color-Coding by Calendar

Each Google sub-calendar has a color (provided by the API or overridden by the user in Cortex settings). The Cortex calendar gets a default brand color (configurable).

On the Week Planner grid:

- Event blocks show a **left border or background tint** in their calendar's color.
- A **legend** (collapsible, in the sidebar or header) maps colors to calendar names.
- Cortex-originated events are visually distinct (e.g. solid fill vs. outlined for external events).

### 6. Priority and Tags on Cortex Events

Cortex events and scheduled tasks retain their `priority` and `tags` metadata from the Page frontmatter:

```yaml
priority: HIGH        # HIGH | MEDIUM | LOW | NONE
tags: [deep-work, backend]
```

On the Week Planner, these are rendered as:

- A **priority indicator** (e.g. colored dot or icon) on the event block — HIGH = red, MEDIUM = amber, LOW = blue, NONE = none.
- **Tag chips** shown on hover or in the context drawer when clicking an event.

Priority and tags are **not synced to Google** (Google Calendar has no equivalent fields). They exist only in the Cortex Vault and are displayed on the Cortex UI.

### 7. Week/Month View Toggle

The calendar grid supports two modes, toggled via a control in the header:

- **Week view** (default): 7-column day grid with hourly time slots. Events rendered as positioned blocks. Tasks draggable from sidebar onto time slots.
- **Month view**: Traditional month grid. Day cells show event dots/counts color-coded by calendar. Clicking a day drills into that day's detail or switches to week view centered on that week.

Both views share the same data queries (date-range filtered), color-coding, and priority indicators. The active view preference is persisted in user settings.

### 8. Frontend Changes (`cortex-os-frontend`)

#### 8.1 Settings → Integrations Tab

A new **4th tab** ("Integrations") is added to `Settings.tsx` alongside General, Intelligence, and Life Modules. It contains a Google Calendar integration card with three states:

**Not Connected:**
- Google Calendar icon + description ("Two-way sync with your Google calendars").
- Status badge: "Not connected".
- "Connect Google Calendar" button → calls `authenticate_google` IPC, transitions to Connecting state.

**Connecting:**
- Spinner + "Complete the authorization in your browser..."
- Cancel button (closes the loopback listener).
- Listens for Tauri event `google_auth_complete` to transition.

**Connected:**
- Green dot + "Connected as user@gmail.com" + relative last-sync timestamp.
- "Sync Now" button → calls `trigger_calendar_sync` IPC.
- "Disconnect" button → confirmation dialog → calls `disconnect_google` IPC.
- **Calendar list**: each calendar row shows:
  - Color swatch (clickable → color picker override).
  - Calendar name + badges ("Cortex" for the dedicated calendar, "Primary" for the Google primary).
  - Visibility toggle switch → calls `set_calendar_visibility` IPC.

#### 8.2 Frontend Types (`types.ts`)

```typescript
interface GoogleAuthStatus {
    isConnected: boolean;
    accountEmail?: string;
    lastSyncedAt?: string;
}

interface GoogleCalendarMeta {
    calendarId: string;
    name: string;
    color: string;
    isVisible: boolean;
    isPrimary: boolean;
    isCortexOwned: boolean;
}
```

#### 8.3 IPC Functions (`services/backend.ts`)

```typescript
getGoogleAuthStatus()           → Promise<GoogleAuthStatus>
authenticateGoogle()             → Promise<void>
disconnectGoogle()               → Promise<void>
getGoogleCalendars()             → Promise<GoogleCalendarMeta[]>
setCalendarVisibility(id, bool)  → Promise<GoogleCalendarMeta[]>
setCalendarColor(id, hex)        → Promise<GoogleCalendarMeta[]>
triggerCalendarSync()            → Promise<void>
```

#### 8.4 Tauri Event Listeners

```typescript
listen('google_auth_complete', (e) => { /* success/error, update UI */ })
listen('google_sync_complete', (e) => { /* events_synced count, update last-sync */ })
```

#### 8.5 Week Planner & Month View

- **Week Planner grid**: Render events with calendar color-coding, priority indicators, and tag chips. External (non-Cortex) events are non-draggable. Week/Month toggle in header.
- **Month view component**: Month grid with color-coded event dots, day click-through.
- **Sidebar**: Unscheduled tasks show priority badge. Dragging onto the grid triggers outbound sync to the Cortex Google calendar.

### 9. Backend Changes (`cortex-os-backend`)

#### 9.1 New Crate: `crates/integrations`

```
crates/integrations/src/
  lib.rs
  google/
    mod.rs
    oauth.rs     ← loopback server, URL builder, code exchange, refresh, revoke
    client.rs    ← reqwest wrapper for Google Calendar REST API + get_valid_access_token()
    sync.rs      ← background sync engine (poll + syncToken)
    models.rs    ← Google API response types (serde)
```

New workspace dependencies: `reqwest` (with `json` + `rustls-tls`), `tokio` (with `rt` + `net` + `time` + `sync`).

#### 9.2 Domain Types (`crates/core`)

- `GoogleAuthSettings` — token storage struct (see Section 3.2)
- `GoogleAuthStatus` — frontend-safe projection (see Section 3.2)
- `GoogleCalendarMeta` — calendar metadata with visibility/color
- `GoogleCalendarList` — `calendars: Vec<GoogleCalendarMeta>` + `sync_tokens: HashMap<String, String>`

All use `#[serde(rename_all = "camelCase")]` per existing convention.

#### 9.3 Storage Layer (`crates/storage`)

Extend `SettingsRepository` with:
- `get_google_auth()` / `set_google_auth()` / `clear_google_auth()` — key: `"google_auth"`
- `get_google_calendars()` / `set_google_calendars()` — key: `"google_calendars"`

Same upsert pattern as existing `get_ai_settings` / `set_ai_settings`.

#### 9.4 Async Strategy (`crates/app`)

OAuth and sync involve HTTP calls (async). The existing codebase uses synchronous Tauri commands with `Mutex<Connection>`. To bridge:

- Add `TokioRuntime(tokio::runtime::Runtime)` as Tauri managed state, created in `setup()`.
- OAuth/sync commands use `runtime.block_on(async { ... })` for HTTP operations.
- The DB `MutexGuard` is always dropped before any `.await` point, then re-acquired after.

#### 9.5 Tauri Plugin

Add `tauri-plugin-shell` for `shell::open()` (launching the browser). Register in `run()`:

```rust
.plugin(tauri_plugin_shell::init())
```

Add capability: `"shell:allow-open"`.

#### 9.6 Sync Engine

- Periodic background task (configurable interval, default 5 min).
- Tracks `syncToken` per calendar for incremental `events.list` polling.
- Conflict resolution: last-write-wins with user notification on conflicts.
- Page frontmatter fields: `google_event_id`, `google_calendar_id`, `google_calendar_name`, `color`.

### 10. Contract Changes (`cortex-os-contracts`)

New IPC commands:

| Command                    | Direction | Description                                      |
| -------------------------- | --------- | ------------------------------------------------ |
| `authenticate_google`      | FE → BE   | Initiate OAuth flow (loopback + browser), store tokens |
| `google_auth_status`       | FE → BE   | Return connection status (no tokens exposed)     |
| `disconnect_google`        | FE → BE   | Revoke tokens, delete synced data, clear settings |
| `get_google_calendars`     | FE → BE   | Return calendar list with colors and visibility  |
| `set_calendar_visibility`  | FE → BE   | Toggle a calendar's visibility on the planner    |
| `set_calendar_color`       | FE → BE   | Override a calendar's display color              |
| `trigger_calendar_sync`    | FE → BE   | Force an immediate inbound + outbound sync       |

Tauri events (BE → FE):

| Event                      | Payload                                           |
| -------------------------- | ------------------------------------------------- |
| `google_auth_complete`     | `{ success: bool, email?: string, error?: string }` |
| `google_sync_complete`     | `{ success: bool, events_synced: number, error?: string }` |

Existing `page_update` IPC already handles task/event mutations. The sync engine watches for changes to pages with `calendar_source: cortex` and pushes outbound automatically — no sync flag needed on individual updates.

### 11. Documentation Updates

- `003_TASKS_AND_PLANNING.md` Section 3.4: Replace "Two-way sync is deferred" with reference to this ADR.
- FR-027: "Two-Way Google Calendar Sync with Multi-Calendar Support" (added to `functional_requirements.md`).
- `docs/traceability.md`: FR-027 mapped to `cortex-os-backend` and `cortex-os-frontend`.

## Consequences

### Positive

- Seamless scheduling: dragging a task onto the Week Planner blocks time in the user's real Google Calendar automatically.
- Full calendar picture: users see all their calendars in one view without switching apps.
- Clean separation: Cortex events live in their own Google calendar, not polluting existing ones.
- Priority and tag metadata give the Week Planner richer context than Google Calendar alone.
- Standard OAuth flow (RFC 8252) — well-understood security model for desktop apps.

### Negative

- **OAuth complexity**: Token lifecycle (refresh, revoke, expiry), loopback server, and Google API quotas add operational burden.
- **Sync conflicts**: Concurrent edits to the same event in Google and Cortex require conflict resolution (last-write-wins with notification as initial strategy).
- **API dependency**: Google Calendar API changes or outages degrade the sync experience. Cortex must function fully offline with local data; sync resumes when connectivity returns.
- **Scope increase**: Multi-calendar + color-coding + priority rendering + OAuth is significantly more frontend and backend work than the original "read-only import" scope.
- **Client secret exposure**: Desktop apps cannot protect the client secret. Accepted per Google's threat model; mitigated by build-time injection and rotation capability.

### Mitigations

- Sync engine is a background task; UI never blocks on API calls.
- All Google-sourced data is cached locally — Cortex works offline, syncs when available.
- The Cortex calendar is clearly separated, so accidental deletion of user calendars is not a risk.
- Tokens encrypted at rest (SQLCipher) and never exposed to the frontend.
- Loopback listener has a 5-minute timeout and CSRF state validation.

## References

- `docs/technical_architecture/003_TASKS_AND_PLANNING.md` — Task/Event schemas, Week Planner spec, Section 3.4
- ADR-0007: Schedule/Calendar Convergence
- FR-015: Calendar / Week View
- FR-026: Schedule Management
- FR-027: Google Calendar Sync
- [RFC 8252: OAuth 2.0 for Native Apps](https://datatracker.ietf.org/doc/html/rfc8252)
- [Google OAuth for Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
