# ADR-0029: Travel v2 Stage 4B — User-Triggered Gmail Reservation Scan and Import

**Status:** PROPOSED  
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-008 (current baseline; travel FR expansion pending)  
**Related:** ADR-0004 (AI multimodal), ADR-0005 (AI action/HITL patterns), ADR-0012 (test strategy), ADR-0014 (Google integration patterns), ADR-0015 (secure settings), ADR-0025 (Stage 1 foundation), ADR-0028 (Stage 4A import pipeline), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md)

---

## Context

Users want Cortex to help detect flight/hotel/reservation information from Gmail and offer a guided import flow such as:

- "This popped up in your inbox — add to trip?"

The agreed v1 product direction is privacy-conscious and explicit:

- Gmail scan is **user-triggered only**
- Gmail-derived suggestions are previewed before import
- Cortex stores/indexes structured extracted reservations, not raw email bodies/attachments by default

Stage 4A already defines a preview/commit import pipeline pattern for manual sources. Gmail scan should reuse the same interaction model.

---

## Decision

Stage 4B adds Gmail-based reservation discovery as a trip-scoped preview/commit import workflow.

### 1) Gmail scan is user-triggered only (v1)

No background polling, inbox watcher, or continuous monitoring in this stage.

Users explicitly initiate scan from the Travel workspace for a selected trip/date range.

### 2) Gmail results are candidates, not direct writes

Gmail scan produces reservation candidates with confidence and extracted fields. Users must review/edit/select candidates before import commit.

### 3) Storage and indexing policy is structured-data-first

Cortex persists:

- structured reservation entities (`trip_item`, optional `trip_expense`)
- optional sanitized snippets and source metadata

Cortex does **not** index/store raw email content or attachments by default in Stage 4B.

### 4) Gmail import reuses preview/commit semantics from Stage 4A

Gmail scan and import should align with the same UI/approval mental model as manual import:

- preview
- edit
- commit selected candidates

This minimizes user confusion and implementation duplication.

### 5) Gmail support may be feature-flagged if OAuth/review scope rollout is delayed

If Gmail OAuth scope approval or implementation timeline blocks release, Stage 4B may ship behind a feature flag without changing the contract shape.

---

## Public Interface Additions (Stage 4B)

Planned commands:

- `travel.gmailScanPreview`
- `travel.gmailImportCommit`

Expected preview response should include:

- candidate list (reservation/provider guesses)
- confidence and extraction warnings
- sanitized snippet preview
- message metadata reference (message id hash/ref, sender, subject, date)
- scan stats (scanned/filtered/matched)

---

## OAuth / Integration Notes

Stage 4B requires Gmail read access (for example `gmail.readonly`) in addition to existing Google Calendar integrations.

Design requirement:

- Gmail token/scope handling must not regress existing Calendar integration behavior
- secure settings/token handling must follow ADR-0015 patterns

Exact auth implementation split (shared Google auth flow vs separate Gmail auth path) may vary, but the user-facing behavior and command contracts defined here are stable.

---

## Deduplication and Provenance Rules

To avoid duplicate imports:

- imported candidates store source provenance metadata (message reference + reservation identifier when available)
- repeated scans should mark existing imports as already imported/skippable where possible

---

## RAG / Indexing Requirements

Entities created by `travel.gmailImportCommit` must be indexed under the same parity rules as all Travel v2 writes.

The policy remains:

- structured extracted reservation data is RAG-accessible
- raw email content is not RAG-indexed by default

---

## Exit Criteria (Stage 4B Done)

1. User can trigger Gmail scan from a trip and receive reservation candidates.
2. Candidates can be reviewed/edited and selectively imported to travel items/expenses.
3. Imported entities are deduplicated/provenance-tagged and indexed for search/RAG.
4. Raw Gmail message bodies are not indexed by default.
5. Backend/frontend/contracts documentation is synchronized for Gmail scan/import semantics.

---

## Consequences

### Positive

- Adds a high-value travel automation workflow without background monitoring complexity
- Keeps privacy posture stronger than indexing raw emails
- Reuses Stage 4A preview/commit UX model

### Tradeoffs

- Users must manually trigger scans
- Gmail OAuth scope and provider rollout may add operational/compliance overhead

