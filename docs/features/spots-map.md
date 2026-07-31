---
sidebar_position: 3
title: Spots Map
---

# Spots Map

The interactive map that lets riders **explore, add, tag, and save** action-sports spots — the primary discovery surface of the [Spots](/docs/features/spots) feature.

Status: **✅ Live** · Last updated: 2026-07-11

This page is the source of truth for the Spots **Map** specifically — the map UI on both mobile and web, the flows that hang off it, the deliberate UX/architecture decisions behind the mobile map (which is unusual for a good reason), the backend that powers it, and the QA plan that keeps it from crashing. For the broader Spots feature (schema, list/detail pages, ratings, resort UI, Chrome Extension), see [Spots](/docs/features/spots).

:::tip[Related surfaces]
- [Spots](/docs/features/spots) — parent feature: browse/list, spot detail, ratings, resort info, Chrome Extension bulk import.
- [Media](/docs/features/media) — the feed/upload surface where a spot gets tagged onto a video or post.
- [AI Companions](/docs/features/ai-companions) — Kaori can search spots and submit spot drafts (admin-reviewed) via chat tools.
- [Kaori AI Architecture](/docs/architecture/kaori) — background on the React Native New Architecture / Reanimated 4 constraints that also shape this map.
:::

---

## 1. Product overview

### What it is

The Spots Map is a full-screen, pannable, zoomable map of every **approved** spot in TrickBook. Riders open it to answer one question fast: **"what can I skate/ride near here (or near there)?"** Pins are colored by category, cluster when zoomed out, and expand as you zoom in. Tapping a pin surfaces a card; from there you go to the spot's detail page, get directions, or save it.

The map is not just a viewer. It is the hub for the whole spot lifecycle:

- **Explore** approved spots (the primary use case).
- **Search** spots and real-world places in one field.
- **Add** a new spot by dropping a pin or searching a place.
- **Edit** a spot you own.
- **Tag** a spot onto a video/post so your content is tied to a location.
- **Save** spots to "My Spots" (one-tap) or to named Collections.
- **Contribute and moderate photos** community-style (Google-Maps model).

### Why it exists

Discovery is the top of the funnel for the whole app. A rider who can instantly see nearby spots is a rider who films, tags, saves, and comes back. Before the map, spots were only reachable through hierarchical country → state → list browsing, which is great for planning a trip but poor for "I'm standing here, what's around me." The map closes that gap and doubles as the on-ramp for user-generated content and the community photo library.

### Platform matrix — what's available where

| Capability | Mobile (React Native / Expo) | Web (Next.js) |
|---|---|---|
| Interactive map of approved spots | ✅ Live | ✅ Live |
| Map technology | Google map base + **projected RN-View overlay markers** (custom) | Real **Google Maps JS SDK** markers (`@vis.gl/react-google-maps`) |
| Clustering | ✅ `supercluster` (JS, 50/18/3) | ✅ `@googlemaps/markerclusterer` |
| Filter by sport / category | ✅ Live (in-map Filter) | ✅ Live (Category dropdown) |
| Filter by country | 🚧 Via list, not the map | ✅ Live (Country dropdown) |
| In-map unified search (spots + Google Places) | ✅ Live | 🚧 Not on the map (list/state pages have text search) |
| Center-on-me button | ✅ Live | 📋 Planned |
| Fullscreen immersive map | ✅ Live | 🚧 Map is already the page; no separate mode |
| Tap pin → card | ✅ Overlay card (fly-to) | ✅ Google `InfoWindow` card |
| List view (country → state → spot) | ✅ Live (List toggle) | ✅ Live (List toggle) |
| Add a spot | ✅ Drop-pin / search-a-place | ✅ Lat-lng or paste Google Maps URL |
| Edit a spot (owner) | ✅ Live (detail Edit) | ✅ Admin form (`/admin/create-spot`); owners via API |
| Tag a spot on a post | ✅ Live (upload picker) | ✅ Live (upload picker) |
| Clickable spot chip on the post | 🚧 See known issues | 🚧 Plain text, not linked |
| One-tap save + long-press list picker | ✅ Live | 🚧 "Add to My Lists" links to `/my-spots` |
| Named Collections (Spot Lists) | ✅ Live | ✅ Live (`/my-spots`) |
| Contribute photos (gallery/camera) | ✅ Live | 🚧 Image URL only on public add form |
| Report a photo (auto-hide at 3) | ✅ Live | 🚧 Backend supports it; web UI not wired |
| Submit a trick to a spot's history | 🚧 Not on map surface | ✅ Live (spot detail) |

