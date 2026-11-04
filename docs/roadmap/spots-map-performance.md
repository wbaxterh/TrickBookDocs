---
title: Spots Map Performance Rework
sidebar_position: 12
---

# Spots Map Performance Rework

Status: **Planned** Â· Owner: Web + Backend Â· Research baseline: 2026-10-30

## Outcome

The map should become useful before the worldwide catalog finishes loading. Riders should receive only the spots relevant to the visible map, with progressively more detail as they zoom, pan, or select a pin.

This plan keeps Google Maps and the current Spots UX. It changes how map and list data are requested, bounded, cached, and rendered.

## Why this work is needed

A production audit found that Amplify and the Next.js shell were not the main bottlenecks:

- `/spots` first contentful paint was about **0.62 seconds** and page load completed in about **0.70 seconds**.
- `GET /api/spots?limit=5000` returned about **13.7 MB** and took about **4.5 seconds** end to end.
- `GET /api/spots/map-pins` returned about **5.2 MB** and took about **3.5 seconds** end to end.
- The default web map initiated both requests, sending nearly **19 MB of overlapping data** before marker creation.
- Cached `304` responses still took about **1.3â€“1.4 seconds**, indicating expensive backend work occurred before cache validation.

The immediate issue is therefore global, duplicate data loadingâ€”not the hosting platform.

## Research conclusions

Large map products converge on a few patterns:

1. **Query the visible viewport.** Map bounds become part of the search request.
2. **Aggregate at low zoom.** Return clusters or coarse cells, then reveal pins as the rider zooms in.
3. **Keep pin payloads minimal.** Load full descriptions, media, reviews, and other detail only after selection.
4. **Debounce and cancel movement requests.** An older viewport response must never replace a newer one.
5. **Cache by spatial key.** Normalized bounds, zoom, and filters produce reusable responses.
6. **Adopt H3 or vector tiles only when measurements justify them.** They are scale tools, not the first fix.

Reference implementations and guidance:

