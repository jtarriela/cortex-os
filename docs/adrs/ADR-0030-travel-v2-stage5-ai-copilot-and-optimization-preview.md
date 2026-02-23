# ADR-0030: Travel v2 Stage 5 — AI Copilot for Inspiration and Optimization Preview (Explicit Apply)

**Status:** IMPLEMENTED  
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-008 (current baseline; travel FR expansion pending)  
**Related:** ADR-0004 (AI multimodal), ADR-0005 (AI action/HITL patterns), ADR-0012 (test strategy), ADR-0017 (frontend hooks layer), ADR-0026 (Stage 2 itinerary/budget), ADR-0027 (Stage 3 routing/maps), ADR-0028 (Stage 4A import), ADR-0029 (Stage 4B Gmail scan), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md)

---

## Context

Travel v2 is intended to support AI-assisted trip planning, inspiration, and optimization. By Stage 5, the module will already have:

- structured trip/location/item data
- itinerary timeline semantics
- route metrics and map views
- imported travel data from manual and Gmail sources

This creates a strong foundation for AI assistance, but write safety remains critical. Users should benefit from AI planning suggestions without autonomous mutations.

---

## Decision

Stage 5 adds a Travel AI copilot with read-only suggestion workflows and explicit user apply actions.

### 1) AI planning support is suggestion-first

Stage 5 AI actions produce previews and recommendations only:

- ideas/inspiration suggestions
- itinerary/day optimization suggestions
- optional summaries/rationales

AI does not directly persist travel changes in this stage.

### 2) Optimization combines deterministic travel data with AI assistance

The optimization preview path should use:

- deterministic itinerary and route metrics from Stage 2/3
- optional AI-generated rationale/explanation and alternative suggestions

This avoids relying solely on LLM output for ordering/timing.

### 3) Apply path uses standard travel mutation commands

When a user accepts AI suggestions, the frontend applies them by calling existing travel CRUD/reorder/update commands.

No separate "AI mutate travel" command is introduced for v1.

### 4) Planner AI is a dedicated travel UX surface

Travel workspace adds a planner/copilot panel with explicit actions such as:

- `Inspire`
- `Optimize Day`
- `Summarize`

This is separate from generic chat and easier to reason about/test.

---

## Public Interface Additions (Stage 5)

Planned commands:

- `travel.aiSuggestIdeas`
- `travel.optimizeDayPlanPreview`

Response requirements:

- structured suggestions
- rationale / explanation text
- warnings / constraints conflicts
- diff-style output for proposed order/time changes

### Implementation Notes (2026-02-23)

- `travel.optimizeDayPlanPreview` is implemented as `reorder_first_v1` (reorder-first; retiming is informational-only in v1)
- frontend v1 supports explicit `Apply All` only, using existing travel mutation commands (no AI write command)
- optimization preview returns typed `changes[]` (`reorder` / `note`) plus `applyGuard` (`sourceItems[]`, `snapshotHash`) for stale-preview blocking
- optimization preview may return `responseMode="degraded_deterministic"` when deterministic preview generation succeeds but AI rationale enrichment fails

---

## Safety and UX Rules

- no AI-generated suggestion is applied without explicit user confirmation
- UI must clearly show "preview" vs "applied"
- failed AI calls must not block manual planning or routing features

---

## RAG Context Usage

Stage 5 AI commands may use:

- trip/location/item structured content
- linked research notes
- imported reservations and summaries

Travel AI suggestions should benefit from Stage 1 RAG indexing parity and linked-note support, but the command contract must remain bounded and predictable.

---

## Exit Criteria (Stage 5 Done)

1. Users can request travel ideas/inspiration scoped to a trip or location.
2. Users can request an optimization preview for a day itinerary and see proposed ordering/timing changes.
3. Accepted suggestions are applied through standard travel mutation commands (no autonomous AI writes).
4. Travel UI clearly distinguishes suggestion previews from persisted changes.
5. Backend/frontend/contracts documentation is synchronized for travel AI planner commands.

---

## Consequences

### Positive

- Delivers high-value AI support without sacrificing control
- Reuses structured travel and routing data for better-quality suggestions
- Keeps travel changes auditable through normal mutation paths

### Tradeoffs

- Users must perform explicit apply actions (slower than full automation)
- AI quality varies by provider/model and available context
