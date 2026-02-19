# Cortex Life OS — Collections & Domain Modules

**Status:** Draft v1
 **Date:** 2026-02-18
 **Parent:** `001_ARCHITECTURE_v1.md`
 **Scope:** Collection definitions, schemas, and view configurations for life planning domains

------

## 0) Collections Philosophy

"Travel," "Finance," "Workouts," and "Habits" are **not separate features with bespoke code.** They are **pre-configured Collections** — JSON definitions that tell the query engine which pages to select, what properties to expect, and which view layouts to offer.

Adding a new life domain (e.g., "Recipes," "Reading List," "Home Projects") means creating a new `.cortex/collections/*.json` file and optionally a new view config. No Rust code changes. No frontend component changes.

The only code that "knows" about specific domains is:

1. **Collection templates** shipped with the app (sensible defaults for common life domains)
2. **Optional adapter logic** for domain-specific import/export (CSV import for finance, ICS for calendar, etc.)
3. **Pre-built view presets** that pair well with certain schemas (map view for travel, chart view for finance)

------

## 1) Collection Definition Format

Every collection is defined by a JSON file in `.cortex/collections/`:

```json
{
    "id": "col_travel",
    "name": "Travel",
    "icon": "plane",
    "description": "Trips, destinations, and travel planning",
    "selector": {
        "kind": "trip"
    },
    "schema": {
        "destination": {
            "type": "text",
            "label": "Destination",
            "required": true
        },
        "start": {
            "type": "date",
            "label": "Start Date"
        },
        "end": {
            "type": "date",
            "label": "End Date"
        },
        "budget_usd": {
            "type": "currency",
            "label": "Budget",
            "default": 0
        },
        "status": {
            "type": "select",
            "label": "Status",
            "options": ["dreaming", "planning", "booked", "in_progress", "completed"],
            "default": "dreaming"
        },
        "travel_type": {
            "type": "select",
            "label": "Type",
            "options": ["vacation", "business", "family", "adventure", "weekend"]
        },
        "companions": {
            "type": "multi_select",
            "label": "Companions",
            "options": []
        },
        "cover_image": {
            "type": "text",
            "label": "Cover Image",
            "hidden": true
        },
        "location": {
            "type": "location",
            "label": "Coordinates"
        },
        "location_name": {
            "type": "text",
            "label": "Location Name"
        }
    },
    "default_view": "view_travel_gallery",
    "folder": "Travel",
    "views": ["view_travel_gallery", "view_travel_calendar", "view_travel_map", "view_travel_table"]
}
```

### Selector Rules

The selector determines which pages belong to a collection. Rules are AND-combined:

| Selector Key  | Behavior                                  | Example                               |
| ------------- | ----------------------------------------- | ------------------------------------- |
| `kind`        | Match `frontmatter.kind` exactly          | `"kind": "trip"`                      |
| `path_prefix` | Match vault path prefix                   | `"path_prefix": "Travel/"`            |
| `tag`         | Page must have this tag                   | `"tag": "finance"`                    |
| `tags_any`    | Page must have at least one of these tags | `"tags_any": ["workout", "exercise"]` |
| `kind_any`    | Match any of these kinds                  | `"kind_any": ["task", "bug"]`         |

Pages can belong to **multiple collections** if they match multiple selectors. A task tagged `#travel` could appear in both the Tasks collection and a "Travel Tasks" filtered view.

------

## 2) Travel Planning

### 2.1 Schema

A trip is a page with `kind: trip`. The body contains freeform planning notes, itinerary details, packing lists, and embedded maps.

**Example page: `Travel/Japan 2026.md`**

~~~markdown
---
id: pg_01JF9A...
kind: trip
destination: Tokyo & Kyoto
start: 2026-04-10
end: 2026-04-20
budget_usd: 4500
status: planning
travel_type: vacation
companions: [partner]
cover_image: assets/japan-cover.jpg
location: "35.6762,139.6503"
location_name: "Tokyo, Japan"
tags: [travel, asia, 2026]
created: 2026-01-15T10:00:00Z
modified: 2026-02-18T14:30:00Z
---
# Japan 2026

## Itinerary

### Day 1–3: Tokyo
- Shibuya, Harajuku, Akihabara
- TeamLab Planets
- Tsukiji outer market

