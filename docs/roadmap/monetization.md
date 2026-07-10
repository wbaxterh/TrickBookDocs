---
sidebar_position: 3
title: "Monetization: Paywall & Tokens"
---

# Monetization — Companion Paywall & Token Allocation

Status: **Proposed 2026-07-09 — ready to build** · researched against July-2026 store rules and live COGS

**The model in one paragraph:** free users get a **sample** — Kaori visible and usable with a small daily voice allowance, other companions shown locked. Paid tiers unlock the full roster plus a monthly **voice-token** allotment (1 token = 1 spoken reply). Cosmetics (boards, outfits, environments) unlock through BOTH usage (XP/streaks) and payment tiers. Web sells via our existing Stripe; mobile sells via RevenueCat IAP; the backend Mongo user doc is the single source of truth.

## Why tokens — the unit economics

Voice is where the money burns. Per Kaori reply (~250–350 chars TTS, ~5k-token prompt):

| Cost driver | Per voice reply | Per text reply |
|-------------|----------------|----------------|
| OpenRouter LLM (Gemini Flash class) | ~$0.008–0.012 | ~$0.01 |
| ElevenLabs TTS (current model) | ~$0.05–0.10 | — |
| ElevenLabs TTS (Flash-class model) | ~$0.03–0.05 | — |
| **All-in** | **~$0.04–0.11** | **~$0.01** |

Two COGS levers to pull **before** revenue work (halves cost, better latency):
1. Switch stage TTS to a Flash-class ElevenLabs model (0.5 credits/char vs 1)
2. Enable OpenRouter prompt caching for Kaori's big static persona block (60–80% cheaper repeated context)

## The token model (v1)

- **1 token = 1 voice reply** (one TTS synthesis of one bot message). Text is NOT tokenized — it gets a coarse anti-abuse daily cap (~50/day free). Simple mental model: *voice costs tokens*.
- **Metering lives server-side**: one `requireVoiceTokens` middleware at the places a `/speak` fires (`routes/botChat.js`, `routes/dm.js`, kaori-live path). Atomic decrement (`findOneAndUpdate` with `$gte: 1` guard) **before** calling kith. On empty wallet: still return the **text** reply with `voiceExhausted: true` so the stage shows a top-up prompt instead of going silent.
- **Every debit logs to `usage_events`** (userId, botId, chars, ts) — this doubles as the usage-analytics foundation the UX audit needs.
- Free daily grant is lazy (a `dailyGrant` date field checked on first request of the day) — no cron.
- The Kith sidecar stays dumb; Express is the only gate.

### Tiers (starting point — tune with `usage_events` data)

| Tier | Companions | Voice tokens | Text | Price |
|------|-----------|--------------|------|-------|
| **Free** | Kaori only (sample) | 5/day | 50 msgs/day | $0 |
| **Plus** | Full roster | 200/mo (rollover ≤2×) | Unlimited* | ~$10/mo (existing TrickBook Plus) |
| **Top-up packs** | — | e.g. 100 tokens | — | ~$4.99 (consumable IAP / Stripe) |

*Sanity check: 200 voice tokens ≈ $5–7 COGS on Flash+caching (~40% margin before store fees). Free tier worst case ≈ $6/mo per maxed-out user — acceptable sampling cost.*

## Platform rules (verified July 2026)

- **Apple:** in-app digital purchases still require IAP (guideline 3.1.1). Post-Epic US anti-steering: apps MAY link out to web checkout, currently 0% Apple commission — but the fee question is back in district court, **don't build anything that assumes 0% is permanent**. Web-bought tokens are legal to consume in-app (multiplatform rule).
- **Google (US):** alternative billing + external links allowed since Dec 2025; Epic settlement (reduced fees) pending approval.
- **Practical:** sell tiers + token packs via IAP in-app on both stores, AND surface a "buy on thetrickbook.com" link on US storefronts to the Stripe checkout. Identical pricing; keep the margin difference.

## Architecture

- **RevenueCat** for mobile IAP (`react-native-purchases` — Expo-compatible, needs the dev-client build we already need for the stage; free until ~$2.5k MTR). One webhook → backend.
- **Keep the existing Stripe flow** (`routes/payments.js` already implements the full TrickBook Plus lifecycle) — extend with tier price IDs + one-time token-pack prices. Don't migrate it into RevenueCat in v1.
- **Mongo is canonical:** `user.subscription` (existing) + `user.wallet.voiceTokens` (new) + `unlocks` collection (new). Both webhooks (Stripe, RevenueCat) write into the same fields, idempotent on event id. The app gates from `GET /api/payments/subscription`, never from client-side store state.

## Unlockables

One `unlocks` collection: `{userId, itemId, source: 'xp' | 'tier' | 'purchase', grantedAt}`. Client only ever asks "is itemId unlocked", never "how". Tier-sourced unlocks deactivate on downgrade; XP- and purchase-sourced are permanent.

Build order by asset cost:
1. **Boards** (easiest, most on-brand) — separate `.glb` props, no VRM surgery; deck graphics are cheap content
2. **Colorways** — runtime MToon base-color texture swaps on the existing VRM; dozens of recolors from one avatar
3. **Full outfits** (heaviest) — one complete `.vrm` per outfit (runtime mesh-swapping inside a VRM is fragile); device-cached, lazy-downloaded, keep to 3–5 per companion
4. **Environments** — independent of the VRM: skybox/ground/props swap in the scene. Kaori gets **snow**; each sport gets its own vibe. Unlockable the same way.

Apple compliance note: XP/streak-earned cosmetics are fine; directly-purchased cosmetics on iOS must be IAP products — **pricing cosmetics in voice tokens is the elegant move** (tokens are already a compliant consumable).

## Build phases

1. **Metering foundation + cost control** (backend only): wallet + `usage_events` + `requireVoiceTokens` + lazy daily grant + `voiceExhausted`; flip TTS to Flash-class; enable prompt caching
2. **Free-sample gating**: companion list returns locked/unlocked per plan; mobile picker + web locked states; text daily cap; `adminOverride` for QA
3. **Web purchases first** (fastest to revenue, zero store review): extend `payments.js` with tier + token-pack prices; paywall + wallet UI on the site
4. **Mobile IAP via RevenueCat**: store products, RC webhook → same Mongo fields, server-driven paywall screen (bundle into the Kaori-stage EAS build)
5. **US steering escape hatch**: external purchase links on iOS/Play US storefronts (re-check the Apple fee ruling first)
6. **Unlockables v1**: `unlocks` collection, board props + colorway swaps, cosmetics priced in tokens, XP earn rules from `usage_events`
7. **Unlockables v2 + world-building**: full outfit VRMs, snowy Kaori environment, per-sport stages
8. **Tune with data**: usage dashboards, re-price allotments from observed chars/reply + cache hit rates; every new companion (Tony, etc.) is then content, not new billing plumbing
