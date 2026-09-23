---
title: Retention, Measurement & LTV Strategy
sidebar_position: 1
---

# Retention, Measurement & LTV Strategy

Status: **Proposed 2026-09-23 — specification complete; implementation not started**

TrickBook's immediate product problem is no longer only acquisition. Available
production checkpoints grew from **326 users on September 11 to 354 on
September 23**: 28 net new accounts, or 8.6%. The stronger measured week had
16 new users versus 7 in the prior week, while weekly active users moved from
5 to 7. Website pageviews rose 9%, but App Store clicks fell from 5 to 1. Event
pages became the largest site section, and one Malibu event produced 73% of
identified Google traffic. Reach is improving faster than our ability to
explain activation, retention, or conversion.

This specification defines the system needed to answer four questions before
we optimize monetization:

1. Which product behaviors create durable rider value?
2. Which acquisition sources and app versions retain those riders?
3. Can every supported client receive the correct update policy safely?
4. When is there enough evidence to meter AI without damaging the free habit?

## Product principles

- **Core progression remains free.** Trick tracking, attempts, landings, spots,
  events, profiles, posting, and social participation are the habit loop.
- **Meter marginal cost, not belonging.** AI voice/video analysis and advanced
  coaching are the natural paid layer because usage has measurable COGS.
- **Measure before redesigning.** Instrument flows before changing onboarding,
  Spots, Events, or companions.
- **Cohorts beat totals.** Aggregate signups can rise while retention falls.
- **Server decisions are authoritative.** Version policy, entitlements, wallet
  debits, and accepted analytics events cannot depend on client claims alone.
- **No dark patterns.** Update prompts are proportional, paywalls state the
  benefit and price, and analytics collection follows consent and deletion rules.

## North-star and metric hierarchy

The north-star metric is **Weekly Progressing Riders (WPR)**: distinct riders
who complete at least one meaningful action during a rolling seven-day window.
A meaningful action is one of:

- add a trick, log an attempt, or record a landing;
- save an event or spot, add an event to a calendar, or open directions;
- complete a substantive AI coaching interaction;
- create a post/comment or form a rider connection.

Supporting metrics:

- **Activation:** first meaningful action within 48 hours of registration.
- **Time to value:** registration to first meaningful action, p50/p90.
- **Retention:** D1, D7, D14, D30, and rolling W4 retention.
- **Depth:** meaningful actions per progressing rider per week.
- **Breadth:** number of distinct value domains used per retained rider.
- **AI economics:** cost, replies, completion rate, and retained-user lift.
- **Version health:** active devices by version/build and update conversion.
- **Revenue:** trial start, paid conversion, ARPPU, churn, gross margin, and LTV.

`active` must never mean merely opening the app. WPR is the strategic metric;
DAU/MAU remains diagnostic.

## Canonical event contract

Every event uses a client-generated UUID and this envelope:

```json
{
  "eventId": "uuid-v7",
  "name": "trick_attempt_logged",
  "occurredAt": "2026-09-23T18:00:00.000Z",
  "receivedAt": "server-assigned",
  "anonymousId": "installation-scoped-id",
  "userId": "nullable-before-auth",
  "sessionId": "uuid",
  "platform": "ios|android|web",
  "appVersion": "3.2.0",
  "buildNumber": 18,
  "schemaVersion": 1,
  "source": {
    "firstTouch": "google|instagram|direct|referral|other",
    "utmSource": "nullable",
    "landingPath": "/events/..."
  },
  "properties": {}
}
```

Required rules:

- `eventId` has a unique database index; retrying is idempotent.
- `occurredAt` is client time, while `receivedAt` is trusted server time.
- Events are append-only. Corrections are new events, never silent mutations.
- Known users are identified across devices; anonymous history is aliased once
  at authentication without rewriting raw events.
- Event properties use IDs and bounded enums, not names, email, free text, raw
  prompts, exact location, or media contents.
- Schema versions are validated server-side. Unknown names/properties are
  quarantined rather than contaminating production metrics.
