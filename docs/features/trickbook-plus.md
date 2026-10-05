---
title: TrickBook Plus
---

# TrickBook Plus and Free-Tier Limits

**Status:** Live<br />
**Price:** $10 per month through Stripe Checkout, web only<br />
**Last verified against production:** October 5, 2026

This page describes the monetization that exists today: one subscription, three kinds of free-tier limit, and the surfaces that show them. The companion paywall and voice-token model that extends it is a roadmap item: [Monetization: Paywall & Tokens](/docs/roadmap/monetization).

## What a rider gets

| | Free | Plus |
|---|---|---|
| Named spot lists | 3 | unlimited |
| Spots per list | 5 | unlimited |
| Total saved spots | 15 | unlimited |
| Kaori text replies | 20 per day | 250 per day |
| Kaori voice replies | 5 per day | 200 per month |
| Kaori burst limit | 6 per minute per account, 10 per device | 12 per minute per account, 20 per device |
| Verified badge on profile | no | yes |
| Price | $0 | $10 per month |

The default "Saved Spots" bucket does not count toward the list limit. Above the per-user allowances sits one global safety budget of 5,000 Kaori text replies per day across all users (`KAORI_DAILY_TEXT_BUDGET`).

## How entitlement is decided

`users.subscription` in MongoDB is the single source of truth. `hasPremiumAccess()` in `middleware/subscription.js` returns true when `plan` is `premium` and `status` is `active` or `canceled`, so a canceled subscription keeps access until the paid period ends. Admins can set `subscription.adminOverride` to `free` or `premium` to test either tier. Every surface reads the server; none of them trust client-side store state.

## Where limits are enforced

| Limit | Enforced in | Response when exceeded |
|---|---|---|
| Spot lists and spots | `middleware/subscription.js` on `POST /api/spotlists` and `POST /api/spotlists/:id/spots` | `403` with `limit`, `current`, and `upgradeRequired: true` |
| Kaori text | `services/kaoriUsage.js`, called from the bot-chat route (mobile) and the DM route (web) | `402` with `code: ALLOWANCE_EXHAUSTED`, `resetsAt`, and `upgradeRequired: true` for free users |
| Kaori voice | same service, `consumeVoice()` | the text reply still returns; the reply is not spoken and the usage payload reports `remaining: 0` |
| Kaori bursts | same service, per account and per device | `429` with `code: RATE_LIMITED` or `DEVICE_RATE_LIMITED` and `retryAfter: 60` |

Kaori metering shipped to production on September 30, 2026 (TB-Backend #68). It takes a single-generation lease per user and reserves the allowance atomically before generating, so a retry or a second tab cannot double-spend, and it refunds the reservation when generation fails. Usage is readable at `GET /api/companion/kaori/usage` (text and voice: used, limit, remaining, reset time) and `GET /api/spotlists/usage` (counts, limits, `isPremium`).

## Surfaces

| Surface | Current behavior |
|---|---|
| Web settings (`/settings`) | Plan card, usage meters for lists and total spots, "Upgrade Now - $10/month" into Stripe Checkout, cancel and reactivate for Plus members |
| Web Kaori widget | Shows text and voice balances. When the daily text allowance is spent it shows "Upgrade to TrickBook Plus for a larger daily allowance", and it disables the voice control when the voice allowance is spent |
| Mobile account screen | Shows Free Plan or TrickBook Plus and a premium badge on the profile. The "Upgrade - $10/month" and "Manage Subscription" buttons are placeholders: there is no in-app purchase path, and no limit or upgrade UI when Kaori allowances run out |

## Stripe lifecycle

- `POST /api/payments/create-checkout-session` creates or reuses the Stripe customer, then opens a subscription Checkout session for `STRIPE_PREMIUM_PRICE_ID`, falling back to an inline $10/month "TrickBook Plus" price when the id is unset. `STRIPE_PREMIUM_YEARLY_PRICE_ID` exists in the environment but nothing reads it.
- `GET /api/payments/subscription`, `POST /api/payments/cancel-subscription`, `POST /api/payments/reactivate-subscription`, and `POST /api/payments/admin/toggle-subscription`.
- `POST /api/payments/webhook` handles `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_succeeded`, and `invoice.payment_failed`, writing `subscription.plan`, `status`, `stripeSubscriptionId`, `currentPeriodEnd`, and `lastPaymentDate` with dotted `$set` paths.
- If `STRIPE_SECRET_KEY` is unset the server logs a warning and the payment routes are disabled.

## Analytics

The web widget emits `kaori_paywall_viewed` and `kaori_upgrade_clicked`. The wider funnel vocabulary (`paywall_viewed`, `checkout_started`, `trial_started`) is specified in [Retention and LTV](/docs/roadmap/retention-ltv) and is not instrumented yet.

## Not built yet

- Mobile purchases (RevenueCat or StoreKit) and any mobile upgrade or limit UI.
- Voice tokens, wallets, top-up packs, `usage_events`, and companion roster gating from the roadmap.
- Yearly billing: the price id is configured, nothing uses it.
- Signed Kith admission tickets for the voice endpoint.

## Related Documentation

- [Monetization: Paywall & Tokens](/docs/roadmap/monetization)
- [Backend API](/docs/backend/api-endpoints)
- [Database](/docs/backend/database)
- [Data Flow](/docs/architecture/data-flow)
- [AI Companions](/docs/features/ai-companions)