:::note[Mobile and web are deliberately different map stacks]
The web map uses the ordinary Google Maps JavaScript SDK. The **mobile** map uses a custom projected-overlay marker system that looks over-engineered until you know it exists to dodge a native crash under React Native's New Architecture. Section 3 explains exactly why. The two stacks share the **same backend** (Section 4), so the data model is identical.
:::

---

## 2. Use cases — step-by-step (mobile and web)

### 2a. Explore the map (the primary use case)

This is the flow that matters most. Get it right and everything else follows.

**Mobile**

1. Open the **Spots** tab → the **All Spots Map** loads centered near you (location permission requested on first use).
2. Pins load for the current viewport only — as you pan/zoom, the app re-queries `GET /map-pins` for the new bounding box (debounced ~350 ms).
3. **Zoom with pinch only.** There are intentionally **no `+`/`–` buttons** (see Section 3). Pinch out to see clusters, pinch in to break them apart.
4. **Tap a cluster** to expand/zoom into it; **tap a single pin** to select it (a card appears and the map flies to it); **tap the background** to deselect.
5. Use the control cluster on the map:
   - **Filter** — pick a sport and/or category; pins re-query filtered.
   - **Center** — recenter on your current location.
   - **Search** — opens the unified spots + Google Places search (see 2a-search).
   - **Fullscreen** — immersive edge-to-edge map (see Section 3).
   - **List** — switch to the country → state → spot list view.

**Mobile — in-map search**

1. Tap the **magnifying-glass** control → a full-screen search panel opens.
2. Type a query. Two result groups return in parallel: **Spots** (`searchSpots`) and **Google Places** (`searchPlaces`, biased to the current viewport).
3. Tap a **Spot** result → the map flies to it **and** shows its card.
4. Tap a **Place** result → the map just flies there (it's a real-world location, not necessarily a spot). This is the on-ramp to *adding* a spot at that place.

**Web**

1. Go to **`/spots`** — it defaults to **Map** view. The Google Maps JS map loads **all approved pins** clustered worldwide (fetched once from `/spots/map-pins`, with a fallback to `/spots?limit=5000` if that 404s).
2. Filter with the **Category** dropdown (10 sports) and/or the **Country** dropdown. Filtering is **client-side** over the already-loaded pins, so it's instant. (Category matching is dual-keyed: it matches either the spot's single `category` field or membership in its `sportTypes` array.)
3. **Click a pin** → a Google Maps **InfoWindow** card opens showing name, state/country, star rating, a category color chip, sport types, and a 2-line description clamp.
4. Click **"View Details →"** → the spot detail page at `/spots/{state}/{spotSlug}?id={id}`.
5. The footer under the map shows a **"`{n}` spots worldwide"** count and a category color legend (park=green, street=amber, indoor=blue, diy=red, other=purple).

:::note[Web loads everything, mobile loads the viewport]
Web fetches all pins once and filters/clusters client-side. Mobile fetches only what's in the current viewport and re-queries on pan/zoom. Both are correct for their platform, but note the web behavior means very large datasets can produce a large single payload — see Known Issues.
:::

### 2b. Add a spot (including photos)

**Mobile**

1. On the map, tap **`+`**.
2. Set the location one of two ways: **drop a pin** on the map, or **search a place** and pick it.
3. Tap **Continue** → the details form.
4. Fill in **name**, **category**, **sport types**, and **Public / Private**.
5. Add **photos** — pick from **Gallery** or take one with the **Camera** (permissions requested as needed). The **first photo becomes the cover**.
6. **Submit** (Public → enters the admin review queue as `pending`) or **Save** (Private → stays yours, `private`).
   - Under the hood: `createSpot` runs first, then each photo is sent via `uploadSpotPhoto`.

**Web**

