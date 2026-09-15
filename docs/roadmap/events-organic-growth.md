---
sidebar_position: 19
---

# Events Organic Growth Plan

**Created:** September 15, 2026  
**Status:** In progress

## Why Events Are the Priority

Event pages are already bringing new visitors to TrickBook through Google, with one Malibu event accounting for most of the observed event traffic. The immediate goal is to reproduce that result across dozens of useful, trustworthy event pages and convert more of those visitors into riders.

The current web MVP has strong event data and usable detail pages, but several technical gaps make discovery inconsistent:

- Event details are fetched only after the browser loads the page.
- Published events are absent from `sitemap.xml`.
- Event pages do not yet emit Schema.org `Event` structured data.
- Canonical, Open Graph, and Twitter metadata are missing.
- Detail-page saves are disabled even though authenticated save endpoints exist.
- Event pages do not link to related events, Spots, or Trickipedia content.
- Analytics retain the referrer but discard landing-page query parameters and UTMs.

## Outcomes

1. Make every published event independently crawlable and eligible for event search features.
2. Build connected sport, location, organizer, venue, and series clusters rather than isolated pages.
3. Give visitors a reason to return through saves, calendar actions, and reminders.
4. Convert event visitors into TrickBook users with sport-specific calls to action.
5. Preserve first-touch acquisition data through signup and outbound App Store visits.

## Phase 1: Indexing Foundation

**Priority: immediate**

- Server-render `/events/[slug]` so the event title, description, date, venue, and actions are present in the initial HTML.
- Return a real HTTP 404 for missing or unpublished events.
- Add a unique title and description using the event name, sport, date, and location.
- Add a canonical URL, `index, follow, max-image-preview:large`, Open Graph fields, and Twitter card fields.
- Emit Schema.org `Event` JSON-LD whose values match the visible page:
  - `name`, `description`, `startDate`, and `endDate`
  - `eventStatus` and `eventAttendanceMode`
  - physical or virtual location
  - image, organizer, registration/ticket offer, and canonical URL
- Include all published event URLs in the sitemap with meaningful `lastmod` values.
- Keep completed event URLs live; update them with results, recap media, and the next edition instead of deleting accumulated search equity.
- Validate representative records with Google's Rich Results Test and Search Console URL Inspection.

## Phase 2: Conversion and Retention

- Add a visible, sport-specific TrickBook module after the event summary.
- Add a sticky mobile App Store or signup call to action without obscuring the event's primary registration/watch action.
- Connect event detail saves to the existing authenticated API.
- Allow anonymous local saves and reconcile them after signup or login.
- Add Google Calendar and downloadable iCalendar actions.
- Track the full event funnel:
  - `event_viewed`
  - `event_saved`
  - `calendar_added`
  - `registration_clicked`
  - `ticket_clicked`
  - `stream_clicked`
  - `related_event_clicked`
  - `app_store_clicked`
  - signup completion attributed to the originating event

## Phase 3: Internal Linking and Topic Clusters

Every event detail page should link to relevant destinations:

- Events in the same sport or discipline
- Events near the same city, region, or venue
- Events from the same organizer or series
- A matching TrickBook Spot
- Relevant Trickipedia content
- The next or previous annual edition

Add visible breadcrumbs following `Events -> Sport -> Region -> Event`. Related-event ranking should prefer future, geographically close records, then the same organizer, series, sport, and discipline.

## Phase 4: Information Quality and Trust

- Show multi-day schedules and local timezone clearly.
- Surface registration deadlines, pricing, divisions, eligibility, stream details, and venue maps.
- Make organizer and source names clickable.
- Display source trust and the last verified timestamp.
- Distinguish scheduled, postponed, cancelled, live, and completed states in both visible content and structured data.
- Flag stale records for review rather than silently presenting potentially outdated information.
- Add results, winners, recap videos, and subsequent editions to historical pages.

## Phase 5: Attribution

Persist first-touch acquisition once per browser and attach it to relevant analytics events:

```js
{
  landingUrl,
  landingPath,
  initialReferrer,
  utmSource,
  utmMedium,
  utmCampaign,
  utmContent,
  utmTerm,
  firstEventId,
  firstEventSlug,
  firstTouchedAt
}
```

Store latest-touch context separately. Carry first-touch values through signup and outbound App Store clicks. Traffic with no usable referrer should remain `direct/unknown`; it should not automatically be interpreted as intentional direct navigation.

## `llms.txt` Decision

Do not create one `llms.txt` per event. If adopted, publish one site-level `/llms.txt` that links to the Events directory, Trickipedia, Spots, and a public feed or API description.

`llms.txt` is an emerging machine-consumption convention, not a Google ranking feature and not a substitute for crawlable HTML, sitemaps, canonical URLs, or Schema.org markup. A public JSON/RSS/Atom event feed is more useful for record-level machine discovery than hundreds of per-event text files.

## Delivery Order

1. Server rendering, metadata, JSON-LD, 404 behavior, and sitemap coverage
2. Event funnel analytics and first-touch attribution
3. Save synchronization and calendar actions
4. Related-event, Spot, organizer, and Trickipedia links
5. Event alerts and richer historical pages

## Measurement

Primary metrics:

- Non-branded organic entrances to event pages
- Number and percentage of event URLs indexed
- Search impressions, clicks, click-through rate, and average position by event
- Organic traffic concentration among the top 1, 5, and 10 event pages
- Event save, registration, calendar, stream, signup, and App Store conversion rates
- Returning visitors from saved events and reminders

Guardrails:

- Structured-data validation errors
- Stale or cancelled event exposure
- Duplicate event pages
- Soft 404s
- Broken registration, ticket, and stream links
- Organic traffic share carried by the single highest-traffic event

## Research References

- [Google Event structured data](https://developers.google.com/search/docs/appearance/structured-data/event)
- [Google sitemap guidance](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)
- [Google canonical URL guidance](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)
- [Google Analytics campaign URL guidance](https://support.google.com/analytics/answer/10917952)
- [`llms.txt` proposal](https://llmstxt.org/)

See [Events](/docs/features/events) for the current product and API implementation and [Event Source and Coordinator Map](/docs/features/event-sources) for ingestion priorities.
