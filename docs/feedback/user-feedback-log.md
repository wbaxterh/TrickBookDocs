---
sidebar_position: 1
title: "User Feedback Log"
---

# User Feedback Log

Real feedback from TrickBook users. This log helps us prioritize features and track what users actually want. Users are identified by initials only, and messages are paraphrased rather than quoted.

:::info[Contributing]
If you have feedback, DM us on [Instagram](https://instagram.com/thetrickbook).
:::

---

## 2026-03-23 — A.R. (via email)

**User since:** Early adopter (since launch)

**Summary of the message:** A long-time user who likes the app could not find two friends when searching for them in the app. They also asked for the option to make a trick list public so others can comment on it or get inspired by creative tricks, and for comment threads attached to spots.

### Feature Requests Extracted

| # | Request | Category | Priority | Status |
|---|---------|----------|----------|--------|
| 1 | **User search not finding people** — could not find two friends by name | 🐛 Bug / UX | High | 🔍 Investigating |
| 2 | **Public tricklists** — option to share your tricklist publicly | ✨ Feature | High | 📋 Planned |
| 3 | **Tricklist comments** — let others comment on public lists | ✨ Feature | Medium | 📋 Planned |
| 4 | **Tricklist inspiration** — browse others' creative trick combos | ✨ Feature | Medium | 📋 Planned |
| 5 | **Spot features/comments** — comment threads connected to spots | ✨ Feature | Medium | 📋 Planned (spot reviews exist) |

### Analysis

**User search issue (#1):** Likely a partial match / case sensitivity bug in the homies search. Need to verify the search endpoint handles partial name matching and check whether the two friends are registered users.

**Public tricklists (#2-4):** This is a high-value social feature. Currently all tricklists are private. Adding a `public: boolean` field + a discovery feed of public lists would:
- Drive engagement (browse what others are working on)
- Create organic content (user-curated trick progressions)
- Encourage friendly competition
- Pair naturally with the existing feed system

**Spot comments (#5):** We already have `spotReviews.js` — this may just need better frontend surfacing or a rename from "reviews" to "comments" to feel more social.

### Action Items

- [ ] Debug user search for partial name matching
- [ ] Design public tricklist feature (schema: `isPublic` flag, discovery endpoint, privacy toggle)
- [ ] Evaluate spot reviews → spot comments rename / enhancement
- [ ] Reply to A.R. thanking them for the feedback

---

## 2026-03-24 — J. (via message)

**Context:** Wes asked for feedback directly

**Summary of the message:** Adding homies is hard. A search for a friend by name returned no result. The user would like to type a name and see profile cards appear, the way Instagram search works.

### Feature Requests Extracted

| # | Request | Category | Priority | Status |
|---|---------|----------|----------|--------|
| 1 | **Homie search broken** — cannot find a friend by name | 🐛 Bug | 🔴 Critical | 🔍 Investigating |
| 2 | **Better user discovery** — search names and see profile cards like Instagram | ✨ Feature | High | 📋 Planned |

### Analysis

**This is the same search bug A.R. reported.** Two users independently cannot find friends by name. This is now a **critical priority** — if users cannot add friends, the social features are dead.

**Instagram-style discovery (#2):** J. wants to search a name and see profile cards pop up. Current search likely requires exact username match. Should support:
- Partial name matching (fuzzy search)
- Profile preview cards in search results (avatar, name, bio, trick count)
- Suggested homies (mutual friends, nearby, same spots)

---

## Feedback Summary

| Theme | Mentions | Users | Priority |
|-------|----------|-------|----------|
| **User search/discovery broken** | 2 | A.R., J. | 🔴 Critical |
| Social/sharing features | 1 | A.R. | 🔴 High |
| Better profile discovery (IG-style) | 1 | J. | 🔴 High |
| Comments/community | 1 | A.R. | 🟡 Medium |
| Spot engagement | 1 | A.R. | 🟡 Medium |

---

*This log is updated as new feedback comes in. Patterns across multiple users drive feature prioritization.*