1. On `/spots`, click **Add Spot** (logged-out users are redirected to `/login?redirect=/spots/add`).
2. On `/spots/add`, set coordinates either by **entering lat/lng manually** or by **pasting a Google Maps URL** and clicking Parse — the URL is regex-parsed for coordinates and the city/state are reverse-geocoded via Nominatim/OpenStreetMap.
3. Fill in **name**, **description**, **tags**, and an **image URL**.
4. Check **"Submit for public listing"** to send it to admin review (`pending`), or leave it unchecked to keep it **private**.
5. Submit → on success you're redirected to the new spot's detail page.

:::warning[Web add-spot takes an image URL, not file uploads]
The public web add form (`/spots/add`) accepts a single **image URL** string, not uploaded photo files. Multi-photo contribution with gallery/camera is a **mobile-only** capability today. The web detail-page carousel is populated from `spot.images` / Google photos, not from a web file-upload path.
:::

### 2c. Edit a spot (owner)

**Mobile**

- Open the spot's detail page. If you're the owner, an **Edit** (and **Delete**) action appears. Edit patches the spot in place (name, location, category, sport types, description, etc.); Delete also removes the spot's photos from storage and pulls it out of every Collection.

**Web**

- Owners edit via the API (`PUT /spots/:id`, owner-or-admin). The **admin** UI at `/admin/create-spot?isEdit&spotId=...` provides a full CRUD edit form and additionally lets admins set a numeric **rating** (a field not exposed in the public add form). Admins also run the approval queue at `/admin/pending-spots` and manage everything at `/admin/spots`.

### 2d. Tag a spot in a video/post (+ the spot chip)

**Mobile**

1. Go to **Upload** (media).
2. In the composer, use **Tag a spot** → a `searchSpots` picker.
3. Select a spot → its `spotId` is attached to the post.

**Web**

1. Go to `/media/feed/upload`, choose a video/image.
2. Use the **spot search field** to find and select a spot.
3. The chosen `spotId` is included in the upload payload.

**The spot chip.** Once tagged, the backend batch-enriches the spot (name, city, state, image, category) onto the post **everywhere** it appears (feed lists, profile, single-post view) — not just on the single-post page. On the web feed, the tagged location currently renders as **plain text** under the poster's name (`post.location?.name`), **not** a link to the spot page. Making the chip clickable (like trick tags are) is a tracked follow-up. See [Media](/docs/features/media).

### 2e. Save / collect spots ("My Spots")

TrickBook uses a **flat "My Spots"** model: the things you **created** and the things you **saved** live together, with named **Collections** behind a toggle.

**Mobile — one-tap save**

1. On any spot (card or detail), tap the **bookmark** → the spot is saved instantly (optimistic) to your default **Saved Spots** bucket. Tap again to unsave.
2. **Long-press** the bookmark → a **list picker** to add the spot to a **named Collection**.
3. View saved/created spots under **My Spots** (buckets: **Mine** = `getMySpots`, **Saved** = `getSavedSpots`) or open a **Collection** (named `SpotList`).

**Web**

- On a spot detail page, the **"Add to My Lists"** button (logged-in only) links to **`/my-spots`**, which manages your Spot Lists (named collections). One-tap save from a map pin is a mobile-first affordance.

:::note[One-tap save is intentionally frictionless]
Saving writes to a **hidden per-user default list** (`isDefaultSaved: true`) that's excluded from the normal Collections view and has **no free-tier limit** — unlike named Collections, which enforce subscription limits. This keeps "save this, I'll come back" a zero-friction gesture. See Section 3 and Section 4.
:::

### 2f. Contribute and report photos (community model)

The photo system follows the **Google Maps model**: photos are **public immediately**, and the community moderates.

**Contribute (mobile)**

1. On a spot's detail page, the gallery combines **user photos** and **Google photos**.
2. Any logged-in user taps **Add Photo** → choose **Gallery** or **Camera** → the photo uploads and appears right away.

**Report / moderate (mobile)**

1. **Long-press** a **user** photo → **Report** or (if it's yours / you're admin) **Delete**. Google photos are read-only.
2. Reporting is idempotent per user (each distinct reporter counts once).
3. At **3 distinct reports**, the photo **auto-hides** and is filtered out of all public responses. Admins can still hard-delete.

