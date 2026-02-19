# ADR-0010: Reading Module — Future Collection Template

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** None assigned
**Supersedes:** N/A
**Related:** `002_COLLECTIONS.md` Section 6 (Reading collection definition)

---

## Context

`002_COLLECTIONS.md` defines a complete Reading collection with:

- Schema: `media_type` (book, article, paper, podcast, video), `author`, `status` (want_to_read, reading, finished, abandoned), `rating`, `started`, `finished`, `source_url`, `notes`
- Board view grouped by `status`
- Gallery view with cover images
- Folder: `Reading/`

However:
- No `Reading` view exists in the frontend
- No `reading` entry in `NavSection` enum or `FeatureFlags` type
- No functional requirement (FR) is assigned
- No mention in any phase of the implementation roadmap

## Decision

The Reading collection definition is retained in `002_COLLECTIONS.md` as a **future collection template**. It is not committed for implementation in Phases 0-4.

## Rationale

- The collection definition is a useful design artifact showing how the collection system handles a media-tracking use case
- No user demand has been established for this module
- The collection engine (Phase 1) will make it trivial to add Reading as a user-created collection without dedicated frontend code
- Once the collection engine exists, a Reading collection can be created entirely through `.cortex/collections/reading.json` with no code changes

## Consequences

- Reading is **not** added to `FeatureFlags`, `NavSection`, or the functional requirements
- The `002_COLLECTIONS.md` definition is preserved as reference material
- When the collection engine is built (Phase 1), Reading becomes a template that users can enable from Settings
- If user demand warrants a dedicated view (beyond generic collection views), a new ADR and FR will be created at that time
