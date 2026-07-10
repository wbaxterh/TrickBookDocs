---
sidebar_position: 2
title: "Companions Launch Audit"
---

# Companions Launch Audit — how far from users?

Status: **Audited 2026-07-09** · everything below verified against live prod + the merged code

**TL;DR:** the feature is done and its backend is live in prod — but **zero installable builds contain it**. TestFlight is ~3–5 days away (one EAS build cycle + device validation). An un-embarrassing **public** launch is ~2–3 weeks away, gated on cost controls, monitoring, and the paywall. One item is urgent **today** regardless of any release: the voice WebSocket is publicly reachable without auth.

## What's already shipped

| Layer | State |
|-------|-------|
| Mobile code | ✅ Full Kaori 3D companion merged to `v2-rebuild` (PR #4, squash `b7b94ce`, 2026-07-08) |
| Backend | ✅ Deployed to prod EC2 (`2fa8388`, 2026-07-09): persona, unified memory, stage gating, vendored Kith sidecar, voice cutover |
| Voice infra | ✅ `kith-voice` PM2 service on :3040, nginx `/kith/ws` proxy verified externally, E2E speak test passed |
| Web | ✅ `kaori-live` deployed on Amplify |

## Gap list

### 🔥 Do first — live exposure today

| Gap | Detail | Effort |
|-----|--------|--------|
| **Unauthenticated public voice WS** | `wss://api.thetrickbook.com/kith/ws` upgrades ANY connection — no JWT, no session cap, no text-length cap. Each session spawns its own Python runtime on the same EC2 box as the whole API. A scripted client could drain the entire ElevenLabs quota and OOM the API host **without installing the app**. Fix: JWT check on WS upgrade, per-user + global session ceilings, speak-text length cap, restrict/remove the client-side `speak` path (backend `/speak/:sessionId` is the legit path). | 1–2 days |

### Blockers for TestFlight

| Gap | Detail | Effort |
|-----|--------|--------|
| No build contains the feature | Latest dev-client (2026-07-07) predates the merge. New native modules (expo-gl/three, audio-api, speech-recognition) → full EAS rebuild; MToon needs **physical-device** validation | 1–2 days |
| Stale store pipeline + version bump | No TestFlight-profile build since ~Feb (v2.1.0); `app.config.js` version/buildNumber need a coherent bump (→ v3.2.0). Signing is fine (cert renewed 2026-06-30) | 0.5–1 day |
| Release notes page | Per our process: `docs/releases/v3.2.0.md` + screenshots when the build ships | 0.5 day |

### Blockers for public launch

| Gap | Detail | Effort |
|-----|--------|--------|
| No rate limits / metering on bot-chat | `POST /api/bot-chat/message` = JWT only; no per-user caps, no message-length cap, no usage ledger. Every message costs OpenRouter + (on stage) ElevenLabs. One scripted account = unbounded spend | 1–2 days basic caps; 5–10 for full [token metering](/docs/roadmap/monetization) |
| Companion 100% ungated | Both entry points reachable by every user; zero entitlement/paywall code anywhere. Free-sample model unbuilt (the existing Stripe `hasPremiumAccess` pattern is the reusable foundation) | 5–10 days |
| iOS IAP compliance | In-app digital gating on iOS needs StoreKit/RevenueCat, not the existing Stripe web checkout — see [monetization](/docs/roadmap/monetization) | 5–10 days (parallel) |
| No monitoring / quota alarm | PM2 only; `kith-voice` isn't in `ecosystem.config.js`; no Sentry, no uptime checks, and **no ElevenLabs credit alarm** — quota exhaustion degrades voice silently | 1–3 days |
| Shared-EC2 blast radius | Voice sessions (one Python runtime each) share the instance with the entire API. Global session cap + `max_memory_restart` now; separate instance/container before scale | 2–4 days |
| App-review prep for AI chat | Apple's age-rating questionnaire now asks about AI chat (expect 13+); add AI disclosure, a report/flag mechanism for bot replies, and documented safety rails for review notes | 1–3 days |

### Nice-to-have

| Gap | Detail | Effort |
|-----|--------|--------|
| 14 MB VRM in every download | `kaori.vrm` bundles into every IPA/AAB. Move companion models to CDN + cache-on-first-open — also the prerequisite for shipping outfits/companions without app releases | 1–2 days |
| Voice-client resilience polish | Fixed 3s reconnect (no backoff); `voiceReady` not reset on WS close (UI can show voice as available after a drop) | 0.5 day |

## Path to launch

1. **This week:** secure kith WS (do first) → EAS dev-client build → physical-device validation → v3.2.0 TestFlight build + release notes
2. **Weeks 2–3:** basic rate caps → metering foundation + free-sample gating ([monetization phases 1–2](/docs/roadmap/monetization)) → monitoring + ElevenLabs alarm → app-review prep
3. **Launch:** public store release with the paywall live from day one — the free sample IS the launch funnel
