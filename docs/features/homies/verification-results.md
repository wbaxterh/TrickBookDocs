---
sidebar_position: 3
title: Verification Results
---

# Homies: Verification Results

**Status: checked — counterexamples found against the as-deployed design;
a corrected design was modeled and passes all properties.** Every number on
this page comes from actual TLC runs; nothing is estimated or extrapolated.

:::warning[What this is and is not]
This is model checking of a **finite model** of the Homies lifecycle
(2–3 riders, a bounded operation budget, documented reductions) against the
backend revision below. It is **not** a proof that TrickBook's production
code is correct, and the corrected design exists **only as a model** — no
backend fix has been implemented or deployed.
:::

## Evidence record

| | |
|---|---|
| Backend inspected | TB-Backend `master` @ `4e1300a96183f20a809f5cc687df7b8661669880`, `routes/users.js` (2026‑09‑11) |
| Model checker | TLC2 Version 2.19 of 08 August 2024 (tla2tools **v1.7.4**, sha256-pinned by `formal/homies/tools/fetch-tla2tools.sh`) |
| Runtime | OpenJDK 21 (Homebrew, macOS aarch64), 8 workers |
| Run date | 2026‑09‑11 |
| Spec / config hashes | `Homies.tla` sha256 `4edc7b3116cc9b17…`; all `.cfg` concatenated `683db8d29b9b9d72…` |
| Command | `npm run verify:homies` (runs `node formal/homies/run.js`; exact TLC flags recorded in each log header) |
| Logs & traces | `formal/homies/out/*.log` locally; uploaded as the `homies-tlc-logs` artifact by the `verify-homies` CI workflow |

The runner asserts each configuration's expected outcome: expected-pass runs
must complete with no error, expected-fail runs must report the **exact**
named invariant — a parse error, timeout, or different violation fails the
whole suite. Final suite output: `All runs matched their expected outcomes.`

## Results

### Baseline — the system as deployed

| Configuration | Checked | Result |
|---|---|---|
| `Baseline_Mutual` | `MutualHomies` | ❌ **violated** — 7-state trace |
| `Baseline_QuiescentMutual_NoCrash` | `QuiescentMutualHomies`, crashes **disabled** | ❌ **violated** — 12-state trace (no crash required) |
| `Baseline_QuiescentMutual_Crash` | `QuiescentMutualHomies`, crashes enabled | ❌ **violated** — 9-state trace (partial write persists) |
| `Baseline_GhostAcceptance` | `NoGhostAcceptance` | ❌ **violated** — 9-state trace |
| `Baseline_DuplicateHomies` | `NoDuplicateHomies` | ❌ **violated** — 10-state trace |
| `Baseline_DuplicateRequests` | `NoDuplicateRequests` | ❌ **violated** — 7-state trace |
| `Baseline_Resurrect` | `NoResurrectedConnection` | ❌ **violated** — 10-state trace |
| `Baseline_RequestSymmetry` | `QuiescentRequestSymmetry` | ❌ **violated** — 5-state trace |
| `Baseline_Holds` | `TypeOK`, `NoSelfHomies` — exhaustive | ✅ **hold** — 196,654,959 generated / 26,923,068 distinct / depth 26 |

Every ❌ above is a defect *class* in the deployed write path, witnessed by a
concrete trace. Every trace was independently reproduced against the real
route handlers by the backend test suite (below). `NoSelfHomies` passing is
an honest positive: the self-guard at `users.js:483` works, verified across
the entire bounded state space including crashes.

### Corrected designs — modeled only, not implemented

| Configuration | Checked | Result |
|---|---|---|
| `Corrected_Tx` (transaction + conditional writes) | all invariants **except** `NoResurrectedConnection` | ✅ 2,247,385 generated / 261,572 distinct / depth 15 |
| `Corrected_Tx_Resurrect` (same design) | `NoResurrectedConnection` | ❌ **still violated** — 11-state crossed-request trace |
| `Corrected_Full` (+ purge pair requests on remove) | **all** invariants | ✅ 2,244,337 generated / 260,784 distinct / depth 15 |
| `Corrected_Full_3Riders` (3 riders) | **all** invariants | ✅ 245,395,279 generated / 18,848,685 distinct / depth 15 |

The headline: **wrapping each handler in a transaction is not enough.**
It fixes mutuality, duplicates, ghost acceptance, and request symmetry — and
TLC then immediately finds that a *stale crossed request* still resurrects a
removed friendship. The additional rule "removing a homie also deletes any
pending requests between the pair" is required, and with it all seven
properties hold in both the 2-rider and 3-rider models.

### Non-vacuity probes

| Configuration | Deliberately violated probe | Meaning |
|---|---|---|
| `Reach_Connected` | `ReachNeverConnected` | ❌ violated ⇒ a full send→accept flow really completes in the strictest model |
| `Reach_Reconnect` | `ReachNoReconnect` | ❌ violated ⇒ after a removal, a **new** request + acceptance really can reconnect the pair (removal is not a permanent ban), even with request-purging on remove |

These two runs exist to prove the passing models aren't passing vacuously.
One property-by-construction caveat is worth stating: in the corrected
model, connection inserts are modeled with `$addToSet` semantics, so
`NoDuplicateHomies` there holds partly by that operator's definition — the
substantive verification of it is the baseline failure plus MongoDB's
documented `$addToSet` behavior, not the corrected model run.

## The counterexamples, in plain English

### 1. One-sided friendship — the original question, answered

