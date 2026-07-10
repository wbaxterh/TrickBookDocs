---
sidebar_position: 5
title: AI Companions
---

# AI Companions

Status: **Live in code, one build away from users** · Last updated: 2026-07-09

TrickBook's AI Companions are riders, not chatbots. They chat with real personality, act on your TrickBook data (creating tricklists, finding spots), and — as of July 2026 — **exist as full 3D characters who talk to you out loud and physically demonstrate tricks with their bodies**.

:::tip Deep Dive
For the full technical architecture (LLM brain, voice pipeline, 3D stage), see [**Kaori AI Architecture**](/docs/architecture/kaori). For the path to shipping this to users, see [**Companions Launch Audit**](/docs/roadmap/companions-launch). For the business model, see [**Monetization: Paywall & Tokens**](/docs/roadmap/monetization).
:::

## Kaori 🏔️ — the flagship companion

- **Character:** Japanese snowboarder (homage to SSX's Kaori Nishidake)
- **Personality:** corpus-mined rider register — dry, understated, short replies, no cheerleader energy. Praise is one specific line ("that back lip was clean"). Trained against a banned-poser-vocabulary list mined from core snowboard media.
- **Brain:** Gemini Flash via OpenRouter with an 8-tool calling loop (TB-Backend `kaori-ai-response.js` + `kaori-tools.js`)
- **Memory:** unified across every surface — web DMs, mobile chat, and 3D-stage voice conversations all merge into one chronological history, so she remembers what you told her anywhere
- **Voice:** ElevenLabs streamed through [Kith](https://github.com/wbaxterh/kith) (our own OSS voice runtime), gapless sentence-by-sentence playback

### The 3D Companion Stage (mobile)

Merged to `v2-rebuild` in PR #4 (2026-07-08). An interactive VRM stage where Kaori:

- **Renders in full 3D** — VRM avatar via three.js + react-three-fiber + expo-gl, orbit/pinch camera, physical devices only (simulators can't run the shaders; a fallback card explains)
- **Talks live** — speak to her with the mic (on-device STT), she answers in her ElevenLabs voice with mouth-sync, gestures, and emotion expressions; barge-in supported
- **Demonstrates tricks with her body** — speech-synced choreography: say "show me a frontside 360" and she explains it while physically performing it, her own sentences cueing the wind-up, pop, and landing. Built on a reusable rider-motion vocabulary (`riderFundamentals.ts`) + a per-trick timeline registry (`trickAnimations.ts`) — adding a trick is one registry entry, no animator required
- **Keeps the chat** — translucent chat overlay on the stage, same brain and history as regular chat

Entry points: the cube icon in Kaori's chat header and the Companion widget on Home.

### Web surface

`thetrickbook.com/kaori-live` — 2D live-voice Kaori sharing the same Kith voice pipeline and brain.

## What Can Kaori Do? (chat tools)

- **Search spots** — "any parks near Brooklyn?" → tappable spot cards
- **View / create tricklists** — "make me a beginner park list" → real tricklist in your account
- **Search trickipedia** — "how do I do a backside 180?" → tricks with tutorials
- **Submit new spots** — paste a Google Maps link → spot draft for admin review
- **Share content** — spots, tricklists, tricks as interactive cards

## Safety & Guardrails

- **No deletion tools** — create and read only
- **Spot moderation** — AI-submitted spots go to a review queue
- **Rate limits** — max 5 write operations per user per hour; tool loop capped at 3 iterations
- **Audit trail** — all AI-created content flagged `createdBy: 'kaori'`
- **Stage prompt gating** — the trick-demo prompt only activates for live stage sessions (`onStage`), so normal chat stays normal

## The Vision

Companions are TrickBook's differentiator: a coach in your pocket for every action sport, with a body, a voice, and a memory.

### Monetization — sample for free, tokens for voice

Free users get a **sample** of the companions (Kaori, with a daily voice allowance); paid tiers unlock the full roster and monthly **voice-token** allotments. Voice is metered because every spoken reply costs real money (TTS + LLM). Full model: [Monetization roadmap](/docs/roadmap/monetization).

### Unlockables — outfits, boards, environments

- **Boards** — deck designs and snowboard graphics as unlockable props (easiest, most on-brand)
- **Outfit colorways → full outfits** — texture swaps first, complete alternate VRMs later
- **Per-sport environments** — each sport gets a vibe: Kaori belongs in a **snowy environment**, Tony in a street/park scene, the surf companion on water
- Unlocks come from **both** usage (streaks, tricks landed, XP) and payment tiers — earned and bought cosmetics coexist

### Roster — skateboarding and snowboarding first

| Companion | Sport | Status |
|-----------|-------|--------|
| **Kaori** 🏔️ | Snowboard | ✅ Live (chat + voice + 3D stage) |
| **Tony** 🛹 | Skateboard | 📋 Next — largest user segment, deepest Trickipedia coverage |
| **Rico** 🏄 | Surf | 📋 Later (after skate + snow are strong) |
| **Max** 🚲 | BMX | 📋 Backlog |
| **Zoe** ⛷️ | Ski | 📋 Backlog |

### Stance-aware coaching

One of the first profile questions for boardsports users will be **regular or goofy** — it changes which direction a frontside rotation goes, which foot leads, and how a companion coaches every trick. Choreography currently assumes regular; stance-awareness is a prerequisite for coaching goofy riders correctly.

## Implementation Status

| Feature | Status |
|---------|--------|
| Chat with personality + 7 tool actions | ✅ Live |
| Rider persona (corpus-mined register) | ✅ Live (prod 2026-07-09) |
| Unified cross-surface memory | ✅ Live (prod 2026-07-09) |
| Live voice pipeline (Kith + ElevenLabs) | ✅ Live (prod 2026-07-09) |
| 3D companion stage (mobile) | ✅ Merged — awaiting new EAS build |
| Speech-synced trick demos (FS360) | ✅ Merged — awaiting new EAS build |
| Web kaori-live (2D voice) | ✅ Live |
| Voice-endpoint auth + usage metering | 🚧 P0 — see [launch audit](/docs/roadmap/companions-launch) |
| Paywall / free-sample gating | 📋 Planned — see [monetization](/docs/roadmap/monetization) |
| More snowboard tricks + FS360 refinement | 📋 Planned |
| Snowy stage environment | 📋 Planned |
| Outfit/board unlocks | 📋 Planned |
| Tony (skateboard companion) | 📋 Planned |
| Regular/goofy stance onboarding | 📋 Planned |
| Spot draft admin flow · DM file uploads | 📋 Planned |
