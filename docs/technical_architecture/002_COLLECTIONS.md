# Cortex Life OS — Collections & Domain Modules

**Status:** Draft v1
 **Date:** 2026-02-18
 **Parent:** `001_architecture.md`
 **Scope:** Collection definitions, schemas, and view configurations for life planning domains

------

## 0) Collections Philosophy

"Travel," "Finance," "Workouts," and "Habits" are **not separate features with bespoke code.** They are **pre-configured Collections** — JSON definitions that tell the query engine which pages to select, what properties to expect, and which view layouts to offer.

> **Phase 0 Divergence:** The frontend implements domain modules as bespoke React view components (`Goals.tsx`, `Meals.tsx`, `Journal.tsx`, `Habits.tsx`, `Travel.tsx`, etc.) with domain-specific TypeScript types, **not** as generic collection views. Each view has hardcoded UI rather than rendering through a universal `collection_query()` + layout engine. The migration to the collection abstraction will happen when the backend collection engine is built. See ADR-0001 (Goals), ADR-0002 (Meals), ADR-0003 (Journal).

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

## 7) Goals

> **Phase 0 Addition.** Not in the original architecture vision. Added during Phase 0 frontend prototyping. See ADR-0001, FR-012.

### 7.1 Schema

```json
{
    "id": "col_goals",
    "name": "Goals",
    "icon": "target",
    "selector": { "kind": "goal" },
    "schema": {
        "title": { "type": "text", "required": true },
        "description": { "type": "text" },
        "goal_type": {
            "type": "select",
            "options": ["MONTHLY", "YEARLY", "LONG_TERM"],
            "required": true,
            "label": "Timeframe"
        },
        "progress": { "type": "number", "default": 0, "label": "Progress (%)" },
        "target_date": { "type": "date", "label": "Target date" },
        "status": {
            "type": "select",
            "options": ["IN_PROGRESS", "COMPLETED", "FAILED"],
            "default": "IN_PROGRESS"
        },
        "project": {
            "type": "relation",
            "label": "Linked project"
        }
    },
    "default_view": "view_goals_gallery",
    "folder": "Goals"
}
```

**Example goal page:**

```markdown
---
id: pg_01JFC2...
kind: goal
title: Learn TypeScript
description: Master advanced types and generics.
goal_type: MONTHLY
progress: 60
target_date: 2026-03-31
status: IN_PROGRESS
project: /Projects/TS Mastery.md
tags: [learning, engineering]
created: 2026-02-01T10:00:00Z
modified: 2026-02-18T14:30:00Z
---
# Learn TypeScript

## Notes

Week 1: Completed basic types, interfaces, and unions.
Week 2: Working through generics and utility types.

## Key Resources
- TypeScript Handbook
- Type Challenges repo
```

### 7.2 Views

**Gallery View (default):** Cards showing title, type badge, progress bar, target date, and status indicator. Color-coded by status (green = in progress, blue = completed, red = failed).

**Board View:** Kanban grouped by `status`. Columns: In Progress, Completed, Failed. Useful for reviewing goals at a glance.

### 7.3 Goal → Project Linkage

Goals can optionally link to a Project page via the `project` relation property. This creates a bidirectional connection:

- Goal card shows linked project name
- Project detail view shows linked goals in a sidebar widget
- Progress can be synchronized (manual or AI-assisted) — when project milestones complete, the linked goal's progress can be updated

------

## 8) Meals & Recipes

> **Phase 0 Addition.** Not in the original architecture vision. Added during Phase 0 frontend prototyping. See ADR-0002, FR-013.

### 8.1 Schema

```json
{
    "id": "col_meals",
    "name": "Meals",
    "icon": "utensils",
    "selector": { "kind_any": ["meal", "recipe"] },
    "schema": {
        "meal_type": {
            "type": "select",
            "options": ["BREAKFAST", "LUNCH", "DINNER", "SNACK"],
            "label": "Meal"
        },
        "date": { "type": "date" },
        "description": { "type": "text" },
        "calories": { "type": "number", "label": "Calories (kcal)" },
        "recipe": {
            "type": "relation",
            "label": "Recipe"
        },
        "ingredients": {
            "type": "multi_select",
            "options": [],
            "label": "Ingredients"
        },
        "instructions": { "type": "text", "label": "Instructions" },
        "image_url": { "type": "url", "label": "Image", "hidden": true }
    },
    "default_view": "view_meals_list",
    "folder": "Meals"
}
```

Meals works as two kinds of pages:

- `kind: meal` — a single meal entry (date, type, description, calories, optional recipe link)
- `kind: recipe` — a recipe definition (title, ingredients, instructions, calories, image)

The `recipe` relation on a meal page points to a recipe page, enabling reuse — log "Avocado Toast" for breakfast by linking to the recipe rather than re-entering details.

**Example meal page:**

