---
sidebar_position: 5
title: "Kaori AI Architecture"
---

# Kaori AI Architecture

Deep-dive into how TrickBook's AI companion system works — one LLM brain serving three surfaces, a streaming voice sidecar, and a 3D body that acts out what she says.

Status: **Current — live in prod** · Last updated: 2026-07-09

:::tip Related pages
Feature overview: [AI Companions](/docs/features/ai-companions) · Path to users: [Companions Launch Audit](/docs/roadmap/companions-launch) · Business model: [Monetization](/docs/roadmap/monetization)
:::

## System Overview

Kaori is TrickBook's flagship AI companion — a dry, understated snowboarder (homage to SSX's Kaori Nishidake) who chats, acts on your TrickBook data via tools, speaks with a real voice, and physically demonstrates tricks on a 3D stage. Three client surfaces converge on **one brain** inside TB-Backend:

```
   Web: Kaori Live + DMs        Mobile: companion chat      Mobile: 3D stage (voice)
   pages/kaori-live.js          bot chat screen             KaoriStage + useKithVoice
        │                            │                            │
        │ POST /api/dm               │ POST /api/bot-chat/        │ POST /api/bot-chat/message
        │ (+ x-kith-session)         │      message               │ (+ x-kith-session)
        ▼                            ▼                            ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │                     TB-Backend (Express, PM2)                        │
  │    routes/dm.js ────────────┐        ┌──────── routes/botChat.js     │
  │                             ▼        ▼                               │
  │                 kaori-ai-response.js  — "the brain"                  │
  │       persona · unified memory · onStage gating · tool loop          │
  │                             │                                        │
  │        kaori-tools.js ──────┼────── MongoDB Atlas (TrickList2)       │
  │                             ▼                                        │
  │                 OpenRouter → Gemini Flash                            │
  └──────────────────┬───────────────────────────────────────────────────┘
                     │ fire-and-forget POST /speak/:sessionId
                     ▼
       kith-voice (Bun, :3040) ─→ Python sidecar (Pipecat) ─→ ElevenLabs
                     │ WS: turn/tts/emotion events + audio chunks
                     ▼
       client — gapless playback, mouth-sync, choreography cues
```

