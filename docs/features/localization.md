---
sidebar_position: 12
---

# Localization (i18n)

Full multilingual support for the web app, mobile app, and all spot content.

**Status:** 🚧 In development — tracked in [TrickBookWebsite#8](https://github.com/wbaxterh/TrickBookWebsite/issues/8)

## Overview

TrickBook is going multilingual. Users choose a language (or get their browser/device locale automatically) and see the entire product translated: navigation, forms, errors, and — critically — the editorial content of every spot. English remains the source language and per-field fallback, so translated pages never render blank content.

## Launch locales

| Locale | Language | Notes |
|--------|----------|-------|
| `en` | English | Source / fallback |
| `es` | Spanish | |
| `pt-BR` | Brazilian Portuguese | |
| `fr` | French | |
| `de` | German | |
| `it` | Italian | |
| `zh-CN` | Simplified Chinese | |
| `zh-TW` | Traditional Chinese | |
| `ja` | Japanese | |
| `ko` | Korean | |
| `hi` | Hindi | |
| `ar` | Arabic | RTL layout |
| `ru` | Russian | |

Additional locales must be addable via config + locale files only — no page-component changes.

## Architecture

Two distinct translation surfaces:

### 1. Static UI strings

- **Web (Next.js, pages router):** Next.js built-in locale sub-path routing (`/es/spots/...`) with `next-i18next`. Centralized JSON locale files under `public/locales/<locale>/`. English URLs stay unprefixed to preserve existing links and SEO.
- **Mobile (Expo / React Native):** `react-i18next` + `expo-localization` for device-locale detection, with the selected language persisted in a Zustand store. Language picker in Settings.

### 2. Spot content (dynamic)

Human-readable spot fields (descriptions, terrain/features, access and fee guidance, rules, safety notes, alt text, etc.) are machine-translated through a backend pipeline and stored **by locale alongside — never overwriting — the English source**:

- Translations keyed by `(spotId, locale, field)` with source-text hash, translation status, provider/model, and review date, so stale translations are detectable and refreshable.
- Repeatable, idempotent backfill job for existing spots; new/updated spots are translated automatically.
- Field-level fallback to English when a translation is missing.
- Admin review workflow to inspect, correct, approve, and regenerate machine translations.
- Never translated: proper names, street addresses, URLs, coordinates, phone numbers.

## Routing, SEO, and sharing (web)

- Locale-aware shareable URLs (`/es/spots/california/los-angeles/...`); existing English URLs unchanged.
- Localized titles/descriptions, canonical URLs, and `hreflang` alternates.
- Sitemap includes localized spot pages without duplicate-content issues.

## Quality gates

- Automated checks for untranslated/missing UI keys and invalid locale payloads.
- Tests: locale detection, selector behavior, persistence, fallback, localized routing, dynamic spot rendering, Arabic RTL.
- Translation jobs are restartable, rate-limited, and observable; placeholders, units, URLs, and structured values are protected from translation.

## Delivery phases

1. **Foundation** — i18n framework, locale routing, language selector, persistence, UI string extraction (web + mobile).
2. **Spot content pipeline** — translation data model/API, one-time backfill, ongoing update pipeline.
3. **Hardening** — editor review tools, RTL polish, localized SEO/sitemaps, coverage checks, staged rollout.

## Related

- Web tracking issue: [TrickBookWebsite#8](https://github.com/wbaxterh/TrickBookWebsite/issues/8)
- Backend: spot translation storage and pipeline (see [Backend → Database](../backend/database.md))