`Baseline_Mutual`, 7 states: rider **a** sends a homie request to **b**;
**b** taps accept; the server validates it and commits the **first** write
(`users.js:611`) — b's document now lists a as a homie. Until the second
write (`users.js:619`) commits, the committed database says **b is homies
with a, but a is a stranger to b.** `GET /users/homie-status` reads only
your own document, so both riders can see contradictory answers at the same
moment. So: *yes — the system can consider us homies on your account and
strangers on mine.* Without a crash it self-heals when the second write
lands; with a crash between the writes (`Baseline_QuiescentMutual_Crash`)
the one-sided friendship is **permanent** — there is no repair mechanism.

### 2. Removal loses a race it should never lose

`Baseline_QuiescentMutual_NoCrash`, 12 states, **no crash involved**:
**a** accepts b's request at the same time **b** removes a. The remove's
two `$pull`s land between the accept's two `$push`es. Everything runs to
completion — and the final, quiet state is still one-sided: one rider
permanently lists the other, who lists nothing. The backend test suite
reproduces this exact interleaving against the real handlers
(`B->false, A->true`).

### 3. Stale acceptance resurrects a severed friendship

`Baseline_Resurrect`, 10 states: an accept is validated, then a removal
severs the pair, then the accept's remaining write lands anyway —
reconnecting what was just removed. The validation (`users.js:601`) and the
writes are separate steps with nothing re-checked at write time.

### 4. Transactions alone don't fix it — the crossed-request trace

`Corrected_Tx_Resurrect`, 11 states, in the *improved* design where every
handler is already atomic: **a** and **b** send each other crossed requests;
**a** accepts one — they're homies; the *other* request stays pending in
someone's inbox; **a** removes **b**; **b** simply accepts a's leftover
pre-friendship request — **and they're homies again, without a doing
anything.** Rider a's removal was silently undone by a request a sent
before the friendship even started. This is why the corrected design must
also purge pending pair requests on removal, and why "just add a
transaction" would have shipped a false sense of safety.

### 5. Duplicates and stuck requests

Double-tapping accept (or a client retry racing itself) yields
`homies: [a, a]` (`$push` + non-atomic validation); double-tapping send
yields two identical pending requests; a crash between send's two writes
leaves a request the recipient sees but the sender can't cancel. All three
are witnessed by TLC traces and reproduced by the backend tests.

## Reproduced against the real backend

`TB-Backend/test/homies-lifecycle.test.js` runs the **actual route
handlers** (`routes/users.js`) in-process against an isolated in-memory
collection that faithfully implements the operators the handlers use
(`$push` duplicates, `$pull`-all, per-`updateOne` atomicity):

- **4 pinning tests (pass today):** send-retry after committed success is
  rejected; acceptance with no pending request is 404; remove is
  idempotent; self-request is rejected.
- **6 `todo` reproductions (fail today, by design):** one per TLC
  counterexample above — partial-write asymmetry, accept/remove race
  asymmetry, double-accept duplicates, double-send duplicates, stale
  crossed-request resurrection (fully sequential — no race needed), and
  crashed-send request asymmetry. Each is marked `{ todo: true }` so the
  suite stays green; **remove the `todo` flags when the corrected write
  path ships** — they are the regression tests for the fix.

## Remaining implementation work (not done here)

1. **Backend fix** (`routes/users.js`): per handler, one MongoDB
   transaction (the codebase already uses `withTransaction` in the rider
   importer) whose first update carries the validation in its filter
   (e.g. accept: `{_id: me, 'homieRequests.received.from': requester}` with
   abort on `modifiedCount === 0`), `$addToSet` instead of `$push`, and —
   per counterexample 4 — remove must also `$pull` both directions of
   pending requests between the pair. Assumes a replica set (transactions
   require one; production runs MongoDB Atlas).
2. **Repair pass** for any existing one-sided rows in production data
   (read-only audit first; same guarded-script pattern as other data fixes).
3. Flip the six `todo` regression tests to enforcing once the fix lands.
4. The model's request-lifetime rule (`NoResurrectedConnection`) is a
   **proposed** product decision — confirm it before implementing.

## Limits

- Finite bounds: 2–3 riders, 2 send / 2 accept / 1 reject / 2 remove
  operations per run, array multiplicities capped at 2, safety only (no
  liveness). Bounds and reductions are documented in `formal/homies/README.md`.
- The models cover the four lifecycle handlers, not adjacent features
  (Kaori auto-add at signup, bot auto-accept, account deletion) — account
  deletion in particular never cleans up `homies` arrays and deserves the
  same treatment later.
- This repo's CI (`verify-homies` workflow) re-checks the models when they
  change; it **cannot** detect TB-Backend changes. Any change to the homies
  handlers in `routes/users.js` must trigger a manual model review against
  the pinned revision above.

## The 30-second rider version

> We asked a simple question: can TrickBook ever think you're my homie while
> I think we're strangers? Instead of guessing, we wrote down the rules of
> the homies system in math and had a checker try **millions of orderings**
> of taps, retries, and crashes — stuff no amount of manual testing covers.
> Answer: yes, it can happen — your accept and my remove can interleave so
> we end up permanently out of sync, and there's even a way a friendship you
> removed comes back because of an old leftover request. We also checked the
> fix: make each action all-or-nothing and clear old requests when you
> remove someone — the checker then finds no way to break it, across
> hundreds of millions of situations. The fix is designed and tested,
> next step is shipping it.

*(Everything in that paragraph matches the results above: the failures are
real counterexamples from the as-deployed model, and the "no way to break
it" claim is scoped to the checked configurations.)*
