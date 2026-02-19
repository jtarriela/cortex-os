# ADR-0005: Frontend AI Agent Actions (Direct Tool-Calling Without HITL)

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Frontend implementation (Phase 0)
**FR:** FR-014
**Supersedes:** N/A
**Related:** FE-AD-03, ADR-0004
**Conflicts with:** `004_AI_INTEGRATION.md` Section 0 (Principles 1 & 2), Section 9 (Morning Review), Section 11 (HITL column)

---

## Context

The original AI architecture establishes two firm principles:

1. **"Backend-only execution"** -- All LLM calls happen in Rust. No API keys or content transit the frontend.
2. **"Human-in-the-loop"** -- AI proposes, user approves. No autonomous vault writes.

The agentic roadmap (Section 11) explicitly shows all write tools routing through a Morning Review approval queue with HITL approval before any vault modification.

During Phase 0, the frontend implements direct tool-calling that violates both principles.

## Decision

The frontend's AI chat (`aiService.ts`) includes 4 Gemini function declarations that execute CRUD operations immediately when the LLM invokes them:

| Tool | Parameters | Action | HITL? |
|------|-----------|--------|-------|
| `addTask` | title, description, priority, dueDate, status | Creates task via `dataService.addTask()` | **No** |
| `addGoal` | title, description, type | Creates goal via `dataService.addGoal()` | **No** |
| `addJournalEntry` | content, mood | Creates journal entry via `dataService.addJournalEntry()` | **No** |
| `searchBrain` | query | Searches via `dataService.searchGlobal()` | N/A (read-only) |

The function declarations are passed to Gemini via `tools: [{ functionDeclarations }]`. When Gemini returns a function call, the frontend executes it immediately and sends the result back for the model to formulate a natural-language response. Tool results are surfaced in the UI as notifications.

## Rationale

- Phase 0 is a prototype; data is ephemeral (in-memory, resets on reload)
- Adding an approval queue would significantly slow AI interaction prototyping
- The risk is minimal: no persistent data, no vault writes, no real PII exposure
- This validates the tool-calling UX before building the backend approval infrastructure

## Consequences

- **Architecture violation:** This explicitly contradicts the HITL principle. The violation is accepted for Phase 0 only.
- **UX expectation:** Users accustomed to immediate execution may resist the approval queue in later phases
- **No undo:** If the AI creates an incorrect task/goal/journal entry, the user must manually delete it
- **Security:** In Phase 0 (mock data), risk is negligible. In Phase 1+ with real data, this pattern MUST NOT persist without HITL safeguards.
- **Migration complexity:** The Morning Review approval queue is a prerequisite before agent actions can persist real data

## Migration Path

Phase 4: Agent tool calls route through the Rust backend. Write tools queue to `review_queue` table (see `004_AI_INTEGRATION.md` Section 9). Read-only tools (`searchBrain`) execute immediately. Morning Review UI provides batch approve/reject/edit. The frontend tool-calling pattern converts to Tauri IPC calls: `invoke("ai_agent_execute", { action, params })` which internally queues rather than executes.

## Enforcement

When Phase 1 (Tauri IPC wiring) begins, the direct `dataService.*` calls in agent action execution **MUST** be replaced with IPC invocations. The backend handler **MUST** implement the queue pattern, not pass-through execution. This ADR transitions to IMPLEMENTED only when the HITL approval flow is in place.
