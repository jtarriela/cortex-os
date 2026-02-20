# ADR-0013: Voice/Audio Architecture — Bundled Whisper + Configurable TTS + Chained Voice Chat

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** FR-024 (Voice I/O)
**Supersedes:** N/A (extends ADR-0004 voice section)
**Related:** ADR-0004 (AI multimodal features), ADR-0005 (agent actions), `004_AI_INTEGRATION.md` Sections 1.2, 2.1, 5.6

---

## Context

The Phase 0 voice implementation has three architectural weaknesses:

1. **STT is not a real transcription model.** `transcribeAudio()` in `aiService.ts:100-121` sends audio to `gemini-3-flash-preview` via `generateContent` — a multimodal generation model that produces transcription as a side-effect of prompting. This is slower, less accurate, and more expensive than a purpose-built STT model.

2. **TTS is locked to Gemini.** `generateSpeech()` in `aiService.ts:123-145` uses `gemini-2.5-flash-preview-tts` with 5 hardcoded voices (Puck, Charon, Kore, Fenrir, Zephyr). No provider abstraction exists — switching TTS providers requires rewriting the function.

3. **Both run in the browser.** Audio data and API keys transit the frontend, violating the backend-only execution principle (same class of violation as ADR-0004, specific to voice).

Additionally, the `LlmProvider` trait in `004_AI_INTEGRATION.md` has no voice methods, and the provider capability table has no STT/TTS columns. ADR-0004 noted that `transcribe()` and `synthesize()` need to be added but did not specify the architecture.

## Phase 5 Implementation Deviation (2026-02-20)

Local Whisper runtime integration is deferred. Current shipped default sets `sttProvider = gemini` (online STT) while retaining `local_whisper` as a selectable/deferred path. This deviation is temporary until the following are implemented:

- Native `whisper-rs` runtime integration in backend.
- Tiered GGML model asset lifecycle (download/load/update/select).
- Audio preprocessing pipeline (MediaRecorder payload -> PCM16 mono/16k) with deterministic tests.

---

## Decision: STT — Bundled Whisper (Local-First)

### Primary: whisper-rs

`whisper-rs` (Rust bindings to whisper.cpp) is bundled with the Tauri app, providing offline speech-to-text with zero API cost. The model runs entirely on-device via the `cortex_ai` crate.

**Distribution tiers** (one model per installer variant, build-time choice):

| Tier | Model | Size | Accuracy | Use Case |
|------|-------|------|----------|----------|
| Lite | `whisper-tiny` or `whisper-base` | 39 MB / 74 MB | Adequate for clear speech | Low-storage devices, fast transcription |
| Standard | `whisper-small` | 244 MB | Good balance | **Default distribution** |
| Full | `whisper-large-v3-turbo` | 809 MB | High accuracy | Accents, technical vocabulary, noisy environments |

`whisper-large-v3` (1.5 GB) is excluded — it exceeds the acceptable installer size budget.

**Model file location:** `resources/models/whisper/whisper-{size}.bin` (GGML format, bundled in app resources).

**Call path:**
```
Frontend (MediaRecorder → base64 WAV)
  → Tauri IPC: invoke("ai_transcribe", { audio_b64, mime_type })
  → cortex_ai crate → whisper-rs → bundled GGML model
  → TranscribeResult { text, detected_language, provider_used, duration_ms }
```

### Cloud Fallback (User-Selected)

If the user opts into cloud transcription via Settings → Voice → STT Provider:

| Priority | Provider | Model | Cost | Requires |
|----------|----------|-------|------|----------|
| Default | Local Whisper | whisper-{tier} | Free | Nothing (bundled) |
| Fallback 1 | OpenAI | `gpt-4o-mini-transcribe` | $0.003/min | OpenAI API key |
| Fallback 2 | Gemini | `generateContent` (multimodal) | Per-token | Gemini API key |

**Important:** Fallback is user-initiated (Settings selection), not automatic. The app does not silently fall back to cloud when local Whisper struggles — the user explicitly chooses their STT provider.

---

## Decision: TTS — Configurable Provider

The TTS provider is selectable in Settings. The interface is provider-agnostic: `text in → audio bytes out`.

| Provider | Model | Voices | Features | Requires |
|----------|-------|--------|----------|----------|
| **Gemini TTS** | `gemini-2.5-flash-preview-tts` | 5 (Puck, Charon, Kore, Fenrir, Zephyr) | Current Phase 0 implementation | Gemini API key |
| **OpenAI TTS** | `gpt-4o-mini-tts` | 13+ (alloy, ash, ballad, coral, echo, fable, onyx, nova, sage, shimmer, verse, marin, cedar) | Instructable voice (affect/style), high quality | OpenAI API key |
| **Local TTS** | Piper (ONNX runtime) | Many open-source voice models | Offline, zero cost | Phase 5+ (planned, not current) |

