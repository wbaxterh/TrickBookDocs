---
sidebar_position: 5
title: "ADR-005: Riders Directory and Homie Relationships"
---

# ADR-005: Use Riders as the People Directory and Homies as Relationships

| Field | Value |
|-------|-------|
| **Status** | Accepted (amended September 3, 2026) |
| **Date** | September 2026 |
| **Deciders** | Wes Huber |
| **Supersedes** | The standalone rider-encyclopedia direction in the original ten-profile pilot |
| **Related** | [Rider pilot](/docs/roadmap/rider-encyclopedia-pilot) · [Homies feature](/docs/features/homies) |

## Context

TrickBook already has most of the domains that a broad encyclopedia proposal would introduce: Trickipedia, spots, events, media, user profiles, rider cards, and social connections called homies. The immediate product gap is narrower: notable riders cannot appear in TrickBook unless they create an account.

Building a separate encyclopedia would duplicate existing concepts and create two competing kinds of rider profile. Renaming the social feature itself from "homies" to "riders" at the storage and API layers would create a different problem: a rider is a person, while a homie is a reciprocal relationship between two member riders.

TrickBook needs one people directory that can include both members and notable non-members without implying that a non-member can receive requests, consent to connections, post, or control an editorial biography.

## Decision

Replace **Homies** as the name of the people-discovery destination with **Riders**. Keep **homie** as the member-to-member social relationship.

### Identity types

Every directory entry is a rider with one explicit profile type:

- `member`: connected to an active TrickBook account and eligible for social actions.
- `editorial`: a sourced profile maintained by TrickBook for a notable rider who has not joined or claimed it.
- `ai`: a clearly labeled TrickBook companion or fictional rider.

An editorial rider may later be linked to a verified member account. Claiming links identities; it does not create a second rider or silently replace historical editorial content.

### Social eligibility

Only an active `member` rider can receive an Add Homie request. Editorial and AI riders cannot be added as homies unless a separately documented capability explicitly permits it. The server, not only the interface, must enforce eligibility.

Existing `homies`, `homieRequests`, homie-only visibility values, endpoints, analytics properties, and authorization checks retain their meaning. They are compatibility contracts and are not renamed during the directory refactor.

### Product language and routes

- `/riders` is the canonical people-directory route.
- `/homies` remains a backward-compatible route during migration.
- The primary navigation label is **Riders**.
- **Homies** moves into the authenticated profile dropdown and remains the relationship-management surface.
- **Find Riders** searches the directory.
- **Add Homie**, **Remove Homie**, and **Homie Requests** remain relationship actions.

The directory must visually distinguish member, editorial, and AI profiles. Search and filters may include sport, discipline, location, era, profile type, and membership eligibility.

### Data ownership

Member account and activity data remain in the existing user system. Editorial biography, career facts, citations, and media rights metadata must not be inserted into authentication or private user fields merely to make a rider searchable.

The implementation may begin with a read model that normalizes existing users into directory results. A dedicated rider entity can be introduced when editorial profiles are added, with an optional `accountId` link for members and claimed profiles.

### Graph technology

MongoDB remains the system of record. Neo4j will be introduced incrementally as a derived relationship projection once the first Rider entities and relationships are available. It is not authoritative for accounts, profiles, permissions, or homie mutations.

The initial graph model is:

- `(Rider)-[:HOMIE_WITH]->(Rider)`
- `(Rider)-[:LANDED]->(Trick)`
- `(Rider)-[:RIDES_AT]->(Spot)`
- `(Rider)-[:APPEARS_IN]->(Media)`
- `(Rider)-[:ATTENDED]->(Event)`

Mongo writes append an idempotent event to a MongoDB outbox in the same logical operation. A worker projects those events into Neo4j. Every graph node stores its Mongo identifier as `sourceId`; duplicated biography and media payloads are deliberately avoided. A full rebuild command must be available before Neo4j serves production recommendations.

Neo4j-powered product queries require:

1. substantive rider-to-trick, brand, board, video, spot, or event relationships;
2. named multi-hop product queries or recommendation use cases;
3. enough curated data to evaluate relevance; and
4. an operational plan for synchronization, backups, and failure handling.

Neo4j is an intelligence/read layer rather than a second writer for accounts or homie relationships. Projection lag or failure must degrade graph recommendations, never core profile or Homies functionality.

## Consequences

### Positive

- Solves the original notable-rider gap without rebuilding Trickipedia, spots, events, or media.
- Gives members and non-members one discoverable people surface.
- Preserves "homie" as distinctive TrickBook language where it is semantically accurate.
- Avoids a breaking database and API rename.
- Leaves a clean path to profile claiming and future graph intelligence.

### Negative

- During migration, `/riders` and `/homies` may both resolve to the same interface.
- The interface must explain why some riders cannot be added as homies.
- A later dedicated rider entity will require identity-linking and duplicate-resolution rules.
- Existing analytics dashboards may need aliases so the destination rename does not break trend lines.

### Rejected alternatives

**Standalone encyclopedia:** rejected because it duplicates existing product domains and creates competing rider identities.

**Rename every homie field and endpoint to rider:** rejected because it confuses a person with a social relationship and creates unnecessary migration risk.

**Require every rider to be a user:** rejected because the purpose of the feature is to represent notable riders who have not joined TrickBook.

**Make Neo4j authoritative:** rejected because cross-database writes would make account and social mutations fragile.

## Rollout

1. Add `/riders` and change primary navigation and directory headings from Homies to Riders.
2. Keep `/homies` and all homie APIs working unchanged.
3. Rename directory-only UI language while retaining relationship language.
4. Define the normalized Rider result and `profileType`/social-eligibility contract.
5. Add editorial riders and a protected editorial workflow.
6. Add claim/link verification and duplicate resolution.
7. Add the outbox, projection worker, rebuild command, and concrete recommendation queries on staging.

## Acceptance criteria for the first slice

- Riders is the primary web destination and page title.
- Existing bookmarks to `/homies` still work.
- Homies is available from the authenticated profile dropdown; requests, messages, and Add/Remove Homie behavior are unchanged.
- No database field, endpoint, or visibility migration is required.
- Automated checks cover both routes and the unchanged relationship actions.
