---
sidebar_position: 5
---

# Shops Directory: Build and Inventory Plan

**Status:** Planned<br />
**Planning date:** September 10, 2026<br />
**Initial scope:** Skate, ski/snowboard, surf, and wakeboard shops

## Product Decision

Build shops as a first-class `shops` resource and MongoDB collection. Do not add `shop` as a Spot category.

Spots describe places where riders participate. Shops describe businesses where riders buy, rent, repair, demo, or receive services. The two resources share location, map, image, review, and save behavior, but shops need commerce-specific data, lifecycle rules, source provenance, and a business-claim workflow. Keeping them separate prevents the Spot filters and schemas from accumulating retail-only fields while allowing a shop to reference nearby spots later.

The MVP should answer three rider questions:

1. Which relevant shops are near me or near a destination?
2. Does this shop support my sport and the service I need?
3. Is the listing current enough that I can trust it before visiting?

## Scope and Qualification

### Include

- Independent and chain retailers with a meaningful in-person action-sports offering
- Brand-owned stores and verified authorized dealers
- Skate shops, ski shops, snowboard shops, surf shops, and wakeboard shops
- Hybrid shops serving more than one supported sport
- Seasonal brick-and-mortar shops when their operating season is documented
- Resort or marina retail locations only when they function as a public shop with a distinct identity
- Rental, demo, repair, tuning, boot-fitting, board-shaping, and consignment businesses when tied to an eligible sport

### Exclude from MVP

- Online-only stores, marketplace sellers, and general sporting-goods listings without a verified specialty department
- Manufacturers, distributors, warehouses, private clubs, and schools with no public retail/service counter
- Temporary event vendors and pop-ups without a stable public location
- Permanently closed, unbuilt, or unverifiable businesses
- Duplicate departments or map pins inside the same business unless they have separate public identities and entrances

The canonical classification is multi-select `sportTypes`, not a single shop type. A skate-and-snow shop is one record with two sports.

## Canonical Data Shape

Use GeoJSON as the canonical coordinate representation and retain flat `latitude` and `longitude` only during the migration if existing map components require them.