| Component | Tech | Purpose |
|-----------|------|---------|
| **TB-Backend** | Express.js, PM2 `TB-Backend` | API server, DM + bot-chat routing, Kaori brain |
| **kaori-ai-response.js** | Node, OpenRouter | Persona, memory merge, tool-calling loop |
| **kaori-tools.js** | Node | Tool registry + MongoDB execution |
| **kith-voice** | Bun + [Kith](https://github.com/wbaxterh/kith), PM2 `kith-voice` :3040 | Voice sessions, WS event stream, `/speak` API |
| **Python sidecar** | Pipecat (vendored) | Streaming ElevenLabs TTS pipeline |
| **MongoDB Atlas** | TrickList2 database | App data + all conversation memory |

Kith is our own OSS voice runtime ([github.com/wbaxterh/kith](https://github.com/wbaxterh/kith)). Everything runs on the single prod EC2 instance behind nginx (`api.thetrickbook.com`).

---

## The Brain: TB-Backend

Both entry points — `routes/dm.js` (web DMs / Kaori Live) and `routes/botChat.js` (mobile chat + 3D stage) — persist the user message, then call `generateKaoriResponse()` in `kaori-ai-response.js`. There is no separate AI server: the brain is an in-process module.

### Persona

`KAORI_SYSTEM_PROMPT` is a corpus-mined **dry rider register**: 1–3 short sentences, no cheerleader openers, praise as one specific line ("that back lip was clean"), rationed hype, real trick vocabulary ("front three", "back lip"), and an explicit banned-poser-vocabulary list ("shred the gnar", "I'd be happy to help", …). Register examples are baked into the prompt so the model imitates rhythm, not just rules.

### Unified cross-surface memory

Kaori remembers you *across surfaces*. Every reply merges recent context from both message stores:

1. **`dm_messages`** — web Kaori Live / DM surface (last 8; conversation looked up by participants if the caller has no conversation id)
2. **`bot_chats`** — mobile chat + 3D-stage voice (last 8)

The two are merged chronologically, trimmed to the most recent 12, and deduped against the current prompt (callers persist the user message before invoking the brain). Tell her your name on the web and she knows it on the stage.

On top of that, a **relationship profile** (`companion_profiles` collection) tracks interaction count, a relationship stage (stranger → acquaintance → friend → close_friend → bestie), remembered facts, name, sports, and last-session mood — all injected into the system prompt so her energy adapts as you rack up messages.

### Tool-calling loop

The brain calls OpenRouter (**Gemini Flash**, `google/gemini-3.5-flash`) with the full tool registry, `tool_choice: auto`, max 3 iterations. Tool results are fed back as `role: tool` messages until the model produces text. Registry (`kaori-tools.js`):

| Tool | Purpose |
|------|---------|
| `search_spots` | Find skateparks / resorts / breaks in `ck_spots` |
| `search_trickipedia` | Look up tricks by name or category |
| `get_user_tricklists` | The user's real lists with resolved trick names |
| `create_tricklist` | Create a list (flagged `createdBy: 'kaori'`) |
| `add_trick_to_list` | Add a trickipedia trick to a list |
| `update_trick_status` | Mark trick progress on a list |
| `lookup_boardsport_knowledge` | Curated boardsport knowledge base (`kaori-knowledge.json`) |
| `remember_user_info` | Persist name / sports / facts to the relationship profile |

The prompt is explicit that saying "I added it" without calling the tool means it didn't happen — no hallucinated writes. A pgvector RAG lookup (`kaori-rag/`) is a **silent-optional** path: wrapped in try/catch, injected only if the module exists and returns hits.

### onStage gating

When a request carries a valid `x-kith-session` header (a UUID minted by the voice service), the caller sets `{ onStage: true }` and the brain appends `STAGE_DEMO_PROMPT`: for trick demos, keep sentences short, open flat ("aight, front three."), include a "watch this" sentence (cues the full trick), then one imperative sentence per phase using the exact keywords **wind up / pop / spin / land** so her 3D body can match, then a dry sign-off. Normal chat stays normal — the structure only kicks in for demonstrations.

---

## Voice Pipeline (Kith)

`kith-voice/src/server.ts` is a Bun server that owns voice sessions:

```
Client ◄── WS ──► kith-voice ◄── WS ──► Python sidecar (Pipecat) ──► ElevenLabs
TB-Backend ── HTTP POST /speak/:sessionId ──► kith-voice
```

### Session protocol

1. Client opens `wss://api.thetrickbook.com/kith/ws` (nginx proxies `/kith/ws` → `:3040/ws`).
2. Server mints a UUID session id, spins up a **per-session PipecatRuntime** (its own Python subprocess), and sends `{ type: '_ready', sessionId }`.
3. The client sends every chat request with header `x-kith-session: <sessionId>` — same contract for web DMs (`dm.js`) and mobile bot chat (`botChat.js`).
4. After responding with the text reply, the backend **fire-and-forgets** `POST ${KITH_VOICE_URL}/speak/<sessionId>` with the reply text (session id validated against a UUID regex before it goes in a URL; runs after `res.json`, so it can never break the HTTP response).
5. Kith speaks the reply **sentence by sentence** — one full turn cycle per sentence:

```
turn_start(assistant) → tts_start → tts_audio_chunk* → tts_end → turn_end   (× per sentence)
plus: emotion_state (expression layer) · barge_in_detected (user interrupt)
```

End-of-reply is *not* a WS event — clients detect it via the audio player's queue-drain grace window. A `VoiceRouter` layer applies Kaori's slang dictionaries (Gen-Z + board-sports + laugh tags) and a `cleanForTTS` transform (strips markdown, collapses `!!!!` and `soooooo`) before synthesis. Clients can also send `{ type: 'barge-in' }` to cut her off.

### Vendored Python sidecar

The Pipecat sidecar is **vendored and git-tracked** at `kith-voice/python-sidecar` — we patched the pipeline to forward the ElevenLabs `speed` voice setting, which upstream drops, and vendoring keeps the patch alive across `bun install`. Build its venv once with `python-sidecar/setup.sh`; `PIPECAT_PYTHON_PATH` / `PIPECAT_PYTHON_CWD` override (the server logs the active interpreter on boot to catch stale overrides). Voice: ElevenLabs `eleven_v3`, voice id `f4h3tN7EZXwGMHo8bUoV` (via `ELEVENLABS_VOICE_ID`), streaming `mp3_44100_128`.

---

## Mobile 3D Stage

The Kaori companion stage merged to `v2-rebuild` in PR #4 (2026-07-08). It requires a **new dev-client / EAS build** — no store build contains it yet.

### Rendering stack

- **three `0.170`** + **`@react-three/fiber/native`** + **expo-gl**, VRM via `@pixiv/three-vrm`. The `/native` fiber entry installs the Hermes polyfills (FileLoader, TextureLoader, Blob URL) that make GLTFLoader work at all; a shim also defines `navigator.userAgent`, which three r170's GLTFLoader probes and React Native lacks.
- **Textures inside the VRM must be PNG/JPEG** — expo-gl's native decoder supports nothing else (never run gltf-transform over a VRM; it strips the VRM extensions).
- **Physical devices only** — MToon materials don't render on simulators; a fallback card explains.
- Fully procedural idle (breathing, sway, blink, eye tracking) ported from the website's `kaori-live` stage so web and mobile share one motion language. One-finger orbit, pinch zoom.

### Choreography model

Trick demos are data, not baked animations:

- **`riderFundamentals.ts`** — the reusable motion vocabulary every board trick is built from: stance yaw, anatomically-correct crouch with hip drop, coil/wind-up counter-rotation distributed hips→spine→chest→neck, arm blending (rest / wound-up / tucked / balance), parabolic jump arc. Values visually tuned on-device against the VRM 1.0 rig.
- **`trickAnimations.ts`** — a `TRICKS` registry of per-trick timelines composed from those fundamentals (first entry: frontside 360, per real technique references). **Adding a trick = one registry entry**, no animator.
- The demo runs as an on-board *session*: Kaori loops the full trick with stance breathers while explaining, and segment demos (wind-up / pop / landing) fire in the gaps.

### Sentence-cue system

`useKithVoice.ts` owns the WS session, the gapless `TtsPlayer`, and a shared mutable `CompanionVoiceState` ref that the per-frame animation loop reads (no React re-renders). Because Kith speaks one sentence per turn cycle, the hook counts assistant `turn_start` events and fires `onAssistantSentence(index)` — the stage maps sentence indexes onto the demo timeline, so her "watch this" sentence is literally the moment her body throws the full trick. `emotion_state` drives the expression layer; barge-in flips her to listening. STT is on-device via `expo-speech-recognition`.

---

## Deployment & Operations

| Process (PM2) | What | Port |
|---------------|------|------|
| `TB-Backend` | Express API + Kaori brain | 3000 (nginx → `api.thetrickbook.com`) |
| `kith-voice` | Bun voice service + Python sidecar children | 3040 (nginx → `/kith/ws`, `/kith/*`) |

```bash
# SSH (EC2 i-00a7cac777c3b3a4e)
ssh -i ~/.ssh/weshuber.pem ubuntu@174.129.64.158

# Restart (always source nvm first)
. ~/.nvm/nvm.sh && pm2 restart TB-Backend
. ~/.nvm/nvm.sh && pm2 restart kith-voice

# Logs / health
. ~/.nvm/nvm.sh && pm2 logs kith-voice --lines 50
curl -s localhost:3040/health   # { ok, sessions, uptime }
```

Env (never committed — see the secrets policy):

- **`/home/ubuntu/TB-Backend/.env`** — `OPENROUTER_API_KEY`, `ATLAS_URI`, `KITH_VOICE_URL` (base URL the backend fires `/speak` at)
- **`kith-voice/.env`** — `ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID`, `ELEVENLABS_MODEL_ID`, `PORT`, optional `PIPECAT_PYTHON_PATH` / `PIPECAT_PYTHON_CWD`

Each browser/mobile voice session spawns its own Python subprocess — session ceilings and WS auth are the top pre-launch hardening items (see the [launch audit](/docs/roadmap/companions-launch)).

---

## Retired Architectures

The original stack — a standalone **kaori-server-v2** Express brain on port 3001, the **ElizaOS** runtime, and a local **PostgreSQL + pgvector** store for conversation memory and RAG — is dead (stopped ~May 2026). `botChat.js` keeps a legacy port-3001 hop only for hypothetical non-Kaori bot characters behind `BOTCHAT_USE_ELIZA`; Kaori goes straight to her in-process brain. Conversation memory now lives entirely in MongoDB. For the historical snapshot and the cutover rationale, see the [Kaori System Audit (May 2026)](/docs/architecture/kaori-audit-2026-05).

---

## What's Next

- 🚀 **Shipping it** — TestFlight build, voice-WS auth, cost ceilings, monitoring: [Companions Launch Audit](/docs/roadmap/companions-launch)
- 💰 **Paywall + voice tokens** — free Kaori sample with a daily voice allowance, paid tiers for the full roster and monthly tokens, outfit/board unlocks: [Monetization](/docs/roadmap/monetization)
- 🗺️ **Roster + product direction** — Tony (skateboard) next, per-sport environments, stance onboarding, Spots UX refactor: [Priorities](/docs/roadmap/priorities)
