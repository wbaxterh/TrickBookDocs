---
sidebar_position: 19
---

# Rider Encyclopedia: Ten-Profile Pilot

**Plan date:** 2026-09-02  
**Status:** Proposed  
**Pilot scope:** Public skateboarder profiles, beginning with ten notable riders

## Product vision

TrickBook should connect tricks, spots, videos, events, and the people who shaped them. The rider encyclopedia is the people layer: a browsable, sourced knowledge base of notable riders and their careers.

This is distinct from the existing user `riderProfile`. A user profile represents a TrickBook member and their activity. An encyclopedia rider is an editorial entity that can exist without an account. A verified member may later claim or link an encyclopedia profile, but the records must not be merged.

## Pilot goals

The first release should answer four questions:

1. Can a reader quickly understand who a rider is and why they matter?
2. Can TrickBook connect a rider to tricks, disciplines, videos, spots, events, and brands without turning biography text into an unmaintainable blob?
3. Can editors support every material claim with a visible source and revision history?
4. Can the same model represent different eras, countries, genders, disciplines, and career types?

The pilot is successful when all ten profiles are useful on their own, browseable as a collection, internally linked, mobile-friendly, and publishable without unlicensed media.

## Pilot roster

The list intentionally tests more than name recognition. It spans four decades, four countries, street, park, vert, freestyle, competitive careers, video-part careers, entrepreneurship, and trick innovation.

### 1. Tony Hawk

