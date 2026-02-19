# ADR-0004: AI Multimodal Features (Voice I/O + Image Generation)

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Frontend implementation (Phase 0)
**FR:** FR-024 (Voice), FR-014 (Image Generation)
**Supersedes:** N/A
**Related:** FE-AD-03 (Direct Gemini calls in frontend)

---

## Context

The original AI architecture (`004_AI_INTEGRATION.md`) defines a text-only LLM gateway with chat, summarization, RAG, and link suggestion capabilities. It makes no mention of:

1. Voice input (speech-to-text)
2. Voice output (text-to-speech)
3. Image generation

During Phase 0, these multimodal features were implemented using direct Gemini SDK calls from the frontend.

## Decision

### Voice I/O

- **Speech-to-text:** `transcribeAudio()` in `aiService.ts` sends base64 WAV audio to Gemini for transcription
- **Text-to-speech:** `generateSpeech()` uses Gemini TTS API to synthesize speech from AI responses
- **Voice selection:** 5 voices (Puck, Charon, Kore, Fenrir, Zephyr) stored in `AISettings.preferredVoice`
- **Auto-speak:** `AISettings.autoSpeak` toggle for automatic TTS on AI responses
- **Audio capture:** Browser MediaRecorder API for microphone input
- **Live session:** Stub only (placeholder for Gemini Live API integration)

### Image Generation

- **`generateImageArtifact()`** in `aiService.ts` generates project images via Gemini image model
- **Context:** Prompt constructed from project title, description, and milestones
- **Storage:** Generated image stored as base64 data URL on `Project.artifacts[]`
- **Access:** Project Detail view displays generated artifacts

## Consequences

- The Rust LLM Gateway trait will need `transcribe()` and `synthesize()` methods in addition to `chat()` and `embed()`
- Image generation requires a model that supports image output (not all providers do)
- Base64 image storage on Project objects is temporary; backend should store in vault `assets/` folder
- Voice features require browser permissions (microphone); Tauri will need equivalent permission handling
- Token accounting must track audio/image generation separately from text tokens
- Not all providers support multimodal -- provider capability matrix needs updating

## Migration Path

Phase 4: Voice and image features move to Rust backend. `cortex_ai` crate gains `transcribe()`, `synthesize()`, and `generate_image()` methods. Frontend calls via Tauri IPC. API keys no longer exposed to browser. Provider trait extended with capability flags for multimodal support.
