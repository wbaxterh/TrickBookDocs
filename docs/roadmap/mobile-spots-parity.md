---
sidebar_position: 11
---

# Mobile Spots Feature Parity

The website's Spots experience and backend capabilities are ahead of mobile. This gap must be closed as a dedicated roadmap item rather than incidentally during Events development.

## Problem

Web includes richer discovery, filtering, map data, spot details, resort information, lodging, photos, videos, reviews, saved spots, lists, and enrichment. Mobile documentation and implementation evolved separately, creating uncertainty about consistent fields and actions.

The current mobile Spots map is also harder to use than it should be. Improving map usability on a phone is a product requirement, not just a web/mobile parity task: users must be able to discover, inspect, and act on spots without fighting overlapping controls, cramped spot previews, or disruptive map movement.

Events increases the importance of venue behavior because event records link to Spots. Mobile needs a coherent Spot detail and navigation experience before native Events is complete.

## Required Audit

Build a matrix across backend, web, iOS, and Android for:

- Sport, category, park type, tags, and skill level
- Address, coordinates, country, state/region, and locality
- Map pins, bounds, nearby search, and radius search
- Images, ordering, carousels, attribution, and reports
- Videos and embedded media
- Ratings and reviews
- Resort facts, terrain, lifts, snow, and lodging
- Save/unsave and custom lists
- User submissions and approval status
- Spot-linked tricks and feed posts
- Sharing, deep links, and external navigation
- Offline, loading, error, and empty states
- Event venue links and upcoming events

## Target Outcome

- One shared API contract with runtime validation
- Explicit platform support status for every field and action
- Mobile browse, map, filters, and details matching web's core value
- Correct location permissions and privacy behavior
- Event/Spot deep links
- Regression coverage for critical flows

## Mobile Map Usability Requirements

- Keep the map as the primary surface, with search, filters, recenter, and map/list switching reachable one-handed and clear of the platform safe areas.
- Make pins easy to select with touch-sized hit targets, visible selected states, sensible clustering, and predictable zoom behavior.
- Show a compact spot preview after pin selection without obscuring most of the map; let users expand it into full spot details.
- Preserve the user's viewport, selected spot, and active filters when moving between the map, list, and spot details.
- Avoid automatic recentering after the user pans or zooms; provide an explicit way to search the visible area.
- Handle location permission denial, loading, no-results, and network failures without blocking manual map browsing.
- Validate the flow on representative small and large iOS and Android devices, including one-handed use and screen-reader labels.

## Suggested Delivery

1. Audit and publish the parity matrix.
2. Resolve API contract drift and deprecated fields.
3. Implement missing browse, map, and filters.
4. Implement missing detail sections.
5. Add Event-to-Spot deep linking.
6. Test iOS and Android using real multi-sport production records.

Complete this before native Events exits beta. The responsive web Events MVP does not need to wait.

