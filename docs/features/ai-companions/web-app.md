---
sidebar_position: 2
title: "Web App Surfaces"
---

# Companions in the Web App

Status: **Audited against code 2026-07-12** · repo `TrickBookWebsite` (Next.js, pages router)

What the website ships for companions today: a full 3D Kaori stage at `/kaori-live`, companion DMs on `/messages`, and the honest parity picture against mobile.

:::tip Related pages
Hub: [AI Companions](/docs/features/ai-companions) · Mobile equivalent: [Mobile App Surfaces](/docs/features/ai-companions/mobile-app) · Backend brain: [Kaori AI Architecture](/docs/architecture/kaori)
:::

## Kaori Live (`pages/kaori-live.js`) — the web 3D stage

A single ~1,200-line page containing the entire experience: **a real 3D VRM stage in the browser**, hand-rolled with raw three.js `^0.183` + `@pixiv/three-vrm ^3.5.2` (no react-three-fiber on web). It loads `/kaori/Kaori_V3.vrm` (19.6MB) with **MToon materials intact** — the browser compiles what expo-gl can't, which is why web Kaori has the true anime shading and mobile runs the [unlit downgrade](/docs/features/ai-companions/animation-system#mobile-rendering-workarounds).

- **Scene:** stylized snowy mountain set — fog, snow ground plane, four cone mountains with snow caps, rotating brand-yellow floor ring, and a cyan pulse ring whose opacity/scale encode the conversation state.
- **Auto-fit:** the VRM is bounding-box-scaled to a 1.8m target height and floored, so a swapped model can't break framing.
- **Fallback:** if the VRM fails to load, a glowing-sphere stage animates instead.
- **Auth:** logged-out users get an inline "Log in to talk with Kaori" card; the page never redirects.

### Procedural animation (shared motion language with mobile)

All animation is procedural — an explicit design choice (the code comments: Mixamo FBX clips override bone rotations and T-pose VRM models). The layers mirror mobile's idle system: breathing/sway/head-drift, hip weight-shift, 3.5s deterministic blink, finger curl, listening/thinking body language, and a **6-pose conversational gesture cycle** (rest, explaining, presenting, emphasis, counting, nodding) that rotates every 2s while speaking. Mouth shapes are **simulated sine visemes** — there is no audio analyser; the `voiceLevel`/`voiceBands` reads in the render loop are dead code that never receives data.

Server-driven emotion (`emotion_state` from Kith) does exactly one thing on web: an **emissive tint** across all materials (excited = warm gold, calm = ice blue, happy = pink, sad = slate). It never selects gestures.

**`lib/kaori-animation-presets.js` is dead code.** It defines the same 6 poses plus a `default-talking` preset, but is never imported — the page duplicates the poses inline, and the values have already drifted (resting-smile weights differ). Treat the presets file as an unrealized refactor, not live architecture. There is **no board, no trick registry, no rider fundamentals on web** — trick demos are mobile-only.

### Voice on web

- **STT:** browser `SpeechRecognition` (Chromium/WebKit), continuous with interim results, auto-submit after 2s of silence, 5s no-speech timeout. `en-US` hardcoded; unsupported browsers get an alert.
- **TTS:** the page opens the Kith WebSocket (`NEXT_PUBLIC_KITH_VOICE_WS_URL`, prod `wss://api.thetrickbook.com/kith/ws`) — **unauthenticated**, the same P0 as mobile. Base64 mp3 chunks are decoded via Web Audio and played gaplessly; a 3s auto-reconnect loop runs while the page is open.
- **Session wiring:** on `_ready` the page stores the `sessionId` and attaches `x-kith-session` to normal DM message POSTs — the text reply arrives over socket.io, the audio over the Kith WS. On `_ready` it also fetches a relationship-aware greeting (`POST /companion/profile/:id/greeting`) and has Kith speak it.
- **Barge-in:** three paths — starting the mic, the stop button while speaking, and server `barge_in_detected` — all clear the local audio queue.

⚠️ Config foot-gun: the WS URL falls back to `ws://localhost:3040/ws` — if the Amplify env var is missing, the page silently retries localhost forever.

### The stage prompt never reaches web

Even with a live `x-kith-session`, the web path goes through `routes/dm.js`, which **never passes `onStage`** to the brain — so Kaori never structures her replies for choreography on web. That's currently fine (web has no demo system to cue), but it's the first backend change needed if the web stage ever gets demos.

## Chat surfaces

- **`/messages`** — the conversation list carries an "AI Companions" avatar row (yellow ring, permanent green presence dot); tapping starts or resumes the bot conversation via `POST /dm/bot-conversation` (no homie requirement for bots).
- **`/messages/[conversationId]`** — companion DMs use the ordinary DM thread: date-grouped bubbles, typing indicator, read receipts, an "AI" badge, and a cosmetic always-"Online" status. **No `x-kith-session` here — the plain DM page is text-only.** Voice Kaori = `/kaori-live` specifically.
- **`/homies`** — despite the name, contains zero companion code; companions live on `/messages`.
- **Rich content cards: none on web.** Both surfaces render `msg.content` as plain text. (Mobile ships a card renderer; neither platform receives `richContent` from the backend yet — see [mobile page](/docs/features/ai-companions/mobile-app#rich-content-cards).)
- Legacy "Kaori voice: *.mp3" messages are regex-filtered — with two *different* regexes on the two surfaces, so a legacy row can appear on one and not the other.

## Discoverability & assets

- **`/kaori-live` has no nav entry point anywhere** — no header link, no homepage promo. It is a direct-URL page. The user-facing companion entry point on web is the AI Companions row on `/messages`.
- `public/kaori/` publicly serves ~70MB: three VRM versions (only `Kaori_V3.vrm` is used) **plus the raw `model.vroid` VRoid Studio source** — an asset leak worth cleaning up alongside the planned move of models to CDN.
- The relationship-profile API client exists on web (`getCompanionProfile`) but no page calls it — relationship/stage UX is mobile territory for now.

## Web ↔ mobile parity matrix

| Capability | Web | Mobile |
|------------|-----|--------|
| 3D VRM stage | ✅ raw three.js, MToon | ✅ r3f + expo-gl, unlit downgrade |
| Idle/gesture/blink/viseme layers | ✅ | ✅ (same motion language) |
| Emotion from Kith | ✅ emissive tint | ✅ facial expressions |
| Trick demos + board | ❌ | ✅ (FS360) |
| Rider fundamentals / TRICKS registry | ❌ | ✅ |
| Live voice (TTS out) | ✅ Kith WS | ✅ Kith WS |
| STT in | ✅ browser API | ✅ expo-speech-recognition |
| Stage demo prompt (`onStage`) | ❌ never passed by `dm.js` | ✅ via `botChat.js` |
| Companion chat | ✅ DM thread + AI badge | ✅ dedicated bot-chat screen |
| Rich content cards | ❌ none | ✅ renderer shipped (dormant) |
| Relationship greeting | ✅ kaori-live auto-greet | ❌ |
| Relationship profile UI | ❌ (client exists, unused) | ❌ |
| Nav entry point to stage | ❌ hidden URL | ✅ widget + chat header cube |
| Paywall/entitlement gating | ❌ | ❌ |

The strategic read: web is the **materials/lighting showcase** (true MToon) and the zero-install demo surface; mobile is the **product** (demos, cards, widget). Divergence to watch: the two stages share motion values by copy-paste, not by a shared module — the third copy (Tony) is the moment to extract one.