- **Why he belongs:** The clearest mainstream entry point and a foundational vert profile.
- **Profile angle:** competitive dominance, the 900, Birdhouse, the video-game franchise, and skatepark advocacy.
- **Model stress test:** long career, business ventures, philanthropy, signature trick milestone, and unusually broad media footprint.
- **Starting sources:** [official biography](https://www.tonyhawk.com/in-the-beginning/), [Skateboarding Hall of Fame roster](https://skateboardinghalloffame.org/shof-1980s-era-2-inductees/).

### 2. Rodney Mullen

- **Why he belongs:** Essential to explaining the technical foundation of modern street skateboarding.
- **Profile angle:** freestyle dominance, transition to street, trick innovation, World Industries, and board/truck design.
- **Model stress test:** disputed or nuanced invention claims and a large graph of associated tricks.
- **Starting sources:** [official biography](https://rodneymullen.com/about), [Skateboarding Hall of Fame profile](https://skateboardinghalloffame.org/shof-2013/rodney-mullen-2013/).

### 3. Daewon Song

- **Why he belongs:** A defining technical street skater whose influence is expressed through video parts and creative terrain more than conventional contest results.
- **Profile angle:** *Love Child*, the Rodney vs. Daewon series, Almost Skateboards, technical progression, and longevity.
- **Model stress test:** filmography, creative influence, companies, awards, and Korean-American identity.
- **Starting source:** [Skateboarding Hall of Fame profile](https://skateboardinghalloffame.org/shof-2017/daewon-song-2017/).

### 4. Elissa Steamer

- **Why she belongs:** A landmark street skater and an essential part of women’s professional skateboarding history.
- **Profile angle:** video parts, contest career, Toy Machine, pioneering visibility, and Gnarhunters.
- **Model stress test:** historically significant career where reductive “first woman to...” copy must be sourced and contextualized.
- **Starting source:** [Skateboarding Hall of Fame profile](https://skateboardinghalloffame.org/shof-2015/elissa-steamer-2015/).

### 5. Bob Burnquist

- **Why he belongs:** A globally recognized Brazilian-American vert and mega-ramp innovator.
- **Profile angle:** switch stance on vert, X Games longevity, the Mega Ramp, and Brazilian skateboarding’s global reach.
- **Model stress test:** dual nationality, vert and big-air disciplines, major contest record, and trick/terrain innovation.
- **Research note:** confirm biographical facts and competition totals through athlete, X Games, and federation sources before drafting.

### 6. Letícia Bufoni

- **Why she belongs:** One of the best-known Brazilian street skaters and a bridge between street culture, contests, and the Olympic era.
- **Profile angle:** X Games career, international street competition, Brazilian representation, and impact on women’s skateboarding.
- **Model stress test:** changing sponsor/team data and time-sensitive career status.
- **Research note:** use World Skate, Olympics, X Games, and first-party rider sources; timestamp sponsors rather than presenting them as permanent facts.

### 7. Nyjah Huston

- **Why he belongs:** A defining competitive street skater of the modern era with an extensive video and contest record.
- **Profile angle:** early professional career, Street League, X Games, Olympic appearances, and technical consistency.
- **Model stress test:** large result history, active-career updates, sponsor changes, and separating measurable record from subjective “greatest” claims.
- **Research note:** use World Skate, Olympics, Street League, X Games, and first-party sources for results.

### 8. Yuto Horigome

- **Why he belongs:** Japan’s first Olympic men’s street champion and a central figure in contemporary technical street skating.
- **Profile angle:** Tokyo and Paris Olympic results, signature technical approach, video parts, and Japan-to-US career path.
- **Model stress test:** multilingual names, Japanese place names, active competition results, and international aliases/transliteration.
- **Starting source:** [official Tokyo 2020 men’s street results](https://library.olympics.com/digitalCollection/DigitalCollectionAttachmentDownloadHandler.ashx?documentId=849134&parentDocumentId=849101&skipCopyright=true&skipWatermark=true).

### 9. Rayssa Leal

- **Why she belongs:** A globally recognized Brazilian street skater and medalist across both Olympic street contests held to date.
- **Profile angle:** early viral visibility, Tokyo silver, Paris bronze, Street League, and progression under intense public attention.
- **Model stress test:** minor-safety editorial rules, rapid career change, nickname handling, and avoiding sensationalized childhood framing.
- **Starting sources:** [IOC Tokyo 2020 marketing report](https://library.olympics.com/digitalCollection/DigitalCollectionAttachmentDownloadHandler.ashx?documentId=1447353&parentDocumentId=1447343&skipCopyright=true&skipWatermark=true), [IOC Paris 2024 analysis](https://library.olympics.com/digitalCollection/DigitalCollectionAttachmentDownloadHandler.ashx?documentId=3416736&parentDocumentId=3416735&skipCopyright=true&skipWatermark=true).

### 10. Sky Brown

- **Why she belongs:** A prominent park skater who brings British and Japanese context and two Olympic cycles into the pilot.
- **Profile angle:** park skating, Olympic medals, cross-cultural background, and influence on young riders.
- **Model stress test:** multilingual/cross-national identity, minor-safety rules, injury reporting, and current-career updates.
- **Starting sources:** [IOC athlete feature](https://newsroom.olympics.com/record/937), [official Tokyo 2020 medalists report](https://library.olympics.com/digitalCollection/DigitalCollectionAttachmentDownloadHandler.ashx?documentId=849134&parentDocumentId=849101&skipCopyright=true&skipWatermark=true).

## Profile information architecture

Each page should use the same core structure while hiding empty optional sections.

1. **Hero and identity:** licensed portrait, display name, native-script name where relevant, pronunciation, nationality/cultural context, hometown, stance, disciplines, active years, and one-sentence significance.
2. **Overview:** an original 150–250 word summary answering who the rider is and why they matter.
3. **Career timeline:** dated milestones with per-item citations.
4. **Skating and influence:** style, terrain, notable contributions, and carefully attributed trick innovations.
5. **Notable tricks:** links to Trickipedia records with relation labels such as `invented`, `popularized`, `signature`, or `notable-performance`. These labels are not interchangeable.
6. **Videos and parts:** title, year, producer, rider role, rights-safe thumbnail, watch link, and media type.
7. **Competition highlights:** selected results, not an unsourced claim to complete statistics.
8. **Companies and sponsors:** role and date range, with an `asOf` date for current relationships.
9. **Related places and events:** meaningful, sourced connections to TrickBook spot and event records.
10. **Sources and revision data:** inline citations, full source list, last fact-check date, editor, and correction link.

Do not add height, weight, relationship status, net worth, home address, injury speculation, or other trivia unless it has clear encyclopedic value and a strong source. Never publish private information.

## Proposed data model

Use a dedicated `encyclopediaRiders` collection. Slugs are stable public identifiers; names and sponsor relationships can change.

```javascript
{
  slug: "rodney-mullen",
  status: "draft" | "review" | "published" | "archived",
  identity: {
    displayName: "Rodney Mullen",
    legalName: String,
    nativeName: String,
    aliases: [String],
    pronunciation: String,
    birthDate: Date,
    birthDatePrecision: "day" | "month" | "year" | "unknown",
    birthPlace: { city: String, region: String, countryCode: String },
    nationalities: [String],
    hometowns: [{ label: String, placeId: ObjectId }]
  },
  skating: {
    stance: "regular" | "goofy" | "ambidextrous" | "unknown",
    disciplines: ["street" | "park" | "vert" | "freestyle" | "big-air"],
    activeYears: { from: Number, to: Number },
    turnedProYear: Number,
    styleTags: [String]
  },
  summary: String,
  biography: [{ heading: String, body: String, citationIds: [String] }],
  timeline: [{ date: String, precision: String, title: String, body: String, citationIds: [String] }],
  trickRelations: [{ trickId: ObjectId, relation: "invented" | "popularized" | "signature" | "notable-performance", note: String, citationIds: [String] }],
  media: [{ type: "video-part" | "documentary" | "interview" | "contest-run", title: String, year: Number, url: String, rights: Object }],
  results: [{ eventId: ObjectId, eventName: String, edition: String, discipline: String, placement: Number, medal: String, citationIds: [String] }],
  affiliations: [{ name: String, role: "sponsor" | "team" | "founder" | "owner", from: String, to: String, asOf: String, citationIds: [String] }],
  sources: [{ id: String, title: String, publisher: String, url: String, publishedAt: Date, accessedAt: Date, sourceType: String }],
  editorial: { factCheckedAt: Date, reviewedBy: ObjectId, notes: String },
  seo: { title: String, description: String },
  createdAt: Date,
  updatedAt: Date
}
```

Unknown values should be `null`, not guessed. Material claims should point to one or more `citationIds`; contentious claims should require two independent reliable sources.

## Routes and discovery

- `GET /riders` — index with search and filters for era, country, discipline, stance, and status.
- `GET /riders/:slug` — public profile with structured data and share metadata.
- `GET /api/riders` — paginated published records; allow `query`, `discipline`, `country`, and `era` filters.
- `GET /api/riders/:slug` — a single published rider and expanded internal links.
- Admin-only create, update, preview, publish, unpublish, and merge endpoints.

Use “Riders” in navigation and URLs. Reserve “user profile” and `/profile` for community accounts. Search results should visually distinguish an encyclopedia rider from a TrickBook member.

## Page and index UX

The index should open with search, compact filter chips, and ten portrait cards. Each card needs name, country, primary discipline, era, and a short significance line. Do not rank the riders.

The profile should place the summary and identity facts above the fold, followed by a horizontal career timeline, linked tricks, selected videos, competition highlights, and sources. On mobile, the fact panel becomes a compact disclosure rather than a long wall before the biography.

Useful internal links are part of the feature, not decoration:

- Rider → trick: “associated with the kickflip” with a precise relationship label.
- Rider → spot: only when a reputable source establishes a meaningful connection.
- Rider → event/result: link to an event entity when one exists; otherwise retain the sourced embedded result.
- Trick/video/event → rider: render reverse links so the encyclopedia becomes a network.

## Editorial and sourcing standard

- Prefer first-party rider sources, official results, federation records, archival skate publications, museums, and direct interviews.
- Wikipedia may help discover sources but should not be the sole source for a material claim.
- Write original summaries; do not copy source biographies.
- Attach citations at the claim or timeline-item level, not only in a footer.
- Label subjective descriptions as attributed opinion. Avoid unsourced “best,” “greatest,” and “first” claims.
- Store access dates and run a recurring broken-link check.
- Treat trick invention claims carefully: distinguish invention, first documented performance, popularization, and signature use.
- For minors, exclude unnecessary personal details and use only licensed, editorially appropriate media.
- Record names in Unicode and support native names and aliases without forcing English-only identity fields.

## Media rights

No profile ships with an image copied from search results, social media, Wikipedia, or a publication merely because it is publicly visible. Every stored asset needs creator/owner, source URL, license or written permission, permitted uses, attribution text, and expiration where applicable.

The pilot may launch with branded silhouettes or typography-first cards until licensed portraits are available. Embedded videos should use the platform embed and thumbnail terms rather than rehosting footage.

## Delivery plan

### Phase 1 — Foundation

- Finalize schema, citation model, slug/alias rules, and admin permissions.
- Build read APIs, draft preview, index, profile template, and basic search/filtering.
- Add `Person` structured data, canonical URLs, Open Graph cards, and a correction route.

### Phase 2 — Five contrasting profiles

Publish Tony Hawk, Rodney Mullen, Elissa Steamer, Yuto Horigome, and Rayssa Leal first. This set exercises legacy and active careers, vert/freestyle/street, innovation claims, women’s history, Olympic results, multilingual names, and minor-safety rules.

### Phase 3 — Complete the ten

Add Daewon Song, Bob Burnquist, Letícia Bufoni, Nyjah Huston, and Sky Brown. Perform a consistency pass across terminology, citation depth, dates, reverse links, and page length.

### Phase 4 — Evaluate before scaling

Review search usage, profile views, outbound video clicks, internal-link clicks, correction submissions, zero-result searches, editorial time per profile, and stale-link rate. Expand only after the model survives the ten-profile review.

## Definition of done

Each pilot rider must have:

- A unique slug, aliases, nationality/cultural context, disciplines, stance when verified, and career range.
- An original overview and at least five dated milestones.
- At least three reliable sources and citations for every material or disputed claim.
- At least two useful internal links, where evidence supports them.
- At least one rights-cleared image or the approved branded fallback.
- Accessible alt text, responsive layout, metadata, structured data, and a visible last-reviewed date.
- Editorial review for naming, sensitive/private data, “first” claims, and media rights.
- Passing API, accessibility, responsive, broken-link, and empty-state tests.

## Explicitly out of scope for the pilot

- Community edits or open wiki editing.
- Rider claiming and identity verification.
- Complete contest databases or automatic sponsor scraping.
- Popularity rankings, “greatest of all time” scores, or unsourced comparison pages.
- AI-generated portraits presented as the real rider.
- Automatically generated biographies published without human fact-checking.

## Decisions needed after the pilot

1. Whether encyclopedia profiles live in the main TrickBook app, a public web knowledge section, or both through the same API.
2. Who has publish rights and who performs factual and media-rights review.
3. Whether verified riders can suggest edits or claim profiles without controlling historical copy.
4. Which content category follows skateboarding: snowboarders, surfers, BMX riders, or a deeper skateboarder catalog.