```js
{
  _id: ObjectId,
  name: String,
  slug: String,
  aliases: [String],
  description: String,

  sportTypes: [
    // skateboarding | skiing | snowboarding | surfing | wakeboarding
  ],
  shopKind: String, // independent | chain | brand_store | resort_shop | marina_shop
  specialties: [String], // decks, hardgoods, apparel, shaping, splitboard, wakesurf...
  services: [
    // retail | rental | demo | repair | tuning | boot_fitting | mounting |
    // board_shaping | lessons_referral | consignment | online_order_pickup
  ],
  brands: [{
    name: String,
    relationship: String, // authorized_dealer | stocked | service_center | unknown
    sourceUrl: String,
    verifiedAt: Date
  }],

  location: { type: 'Point', coordinates: [Number, Number] }, // [longitude, latitude]
  address: {
    line1: String,
    line2: String,
    city: String,
    region: String,
    postalCode: String,
    countryCode: String
  },
  timezone: String, // IANA zone, for example America/Los_Angeles
  serviceArea: String,

  contact: {
    website: String,
    phone: String,
    email: String,
    instagram: String,
    facebook: String
  },
  hours: {
    weekly: [{ day: Number, intervals: [{ open: String, close: String }] }],
    note: String,
    seasonal: Boolean,
    temporarilyClosed: Boolean,
    sourceUrl: String,
    verifiedAt: Date
  },

  images: [{
    url: String,
    storageKey: String,
    alt: String,
    kind: String, // storefront | interior | service | team | logo
    sourceUrl: String,
    rightsBasis: String,
    credit: String,
    isHero: Boolean
  }],

  operationalStatus: String, // operating | seasonal | temporarily_closed | permanently_closed | unknown
  verificationStatus: String, // pending | verified | disputed | rejected
  confidence: Number, // 0-100, derived from evidence rather than manually presented as fact
  lastVerifiedAt: Date,
  nextReviewAt: Date,

  sourceRecords: [{
    sourceType: String, // official_site | brand_locator | osm | google_place_id | directory | social | manual
    sourceName: String,
    sourceId: String,
    sourceUrl: String,
    fieldsSupported: [String],
    observedAt: Date,
    contentHash: String
  }],
  dedupeKeys: [String],
  googlePlaceId: String,
  osmElement: { type: String, id: String },

  claimedBy: ObjectId,
  claimStatus: String, // unclaimed | pending | claimed | revoked
  submittedBy: ObjectId,
  approvedBy: ObjectId,
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

Do not copy Google ratings, reviews, photos, hours, or other Places content into the canonical record as if TrickBook owns it. Google permits Place IDs to be stored, but Places content has caching, display, and attribution restrictions. Store the Place ID and fetch permitted display data at request time behind a provider adapter when the product needs it. See [Google Places policies](https://developers.google.com/maps/documentation/places/web-service/policies) and [Place ID guidance](https://developers.google.com/maps/documentation/places/web-service/place-id).

### Required MVP fields

`name`, at least one `sportTypes` value, `location`, country/city address data, `operationalStatus`, `verificationStatus`, `lastVerifiedAt`, one authoritative or corroborating source record, and a deterministic dedupe key.

### Indexes

```js
db.shops.createIndex({ location: '2dsphere' });
db.shops.createIndex({ slug: 1 }, { unique: true });
db.shops.createIndex({ sportTypes: 1, operationalStatus: 1 });
db.shops.createIndex({ 'address.countryCode': 1, 'address.region': 1, 'address.city': 1 });
db.shops.createIndex({ googlePlaceId: 1 }, { unique: true, sparse: true });
db.shops.createIndex(
  { 'osmElement.type': 1, 'osmElement.id': 1 },
  { unique: true, sparse: true }
);
db.shops.createIndex({ name: 'text', aliases: 'text', specialties: 'text', 'brands.name': 'text' });
db.shops.createIndex({ nextReviewAt: 1, verificationStatus: 1 });
```

## API Plan

Keep public reads separate from authenticated submissions and admin inventory operations.

### Public

- `GET /api/shops` — cursor-paginated list with bounding box, radius, sport, service, status, and text filters
- `GET /api/shops/map-pins` — compact payload for the visible viewport
- `GET /api/shops/search` — name, city, specialty, service, and brand search
- `GET /api/shops/:slugOrId` — detail record plus freshness and attribution
- `GET /api/shops/:id/nearby-spots` — second phase; reuse geospatial Spot queries

Use `bbox` for map movement and `lat`, `lng`, `radius` for “near me.” Cap radius and result counts. Return only projected fields from `map-pins`.

### Authenticated users and claimed businesses

- `POST /api/shops/submissions` — create a pending listing or correction
- `POST /api/shops/:id/save` and `DELETE /api/shops/:id/save`
- `POST /api/shops/:id/claims` — begin claim verification
- `PATCH /api/shops/:id/claimed-profile` — edit business-owned fields through moderation

### Admin and ingestion

- `GET /api/admin/shops/pending`
- `POST /api/admin/shops/bulk-upsert` — idempotent, validated, provenance required
- `PATCH /api/admin/shops/:id/verification`
- `POST /api/admin/shops/:id/merge`
- `POST /api/admin/shops/:id/reverify`

Every write should use Joi validation, field allowlists, normalized URLs/phones, and audit entries. Bulk upsert must support `dryRun: true` and return created, updated, unchanged, rejected, and ambiguous-duplicate counts.

## Discovery and Scraping Strategy

The inventory system should collect leads broadly, then publish narrowly. A source mentioning a shop is evidence, not permission to republish every field or image.

### Source priority

1. **Shop-owned sources:** official website, store page, contact page, structured data, and official social account
2. **Brand dealer locators:** strong evidence for sport and brand relationships; for example, Burton describes its locator as its current authorized-retailer source ([Burton locator guidance](https://www.burton.com/en-us/blogs/the-burton-blog/closest-burton-dealer))
3. **OpenStreetMap extracts:** useful discovery and coordinates under ODbL, with attribution and license review
4. **Trade associations, local tourism/business registries, and reputable specialty directories:** discovery and corroboration
5. **Google Places:** identity matching and live display through the supported API; retain the Place ID, not scraped Google Maps content
6. **Community submissions:** queued for verification, never auto-published

Do not build the inventory by scraping Google Maps pages or copying third-party reviews/photos. Do not treat editorial lists such as “best skate shops” as canonical databases; use them only to discover candidates.

For OSM-scale work, use regional extracts or a controlled data provider rather than systematic Nominatim queries. The public Nominatim service prohibits systematic POI harvesting and heavily restricts scheduled bulk geocoding ([usage policy](https://operations.osmfoundation.org/policies/nominatim/)).

### Sport-specific discovery queries

- Skate: `skate shop`, `skateshop`, `skateboard shop`, brand dealer lists, local skate media, park/shop cross-references
- Ski/snowboard: `ski shop`, `snowboard shop`, `ski rental`, `board shop`, resort town directories, binding/tuning/boot-fitting services, brand dealer locators
- Surf: `surf shop`, `surfboard shop`, `surfboard rental`, shaper/showroom, coastal tourism directories, surf-brand dealer locators
- Wake: `wakeboard shop`, `wakesurf shop`, `watersports dealer`, cable-park pro shop, marina dealer, wake-brand dealer locators

Generic sporting-goods stores require an explicit specialty signal: an official department page, an authorized-dealer relationship, or current hardgoods/service evidence.

### Connector contract

Each connector implements:

```ts
interface ShopSourceConnector {
  id: string;
  discover(scope: GeographicScope, cursor?: string): Promise<RawCandidatePage>;
  normalize(raw: unknown): NormalizedShopCandidate;
  sourcePolicy: {
    license?: string;
    attribution?: string;
    allowedStoredFields: string[];
    refreshCadence: string;
  };
}
```

Store a raw snapshot or content hash only when the source terms allow it. Connector tests should use checked-in redacted fixtures, never depend on a live website in CI.

### Pipeline

1. Select a bounded metro and sport scope.
2. Run connectors and write raw candidates to a staging collection.
3. Normalize names, URLs, phones, addresses, coordinates, sports, services, and brands.
4. Match production records and cluster likely duplicates.
5. Verify qualifying candidates using at least one shop-owned source, or two independent current sources when no official site exists.
6. Review licensing and curate a rights-safe hero image. A record may launch without an image; a weak or unlicensed image is worse than a placeholder.
7. Dry-run the upsert, review the diff, then publish.
8. Audit API output, map placement, source URLs, image URLs, desktop/mobile rendering, and duplicate counts.
9. Checkpoint the metro cursor and schedule a freshness review.

### Dedupe rules

Match in descending confidence:

1. Exact Google Place ID or OSM element ID
2. Exact normalized official domain plus compatible address
3. Exact normalized phone plus compatible city
4. Name similarity plus address/coordinate proximity
5. Manual review for chain branches, resort departments, relocated stores, and aliases

Never auto-merge on name alone. A relocation should preserve the canonical shop identity and history when the official business is continuous; two active branches remain separate records.

### Verification and freshness

- Operating: official site/contact source checked within 180 days
- Seasonal: recheck before its documented opening season
- Temporarily closed or uncertain: recheck within 30 days
- Brand relationships and services: recheck annually or when challenged
- Permanently closed: retain a tombstone and redirect/merge history; hide from default discovery

Confidence is calculated from evidence recency, source authority, cross-source agreement, and field completeness. It must not replace a visible `lastVerifiedAt` date.

## Inventory State

Mirror the proven Spot inventory pattern but use shop-specific state.

```json
{
  "version": 1,
  "activeMetro": "los-angeles",
  "activeSports": ["skateboarding"],
  "cursor": null,
  "counts": {
    "discovered": 0,
    "published": 0,
    "updated": 0,
    "excluded": 0,
    "needsReview": 0
  },
  "candidates": {},
  "sourceRuns": {},
  "lastCheckpointAt": null
}
```

The scheduled job must be idempotent, bounded to one metro/batch per run, and unable to publish when source provenance or required verification is missing. Report direct URLs for every created or changed shop.

## User Experience

### MVP surfaces

- Shops landing page with list/map toggle and “near me”
- Filters for sport and service; optional brand filter after brand data is reliable
- Shop card: name, distance, sports, top services, operational status, hero, and last-verified signal
- Detail page: contact/directions, hours, sports/services, brands with evidence, gallery, source attribution, and “suggest a correction”
- Saved shops

Do not combine Shop and Spot pins by default. Add an explicit map layer toggle after both layers perform well independently.

### Later phases

- Nearby Spots and nearby Events cross-links
- Verified business claims and owner-managed profiles
- Inventory/product availability partnerships
- Deals, demos, shop events, team riders, and community features
- Reviews only after moderation, anti-spam, aggregate-rating, and business-response policies exist

## Delivery Phases

### Phase 0 — Contract and policy spike

- Confirm source permissions, attribution, and data-retention rules
- Sample 50 shops across all four verticals and at least three metros
- Validate taxonomy, false-positive rate, dedupe rules, and available service/brand evidence
- Produce fixtures before building a large scraper

**Exit:** at least 90% of the sample can be correctly included/excluded and deduplicated, with every canonical field tied to an allowed source.

### Phase 1 — Backend foundation

- `shops`, `shop_submissions`, `shop_claims`, and `shop_audit_log` collections
- Validation, indexes, public list/detail/map APIs, admin bulk dry-run/upsert, merge, and verification routes
- Unit/integration tests for validation, geo queries, projections, auth, idempotency, and merges

### Phase 2 — Inventory pilot

- Pilot Los Angeles skate shops first: the domain is easy to evaluate and complements the current LA/Spot work
- Add official-site, OSM-extract, and selected brand-locator connectors
- Run the full verify, image-rights, dry-run, publish, and render-audit workflow
- Measure precision, duplicate rate, research time per published shop, and stale-source rate

**Exit:** 95%+ precision in a manually audited pilot and zero unresolved high-confidence duplicates.

### Phase 3 — Product MVP

- Website and mobile list/map/detail views
- Sport/service filters, directions, saves, freshness, attribution, correction submissions, analytics, and empty/error states
- Feature flag and staged rollout

### Phase 4 — Geographic and sport expansion

- Expand skate metro by metro
- Add ski/snowboard in resort metros, surf in coastal metros, and wake around cable parks/lakes
- Tune source packs independently; do not assume skate discovery sources work for snow, surf, or wake

### Phase 5 — Claims and monetization

- Verify owners by domain email, DNS/file challenge, official social confirmation, or manual documents
- Separate factual corrections from promotional profile content
- Define free versus paid features without selling ranking in organic results

## Analytics and Acceptance Criteria

Instrument `shops_view`, `shops_search`, `shops_filter`, `shop_open`, `shop_directions`, `shop_website`, `shop_phone`, `shop_save`, and `shop_correction_submit`.

MVP acceptance requires:

- Geo queries use the `2dsphere` index and have bounded response sizes
- Public APIs never expose admin notes, submitter details, or raw source snapshots
- Every published record has provenance and `lastVerifiedAt`
- Re-running an unchanged source batch creates no duplicate or material update
- Closed and duplicate records are removed from default discovery without erasing audit history
- Map/detail pages pass desktop and mobile render checks with no broken images or console errors
- Google/OSM/provider attribution and storage behavior pass a documented policy review
- Accessibility includes keyboard navigation, labeled controls, non-color status cues, and descriptive image alt text

## Recommended First Build Slice

The smallest end-to-end slice is **verified Los Angeles skate shops**: schema and indexes, public list/detail/map routes, admin dry-run/upsert, one bounded inventory state file, official-site plus OSM discovery, manual verification, and a web read-only UI behind a feature flag. Do not start with global multi-sport scraping. Prove precision, provenance, dedupe, and freshness in one vertical and metro, then reuse the pipeline.

## Related Documentation

- [Spots](/docs/features/spots)
- [Spots Inventory Automation](/docs/features/spots-inventory-automation)
- [Events](/docs/features/events)
- [Backend API](/docs/backend/api-endpoints)
- [Database](/docs/backend/database)
