---
sidebar_position: 3
title: "Instructor Outcomes: Formal Specification"
---

# Instructor Outcomes: Formal Specification

This specification protects attribution integrity, privacy, revocation, aggregation, and settlement. It complements the [Claimed formal specification](/docs/features/claimed/formal-spec) and does not restate Claimed's physical-evidence limitations.

## 1. Sets and state

Let `R` be riders, `I` instructors, `T` tutorials, `K` canonical tricks, `C` eligible Claimed claims, `O` outcomes, and `N` attribution nullifiers.

```text
Status     = {Draft, AwaitingClaim, Qualified, Active, Disputed, Revoked, Ineligible}
Visibility = {Private, AggregateOnly, Homies, Public}

claim[o]       ∈ C
rider[o]       ∈ R
targets[o]     ⊆ T × I × Credit
trick[o]       ∈ K
status[o]      ∈ Status
visibility[o]  ∈ Visibility
policy[o]      ∈ Nat
consent[o]     ∈ Nat
nullifier[o]   ∈ N
anchored[o]    ∈ BOOLEAN
settled[o]     ∈ BOOLEAN
```

Auxiliary sets are `UsedNullifiers`, `RevokedCommitments`, `PublishedAggregates`, and append-only `SettlementEntries`.

## 2. Qualification predicate

`Qualifiable(o)` is true exactly when:

1. its Claimed claim is eligible and not revoked;
2. every tutorial version was active before the eligible event;
3. every target maps to the trick or an approved prerequisite;
4. credit shares are positive, sum to 10,000 basis points, and target count is 1–3;
5. the rider gave the referenced consent;
6. the nullifier has not been used;
7. it is not prohibited self-attribution or a duplicate;
8. risk controls have not placed it in review.

## 3. Safety invariants

### I1 — No qualification without evidence

```text
status[o] ∈ {Qualified, Active, Disputed, Revoked} ⇒ ClaimWasEligibleAtIssuance(o)
```

### I2 — Attribution uniqueness

```text
∀ o1, o2 ∈ O : nullifier[o1] = nullifier[o2] ⇒ o1 = o2
```

### I3 — Consent before disclosure

```text
PublicRiderEdge(o) ⇒ visibility[o] ∈ {Homies, Public} ∧ ValidConsent(o)
```

Aggregate-only consent never permits publication of the rider-instructor edge.

### I4 — Revocation is terminal

```text
status[o] = Revoked ⇒ status'[o] = Revoked
```

Corrections create a replacement and, when necessary, compensating settlement entries.

### I5 — No invalid aggregate contribution

```text
Contributes(o, report) ⇒
  status[o] = Active ∧ visibility[o] ≠ Private ∧
  FraudDelayElapsed(o) ∧ ¬Disputed(o) ∧ ¬Revoked(o)
```

### I6 — Threshold privacy

```text
Published(report) ⇒ DistinctPairwiseRiders(report) ≥ 5
```

### I7 — Settlement conservation

```text
Σ targetCreditBps(o) = 10000
```

Every settlement entry references one outcome and settlement version. Revocation after payout appends a compensating entry rather than mutating history.

### I8 — Anchor independence

```text
¬anchored[o] ⇏ status[o] = Ineligible
```

Midnight availability never determines whether the landing evidence is valid.

### I9 — Minimal public state

Contract state contains only commitments, roots, nullifiers, attestation classes, revocations, and governance epochs—never user IDs, handles, video, URLs, GPS, views, or payment identity.

### I10 — Version immutability

Once qualified, claim, targets, trick, policy, and consent versions do not change. Corrections replace and revoke.

## 4. State transitions

```text
Create(o):
  PRE  o ∉ Outcomes
  POST status[o] = Draft

Confirm(o):
  PRE  status[o] = Draft ∧ ValidConsent(o)
  POST status[o] = AwaitingClaim

Qualify(o):
  PRE  status[o] = AwaitingClaim ∧ Qualifiable(o)
  POST status[o] = Qualified ∧ UsedNullifiers' = UsedNullifiers ∪ {nullifier[o]}

Reject(o):
  PRE  status[o] = AwaitingClaim ∧ ¬Qualifiable(o)
  POST status[o] = Ineligible

Anchor(o):
  PRE  status[o] = Qualified ∧ ValidIssuerAuthorization
  POST anchored[o] = TRUE ∧ status[o] = Active

ActivateWithoutAnchor(o):
  PRE  status[o] = Qualified ∧ AnchorDeferredByPolicy
  POST status[o] = Active ∧ anchored[o] = FALSE

Dispute(o):
  PRE  status[o] = Active
  POST status[o] = Disputed

Revoke(o):
  PRE  status[o] ∈ {Qualified, Active, Disputed}
  POST status[o] = Revoked ∧ commitment[o] ∈ RevokedCommitments'
```

## 5. TLA+ model skeleton

The implementation repository must contain a complete TLC-checkable model. This skeleton fixes expected variables and boundaries:

