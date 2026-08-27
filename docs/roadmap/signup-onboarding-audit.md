---
sidebar_position: 11
title: Signup & Onboarding Audit
description: A walkthrough of the current web signup flow with conversion + retention recommendations.
---

# Signup & Onboarding Audit (Web)

_Audited August 2026 via an automated browser walkthrough of `thetrickbook.com/signup` plus a code review of `pages/signup.js`, `pages/login.js`, and the next-auth config. The walkthrough filled the form with test data and stopped **before** creating an account._

## TL;DR

The web signup is a **4-step wizard**, and its single biggest problem is that **the account isn't created until the final step**. Every user who drops off at step 2, 3, or 4 leaves with **no account** — so we can't email them, re-engage them, or even count them as a signup. On top of that, social login is buried below four password fields, and the last step is a **16-field vanity form** before the account exists.

**Highest-leverage fixes:** create the account at step 1 (email/social), lead with social auth, delete the confirm-password field, and move everything after "create account" into a **skippable, non-blocking** post-signup flow that lands the user on an activation moment (the spots map) rather than an empty profile.

## Current flow

| Step | Screen | What it asks | Account exists? |
|------|--------|--------------|-----------------|
| 1 | Create Your Account | Name, Email, Password, **Confirm Password** — or Google / Apple (below the fold) | ❌ No |
| 2 | Choose Your Avatar | Upload a photo, or pick 1 of 12 emoji icons | ❌ No |
| 3 | What Do You Ride? | Multi-select from 9 sports | ❌ No |
| 4 | Rider Profile | **~16 optional fields** (nickname, style, age, motto, sickest trick, dream date, favorite movie/music/reading…) | ✅ Only on "Create My Account" |

After submit, the user is redirected to `/profile` (their empty profile).

### Step 2 — Choose Your Avatar

![Signup step 2 — avatar picker](/img/signup/step2-avatar.jpg)

### Step 3 — What Do You Ride?

![Signup step 3 — sport selection](/img/signup/step3-sports.jpg)

### Step 4 — Rider Profile (16 fields, before the account exists)

![Signup step 4 — rider profile form](/img/signup/step4-rider-profile.jpg)

## Conversion problems (ranked)

1. **The account is created last.** The wizard only calls the register endpoint on step 4's "Create My Account." Abandon at step 2–4 → no account, no email, no re-engagement, not counted. This is the #1 funnel leak. **Create the account as early as possible (step 1)**; treat everything after as resumable onboarding.
2. **Social login is buried.** Google / Apple sit *below* four password fields. Social auth is one tap, needs no password, and returns a verified email — it typically converts far better. **Lead with "Continue with Google / Apple"**; make email the secondary path.
3. **Confirm-password field.** Adds friction and error states. **Drop it** in favor of a single password field with a show/hide toggle.
4. **A 16-field form gates account creation.** Even labeled "optional but fun," step 4 reads as a wall of work, and the "Skip to finish" link is small and easy to miss. **Move the rider card entirely post-signup** (an in-profile "complete your rider card" prompt), and trim it — 16 vanity fields is over-scoped for onboarding.
5. **No value or proof before the ask.** `/signup` drops straight into a form: no headline, no social proof (we have **4,900+ spots across 48 countries** and real events to point at), no product preview. This is exactly where eliza.app's homepage wins — a benefit-led hero, visible social proof, and one clear CTA above the fold. Our signup has no motivation layer.
6. **Lands on a dead end.** Post-signup redirect to `/profile` shows an empty profile. **Land on an activation moment** instead — the spots map centered on their location, "find riders near you," or "log your first trick."
7. **Emoji avatars.** 12 emoji "icons" as the avatar set reads low-fidelity for the brand (and cuts against the emoji-cleanup direction elsewhere). Prefer photo upload + generated/initials avatars.

## Bugs found in the signup code

:::danger[Real bug]
- **Avatar photo upload is stubbed.** The step-2 photo is never persisted — the code has `// This would need a separate endpoint - for now we'll handle it later`. So a user who uploads a signup avatar loses it. (Related to the web-vs-app profile-picture precedence issue.)
:::

:::note[Flagged but verified NOT broken]
Two things initially looked like bugs but check out on closer inspection:
- **`NEXT_PUBLIC_BASE_URL` in the register call** — this env var **is** set and is used across the app (settings, profile, next-auth, payments) as the API host, so `` `${NEXT_PUBLIC_BASE_URL}/api/users` `` resolves correctly. It differs from `NEXT_PUBLIC_API_BASE_URL` (which already includes `/api`).
- **`logIn(loginResult.token)`** — `signIn('credentials')` returns no `token`, so that argument is `undefined`, but `signIn` sets the next-auth **session cookie** on success and `AuthContext` reads it, so login works. It was cleaned up (`logIn(null, email)`) rather than left relying on the redundant call.
:::

## Implemented from this audit

- **Social-first step 1** — "Continue with Google / Apple" now lead, above the email form.
- **Single password field** with a show/hide toggle (removed the confirm-password field + its error state).
- **Activation landing** — new users go to `/spots` (the map) instead of an empty `/profile`.

Still open (larger): **create the account at step 1** (make steps 2–4 skippable post-signup onboarding), trim the 16-field rider card, and add a value/proof hero to the signup page.

## Retention recommendations

- **Activation-first onboarding.** Guide the new user to exactly **one meaningful action** (save a spot, follow a homie, log a trick). First-action users retain dramatically better than passive signups.
- **Progressive profiling.** Collect the rider-card details over time via in-app prompts, never upfront.
- **Use the sport selection.** Personalize the first post-signup screen with their sports — spots filtered to their sports, events for their sports, riders who share them. Today the selection isn't obviously leveraged after signup.
- **Lifecycle email.** Because the account now exists early, send a welcome email with a clear next step, then day-1 / day-3 / day-7 nudges. (The backend already has a reminder/notification system to build on.)
- **Network effects.** Prompt "find your homies" / connect contacts early — social graph is the strongest retention lever for a community app.
- **Habit loops.** Trick-logging streaks and weekly session reminders (push infra already exists).

## Recommended redesign

**1. Signup page = value + social-first + minimal.**
- Above the fold: a tight value prop + social proof ("4,900+ spots, real events, your crew"), then **"Continue with Google" / "Continue with Apple"** as the primary CTAs, with **"Sign up with email"** (email + one password w/ show-hide) as the secondary path.
- **Create the account here.**

**2. Post-signup onboarding = 2 light, skippable, non-blocking steps.**
- (1) Pick sports (personalization), (2) optional avatar. Everything else (the rider card) becomes an in-profile prompt.

**3. Land on activation, not the profile.**
- Send them to the spots map centered on their location (or "find riders near you") so they hit the aha and take a first action immediately.

**4. Let people explore before committing.**
- The map with thousands of spots and real events is the value — surface it pre-signup and gate only the *save/follow* actions behind account creation (which is now one tap).

> North star: eliza.app's homepage converts because it shows value + social proof and offers a single, low-friction CTA above the fold. TrickBook has stronger raw proof (thousands of spots, real events) — we just need to *show* it before asking for a commitment, and make that commitment one tap.
