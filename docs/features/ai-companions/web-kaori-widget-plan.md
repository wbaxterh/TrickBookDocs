---
sidebar_position: 3
title: "Web Kaori Chat & Live Beta Plan"
description: Product and technical plan for an authenticated Kaori chat widget, 3D live beta, usage controls, and upgrade flow.
---

# Web Kaori Chat & Live Beta Plan

Status: **Implementation plan — 2026-09-30** · Scope: web app + shared backend · No product code shipped by this document

:::info[Implementation started — 2026-09-30]
The first web slice and text-usage control plane are implemented locally. The shared-layout launcher/drawer now has authenticated Kaori DM bootstrap, 20-message history, Socket.IO replies, relationship greeting, login return, Live Beta handoff, responsive UI, accessible controls, and dual PostHog/backend analytics events.

The backend now enforces server-authoritative daily text allowances (free 20, Plus 250), account and pseudonymous-device minute limits, one in-flight generation per account, 45-second expiring generation leases, atomic counter increments, reservation/settlement/refund events, 4,000-character input ceilings, and structured `402`, `409`, and `429` responses on both DM and bot-chat entry points. The widget reads the allowance endpoint, preserves rejected drafts, and presents the Plus upgrade state.

Voice replies are now separately metered (free 5/day, Plus 200/month), including Live greetings. The Kith service rejects direct browser speech requests, requires a 32+ character shared secret on backend `/speak` calls, limits global and per-IP concurrent sessions, caps each session at 15 minutes, and rejects oversized TTS payloads. Still pending: signed WebSocket admission tickets, provider spend alarms/kill switches, and checkout return directly into the reopened widget.
:::

## Decision

Ship Kaori as a persistent bottom-right web companion for all traffic. Anyone can see the launcher, but only authenticated riders can send messages or start Kaori Live. Text chat opens in a compact drawer. A secondary **Video chat — Beta** action opens the existing `/kaori-live` 3D voice experience.

This is an expansion of the existing companion system, not a new chatbot:

- reuse the production Kaori response engine, 14-tool registry, relationship memory, and Atlas retrieval over Trickipedia, films, spots, and events;
- reuse the existing DM conversation and Socket.IO delivery path so widget, Messages, mobile, and Kaori Live share history;
- reuse the existing VRM/Kith experience at `/kaori-live`, then harden its authentication, metering, and session lifecycle;
- reuse Stripe and the canonical `user.subscription` record for paid access.

"Video chat" means a live, spoken conversation with the rendered 3D Kaori character. Version one does **not** request the rider's camera. It requests microphone permission only after a clear user action. This is more honest, works on more devices, and avoids collecting video that the experience does not use.

## Rider experience

### Launcher and drawer

Mount one `KaoriWidget` in the shared web layout, above mobile safe areas and without covering cookie banners, checkout, or other fixed controls.

1. **Collapsed:** Kaori portrait, online/status treatment, and accessible label `Chat with Kaori`.
2. **First authenticated open:** Kaori gives one short relationship-aware greeting: she is TrickBook's action-sports expert and asks what the rider is working on. Do not auto-play audio.
3. **Chat:** last 20 messages, streaming/typing state, retry state, text box, send button, and suggested prompts such as “What should I learn next?” or “Find a spot near me.”
4. **Live action:** `Video chat — Beta` with a beta badge and a one-line explanation: “Talk with Kaori’s 3D character.”
5. **Logged out:** keep the drawer useful but locked. Show what Kaori can do and a `Log in to chat` action whose callback returns to the current page and reopens the drawer.
6. **Allowance low/exhausted:** show remaining access near the composer only when it is relevant. On exhaustion, preserve conversation history, disable the costly action, and show `Get more Kaori` plus plan details. Never discard a typed message.

The greeting must happen once per relationship session, not once per route change. Store the greeted state server-side or in session storage keyed by companion and conversation; never make every page navigation spend an AI/voice credit.

### Expert behavior

Kaori should introduce herself as an expert guide to action sports, while staying honest about her strongest snowboard identity. “Trained on all TrickBook data” is implemented as **grounded retrieval and tools**, not a fine-tuning claim:

- search the live TrickBook corpus first for factual questions about tricks, progression, films, spots, events, and riders;
- attach source IDs/URLs to tool results and render source chips in the widget;
- state when TrickBook does not contain an answer rather than inventing one;
- infer the active sport from page context and the rider profile, but allow the rider to correct it;
- keep write tools scoped to the authenticated user and require confirmation for consequential changes;
- prevent retrieved text and user content from overriding system/tool policy.

The current Atlas index already covers the core product corpus. Before launch, add an automated coverage report with document counts, freshness, failed embeddings, and sport/category distribution. “All data” is not a one-time import; it is an ingestion SLA.

### Kaori Live beta

The button opens `/kaori-live?source=widget` in the same tab, with a visible `Beta` badge and a return path. Keep the current typed fallback available when speech recognition or audio playback is unavailable.

Before entering Live:

