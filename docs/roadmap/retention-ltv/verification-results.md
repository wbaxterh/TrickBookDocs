---
title: Verification Results
sidebar_position: 3
---

# Retention/LTV Verification Results

Status: **checked 2026-09-23 — all safety properties hold in the bounded model;
all four reachability probes produced their exact expected counterexample.**

## Expected verification matrix

| Configuration | Purpose | Required result |
|---|---|---|
| `Model.cfg` | All safety invariants | ✅ 9,239,617 generated / 1,796,432 distinct / depth 15 |
| `ReachRequired.cfg` | Required update is reachable | ✅ exact violation; 2 states / depth 2 |
| `ReachOptional.cfg` | Optional update is reachable | ✅ exact violation; 4 states / depth 3 |
| `ReachCore.cfg` | Accepted free core action is reachable | ✅ exact violation; 516 generated / depth 6 |
| `ReachPremium.cfg` | Accepted authorized premium action is reachable | ✅ exact violation; 1,269 generated / depth 6 |

The runner treats parse errors, timeouts, different invariant failures, and
unexpected passes as failures. Logs are written to
`formal/retention-ltv/out/*.log` and remain untracked.

## Implementation obligations derived from the model

Passing the model only supports the design if implementation preserves these
refinement points:

1. Compare ordered build/version values on the server; do not compare semantic
   version strings lexicographically.
2. Once a required policy is applied at a safe point, block all new mutations,
   not merely navigation to selected screens.
3. Use a unique `eventId` index and atomic upsert/insert behavior before any
   aggregate consumes the event.
4. Reserve/debit premium usage atomically on the server with an idempotency key.
5. Keep core-action code paths independent of the AI wallet.
6. Treat subscription webhooks as idempotent entitlement facts; analytics events
   cannot grant access.
7. Derive cohorts only from accepted events and publish metric definitions.

## Required implementation verification

Before launch, add contract tests for every event producer, concurrency tests for
duplicate ingestion and wallet debits, endpoint tests for all version boundaries,
mobile UI tests for optional/required/safe-point behavior, and end-to-end tests
using real non-admin accounts. Production canaries must confirm dashboard counts
against raw events before product decisions use them.

## Evidence record

| Evidence | Value |
|---|---|
| Run date | 2026-09-23 |
| Model checker | TLC2 2.19, TLA+ tools v1.7.4; jar SHA-256 verified |
| Runtime | Eclipse Temurin OpenJDK 21.0.12.1, Windows x86_64, 8 workers |
| Command | `npm run verify:retention` |
| Spec SHA-256 | `3eb2ed25d15d045725ed1196269828abc38982fe8852c2ea6e3e510c2280dc96` |
| Concatenated config SHA-256 | `e38023432a116b1dcd51ecc295789c1f410e59b4ef759097b2af4638bec58a6d` |
| Logs | `formal/retention-ltv/out/*.log` locally (ignored generated evidence) |

The main configuration exhausted its finite state graph with no error. That is
strong evidence for the specified control-plane design within the documented
bounds; it remains neither an unbounded mathematical proof nor verification of
future production code.
