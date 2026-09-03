---
title: Riders
---

# Riders

Riders is TrickBook's public people directory. It is a top-level destination; Homies remains the signed-in relationship manager under the profile menu.

## First staging slice

- `/riders` lists opted-in member riders from MongoDB.
- Search covers public name, nickname, biography, and profile location/nationality text.
- Sport filtering and pagination are server-side.
- API responses use an explicit public projection and never expose email, password, reset, provider, or private account data.
- `/homies` and existing relationship APIs remain unchanged.

The first slice normalizes existing member accounts. Editorial and claimed profiles come next and will use an explicit `profileType` rather than fake login accounts.

## Data ownership

MongoDB owns Rider identity, public profile content, visibility, and relationship mutations. Neo4j receives a rebuildable projection for multi-hop discovery and recommendations. See [ADR-005](/docs/architecture/adrs/riders-directory).

## Staging acceptance

- Riders appears in primary navigation.
- Homies appears in the authenticated profile dropdown and no longer occupies a primary navigation slot.
- Anonymous visitors can browse only opted-in riders.
- Search, sport filtering, empty state, pagination, and profile links work.
- Staging uses its own MongoDB database and API origin.
- Production is unchanged until a staging-to-production promotion PR passes checks and manual QA.
