---
sidebar_position: 1
title: "Instructor Outcomes: PRD"
---

# Instructor Outcomes: Product Requirements

*Turn tutorials into measurable progression, without turning learning into an unverifiable popularity contest.*

| Field | Value |
|---|---|
| **Status** | Draft for review |
| **Owner** | Wes Huber |
| **Date** | September 2026 |
| **Working name** | Instructor Outcomes. Rider-facing copy uses “Learned with”; instructor-facing copy uses “Riders helped.” |
| **Related** | [Architecture](/docs/features/instructor-outcomes/architecture) · [Formal spec](/docs/features/instructor-outcomes/formal-spec) · [Claimed PRD](/docs/features/claimed) · [Verification pipeline](/docs/features/claimed/verification-pipeline) |

:::info[One paragraph]
Instructor Outcomes connects a rider's verified progression to the tutorial or instructor that helped them. A rider can select “Learned with [creator]” when recording a landed trick. Once the underlying Claimed evidence reaches an eligible verification tier, TrickBook issues a consented outcome attestation. The rider receives a mastery entry on an expanded progression profile; the instructor receives an aggregated, auditable “riders helped” outcome on an expanded instructor profile. Midnight anchors private commitments and proves valid attribution without publishing rider identity, raw footage, viewing history, or coaching notes. NIGHT is not the credential database or a required user payment: TrickBook holds NIGHT to generate/delegate DUST for contract execution.
:::

## 1. Product thesis

Views measure distribution. Likes measure reaction. Neither measures whether instruction worked.

TrickBook can create a stronger unit of value for action-sports education: a **verified learning outcome**. A useful tutorial can remain discoverable on the trick it teaches, guide a rider through prerequisites, and later receive credit when that rider lands the trick. This gives each side a reason to participate:

- **Riders** get credible progression history, better recommendations, and recognition for what they learned.
- **Instructors and creators** get durable attribution, proof of teaching impact, community tools, and a basis for revenue.
- **TrickBook** gets a progression graph informed by outcomes rather than watch time alone.

The product must not claim that a creator caused a landing merely because a rider watched a video. Attribution is rider-selected, consented, and attached only after an eligible mastery claim. The public statement is “Wes learned with Alex's tutorial,” not “Alex exclusively caused Wes to land.”

## 2. Relationship to Claimed and Midnight

[Claimed](/docs/features/claimed) remains the system of record for capture provenance, evidence tiers, private sealing, reveal, and priority. Instructor Outcomes adds a second object: an attribution from one eligible claim to one or more learning resources.

- The **verification pipeline** evaluates evidence that the claimed trick and landing match the clip.
- The **rider** states which tutorial or instructor materially helped.
- The **instructor** opts into a public instructor profile and may dispute false or abusive attribution.
- **Midnight** proves that a valid, non-revoked outcome attestation exists under the contract rules. It does not inspect a video, prove causality, or decide whether instruction was good.
- **NIGHT** generates the DUST used for execution. Riders and instructors need no NIGHT, DUST, wallet, or blockchain knowledge in v1.

## 3. Users and jobs to be done

| User | Job | Product outcome |
|---|---|---|
| Learning rider | Remember what helped me and show credible progress | Mastery entry with evidence tier and optional “Learned with” credit |
| Private rider | Receive progression benefits without publishing identity or clips | Private credential; aggregate contribution only with explicit consent |
| Micro-influencer | Show that my tutorials produce real outcomes | Instructor profile with qualified riders helped, tricks taught, and challenge conversions |
| Coach | Organize instruction and recognize students | Programs, progression paths, cohort outcomes, and coach attestations |
| Filmer/publisher | Receive accurate content credit | Separate instructor, creator, filmer, and publisher roles |
| Brand/event partner | Sponsor participation and outcomes, not impressions alone | Campaign report with deduplicated qualified outcomes and fraud flags |
| Moderator | Resolve impersonation, attribution, and verification disputes | Evidence-aware review and reversible attestations |

## 4. Profile model

There is one TrickBook account and one profile shell. Capabilities are added through roles; users do not create separate rider and creator accounts.

### Rider profile

- Sport, stance, preferred terrain, and home region at user-selected precision
- Progression summary: learning, landed, and mastered counts
- Mastery timeline with public, homies-only, or private visibility per entry
- Evidence label from Claimed: self-reported, captured, or Verified
- “Learned with” attribution when profile and entry visibility permit it
- Goals, active challenges, saved tutorials, and progression paths
- No public failed-attempt count, precise location history, wallet address, or private coaching notes

### Instructor profile

- Display name, bio, sports, disciplines, teaching languages, regions, and links
- Role labels: creator, coach, professional athlete, filmer, publisher, organization
- Credential claims with state: unverified, evidence submitted, verified, expired, or disputed
- Tutorial library mapped to canonical TrickBook trick IDs
- Programs, challenges, prerequisites, safety notes, and audience level
- Outcome summary: qualified riders helped, verified masteries influenced, repeat learners, and completion rate only where the denominator is meaningful
- Attribution and payout settings
- Report/dispute controls and a transparent explanation of each metric

