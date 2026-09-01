---
sidebar_position: 8
---

# Event Source and Coordinator Map

Action-sports events are fragmented across governing bodies, professional tours, registration/scoring platforms, regional series, resorts and parks, and media or energy-drink brands. TrickBook needs all of these layers rather than treating one global brand calendar as complete coverage.

## Current Source Inventory

As of August 31, 2026, X Games and The Boardr produce production records. This page is otherwise a source strategy and research backlog, not a list of completed integrations.

| Source | State | Current output | Main limitation |
|---|---|---|---|
| X Games | Active | 13 historical/completed records | Sports and location are inferred; no timezone, disciplines, registration, tickets, or streams |
| The Boardr | Active | 11 upcoming records | U.S.-heavy coverage; no authoritative timezone, coordinates, images, ticketing, or livestream data |
| Development fixtures | Local only | 5 curated future examples | Enabled only by a frontend environment flag; never ingested |
| All other sources below | Research/planned | 0 records | No production connector or persisted source configuration |

There is currently no `eventSources` collection, connector health dashboard, persisted cursor, licensing registry, raw source snapshot store, or source-level retry state. Each production event carries only `source`, `sourceId`, and `sourceUrl`, plus ingestion timestamps on the canonical record.

### Active X Games Feed

- Endpoint: `https://www.xgames.com/wp-json/xgames/v1/events`
- Transport: public JSON containing HTML event cards
- Pagination cap: six pages per run
- Identity: URL slug in `sourceId`; normalized title/date/city in `dedupeKey`
- Refresh behavior: idempotent MongoDB upsert; `lastSeenAt` is refreshed on every successful record
- Failure behavior: page failures are logged and stop further X Games pagination; one source failure does not abort the overall ingestion run

Each new source should follow the tested connector contract: fetch, normalize, stable external identity, provenance, freshness, and fixture-based parser tests. Persisted source health and raw snapshots are the next shared ingestion-layer gaps.

### Active The Boardr Feed

- Endpoint: `https://www.theboardr.com/events`
- Transport: server-rendered Next.js `__NEXT_DATA__` JSON
- Identity: numeric `EventID` in `sourceId` and the stable detail URL
- Coverage at launch: 11 upcoming U.S. events from September 2026 through April 2027
- Normalization: calendar dates are stored at noon UTC with `timeTba: true`; city and state are split from the published location text
- Classification: conservative title/description inference for competition, community, festival, exhibition, BMX inclusion, open entry, and invite-only status
- Failure behavior: missing or changed `__NEXT_DATA__`/`eventList` structure throws an ingestion error and is covered by parser tests

## Source Roles

| Role | What it provides | Examples |
|---|---|---|
| Governing body | Sanctioned calendars, classifications, eligibility, results | World Skate, UCI, FIS, ISA, IWWF |
| Professional tour | Top-level tour stops, tickets, broadcasts | SLS, WSL, Crankworx, Freeride World Tour |
| Registration/scoring platform | Long-tail events, entry state, schedules, results, streams | LiveHeats, The Boardr |
| National or regional series | Local contests riders can actually enter | USASA regional series, USA BMX, ESA |
| Promoter or festival | Multisport event details and registration | X Games, FISE |
| Brand-owned event | Specialty contests and broadcasts | Red Bull Rampage, Rockstar Energy Open |
| Venue or organizer | Grassroots events, clinics, sessions, demos | Resorts, skateparks, cable parks, clubs |

:::warning[Brand calendars are not complete industry calendars]
X Games, FISE, Red Bull, Monster Energy, and Rockstar Energy are high-value sources for headline events. They should supplement governing bodies, tours, and registration platforms—not replace them.
:::

## Cross-Sport Priority Sources

### LiveHeats

The strongest first partnership candidate. LiveHeats supports registrations, schedules, scoring, rankings, and livestreaming across surfing, skateboarding, snowboarding, freeski, BMX, scooter, mountain biking, and related sports.

- API: GraphQL with commercial approval and additional fees
- Best use: stable IDs, entry state, divisions, schedules, results, and streams
- Action: request pricing, rights, attribution rules, polling limits, and webhook availability

### X Games

Coordinates major skateboarding, BMX, motocross, ski, and snowboard events. Its official schedule is a top-tier source for dates, tickets, and broadcast actions, but not grassroots coverage.

### FISE / Hurricane Group

Coordinates international urban-sports festivals and operates UCI BMX Freestyle World Cup events. Coverage includes BMX freestyle, skateboarding, scooter, roller freestyle, and other festival disciplines. Approach Hurricane Group for a tour feed.

### Red Bull

Both promoter and broadcaster. It owns or coordinates properties such as Rampage, Hardline, and District Ride, while Red Bull TV exposes live viewing. Treat it as authoritative when it owns or directly operates an event, not merely when it sponsors one.

### Monster Energy

Maintains an official events schedule and sponsors many tours. Use its listings for discovery and enrichment; prefer the underlying tour or organizer as the primary record.

### Rockstar Energy

Operates selected properties such as the Rockstar Energy Open and sponsors other events. Monitor owned-event pages and identify the actual coordinator for sponsored events.

## Industry Maps

### Skateboarding

- World Skate and national federations: sanctioned and Olympic-path events
- Street League Skateboarding: professional street tour
- X Games: street, park, vert, and specialties
- The Boardr: broad calendar, registration, and results
- FISE / Hurricane Group: international urban-sports festivals
- Skatepark of Tampa: Tampa Am and Tampa Pro
- Exposure Skate: women's, nonbinary, and adaptive competition
- Grind for Life / The Boardr Series: open regional contests
- Rockstar Energy Open and Red Bull-owned properties
- Local skateparks, municipalities, shops, and promoters