- [Airbnb: Improving Search Ranking for Maps](https://airbnb.tech/ai-ml/improving-search-ranking-for-maps/)
- [Google Maps marker clustering](https://developers.google.com/maps/documentation/javascript/marker-clustering)
- [Uber H3](https://github.com/uber/h3)
- [Mapbox performance guidance](https://docs.mapbox.com/help/troubleshooting/mapbox-gl-js-performance/)
- [MongoDB geospatial queries](https://www.mongodb.com/docs/manual/geospatial-queries/)

## Target architecture

### Map request

```http
GET /api/spots/map-pins?minLat=32.7&maxLat=33.1&minLng=-117.4&maxLng=-116.9&zoom=11&sportType=skateboarding&category=park
```

At city/street zoom, return a lightweight pin envelope:

```json
{
  "type": "pins",
  "dataVersion": "2026-10-30T21:00:00Z",
  "items": [
    {
      "id": "spot-id",
      "name": "Spot name",
      "lat": 32.9,
      "lng": -117.2,
      "category": "park",
      "sportTypes": ["skateboarding"]
    }
  ]
}
```

At world/country zoom, return server-generated clusters:

```json
{
  "type": "clusters",
  "items": [
    { "id": "spatial-cell", "lat": 39.5, "lng": -98.3, "count": 184 }
  ]
}
```

### Backend rules

- Validate all coordinates, bounds, zoom, and filter values.
- Apply `approvalStatus: approved`, sport, category, and country filters in MongoDB.
- Project only fields required to render and filter pins.
- Enforce a maximum pin count and bounded query timeout.
- Preserve antimeridian behavior.
- Verify the production query plan and documents-examined ratio. Use GeoJSON + `2dsphere` if it materially improves the measured plan; do not migrate schema on assumption alone.
- Return `Cache-Control` plus `ETag` or `Last-Modified`, and make conditional responses cheap.
- Cache normalized bounds/zoom/filter keys for a short period.

### Web behavior

- Fetch after Google Maps `idle`, using current bounds and zoom.
- Debounce movement by **200â€“300 ms**.
- Abort the previous request with `AbortController` and reject stale responses by sequence number.
- Keep current markers visible during refresh and show a subtle loading state.
- Send filters to the API instead of filtering a global catalog in the browser.
- Fetch full spot detail only after selection.
- Load list data only when list view opens, using paginated/grouped endpoints.
- Remove the `/spots?limit=5000` fallback. Fail with a bounded retry state instead.

Mobile already uses viewport requests. Its marker-layer crash safeguards and physical-iOS regression suite remain unchanged; the shared response contract must not regress them.

## Delivery plan

### Phase 0 â€” Baseline and rollout safety

- Add request timing, payload size, result count, zoom, cache status, and client map-ready telemetry.
- Record p50/p95 latency, documents examined/returned, and current error rate.
- Confirm production coordinate schema and indexes with a read-only query plan.
- Add a feature flag for the new web loading path.

**Exit:** Baseline dashboard exists and rollback can occur without redeployment.

### Phase 1 â€” Remove duplicate global loading

- Do not call the 5,000-record list request while map view is active.
- Lazy-load list data after the rider switches to list view.
- Replace the full-catalog fallback with retry/error UI.
- Add compression and cache headers to the current pin endpoint.

**Exit:** Default `/spots` makes no `/api/spots?limit=5000` request.

### Phase 2 â€” Viewport-first web map

- Extend and version the `map-pins` contract for bounds, zoom, and filters.
- Enforce minimal projection, validation, and result ceilings.
- Wire map `idle` to debounce, cancellation, and stale-response protection.
- Add integration coverage for filters, empty bounds, invalid input, antimeridian crossing, and rapid pan/zoom.

**Exit:** Normal viewport responses are under **200 KB compressed** and stale markers cannot win a race.

### Phase 3 â€” Low-zoom aggregation and caching

- Return server-side clusters below the chosen zoom threshold.
- Cache normalized spatial responses.
- Version or invalidate cached results when approved coordinates or filterable fields change.
- Make conditional `304` handling avoid expensive query/serialization work where possible.

**Exit:** World/country responses remain under **300 KB compressed** as the catalog grows.

### Phase 4 â€” Scale review, only if required

Evaluate H3 aggregation or vector tiles when measured p95 latency, payload size, catalog growth, or traffic exceeds the viewport API targets. This phase is explicitly not required for the initial rework.

## Acceptance criteria

- Default `/spots` does not request `/api/spots?limit=5000`.
- No map response contains full spot records.
- Initial useful map appears within **1.5 seconds at p75** on a mid-tier mobile connection/device.
- Ordinary city/region map API latency is below **500 ms at p95**.
- Typical compressed viewport responses are below **200 KB**; world view remains below **300 KB** using clusters.
- Rapid pan/zoom never displays markers from a stale request.
- Sport, category, country, approval status, and cluster counts remain correct.
- Selecting a pin still opens the correct spot.
- Failures show retry UI and never trigger a global catalog download.
- Existing mobile physical-iOS crash regression tests remain green.

## Observability

Track:

- `spots_map_ready_ms`
- `spots_map_request_ms`
- response bytes, result type/count, zoom, and cache status
- cancellation, timeout, and error rate
- time to first pin selection and pin selection rate
- map-to-list switch rate and list endpoint latency
- backend p50/p95/p99 and documents-examined/returned ratio

The product signal is whether riders reach and select a relevant spot faster. Infrastructure metrics support that outcome; they do not replace it.

## Rollout and rollback

Ship the web path behind a temporary feature flag, then ramp while comparing map-ready time, errors, payloads, and selection behavior. If the new path fails, disable it and show the bounded retry state. Do **not** restore the 5,000-full-record fallback.

## Related documentation

- [Spots Rework â€” Execution Plan](/docs/roadmap/spots-rework-execution) â€” ticket-level work breakdown for this plan
- [Spots Map](/docs/features/spots-map)
- [Spots](/docs/features/spots)
- [Backend API Endpoints](/docs/backend/api-endpoints)