### Identity and role rules

1. “Creator” is self-selected. “Verified coach,” “professional,” and organization affiliation require evidence and review.
2. Legal identity is private unless the user publishes it.
3. Profiles may hold several roles, but credits keep instructor, performer, filmer, publisher, and rights holder separate.
4. Counts are deduplicated by rider, tutorial, trick, and attribution version according to the metric definition.
5. Public profile numbers are aggregates. No instructor receives a list of private riders.

## 5. Core experience

### Publish instruction

1. An instructor claims or creates a profile.
2. They submit a hosted video or authorize an existing TrickBook tutorial record.
3. They identify the canonical trick, intended level, prerequisites, safety notes, language, and content roles.
4. TrickBook verifies ownership/permission, attribution, availability, and any professional credential claims.
5. The tutorial receives a stable `tutorialId`, content hash/version, and public attribution record.

### Learn and land

1. A rider opens a tutorial from a trick page, instructor profile, program, or challenge.
2. TrickBook records a private learning interaction; viewing alone never creates public credit.
3. When recording or attaching a landing, the rider can choose up to three resources under “What helped?”
4. The claim runs through Claimed verification.
5. Once eligible, the rider confirms the attribution and its visibility.
6. TrickBook creates an outcome attestation and updates aggregates after the anti-fraud delay.

### Display outcomes

- Rider: “Kickflip · Verified · Learned with Alex Rivera.”
- Instructor: “Helped 126 riders progress · 84 Verified landings · strongest at Kickflip and Frontside 180.”
- Tutorial: “Credited in 42 qualified landings,” with the metric definition one tap away.

Never display “guaranteed results,” a causal success rate without a valid denominator, or rankings that reward unsafe volume.

## 6. Attribution policy

### Eligible attribution

- The rider explicitly selects the tutorial/instructor.
- The tutorial version existed before the claim's eligible event time.
- The tutorial maps to the claimed trick or an approved prerequisite relationship.
- The mastery claim meets the configured evidence threshold.
- The attribution is not revoked, disputed, duplicated, self-dealing, or outside the allowed attribution window.

### Multiple influences

A rider may credit up to three resources. Public counts use fractional credit (`1/n`) for monetization and ranking, while “riders helped” counts a unique rider once per instructor/trick window. The UI does not force false exclusivity.

### Attribution window

Default: the resource must have been saved, opened, joined as a challenge, or manually cited within 90 days before the eligible landing. Manual citation is allowed because learning often happens outside TrickBook, but receives a lower confidence label unless the tutorial link or code resolves.

### Revocation and correction

- Riders can remove or replace attribution for 30 days without support.
- After a payout locks, corrections create compensating ledger entries; history is not silently rewritten.
- Instructors can dispute impersonation, unrelated tricks, brigading, or prohibited incentives.
- Removing public credit does not delete the rider's mastery claim.

## 7. Functional requirements

| ID | Requirement |
|---|---|
| FR-1 | Accounts support composable profile roles and role-specific modules without separate logins. |
| FR-2 | Tutorials have stable IDs, versions, canonical trick links, content-role credits, rights status, and instructor-profile links. |
| FR-3 | A rider can attach zero to three attribution targets to a Claimed claim and choose private, aggregate-only, homies, or public visibility. |
| FR-4 | Only an eligible Claimed claim can produce a `qualified` outcome; self-reported progress never affects verified outcome counts or payouts. |
| FR-5 | Every outcome stores its policy version, tutorial version, evidence tier, consent state, and revocation state. |
| FR-6 | Instructor aggregates distinguish all attributed landings from Verified outcomes and deduplicate repeats. |
| FR-7 | Public instructor metrics are delayed seven days and suppressed below five distinct riders. |
| FR-8 | A rider can prove possession of a valid private mastery credential without disclosing clip, account ID, instructor, or exact date. |
| FR-9 | With rider consent, a verifier can prove that an outcome references a public instructor/tutorial without revealing the rider. |
| FR-10 | Instructors can export public catalogs and aggregate reports; riders can export/delete off-chain data subject to immutable commitment disclosures. |
| FR-11 | Moderation supports impersonation, rights, credential, unsafe instruction, attribution, and outcome-fraud cases. |
| FR-12 | Reward calculation is separate. No smart contract automatically pays merely because an attribution was submitted. |

## 8. Privacy, safety, and security requirements

