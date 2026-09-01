---
sidebar_position: 4
title: "ADR-004: Midnight for Sealed Claims"
---

# ADR-004: Seal Trick Claims on Midnight with a Custodial Backend Wallet

| Field | Value |
|-------|-------|
| **Status** | Proposed |
| **Date** | September 2026 |
| **Deciders** | Wes Huber |
| **Supersedes** | None |
| **Related** | [Sealed Claims PRD](/docs/features/sealed-claims) · [Architecture](/docs/features/sealed-claims/architecture) · [Formal spec](/docs/features/sealed-claims/formal-spec) |

## Context

Riders want to establish priority for a trick ("I did it first, on this date") without publishing the footage, because footage is saved for video parts. TrickBook's spot trick history registry has an admin-only `verified` flag and no way to express a claim about footage that is not yet public.

The requirement is a **commitment with selective disclosure**: seal a hash and metadata at a time the rider does not control, keep everything private, and later prove statements about the sealed data (it existed by block B, it belongs to me, it has not been claimed twice) without revealing the data. Priority disputes and embargoed footage are the two skate-culture facts that make this worth building.

TrickBook's constraints: 315 registered users who will not install a crypto wallet; an Express and MongoDB backend on one EC2 box; an Expo mobile app with no video capture today; a proprietary codebase. Wes also has a working Midnight contract, `vouched`, that implements the exact primitive needed (commitment Merkle tree, nullifier set, membership proof, explicit disclosure), passing end to end on a local devnet with a custodial demo backend.

## Options considered

| Option | Timestamp | Hides contents | Proves properties without reveal | One reveal per claim | Rider friction | Notes |
|--------|-----------|----------------|----------------------------------|----------------------|----------------|-------|
| A. Signed record in TrickBook's database | TrickBook's clock | Yes | No | Policy only | None | Proves nothing to anyone who does not trust TrickBook; TrickBook holds the data it attests |
| B. Hash anchored on Bitcoin (OpenTimestamps) or in Cardano transaction metadata | Chain | Hash only | No | No | None if TrickBook anchors | Public account links every claim; no way to prove "sealed before B for trick T" without publishing the pre-image; no nullifier |
| C. Midnight, riders hold wallets (Lace) | Chain | Yes | Yes | Yes | High: wallet install, seed phrase, DUST | Correct trust model, wrong onboarding for skaters at a spot |
| D. Midnight, TrickBook custodial wallet and proving (chosen) | Chain | Yes | Yes | Yes | None | Custodial trust in TrickBook for v1; the contract itself does not care who submits |
| E. Wait for on-device Midnight proving on mobile | Chain | Yes | Yes | Yes | Low | Not shippable now; it is the v2 track from D |

## Decision

**Option D.** Seal claims on Midnight using the `vouched` contract pattern, with TrickBook's backend holding the app wallet and generating proofs. Specifically:

1. **Contract.** Historic Merkle tree of commitments, nullifier set, `reveal` and `provePriority` membership circuits, `attest` gated by a sealed verifier key hash. Ported from `vouched.compact` with a per-claim salt added for unlinkability.
2. **Custodial v1, disclosed.** The rider secret is generated on the device and stored in the keychain; it is relayed to the backend for proof generation over TLS and encrypted at rest. The settings screen says so in plain language. On-device proving is the v2 track.
3. **Priority by chain time.** Priority proofs are membership proofs under a historic root; the block that root belongs to is the timestamp. The device clock is evidence, never the clock.
4. **Evidence stays off-chain.** The verification pipeline's outputs live in MongoDB; only a tier bitmask is anchored on-chain by the verifier.
5. **Open-source module.** Contract, sealing service, and a minimal demo ship in a public repository; TrickBook integrates it. This satisfies the Midnight example-dApp submission rules and keeps TrickBook proprietary.
6. **Preprod first.** Launch on preprod through the integration milestone, move to mainnet with a re-seal migration once DUST cost per claim is measured.

## Consequences

**Positive**

- The primitive is the right one: hiding, binding, single use, and selective disclosure are properties of the contract, not of TrickBook's policy.
- Zero onboarding friction. A rider taps Seal; nothing about Midnight is visible.
- Most of the contract, witnesses, API layer, and the custodial server pattern already exist and pass end to end.
- The historic-root construction gives a timestamp that TrickBook cannot forge even as custodian: the backend can refuse to seal, but it cannot make a seal look older than the block it landed in.

**Negative**

- Custodial trust in v1. TrickBook could seal or reveal on a rider's behalf. Mitigated by disclosure, audit logs, encrypted secrets, and the v2 plan; not eliminated.
- New operational surface: a funded wallet, a proof server container, a queue, DUST monitoring.
- New native work in the mobile app (video capture, secure storage, device attestation) that has nothing to do with Midnight but is required for the provenance tier to mean anything.
- Proof latency (tens of seconds) shapes the UX: sealing must be asynchronous and honest about its state.

**Neutral**

- App Store review: the feature is timestamping with no token, purchase, or wallet UI. Apple's guidelines permit that; the submission notes should say so up front.
- Tree depth, proving cost, and historic-root retention must be measured and confirmed against current Midnight documentation before the contract is final (listed as M1 exit criteria in the PRD).

## Follow-ups

- Confirm `HistoricMerkleTree` root retention semantics against the current ledger ADT documentation; if bounded, add a checkpoint circuit.
- Decide whether `attest` should require an on-chain membership proof for the target commitment (invariant I8 in the formal spec) or stay service-enforced in v1.
- Add a round counter to `attest` before mainnet so verifier transactions are unlinkable.
- Evaluate Play Integrity and App Attest integration paths in Expo (config plugin versus bare module).
- Revisit this ADR when on-device proving becomes practical on iOS and Android; that is the trigger to retire the custodial boundary.
