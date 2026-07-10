---
sidebar_position: 6
title: "Kaori System Audit (May 2026)"
---

# Kaori AI System Audit — May 2026

Status: **Superseded — see [Kaori AI Architecture](/docs/architecture/kaori)** · Snapshot date: May 2026

Current state of Kaori's AI companion system, voice pipeline, 3D character, and tool integration.

## Status Overview

| Component | Status | Notes |
|-----------|--------|-------|
| AI Response Engine | **Working** | Gemini 2.0 Flash via OpenRouter, tool calling active |
| Tool Calling (7 tools) | **Working** | Spots, trickipedia, tricklists, knowledge base |
| Boardsport Knowledge Base | **Working** | Static JSON, 5 sports covered |
| Relationship System | **Working** | 5 stages, interaction tracking, adaptive greetings |
| Kaori Live (Web) | **Working** | 3D VRM avatar, chat overlay, voice input |
| Voice / TTS (Kith) | **Working** | ElevenLabs via Kith sidecar, streaming audio |
| VRM Character | **Working** | Procedural animation, emotion tinting |
| RAG (Torment Articles) | **Not Deployed** | pgvector pipeline exists but `kaori-rag/` not on server |
| ElizaOS (Port 3001) | **Stopped** | Disabled in favor of direct OpenRouter path |
| Mobile App Integration | **Not Built** | Falls back to standard DM interface |

---

## Architecture

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Browser   │◄──►│   TB-Backend     │◄──►│  MongoDB Atlas   │
│             │    │   (Express)      │    │  (TrickList2)    │
│  kaori-live │    │                  │    │                  │
│  Socket.IO  │    │  dm.js           │    │  dm_messages     │
│  Kith WS    │    │  ├─ kaori-ai-    │    │  companion_      │
│  Three.js   │    │  │  response.js  │    │  profiles        │
│             │    │  └─ kaori-       │    │  spots, tricks   │
└──────┬──────┘    │     tools.js     │    │  tricklists      │
       │           └────────┬─────────┘    └─────────────────┘
       │                    │
       │           ┌────────▼─────────┐    ┌─────────────────┐
       │           │  OpenRouter API  │    │  Kith Voice      │
       │           │  (Gemini Flash)  │    │  (Port 3040)     │
       │           └──────────────────┘    │  ElevenLabs TTS  │
       │                                   │  Emotion State   │
       └───────────────────────────────────►│  Audio Streaming │
                                           └─────────────────┘
