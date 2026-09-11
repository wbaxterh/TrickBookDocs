---
sidebar_position: 4
---

# Trickipedia: Data Model & Formal Verification

A formal-methods treatment of the Trickipedia progression network: the data model as deployed, its relationships to the rest of the app, a TLA+ specification of the design, and the results of model checking it with TLC plus a conformance check of the live production data — which found (and led to the fix of) a real prerequisite cycle.

## Overview

Trickipedia is TrickBook's trick encyclopedia: 144 trick documents across seven categories (Skateboarding 47, Snowboarding 74, BMX, Surfing, Longboarding, Inline, Scooter), each with description, difficulty, steps, media, and — for skateboarding and snowboarding — a **progression network** that tells riders what to learn first, what to try next, and what's related.

## Data model (as deployed)

Each trick is a MongoDB document in the `trickipedia` collection:

```js
{
  _id: ObjectId,
  name: "Kickflip",
  url: "kickflip",             // stable slug, page route /trickipedia/<category>/<url>
  category: "Skateboarding",   // one of 7 sport categories
  difficulty: "Intermediate",  // Beginner | Intermediate | Advanced
  description, steps, images, videos, videoUrl, source,
  tutorials: [ { title, canonicalUrl, availability: "active" | ..., featured, instructor } ],
  progression: {
    prerequisites: [ Edge ],   // learn these first (ordering semantics!)
    nextSteps:     [ Edge ],   // natural follow-ups
    related:       [ Edge ]    // variations / companion skills (no ordering)
  }
}
```

An **Edge** carries editorial provenance, not just a pointer:

```js
{
  trickId: ObjectId,           // the other trick
  reason: "Supplies the flip half of the trick.",
  order: 0,
  research: {
    status: "draft" | "reviewed" | "published" | "rejected",
    confidence: "low" | "medium" | "high",
    evidence: [ { url, claim, checkedAt } ]
  }
}
```

### Relationships with other features

| Relationship | Mechanism |
|---|---|
| **Network API** | `GET /api/trickipedia/:id/network` returns `foundations` (prerequisites), `nextSteps`, `related`. Only edges with `research.status ∈ {reviewed, published}` are exposed; the hydrate step silently **drops edges whose `trickId` no longer resolves** (deletions leave dangling references in place). |
| **Trick pages** | `/trickipedia/[category]/[trick]` renders the three network rails ("Learn these first", "Try next", "Related variations") with each edge's `reason`. |
| **Trick lists** | The "Add to TrickList" button writes into the user's `tricklists` documents; completion is tracked per list. Deleting a Trickipedia document does **not** touch list entries. |
| **Categories** | Edges only ever link tricks within the same category (a skateboarding trick never lists a snowboarding prerequisite). |

## The formal specification

The essential correctness question for a *learning* network: **can every visible progression actually be learned?** If the prerequisite graph a user sees contains a cycle, the ordering it promises is impossible. Secondary properties: the API must only serve moderated edges, must never expose dangling references, cross-category edges must not exist, and a user's completed tricks must be a subset of their list.

The spec models the system with a `GuardedWrites` switch: `FALSE` is the system as deployed (edge writers — the migration scripts — perform **no cycle check**); `TRUE` is the corrected design in which a prerequisite write is refused if it would create a cycle.

