---
sidebar_position: 1
title: "Mobile App Surfaces"
---

# Companions in the Mobile App

Status: **Audited against code 2026-07-12** · repo `TrickList`, branch `v2-rebuild`

Everything the mobile app ships for companions: where they appear, how chat and voice work, and the exact plumbing between screens, the Kith voice sidecar, and the backend brain.

:::tip Related pages
Hub: [AI Companions](/docs/features/ai-companions) · 3D internals: [Animation System](/docs/features/ai-companions/animation-system) · Backend brain: [Kaori AI Architecture](/docs/architecture/kaori)
:::

## Surface map

| Surface | File | What it does |
|---------|------|--------------|
| Homies roster | `app/(tabs)/homies/index.tsx` | "COMPANIONS" section above human homies |
| Home widget | `src/components/home/CompanionWidget.tsx` | Featured companion card on Home |
| Bot chat | `app/(tabs)/homies/bot-chat/[botId].tsx` | Text chat with rich-content cards |
| 3D stage | `app/(tabs)/homies/companion-stage/[botId].tsx` | Voice + choreography over the VRM stage |
| Voice session | `src/lib/companion/kithVoice.ts` | Raw WS client for the Kith sidecar |
| TTS player | `src/lib/companion/ttsPlayer.ts` | Gapless streamed-audio playback |
| Voice hook | `src/hooks/useKithVoice.ts` | WS events → animation state + sentence cues |
| STT hook | `src/hooks/useVoiceInput.ts` | expo-speech-recognition wrapper |
| Rich cards | `src/components/chat/RichContentCards.tsx` | 5 card types with deep links |

There is deliberately **no `src/lib/api/botChat.ts` module** — all three bot endpoints (`GET /bot-chat/bots`, `GET /bot-chat/history/:botId`, `POST /bot-chat/message`) are inline `apiClient` calls from the screens.

## Roster & entry points

- The **Homies screen** fetches `GET /bot-chat/bots` in parallel with human homies and renders companions in a "COMPANIONS" header section — avatar, yellow chip badge, bio, tap → bot chat. A user with zero homies still sees Kaori (the empty state is suppressed when companions exist).
- The **Home screen** takes `bots[0]` as the featured companion and renders `CompanionWidget`: yellow-edged card, tap → chat, and a cube button → 3D stage. The cube (and the matching cube icon in the bot-chat header) only renders when `botCharacter`/name contains `"kaori"` — the 3D stage exists only for her so far.
- Bot chat history is **not** part of DM conversations — bots live in the separate `bot_chats` collection and never appear on the conversations screen.

⚠️ Two scaling landmines here, both hardcoded in two places: the `bots[0]`-is-featured assumption (no roster ordering from the API) and the `"kaori"` substring gate for the stage. Both need parameterizing before Tony ships.

## Bot chat screen

- Optimistic send: a `temp-` message renders immediately; `POST /bot-chat/message` returns `{userMessage, botMessage}` which replace it. On failure the text is restored to the input.
- **Legacy rows:** user messages from before the backend persisted message text (fixed May 2026) have no `message` field and render as an italic *"message not saved"* placeholder — permanent for pre-fix history.
- Text chat **never sends `x-kith-session`**, so it is voiceless by design; voice lives on the stage.
- Input capped at 1000 chars (500 on the stage); typing indicator is three static dots while awaiting the reply.

## Rich content cards

`RichContentCards.tsx` renders five card types when a message carries `richContent`:

| Type | Renders | Tap → |
|------|---------|-------|
| `spot_card` | image, name, address, rating, category badge | spot detail |
| `spots_list` | first 3 spots + "+N more" | spot detail per row |
| `tricklist_card` | name, trick count, difficulty, progress bar | tricklist detail |
| `trick_card` | image, name, difficulty, description | ⚠️ trickbook **index** (ignores the trick id) |
| `spot_draft_confirmation` | green "Spot Draft Created" confirmation | not tappable |

**Reality check: these cards are dormant.** The backend has no `richContent` mechanism at all — tool results are fed back to the model as plain JSON and replies come back as plain text. The renderer shipped ahead of the backend (per the [original plan](/docs/roadmap/ai-companion-tools)); wiring tool results into `richContent` on the reply payload is a pending backend task, and the payoff is large — tappable spot/tricklist cards are the "companion operates the app" moment. Cards are also hardcoded dark-theme and `richContent.data` is untyped (`any`) — worth tightening when the backend side lands.

## Voice stack (three layers)

```
useKithVoice (hook) ── owns ──► KithVoiceSession (WS) ──► wss://api.thetrickbook.com/kith/ws
      │                                                    (dev: ws://DEV_API_HOST:3040/ws)
      └────────────── owns ──► TtsPlayer (react-native-audio-api)
```