| ID | Requirement |
|---|---|
| PR-1 | Midnight never receives raw video, account IDs, usernames, GPS, viewing history, coaching notes, or payout identity. |
| PR-2 | Outcome commitments use fresh salts and domain-separated hashes so claims cannot be correlated on-chain. |
| PR-3 | Aggregate-only consent permits thresholded counting but not disclosure of the rider-instructor edge. |
| PR-4 | An instructor cannot enumerate private learners or contact a rider because of an attribution. |
| PR-5 | Public proofs disclose the minimum statement and use pairwise or one-time presentation identifiers. |
| SR-1 | Issuance requires a currently eligible claim, active tutorial version, rider consent, and unused attribution nullifier. |
| SR-2 | Issuer, verifier, moderator, and payout roles use separate keys and least privilege. |
| SR-3 | Revocation is append-only and auditable; an attestation cannot move from revoked back to active. |
| SR-4 | Rate limits, device/account risk, collusion signals, and manual review protect metrics and rewards. |
| SR-5 | “Mastered” never means injury-free, competition-certified, or professionally endorsed. |

## 9. Trust and evidence labels

| Label | Basis | Public outcomes | Reward eligibility |
|---|---|---:|---:|
| Self-reported | Rider changed progress state | No | No |
| Captured | In-app provenance passed | Private history only | No |
| Verified landing | Claimed tier 1 and tier 3 pass; tier 2 does not fail | Yes | Yes, after fraud delay |
| Coach attested | Qualified coach reviewed evidence | Yes, separately labeled | Policy-dependent |
| Event certified | Approved event/competition result | Yes, separately labeled | Policy-dependent |

The first release should use **Verified landing**, not “mastered,” as the qualifying public outcome. Mastery can later require three verified landings across two sessions, or a coach/event credential. The rule must be sport- and trick-versioned rather than implied by one clip.

## 10. Monetization and rewards

Outcomes create a settlement input, not an automatic entitlement.

### Initial incentives

- Featured instructor profiles and durable tutorial attribution
- Creator challenge tools and outcome analytics
- Affiliate links/codes for paid TrickBook conversion
- Sponsored challenge reports based on qualified outcomes

### Later incentives

- Revenue share from attributable paid memberships
- Paid programs or coaching cohorts
- Brand-funded outcome bounties with geographic, age, and safety controls
- Optional NIGHT-denominated ecosystem campaigns only after legal, tax, fraud, custody, and app-store review

TrickBook should fund network execution itself. Holding NIGHT can generate/delegate DUST, allowing interactions to remain free at the point of use. NIGHT rewards are not required to make the learning loop valuable.

## 11. Success metrics

| Metric | 90-day target |
|---|---:|
| Eligible landings with rider-selected attribution | 25% |
| Published tutorials credited by at least one rider | 30% |
| Attribution confirmation completion | 80% |
| Outcome dispute rate | Below 2% |
| Riders returning to the same instructor | 15% |
| Instructor profile → tutorial start conversion | 20% |
| Median issuance after eligible verification | Under 5 minutes, excluding public delay |

Guardrails include injury/safety reports, verification failures, false credentials, creator concentration, private-edge leakage, and reward abuse.

## 12. Delivery plan

### Phase 0 — definitions and policy

- Approve landed versus mastered rules by sport.
- Approve attribution window, evidence threshold, privacy threshold, disputes, and reward exclusions.
- User-test “Learned with” and “riders helped” with riders and micro-influencers.

### Phase 1 — profile and tutorial foundation

- Ship composable roles, instructor claim flow, content-role attribution, tutorial versions, credential evidence, and visibility controls.
- Backfill current Trickipedia tutorials without awarding retroactive verified outcomes.
- Add public instructor pages and private rider progression modules.

### Phase 2 — off-chain outcome vertical slice

- Connect one tutorial to one eligible Claimed landing.
- Issue signed off-chain attestations, compute delayed aggregates, add disputes, and instrument the funnel.
- Pilot with 5–10 instructors and no financial rewards.

### Phase 3 — Midnight proof layer

- Deploy outcome commitment/attestation extensions on preprod.
- Prove private credential possession and anonymous instructor attribution.
- Threat-model, property-test, model-check, measure proof latency/DUST, and complete external contract review.

### Phase 4 — incentives

- Add affiliate settlement and sponsored challenges using the fraud-reviewed outcome ledger.
- Introduce payouts only after minimum cohort size and legal/app-store review.
- Evaluate optional NIGHT campaigns separately from normal creator compensation.

## 13. Launch gates

- One complete rider → tutorial → eligible claim → outcome → aggregate flow works on web and mobile.
- Profile visibility combinations are tested, including deletion and instructor blocking.
- No aggregate is public below five distinct consenting riders.
- Revoked, duplicated, expired, or disputed outcomes never count or pay.
- Midnight outage does not block landing verification or profile use; anchoring queues safely.
- The [formal invariants](/docs/features/instructor-outcomes/formal-spec) pass bounded model checking and map to automated tests.
- Five pilot instructors understand the metric definitions without explanation from the product team.

## 14. Open decisions

1. Does “mastered” require repeated verified landings, coach attestation, or a trick-specific rubric?
2. Should attribution accept prerequisites by default or require editorial mapping?
3. Is aggregate-only consent the default, or must every contribution be opted in?
4. What cohort and delay thresholds are required before financial rewards?
5. Should organizations share credit with individual instructors, and in what proportions?

