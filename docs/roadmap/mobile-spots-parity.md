---
sidebar_position: 11
---

# Mobile Spots Feature Parity

The website's Spots experience and backend capabilities are ahead of mobile. This gap must be closed as a dedicated roadmap item rather than incidentally during Events development.

## Problem

Web includes richer discovery, filtering, map data, spot details, resort information, lodging, photos, videos, reviews, saved spots, lists, and enrichment. Mobile documentation and implementation evolved separately, creating uncertainty about consistent fields and actions.

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

## Suggested Delivery

1. Audit and publish the parity matrix.
2. Resolve API contract drift and deprecated fields.
3. Implement missing browse, map, and filters.
4. Implement missing detail sections.
5. Add Event-to-Spot deep linking.
6. Test iOS and Android using real multi-sport production records.

Complete this before native Events exits beta. The responsive web Events MVP does not need to wait.