### KithVoiceSession (`src/lib/companion/kithVoice.ts`)

Raw WebSocket client. Server sends `{type:'_ready', sessionId}` on connect; the client can send `{type:'speak', text}` (direct TTS, bypasses the brain) and `{type:'barge-in'}`. Reconnects forever at a fixed 3s interval — no backoff, no cap. **No auth token is attached to the connection** (the known P0 — see [launch audit](/docs/roadmap/companions-launch)).

### TtsPlayer (`src/lib/companion/ttsPlayer.ts`)

Kith streams independently-decodable `mp3_44100_128` chunks — **one full turn cycle per sentence**. The player keeps a single long-lived `AudioBufferQueueSourceNode` for the whole conversation (drained queue nodes never reach FINISHED, so per-turn nodes would leak), serializes decodes on a promise chain (decodeAudioData resolves out of order), and detects end-of-reply with a 500ms queue-drain grace timer — `tts_end`/`turn_end` are per-*sentence* boundaries and must not be treated as end-of-reply.

Pinned `react-native-audio-api@0.13.1` workarounds (do not remove):
- `start()` with no args throws → always `start(0, 0)`
- `onEnded` never fires for queue nodes → use `onBufferEnded` + `isLastBufferInQueue`
- worklets stays at 0.5.1 (Expo SDK 54) → audio-api worklet nodes disabled; we only need `decodeAudioData` + the queue node

### useKithVoice (`src/hooks/useKithVoice.ts`)

Maps WS events onto a **mutable `CompanionVoiceState` ref** (`mode`, `emotion`, `emotionIntensity`) that the stage's per-frame loop reads — deliberately outside React state. Because Kith speaks one sentence per turn, the hook counts assistant `turn_start` events and fires `onAssistantSentence(index)` — this is what drives [speech-synced choreography](/docs/features/ai-companions/animation-system#sentence-cues). `beginReply()` must be called on send to reset the counter. `onReplyDone` fires from the player's drain grace.

Known wart: `voiceReady` is set on `_ready` but never reset on WS close, so the "Talk to Kaori…" placeholder can be stale during a reconnect window.

### STT (`src/hooks/useVoiceInput.ts`)

`expo-speech-recognition` with live interim transcript, auto-submit after 2s of silence, 5s never-spoke timeout — mirrors the web stage behavior. Hardcoded `en-US`, cloud recognition allowed. Permission denial is currently silent (no Settings guidance).

Two ordering rules the stage enforces around the mic:

1. **Barge-in before the mic opens** — otherwise Kaori's speaker output bleeds into the head of the transcript.
2. **Reassert playback after the mic closes** — speech recognition leaves the iOS audio session in record mode and never restores it; `reassertPlayback()` restores the `playback`/`spokenAudio` session so the reply's TTS isn't attenuated.

## The stage screen's chat plumbing

- Sends `POST /bot-chat/message` with the `x-kith-session` header when a session is live — this is what makes the backend (a) append the stage-demo prompt to the brain and (b) fire the reply text at Kith for voice.
- Splits the reply into sentences client-side (`/(?<=[.!?…])\s+/`) to index sentence cues — this **assumes the client split matches Kith's server-side chunking 1:1**; divergence silently mis-cues choreography (a known fragility, see [Animation System](/docs/features/ai-companions/animation-system#sentence-cues)).
- Voiceless fallback: no session → run the full trick once, end the demo after a hardcoded 7s.
- Dead-session recovery: still `thinking` 8s after send → force back to idle.
- The stage is **never wrapped in KeyboardAvoidingView** (resizing the expo-gl surface every keyboard toggle churns the GL context); rendering pauses when the screen loses focus (`active={isFocused}`).
- Stage messages are ephemeral locally (last 2 rendered as translucent bubbles) but the backend logs everything in `bot_chats` — the history shows up in the text chat later.

## Tuning constants (all hardcoded)

7000ms voiceless-demo teardown · 8000ms dead-session recovery · 400ms mode-pill polling · 500ms TTS drain grace · 2000ms STT silence auto-submit · 5000ms STT no-speech timeout · 3000ms WS reconnect. The 7s voiceless teardown must stay ≥ the longest trick duration (currently 4.2s) — nothing enforces that.

## Known gaps (mobile)

- Voice WS unauthenticated (P0, [launch audit](/docs/roadmap/companions-launch)); no analytics/telemetry anywhere in the companion code; roster/history fetch errors are swallowed into empty states; `trick_card` deep link drops the trick id; STT permission denial is silent; no handling for audio interruptions (phone calls) beyond the STT reassert.
