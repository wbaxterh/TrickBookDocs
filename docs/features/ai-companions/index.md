---
sidebar_position: 5
title: AI Companions
---

# AI Companions

Status: **Live in code, one build away from users** · Last updated: 2026-07-12

TrickBook's AI Companions are riders, not chatbots. They chat with real personality, act on your TrickBook data through tool calls, and — as of July 2026 — **exist as full 3D characters who talk to you out loud and physically demonstrate tricks with their bodies**.

This is the hub for the companions documentation. The deep-dives below were written from a full code audit of the mobile app, the web app, and the backend (2026-07-12).

:::tip This section
[**Mobile App Surfaces**](/docs/features/ai-companions/mobile-app) — roster, widget, bot chat, rich cards, voice stack · [**Web App Surfaces**](/docs/features/ai-companions/web-app) — the Kaori Live 3D stage, DMs, parity matrix · [**Animation System**](/docs/features/ai-companions/animation-system) — rider fundamentals, trick timelines, speech-synced choreography, scaling audit · [**The Board Model**](/docs/features/ai-companions/board-model) — how the board is generated and where per-design boards fit · [**Motion Capture Pipeline**](/docs/features/ai-companions/motion-pipeline) — how we'll learn real trick movements from video · [**RAG & Internal Tools**](/docs/features/ai-companions/rag-and-tools) — the knowledge/tool architecture today and the plan to make companions truly smart
:::

:::tip Related pages
Technical architecture: [**Kaori AI Architecture**](/docs/architecture/kaori) · Path to users: [**Companions Launch Audit**](/docs/roadmap/companions-launch) · Business model: [**Monetization: Paywall & Tokens**](/docs/roadmap/monetization)
:::

## Kaori 🏔️ — the flagship companion