```tla
------------------------- MODULE TrickipediaNetwork -------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS
  Tricks,        \* model universe of trick documents
  SnowTricks,    \* subset of Tricks in the second category
  GuardedWrites  \* BOOLEAN: cycle guard on prerequisite writes?

ASSUME SnowTricks \subseteq Tricks
ASSUME GuardedWrites \in BOOLEAN

CatOf(t) == IF t \in SnowTricks THEN "snowboarding" ELSE "skateboarding"

Pairs == {p \in Tricks \X Tricks : p[1] # p[2]}

Statuses == {"none", "draft", "reviewed", "published", "rejected"}
ActiveStatuses  == {"draft", "reviewed", "published"}
VisibleStatuses == {"reviewed", "published"}

VARIABLES
  existing,  \* SUBSET Tricks: documents currently in the collection
  edges,     \* [Pairs -> Statuses]: prerequisite edge p[1] REQUIRES p[2]
  list       \* one user's trick list: [tricks: SUBSET, completed: SUBSET]

vars == <<existing, edges, list>>

RECURSIVE TransitiveClosure(_)
TransitiveClosure(R) ==
  LET Next == R \cup {p \in Pairs \cup {<<t, t>> : t \in Tricks} :
                        \E b \in Tricks : <<p[1], b>> \in R /\ <<b, p[2]>> \in R}
  IN IF Next = R THEN R ELSE TransitiveClosure(Next)

HasCycle(R) == \E t \in Tricks : <<t, t>> \in TransitiveClosure(R)

ActiveRel  == {p \in Pairs : edges[p] \in ActiveStatuses}

\* What the network endpoint serves: moderated edges whose endpoints both
\* still resolve (the hydrate step silently drops dangling references).
ApiRel == {p \in Pairs : edges[p] \in VisibleStatuses
                          /\ p[1] \in existing /\ p[2] \in existing}

Init ==
  /\ existing = {}
  /\ edges = [p \in Pairs |-> "none"]
  /\ list = [tricks |-> {}, completed |-> {}]

AddTrick(t) ==
  /\ t \notin existing
  /\ existing' = existing \cup {t}
  /\ UNCHANGED <<edges, list>>

\* Deleting a document does NOT clean up edges that point at it, and does
\* not touch user lists: both mirror the deployed system.
RemoveTrick(t) ==
  /\ t \in existing
  /\ existing' = existing \ {t}
  /\ UNCHANGED <<edges, list>>

ProposeEdge(p) ==
  /\ p[1] \in existing /\ p[2] \in existing
  /\ CatOf(p[1]) = CatOf(p[2])
  /\ edges[p] = "none"
  /\ GuardedWrites => ~HasCycle(ActiveRel \cup {p})
  /\ edges' = [edges EXCEPT ![p] = "draft"]
  /\ UNCHANGED <<existing, list>>

ReviewEdge(p) ==
  /\ edges[p] = "draft"
  /\ edges' = [edges EXCEPT ![p] = "reviewed"]
  /\ UNCHANGED <<existing, list>>

RejectEdge(p) ==
  /\ edges[p] = "draft"
  /\ edges' = [edges EXCEPT ![p] = "rejected"]
  /\ UNCHANGED <<existing, list>>

PublishEdge(p) ==
  /\ edges[p] = "reviewed"
  /\ edges' = [edges EXCEPT ![p] = "published"]
  /\ UNCHANGED <<existing, list>>

AddToList(t) ==
  /\ t \in existing
  /\ t \notin list.tricks
  /\ list' = [list EXCEPT !.tricks = @ \cup {t}]
  /\ UNCHANGED <<existing, edges>>

CompleteTrick(t) ==
  /\ t \in list.tricks
  /\ t \notin list.completed
  /\ list' = [list EXCEPT !.completed = @ \cup {t}]
  /\ UNCHANGED <<existing, edges>>

Next ==
  \/ \E t \in Tricks : AddTrick(t) \/ RemoveTrick(t)
                       \/ AddToList(t) \/ CompleteTrick(t)
  \/ \E p \in Pairs : ProposeEdge(p) \/ ReviewEdge(p)
                      \/ RejectEdge(p) \/ PublishEdge(p)

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ existing \subseteq Tricks
  /\ edges \in [Pairs -> Statuses]
  /\ list.tricks \subseteq Tricks
  /\ list.completed \subseteq Tricks

NoSelfEdges == \A p \in Pairs : p[1] # p[2]

SameCategoryEdges ==
  \A p \in Pairs : edges[p] # "none" => CatOf(p[1]) = CatOf(p[2])

ApiServesOnlyModerated ==
  \A p \in ApiRel : edges[p] \in VisibleStatuses

ApiNeverServesDangling ==
  \A p \in ApiRel : p[1] \in existing /\ p[2] \in existing

CompletionWithinList == list.completed \subseteq list.tricks

\* THE learnability property: the prerequisite graph a user can see must
\* never contain a cycle, or the progression it describes is unlearnable.
PrereqAcyclic == ~HasCycle(ApiRel)

=============================================================================
```

### Reading the spec