```tla
---------------- MODULE InstructorOutcomes ----------------
EXTENDS Naturals, FiniteSets, Sequences, TLC

CONSTANT Outcomes, MinCohort
VARIABLES status, consent, eligible, usedNullifiers,
          anchored, disputed, aggregateMembers, settled

vars == <<status, consent, eligible, usedNullifiers,
          anchored, disputed, aggregateMembers, settled>>

Qualify(o) ==
  /\ status[o] = "awaiting"
  /\ consent[o]
  /\ eligible[o]
  /\ nullifier[o] \notin usedNullifiers
  /\ status' = [status EXCEPT ![o] = "qualified"]
  /\ usedNullifiers' = usedNullifiers \cup {nullifier[o]}
  /\ UNCHANGED <<consent, eligible, anchored, disputed,
                  aggregateMembers, settled>>

Revoke(o) ==
  /\ status[o] \in {"qualified", "active", "disputed"}
  /\ status' = [status EXCEPT ![o] = "revoked"]
  /\ UNCHANGED <<consent, eligible, usedNullifiers, anchored,
                  disputed, aggregateMembers, settled>>

PublishAggregate(s) ==
  /\ Cardinality(s) >= MinCohort
  /\ \A o \in s : status[o] = "active" /\ ~disputed[o]
  /\ aggregateMembers' = aggregateMembers \cup s
  /\ UNCHANGED <<status, consent, eligible, usedNullifiers,
                  anchored, disputed, settled>>

NoQualificationWithoutConsent ==
  \A o \in Outcomes : status[o] \in {"qualified", "active"} => consent[o]

Spec == Init /\ [][Next]_vars
=============================================================
```

The complete model represents compensating aggregate and settlement deltas so revocation never requires deletion of history.

## 6. Liveness properties

Under weak fairness and available dependencies:

- Every awaiting outcome eventually becomes qualified, ineligible, or held for review.
- Every qualified outcome eventually anchors or exposes a deferred/failed state.
- Every dispute eventually resolves to active or revoked.
- Every payout-eligible outcome receives exactly one decision per settlement version.
- Every revocation eventually leaves all future aggregates and settlements through a compensating delta.

These require dead-letter handling, alerts, and replay tooling.

## 7. Circuit obligations

1. Domain-separate claim, outcome, attribution-nullifier, presentation-nullifier, and revocation hashes.
2. Assert membership against an allowed current or historic root.
3. Assert the commitment opens to witness-supplied private fields.
4. Assert the attestation class satisfies the requested statement.
5. Assert the commitment is not revoked.
6. Reveal only explicitly selected public outputs.
7. Use fresh or verifier-scoped presentation identifiers.
8. Authenticate issuer/governance operations with hash-based keys and epochs.
9. Audit every witness-derived value flowing to ledger state for required explicit disclosure.

## 8. Threat model

| Threat | Required defense |
|---|---|
| Friends farm rewards | Device/account risk, self-dealing checks, delay, thresholds, review |
| Creator buys false attribution | Prohibited incentives, anomaly detection, audit |
| One landing creates many outcomes | Claim/attribution nullifier uniqueness and target cap |
| Instructor infers private learners | Thresholds, pairwise IDs, no private-edge API |
| Tutorial changes after earning trust | Immutable versions and content hashes |
| False coach/pro claim | Evidence, expiry, dispute, visible state |
| Issuer key compromised | Separate roles, rotation epoch, HSM/secret manager, revocation |
| Public proof tracks a rider | One-time or verifier-scoped presentations |
| Midnight unavailable | Off-chain qualification continues; anchors queue |
| Unsafe content optimized for outcomes | Safety reports, editorial guardrails, payout freeze |

## 9. Verification plan

### Model checking

Check three outcomes, two riders, two instructors, two tutorials; duplicate nullifiers; qualify/anchor/revoke interleavings; disputes before and after publication; revocation before and after settlement; cohort sizes around the threshold; and Midnight retry.

### Property-based tests

- Reject target splits that are zero, negative, over three, or do not sum to 10,000.
- Reordered/retried requests produce one outcome and one settlement decision.
- Aggregate-only never exposes a rider edge.
- Event-log recomputation matches published reports byte-for-byte.
- A revoked outcome never enters a future positive delta.

### Contract and integration tests

- Invalid issuer, reused nullifier, invalid path, revoked commitment, stale epoch, and over-disclosure fail.
- Two outcomes by one rider are unlinkable from public chain data.
- A valid proof remains verifiable after profile deletion if the rider retains its secret.
- Midnight downtime does not block Claimed verification, profiles, or attribution capture.

## 10. What this specification does not claim

- It does not prove a physical trick happened; it relies on Claimed evidence.
- It does not prove a tutorial caused a landing.
- It does not make instructor credentials globally authoritative.
- It does not make rewards fraud-free.
- It does not require public rider identity or a rider-held wallet.
- It does not define “mastered” universally; mastery is a versioned policy built from evidence and repetition.

