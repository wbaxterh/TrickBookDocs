---------------------------- MODULE RetentionLTV ----------------------------
(***************************************************************************)
(* Pre-build model for TrickBook's retention, version-control, analytics,  *)
(* and monetization control plane. This specifies the proposed design, not *)
(* the currently deployed system.                                          *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets

CONSTANTS
  Clients, EventIds, Versions,
  LatestVersion, MinimumVersion, RequiredClients,
  InitialTokens, MaxTokens

ASSUME Clients # {}
ASSUME EventIds # {}
ASSUME Versions \subseteq Nat
ASSUME LatestVersion \in Versions
ASSUME MinimumVersion \in Versions
ASSUME MinimumVersion <= LatestVersion
ASSUME RequiredClients \subseteq Clients
ASSUME MinimumVersion > 0
ASSUME (MinimumVersion - 1) \in Versions
ASSUME InitialTokens \in 0..MaxTokens

PromptStates == {"unchecked", "none", "optional", "required"}
EventKinds == {"unused", "core_action", "premium_action", "update_prompt",
               "update_accepted", "subscription_started"}

SomeClient == CHOOSE c \in Clients : TRUE

VARIABLES
  version, prompt, tokens, pro,
  issued, queued, accepted, eventOwner, eventKind,
  unsupportedAction, unauthorizedPremium, coreDebited

vars == <<version, prompt, tokens, pro, issued, queued, accepted,
          eventOwner, eventKind, unsupportedAction, unauthorizedPremium,
          coreDebited>>

Init ==
  /\ version = [c \in Clients |->
       IF c \in RequiredClients THEN MinimumVersion - 1 ELSE MinimumVersion]
  /\ prompt = [c \in Clients |-> "unchecked"]
  /\ tokens = [c \in Clients |-> InitialTokens]
  /\ pro = [c \in Clients |-> FALSE]
  /\ issued = {}
  /\ queued = {}
  /\ accepted = {}
  /\ eventOwner = [e \in EventIds |-> SomeClient]
  /\ eventKind = [e \in EventIds |-> "unused"]
  /\ unsupportedAction = FALSE
  /\ unauthorizedPremium = FALSE
  /\ coreDebited = FALSE

FreshEvent == EventIds \ issued

Emit(c, kind, e) ==
  /\ e \in FreshEvent
  /\ issued' = issued \cup {e}
  /\ queued' = queued \cup {e}
  /\ eventOwner' = [eventOwner EXCEPT ![e] = c]
  /\ eventKind' = [eventKind EXCEPT ![e] = kind]
  /\ UNCHANGED accepted

KeepEvents == UNCHANGED <<issued, queued, accepted, eventOwner, eventKind>>

CheckPolicy(c) ==
  /\ prompt[c] = "unchecked"
  /\ IF version[c] < MinimumVersion
        THEN prompt' = [prompt EXCEPT ![c] = "required"]
        ELSE IF version[c] < LatestVersion
          THEN prompt' = [prompt EXCEPT ![c] = "optional"]
          ELSE prompt' = [prompt EXCEPT ![c] = "none"]
  /\ UNCHANGED <<version, tokens, pro, unsupportedAction,
                  unauthorizedPremium, coreDebited>>
  /\ KeepEvents

RecordPrompt(c) ==
  /\ prompt[c] \in {"optional", "required"}
  /\ \E e \in FreshEvent :
       /\ Emit(c, "update_prompt", e)
       /\ UNCHANGED <<version, prompt, tokens, pro, unsupportedAction,
                      unauthorizedPremium, coreDebited>>

Upgrade(c) ==
  /\ prompt[c] \in {"optional", "required"}
  /\ \E e \in FreshEvent :
       /\ version' = [version EXCEPT ![c] = LatestVersion]
       /\ prompt' = [prompt EXCEPT ![c] = "none"]
       /\ Emit(c, "update_accepted", e)
       /\ UNCHANGED <<tokens, pro, unsupportedAction,
                      unauthorizedPremium, coreDebited>>

CoreAction(c) ==
  /\ prompt[c] # "required"
  /\ \E e \in FreshEvent :
       /\ Emit(c, "core_action", e)
       /\ coreDebited' = coreDebited
       /\ tokens' = tokens
       /\ UNCHANGED <<version, prompt, pro, unsupportedAction,
                      unauthorizedPremium>>

PremiumAction(c) ==
  /\ prompt[c] # "required"
  /\ (pro[c] \/ tokens[c] > 0)
  /\ \E e \in FreshEvent :
       /\ Emit(c, "premium_action", e)
       /\ tokens' = IF pro[c] THEN tokens ELSE [tokens EXCEPT ![c] = @ - 1]
       /\ unauthorizedPremium' = unauthorizedPremium \/ ~(pro[c] \/ tokens[c] > 0)
       /\ UNCHANGED <<version, prompt, pro, unsupportedAction, coreDebited>>

Subscribe(c) ==
  /\ ~pro[c]
  /\ \E e \in FreshEvent :
       /\ pro' = [pro EXCEPT ![c] = TRUE]
       /\ Emit(c, "subscription_started", e)
       /\ UNCHANGED <<version, prompt, tokens, unsupportedAction,
                      unauthorizedPremium, coreDebited>>

RefreshAllowance(c) ==
  /\ tokens[c] < MaxTokens
  /\ tokens' = [tokens EXCEPT ![c] = MaxTokens]
  /\ UNCHANGED <<version, prompt, pro, unsupportedAction,
                  unauthorizedPremium, coreDebited>>
  /\ KeepEvents

ProcessEvent(e) ==
  /\ e \in queued
  /\ queued' = queued \ {e}
  /\ accepted' = accepted \cup {e}
  /\ UNCHANGED <<version, prompt, tokens, pro, issued, eventOwner,
                  eventKind, unsupportedAction, unauthorizedPremium,
                  coreDebited>>

Next ==
  \/ \E c \in Clients : CheckPolicy(c)
  \/ \E c \in Clients : RecordPrompt(c)
  \/ \E c \in Clients : Upgrade(c)
  \/ \E c \in Clients : CoreAction(c)
  \/ \E c \in Clients : PremiumAction(c)
  \/ \E c \in Clients : Subscribe(c)
  \/ \E c \in Clients : RefreshAllowance(c)
  \/ \E e \in EventIds : ProcessEvent(e)

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ version \in [Clients -> Versions]
  /\ prompt \in [Clients -> PromptStates]
  /\ tokens \in [Clients -> 0..MaxTokens]
  /\ pro \in [Clients -> BOOLEAN]
  /\ issued \subseteq EventIds
  /\ queued \subseteq EventIds
  /\ accepted \subseteq EventIds
  /\ eventOwner \in [EventIds -> Clients]
  /\ eventKind \in [EventIds -> EventKinds]
  /\ unsupportedAction \in BOOLEAN
  /\ unauthorizedPremium \in BOOLEAN
  /\ coreDebited \in BOOLEAN

PolicyIsConsistent ==
  \A c \in Clients :
    /\ (prompt[c] = "required" => version[c] < MinimumVersion)
    /\ (prompt[c] = "optional" =>
          version[c] >= MinimumVersion /\ version[c] < LatestVersion)
    /\ (prompt[c] = "none" => version[c] >= LatestVersion)

NoUnsupportedAction == unsupportedAction = FALSE
NoUnauthorizedPremium == unauthorizedPremium = FALSE
CoreRemainsFree == coreDebited = FALSE
TokensNeverNegative == \A c \in Clients : tokens[c] >= 0
ExactlyOnceAccounting ==
  /\ queued \cap accepted = {}
  /\ queued \cup accepted = issued
  /\ \A e \in issued : eventKind[e] # "unused"

RequiredPromptReachable == ~\E c \in Clients : prompt[c] = "required"
OptionalPromptReachable == ~\E c \in Clients : prompt[c] = "optional"
CoreActionReachable == ~\E e \in accepted : eventKind[e] = "core_action"
PremiumActionReachable == ~\E e \in accepted : eventKind[e] = "premium_action"

=============================================================================