```markdown
---
id: pg_01JFC3...
kind: meal
date: 2026-02-18
meal_type: BREAKFAST
description: Avocado toast with a fried egg
calories: 350
recipe: /Meals/recipes/avocado-toast.md
tags: [breakfast, quick]
created: 2026-02-18T08:00:00Z
---
# Breakfast — Feb 18

Avocado toast with a fried egg and everything bagel seasoning.
```

**Example recipe page:**

```markdown
---
id: pg_01JFC4...
kind: recipe
title: Avocado Toast
ingredients: [bread, avocado, egg, salt, pepper, everything bagel seasoning]
instructions: |
  1. Toast bread until golden
  2. Mash avocado with salt and pepper
  3. Fry egg sunny-side up
  4. Spread avocado on toast, top with egg
calories: 350
image_url: assets/avocado-toast.jpg
tags: [breakfast, quick, vegetarian]
created: 2026-02-01T12:00:00Z
---
# Avocado Toast

A quick, healthy breakfast staple.
```

### 8.2 Views

**List View (default, meals):** Date-grouped list of meals showing type badge, description, calories. Daily calorie total shown as a summary row.

**Gallery View (recipes):** Card grid showing recipe image, title, calorie count, and tags. Filtered to `kind: recipe` only.

### 8.3 Calorie Aggregation

The collection query engine can compute daily/weekly calorie totals by aggregating `calories` across meals for a date range. This powers a dashboard widget showing nutritional trends.

> **Phase 0 Divergence:** `Meals.tsx` manages all meal and recipe state locally in the component — no `dataService.ts` functions exist. This is the only module with this pattern. Before Phase 1 IPC wiring, CRUD must be extracted to `dataService.ts`. See traceability.md FR-013.

------

## 9) Journal & Mood Tracking

> **Phase 0 Addition.** Not in the original architecture vision. Added during Phase 0 frontend prototyping. See ADR-0003, FR-010.

### 9.1 Schema

```json
{
    "id": "col_journal",
    "name": "Journal",
    "icon": "book-heart",
    "selector": { "kind": "journal_entry" },
    "schema": {
        "date": { "type": "date", "required": true },
        "mood": {
            "type": "select",
            "options": ["Happy", "Neutral", "Sad", "Stressed", "Energetic"],
            "label": "Mood"
        }
    },
    "default_view": "view_journal_list",
    "default_sort": { "property": "date", "direction": "desc" },
    "folder": "Journal"
}
```

**Example journal entry page:**

```markdown
---
id: pg_01JFC5...
kind: journal_entry
date: 2026-02-18
mood: Energetic
tags: [productivity, cortex]
created: 2026-02-18T21:30:00Z
---
# Feb 18, 2026

Productive day. Got the DB Actor pattern design done and started on the
indexing pipeline. Feeling good about the architecture direction.

Had a great workout in the morning — push day, bench is progressing.
Energy was high all day, probably because I slept 7.5 hours.

## Gratitude
- Making progress on Cortex
- Good weather for a walk at lunch
- Partner made dinner
```

### 9.2 Views

**List View (default):** Reverse-chronological feed. Each entry shows date, mood badge (emoji or colored dot), and a content preview. The full entry expands on click.

### 9.3 Mood Analytics (Phase 4+)

The structured `mood` property enables future analytics:

- Mood trends over time (line chart, weekly/monthly)
- Correlation with habits (e.g., "you tend to feel Energetic on days you work out")
- AI-powered insights from journal content + mood data

> **Phase 0 Divergence (MINOR):** The frontend implements `content` as a top-level field on the `JournalEntry` interface. In the Page model, content is the markdown body (below the frontmatter), not a frontmatter property. The migration is straightforward: `content` moves from frontmatter to the `## Body` of the markdown file.

------

## 10) Custom Collections (User-Created)

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

## 11) Collection Query Engine (`collection_query`)

This is the single most important backend function. Every view in the app calls it.

### 11.1 Query Parameters

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

### 11.2 Query Execution

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

### 11.3 Result Shape (CardDTO)

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

## 12) View Layout Specifications

### 12.1 Gallery

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

### 12.2 Table

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

### 12.3 Board (Kanban)

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

### 12.4 Calendar

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

### 12.5 Map

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

### 12.6 List

Simple vertical list. Minimal chrome. Good for quick scanning.

------

## 13) Cross-Collection Relationships

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

## 14) Collection Templates (Shipped with App)

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
| Goals    | goal                         | Gallery, Board (status)             | Goals/    |
| Meals    | meal, recipe                 | List (date), Gallery (recipes)      | Meals/    |
| Journal  | journal_entry                | List (reverse-chrono)               | Journal/  |

> **Phase 0 Addition:** Goals, Meals, and Journal are not in the original vision. They were added during Phase 0 frontend prototyping. See ADR-0001, ADR-0002, ADR-0003.

Users can modify any template after installation. Deleting a collection config doesn't delete the pages — they're still in the vault, just not grouped into a view.