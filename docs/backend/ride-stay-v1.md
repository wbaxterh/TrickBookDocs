---
title: Ride+Stay v1
---

# Ride+Stay v1

## Architecture (lean v1)
- Reuses `spots` collection with embedded `stays[]` on each spot.
- Write operations are auth-guarded.
- Public reads are available for discovery/search.
- Backward compatible: spots without `stays` continue working.

## Spot schema addition
`stays` is optional array on spot documents.

Core stay fields:
- `_id` (string)
- `name` (required)
- `type` (`hotel|hostel|airbnb|campground|lodge|other`)
- `priceLevel` (1..4)
- `nightlyPriceMin`, `nightlyPriceMax`
- `rating`, `reviewCount`
- `distanceKm`
- `bookingUrl`, `imageUrl`
- `address`, `city`, `state`, `country`
- `source`, `sourceConfidence`
- `notes`, `tags[]`
- `createdAt`, `updatedAt`, `createdBy`

## Endpoints
- `GET /api/spots/:spotId/stays`
- `POST /api/spots/:spotId/stays` (auth)
- `PUT /api/spots/:spotId/stays/:stayId` (auth)
- `DELETE /api/spots/:spotId/stays/:stayId` (auth)
- `GET /api/stays/search`

### Idempotent-safe behavior
- `PUT` is deterministic replacement for mutable stay fields by `stayId`.
- `DELETE` returns `{ deleted: boolean, stayId }`; repeated deletes are safe.

## Rollout plan (Skateboarding → Snowboarding → Wakeboarding)

### Phase 1: Skateboarding (seed quality)
- Seed top destination spots with 3-8 stays each.
- Priority: urban/street hubs + famous parks.
- Validate booking links, city/state, distance and type tags.

### Phase 2: Snowboarding
- Focus on resorts already in TrickBook dataset.
- Stays weighted by mountain proximity and shuttle availability.
- Add seasonal notes and confidence score checks.

### Phase 3: Wakeboarding
- Focus cable parks + lake destinations.
- Add campground/lodge-heavy profiles where appropriate.

## Data acquisition strategy
1. Manual curation for top seed spots.
2. Google Places enrichment for nearby lodging.
3. Partner/feed/scrape as secondary with lower default confidence.

## Source confidence model
- `0.90-1.00`: manually verified link + location
- `0.70-0.89`: trusted provider feed with recent timestamp
- `0.50-0.69`: automated enrichment requiring QA pass
- `<0.50`: hidden from default ranking until reviewed

## QA checklist
- Required fields present (`name`, `type`)
- URL validity (`bookingUrl`, `imageUrl` if present)
- City/state/country consistency vs spot
- Distance sanity check (< 200km preferred)
- Duplicate stay detection within spot

## Best examples to seed first
- **Skateboarding:** Burnside (Portland), Venice Beach, LES Coleman, Stoner Plaza
- **Snowboarding:** Mammoth, Park City, Whistler, Breckenridge
- **Wakeboarding:** Orlando Watersports Complex, McCormick’s, Texas Ski Ranch, Terminus Wake Park

## Frontend handoff
See backend contract doc:
- `trickbook-backend/docs/ride-stay-ui-contract-v1.md`