- check entitlement and remaining voice allowance server-side;
- acquire a short-lived live-session lease tied to user + device;
- display microphone purpose before the browser permission prompt;
- load the 3D stage lazily only after navigation, not with every page's widget bundle;
- cap idle time and total session duration; release the lease on disconnect and expire abandoned leases automatically;
- authenticate the Kith WebSocket with a short-lived, audience-scoped ticket. A public WebSocket URL or client-supplied user ID is not authorization.

Release the beta entry point to 100% of traffic, but keep independent server-side kill switches for `kaoriWidget`, `kaoriText`, and `kaoriLive`. “All traffic” should not remove the ability to stop runaway cost or a broken voice dependency.

## Architecture

```text
Shared Layout
  -> KaoriWidget (lazy drawer)
      -> authenticated companion bootstrap endpoint
          -> entitlement + allowance snapshot
          -> existing Kaori bot/conversation
          -> recent shared history + greeting state
      -> existing DM send + Socket.IO receive
          -> usage reservation
          -> Kaori brain -> Atlas RAG/tools -> OpenRouter
          -> usage settlement + analytics
      -> Video chat — Beta
          -> live-session lease + signed WS ticket
          -> existing /kaori-live VRM stage + Kith voice
          -> voice reservation/settlement
```

Add one bootstrap endpoint rather than making the widget fan out across bot-list, conversation, profile, subscription, and usage endpoints:

```json
GET /api/companion/kaori/bootstrap
{
  "companion": { "id": "...", "name": "Kaori", "avatar": "..." },
  "conversationId": "...",
  "messages": [],
  "greeting": { "text": "...", "alreadyShown": false },
  "entitlement": { "tier": "free", "textEnabled": true, "liveEnabled": true },
  "allowance": { "textRemaining": 20, "voiceRemaining": 5, "resetsAt": "..." },
  "live": { "beta": true, "available": true }
}
```

The response is a convenience snapshot, not authorization. Every send, tool call, TTS request, and live-session connection rechecks its own server-side policy.

## Authentication and device sessions

- Require the existing JWT middleware on bootstrap, greeting, text-send, allowance, live-ticket, and voice routes.
- Derive `userId` exclusively from the verified token; ignore user IDs supplied in request bodies.
- Use account ID as the primary quota key.
- Add a random, pseudonymous `tb_device` ID in a signed, Secure, HttpOnly, SameSite=Lax cookie. Do not use invasive browser fingerprinting.
- Treat device ID and a privacy-preserving IP/network hash as abuse signals and backstops, not identity. Rotate the IP hash salt and retain only the window needed for abuse review.
- Limit one in-flight generation per account and one active Live session per account/device in v1. A second tab can take over after explicit confirmation or after the lease expires.
- Store leases with `{userId, deviceId, sessionId, expiresAt, lastSeenAt}` and a TTL index. Heartbeats extend the lease within a hard maximum duration.

## Metering, throttling, and paywall

Use two layers. A request limiter protects availability; a durable allowance ledger protects credits and billing.

### Initial limits (configuration, not hardcoded product promises)

| Control | Free | Plus | Purpose |
|---|---:|---:|---|
| Text generations | 20/day | 250/day fair-use | LLM cost and scripted abuse |
| Voice replies | 5/day | 200/month | TTS cost |
| Concurrent generations | 1/account | 1/account | duplicate sends and cost spikes |
| Active Live sessions | 1/account + device | 1/account + device | subprocess/session exhaustion |
| Live session hard cap | 10 minutes | 30 minutes | abandoned sessions and denial-of-wallet |
| Message length | 2,000 chars | 4,000 chars | prompt amplification |

Validate these numbers against real `usage_events` and COGS after two weeks. Avoid “unlimited”; paid access remains a clearly disclosed fair-use allowance.

### Enforcement order

1. verify auth and account status;
2. validate payload size/type;
3. apply short-window account + device + IP rate limits;
4. atomically reserve allowance before calling an AI/voice provider;
5. run the generation with timeout, tool-iteration, and output-size ceilings;
6. settle actual usage, or idempotently refund the reservation on provider failure;
7. record provider/model, latency, tokens/characters, surface, result, and estimated cost.

Use a unique request id and an atomic conditional update (`remaining >= cost`) so retries or parallel tabs cannot double-spend. MongoDB documents that compound `findOneAndUpdate` operations are atomic; the debit and immutable `usage_events` record should use a transaction when both must succeed together.

Return structured errors:

- `401 AUTH_REQUIRED` — open login with callback;
- `409 GENERATION_IN_PROGRESS` or `LIVE_SESSION_ACTIVE` — offer retry/takeover;
- `429 RATE_LIMITED` — include `retryAfter`;
- `402 ALLOWANCE_EXHAUSTED` — include reset time and eligible upgrade/top-up offers;
- `503 AI_TEMPORARILY_UNAVAILABLE` — keep the draft and offer retry.

The existing Stripe Plus flow remains the first paid path. Extend the subscription response with companion entitlements and allowances. Upgrade checkout returns to the open Kaori drawer, refreshes entitlements from the backend, and restores the rider's draft. Webhook state—not a successful client redirect—unlocks access.

