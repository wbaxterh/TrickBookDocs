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

## Feedback Summary

| Theme | Mentions | Priority |
|-------|----------|----------|
| Social/sharing features | 1 | 🔴 High |
| User discovery/search | 1 | 🔴 High |
| Comments/community | 1 | 🟡 Medium |
| Spot engagement | 1 | 🟡 Medium |

---

*This log is updated as new feedback comes in. Patterns across multiple users drive feature prioritization.*
