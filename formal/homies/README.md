# Homies connection lifecycle — TLA+ verification

Executable formal models of TrickBook's Homies (mutual connection) feature,
checked with TLC. The rider-facing question: **can the system consider us
homies on your account but strangers on mine?**

Docs: `/docs/features/homies/formal-spec` (model walkthrough) and
`/docs/features/homies/verification-results` (actual TLC results).

## What is modeled

The authoritative friendship/request state in MongoDB and the four HTTP
handlers that mutate it, inspected at **TB-Backend `master` commit
`4e1300a96183f20a809f5cc687df7b8661669880`** (2026-09-11):

| Model action | Backend operation | Source |
|---|---|---|
| `BaseSend` pc1 (validate) | `findOne` on target's doc: self-guard, already-homies, already-requested | `routes/users.js:483-507` |
| `BaseSend` pc2 | `updateOne` target: `$push homieRequests.received {from, sentAt}` | `routes/users.js:510` |
| `BaseSend` pc3 | `updateOne` sender: `$push homieRequests.sent` | `routes/users.js:523` |
| `BaseAccept` pc1 (validate) | `findOne` on acceptor's doc requiring the pending request | `routes/users.js:601` |
| `BaseAccept` pc2 | `updateOne` acceptor: `$push homies` + `$pull received` (one doc — atomic together) | `routes/users.js:611` |
| `BaseAccept` pc3 | `updateOne` requester: `$push homies` + `$pull sent` | `routes/users.js:619` |
| `BaseReject` pc1/pc2 | two `$pull` updateOnes (no validation read) | `routes/users.js:645,653` |
| `BaseRemove` pc1/pc2 | two `$pull` updateOnes (no validation read) | `routes/users.js:757,762` |
| `Crash` | handler dies between committed writes; no compensation exists | (absence of any) |
| `Atomic*` actions | **proposed** corrected design: one transaction per handler with conditional-write guards and `$addToSet`; `PurgeOnRemove` additionally clears pending pair requests on removal | not implemented in backend |

Faithfulness notes:

- One MongoDB `updateOne` on one document = one atomic model step
  ([single-document atomicity](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/)).
  A handler's separate `updateOne` calls are separate steps that interleave
  with every other in-flight handler. Nothing in the homies code uses
  transactions, conditional filters beyond `_id`, request IDs, or recovery.
- Arrays are modeled as multiplicity counts (`0..MaxMult`) because the code
  uses `$push`: duplicates are representable, not excluded by abstraction.
  `$pull` removes all matching elements → sets the count to 0.
- Ghost state (`gen`, `reqGen`, `ghostWrite`, `resurrect`) is
  specification-only bookkeeping for the stale-authorization properties;
  the modeled handlers never read it.

## Assumptions and bounds (all deliberate)

- **Out of scope:** messaging/notifications/feeds, the `network` privacy
  flag (both riders modeled as accepting requests), bot auto-accept
  (`users.js:533`), client UI refresh. Liveness is not checked — safety only.
- **Operation budget:** fixed slots (2 send, 2 accept, 1 reject, 2 remove).
  A client retry after a lost response is just another slot. Terminal
  states are expected, hence `-deadlock`.
- **`MaxMult = 2`**: array cells saturate at 2 copies; detecting a duplicate
  only needs multiplicity 2. Histories needing triple-pushes are not explored.
- **Riders:** 2 (default) / 3 (`Corrected_Full_3Riders`). Self-targeted
  accept/reject/remove are excluded (they can only touch `homies[u][u]`
  cells, which no reachable behavior makes positive — send's self-guard is
  modeled and verified via `NoSelfHomies`).
- `gen` saturates at the number of remove slots; `reqGen` keeps only the
  latest stamp per cell (duplicate concurrent requests share it — this can
  under-report, never fabricate, a resurrection).

## Properties

See `Homies.tla` invariant section. Baseline-expected-fail configs each pin
ONE invariant so TLC preserves that specific counterexample; `Reach_*`
configs are deliberately-violated probes proving the model is not vacuous
(connection, severing removal, and re-connection are all reachable).

## Run it

```bash
bash formal/homies/tools/fetch-tla2tools.sh   # pinned v1.7.4, sha256-verified
npm run verify:homies                          # asserts every expected outcome
```

Requires Java 11+ (`TLA_JAVA=/path/to/java` to override). Full TLC output,
including counterexample traces, lands in `formal/homies/out/*.log`
(gitignored; uploaded as artifacts in CI).

## Keeping it honest

This repo's CI cannot see TB-Backend changes. The model matches the
revision above; any backend change to `routes/users.js` homies handlers
should trigger a review of this model (grep for `homie` in the diff).
