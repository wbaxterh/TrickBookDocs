---
sidebar_position: 1
---

# Priority Roadmap

Status: **Rewritten 2026-07-09** to align with what's actually built (Kaori 3D companion shipped) and the current product vision: launch the companions behind a paywall, then iterate — more tricks, more companions, better UX everywhere.

## The vision in one paragraph

Companions are the product's differentiator: a coach in your pocket for every action sport, with a body, a voice, and a memory. Kaori (snowboard) is built — 3D stage, live voice, speech-synced trick demos, unified memory. Next: ship her to users with a **free-sample paywall and voice-token allocation**, then iterate the companion experience (more tricks, snowy environment, outfit/board unlocks, stance-aware coaching), add the **skateboarding companion**, refactor **Spots** into a flagship-quality UX, and instrument the whole app with **usage analytics** so decisions stop being guesses. Surfing companion after skate + snow are strong.

## Priority Matrix

### P0 — Ship the companions (now)

The feature is merged and prod-deployed; nothing installable contains it yet. Full audit: [Companions Launch](/docs/roadmap/companions-launch).

| # | Task | Repo | Effort | Status |
|---|------|------|--------|--------|
| 1 | **Secure the voice WebSocket** (JWT on upgrade, session caps, text-length cap) — live exposure TODAY | Backend | 1–2 days | Pending |
| 2 | New EAS dev-client build + physical-device validation (MToon, voice, choreography) | Mobile | 1 day | Pending |
| 3 | v3.2.0 TestFlight + Play internal builds (version bump, store pipeline dusted off) | Mobile | 1 day | Pending |
| 4 | Monitoring: Sentry both services, kith-voice in ecosystem.config, ElevenLabs credit alarm, uptime checks | Backend | 1–3 days | Pending |
| 5 | Release notes `docs/releases/v3.2.0.md` when the build ships | Docs | 0.5 day | Pending |

### P1 — Monetization foundation (before public launch)

Full model: [Monetization: Paywall & Tokens](/docs/roadmap/monetization).

| # | Task | Repo | Effort | Status |
|---|------|------|--------|--------|
| 1 | COGS levers: Flash-class TTS on stage + OpenRouter prompt caching | Backend | 0.5 day | Pending |
| 2 | Token metering: `user.wallet.voiceTokens`, `usage_events`, `requireVoiceTokens` middleware, lazy daily grant | Backend | 3–5 days | Pending |
| 3 | Free-sample gating: Kaori-only for free tier, locked companion states + upsell UI | Backend + Mobile + Web | 3–5 days | Pending |
| 4 | Web purchases: extend Stripe `payments.js` with tier + token-pack prices, site paywall/wallet UI | Backend + Web | 3–5 days | Pending |
| 5 | Mobile IAP via RevenueCat (fold into the companion EAS build) | Mobile + Backend | 5–10 days | Pending |
| 6 | Basic rate caps on bot-chat (interim until metering lands) | Backend | 1 day | Pending |

### P2 — Companion iteration + the skate companion

| # | Task | Repo | Effort | Status |
|---|------|------|--------|--------|
| 1 | **Regular/goofy stance onboarding** — early profile question for boardsports users; feeds stance-aware choreography + coaching | Mobile + Backend | 2–3 days | Pending |
| 2 | Better snowboard 3D design (shape, materials, deck art) | Mobile | 1–2 days | Pending |
| 3 | Refine FS360 + expand the snowboard TRICKS registry (bs 180, ollie, butters, grabs…) | Mobile | ~0.5–1 day per trick | Pending |
| 4 | **Snowy stage environment for Kaori** (skybox/terrain/props; per-sport environments pattern) | Mobile | 3–5 days | Pending |
| 5 | Companion models → CDN with device cache (kills the 14MB bundle tax; prerequisite for outfits + roster growth) | Mobile + Backend | 1–2 days | Pending |
| 6 | Unlockables v1: boards + colorways, XP/tier/purchase `unlocks` collection | Mobile + Backend | 3–5 days | Pending |
| 7 | **Tony — skateboarding companion**: VRM avatar, persona corpus (skate media), voice, skate TRICKS registry (ollie, kickflip, shuv…), street/park environment | All | 2–3 weeks | Pending |
| 8 | Analytics events on all companion surfaces (demo opens, voice minutes, trick views) via `usage_events` | Mobile + Backend | 2 days | Pending |

### P3 — Platform quality (parallel track)

| # | Task | Repo | Effort | Status |
|---|------|------|--------|--------|
| 1 | **Spots UX refactor** — browsing/filtering/detail flows re-designed to flagship quality; the map overlay work was the start | Mobile + Web | 1–2 weeks | Pending |
| 2 | **Full-app UX audit** (web + mobile): intuitiveness/value pass on every flow, informed by analytics | All | 1 week audit + fixes | Pending |
| 3 | Usage-analytics instrumentation app-wide (PostHog exists on web; add mobile SDK + event taxonomy) | Mobile + Web | 3–5 days | Pending |
| 4 | Surf companion (Rico) — after skate + snow are strong | All | Later | Backlog |
| 5 | Engineering-standards carryover: tests on critical paths, Zod API schemas, structured logging, API versioning | All | Ongoing | Partial |

**Engineering-standards status (July 2026):** Biome + Husky + CI ✅ (mobile, backend, docs) · Node 20 on prod ✅ · Google Play closed alpha ✅ · Push notifications ✅ (v3.1.0) · rate limiting ⚠️ partial (auth/registration only) · Sentry, tests, health endpoint, graceful shutdown still pending — folded into P0#4 and P3#5 above.

---

## Quarterly Plan

### Q3 2026 — Launch the companions

- [x] Kaori 3D stage + live voice + FS360 demos (merged PR #4)
- [x] Backend persona / unified memory / voice pipeline in prod (2fa8388)
- [ ] Secure voice endpoint + monitoring
- [ ] v3.2.0 TestFlight + Play internal
- [ ] Token metering + free-sample paywall
- [ ] Web purchases live; mobile IAP submitted
- [ ] Public launch with paywall from day one

### Q4 2026 — Iterate + second companion

- [ ] Stance onboarding (regular/goofy)
- [ ] Snowboard trick library expansion + snowy environment
- [ ] Unlockables v1 (boards, colorways)
- [ ] Tony (skateboard) alpha
- [ ] Spots UX refactor
- [ ] Full-app UX audit + analytics instrumentation

### 2027 — Scale the roster

- [ ] Tony launch + skate trick library
- [ ] Outfit VRM variants + per-sport environments
- [ ] Surf companion (Rico) exploration
- [ ] Community/social growth features informed by analytics

---

## Metrics to Track

### Companion & business

| Metric | Why |
|--------|-----|
| Stage opens / DAU | Is the flagship discoverable? |
| Voice replies per user per day | Token-tier tuning input (from `usage_events`) |
| Free → paid conversion | The paywall's whole job |
| Voice COGS per user per month | Must stay under tier price; alarm on drift |
| Demo → "Learning" trick status lift | Does coaching actually work? |
| D1/D7/D30 retention, companion users vs not | The differentiation hypothesis |

### Engineering health

| Metric | Current | Target |
|--------|---------|--------|
| Crash-free sessions | Unknown (no Sentry) | >99.5% |
| Mean time to detect error | Days (user report) | Minutes (Sentry alert) |
| CI pass rate | Green on all repos | >95% |
| Test coverage | ~0% | 40% on critical paths |
