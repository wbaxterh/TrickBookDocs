---
sidebar_position: 1
title: "User Feedback Log"
---

# User Feedback Log

Real feedback from TrickBook users. This log helps us prioritize features and track what users actually want.

:::info Contributing
If you have feedback, email **wesleybaxterhuber@gmail.com** or DM us on [Instagram](https://instagram.com/thetrickbook).
:::

---

## 2026-03-23 — Alex Ricketts (via email)

**User since:** Early adopter (since launch)

> Hey man ive been using the app since you put it out and love it. I was trying to add clark and jake but I dont see them when I search in the app. It would be cool to make your trick list public if you want and allow others to comment on or get inspired by creative tricks. Also it would be cool to have feature ideas maybe connected to spots that people could comment on too. Cheers dawg

### Feature Requests Extracted

| # | Request | Category | Priority | Status |
|---|---------|----------|----------|--------|
| 1 | **User search not finding people** — couldn't find "clark" and "jake" | 🐛 Bug / UX | High | 🔍 Investigating |
| 2 | **Public tricklists** — option to share your tricklist publicly | ✨ Feature | High | 📋 Planned |
| 3 | **Tricklist comments** — let others comment on public lists | ✨ Feature | Medium | 📋 Planned |
| 4 | **Tricklist inspiration** — browse others' creative trick combos | ✨ Feature | Medium | 📋 Planned |
| 5 | **Spot features/comments** — comment threads connected to spots | ✨ Feature | Medium | 📋 Planned (spot reviews exist) |

### Analysis

**User search issue (#1):** Likely a partial match / case sensitivity bug in the homies search. Need to verify the search endpoint handles partial name matching and check if "clark" and "jake" are registered users.

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
- [ ] Reply to Alex thanking him for the feedback

---

## 2026-03-24 — Jake (via iMessage)

**Context:** Wes asked for feedback directly

> It's hard to add homies.. I search for Clark and It says It cant find him
> Like if I could just search names and profiles pop up like ig that'd be sick

### Feature Requests Extracted

| # | Request | Category | Priority | Status |
|---|---------|----------|----------|--------|
| 1 | **Homie search broken** — can't find "Clark" by name | 🐛 Bug | 🔴 Critical | 🔍 Investigating |
| 2 | **Better user discovery** — search names and see profile cards like Instagram | ✨ Feature | High | 📋 Planned |

### Analysis

**This is the same search bug Alex reported.** Two users independently can't find friends by name. This is now a **critical priority** — if users can't add friends, the social features are dead.

**Instagram-style discovery (#2):** Jake wants to search a name and see profile cards pop up. Current search likely requires exact username match. Should support:
- Partial name matching (fuzzy search)
- Profile preview cards in search results (avatar, name, bio, trick count)
- Suggested homies (mutual friends, nearby, same spots)

---

## Feedback Summary

| Theme | Mentions | Users | Priority |
|-------|----------|-------|----------|
| **User search/discovery broken** | 2 | Alex, Jake | 🔴 Critical |
| Social/sharing features | 1 | Alex | 🔴 High |
| Better profile discovery (IG-style) | 1 | Jake | 🔴 High |
| Comments/community | 1 | Alex | 🟡 Medium |
| Spot engagement | 1 | Alex | 🟡 Medium |

---

*This log is updated as new feedback comes in. Patterns across multiple users drive feature prioritization.*