- Internal staff, bots, App Review, and automated QA are labeled and excluded
  by default, never deleted from the underlying evidence.

### Initial taxonomy

**Lifecycle:** `app_installed`, `app_opened`, `signup_completed`,
`onboarding_started`, `onboarding_completed`, `session_ended`.

**Progression:** `trick_viewed`, `trick_added`, `trick_attempt_logged`,
`trick_landed`, `progression_status_changed`.

**Discovery:** `spot_viewed`, `spot_saved`, `spot_directions_opened`,
`event_viewed`, `event_saved`, `event_calendar_added`, `event_shared`.

**AI:** `ai_session_started`, `ai_response_completed`,
`ai_session_completed`, `ai_allowance_exhausted`. Store model, latency,
token/character counts, and cost micros—never prompt text in analytics.

**Community:** `post_created`, `comment_created`, `rider_followed`,
`homie_connected`.

**Notifications:** `notification_permission_result`, `notification_received`,
`notification_opened`, with category/campaign IDs.

**Versioning:** `version_heartbeat`, `update_prompt_seen`,
`update_prompt_dismissed`, `update_store_opened`, `update_completed`.

**Revenue:** `paywall_viewed`, `checkout_started`, `trial_started`,
`subscription_started`, `subscription_renewed`, `subscription_canceled`,
`subscription_expired`, `ai_credit_debited`. Store receipts/webhooks remain the
financial source of truth; analytics events do not grant entitlements.

## Feature-value analysis

Assign every meaningful event to a value domain: `progression`, `discovery`,
`coaching`, or `community`. For each signup cohort, compare D7/D30 retention by:

- first value domain and first meaningful event;
- acquisition source and first landing page;
- sport, platform, app version/build, and onboarding variant;
- number of value domains reached in the first 48 hours;
- AI users versus propensity-matched non-AI users.

Do not call correlation causation. Use cohort findings to choose a hypothesis,
then randomized feature flags to test it. Every experiment needs one primary
metric, guardrails, exposure events, minimum run time, and a written stopping
rule before launch.

## Version inventory and update policy

The existing push-token record accepts `appVersion`, but that is incomplete:
it sees only registered tokens and becomes stale. Add an authenticated or
anonymous `POST /api/client-heartbeat` on launch/resume with installation ID,
platform, semantic version, build number, OS/device family, locale, timezone,
first-seen, last-seen, and notification capability. Upsert one current record
per installation; retain version transitions separately.

`GET /api/mobile/version-policy?platform=ios` returns a signed/configured policy:

```json
{
  "latestVersion": "3.2.0",
  "minimumSupportedVersion": "3.1.0",
  "promptMode": "optional|required",
  "title": "A new TrickBook is ready",
  "message": "Release-specific plain text",
  "storeUrl": "platform-specific URL",
  "effectiveAt": "2026-09-23T18:00:00Z",
  "gracePeriodHours": 24,
  "policyRevision": 7
}
```

- Current: no prompt.
- Below latest but at/above minimum: dismissible prompt, frequency-capped.
- Below minimum: blocking prompt after `effectiveAt` plus grace period.
- Never interrupt onboarding, media upload, payment, an active coaching
  response, or an unsaved attempt. Apply a required prompt at the next safe point.
- Cache the last valid policy. If the policy endpoint fails, do not convert an
  optional update into a required one. Emergency blocks require a cached,
  unexpired signed policy.
- Admin changes require reason, actor, timestamp, and immutable audit history.

Dashboard slices: active installations by version over 1/7/30 days, update
prompt funnel, retention/crash rate by build, and unsupported-client attempts.

## Retention interventions

Interventions are triggered by demonstrated intent, not generic blasts:

- Incomplete onboarding: resume the next unfinished choice.
- First trick saved but no attempt: reminder tied to that trick and preferred
  riding window.
- Attempt without landing: progression tip or prerequisite, not a sales prompt.
- Event saved: time-sensitive reminder with calendar/location action.
- Former weekly rider inactive 7 days: recap progress and suggest one achievable
  next action.
