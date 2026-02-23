# ADR-0028: Travel v2 Stage 4A — URL/Text/Screenshot Import Pipeline (Preview + Commit)

**Status:** PROPOSED  
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-008 (current baseline; travel FR expansion pending)  
**Related:** ADR-0004 (AI multimodal), ADR-0005 (AI action/HITL patterns), ADR-0012 (test strategy), ADR-0017 (frontend hooks layer), ADR-0019 (linked-vault indexing/RAG), ADR-0022 (Vault Workbench write-back), ADR-0025 (Stage 1 foundation), [`005_TRAVEL_MODULE_INTEGRATION_PLAN`](../integration/005_TRAVEL_MODULE_INTEGRATION_PLAN.md)

---

## Context

Users want to create travel locations/items from information discovered on the web (especially Google Maps pages/content) without requiring Google Places API integration in v1.

The agreed v1 approach is:

- user pastes URL and/or text
- user can upload screenshots
- Cortex performs AI-assisted extraction and summarization
- user reviews/edits candidates before commit

This requires a dedicated travel import pipeline and UX. Current `ai_chat` request shape does not support image attachments and should not be overloaded for this structured workflow.

---

## Decision

Stage 4A introduces a travel-specific import preview/commit pipeline for manual sources.

### 1) Import is a two-step flow: preview then commit

New import behavior is split into:

- `travel.importPreview` (extraction + normalization proposal; no writes)
- `travel.importCommit` (persists approved candidates)

This preserves user control and makes the workflow testable and deterministic.

### 2) Supported source types (v1 Stage 4A)

- URL (`kind=url`)
- text (`kind=text`)
- screenshot/image (`kind=image_base64`)

Browser extension/clipper is explicitly out of scope for this stage.

### 3) AI extraction is travel-scoped and schema-validated

Backend import preview command is responsible for:

- AI-assisted extraction/OCR-assisted parsing (for screenshots)
- validation against travel candidate schema
- producing structured candidate rows for UI review
- generating optional AI summaries for locations/items

### 4) No direct persistence from AI output

Even high-confidence candidates remain preview-only until user commits.

---

## Public Interface Additions (Stage 4A)

Planned commands:

- `travel.importPreview`
- `travel.importCommit`

Expected preview output includes:

- structured candidates (location/item/expense possibilities)
- confidence
- warnings / ambiguity markers
- source attribution metadata

---

## UI/UX Requirements (Stage 4A)

Travel workspace import modal/wizard must support:

- paste URL/text
- add screenshot(s)
- preview candidate extraction
- inline edits before commit
- selective import (import some, skip some)
- explicit source attribution badges

---

## RAG / Indexing Requirements

All entities created by `travel.importCommit` must follow Travel v2 indexing parity:

- enqueue/process index jobs
- become searchable/RAG-visible immediately on the same semantics as other page writes

---

## Exit Criteria (Stage 4A Done)

1. Users can import candidate travel data from URL/text/screenshots with preview-before-write.
2. Screenshot-based import path is supported without changing generic `ai_chat` request shape.
3. Import commit writes structured travel entities and indexes them for search/RAG.
4. Ambiguous extractions are surfaced to users with edit/skip controls.
5. Backend/frontend/contracts documentation is synchronized for import preview/commit semantics.

---

## Consequences

### Positive

- Unlocks fast trip planning without requiring Google Places API in v1
- Reuses Cortex AI infrastructure while keeping travel import schema-specific
- Supports human review and auditability

### Tradeoffs

- Import extraction quality depends on provider/model performance and user-provided input quality
- Adds a new structured import workflow surface (more backend/frontend complexity)