- **Character:** Japanese snowboarder (homage to SSX's Kaori Nishidake) — 18, from Sapporo, youngest rider on the SSX circuit
- **Personality:** corpus-mined rider register — dry, understated, short replies, no cheerleader energy. Praise is one specific line ("that back lip was clean"). Trained against a banned-poser-vocabulary list mined from core snowboard media.
- **Brain:** Gemini Flash via OpenRouter with an 8-tool calling loop (TB-Backend `kaori-ai-response.js` + `kaori-tools.js`)
- **Memory:** unified across every surface — web DMs, mobile chat, and 3D-stage voice conversations merge into one chronological history, plus a relationship profile (stranger → bestie) that grows with interaction count
- **Voice:** ElevenLabs streamed through [Kith](https://github.com/wbaxterh/kith) (our own OSS voice runtime), gapless sentence-by-sentence playback

### The 3D Companion Stage (mobile)

Merged to `v2-rebuild` in PR #4 (2026-07-08). An interactive VRM stage where Kaori:

- **Renders in full 3D** — VRM avatar via three.js + react-three-fiber + expo-gl, orbit/pinch camera, physical devices only (simulators can't run the shaders; a fallback card explains)
- **Talks live** — speak to her with the mic (on-device STT), she answers in her ElevenLabs voice with mouth-sync, gestures, and emotion expressions; barge-in supported
- **Demonstrates tricks with her body** — speech-synced choreography: say "show me a frontside 360" and she explains it while physically performing it, her own sentences cueing the wind-up, pop, and landing. Built on a reusable rider-motion vocabulary (`riderFundamentals.ts`) + a per-trick timeline registry (`trickAnimations.ts`). Full details: [Animation System](/docs/features/ai-companions/animation-system).
- **Keeps the chat** — translucent chat overlay on the stage, same brain and history as regular chat

Entry points: the cube icon in Kaori's chat header and the Companion widget on Home. Details: [Mobile App Surfaces](/docs/features/ai-companions/mobile-app).

### The Kaori Live stage (web)

`thetrickbook.com/kaori-live` is a **full 3D VRM stage in the browser** (raw three.js, MToon materials intact, stylized snowy-mountain environment) with live voice: browser speech recognition in, Kith/ElevenLabs audio out. It shares the idle/gesture motion language with mobile but has **no board and no trick demos** — those are mobile-only today. It also has no nav entry point; it's reachable only by direct URL. Details: [Web App Surfaces](/docs/features/ai-companions/web-app).

## What Can Kaori Do? (the shipped tool registry)

The 8 tools actually live in production (`kaori-tools.js`):

| Tool | What it does |
|------|--------------|
| `search_spots` | Find approved skateparks / resorts / breaks — "any parks near Brooklyn?" |
| `search_trickipedia` | Look up tricks by name — "how do I do a backside 180?" |
| `get_user_tricklists` | Read the user's real lists with resolved trick names |
| `create_tricklist` | Create a list in the user's account (flagged `createdBy: 'kaori'`) |
| `add_trick_to_list` | Add a trickipedia trick to one of the user's lists |
| `update_trick_status` | Mark a trick Complete / To Do |
| `lookup_boardsport_knowledge` | Curated static knowledge (magazines, events, culture per sport) |
| `remember_user_info` | Persist name / sports / facts to the relationship profile |

Spot submission (`create_spot_draft`) and rich-card sharing (`share_content`) were **planned but are not shipped** — see the [original tool-calling plan](/docs/roadmap/ai-companion-tools) vs. what landed. The mobile app already ships the rich-card renderer for when the backend starts sending them ([details](/docs/features/ai-companions/mobile-app#rich-content-cards)).

## Safety & Guardrails

What's actually enforced in code today:

- **No deletion tools** — create and read only
- **Ownership checks** — Kaori can only touch lists/tricks belonging to the requesting user
- **Approved spots only** — `search_spots` filters to `approvalStatus: 'approved'` and instructs the model to disclose when a suggestion isn't in TrickBook
- **Audit trail** — AI-created content flagged `createdBy: 'kaori'`
- **Loop caps** — max 3 tool iterations and 400 output tokens per reply
- **Stage prompt gating** — the trick-demo prompt only activates for live stage sessions (`x-kith-session` header), so normal chat stays normal

What's **not** built yet (open items in the [launch audit](/docs/roadmap/companions-launch)): per-user rate limiting on the AI endpoints, voice-token metering, and authentication on the voice WebSocket.

## The Vision

Companions are TrickBook's differentiator: a coach in your pocket for every action sport, with a body, a voice, and a memory. Two capability tracks make them genuinely smart rather than chat-deep:

1. **Knowledge (RAG)** — companions grounded in our own knowledgebase: Trickipedia, coaching content, the docs. Today's knowledge is a 1,500-word static JSON; the migration plan to real retrieval is in [RAG & Internal Tools](/docs/features/ai-companions/rag-and-tools).
2. **Action (internal tool calls)** — companions operating the whole product: tricklists, spots, videos, feed. The backend already exposes the REST surface for all of it; the tool registry needs to grow into it. Inventory and architecture in [RAG & Internal Tools](/docs/features/ai-companions/rag-and-tools).

And one embodiment track:

3. **Demonstration** — companions that can *show* every trick of their sport. The procedural foundation shipped; the scaling plan (motion capture → `.vrma` clip library layered over the procedural fundamentals) is in [Motion Capture Pipeline](/docs/features/ai-companions/motion-pipeline).

### Monetization — sample for free, tokens for voice

Free users get a **sample** of the companions (Kaori, with a daily voice allowance); paid tiers unlock the full roster and monthly **voice-token** allotments. Voice is metered because every spoken reply costs real money (TTS + LLM). Full model: [Monetization roadmap](/docs/roadmap/monetization).

### Unlockables — boards, outfits, environments

- **Boards** — deck designs and snowboard graphics as unlockable props (easiest, most on-brand — see [The Board Model](/docs/features/ai-companions/board-model) for the technical path)
- **Outfit colorways → full outfits** — texture swaps first, complete alternate VRMs later
- **Per-sport environments** — Kaori belongs in a **snowy environment**, Tony in a street/park scene, the surf companion on water
- Unlocks come from **both** usage (streaks, tricks landed, XP) and payment tiers

### Roster — skateboarding and snowboarding first

| Companion | Sport | Status |
|-----------|-------|--------|
| **Kaori** 🏔️ | Snowboard | ✅ Live (chat + voice + 3D stage) |
| **Tony** 🛹 | Skateboard | 📋 Next — largest user segment, deepest Trickipedia coverage |
| **Rico** 🏄 | Surf | 📋 Later (after skate + snow are strong) |
| **Max** 🚲 | BMX | 📋 Backlog |
| **Zoe** ⛷️ | Ski | 📋 Backlog |

### Stance-aware coaching

One of the first profile questions for boardsports users will be **regular or goofy** — it changes which direction a frontside rotation goes, which foot leads, and how a companion coaches every trick. Choreography currently assumes regular ([why that matters](/docs/features/ai-companions/animation-system#whats-hardcoded)); stance-awareness is a prerequisite for coaching goofy riders correctly.

## Implementation Status

| Feature | Status |
|---------|--------|
| Chat with personality + 8 shipped tools | ✅ Live |
| Rider persona (corpus-mined register) | ✅ Live (prod 2026-07-09) |
| Unified cross-surface memory + relationship profile | ✅ Live (prod 2026-07-09) |
| Live voice pipeline (Kith + ElevenLabs) | ✅ Live (prod 2026-07-09) |
| Web Kaori Live (3D VRM stage + voice) | ✅ Live (hidden — no nav entry) |
| 3D companion stage (mobile) | ✅ Merged — awaiting new EAS build |
| Speech-synced trick demos (FS360) | ✅ Merged — awaiting new EAS build |
| Mobile rich-content card renderer | ✅ Shipped — dormant (backend never sends `richContent` yet) |
| Voice-endpoint auth + usage metering | 🚧 P0 — see [launch audit](/docs/roadmap/companions-launch) |
| Real RAG on our knowledgebase | 📋 Planned — [architecture](/docs/features/ai-companions/rag-and-tools) |
| Expanded internal tool calls (spots/videos/feed) | 📋 Planned — [inventory](/docs/features/ai-companions/rag-and-tools#tool-call-targets--the-rest-surface-companions-can-grow-into) |
| Mocap-driven trick clip library | 📋 Planned — [pipeline](/docs/features/ai-companions/motion-pipeline) |
| Paywall / free-sample gating | 📋 Planned — see [monetization](/docs/roadmap/monetization) |
| Snowy stage environment · board/outfit unlocks | 📋 Planned |
| Tony (skateboard companion) | 📋 Planned |
| Regular/goofy stance onboarding | 📋 Planned |
