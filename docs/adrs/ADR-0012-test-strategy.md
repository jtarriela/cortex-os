# ADR-0012: Test Strategy

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** All (cross-cutting)
**Supersedes:** N/A
**Related:** `.system/PROTOCOL.md` (TDD mandate), `docs/traceability.md`

---

## Context

The project has zero tests. The `.system/PROTOCOL.md` mandates TDD-first development: "No feature implementation logic may be written until a failing test exists." The traceability matrix (`docs/traceability.md`) references planned test files (`frontend/tests/tasks.spec.tsx`, `backend/tests/tasks.rs`, etc.) that do not exist.

The frontend `package.json` has no `test` script. No test framework is installed. The backend has no `Cargo.toml` (no code exists yet).

This ADR establishes the test framework choices, directory structure, and Phase 0 test scope.

## Decision

### Frontend Test Stack

| Tool | Purpose |
|------|---------|
| **Vitest** | Test runner (integrates natively with Vite, same config) |
| **React Testing Library** | Component rendering and interaction testing |
| **@testing-library/jest-dom** | DOM assertion matchers |

### Backend Test Stack

| Tool | Purpose |
|------|---------|
| **`#[test]` (built-in)** | Standard Rust unit tests |
| **rstest** | Parameterized tests and fixtures |
| **tempfile** | Temporary vault directories for integration tests |

### Frontend Directory Structure

```
frontend/
  src/
    __tests__/
      services/
        dataService.test.ts      # CRUD contract tests for all modules
        aiService.test.ts        # AI service mock tests
      views/
        TodayDashboard.test.tsx  # Render + interaction smoke tests
        TasksIndex.test.tsx
        WeekDashboard.test.tsx
        ...
      types/
        types.test.ts            # Type validation / guard tests
    test-utils/
      render.tsx                 # Custom render with providers
      mocks.ts                   # Shared mock data factories
```

### Backend Directory Structure

```
crates/
  cortex_core/
    src/lib.rs
    tests/
      page_model.rs              # Page, Property, Kind tests
  cortex_storage/
    src/lib.rs
    tests/
      sqlcipher.rs               # Encryption/decryption (Spike 2)
      fts5.rs                    # Full-text search (Spike 3)
      sqlite_vec.rs              # Vector search (Spike 4)
      combined.rs                # All three together (Spike 5)
      repositories.rs            # CRUD operations against EAV schema
  cortex_vault/
    tests/
      read_write.rs              # Markdown read/write round-trip
      watcher.rs                 # FS event tests
  cortex_index/
    tests/
      frontmatter_parse.rs       # YAML → EAV normalization
      change_detection.rs        # Hash-based skip logic
```

### Test Categories

| Category | Scope | When to Run |
|----------|-------|-------------|
| **Unit** | Isolated functions, pure logic, type validation | On every save (watch mode) |
| **Integration** | Component + service, DB operations, IPC round-trips | On commit (pre-commit hook) |
| **E2E** | Full Tauri app, WebDriver-based | On PR / CI pipeline (Phase 2+) |

### Package.json Updates (Phase 0)

Add to `devDependencies`:
```json
{
  "vitest": "^3.x",
  "@testing-library/react": "^16.x",
  "@testing-library/jest-dom": "^6.x",
  "@testing-library/user-event": "^14.x"
}
```

Add to `scripts`:
```json
{
  "test": "vitest",
  "test:run": "vitest run",
  "test:coverage": "vitest run --coverage"
}
```

## Phase 0 Test Scope

Focus on **high-value, transferable tests** — tests that will remain valid when `dataService.ts` is replaced with Tauri IPC invokes:

### Priority 1: dataService Contract Tests

Test every exported function in `dataService.ts` for input/output correctness. These tests assert the **interface contract**, not the implementation. When the implementation changes from in-memory to IPC, the assertions stay the same:

```typescript
// Example: dataService.test.ts
describe('addTask', () => {
  it('creates a task with required fields', () => {
    const task = addTask({ title: 'Test task', priority: 'HIGH' });
    expect(task.id).toBeDefined();
    expect(task.title).toBe('Test task');
    expect(task.status).toBe('TODO');
  });
});
```

### Priority 2: View Rendering Smoke Tests

Test that each view renders without crashing given mock data. Not deep interaction testing — just "does it render":

```typescript
// Example: TasksIndex.test.tsx
describe('TasksIndex', () => {
  it('renders without crashing', () => {
    render(<TasksIndex tasks={mockTasks} />);
    expect(screen.getByText('Tasks')).toBeInTheDocument();
  });
});
```

### Priority 3: AI Service Mock Tests

Test `aiService.ts` function declarations and tool-calling logic with mocked Gemini responses. Verify that tool calls dispatch to the correct `dataService` functions.

## Consequences

- **No more untested code.** After this ADR, all new features and bug fixes must include tests per the TDD mandate.
- **CI gate.** Tests must pass before PR merge. The test script is added to the CI pipeline (when CI is set up).
- **Traceability alignment.** Test file locations in `docs/traceability.md` are updated to match the directory structure defined here.

## Enforcement

PRs that add functionality without corresponding tests must be rejected with a reference to this ADR and `.system/PROTOCOL.md`.