Priority: LiveHeats and The Boardr; then World Skate, SLS, X Games, and FISE; then specialist series and verified local feeds.

### BMX

Separate racing from freestyle.

- UCI: international racing and freestyle calendars
- USA BMX: national, Gold Cup, state, and track racing
- USA Cycling: U.S. national championships
- FISE / Hurricane Group: UCI BMX Freestyle World Cup operations
- X Games: BMX freestyle
- The Boardr and LiveHeats: selected contests
- National federations, tracks, parks, and promoters

### Mountain Biking

Use discipline tags for downhill, enduro, cross-country, slopestyle, freeride, dual slalom, pump track, and e-MTB.

- UCI and WHOOP UCI Mountain Bike World Series
- Crankworx
- Freeride Mountain Bike World Tour (FMB)
- Red Bull Rampage, Hardline, District Ride, and related properties
- USA Cycling and other national federations
- Regional series, bike parks, and local promoters

### Scooter

- World Skate and national federations
- International Scooter Association and affiliated bodies where active
- FISE
- LiveHeats
- Skateparks, shops, and local promoters

Scooter has less consistent global infrastructure, making verified organizer submissions especially important.

### Rollerblading / Roller Freestyle

- World Skate and World Skate Europe
- FISE roller freestyle
- LiveHeats where used
- National roller-sport federations and independent promoters

Map source terms including `roller freestyle`, `inline freestyle`, and `aggressive inline` to TrickBook's `rollerblading` sport.

### Surfing

- World Surf League: CT, Challenger, QS, longboard, junior, and regional events
- International Surfing Association: world and federation events
- USA Surfing and national bodies
- LiveHeats: regional associations, boardrider clubs, registration, draws, and results
- Eastern Surfing Association, NSSA, Surfing America, and regional associations
- Specialty-event owners and local clubs

Surf requires separate event-window and day-of competition-call states (`It's On`, standby, completed).

### Wakeboarding

- World Wake Association: Wakeboard World Series and Nautique championships
- IWWF: boat/cable world events and EMS registration
- Pro Wakeboard Tour and major boat-brand series
- National associations, cable parks, dealers, clubs, and grassroots series
- LiveHeats where adopted

Separate boat wakeboard, cable wakeboard, wakesurf, and wakeskate.

### Snowboarding

- FIS: World Cups, championships, continental cups, and results
- USASA: U.S. grassroots regional series and nationals
- U.S. Ski & Snowboard and national bodies
- Freeride World Tour pathways
- X Games and Dew Tour
- LiveHeats
- Resorts, terrain parks, regional series, shops, and brand events

USASA competitions are operated by regional series directors, so national listings alone are insufficient for local entry opportunities.

### Skiing / Freeski

- FIS
- U.S. Ski & Snowboard, USASA, and national federations
- Freeride World Tour pathways
- X Games and Dew Tour
- IFSA/youth freeride organizers, resorts, terrain parks, and local series
- LiveHeats where adopted

The shared snow connector layer normalizes source terminology while retaining separate `skiing` and `snowboarding` sports.

## Integration Research Queue

For every source, record:

- Organizer and legal entity
- Sports, disciplines, geography, and event level
- Calendar, registration, ticket, result, and stream URLs
- API, feed, iCalendar, RSS, JSON-LD, or export availability
- Authentication and rate limits
- Display, caching, attribution, and retention rights
- Stable external ID and update timestamps
- Cancellation/postponement behavior
- Partnership contact and status

## Recommended Outreach Order

1. LiveHeats
2. The Boardr
3. FISE / Hurricane Group
4. World Skate
5. UCI and WHOOP UCI Mountain Bike World Series
6. WSL and ISA
7. FIS, USASA, and U.S. Ski & Snowboard
8. WWA and IWWF
9. X Games
10. Red Bull, Monster Energy, and Rockstar Energy

This order optimizes usable event volume and registration data before brand enrichment.

## Verified Starting Points

- [LiveHeats API](https://support.liveheats.com/hc/en-us/articles/360059474652-Using-the-LiveHeats-API)
- [The Boardr events](https://www.theboardr.com/events)
- [X Games schedule](https://www.xgames.com/schedule/)
- [FISE World Series](https://www.fiseworldseries.com/)
- [World Skate Europe calendar](https://europe.worldskate.org/skateboarding/)
- [UCI BMX Racing calendar](https://www.uci.org/calendar/bmx-racing/6E4kyzTNAnHJlur4sVcIvV)
- [FMB World Tour calendar](https://www.fmbworldtour.com/calendar/)
- [Crankworx](https://www.crankworx.com/)
- [WSL events](https://www.worldsurfleague.com/events)
- [ISA](https://isasurf.org/)
- [WWA Wakeboard World Series](https://www.thewwa.com/wakeboard-world-series/)
- [IWWF EMS](https://ems.iwwf.sport/)
- [FIS snowboard calendar](https://www.fis-ski.com/DB/snowboard/calendar-results.html)
- [Freeride World Tour](https://www.freerideworldtour.com/)
- [Monster Energy events](https://www.monsterenergy.com/en-us/events/)
- [Red Bull live events](https://www.redbull.tv/events)
- [Rockstar Energy Open](https://www.rockstarenergy.com/pages/rseo)