```cortex-map
lat: 35.6762
lng: 139.6503
zoom: 12
markers:
  - lat: 35.6586
    lng: 139.7454
    label: "Tokyo Tower"
  - lat: 35.7148
    lng: 139.7967
    label: "Senso-ji Temple"
  - lat: 35.6654
    lng: 139.7707
    label: "TeamLab Planets"
~~~

### Day 4–5: Hakone

- Ryokan stay
- Hot springs + Mt. Fuji views

### Day 6–8: Kyoto

- Fushimi Inari
- Arashiyama bamboo grove

## Budget Breakdown

| Category   | Estimate |
| ---------- | -------- |
| Flights    | $1,200   |
| Hotels     | $1,800   |
| Food       | $800     |
| Transport  | $400     |
| Activities | $300     |

## Packing List

- [ ] Passport (expires 2028 ✓)
- [ ] JR Pass (7-day)
- [ ] Power adapter (Type A)
- [ ] Rain jacket

## Related Notes

- [[Japanese phrases]]
- [[Tokyo restaurant research]]

```
### 2.2 Views

**Gallery View (default):** Cards showing cover image, destination, dates, status badge, budget. Think Pinterest board of trips.

```json
{
    "id": "view_travel_gallery",
    "collection_id": "col_travel",
    "name": "Trip Gallery",
    "layout": "gallery",
    "query": {
        "sort": [{"key": "start", "dir": "desc"}],
        "projection": ["destination", "start", "end", "status", "budget_usd", "cover_image", "location_name"]
    },
    "config": {
        "card_size": "medium",
        "cover_field": "cover_image",
        "title_field": "destination",
        "subtitle_template": "{start} — {end}",
        "badge_field": "status",
        "badge_colors": {
            "dreaming": "purple",
            "planning": "blue",
            "booked": "green",
            "in_progress": "yellow",
            "completed": "gray"
        }
    }
}
```

**Calendar View:** Trips plotted on a calendar by start/end date range. Useful for seeing trip density and overlap.

**Map View:** All trips plotted on a world map using their `location` coordinates. Click a pin to open the trip card.

```json
{
    "id": "view_travel_map",
    "collection_id": "col_travel",
    "name": "Trip Map",
    "layout": "map",
    "query": {
        "filter": [{"key": "location", "op": "is_not_empty"}],
        "projection": ["destination", "status", "start", "location", "location_name"]
    },
    "config": {
        "lat_field": "location",
        "label_field": "destination",
        "color_field": "status",
        "default_zoom": 2,
        "default_center": [20, 0]
    }
}
```

**Table View:** Spreadsheet-style view for budget tracking and comparison across trips.

### 2.3 Sub-Items Pattern

For itinerary items, restaurant bookings, activities within a trip — these are **child pages** linked via the `relation` property:

```markdown
---
id: pg_01JF9B...
kind: trip_item
trip: /Travel/Japan 2026.md
item_type: activity
day: 2
title: TeamLab Planets
start: 2026-04-11T10:00
end: 2026-04-11T13:00
cost_usd: 35
location: "35.6654,139.7707"
booked: true
tags: [travel, japan]
---
# TeamLab Planets

Digital art museum in Toyosu. Book tickets online 2 weeks ahead.
Wear shorts — you'll wade through water.
```

These child items can have their own collection (`col_trip_items`) with a board/timeline view grouped by day number.

------

## 3) Finance Tracking

### 3.1 Schema

Finance uses two kinds: `account` (a financial account) and `transaction` (individual entries). Budgets are accounts with `account_type: budget_category`.

**Collection: `.cortex/collections/finance.json`**

```json
{
    "id": "col_finance",
    "name": "Finance",
    "icon": "wallet",
    "selector": {
        "kind_any": ["account", "transaction", "budget"]
    },
    "schema": {
        "account_type": {
            "type": "select",
            "options": ["checking", "savings", "credit", "investment", "budget_category"]
        },
        "balance": { "type": "currency" },
        "amount": { "type": "currency" },
        "category": {
            "type": "select",
            "options": ["housing", "food", "transport", "utilities", "entertainment", "health", "savings", "income", "other"]
        },
        "transaction_date": { "type": "date" },
        "recurring": { "type": "boolean" },
        "vendor": { "type": "text" }
    },
    "default_view": "view_finance_dashboard",
    "folder": "Finance"
}
```

**Example account page: `Finance/checking-chase.md`**

```markdown
---
id: pg_01JFA1...
kind: account
account_name: Chase Checking
account_type: checking
balance: 4250.00
currency: USD
institution: Chase
last_reconciled: 2026-02-15
tags: [finance, checking]
---
# Chase Checking

Primary checking account for daily expenses.
Auto-pay: rent, utilities, subscriptions.
```

**Example budget page: `Finance/feb-2026-budget.md`**

