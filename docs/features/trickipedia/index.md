---
sidebar_position: 1
---

# Trickipedia

The trick encyclopedia and personal trick-list system — TrickBook's core feature.

## Overview

Trickipedia is a moderated trick encyclopedia covering seven action sports. Users browse tricks with steps, videos, and sources; add tricks to personal **TrickLists**; and track per-trick progress. Skateboarding and snowboarding tricks additionally carry an editorial **progression network** (prerequisites / next steps / related).

Current production catalog (as of 2026‑09‑11): **144 tricks** — Skateboarding 47, Snowboarding 74, BMX 6, Surfing 7, Longboarding 4, Inline 2, Scooter 2 — with **807 progression edges** across the two networked categories.

## Data model

### Collection: `trickipedia`

```js
{
  _id: ObjectId,
  name: "Kickflip",
  url: "kickflip",              // unique slug; page route /trickipedia/<category>/<url>
  category: "Skateboarding",    // one of the 7 sport categories
  difficulty: "Intermediate",   // Beginner | Intermediate | Advanced
  description: String,
  steps: [String],
  images: [String],             // S3-hosted
  videos: [{ url, platform, title, thumbnailUrl }],  // multi-video (YouTube/Instagram/TikTok)
  videoUrl: String,             // legacy single video, still rendered as fallback
  source: String,               // citation for the write-up
  ccAttribution: String,        // license attribution where required
  tutorials: [{ title, canonicalUrl, availability, featured, instructor }],
  progression: {
    prerequisites: [Edge],      // learn these first (ordering semantics)
    nextSteps:     [Edge],      // natural follow-ups
    related:       [Edge]       // variations / companion skills (no ordering)
  },
  audit: Object,                // provenance of automated content passes
  createdAt, updatedAt
}
```

Each progression **Edge** is `{ trickId, reason, order, research: { status, confidence, evidence: [{ url, claim, checkedAt }] } }`. Edges follow the editorial lifecycle `draft → reviewed → published` (or `draft → rejected`); only `reviewed`/`published` edges are ever served. See the [formal specification](./formal-spec.md) for the verified invariants of this design.

### Collections: `tricklists` and `tricks`

Personal lists live in **two** collections: `tricklists` holds the list documents (name, owner, visibility, an array of member trick `_id`s), and `tricks` holds the individual list entries. An entry stores the user's copy of the trick — name, notes, status — plus optional links outward:

- `trickipediaId` — back-reference to the encyclopedia entry it was added from
- `spotId` — the spot where the trick was landed (see [Spots](/docs/features/spots))
- `videoUrl` / `feedPostId` — proof clip and feed cross-post

Per-trick status on mobile: `Not Started | Learning | Landed | Mastered` (legacy values `To Do / Complete / Completed` still normalize).

## Backend API

**File:** `Backend/routes/trickipedia.js` · **Base:** `https://api.thetrickbook.com/api`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/trickipedia` | List tricks. Filters: `category`, `sportType`, `difficulty`, `search` (regex-escaped name/description). Pagination: `limit` (default 100, max 250), `skip` | No |
| GET | `/trickipedia/url/:slug` | Get trick by slug | No |
| GET | `/trickipedia/:id` | Get trick by id | No |
| GET | `/trickipedia/category/:category` | Tricks in a category (+ `difficulty`, `search`) | No |
| GET | `/trickipedia/:id/network` | Progression network (see below) | No |
| POST / PUT / DELETE | `/trickipedia[/:id]` | Create / update / delete | JWT + `role: admin` |

The **network endpoint** returns `{ trick, foundations, nextSteps, related, featuredTutorial, alternateTutorials }`. It only exposes edges with `research.status ∈ {reviewed, published}`, hydrates each edge with the linked trick's card fields, silently drops edges whose target no longer resolves, and sorts by `order`.

Trick-list routes (`routes/listings.js` for lists, `routes/listing.js` for entries):

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/listings` | A user's lists (visibility-aware) | Optional JWT¹ |
| POST | `/listings` | Create list | JWT |
| PUT | `/listings/edit` | Rename / edit list | JWT |
| PUT | `/listings/:id/visibility` | Toggle public/private | JWT |
| GET | `/listings/public` | Community (public) lists | Optional JWT¹ |
| DELETE | `/listings/:id` | Delete list | JWT |
| GET | `/listing?list_id=` | Entries in a list | Optional JWT¹ |
| PUT | `/listing` | Add entry (accepts `trickipediaId`, `spotId`, `videoUrl`, `feedPostId`) | JWT (owner/admin) |
| PUT | `/listing/update` | Update entry status/notes | JWT (owner/admin) |
| PUT | `/listing/:trickId/spot` · `/video` | Link/unlink spot or proof video | JWT (owner/admin) |
| DELETE | `/listing/:id` | Remove entry | JWT (owner/admin) |

¹ Optional-auth reads use `verifyTokenWithGrace` (30-day expired-JWT grace) so a stale session still sees its own private lists instead of an empty page.

## Website (Next.js)

| Route | File | Purpose |
|-------|------|---------|
| `/tricklist` | `pages/tricklist.js` | Trickipedia landing — category chooser |
| `/trickipedia/[category]` | `pages/trickipedia/[category].js` | Category browse with client-side search |
| `/trickipedia/[category]/[trick]` | `pages/trickipedia/[category]/[trick].js` | Trick detail: steps, multi-platform video chips, source links, **Add to TrickList** modal |
| `/trickbook` | `pages/trickbook.js` | "My TrickBook" — personal list manager (create/edit/delete, public/private) |

Shared components: `TrickCard.js`, `TrickipediaSidebar.js`. Trickipedia page styling lives in `styles/trickipedia.module.css` and is **theme-aware by requirement**: link/chip/typography colors go through module classes with `:global(.dark)` overrides, never hardcoded inline colors. Both themes were contrast-audited page-by-page (WCAG) in Sep 2026.

## Mobile app (Expo Router)

| Screen | File | Purpose |
|--------|------|---------|
| TrickBook tab | `app/(tabs)/trickbook/index.tsx` | Two tabs: **Trickipedia** browse and **My TrickLists** |
| Trick detail | `app/(tabs)/trickbook/[trickId].tsx` | Steps, videos, add-to-list |
| List detail | `app/(tabs)/trickbook/list/[listId].tsx` | Entries with per-trick status tracking |

API client: `src/lib/api/trickbook.ts` · types: `src/types/trickbook.ts` · components: `src/components/trickbook/` (`TrickCard`, `TrickRow`, `TrickListCard`).

## Progression network status

- **Data + API: live.** All 47 skateboarding and 74 snowboarding tricks have researched, evidence-backed edges (`scripts/migrate-skateboarding-network.js` pattern; dry-run by default, `--apply`). BMX, Surfing, Longboarding, Inline, and Scooter don't have networks yet — the same script pattern extends to them.
- **Client UI: not yet shipped.** Neither the website trick page nor the mobile app renders the network endpoint today; see the [first-pass rollout plan](/docs/roadmap/trickipedia-network-first-pass).
- **Integrity is verified.** The design is model-checked and the live data is auditable: `scripts/check-trickipedia-invariants.js` checks self-edges, dangling references, category consistency, statuses, and prerequisite acyclicity against any environment (exit 1 on violations — suitable as a CI gate). Details and results: [Formal Verification](./formal-spec.md).

## Related documentation

- [Trickipedia: Formal Verification (TLA+)](./formal-spec.md)
- [Progression network rollout plan](/docs/roadmap/trickipedia-network-first-pass)
- [Spots](/docs/features/spots) — spot↔trick linking