- **State**: the trick catalog (`existing`), every possible prerequisite edge with its moderation status (`edges`, where `"none"` means the edge does not exist), and one user's trick list.
- **Actions**: catalog add/remove; the edge lifecycle `draft → reviewed → published` (or `draft → rejected`); list add/complete. `RemoveTrick` deliberately leaves edges and list entries untouched — that is what the deployed system does.
- **`ApiRel`** encodes the network endpoint's contract: moderated statuses only, dangling references filtered out at read time.
- **Invariants**: type safety, no self-edges, category consistency, the two API-contract properties, list-completion containment, and the headline property `PrereqAcyclic`.

## Verification results

### Model checking with TLC

Model checked with TLC (tla2tools, OpenJDK 21) on 2026‑09‑11.

**Design as deployed (`GuardedWrites = FALSE`), 3 tricks:**

```text
Error: Invariant PrereqAcyclic is violated.
```

TLC produces a 7-state counterexample: add tricks `t1`, `t2`; propose and review edge `t2 → t1`; propose and review edge `t1 → t2`. Both edges are now visible and form a cycle — the progression is unlearnable. **This is not a theoretical concern**; see the conformance check below.

**Corrected design (`GuardedWrites = TRUE`):**

| Model | States generated | Distinct states | Depth | Result |
|---|---|---|---|---|
| 3 tricks (2 categories) | 18,361 | 3,456 | 18 | **All 7 invariants hold** |
| 4 tricks (2 categories) | 2,529,793 | 331,776 | 27 | **All 7 invariants hold** |

The guarded design refuses any prerequisite write that would create a cycle among active (non-rejected) edges, which is strictly stronger than guarding the visible subset — an edge can't sneak into a cycle later by being reviewed.

### Conformance check of production data

The spec's static invariants were checked directly against the production `trickipedia` collection (144 tricks, **807 progression edges**):

| Invariant | Result |
|---|---|
| No self-edges | ✅ 0 violations |
| Referential integrity (no dangling `trickId`) | ✅ 0 violations |
| Category consistency | ✅ 0 violations |
| Valid research statuses (185 reviewed, 622 published) | ✅ 0 violations |
| **Prerequisite acyclicity** | ❌ **2 cycles found** |

The cycles — `ollie-snowboard → tail-press-snowboard → 50-50-snowboard → ollie-snowboard` and `ollie-snowboard → tail-press-snowboard → boardslide-snowboard → ollie-snowboard` — share one edge: the ollie listing the tail press as a prerequisite. Each edge was individually well-reasoned, but together they promised an impossible ordering. That shared edge described itself as *"helpful, not mandatory"* — exactly the semantics of `related`, not `prerequisites` — so the remediation (`scripts/fix-snowboard-prereq-cycle.js` in the backend repo) reclassifies that single edge, breaking both cycles without losing the pedagogy.

This is the useful lesson of the exercise: **TLC predicted the exact bug class from the unguarded design, and the data audit found a live instance of it.**

> **Remediation applied 2026‑09‑11.** The edge was reclassified in production and the conformance check now reports zero violations across all five static invariants (144 tricks, 807 edges, `cycles: []`).

## Recommendations

1. **Write-time guard** *(mirrors `ProposeEdge` in the spec)*: any code path that writes `progression.prerequisites` — admin tools and migration scripts alike — should reject writes that create a cycle among active prerequisite edges. The check is a transitive-closure test over at most a few hundred edges per category.
2. **CI conformance check**: run the static-invariant audit (self-edges, dangling refs, category consistency, statuses, acyclicity) against staging on every migration PR. It is a ~40-line script and it already caught one production bug.
3. Keep `related` free of ordering semantics — it is the correct home for "helpful but not required" connections, as the remediation above demonstrates.

## Re-running the verification

```bash
# Model checking (spec + configs live in the docs repo under static/tla/)
java -cp tla2tools.jar tlc2.TLC -config Unguarded.cfg TrickipediaNetwork.tla   # expect PrereqAcyclic violation
java -cp tla2tools.jar tlc2.TLC -config Guarded.cfg   TrickipediaNetwork.tla   # expect all invariants to hold

# Live-data conformance (Backend repo)
MONGODB_DATABASE=TrickList2 node scripts/check-trickipedia-invariants.js
```