```markdown
---
id: pg_01JFA2...
kind: budget
month: 2026-02
total_income: 6500
total_budgeted: 5800
categories:
  housing: 1800
  food: 600
  transport: 200
  utilities: 250
  entertainment: 300
  health: 150
  savings: 1500
  other: 1000
tags: [finance, budget, 2026]
---
# February 2026 Budget

## Notes
- Increased food budget by $50 (eating out more this month)
- Extra $500 to savings goal for Japan trip
```

### 3.2 Views

**Dashboard View (custom):** The finance "page" is a collection view with multiple sub-views composited:

- Summary cards: total across accounts, net worth trend
- Table view: accounts list with balances
- Chart view: income vs. expenses by month (Recharts)
- Category breakdown: budget vs. actual per category

**Table View:** All transactions sortable by date, category, amount. Filter by date range, category.

**Board View:** Transactions grouped by category (Kanban-style) — useful for categorizing uncategorized imports.

### 3.3 CSV Import Adapter

Finance is the one domain that benefits from a dedicated import adapter:

```
Frontend: User selects CSV file + mapping config
    → invoke("finance_import_csv", { file_path, column_map })
    → Rust: parse CSV → create transaction pages in Finance/ folder
    → Indexer picks them up → appear in finance collection
```

The column mapping UI lets users specify which CSV columns map to which schema properties (date, amount, vendor, category). Saved mappings persist for repeated imports from the same bank.

This is **the only domain-specific backend code** for finance. Everything else flows through the generic collection system.

### 3.4 YNAB Integration (Later)

Read-only sync from YNAB API → creates/updates transaction pages. Deferred to Phase 4+ because it requires OAuth and ongoing API maintenance.

------

## 4) Workouts & Fitness

### 4.1 Schema

```json
{
    "id": "col_workouts",
    "name": "Workouts",
    "icon": "dumbbell",
    "selector": { "kind": "workout" },
    "schema": {
        "workout_type": {
            "type": "select",
            "options": ["strength", "cardio", "flexibility", "sport", "other"]
        },
        "date": { "type": "date", "required": true },
        "duration_min": { "type": "number", "label": "Duration (min)" },
        "rating": {
            "type": "select",
            "options": ["1", "2", "3", "4", "5"],
            "label": "How'd it feel?"
        },
        "program": {
            "type": "relation",
            "label": "Program"
        },
        "muscles": {
            "type": "multi_select",
            "options": ["chest", "back", "shoulders", "arms", "core", "legs", "full_body"]
        },
        "completed": { "type": "boolean", "default": false }
    },
    "default_view": "view_workouts_calendar",
    "folder": "Workouts"
}
```

**Example workout page:**

```markdown
---
id: pg_01JFB1...
kind: workout
workout_type: strength
date: 2026-02-18
duration_min: 65
rating: "4"
muscles: [chest, shoulders, arms]
completed: true
tags: [workout, push-day]
---
# Push Day — Feb 18

## Exercises

| Exercise | Sets x Reps | Weight | Notes |
|----------|------------|--------|-------|
| Bench Press | 4x8 | 185 lbs | Last set RPE 9 |
| OHP | 3x10 | 95 lbs | Felt strong |
| Incline DB Press | 3x12 | 55 lbs | |
| Lateral Raises | 4x15 | 20 lbs | Superset with front raises |
| Tricep Pushdowns | 3x15 | 40 lbs | |
| Dips | 3x12 | BW | |

## Notes
Solid session. Bench is progressing — add 5 lbs next week.
Energy was good, slept 7.5 hours last night.
```

### 4.2 Views

**Calendar View (default):** Workouts plotted on a monthly calendar, color-coded by workout_type. Quick visual of training frequency and consistency.

**Table View:** Log-style table sorted by date. Good for reviewing volume and progression over time.

**Gallery View:** Cards showing date, type, duration, rating. Useful for scrolling through recent sessions.

### 4.3 Workout Programs (Sub-Collection)

Programs are pages with `kind: program` that link to workout template pages:

```markdown
---
id: pg_01JFB2...
kind: program
name: "PPL 6-Day Split"
status: active
start: 2026-01-06
weeks: 12
current_week: 7
tags: [workout, program]
---
# PPL 6-Day Split

## Schedule
- Mon: Push
- Tue: Pull
- Wed: Legs
- Thu: Push
- Fri: Pull
- Sat: Legs
- Sun: Rest

## Progression
Add 5 lbs to compounds each week. Deload every 4th week.
```

------

## 5) Habits & Routines

### 5.1 Schema