## Safety, privacy, and trust

- Render assistant output as escaped text plus allowlisted rich cards; never inject raw model HTML.
- Enforce tool ownership and permissions in handlers, independent of what the model requests.
- Separate instructions from retrieved/user data, constrain tool schemas, and log denied tool calls. OWASP recommends least privilege, user/session memory isolation, input/output controls, request limits, spend ceilings, and kill switches for LLM systems.
- Moderate user input and model output with a deterministic policy plus provider classifier appropriate to the chosen model stack. Provide `Report response` in the message menu.
- Never place secrets, raw tokens, private cross-user messages, or unrestricted database documents in prompts.
- Publish retention behavior for chat, companion memory, audio, and abuse telemetry. Do not record microphone audio by default.
- Add account controls to clear Kaori history and remembered facts without deleting the whole TrickBook account.

## Analytics and operating targets

Instrument `kaori_launcher_viewed`, `kaori_opened`, `kaori_login_clicked`, `kaori_message_sent`, `kaori_response_completed`, `kaori_source_opened`, `kaori_live_clicked`, `kaori_live_connected`, `kaori_limit_warning`, `kaori_paywall_viewed`, `kaori_checkout_started`, and `kaori_upgrade_completed`.

Launch dashboard:

- activation: authenticated open → first useful response;
- 7-day repeat use and conversations per active rider;
- source/tool success and grounded-answer evaluation pass rate;
- p50/p95 time to first text and Live connection time;
- generation, voice, and tool error rates;
- cost per free active rider and paid active rider;
- limit-hit → upgrade conversion, refund/support rate, and false-positive abuse reports;
- concurrent Live sessions, orphaned leases, CPU/memory, and provider credit balance.

Initial service targets: text success ≥99%, p95 first response ≤8s, Live connect success ≥95%, no duplicate charges/replies, and a hard daily spend alert at 50/75/90/100% of budget.

## Delivery sequence

### Phase 0 — correct and measure

- fix and regression-test SSO → `/profile/:userId` before adding another authenticated surface;
- add usage/cost events to both `routes/dm.js` and `routes/botChat.js`;
- reconcile current web docs with the shipped trick-demo code and remove stale architectural claims;
- create grounded-answer evals across every sport and corpus type.

### Phase 1 — backend control plane

- implement canonical entitlement/allowance service, reservation ledger, and indexes;
- add account/device/IP limiters backed by a shared production store;
- cover DM, bot-chat, greeting, tool loop, TTS, and Kith connection paths—no cheaper side door;
- add live leases, signed WS tickets, provider timeouts, circuit breakers, and spend alarms;
- extend Stripe checkout/webhooks and subscription response.

### Phase 2 — widget

- build a lazy, accessible widget in the shared layout;
- bootstrap shared conversation/history and resume Socket.IO updates;
- add source cards, login-return flow, allowance warnings, paywall, and analytics;
- suppress or reposition on narrow screens and routes where it conflicts with primary UI.

### Phase 3 — Live beta

- add Beta labeling, preflight, microphone disclosure, typed fallback, lease heartbeat, timeout, and return path;
- ensure text-only fallback survives Kith/ElevenLabs failure;
- performance-budget the VRM and move unused/source assets out of the public bundle;
- release the entry point to 100% with server-side kill switches.

### Phase 4 — tune

- run two weeks of cost, retention, latency, and limit-hit review;
- adjust allowances from observed unit economics rather than guesses;
- interview riders who used and abandoned Live;
- only then consider top-up packs, camera-based coaching, or additional companions.

## Acceptance criteria

- Google, Apple, and credentials login land on the authenticated rider's public profile without a login bounce.
- The launcher is visible site-wide, keyboard/screen-reader usable, and does not load the 3D bundle.
- Logged-out sends and Live starts never reach an AI provider.
- Widget, Messages, mobile, and Live show one coherent Kaori history.
- Kaori answers tested TrickBook questions from current indexed data with traceable sources and admits missing coverage.
- Quotas cannot be bypassed with refreshes, tabs, devices on one account, direct API calls, or retries.
- Concurrent sends do not double-charge or emit duplicate replies.
- Exhaustion shows reset/upgrade choices while preserving history and drafts.
- Live is visibly Beta, microphone-only by default, has a typed fallback, and releases abandoned sessions.
- Provider outage and global budget kill switch degrade to a clear, non-destructive unavailable state.

## Research references

- [OWASP LLM Prompt Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html)
- [OWASP Secure AI Model Ops Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secure_AI_Model_Ops_Cheat_Sheet.html)
- [MongoDB Node.js compound operations](https://www.mongodb.com/docs/drivers/node/current/crud/compound-operations/)
- [MongoDB atomicity and transactions](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/)
- [Stripe subscription webhooks](https://docs.stripe.com/billing/subscriptions/webhooks)
- [Stripe Entitlements](https://docs.stripe.com/billing/entitlements)
- [MDN: MediaDevices.getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)