**Web** — the backend fully supports the photo model, but the web UI for uploading files and reporting is **not wired up** yet; the web detail page shows the existing photo carousel read-only.

---

## 3. UX / UI decisions (mobile) — with rationale

The mobile map's architecture is unusual. Every choice below traces back to a hard constraint. Read this before changing anything on the map.

### The projected-overlay marker architecture — and why

**Decision:** The main map (`app/(tabs)/spots/index.tsx`) renders an **empty** `MapView` (`PROVIDER_GOOGLE`) and draws markers as **plain React Native `View`s positioned on top**, using `projectToScreenXY` (`src/lib/mapProjection.ts`) to convert each spot's lat/lng into screen x/y. It does **not** use `react-native-maps` `<Marker>` on the main map.

**Why:** Under React Native's **New Architecture**, `react-native-maps`' native `<Marker>` **crashes `AIRGoogleMap`**. We can't just turn the New Architecture off, because **Reanimated 4 requires it**. So the map base comes from Google, but the interactive markers are our own RN views layered above it and kept in sync with the camera via projection. This is the entire reason the mobile stack diverges from the web stack (which has no RN dependency and therefore uses plain Google Maps JS markers).

### The touch-registry crash — and the "never unmount a touch target mid-gesture" fix

**Problem (RN #53303):** When a touchable is **unmounted while a gesture is in flight** (e.g. a marker scrolls off-screen as you pan and we destroy it), React Native's touch registry desyncs and the app **crashes**.

**Fixes, layered:**

- **Hide, never unmount.** Off-screen markers stay **mounted but hidden** (moved off-screen via projection), so a touch target is never destroyed mid-pan.
- **Two-region split.** A **settled** region drives clustering + which pins exist; a separate **projectionRegion** drives marker screen positions. Decoupling them keeps the marker set stable while the camera moves.
- **Stable cluster keys.** Clusters use stable keys so React doesn't churn/remount marker views on every frame.
- **Deferred `onPress`.** Tap handlers defer their work (via `requestAnimationFrame`) so a press that lands as a marker is repositioning doesn't fire mid-reconcile.
- **`patch-package` `RCTAssert` safety net.** A patched assertion prevents a hard crash if the registry ever does desync — belt and suspenders.

:::warning[The load-bearing invariant]
**Never unmount a touch target during an active gesture.** `projectToScreenXY` hides off-screen markers instead of unmounting them precisely to hold this invariant. Any refactor of the marker layer must preserve it or the RN #53303 crash comes back — and it only reproduces reliably on **physical iOS with dense data under aggressive panning** (see Section 5).
:::

### Clustering (supercluster)

Clustering runs in JS via **`supercluster`** (`src/hooks/useMapClusters.ts`), configured **radius 50 / maxZoom 18 / minPoints 3**. Combined with viewport-only pin loading, this bounds the number of rendered marker views at any time, which keeps panning smooth and keeps the projected-overlay approach affordable.

### Pinch-to-zoom only — no `+`/`–` buttons

The `+`/`–` zoom buttons were **removed**. Rationale: pinch-to-zoom is the native, expected gesture on a touch map; the buttons were redundant chrome. **Freeing that slot let us add the unified in-map Search control** instead — a higher-value use of the same real estate.

### Google-Maps-style in-map search

Search is a single field that queries **both** TrickBook spots and **Google Places** (viewport-biased) at once. Selecting a **spot** flies to it and shows its card; selecting a **place** just flies there. This mirrors the Google Maps mental model and doubles as the entry point for adding a spot at a real-world place.

### Fullscreen immersive mode

A **Fullscreen** control expands the map edge-to-edge, hiding surrounding app chrome for an immersive browse. It's a mode toggle, not a separate screen, so map state (region, selected pin, filters) is preserved.

### Flat "My Spots" (created + saved) + one-tap-save vs long-press

- **Flat model.** Authored + saved spots share one **My Spots** surface (Mine / Saved), with named **Collections** behind a toggle. This matches how riders think ("my spots") rather than forcing a folder decision up front.
- **One-tap save vs long-press.** A **single tap** performs the frictionless default save (optimistic, no limit). A **long-press** opens the list picker for deliberate filing into a named Collection. Common action is one tap; power action is one long-press.

### Google-Maps photo-contribution model + moderation

Photos are **public on upload** (no pre-moderation queue) to maximize contribution, with community **reporting** and **auto-hide at 3 distinct reports** as the safety valve, plus admin hard-delete. This trades a small window of possible bad content for a much richer, faster-growing photo library — the same bargain Google Maps makes.

---

## 4. Technical architecture

### Mobile stack

| Piece | Detail |
|---|---|
| Map base | `react-native-maps` `MapView` with `PROVIDER_GOOGLE`, rendered **empty** (no native markers on the main map) |
| Markers | Plain RN `View`s positioned by `projectToScreenXY` in **`src/lib/mapProjection.ts`** |
| Off-screen markers | **Mounted but hidden** (never unmounted mid-gesture) — RN #53303 mitigation |
| Regions | **settled** region → clustering + which pins load; **projectionRegion** → marker screen positions |
| Clustering | **`supercluster`** via **`src/hooks/useMapClusters.ts`** (radius 50 / maxZoom 18 / minPoints 3) |
| Pin loading | Viewport-loaded via `getMapPins` → `GET /spots/map-pins`, debounced ~350 ms on pan/zoom |
| Controls | Filter · Center · Search · Fullscreen · List — **no `+`/`–` zoom** |
| Search | `searchPlaces` (Google Places, viewport-biased) + `searchSpots`, in one panel |
| Save | `getMySpots` (Mine) + `getSavedSpots` (Saved); named lists via `SpotList` |
| Add | `app/(tabs)/spots/add.tsx` — **still renders a native `<Marker>`** for the drop-pin (with a code warning); submits `createSpot` then `uploadSpotPhoto` (first = cover) |
| Detail | `app/(tabs)/spots/[spotId].tsx` — merges `userPhotos` + `googlePhotos`; Add Photo (any user), Report/Delete (user photos), Google read-only; owner Edit/Delete |
| Tag | `media/upload.tsx` — `searchSpots` picker attaches `spotId` to the post |

:::note[`add.tsx` is the one place the mobile app still uses a native `<Marker>`]
The main map avoids `<Marker>` entirely, but the **add-spot** screen still uses a native `<Marker>` for the drop-pin (guarded by an in-code warning). Migrating this to the projected-overlay approach is a tracked follow-up (Section 6). It hasn't crashed in practice because the add screen shows a single marker with no aggressive panning, but it's the last inconsistency in the marker story.
:::

### Web stack

| Piece | Detail |
|---|---|
| Map component | `components/SpotsMap.js` |
| Map SDK | `@vis.gl/react-google-maps` (`APIProvider` / `Map` / `InfoWindow` / `useMap`) |
| Markers | **Real** `new google.maps.Marker(...)` with SVG-data-URI pins colored by category |
| Clustering | `@googlemaps/markerclusterer` (`ClusteredMarkers`), yellow `#fcf150` cluster bubbles sized by count |
| API key | `process.env.NEXT_PUBLIC_GOOGLE_MAPS_KEY` (missing key → config message, not a crash) |
| Pin fetch | Once from `${API_BASE}/spots/map-pins`, fallback to `/spots?limit=5000` on 404 |
| Filtering | Client-side over all pins; category matches `category` **or** `sportTypes` |
| Tapped pin | Google `InfoWindow` card → `View Details →` link to `/spots/{state}/{spotSlug}?id={id}` |
| Rendering | `SpotsMap` dynamically imported with **`ssr: false`** (avoids Next.js SSR breaking on Google Maps globals) |
| Browse page | `pages/spots.js` — map/list toggle (default map), Category + Country dropdowns |
| List view | `organizeByCountry` → country → state → spot; state pages at `pages/spots/[state].js` (debounced 300 ms search, tag filters, `SpotCard` grid) |
| Detail | `pages/spots/[state]/[spotSlug].js` — carousel, tags, resort/ski-pass info, lodging, videos, press, **Trick History** |
| Add | `pages/spots/add.js` (public) · `pages/admin/create-spot.js` (admin CRUD + rating) |
| Data layer | `lib/apiSpots.js` — all `getSpotsData/searchSpots/getSpotData/createSpot/updateSpot` + SpotList CRUD |

**No React Native anywhere on web.** The projected-overlay hack does **not** exist on the site; there's no `react-native`, `react-native-web`, RN `<Marker>`, or manual lat/lng→pixel projection. The browser has no `react-native-maps` crash to avoid, so it uses the ordinary Google Maps JS SDK.

### Backend endpoints

Three Express routers, all in prod, mounted in `Backend/index.js`: `/api/spots` (`routes/spots.js`), `/api/spotlists` (`routes/spotlists.js`), `/api/feed` (`routes/feed.js`). Auth is **JWT via the `x-auth-token` header**. Only `approvalStatus: 'approved'` spots surface on public map/list/search. See [Backend API Endpoints](/docs/backend/api-endpoints) for the full reference.

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/spots/map-pins` | Public | **Marker data source.** Viewport bbox (`minLat/maxLat/minLng/maxLng`, all four required), `approved`-only, antimeridian-aware, optional `sportType`/`category`. Returns a **trimmed projection** (name, lat/lng, category, sportTypes, rating, imageURL, city/state/country, description). Backed by index `{approvalStatus, latitude, longitude}` |
| GET | `/spots` | Public | Paginated approved list; `sort/order/country/sportType/category/q` filters |
| GET | `/spots/search` | Public | Approved search: `q/city/state/category/tags` |
| GET | `/spots/:id` | Public* | Full detail. Approved is public; private/pending/rejected returned only to owner/admin (`optionalUser`); hidden user photos stripped |
| GET | `/spots/my-spots` | JWT | Requester's **own** spots at **all** statuses |
| GET | `/spots/saved` | JWT | Spots from the user's default **Saved Spots** list, newest-first |
| POST | `/spots` | JWT | Create. `isPublic:false → private`; `isPublic:true → pending (+submittedAt)`; lat/long dedupe |
| PUT | `/spots/:id` | JWT | Edit — **owner or admin** (403 else) |
| DELETE | `/spots/:id` | JWT | Delete — owner or admin; also deletes S3 photos and `$pull`s the id from **all** spotlists |
| POST | `/spots/:id/save` | JWT | **One-tap save** into the hidden default list (upsert). `{saved:true}` |
| DELETE | `/spots/:id/save` | JWT | Unsave (`$pull`). `{saved:false}` |
| GET | `/spots/all` | Admin | Every-status list |
| GET | `/spots/pending` | Admin | Review queue (`pending`, by `submittedAt` desc) |
| PUT | `/spots/:id/approve` | Admin | `approved` (+ reviewedAt/By) |
| PUT | `/spots/:id/reject` | Admin | `rejected` (+ rejectionReason) |
| GET | `/spots/:id/photos` | Public | `{googlePhotos, userPhotos (hidden filtered), mainImage}` |
| POST | `/spots/:id/photos` | JWT | Upload user photo (multipart `photo`, ≤10 MB, images only → S3) |
| DELETE | `/spots/:id/photos/:photoKey` | JWT | Delete — uploader or admin |
| POST | `/spots/:id/photos/:photoKey/report` | JWT | Report. Idempotent per user; **auto-hide at 3 distinct reporters** (`PHOTO_REPORT_HIDE_THRESHOLD = 3`) |
| GET | `/spots/:id/places-info` | Public | Fetch/cache Google Places data (30-day cache) |
| GET | `/spots/places-search` · `/places/:placeId` · `/reverse-geocode` | JWT | Google Places search / details / reverse-geocode |
| — | `/spotlists/*` | JWT (owner-scoped) | Named collections CRUD; default saved bucket excluded from list view; subscription limits enforced |
| POST | `/feed/:postId/link-spot` | JWT (owner) | Attach/clear a `spotId` on a post; enriched onto posts via `populatePostUsers` |

:::note[map-pins is uncapped]
`GET /spots/map-pins` returns **all** matching approved pins in the bbox with **no server-side limit or clustering**. Mobile keeps payloads small by querying only the visible viewport; web fetches everything once. A very large viewport / very dense region can therefore return a large payload — tracked in Known Issues.
:::

---

## 5. QA / test plan

Test on **both** platforms. The crash-regression suite (5.3) is **mandatory before any mobile release that touches the map or marker layer** and must run on a **physical iOS device**.

### 5.1 Functional — per use case

| # | Scenario | Platform | Expected |
|---|---|---|---|
| F1 | Open map | Both | Approved pins render; mobile centers near user; web shows worldwide clustered |
| F2 | Pinch zoom out/in | Mobile | Clusters form/break; **no `+`/`–` buttons present** |
| F3 | Pan across viewport | Mobile | Pins re-query for new bbox (~350 ms debounce); no flicker; no crash |
| F4 | Tap cluster | Both | Expands / zooms into the cluster |
| F5 | Tap single pin | Mobile | Selects, flies to it, shows card |
| F6 | Tap pin | Web | `InfoWindow` card with name/location/rating/category chip/description |
| F7 | Tap background | Mobile | Deselects |
| F8 | Filter by sport/category | Both | Pins re-filter; web is instant (client-side, dual-keyed `category`/`sportTypes`) |
| F9 | Filter by country | Web | Pins filter to country |
| F10 | Center button | Mobile | Recenters on current location |
| F11 | Fullscreen toggle | Mobile | Edge-to-edge; region/selection/filters preserved |
| F12 | List toggle | Both | Country → state → spot hierarchy |
| F13 | In-map search — spot | Mobile | Flies **and** shows card |
| F14 | In-map search — place | Mobile | Flies only (no card) |
| F15 | Add spot (drop pin) | Mobile | `createSpot` then photo upload; first photo = cover |
| F16 | Add spot (search place) | Mobile | Place selectable as location |
| F17 | Add spot (lat/lng) | Web | Coordinates accepted |
| F18 | Add spot (paste Maps URL) | Web | Coords parsed; city/state reverse-geocoded |
| F19 | Public vs private on add | Both | Public → `pending` (queue); private → `private` (owner-only) |
| F20 | Edit spot (owner) | Both | Patch persists; non-owner/non-admin gets 403 |
| F21 | Delete spot | Both | Spot gone; S3 photos removed; id pulled from all Collections |
| F22 | Tag spot on post | Both | `spotId` on post; enriched everywhere (feed/profile/single) |
| F23 | Spot chip render | Web | Location text shows (known: not clickable) |
| F24 | One-tap save | Mobile | Optimistic add to Saved; toggles off; no limit |
| F25 | Long-press save | Mobile | List picker → adds to named Collection |
| F26 | My Spots buckets | Mobile | Mine (all statuses) + Saved (newest-first) correct |
| F27 | Named Collection limits | Both | Subscription limits enforced on named lists; default bucket exempt |
| F28 | Add photo | Mobile | Gallery/camera upload appears immediately |
| F29 | Trick history submit/upvote | Web | Logged-in submit/upvote; logged-out read-only |
| F30 | Missing Google Maps key | Web | Config message, **no crash**; pin fallback `/spots?limit=5000` works |

### 5.2 Approval / visibility

- Approved spot appears on `map-pins`/list/search; private spot appears **only** to its owner; pending appears in the admin queue and not on the public map.
- `GET /spots/:id` returns 404 for a private/pending/rejected spot to a non-owner; returns it to owner/admin.
- Admin approve moves a spot onto the map; reject records `rejectionReason`.
- **Antimeridian:** a viewport crossing ±180° returns pins from both sides.

### 5.3 CRASH regression (mandatory, physical iOS 26)

This suite reproduces the RN #53303 touch-registry crash and the `AIRGoogleMap` New-Architecture crash. If any of these crash, **do not ship**.

| # | Test | Expected |
|---|---|---|
| C1 | Load a **dense** region (many pins in viewport) on a **physical iOS 26** device | Renders; smooth; no crash |
| C2 | **Aggressive continuous panning** across dense areas | No touch-registry desync; no crash |
| C3 | **Aggressive pinch** in/out repeatedly over dense data | Clusters form/break; no crash |
| C4 | **Tap a marker mid-pan** as it scrolls off-screen | Deferred `onPress`; marker hidden not unmounted; no crash |
| C5 | Rapid select → deselect → re-select while panning | Stable cluster keys hold; no remount churn crash |
| C6 | Confirm off-screen markers are **hidden, not unmounted** (instrument/inspect) | Touch targets never destroyed mid-gesture |
| C7 | Confirm `patch-package` `RCTAssert` patch present in the build | Safety net in place |

:::warning[Physical device only, dense data only]
The crash does **not** reproduce on the iOS Simulator or with sparse data. Every marker-layer change must be validated on a real iOS 26 device against a dense dataset with aggressive gestures. A "works on simulator" result proves nothing here.
:::

### 5.4 Performance / smoothness

- Panning/zooming a dense viewport stays visually smooth (target ~60fps; no long frame hitches).
- Rendered marker count stays bounded by clustering even as data grows.
- Viewport re-query debounce (~350 ms) prevents request storms during fast panning.
- Web: large single `map-pins` payload loads without freezing the main thread (watch the uncapped-payload risk).

### 5.5 Moderation / photos

- Photo is public immediately on upload.
- Reporting is **idempotent per user** (same user reporting twice counts once).
- **3 distinct reporters → auto-hide**; hidden photo disappears from `GET /:id` and `/:id/photos`.
- Admin hard-delete removes a photo regardless of report count.
- Non-uploader, non-admin **cannot** delete another user's photo (403).
- Google photos are read-only (no report/delete).

### 5.6 Permissions

- **Location** — map requests it on first open; denial degrades gracefully (map still usable, no auto-center).
- **Photos (gallery)** — requested at Add Photo / add-spot; denial blocks that path with a clear message, no crash.
- **Camera** — requested when taking a photo; denial handled gracefully.

### 5.7 Acceptance criteria

- ✅ Explore, search, filter, tap-pin, fullscreen all work on mobile; explore/filter/tap-pin/list work on web.
- ✅ Add / edit / tag / save / photo-contribute flows complete end-to-end per the matrix in Section 1.
- ✅ Only approved spots appear publicly; ownership/admin authorization enforced (403s correct).
- ✅ Photo auto-hide triggers at exactly 3 distinct reporters.
- ✅ **Zero crashes** across the entire 5.3 suite on a physical iOS 26 device with dense data.
- ✅ No performance regression versus the current release on a dense viewport.

---

## 6. Known issues / follow-ups

| Item | Status | Notes |
|---|---|---|
| Reanimated-driven marker positions | 🚧 In progress | Drive projected-marker positions through Reanimated shared values for buttery pan/zoom smoothness (fewer JS-thread position updates) |
| My-Spots row unsave affordance | 📋 Planned | The My Spots list rows need a clearer unsave/remove control (parity with the map bookmark toggle) |
| `add.tsx` `<Marker>` migration | 📋 Planned | The add-spot drop-pin still uses a native `<Marker>`; migrate to the projected-overlay approach for full consistency with the main map |
| Add-spot from a searched place | 📋 Planned | Tighten the flow so selecting a Google Places result in search flows directly into add-spot with the place pre-filled |
| Offline support | 📋 Planned | Cache viewport pins / user Collections and tiles for offline browse; sync on reconnect |
| Web clickable spot chip | 🚧 Gap | Feed shows tagged location as plain text, not a link to the spot page (trick tags are clickable — spot chip should match) |
| Vestigial local-only "heart" favorite | 🚧 Cleanup | The mobile detail page has a leftover local-only heart favorite superseded by one-tap save; remove to avoid confusion |
| `map-pins` uncapped payload | 🚧 Risk | No server-side limit/clustering on `map-pins`; a very large/dense viewport can return a large payload. Consider a server cap or server-side clustering |
| `POST /spots/bulk` has no admin gate / no owner/status | 🚧 Risk | Bulk-inserted spots set no `userId`/`approvalStatus`, so they're unowned and invisible on approved-only endpoints unless the payload pre-sets `approvalStatus: 'approved'` |
| `feed.js` stores `userId` as string vs `spots.js` ObjectId | 🚧 Inconsistency | Cross-collection type mismatch in ownership comparisons; harmonize to avoid subtle auth bugs |

:::tip[Where this sits on the roadmap]
The Spots surface (including this map) is slated for a broader UX-excellence pass with analytics instrumented first. See [Spots → Planned UX refactor](/docs/features/spots) and [Roadmap Priorities](/docs/roadmap/priorities).
:::
