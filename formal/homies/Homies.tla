------------------------------- MODULE Homies -------------------------------
(***************************************************************************)
(* Formal model of TrickBook's Homies connection lifecycle.                *)
(*                                                                         *)
(* Modeled against TB-Backend routes/users.js @ master 4e1300a9            *)
(* (inspected 2026-09-11):                                                 *)
(*   send    POST   /users/:id/homie-request   users.js:475               *)
(*   accept  POST   /users/:id/accept-homie    users.js:591               *)
(*   reject  POST   /users/:id/reject-homie    users.js:635               *)
(*   remove  DELETE /users/homie/:id           users.js:747               *)
(*                                                                         *)
(* State mirrors the deployed MongoDB shape: each user document carries    *)
(*   homies                 : array of user-id strings ($push / $pull)     *)
(*   homieRequests.received : array of {from, sentAt}                      *)
(*   homieRequests.sent     : array of user-id strings                     *)
(* Because the code uses $push (not $addToSet), arrays can hold duplicate  *)
(* entries; we model each array cell as a multiplicity count 0..MaxMult so *)
(* duplicates are representable rather than impossible by abstraction.     *)
(* $pull removes ALL matching elements, so a pull sets the count to 0.     *)
(*                                                                         *)
(* Atomicity boundaries are preserved exactly: one MongoDB updateOne on    *)
(* one document is one atomic model step ($push and $pull in the same      *)
(* updateOne commit together); each handler is a SEQUENCE of such steps    *)
(* interleavable with every other in-flight handler, and a handler can     *)
(* crash between steps (CrashesEnabled), leaving its partial writes        *)
(* committed. Validation reads (findOne) are their own snapshot steps.     *)
(*                                                                         *)
(* Design switches:                                                        *)
(*   AtomicOps     FALSE = system as deployed (separate writes, validate-  *)
(*                 then-write). TRUE = proposed corrected design: each     *)
(*                 handler is one multi-document transaction whose guard   *)
(*                 (conditional write) re-checks the request at commit     *)
(*                 time, and connection inserts use $addToSet semantics.   *)
(*   PurgeOnRemove TRUE  = corrected remove also deletes any pending       *)
(*                 requests between the pair (both directions). Needed     *)
(*                 because a transaction alone does not stop a stale       *)
(*                 crossed request from resurrecting a severed connection. *)
(*                                                                         *)
(* Ghost (specification-only) state, invisible to the modeled handlers:    *)
(*   gen[{u,v}]   counts severed connection lifecycles for the pair; it    *)
(*                bumps when a remove step actually severs a connection.   *)
(*   reqGen[u][v] the pair's gen when u's pending request from v was       *)
(*                (last) created — which lifecycle the request belongs to. *)
(*   ghostWrite   latched TRUE if a connection write commits when the      *)
(*                authorizing request is no longer present (TOCTOU).       *)
(*   resurrect    latched TRUE if a connection write commits for a request *)
(*                from an earlier (since-severed) lifecycle.               *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets

CONSTANTS
  Riders,          \* model users, e.g. {a, b}
  SendSlots,       \* operation budget: one slot = one client-issued call
  AcceptSlots,     \* (a retry after a lost response is simply another slot)
  RejectSlots,
  RemoveSlots,
  AtomicOps,       \* BOOLEAN design switch, see header
  PurgeOnRemove,   \* BOOLEAN design switch, see header
  CrashesEnabled,  \* BOOLEAN: allow a handler to die between its writes
  MaxMult          \* multiplicity cap per array cell (state-space bound)

ASSUME AtomicOps \in BOOLEAN
ASSUME PurgeOnRemove \in BOOLEAN
ASSUME PurgeOnRemove => AtomicOps
ASSUME CrashesEnabled \in BOOLEAN
ASSUME MaxMult \in Nat \ {0}

Slots == SendSlots \cup AcceptSlots \cup RejectSlots \cup RemoveSlots

\* gen can bump at most once per remove slot
MaxGen == Cardinality(RemoveSlots)

Counts == 0..MaxMult
Gens   == 0..MaxGen

Pair(u, v) == {u, v}
Pairs == {P \in SUBSET Riders : Cardinality(P) = 2}

\* Saturating add: pushing past the cap is simply not explored (documented
\* bound). Duplicate detection only needs multiplicity 2.
Inc(n)   == IF n < MaxMult THEN n + 1 ELSE n
GBump(g) == IF g < MaxGen THEN g + 1 ELSE g

SomeRider == CHOOSE r \in Riders : TRUE

IdleOp == [st |-> "idle", a |-> SomeRider, t |-> SomeRider, pc |-> 0, g |-> 0]

OpStates == [st : {"idle", "run", "done", "crash"},
             a  : Riders, t : Riders, pc : 0..3, g : Gens]

VARIABLES
  homies,   \* [Riders -> [Riders -> Counts]] homies[u][v]: copies of v in u's homies
  recv,     \* recv[u][v]: entries {from: v} in u's homieRequests.received
  sent,     \* sent[u][v]: copies of v in u's homieRequests.sent
  gen,      \* ghost: [Pairs -> Gens]
  reqGen,   \* ghost: [Riders -> [Riders -> Gens]]
  ghostWrite, resurrect,  \* ghost flags
  op        \* [Slots -> OpStates]

vars == <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect, op>>

Init ==
  /\ homies = [u \in Riders |-> [v \in Riders |-> 0]]
  /\ recv   = [u \in Riders |-> [v \in Riders |-> 0]]
  /\ sent   = [u \in Riders |-> [v \in Riders |-> 0]]
  /\ gen    = [p \in Pairs |-> 0]
  /\ reqGen = [u \in Riders |-> [v \in Riders |-> 0]]
  /\ ghostWrite = FALSE
  /\ resurrect  = FALSE
  /\ op = [s \in Slots |-> IdleOp]

(***************************************************************************)
(* Starting an operation: a client issues the HTTP call. Send may target   *)
(* anyone including self (the handler's own guard rejects self, users.js   *)
(* :483). Accept/reject/remove are modeled for distinct pairs only: their  *)
(* self-targeted forms can only touch homies[u][u]-shaped cells, which no  *)
(* reachable behavior makes positive (documented reduction).               *)
(***************************************************************************)
StartSend(s) ==
  /\ op[s].st = "idle"
  /\ \E x \in Riders, y \in Riders :
       op' = [op EXCEPT ![s] = [st |-> "run", a |-> x, t |-> y, pc |-> 1, g |-> 0]]
  /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>

StartOther(s) ==
  /\ op[s].st = "idle"
  /\ \E x \in Riders : \E y \in Riders \ {x} :
       op' = [op EXCEPT ![s] = [st |-> "run", a |-> x, t |-> y, pc |-> 1, g |-> 0]]
  /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>

(***************************************************************************)
(* A handler crash between committed steps: the op dies, its writes so far *)
(* stay committed, no compensation runs (there is none in the code).       *)
(***************************************************************************)
Crash(s) ==
  /\ CrashesEnabled
  /\ op[s].st = "run"
  /\ op' = [op EXCEPT ![s] = [IdleOp EXCEPT !.st = "crash"]]
  /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>

\* Terminal op states are normalized (params/pc/ghost fields are never read
\* again) — a pure state-space reduction with no semantic effect.
Done(s) == op' = [op EXCEPT ![s] = [IdleOp EXCEPT !.st = "done"]]

(***************************************************************************)
(* SEND — baseline (users.js:475). pc1: one findOne on the TARGET's doc    *)
(* checks self, already-homies (target's array only!) and already-         *)
(* requested (target's received only). pc2: $push target's received.      *)
(* pc3: $push sender's sent. Bot auto-accept and the network/privacy flag  *)
(* are out of scope (both riders modeled as existing and accepting).       *)
(***************************************************************************)
BaseSend(s) ==
  /\ op[s].st = "run"
  /\ LET x == op[s].a  y == op[s].t IN
     CASE op[s].pc = 1 ->
            IF x = y \/ homies[y][x] > 0 \/ recv[y][x] > 0
              THEN Done(s) /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>
              ELSE /\ op' = [op EXCEPT ![s].pc = 2]
                   /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>
       [] op[s].pc = 2 ->
            /\ recv' = [recv EXCEPT ![y][x] = Inc(@)]
            /\ reqGen' = [reqGen EXCEPT ![y][x] = gen[Pair(x, y)]]
            /\ op' = [op EXCEPT ![s].pc = 3]
            /\ UNCHANGED <<homies, sent, gen, ghostWrite, resurrect>>
       [] op[s].pc = 3 ->
            /\ sent' = [sent EXCEPT ![x][y] = Inc(@)]
            /\ Done(s)
            /\ UNCHANGED <<homies, recv, gen, reqGen, ghostWrite, resurrect>>

(***************************************************************************)
(* ACCEPT — baseline (users.js:591). Acceptor u, requester r.              *)
(* pc1: validation findOne on u's own doc requires a pending request from  *)
(* r (only the intended recipient can pass this). The op records which     *)
(* lifecycle that request belongs to (ghost).                              *)
(* pc2: ONE updateOne on u's doc: $push homies[r] AND $pull received{from  *)
(* r} — atomic together. The write is unconditional: if the request        *)
(* vanished after validation, it still commits (ghostWrite latches).       *)
(* pc3: ONE updateOne on r's doc: $push homies[u], $pull sent[u].          *)
(***************************************************************************)
BaseAccept(s) ==
  /\ op[s].st = "run"
  /\ LET u == op[s].a  r == op[s].t IN
     CASE op[s].pc = 1 ->
            IF recv[u][r] > 0
              THEN /\ op' = [op EXCEPT ![s].pc = 2, ![s].g = reqGen[u][r]]
                   /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>
              ELSE Done(s) /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>
       [] op[s].pc = 2 ->
            /\ ghostWrite' = (ghostWrite \/ recv[u][r] = 0)
            /\ resurrect' = (resurrect \/ gen[Pair(u, r)] > op[s].g)
            /\ homies' = [homies EXCEPT ![u][r] = Inc(@)]
            /\ recv' = [recv EXCEPT ![u][r] = 0]
            /\ op' = [op EXCEPT ![s].pc = 3]
            /\ UNCHANGED <<sent, gen, reqGen>>
       [] op[s].pc = 3 ->
            /\ resurrect' = (resurrect \/ gen[Pair(u, r)] > op[s].g)
            /\ homies' = [homies EXCEPT ![r][u] = Inc(@)]
            /\ sent' = [sent EXCEPT ![r][u] = 0]
            /\ Done(s)
            /\ UNCHANGED <<recv, gen, reqGen, ghostWrite>>

(***************************************************************************)
(* REJECT — baseline (users.js:635). No validation read at all.            *)
(* pc1: $pull u's received{from r}. pc2: $pull r's sent[u].                *)
(***************************************************************************)
BaseReject(s) ==
  /\ op[s].st = "run"
  /\ LET u == op[s].a  r == op[s].t IN
     CASE op[s].pc = 1 ->
            /\ recv' = [recv EXCEPT ![u][r] = 0]
            /\ op' = [op EXCEPT ![s].pc = 2]
            /\ UNCHANGED <<homies, sent, gen, reqGen, ghostWrite, resurrect>>
       [] op[s].pc = 2 ->
            /\ sent' = [sent EXCEPT ![r][u] = 0]
            /\ Done(s)
            /\ UNCHANGED <<homies, recv, gen, reqGen, ghostWrite, resurrect>>

(***************************************************************************)
(* REMOVE — baseline (users.js:747). No validation read.                   *)
(* pc1: $pull u's homies[h]. pc2: $pull h's homies[u].                     *)
(* Ghost: the pair's lifecycle counter bumps when the remove actually      *)
(* severs a (possibly one-sided) connection, evaluated at pc1.             *)
(***************************************************************************)
BaseRemove(s) ==
  /\ op[s].st = "run"
  /\ LET u == op[s].a  h == op[s].t IN
     CASE op[s].pc = 1 ->
            /\ gen' = IF homies[u][h] > 0 \/ homies[h][u] > 0
                        THEN [gen EXCEPT ![Pair(u, h)] = GBump(@)]
                        ELSE gen
            /\ homies' = [homies EXCEPT ![u][h] = 0]
            /\ op' = [op EXCEPT ![s].pc = 2]
            /\ UNCHANGED <<recv, sent, reqGen, ghostWrite, resurrect>>
       [] op[s].pc = 2 ->
            /\ homies' = [homies EXCEPT ![h][u] = 0]
            /\ Done(s)
            /\ UNCHANGED <<recv, sent, gen, reqGen, ghostWrite, resurrect>>

(***************************************************************************)
(* Corrected design: each handler is one transaction committing            *)
(* atomically, with the validation re-expressed as a conditional-write     *)
(* guard (the transaction aborts, changing nothing, if the guard fails)    *)
(* and $addToSet in place of $push for connection inserts.                 *)
(***************************************************************************)
AtomicSend(s) ==
  /\ op[s].st = "run" /\ op[s].pc = 1
  /\ LET x == op[s].a  y == op[s].t IN
     IF x = y \/ homies[y][x] > 0 \/ recv[y][x] > 0
       THEN Done(s) /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>
       ELSE /\ recv' = [recv EXCEPT ![y][x] = 1]
            /\ sent' = [sent EXCEPT ![x][y] = 1]
            /\ reqGen' = [reqGen EXCEPT ![y][x] = gen[Pair(x, y)]]
            /\ Done(s)
            /\ UNCHANGED <<homies, gen, ghostWrite, resurrect>>

AtomicAccept(s) ==
  /\ op[s].st = "run" /\ op[s].pc = 1
  /\ LET u == op[s].a  r == op[s].t IN
     IF recv[u][r] = 0
       THEN Done(s) /\ UNCHANGED <<homies, recv, sent, gen, reqGen, ghostWrite, resurrect>>
       ELSE /\ resurrect' = (resurrect \/ gen[Pair(u, r)] > reqGen[u][r])
            /\ homies' = [homies EXCEPT ![u][r] = 1, ![r][u] = 1]
            /\ recv' = [recv EXCEPT ![u][r] = 0]
            /\ sent' = [sent EXCEPT ![r][u] = 0]
            /\ Done(s)
            /\ UNCHANGED <<gen, reqGen, ghostWrite>>

AtomicReject(s) ==
  /\ op[s].st = "run" /\ op[s].pc = 1
  /\ LET u == op[s].a  r == op[s].t IN
     /\ recv' = [recv EXCEPT ![u][r] = 0]
     /\ sent' = [sent EXCEPT ![r][u] = 0]
     /\ Done(s)
     /\ UNCHANGED <<homies, gen, reqGen, ghostWrite, resurrect>>

AtomicRemove(s) ==
  /\ op[s].st = "run" /\ op[s].pc = 1
  /\ LET u == op[s].a  h == op[s].t IN
     /\ gen' = IF homies[u][h] > 0 \/ homies[h][u] > 0
                 THEN [gen EXCEPT ![Pair(u, h)] = GBump(@)]
                 ELSE gen
     /\ homies' = [homies EXCEPT ![u][h] = 0, ![h][u] = 0]
     /\ IF PurgeOnRemove
          THEN /\ recv' = [recv EXCEPT ![u][h] = 0, ![h][u] = 0]
               /\ sent' = [sent EXCEPT ![u][h] = 0, ![h][u] = 0]
          ELSE UNCHANGED <<recv, sent>>
     /\ Done(s)
     /\ UNCHANGED <<reqGen, ghostWrite, resurrect>>

SendStep(s)   == IF AtomicOps THEN AtomicSend(s)   ELSE BaseSend(s)
AcceptStep(s) == IF AtomicOps THEN AtomicAccept(s) ELSE BaseAccept(s)
RejectStep(s) == IF AtomicOps THEN AtomicReject(s) ELSE BaseReject(s)
RemoveStep(s) == IF AtomicOps THEN AtomicRemove(s) ELSE BaseRemove(s)

Next ==
  \/ \E s \in SendSlots   : StartSend(s)  \/ SendStep(s)   \/ Crash(s)
  \/ \E s \in AcceptSlots : StartOther(s) \/ AcceptStep(s) \/ Crash(s)
  \/ \E s \in RejectSlots : StartOther(s) \/ RejectStep(s) \/ Crash(s)
  \/ \E s \in RemoveSlots : StartOther(s) \/ RemoveStep(s) \/ Crash(s)

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Invariants                                                              *)
(***************************************************************************)
TypeOK ==
  /\ homies \in [Riders -> [Riders -> Counts]]
  /\ recv   \in [Riders -> [Riders -> Counts]]
  /\ sent   \in [Riders -> [Riders -> Counts]]
  /\ gen    \in [Pairs -> Gens]
  /\ reqGen \in [Riders -> [Riders -> Gens]]
  /\ ghostWrite \in BOOLEAN /\ resurrect \in BOOLEAN
  /\ op \in [Slots -> OpStates]

\* No handler is mid-flight; "crash" is terminal, so its partial writes
\* are part of quiescent state — deliberately NOT excluded.
Quiescent == \A s \in Slots : op[s].st \in {"idle", "done", "crash"}

Mutual == \A u \in Riders : \A v \in Riders \ {u} :
            (homies[u][v] > 0) <=> (homies[v][u] > 0)

\* A. Strict: mutuality holds in every committed database state.
MutualHomies == Mutual

\* A'. Durable: mutuality holds whenever no handler is mid-flight.
QuiescentMutualHomies == Quiescent => Mutual

\* B/C enforcement: the moment a connection write commits, the request
\* that authorized it must still be pending (no TOCTOU acceptance).
NoGhostAcceptance == ghostWrite = FALSE

\* C. $push must never yield duplicate logical connections.
NoDuplicateHomies == \A u \in Riders : \A v \in Riders : homies[u][v] <= 1

\* C. Nor duplicate pending-request entries (two concurrent sends both pass
\* the already-requested check, then both $push).
NoDuplicateRequests ==
  \A u \in Riders : \A v \in Riders : recv[u][v] <= 1 /\ sent[u][v] <= 1

\* D. An acceptance authorized by a request from an earlier, since-severed
\* connection lifecycle must never commit a connection write.
NoResurrectedConnection == resurrect = FALSE

\* E. Self-connections are impossible.
NoSelfHomies == \A u \in Riders : homies[u][u] = 0

\* Request bookkeeping mutuality: at quiescence, "u has a pending request
\* from v" and "v's sent list contains u" must agree (otherwise one phone
\* shows a pending request the other cannot see or cancel).
QuiescentRequestSymmetry ==
  Quiescent => \A u \in Riders : \A v \in Riders \ {u} :
                 (recv[u][v] > 0) <=> (sent[v][u] > 0)

(***************************************************************************)
(* Reachability probes (expected to be VIOLATED — each violation is a      *)
(* constructive proof that the model is not vacuous).                      *)
(***************************************************************************)
ReachNeverConnected == \A u \in Riders : \A v \in Riders \ {u} : homies[u][v] = 0

ReachNoReconnect ==
  ~(\E u \in Riders : \E v \in Riders \ {u} :
      /\ gen[Pair(u, v)] >= 1
      /\ homies[u][v] > 0 /\ homies[v][u] > 0)

=============================================================================
