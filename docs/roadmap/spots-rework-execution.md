---
title: Spots Rework â€” Execution Plan
sidebar_position: 13
---

# Spots Rework â€” Execution Plan

Status: **Ready to start** Â· Owner: Web + Backend Â· Created: 2026-11-04

This is the **work-breakdown** for the [Spots Map Performance Rework](/docs/roadmap/spots-map-performance). That doc is the *why* and the target architecture; this doc is the *what to do, in what order, and how to know it's done*. Every ticket below names the files it touches, its dependencies, and its exit gate.

For the full feature surface these changes sit on top of, see [Spots Map](/docs/features/spots-map).

## Guiding constraints

- **Keep Google Maps and the current UX.** This is a data-loading rework, not a redesign.
- **Mobile already does viewport loading** (`getMapPins` on `idle`, ~350 ms debounce). The shared `map-pins` response contract must evolve **without regressing** mobile â€” especially the physical-iOS crash suite (5.3 in the feature doc).
- **Ship behind a feature flag.** No phase may require a redeploy to roll back.
- **Measure before and after every phase.** A phase isn't "done" until its exit metric is recorded.

## Ticket board

### Phase 0 â€” Baseline & safety (do first, blocks everything)

| ID | Ticket | Files | Exit |
|---|---|---|---|
| P0-1 | Add request telemetry to `map-pins`: timing, payload bytes, result count, zoom, cache status | `Backend/routes/spots.js` | Logs emit structured timing per request |
| P0-2 | Add client `spots_map_ready_ms` + per-request timing | `components/SpotsMap.js` (web), mobile map hook | Dashboard shows map-ready + request latency |
| P0-3 | Capture production baseline: p50/p95 latency, payload size, docs-examined/returned, error rate | â€” (measurement) | Baseline numbers recorded in this doc |
| P0-4 | Verify coordinate schema + index with read-only `explain("executionStats")` | prod Mongo (read-only) | Query plan + index coverage documented |
| P0-5 | Add `spotsViewportLoading` feature flag (web) | web config / env | Flag toggles new path without redeploy |

**Gate:** baseline dashboard exists; rollback is flag-only.

### Phase 1 â€” Stop the duplicate global fetch (biggest single win)

| ID | Ticket | Files | Exit |
|---|---|---|---|
| P1-1 | Do **not** call `getSpotsByState()` while map view is active | `pages/spots.js` | No `/api/spots?limit=5000` on default map load |
| P1-2 | Lazy-load list data only when `viewMode === "list"` | `pages/spots.js`, `lib/apiSpots.js` | List fetch fires on list-toggle only |
| P1-3 | Remove the `/spots?limit=5000` map fallback; replace with retry/error UI | `components/SpotsMap.js` | A failed map request shows retry, never a global download |
| P1-4 | Add compression + `Cache-Control`/`ETag` to the existing pin endpoint (interim) | `Backend/routes/spots.js` | Responses are gzipped + conditionally cacheable |

**Gate:** default `/spots` makes **zero** `limit=5000` requests. Re-measure P0 metrics â€” expect the ~13.7 MB request gone from the default path.

### Phase 2 â€” Viewport-first web map

| ID | Ticket | Files | Exit |
|---|---|---|---|
| P2-1 | Version + extend `map-pins` contract: `minLat/maxLat/minLng/maxLng/zoom/sportType/category/country`, typed `{type:"pins", dataVersion, items[]}` envelope | `Backend/routes/spots.js` | Contract documented in [API Endpoints](/docs/backend/api-endpoints); mobile unaffected |
| P2-2 | Indexed geospatial query + **minimal projection** (id, name, lat, lng, category, sportTypes); filters applied in DB | `Backend/routes/spots.js` | No full records; filters are server-side |
| P2-3 | Enforce bounds/zoom/coord validation, max-pin ceiling, bounded query timeout | `Backend/routes/spots.js` | Invalid input rejected; ceiling enforced |
| P2-4 | Wire web map to Google Maps `idle` â†’ fetch current bounds/zoom | `components/SpotsMap.js` | Pins re-query on pan/zoom |
| P2-5 | Debounce 200â€“300 ms, `AbortController` cancel, stale-response sequence guard, keep-old-markers-during-load | `components/SpotsMap.js` | Rapid pan/zoom never shows stale markers |
| P2-6 | Integration tests: filters, empty bounds, invalid input, **antimeridian**, rapid pan/zoom | backend + web test suites | Suite green |

**Gate:** normal viewport responses **< 200 KB compressed**; stale markers cannot win a race.

### Phase 3 â€” Low-zoom aggregation & caching

| ID | Ticket | Files | Exit |
|---|---|---|---|
| P3-1 | Return `{type:"clusters", items:[{id,lat,lng,count}]}` below a chosen zoom threshold | `Backend/routes/spots.js` | World/country zoom returns clusters, not raw pins |
| P3-2 | Short application cache keyed by normalized bounds/zoom/filters | `Backend/routes/spots.js` | Repeat viewport requests are cheap |
| P3-3 | Version/invalidate cache when approved coords or filterable fields change | spot approve/edit paths | Edits reflect without rebuilding the world |
| P3-4 | Make conditional `304` handling skip expensive query/serialize work | `Backend/routes/spots.js` | Cached hits avoid full re-query |

**Gate:** world/country responses **< 300 KB compressed** and stay fast as the catalog grows.

### Phase 4 â€” Scale review (only if measured need)

Evaluate H3 aggregation or vector tiles **only** when the viewport API stops meeting targets (p95, payload, catalog growth, or dynamic-bbox query cost). Not required for the initial rework. Track the trigger metrics from P0/P2/P3 and open this phase only when one breaches target.

## Dependency order

```
P0 (all) â”€â–¶ P1 â”€â–¶ P2 â”€â–¶ P3 â”€â–¶ (P4 only if triggered)
```

P1 is independently shippable and delivers most of the user-visible win. P2 depends on the P0 index verification. P3 depends on the P2 contract.

## Acceptance criteria (rolled up from the rework plan)

- Default `/spots` does not request `/api/spots?limit=5000`.
- No map response contains full spot records.
- Initial useful map within **1.5 s at p75** on mid-tier mobile.
- City/region map API **< 500 ms at p95**.
- Viewport payloads **< 200 KB**; world view **< 300 KB** via clusters.
- Rapid pan/zoom never shows stale markers.
- Sport/category/country/approval/cluster counts remain correct.
- Marker selection still opens the correct spot.
- Failures show retry UI; never a global catalog download.
- **Mobile physical-iOS crash regression suite stays green.**

## Baseline measurements (fill in during P0)

| Metric | Baseline (pre-rework) | Target |
|---|---|---|
| `/spots` default payload | ~19 MB (13.7 + 5.2) | â€” |
| `map-pins` p95 latency | _tbd_ | < 500 ms |
| Viewport payload (city) | n/a (global) | < 200 KB |
| World payload | ~5.2 MB | < 300 KB |
| Map-ready p75 (mobile) | _tbd_ | < 1.5 s |
| Docs examined/returned | _tbd_ | near 1:1 |

## Related documentation

- [Spots Map Performance Rework](/docs/roadmap/spots-map-performance) â€” architecture & rationale
- [Spots Map](/docs/features/spots-map) â€” full feature surface, QA/crash suite
- [Spots](/docs/features/spots) â€” parent feature
- [Backend API Endpoints](/docs/backend/api-endpoints) â€” `map-pins` contract