```json
{
    "id": "col_habits",
    "name": "Habits",
    "icon": "repeat",
    "selector": { "kind_any": ["habit", "habit_log"] },
    "schema": {
        "habit_name": { "type": "text", "required": true },
        "frequency": {
            "type": "select",
            "options": ["daily", "weekdays", "weekly", "custom"]
        },
        "streak": { "type": "number", "default": 0 },
        "target": { "type": "number", "label": "Daily target" },
        "unit": { "type": "text", "label": "Unit (glasses, minutes, etc.)" },
        "log_date": { "type": "date" },
        "log_value": { "type": "number" },
        "completed": { "type": "boolean" }
    },
    "default_view": "view_habits_board",
    "folder": "Habits"
}
```

Habits work as two kinds of pages:

- `kind: habit` — the habit definition (name, frequency, target)
- `kind: habit_log` — daily check-ins linked to the habit via `relation`

The Today Dashboard queries habit logs for today and renders streak/completion UI.

------

## 6) Reading List / Learning

### 6.1 Schema

```json
{
    "id": "col_reading",
    "name": "Reading",
    "icon": "book-open",
    "selector": { "kind": "reading" },
    "schema": {
        "media_type": {
            "type": "select",
            "options": ["book", "article", "paper", "course", "podcast", "video"]
        },
        "author": { "type": "text" },
        "status": {
            "type": "select",
            "options": ["want_to_read", "reading", "finished", "abandoned"]
        },
        "rating": {
            "type": "select",
            "options": ["1", "2", "3", "4", "5"]
        },
        "started": { "type": "date" },
        "finished": { "type": "date" },
        "url": { "type": "url" }
    },
    "default_view": "view_reading_board",
    "folder": "Reading"
}
```

Board view grouped by `status` is the natural default — a Kanban of reading progress.

------

## 7) Custom Collections (User-Created)

Users can create their own collections via the Settings UI or by manually adding a JSON file to `.cortex/collections/`. The UI flow:

1. Click "New Collection" in sidebar
2. Name it, choose icon, select folder
3. Define properties (type picker for each)
4. Choose default view layout
5. Cortex writes the JSON config and creates the vault folder

**Example user-created collection: Home Projects**

```json
{
    "id": "col_home_projects",
    "name": "Home Projects",
    "icon": "hammer",
    "selector": { "kind": "home_project" },
    "schema": {
        "room": {
            "type": "select",
            "options": ["kitchen", "bathroom", "bedroom", "living_room", "garage", "yard"]
        },
        "estimated_cost": { "type": "currency" },
        "actual_cost": { "type": "currency" },
        "status": {
            "type": "select",
            "options": ["idea", "planned", "in_progress", "done"]
        },
        "contractor_needed": { "type": "boolean" },
        "priority": {
            "type": "select",
            "options": ["high", "medium", "low"]
        }
    },
    "default_view": "view_home_board",
    "folder": "Home Projects"
}
```

------

## 8) Collection Query Engine (`collection_query`)

This is the single most important backend function. Every view in the app calls it.

### 8.1 Query Parameters

```typescript
interface CollectionQueryParams {
    collection_id: string;
    view_id?: string;           // if provided, uses view's saved query
    filters?: Filter[];         // override or add to view filters
    sorts?: Sort[];
    group_by?: string;          // property key for board/grouped views
    projection?: string[];      // which props to return (performance)
    search?: string;            // FTS query within collection
    limit?: number;             // default 50
    cursor?: string;            // pagination cursor (page_id of last result)
}

interface Filter {
    key: string;                // property key
    op: "eq" | "neq" | "gt" | "lt" | "gte" | "lte" | "contains" | "not_contains" | "is_empty" | "is_not_empty" | "in" | "not_in";
    value: any;
}

interface Sort {
    key: string;
    dir: "asc" | "desc";
}
```

### 8.2 Query Execution

```sql
-- Generated query for: Travel collection, gallery view, status = "planning"
SELECT
    p.page_id, p.title, p.path, p.kind,
    MAX(CASE WHEN pp.key = 'destination' THEN pp.value_text END) as destination,
    MAX(CASE WHEN pp.key = 'start' THEN pp.value_date END) as start_date,
    MAX(CASE WHEN pp.key = 'end' THEN pp.value_date END) as end_date,
    MAX(CASE WHEN pp.key = 'status' THEN pp.value_text END) as status,
    MAX(CASE WHEN pp.key = 'budget_usd' THEN pp.value_num END) as budget_usd,
    MAX(CASE WHEN pp.key = 'cover_image' THEN pp.value_text END) as cover_image
FROM pages p
JOIN page_props pp ON p.page_id = pp.page_id
WHERE p.kind = 'trip'                              -- collection selector
  AND p.page_id IN (
      SELECT page_id FROM page_props
      WHERE key = 'status' AND value_text = 'planning'  -- view filter
  )
GROUP BY p.page_id
ORDER BY start_date DESC
LIMIT 50;
```