```

---

## AI Response Pipeline

**Model:** `google/gemini-2.0-flash-001` via OpenRouter  
**Temperature:** 0.7  
**Max Tokens:** 400  
**Tool Choice:** auto  
**Conversation History:** Last 4 messages  

### Message Flow

1. User sends DM via REST API → `routes/dm.js`
2. `dm.js` detects bot conversation, emits typing indicator
3. Tries ElizaOS at `localhost:3001` (currently stopped, fails immediately)
4. Falls back to `kaori-ai-response.js` → `generateKaoriResponse()`
5. Fetches conversation history (4 messages) from MongoDB
6. Fetches relationship profile from `companion_profiles`
7. Updates interaction count and relationship stage
8. Queries RAG context (currently fails silently — RAG not deployed)
9. Calls OpenRouter with system prompt + tools
10. **Tool loop** (max 3 iterations):
    - If model calls tools → execute via `kaori-tools.js` → feed results back
    - If model returns text → done
11. Bot response saved to `dm_messages`, emitted via Socket.IO
12. If Kith session active → fire-and-forget POST to `/speak/{sessionId}`

### System Prompt

Kaori Nishidake — 18-year-old Japanese freestyle snowboarder from Sapporo. SSX Tricky character. Personality: bubbly, encouraging, uses Japanese naturally (sugoi, ne, yatta), short messages (2-4 sentences), emoji-friendly.

Key directive in prompt:
> **MUST use tools** for trick lists, spots, trickipedia, knowledge lookups. NEVER make up data — always use tools for real results.

---

## Tools (7 Available)

| Tool | Type | What It Does | DB Collection |
|------|------|-------------|---------------|
| `search_spots` | Read | Find spots by name/state/city/sport | `spots` |
| `search_trickipedia` | Read | Look up tricks by name/category/difficulty | `trickipedia` |
| `get_user_tricklists` | Read | Fetch user's trick lists with progress | `tricklists` + `tricks` |
| `lookup_boardsport_knowledge` | Read | Magazines, Instagram, events, culture | `kaori-knowledge.json` |
| `create_tricklist` | Write | Create new trick list for user | `tricklists` |
| `add_trick_to_list` | Write | Add trick to existing list | `tricks` + `tricklists` |
| `update_trick_status` | Write | Mark trick Complete or To Do | `tricks` |

**Safety:** Write tools flag content with `createdBy: 'kaori'`. Max 3 tool iterations per message. ObjectId validation on all IDs.

---

## Boardsport Knowledge Base

Static JSON at `Backend/kaori-knowledge.json` covering 5 sports:

| Sport | Magazines | Instagram | Events | Key Figures | Brands |
|-------|-----------|-----------|--------|-------------|--------|
| Snowboarding | 6 | 9 | 6 | 9 | 9 |
| Skateboarding | 6 | 9 | 6 | 10 | 10 |
| Surfing | 5 | 7 | 5 | 7 | 6 |
| BMX | 4 | 6 | 5 | 7 | 7 |
| Skiing | 5 | 7 | 5 | 7 | 8 |

Queried via `lookup_boardsport_knowledge` tool — not injected into system prompt.

---

## Relationship System

**Collection:** `companion_profiles`

### Stages

| Stage | Messages | Behavior |
|-------|----------|----------|
| Stranger | 0-4 | Welcoming, asks name, learns about them |
| Acquaintance | 5-19 | Remembers details, friendly |
| Friend | 20-59 | Personal, uses name, references history |
| Close Friend | 60-149 | Warm, inside jokes, deeper conversations |
| Bestie | 150+ | Maximum energy, deeply personal |

### Profile Fields

- `interactionCount` — auto-incremented on each message
- `relationshipStage` — computed from interaction count
- `memory.userName` — learned from conversation
- `memory.knownFacts` — stored facts about user
- `traits.sports` — user's sports
- `traits.preferredTopics` — conversation preferences

### Greetings

Generated from hardcoded templates per stage + time of day. 2-3 variants per combination. References last discussed trick when applicable.

---

## Voice Pipeline (Kith)

**Service:** Runs on port 3040 as PM2 process `kith-voice`  
**TTS Provider:** ElevenLabs (eleven_v3 model)  
**Voice ID:** `klHOJHbGA89BjwulA7MN`  
**Speed:** 1.05x  

### WebSocket Protocol

**Client → Server:**
- `{ type: 'speak', text: '...' }` — queue text for TTS
- `{ type: 'barge-in' }` — user interrupted

**Server → Client:**
- `_ready` — session initialized (includes `sessionId`)
- `tts_audio_chunk` — base64 mp3 audio frame
- `tts_start` / `tts_end` — TTS lifecycle
- `turn_start` / `turn_end` — conversation turn markers
- `emotion_state` — `{ state: 'excited'|'calm'|'happy'|'sad'|'neutral', intensity: 0-1 }`
- `barge_in_detected` — user interruption confirmed

### Character Voice Config

From `kaori-character.json`:
- Stability: 0.55
- Similarity boost: 0.82
- Style: 0.45
- 42 slang definitions (gg → good game, fs → frontside, etc.)
- 13 pronunciation rules for Japanese/English terms

---

## Kaori Live (Web Interface)

**Page:** `/kaori-live`  
**Tech:** Three.js + @pixiv/three-vrm + Socket.IO + Web Audio API

### Features

- **3D Avatar:** VRM character with procedural breathing, idle sway, blinking
- **Animation States:** idle → listening → thinking → speaking (with arm/mouth movement)
- **Emotion Tinting:** VRM materials change emissive color based on Kith emotion events
- **Chat Overlay:** Glassmorphism message bubbles overlaying the avatar
- **Voice Input:** Web Speech API (SpeechRecognition), auto-submits on end
- **Voice Output:** Streaming mp3 from Kith via Web Audio API
- **Auto-Greeting:** Fires on Kith WebSocket `_ready` event

### Scene

- Snowy mountain backdrop (procedural cones with snow caps)
- Ambient + directional lighting
- Animated ring at feet
- Pulsing ring responds to voice level
- Camera at (0, 1.45, 2.15) looking at character

---

## Known Issues & Gaps

### High Priority

| Issue | Impact | Status |
|-------|--------|--------|
| RAG not deployed | No dynamic article knowledge | `kaori-rag/` missing from server |
| Tool calls sometimes skipped | Model guesses instead of using tools | Improved with directive prompt |
| Memory not auto-populated | User preferences not learned from chat | Requires NLP extraction |
| Knowledge base is static | Info will stale over time | Needs update pipeline |

### Medium Priority

| Issue | Impact | Status |
|-------|--------|--------|
| FBX animations missing | Character uses procedural animation only | Need `/kaori/anims/*.fbx` |
| No content moderation | Kaori receives unfiltered input | Needs safety layer |
| Greetings are hardcoded | Feel formulaic at scale | Could be AI-generated |
| No mobile Kaori integration | Only web has immersive experience | Standard DM on mobile |

### Low Priority

| Issue | Impact | Status |
|-------|--------|--------|
| Kith reconnects aggressively (3s) | Minor network noise | Could use backoff |
| Auto-scroll disabled | Messages don't follow | Intentional decision |
| No accessibility features | Screen reader unfriendly | Needs ARIA labels |

---

## Key Files

| File | Purpose |
|------|---------|
| `Backend/kaori-ai-response.js` | AI response generation + tool loop |
| `Backend/kaori-tools.js` | 7 tool definitions + MongoDB handlers |
| `Backend/kaori-knowledge.json` | Static boardsport knowledge |
| `Backend/routes/dm.js` | Message routing, bot detection, Socket.IO |
| `Backend/routes/companionProfile.js` | Relationship tracking + greetings |
| `Backend/kith-voice/` | Voice synthesis service |
| `Website/pages/kaori-live.js` | 3D avatar chat interface |
| `Website/lib/apiMessages.js` | API client for messaging |
| `Website/public/kaori/kaori_sample.vrm` | 3D character model |

---

## Infrastructure

- **EC2:** t3.small (2 vCPU, 2GB RAM)
- **PM2 Processes:** TB-Backend (port 9000), kith-voice (port 3040)
- **MongoDB:** Atlas M0 (shared connection pool, maxPoolSize: 20)
- **LLM:** OpenRouter → Gemini 2.0 Flash
- **TTS:** ElevenLabs (eleven_v3)
- **Kaori Bot User ID:** `69c15e55c7ebe2c6884f1267`

---

## What changed since this audit (July 2026)

This audit is preserved as a historical snapshot. Several of its gaps have since been closed:

| Area | May 2026 (this audit) | July 2026 |
|------|----------------------|-----------|
| Mobile integration | ❌ Not built — standard DM fallback | ✅ 3D companion stage shipped in mobile PR #4 (VRM stage, live voice, chat overlay) |
| Character animation | ❌ FBX animations missing, procedural only | ✅ Speech-synced trick choreography (FS360) closes the animations gap |
| Persona & memory | Hardcoded prompt, memory not auto-populated | ✅ Backend `2fa8388`: corpus-mined rider persona, unified cross-surface memory (DMs + bot chats), `onStage` stage-demo prompt gating |
| Kith voice sidecar | Upstream Kith on port 3040 | ✅ Vendored + patched Kith (speed forwarding); nginx `/kith/ws` proxy verified externally |
| Voice ID | `klHOJHbGA89BjwulA7MN` | ✅ Now `f4h3tN7EZXwGMHo8bUoV` |
| ElizaOS (port 3001) | Stopped | Remains retired — prod path is direct OpenRouter via `kaori-ai-response.js` |

:::tip
For the current end-to-end state and launch readiness, see the [Companions Launch Audit](/docs/roadmap/companions-launch).
:::