- AI allowance nearing exhaustion: show remaining value and cost before use;
  paywall only when intent is clear.

Frequency caps, quiet hours, per-category preferences, unsubscribe, minors'
protections, and notification received/opened attribution are required.

## LTV model and monetization gate

Until paid cohorts mature, use a leading value model:

```text
Expected LTV = expected retained paid months × monthly gross margin
Monthly gross margin = recognized revenue − store fees − AI variable cost
```

Report realized LTV only from revenue/expense facts. A separate **LTV potential
score** may rank cohorts using retained weeks, meaningful-action depth, and
premium-feature affinity, but it must never be labeled dollars.

AI monetization proceeds only when four gates are satisfied:

1. reliable D7/D30 cohorts and event completeness are available;
2. AI cost per active user and per completed outcome is measured;
3. repeated demand and allowance exhaustion are observed;
4. an experiment shows the proposed allowance/paywall does not materially harm
   activation or retained core usage.

Free core actions never debit AI credits. Server-side atomic debit precedes paid
work, retries are idempotent, and failed generation refunds or never settles the
reservation. Stripe/RevenueCat webhooks grant entitlements idempotently.

## Data model and ownership

- `client_installations`: latest version/device heartbeat per installation.
- `client_version_history`: append-only version transitions.
- `mobile_version_policies`: revisioned platform policies and audit metadata.
- `analytics_events`: immutable validated event envelopes, unique `eventId`.
- `analytics_quarantine`: rejected schema versions/names with safe diagnostics.
- `experiment_exposures`: stable assignment, variant, eligibility, exposure time.
- `usage_events`: billable AI reservations/debits/refunds and unit cost.
- Existing subscription/wallet records remain canonical for entitlement.

The backend owns validation, deduplication, policy, entitlement, and cost facts.
Clients own capture timing and presentation. PostHog is an analysis sink, not the
canonical ledger; the backend event store can forward a privacy-safe projection.

## Privacy, security, and quality gates

- Update privacy disclosures before production collection; honor consent by
  region/platform and support export/deletion.
- Avoid sensitive free text, exact coordinates, raw media, authentication data,
  and payment data in analytics.
- Authenticate user-bound events but accept bounded anonymous lifecycle events
  with abuse controls.
- Rate-limit ingestion, cap batch/event sizes, validate enums and timestamps,
  and redact logs.
- Monitor ingest acceptance, quarantine rate, event lag, duplicates, missing
  identity/version dimensions, dashboard freshness, and cost drift.
- CI contract tests compare mobile/web event payloads to the shared schema.

## Delivery plan

1. **Foundation:** shared schema registry, ingestion idempotency, heartbeat,
   version-policy endpoint, privacy review.
2. **Mobile control:** SDK instrumentation, safe-point update UI, installation
   identity, offline queue and retry.
3. **Value measurement:** WPR and activation definitions, cohort jobs/dashboards,
   source attribution, internal-user filtering.
4. **Retention tests:** onboarding and intent-based reminder experiments.
5. **Monetization evidence:** AI cost/outcome metering, allowance experiment,
   then soft Pro conversion if gates pass.

## Acceptance criteria

- At least 98% of authenticated mobile events contain platform, semantic version,
  build, session, and user/installation identity.
- Duplicate delivery never increments an aggregate twice.
- Current, optional-update, and required-update clients follow the defined policy;
  unsupported clients cannot start new core/premium mutations after the safe point.
- Core actions cannot debit AI credits; premium work cannot run without an atomic
  entitlement or credit reservation.
- D1/D7/D14/D30 cohorts can be reproduced from raw accepted events.
- Every dashboard states its definition, exclusions, event-time/receive-time rule,
  timezone, and freshness.
- All implementation PRs link back to this specification and the formal model.

See [Formal Specification](/docs/roadmap/retention-ltv/formal-spec) and
[Verification Results](/docs/roadmap/retention-ltv/verification-results).
