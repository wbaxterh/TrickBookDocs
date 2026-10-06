---
sidebar_position: 2
title: "Progress: September 24 to October 6, 2026"
---

# Platform progress, September 24 to October 6, 2026

Status: **Shipped and live** · Written 2026-10-06

A dated record of the tech-debt sprint and the two production fixes that followed it, so the roadmap pages stop describing a July snapshot. Each row names the repository, the pull requests, and what proves it is live.

## What shipped

| Area | Repo | PRs | Live proof |
|---|---|---|---|
| Apple sign-in resolves identity from the verified token only; avatar upload requires auth and targets the caller | TB-Backend | #65, #66 | API restart 2026-09-25 |
| `GET /health` liveness probe (database ping, 200 or 503, no secrets in the body) | TB-Backend | #65, #66 | `/health` returns `db: ok` |
| Schema layer: a `$jsonSchema` for every collection the code touches, applied as validators in warn mode on boot, with a drift-guard test and `schema:report` | TB-Backend | #65, #66 | boot log line `[schema] validators warn/moderate` |
| Native projects generated from `app.config.js` (CNG); the build fails without `GOOGLE_MAPS_API_KEY`; jest-expo unit runner | TrickBookFrontend | #25 | `git ls-files ios android` is empty |
| Bootstrap UI kit removed; header and language menu on Radix; Jest unit runner ([ADR-006](/docs/architecture/adrs/web-ui-kit-consolidation)) | TrickBookWebsite | #87, #88 | no bootstrap stylesheet in the page HTML |
| Host identifiers removed from this site; feedback log anonymized | TrickBookDocs | #23 | `llms-full.txt` carries none |
| Google and Apple web sign-in: `www` redirects to the apex so NextAuth's state cookie meets its callback (see [Canonical host](/docs/deployment/web-app#canonical-host)) | TrickBookWebsite | #89, #88 | `www` answers 308 |
| Stripe webhook verified on the raw body, idempotent deliveries, `verify-session` and `reconcile`, billing page confirms with the server | TB-Backend, TrickBookWebsite | #75, #76, #103, #104 | forged signature gets 400; new routes answer 401 unauthenticated |

## What the review found, 2026-10-01

Three read-only reviews compared the website, the API and this site. The ranked list, with the first item now done:

1. **Stripe webhook** (done 2026-10-06). The JSON parser ran before the webhook's raw-body parser, so no delivery could verify and no web checkout could activate Plus.
2. **Security batch**, each under two hours: finish the credential rotations from the September review, admin-gate media-library writes, require conversation membership before a DM socket joins a room, drop email from the public feed projection and the public email lookup, delete the public debug-token route.
3. **Make the retention dashboard trustworthy**: emit the missing meaningful events (landed trick, signup), fix the calendar event name, use weekly windows at the current scale, add Sentry.
4. **Server-render spot and Trickipedia detail pages** and list them in the sitemap; fix the `/about` and `/blog` hydration errors and the `/trickipedia` 404.
5. **Docs truth pass**: one metric set, one price, no stale status rows.

Not yet: RevenueCat and mobile IAP, Tony, unlockables, Claimed, the marketplace.

## Companion knowledge layer, as of 2026-10-06

- Vector retrieval (`kaori-rag/`) is live: hybrid keyword and Atlas Vector Search over Trickipedia, films, spots, events and riders, refreshed nightly by the `kaori-rag-indexer` PM2 cron. Retrieval runs on every turn and is pushed into the system prompt.
- The Mongo relationship graph (`companion-graph/`) is live and rebuilt nightly; it backs the film, spot, similar-trick, learning-path and next-trick tools. The registry has 15 tools.
- The Neo4j progression projection is built and disabled by default. No client calls its route.
- Known gaps: the event and rider document adapters read field names older than the current ingest, so those two source types index thin; the evaluation set has five queries; nothing records whether a retrieval was used in an answer.

Details and the next steps are in [Companion Intelligence Progress](/docs/roadmap/companions-intelligence-progress).

## Still open from the September review

Complete the credential rotations, add the Maps key as an EAS environment variable before the next mobile build, enable secret scanning and Dependabot on the three code repositories, and add the token check on the voice WebSocket upgrade (session, per-IP and message caps shipped 2026-09-30).
