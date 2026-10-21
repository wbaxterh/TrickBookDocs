---
title: TV App Expansion Roadmap
description: Product, platform, streaming, monetization, licensing, and launch plan for bringing TrickBook to connected TVs.
---

# TV app expansion roadmap

Status: **Strategy approved for validation; implementation not started**  
Last researched: **October 21, 2026**

:::caution[Not legal advice]
This document is an operating plan, not a legal opinion. A media attorney should review the final creator license, privacy disclosures, subscription terms, DMCA process, and platform-specific commercial terms before TrickBook accepts masters or sells access.
:::

## Executive decision

TrickBook should become a connected-TV product, but it should not attempt six native launches at once. The TV experience should begin as **The Couch on TV**: a remote-first action-sports film and tutorial service powered by the existing catalog, identity system, rider graph, and Bunny streaming infrastructure.

The recommended order is:

1. **Casting readiness:** reliable Google Cast and AirPlay from mobile and web
2. **Google TV / Android TV:** first installed TV MVP
3. **Amazon Fire TV:** reuse the Android TV application architecture
4. **Apple TV (tvOS):** premium native experience and shared Apple subscription entitlement
5. **Roku:** important reach, but a separate SceneGraph/BrightScript application and certification path
6. **Samsung Tizen:** first television-manufacturer platform
7. **LG webOS:** second television-manufacturer platform
8. **Later:** Vizio, Xumo, Xbox, PlayStation, operator boxes, and FAST-channel distribution

This sequence validates television retention before multiplying codebases. It also buys time to replace the current mixed-source catalog with enough explicitly licensed, TV-ready masters to support subscriptions, advertising, and broad store review.

## What the first TV product is

The first release is not the entire mobile social app enlarged for a television. It is a focused ten-foot experience:

- The Couch home screen with featured, new, sport, filmmaker, and collection rows
- Film and episode detail pages with riders, sponsors, duration, year, and rights/source labels
- Remote-friendly adaptive video playback
- Search by title, rider, sport, crew, filmmaker, and sponsor
- QR or short-code account activation
- Watchlist, continue watching, and cross-device playback position
- Captions and accessible playback controls
- Deep links from rider profiles and Trickipedia tutorials into relevant films
- A free browse mode so store reviewers and new viewers can understand the service without typing credentials

Defer comments, direct messages, uploads, marketplace checkout, complex profile editing, Kaori's 3D stage, and creator administration. Those remain phone/web activities. A later TV release can add a lightweight Kaori voice guide or training mode after core playback is stable.

## Why TrickBook can win

TrickBook should not compete with general streaming services on library size. Its advantage is the structured action-sports graph around each video:

- a film resolves to its riders;
- riders resolve to tricks, sponsors, disciplines, spots, and related films;
- tutorials resolve to progression paths;
- events resolve to streams, results, venues, and athletes;
- independent filmmakers get credit, discovery, reporting, and a direct relationship with a focused audience.

The positioning is **the action-sports film library that knows the scene**, not a generic playlist of embedded videos.

## Comparable services and lessons

### FUEL TV+

