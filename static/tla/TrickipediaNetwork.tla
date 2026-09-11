------------------------- MODULE TrickipediaNetwork -------------------------
(***************************************************************************)
(* Formal model of TrickBook's Trickipedia progression network and its     *)
(* interaction with user trick lists.                                      *)
(*                                                                         *)
(* State mirrors the deployed MongoDB shape:                               *)
(*   - tricks may be added and removed from the catalog                    *)
(*   - progression edges (modelled here for `prerequisites`, the only      *)
(*     group with ordering semantics) carry a research status with the     *)
(*     lifecycle  draft -> reviewed -> published  (or draft -> rejected)   *)
(*   - the /api/trickipedia/:id/network endpoint exposes only edges whose  *)
(*     status is `reviewed` or `published`, and hides edges whose target   *)
(*     no longer exists (the hydrate step drops unresolvable trickIds)     *)
(*   - a user trick list references catalog tricks and tracks completion   *)
(*                                                                         *)
(* GuardedWrites selects between the system as deployed (FALSE: edge      *)
(* writers such as the migration scripts perform no cycle check) and the   *)
(* corrected design (TRUE: a write is refused if it would create a         *)
(* prerequisite cycle among active edges).                                 *)
(***************************************************************************)
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

(***************************************************************************)
(* Reachability over a relation given as a set of pairs.                   *)
(***************************************************************************)
RECURSIVE TransitiveClosure(_)
TransitiveClosure(R) ==
  LET Next == R \cup {p \in Pairs \cup {<<t, t>> : t \in Tricks} :
                        \E b \in Tricks : <<p[1], b>> \in R /\ <<b, p[2]>> \in R}
  IN IF Next = R THEN R ELSE TransitiveClosure(Next)

HasCycle(R) == \E t \in Tricks : <<t, t>> \in TransitiveClosure(R)

ActiveRel  == {p \in Pairs : edges[p] \in ActiveStatuses}

(***************************************************************************)
(* What the network endpoint serves: moderated edges whose endpoints both  *)
(* still resolve (the hydrate step silently drops dangling references).    *)
(***************************************************************************)
ApiRel == {p \in Pairs : edges[p] \in VisibleStatuses
                          /\ p[1] \in existing /\ p[2] \in existing}

Init ==
  /\ existing = {}
  /\ edges = [p \in Pairs |-> "none"]
  /\ list = [tricks |-> {}, completed |-> {}]

(***************************************************************************)
(* Catalog actions                                                         *)
(***************************************************************************)
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

(***************************************************************************)
(* Edge lifecycle. Writers (admin tools, migration scripts) only create    *)
(* edges between existing tricks of the same category and never self-      *)
(* edges; that much the shipped importers guarantee by construction.       *)
(* Whether they check for cycles is the GuardedWrites switch.              *)
(***************************************************************************)
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

(***************************************************************************)
(* User trick-list actions ("Add to TrickList" on a trick page).           *)
(***************************************************************************)
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

(***************************************************************************)
(* Invariants                                                              *)
(***************************************************************************)
TypeOK ==
  /\ existing \subseteq Tricks
  /\ edges \in [Pairs -> Statuses]
  /\ list.tricks \subseteq Tricks
  /\ list.completed \subseteq Tricks

\* Edges never point from a trick to itself (holds by construction:
\* the state space only contains non-self pairs).
NoSelfEdges == \A p \in Pairs : p[1] # p[2]

\* Progression edges never cross categories.
SameCategoryEdges ==
  \A p \in Pairs : edges[p] # "none" => CatOf(p[1]) = CatOf(p[2])

\* The API only ever serves moderated, fully-resolvable edges.
ApiServesOnlyModerated ==
  \A p \in ApiRel : edges[p] \in VisibleStatuses

ApiNeverServesDangling ==
  \A p \in ApiRel : p[1] \in existing /\ p[2] \in existing

\* A user can never have completed a trick that is not on their list.
CompletionWithinList == list.completed \subseteq list.tricks

\* THE learnability property: the prerequisite graph a user can see must
\* never contain a cycle, or the progression it describes is unlearnable.
PrereqAcyclic == ~HasCycle(ApiRel)

=============================================================================