The query engine builds this SQL dynamically from the collection selector + view query + runtime params. The EAV pivot (MAX CASE) pattern is standard for this storage model.

### 8.3 Result Shape (CardDTO)

```typescript
interface CardDTO {
    page_id: string;
    title: string;
    path: string;
    kind: string;
    cover?: string;
    props: Record<string, any>;  // only projected properties
    tags: string[];
    linked_count: number;
}
```

The frontend view components receive `CardDTO[]` and render based on layout type. The gallery renders cards, the table renders rows, the board renders columns, the calendar renders date-positioned blocks, the map renders pins.

------

## 9) View Layout Specifications

### 9.1 Gallery

Grid of cards. Each card shows: cover image (optional), title, subtitle (template string from props), status badge, and 2–3 key properties.

**Config:**

```json
{
    "card_size": "small" | "medium" | "large",
    "cover_field": "cover_image",
    "title_field": "title",
    "subtitle_template": "{destination} · {start}",
    "badge_field": "status",
    "visible_props": ["budget_usd", "travel_type"]
}
```

### 9.2 Table

Spreadsheet-style rows and columns. Columns are properties. Supports inline editing, column resize, column reorder, multi-sort.

**Config:**

```json
{
    "columns": [
        { "key": "title", "width": 250, "frozen": true },
        { "key": "status", "width": 120 },
        { "key": "due", "width": 120 },
        { "key": "priority", "width": 100 }
    ],
    "row_height": "compact" | "normal" | "tall",
    "show_row_numbers": false
}
```

### 9.3 Board (Kanban)

Columns grouped by a `select` property (typically `status`). Cards are draggable between columns. Drag updates the property value → writes frontmatter → re-indexes.

**Config:**

```json
{
    "group_by": "status",
    "column_order": ["TODO", "DOING", "BLOCKED", "DONE"],
    "card_props": ["priority", "due", "assignee"],
    "hide_empty_columns": false
}
```

### 9.4 Calendar

Pages with date properties placed on a month/week/day grid. Date range pages (start + end) render as spans. Drag to reschedule.

**Config:**

```json
{
    "date_field": "start",
    "end_date_field": "end",
    "default_range": "month",
    "color_field": "status",
    "label_template": "{title}"
}
```

### 9.5 Map

Pages with `location` properties plotted on a Leaflet map. Clusters for density. Click pin → card popup.

**Config:**

```json
{
    "location_field": "location",
    "label_field": "title",
    "color_field": "status",
    "default_zoom": 2,
    "default_center": [20, 0],
    "cluster_at_zoom": 8
}
```

### 9.6 List

Simple vertical list. Minimal chrome. Good for quick scanning.

------

## 10) Cross-Collection Relationships

Pages link to pages. A task can reference a project. A trip can reference related notes. These links are stored as:

1. **`relation` property in frontmatter:** `project: /Projects/Cortex.md`
2. **Wiki-links in body:** `[[Japanese phrases]]`
3. **AI-suggested links:** Stored in `graph_edges` with `edge_type: ai_suggested`

All three types produce edges in `graph_edges`. The Context Drawer shows backlinks for any focused page, regardless of which collection it belongs to.

**Cross-collection query example:** "Show me all tasks related to the Japan trip"

```
collection_query("col_tasks", filters: [
    { key: "project", op: "eq", value: "pg_01JF9A..." }  // Japan trip page_id
])
```

Or via graph traversal: find all pages within 1 hop of the Japan trip page.

------

## 11) Collection Templates (Shipped with App)

On first launch or when creating a new vault, Cortex offers to install collection templates:

| Template | Kind(s)                      | Default Views                       | Folder    |
| -------- | ---------------------------- | ----------------------------------- | --------- |
| Tasks    | task                         | Board (status), Table, Today filter | Tasks/    |
| Projects | project                      | Gallery, Board (status), Table      | Projects/ |
| Calendar | event                        | Calendar (week), Calendar (month)   | Calendar/ |
| Travel   | trip, trip_item              | Gallery, Calendar, Map, Table       | Travel/   |
| Finance  | account, transaction, budget | Dashboard, Table                    | Finance/  |
| Workouts | workout, program             | Calendar, Table, Gallery            | Workouts/ |
| Habits   | habit, habit_log             | Board, Calendar                     | Habits/   |
| Notes    | note                         | List, Gallery                       | Notes/    |
| Reading  | reading                      | Board (status), Table               | Reading/  |

Users can modify any template after installation. Deleting a collection config doesn't delete the pages — they're still in the vault, just not grouped into a view.