[FUEL TV+](https://plus.fuel.tv/content/about) is the closest commercial comparison. It offers a large action-sports catalog across Apple TV, Roku, Fire TV, Android TV, mobile, and web. Its public offer is $4.99 monthly or $49.99 annually, with a trial, commercial-free subscription viewing, watchlists, cross-device resume, casting, and some individual rentals or purchases. Its Apple listing describes more than 2,000 hours and in-app subscription support.

**Lesson for TrickBook:** device coverage, account linking, resume playback, and a simple price are table stakes. TrickBook should differentiate through independent scene coverage, structured rider/trick data, creator relationships, and community—not by trying to out-license an established television network.

### Red Bull TV

[Red Bull TV on Apple TV](https://apps.apple.com/us/app/red-bull-tv-watch-live-events/id364269164?platform=tv) combines a free on-demand catalog, live events, replays, a 24/7 stream, favorites, and casting. It is brand-funded and uses premium owned/licensed programming to make the service free.

**Lesson for TrickBook:** a free service can be powerful when underwriting and content ownership are strong. TrickBook can borrow the programming model—featured premieres, collections, live events, and a later linear channel—but cannot copy the economics without sponsors or owned rights.

### X Games

[X Games](https://www.xgames.com/watch/) distributes through a portfolio rather than relying on one proprietary app: ESPN, Roku Sports Channel, YouTube, Kick, social platforms, and regional partners. X Games has also used a FAST channel and dedicated Roku placement.

**Lesson for TrickBook:** distribution can be a network. The TrickBook app should be the canonical catalog and account experience, while selected premieres or channels can also run on YouTube, Roku, FAST services, and creator-owned channels under separate agreements.

### Strategic conclusion

The market supports three working models:

- **brand-funded free** (Red Bull TV),
- **subscription catalog** (FUEL TV+), and
- **multi-partner event distribution** (X Games).

TrickBook should begin with a hybrid: free creator-authorized programming and sponsorship, then add premium licensed collections to the existing TrickBook Plus subscription.

## Platform plan

### Phase 0: casting and television readiness

Before an installed TV app, make the mobile/web player a dependable sender:

- Google Cast with sender state, queueing, captions, and resume synchronization
- AirPlay using standards-compliant HLS
- TV-safe posters and 16:9 backdrops
- persistent playback-position API
- device activation endpoint and short-lived pairing codes
- playback analytics by content, device family, rendition, startup time, buffering, and completion

Casting produces real living-room usage data with the lowest product and certification cost.

### Phase 1: Google TV / Android TV

Google states that TV apps can share the same architecture as phone/tablet apps, but must provide a television activity, remote navigation, TV assets, and a ten-foot interface. Compose for TV is Google's recommended modern UI toolkit. See [Android TV overview](https://developer.android.com/training/tv/index.html), [create a TV app](https://developer.android.com/training/tv/get-started/create), and the [TV app quality checklist](https://developer.android.com/docs/quality-guidelines/tv-app-quality).

**Recommendation:** build a dedicated TV presentation layer over shared TypeScript API models and backend contracts. Prototype both a `react-native-tvos` route and native Compose before committing; choose native Compose if focus behavior, playback, memory, or certification quality is materially better. Do not ship the touch UI with a TV launcher flag.

Release gate:

- every action is reachable with D-pad, select, back, play/pause, seek, and home behavior;
- focus is always visible and deterministic;
- playback pauses when the app loses foreground;
- TV banner/icon, screenshots, privacy disclosures, and reviewer credentials are ready;
- low-memory and slower TV hardware are included in testing.

### Phase 2: Amazon Fire TV

Fire TV is based on Android/AOSP and officially supports Android, HTML5, and React Native application paths. See [Amazon's Fire TV getting-started guide](https://developer.amazon.com/docs/fire-tv/get-started-with-fire-tv.html).

Reuse the Google TV domain, API, analytics, and most presentation logic, while isolating:

- Amazon Appstore billing and entitlement receipts;
- Fire TV device capability checks;
- Amazon-specific store assets and certification;
- any Google Play Services dependency;
- Fire remote and lifecycle differences.

This should be the second installed release because it increases reach without creating a fundamentally new playback stack.

### Phase 3: Apple TV

Apple recommends SwiftUI and provides AVPlayer/AVKit, focus, sidebar, user-management, 4K/HDR, remote, and system playback integrations for tvOS. See [Apple's tvOS overview](https://developer.apple.com/tvos/) and [video framework guidance](https://developer.apple.com/documentation/technologyoverviews/video).

Build a native SwiftUI shell unless a `react-native-tvos` spike proves equal in focus, AVPlayer, StoreKit, and review quality. Reuse backend schemas, design tokens, catalog services, and entitlements—not mobile screen layouts.

Apple review requires a complete application, working backend, and reviewer access. An Apple TV app must work with the Siri Remote without depending on a phone keyboard. QR activation may be offered as convenience, but a compliant on-device path and review account should exist. Apple's current [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) govern user-generated content, subscriptions, and external purchase links.

### Phase 4: Roku

Roku remains strategically important for U.S. living rooms, but it uses BrightScript plus SceneGraph rather than the Android/Apple stacks. See Roku's [getting-started documentation](https://developer.roku.com/dev/docs/getting-started), [SceneGraph reference](https://developer.roku.com/dev/docs/scenegraph), and [certification criteria](https://developer.roku.com/dev/docs/certification).

Treat Roku as its own client with shared backend contracts. Its initial feature set should be narrower than the Android/Apple clients. Roku's current certification rules require Roku Pay for transactional/SVOD content and on-device authentication flows; the implementation and commercial agreement must be reviewed immediately before build and submission.

### Phase 5: Samsung Tizen

Samsung TV apps are web applications with Samsung playback APIs and a manufacturer certification workflow. The [TV Seller Office](https://developer.samsung.com/tv-seller-office/guides/overview.html) handles partnership, registration, pre-testing, certification, and distribution. Samsung's submission data explicitly describes HLS/DASH engines, AVPlay/MSE player APIs, and subtitle formats.

Build a shared web-TV core only after the product and navigation have stabilized on earlier platforms. Maintain an explicit device/model test matrix because TV engine behavior varies by model year.

### Phase 6: LG webOS

LG webOS is also web-based and supports HLS, but its [streaming compatibility documentation](https://webostv.developer.lge.com/develop/specifications/streaming-protocol-drm) identifies model/version-specific HLS limitations. In particular, some playlist tags and discontinuity behaviors differ across older versions, and audio/video segment duration must align.

Reuse the Samsung web-TV application shell where practical, but keep player adapters and capability detection separate. Test physical devices; emulator success is not enough.

## Streaming and media architecture

### Source classes must remain distinct

Every Couch title must have one—and only one—playback class:

1. **TrickBook-hosted licensed master:** TrickBook has written rights to store, encode, transmit, promote, and monetize the title on the applicable devices and territories.
2. **Official third-party player:** the publisher hosts the work on YouTube or another approved service; TrickBook launches or embeds the official player under that platform's rules.
3. **External-only link:** TrickBook catalogs the title and sends viewers to the authorized service because a compliant embedded/TV player is unavailable.
4. **Unavailable:** the source or permission is withdrawn, geo-blocked, private, removed, or otherwise cannot be lawfully played.

Never download, restream, proxy, remove advertisements from, or manufacture HLS renditions from a YouTube upload merely because it is publicly viewable.

### Target delivery format

Use adaptive-bitrate **HLS over HTTPS** as the baseline VOD format. HLS works natively across Apple TV and is supported by Android/Google TV, Fire TV, Roku, Samsung, and LG players. Apple's current [HLS authoring specification](https://developer.apple.com/streaming/hls-authoring-specification-for-apple-devices.html) supports H.264 in fragmented MP4 or MPEG transport streams and requires television-specific details such as trick-play renditions.

Initial compatibility profile:

| Rendition | Video target | Use |
|---|---:|---|
| 426×240 H.264 | 350–500 kbps | degraded connections only |
| 640×360 H.264 | 700–1,000 kbps | low bandwidth |
| 960×540 H.264 | 1.4–2.2 Mbps | medium bandwidth |
| 1280×720 H.264 | 2.8–4.5 Mbps | normal HD |
| 1920×1080 H.264 | 5.5–8 Mbps | high-quality HD |
| AAC-LC stereo | 128–192 kbps | universal audio fallback |

These are starting targets, not fixed encoder law. High-motion snow, skate, surf, BMX, and MTB footage needs visual inspection and may require more bitrate than talking-head video.

Packaging requirements:

- preserve original frame rate; do not convert 24/25/30/50/60 fps without reason;
- closed GOPs and aligned keyframes across every rendition;
- aligned audio/video segment boundaries, approximately 4–6 seconds for VOD;
- accurate `BANDWIDTH`, `AVERAGE-BANDWIDTH`, resolution, frame-rate, and codec attributes;
- stereo AAC fallback even when surround audio is available;
- WebVTT captions, language metadata, and SDH accessibility flags;
- poster (2:3), backdrop (16:9), logo/title treatment, preview thumbnails, and scrub/trick-play assets;
- no baked-in black bars, device UI, platform watermarks, or unlicensed music substitutions;
- HTTPS, correct MIME types, byte-range support where applicable, and CORS for approved origins;
- SHA-256 checksum and immutable master identifier for every delivery.

Bunny Stream can remain the first encoding/CDN system if its generated manifests pass the full physical-device matrix. Keep source masters outside the delivery renditions so content can be re-encoded or migrated without requesting a new upload from the filmmaker.

### Master-delivery specification for creators

Preferred master:

- ProRes 422/422 HQ or high-bitrate H.264/H.265 mezzanine
- native resolution and frame rate, progressive scan
- 48 kHz audio, stereo mix plus optional discrete surround stems
- textless master when available
- captions/transcript and music cue sheet
- clean poster, backdrop, logo, stills, trailer, credits, synopsis, release date, runtime, ratings notes, and territories

Accept a high-quality existing final export for independent filmmakers who cannot produce ProRes. Do not make an expensive delivery spec a gate to participation; TrickBook can provide an upload portal and preflight report.

### Playback authorization

The client should not receive a permanent unrestricted CDN URL. Use this flow:

1. TV requests playback from TrickBook with user, device, title, and app version.
2. Backend checks publication, territory, window, age restriction, subscription, and concurrency.
3. Backend returns a short-lived signed manifest URL plus playback-session ID.
4. Client reports start, heartbeat, rendition changes, buffering, completion, and fatal errors.
5. Backend enforces concurrent-stream limits and revokes a session when required.

Free titles can use longer-lived tokens and anonymous session IDs. Premium titles need short expiry, entitlement checks, and server-side receipt validation.

### DRM decision

Do not add DRM merely for appearance. Signed HLS plus operational controls are enough for creator-authorized free content. Add multi-DRM when a license requires it or premium value justifies it:

- FairPlay Streaming for Apple/tvOS HLS;
- Widevine for Google TV/Android/compatible web TVs;
- PlayReady where required by Roku, Samsung, LG, Microsoft, or a distributor agreement.

DRM is a rights and vendor decision, not only a player feature. Before promising it, run a provider evaluation covering device reach, license-server uptime, offline rules, key rotation, forensic watermarking, 4K robustness, cost, and Bunny integration. Keep playback authorization vendor-neutral.

### Quality assurance matrix

Every release must test:

- cold launch, activation, anonymous browse, sign-in, sign-out, and token expiry;
- 24/30/60 fps content and long-form playback;
- slow, variable, and interrupted networks;
- seek, pause/resume, subtitles, audio selection, scrub previews, and end-of-title behavior;
- app background/foreground, sleep, power loss, and backend/CDN failure;
- geo/window/entitlement denial with useful messages;
- older low-memory devices and current flagship hardware;
- ad breaks when present, including failed and empty ad responses;
- analytics accuracy and no duplicate view/revenue events.

## Content rights and legality

### The core rule

Public availability is not a distribution license. The U.S. Copyright Office explains that copyright owners control reproduction, distribution, public performance of audiovisual works, and authorization of others to exercise those rights. See [What is Copyright?](https://www.copyright.gov/what-is-copyright/).

For every TrickBook-hosted film, obtain a signed agreement from the party with authority to grant all necessary rights. A filmmaker may control the picture but not the music, archival footage, athlete releases, sponsor marks, or event footage. The agreement must include representations about those underlying rights.

### Minimum creator/distributor license terms

The contract should state:

- exact title, version, runtime, and delivered assets;
- licensor identity and authority;
- nonexclusive or exclusive grant;
- permitted uses: hosting, reproduction for encoding, public performance, promotion, clips, thumbnails, trailers, captions, and metadata;
- platforms: web, mobile, connected TV, FAST, social promotion, and future devices;
- territories and geo-blocking obligations;
- start/end dates, renewal, holdbacks, and withdrawal procedure;
- monetization rights: free, AVOD, SVOD, TVOD, sponsorship, FAST, or combinations;
- revenue definition, platform/store fees, ad costs, taxes, refunds, minimum payouts, reporting cadence, audit rights, and payment timing;
- music, footage, appearance, privacy, trademark, and union/guild clearances;
- content rating and sensitive-content disclosures;
- delivery materials and technical acceptance;
- marketing approvals and use of names/likenesses;
- warranties, indemnities, limitation of liability, takedown cooperation, and dispute venue;
- whether TrickBook may create accessibility files, edits, censored versions, compilations, and promotional excerpts;
- data shared with the creator: starts, unique viewers, completion, geography, watch time, and revenue without exposing personal user data.

Use a short-form **creator hosting license** for independent films and a longer **distribution agreement** for paid/exclusive catalogs.

### YouTube-hosted titles

YouTube content must use the official YouTube player or open in the YouTube application as required. Current [YouTube API policies](https://developers.google.com/youtube/terms/developer-policies) prohibit downloading or separating media, blocking YouTube advertising or controls, charging users to watch embedded YouTube content, placing unauthorized advertising within the player, and using the API as a low-value YouTube clone. The service must preserve attribution and provide meaningful independent value.

Therefore:

- YouTube titles stay outside the TrickBook paywall;
- no TrickBook pre-roll, mid-roll, overlay, or sponsor takeover may be inserted into the YouTube player;
- do not promise uninterrupted or ad-free YouTube playback;
- title, thumbnail, channel, and source attribution stay accurate;
- if a TV platform cannot support a compliant player, open/deep-link to YouTube or mark the title external-only;
- premium hosting begins only after the rights holder supplies a master and signs a hosting/monetization license.

### User uploads and DMCA

If TV surfaces user-uploaded clips, TrickBook must maintain the same moderation and copyright process as mobile/web. The Copyright Office explains that qualifying providers seeking DMCA section 512 safe-harbor protection must designate an agent, publish the agent's information, maintain an accurate designation, and respond expeditiously to valid notices. See the [DMCA overview](https://www.copyright.gov/dmca/) and [designated-agent directory guidance](https://www.copyright.gov/dmca-directory/faq.html).

Operational requirements include:

- registered and published DMCA agent;
- notice, counter-notice, and restoration workflow;
- repeat-infringer policy that is actually enforced;
- content/source audit trail and legal hold support;
- rapid unpublish across API, CDN, caches, search, and all TV clients;
- rights-contact and escalation log;
- store-compliant reporting/blocking for objectionable user content.

Safe harbor does not replace direct licenses for a curated catalog TrickBook selects and hosts.

### Privacy, children, accessibility, and advertising

- Update the privacy policy for TV device IDs, activation codes, viewing history, crash data, ad IDs, and household inference.
- Minimize data before login and offer account/data deletion from web/mobile even when TV input is impractical.
- Determine the product's audience and age rating; do not casually classify it as child-directed. If child-directed content/users are intentionally served, obtain specialist COPPA/GDPR-K advice and configure players/ads accordingly.
- Provide captions and accessible focus/contrast from the first release. Treat accessibility files as part of delivery and licensing.
- Sponsored rows, films, and recommendations must be clearly labeled. FTC guidance says native advertising must be identifiable as advertising and disclosures must be clear and prominent. See the FTC's [native advertising guide](https://www.ftc.gov/business-guidance/resources/native-advertising-guide-businesses).

## Monetization plan

### Recommended model

Do not launch a separate “TV-only” subscription. Extend the existing TrickBook account and Plus entitlement across web, mobile, and TV.

**Free layer**

- licensed free films and tutorials;
- official YouTube/external-player catalog where compliant;
- selected premieres, highlights, trailers, and live events;
- sponsor-funded collections and clearly labeled branded programming;
- optional ad-supported playback only on titles licensed for AVOD.

**TrickBook Plus layer**

- premium licensed films and collections;
- commercial-free playback for TrickBook-hosted premium content;
- early-access premieres and filmmaker Q&As;
- higher-value Kaori/companion benefits already defined by the broader Plus plan;
- cross-device watchlist, resume, and member collections.

**Later options**

- TVOD rentals/purchases for event premieres or new films;
- creator channels or season passes;
- FAST channel built from content with explicit linear/FAST rights;
- event sponsorship and branded collections;
- affiliate commerce tied to riders, films, gear, events, and shops;
- B2B licensing of a curated channel to resorts, shops, gyms, hotels, or venues.

### Platform billing

Platform payment rules change and must be re-checked before each release.

- Apple currently requires in-app purchase for in-app digital content and supports subscriptions shared across an app's Apple platform versions. See [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and [App Store Connect IAP overview](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/).
- Google Play requires Play Billing for covered digital content subscriptions purchased in Play-distributed apps, subject to current program/region exceptions. See [Google Play payments policy](https://support.google.com/googleplay/android-developer/answer/10281818).
- Roku currently requires Roku Pay for transactional/SVOD apps and has separate advertising requirements. See [Roku certification](https://developer.roku.com/dev/docs/certification), [billing](https://developer.roku.com/dev/docs/billing), and [advertising](https://developer.roku.com/dev/docs/advertising).
- Amazon, Samsung, and LG agreements and billing programs must be reviewed at implementation time; never assume a web checkout CTA is permitted merely because account activation is.

Backend entitlements must be platform-neutral and receipt-driven:

```text
store receipt/webhook -> normalized transaction -> account entitlement
                                           -> TV playback authorization
```

Storefront determines billing ownership and cancellation UX; TrickBook's backend determines content access after validating the transaction. Preserve purchase-source metadata so support can send users to the correct platform for refunds or cancellation.

### Creator economics

Offer creators a menu rather than one take-it-or-leave-it deal:

1. **Discovery listing:** official external player, no hosting transfer, no TrickBook paywall.
2. **Free hosted showcase:** nonexclusive hosting, creator retains ownership, sponsor or fixed-fee support when available.
3. **Revenue-share license:** title participates in AVOD/SVOD/TVOD revenue under an agreed allocation method.
4. **Minimum guarantee/license fee:** reserved for proven premieres, exclusives, or anchor catalogs.

Avoid promising per-view revenue before measurement and platform deductions are defined. For pooled subscription revenue, define a transparent formula—for example, a creator pool allocated by qualified watch time, with fraud exclusions, minimum play duration, territory, refunds, and store fees specified.

### What to measure before setting price

- TV monthly active viewers and activated households
- browse-to-play conversion
- playback starts, 5-minute viewers, completion, and qualified watch hours
- casting versus installed-app retention
- free-to-Plus conversion by title/collection
- subscriber churn and cross-device engagement
- CDN/encoding cost per qualified hour
- platform fees, ad fill, CPM, and net revenue
- creator catalog acquisition cost and revenue per licensed hour

Use FUEL TV+'s public $4.99/month benchmark as market context, not an automatic price. TrickBook Plus already bundles a broader product; test whether TV increases retention before creating another plan.

## Creator outreach program

The outreach proposition should be concrete:

> TrickBook is building a cross-device home for action-sports films. We can preserve your credits, connect every featured rider to their profile and other work, stream a high-quality licensed master on mobile/web/TV, share transparent viewing reports, and structure the release as free discovery, sponsored programming, or revenue share. You keep ownership.

Priority targets:

- independent skate/snow/surf/BMX/MTB/scooter filmmakers with complete films;
- crews and shops with under-distributed back catalogs;
- event organizers with replay rights;
- established channels whose YouTube catalog proves demand;
- brands willing to clear older team videos for a sponsored collection;
- film festivals and distributors with multi-title catalogs.

Outreach sequence:

1. Identify the rights decision-maker, not only the uploader.
2. Send a one-page offer with audience, platforms, reporting, and deal options.
3. Confirm picture, music, athlete, sponsor, archive, territory, and platform rights.
4. Execute the appropriate license before accepting the master.
5. Run technical/QC ingest and approve metadata/credits with the licensor.
6. Schedule a launch package: trailer, rider pages, editorial, social, and TV feature.
7. Report performance and pay on the contractual cadence.

Build a creator portal later; begin with a disciplined CRM, approved templates, secure upload links, and a rights ledger.

## Data and backend work

Extend `couch_videos` with fields that make rights and device behavior enforceable rather than implied:

```javascript
{
  playbackClass: 'trickbook_hosted' | 'official_player' | 'external_only' | 'unavailable',
  rights: {
    licensorId,
    agreementId,
    startsAt,
    endsAt,
    territories: ['US', 'CA'],
    platforms: ['web', 'mobile', 'ctv'],
    models: ['free', 'avod', 'svod'],
    promotionalClipSeconds,
    musicCleared: true,
    captionsAuthorized: true,
    takedownStatus: 'clear'
  },
  media: {
    masterAssetId,
    hlsUrl,
    dashUrl,
    drmPolicy,
    captions: [],
    audioTracks: [],
    posters: {},
    checksum
  },
  availability: {
    status: 'available',
    allowedCountries: [],
    blockedCountries: [],
    minPlan: 'free'
  }
}
```

New services/endpoints:

- device activation issue/claim/status
- TV home rails and remote-friendly search
- playback authorization and signed manifest delivery
- progress heartbeat and continue-watching
- entitlement normalization across Stripe and TV stores
- device/session management and concurrent-stream enforcement
- catalog availability resolver by platform, territory, time, and plan
- rights-expiry and takedown jobs
- QoE analytics pipeline and operational dashboards

## Delivery roadmap

### Gate A — rights and playback audit (2–4 weeks)

- classify every Couch title into the four playback classes;
- identify which hosted assets have signed connected-TV and monetization rights;
- produce a red/yellow/green rights report;
- validate every current Bunny HLS title on representative TV players;
- select 20–40 launch-quality, fully cleared titles;
- have counsel approve creator/distributor templates and the DMCA process.

**Exit:** no launch title relies on assumptions about public availability or uploader authority.

### Gate B — casting and shared TV services (3–6 weeks)

- ship Cast and AirPlay;
- implement activation, progress, watchlist, entitlement, signed playback, and TV home APIs;
- normalize TV artwork and captions;
- instrument playback quality and household activation;
- create TV design system and remote-navigation prototype.

**Exit:** viewers can reliably watch the launch catalog on televisions and resume across devices.

### Gate C — Google TV MVP (4–8 weeks)

- build browse, search, detail, player, activation, settings, and error states;
- test physical devices and complete Play TV quality requirements;
- run internal/closed testing with real accounts and network impairment;
- submit a free catalog first unless premium rights/billing are already proven.

**Exit:** stable production release with measurable weekly returning households.

### Gate D — Fire TV and Apple TV (6–12 weeks, partly parallel)

- port Android domain/UI work to Fire TV and integrate Amazon requirements;
- build native tvOS shell with AVPlayer and StoreKit entitlement support;
- add cross-platform subscription validation only after legal/store review;
- expand licensed catalog based on Google TV viewing data.

**Exit:** the three major reusable technology families are proven.

### Gate E — Roku (6–10 weeks)

- build the focused SceneGraph client;
- integrate Roku authentication, billing, and/or advertising as applicable;
- pass device, playback, and certification testing;
- evaluate Roku Sports/FAST partnership opportunities separately from the app.

### Gate F — Samsung and LG (8–14 weeks)

- create shared web-TV shell with separate Tizen/webOS player adapters;
- maintain model-year compatibility matrix;
- complete manufacturer partnership, pre-test, certification, and regional rollout;
- add DRM only if the licensed premium catalog requires it.

### Gate G — scale programming and distribution

- recurring independent premieres;
- filmmaker/crew storefront pages;
- live events and replay windows;
- FAST channel only after linear rights and sufficient hours exist;
- resort/shop/gym distribution;
- additional device families based on measured demand.

## Go/no-go criteria

Do not start a new platform merely to collect a store badge. Advance when:

- at least 20–40 strong titles are explicitly cleared for that device and business model;
- the existing platform has acceptable crash-free sessions, startup time, buffering, and retention;
- account activation and entitlement support load is manageable;
- rights expiration and takedown can propagate automatically;
- the next platform has demonstrated audience demand or meaningful code reuse;
- content acquisition has a repeatable owner, CRM, contract, ingest, QC, and reporting process.

## Immediate next actions

1. Create the catalog rights audit and mark every title `hosted licensed`, `official player`, `external-only`, or `unavailable`.
2. Ask counsel for a short-form creator hosting license and a paid distribution/revenue-share agreement.
3. Recruit an initial connected-TV cohort of 10–20 filmmakers/crews and request masters only after signature.
4. Audit Bunny HLS output, signed-token behavior, captions, thumbnails, and physical-device compatibility.
5. Build Cast/AirPlay plus playback progress before the first installed TV client.
6. Prototype Google TV remote navigation and playback on one low-cost device and one current 4K device.
7. Decide the free launch catalog and which, if any, titles can legally participate in Plus.
8. Re-check each store's billing, authentication, privacy, and certification terms immediately before implementation and submission.