**Settings impact:** The `AISettings` type in `types.ts` gains:
- `sttProvider: 'local_whisper' | 'openai' | 'gemini'` (target default: `'local_whisper'`; **current implementation default: `'gemini'` per Phase 5 deviation**)
- `ttsProvider: 'gemini' | 'openai' | 'local'` (default: `'gemini'`)
- `preferredVoice` becomes provider-specific (Gemini voice names are not valid for OpenAI)

---

## Decision: Voice Chat Architecture

### Standard Mode — Chained Pipeline

```
1. Mic (browser MediaRecorder API)
2. → Raw audio bytes (base64 WAV)
3. → Tauri IPC: invoke("ai_transcribe", { audio_b64 })
4. → cortex_ai: Local Whisper (or cloud STT fallback)
5. → Transcribed text
6. → Tauri IPC: invoke("ai_chat", { message: transcribed_text, ... })
7. → Any provider (Claude / GPT / Gemini) + tool use if agent mode
8. → Response text
9. → Tauri IPC: invoke("ai_synthesize", { text, voice_config })
10. → cortex_ai: configured TTS provider
11. → Audio bytes returned to frontend
12. → Browser AudioContext plays audio
```

**Key property:** The LLM step (step 7) is completely decoupled from voice. Any text LLM works — Claude, GPT, Gemini, Ollama — with full tool-calling support. Voice is an I/O layer, not a model constraint.

### Alternative: Native Speech-to-Speech (Phase 5+)

| Approach | Latency | Tool Use | Provider |
|----------|---------|----------|----------|
| **Chained** (STT → LLM → TTS) | Higher (3 steps) | Full — any provider | Any combination |
| **OpenAI Realtime** (`gpt-realtime` via WebRTC) | Low (continuous stream) | Yes (function calling) | OpenAI only |
| **Gemini Live Audio** | Low (continuous stream) | Yes | Gemini only |
| **Anthropic** | N/A — no native voice API | N/A | Chained only |

Native speech-to-speech is documented for future consideration but **not** the Phase 1-4 implementation target. The chained approach is preferred because:
- Provider-agnostic (works with Claude, which has no voice API)
- Full control over each pipeline step (PII shield can inspect text between STT and LLM)
- Simpler to implement and debug

---

## Decision: Multi-Provider Tool Use

The current agentic flow (4 Gemini function declarations in `aiService.ts:14-67`) translates directly to all three providers. The application-layer tool definitions are provider-agnostic:

```rust
pub struct ToolDef {
    pub name: String,
    pub description: String,
    pub parameters: serde_json::Value,  // JSON Schema
}
```

The LLM Gateway in `cortex_ai` translates `ToolDef` to each provider's native format:

| Provider | API | Tool Format | Schema Enforcement |
|----------|-----|-------------|-------------------|
| **OpenAI** | Responses API | `function` type with `strict: true` | JSON Schema validation guaranteed |
| **Anthropic** | Messages API | `tools` parameter, `tool_use`/`tool_result` turns | Schema validated, not strict-enforced |
| **Gemini** | `generateContent` | `functionDeclarations` in `tools` | Schema declared, model may deviate |

All three support parallel multi-tool calls per turn. The four Cortex agent tools (`addTask`, `addGoal`, `addJournalEntry`, `searchBrain`) are defined once as `ToolDef` structs and translated per provider — no duplication.

---

## Migration Path

| Phase | STT | TTS | Agent Tools |
|-------|-----|-----|-------------|
| **Phase 0** (current) | Gemini `generateContent` in browser | Gemini TTS in browser | Gemini function declarations only |
| **Phase 4** (target) | `ai_transcribe` IPC → whisper-rs (local) or cloud | `ai_synthesize` IPC → configured provider | `ai_chat` IPC with provider-agnostic `ToolDef` |
| **Phase 5+** (future) | Local Whisper + native speech-to-speech options | Local Piper TTS + native options | Same tool surface |

---

## Consequences

- **Installer size:** Increases by 74-809 MB depending on Whisper tier. The `001_architecture.md` Section 9 performance budget (`< 15MB` binary) must be split into "binary" vs "binary + bundled models."
- **`AISettings` type changes:** New fields `sttProvider`, `ttsProvider`, provider-specific voice selection.
- **IPC surface:** Two new commands `ai_transcribe` and `ai_synthesize` added to `001_architecture.md` Section 6.2.
- **Token accounting:** `usage_log` gains `feature = "transcribe"` and `feature = "synthesize"` entries. Local Whisper logs with `provider = "local_whisper"` and zero cost.
- **Voice Settings UI:** Redesigned to show STT/TTS provider selection, not just voice name.
- **`LlmProvider` trait:** Gains `transcribe()` and `synthesize()` methods (per ADR-0004's note). `whisper-rs` is a separate `LocalTranscriber` that bypasses the provider trait.
- **AD-18:** New architectural decision added to `001_architecture.md` Section 13.

## Enforcement

When `cortex_ai` is implemented, the voice pipeline must use the local Whisper path by default. Any PR that adds cloud-only STT without the local fallback must be rejected with a reference to this ADR.
