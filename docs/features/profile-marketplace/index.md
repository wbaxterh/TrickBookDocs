---
title: "Profile Marketplace: Instructors, Creators, and Brand Deals"
sidebar_position: 1
---

# Profile Marketplace: Product Requirements

*Make rider profiles useful for finding instruction and credible sponsorship opportunities without turning onboarding into a form wall.*

| Field | Value |
|---|---|
| **Status** | Draft for review |
| **Owner** | Wes Huber |
| **Date** | September 2026 |
| **Related** | [Riders directory ADR](/docs/architecture/adrs/riders-directory) · [Signup audit](/docs/roadmap/signup-onboarding-audit) · [Instructor Outcomes](/docs/features/instructor-outcomes) |

## Product decision

Use the existing member profile as the single identity. A member can opt into two independent capabilities:

- **Offer lessons**, which adds an instructor card, rate and service-area fields, and instructor-directory eligibility.
- **Open to partnerships**, which adds verified social accounts, audience insights, partnership preferences, and a brand inquiry action.

Do not create separate instructor or influencer accounts. Do not require either path during signup. Onboarding asks one skippable question—“Do you offer lessons?”—after the account exists; the detailed setup happens progressively in the profile.

Use **Creator Score** as the working customer-facing label instead of “Influencer Score.” It should represent useful, authentic reach and TrickBook outcomes rather than celebrity.

## Goals and non-goals

### Goals

- Let riders discover instructors by sport, discipline, area, format, and price.
- Let members link Instagram, YouTube, and TikTok accounts.
- Show a credible, explainable Creator Score only when enough verified data exists.
- Let approved brands send structured partnership inquiries without exposing member contact details.
- Give TrickBook a path to promoted profiles, lead fees, campaign tools, and later transaction revenue.

### Non-goals for v1

- Booking, escrow, contracts, payouts, tax handling, or dispute arbitration.
- Scraping follower counts from public profile pages.
- Guaranteeing that an instructor is licensed, insured, safe, or professionally certified.
- Selling direct access to riders' email addresses or precise home locations.
- Ranking members solely by follower count.

## User experience

### Progressive onboarding

After account creation and sport selection, show one optional card:

> **Do you offer lessons?**<br />
> Help riders nearby or online learn from you.<br />
> **Yes, set up teaching** · **Maybe later**

Choosing yes creates a draft instructor profile and opens the instructor setup checklist. It does not make the member searchable until they explicitly publish it.

Do not ask for social accounts, hourly rate, partnership status, or detailed location in the core signup funnel. Prompt for these later from profile-completion cards.

### Instructor setup

Required to publish:

- At least one sport and discipline
- Lesson format: in person, online, or both
- Public service area for in-person lessons: city/region or radius, never a home address
- Pricing mode: hourly rate, “starting at,” price range, or contact for pricing
- Currency
- Short teaching bio
- Minimum participant age or “all ages,” where relevant
- Agreement to instructor conduct and safety terms

Optional:

- Languages, skill levels, availability summary, travel radius, certifications, years teaching, group lessons, and booking URL
- Credential evidence submitted privately for review

Public instructor cards show rate text, general area, specialties, format, languages, verified credentials, response status, and later aggregated Instructor Outcomes. “Instructor” is self-selected; only evidence-reviewed claims receive a **Verified credential** label.

### Social accounts

Members can connect one account per supported platform in v1:

- Instagram
- YouTube
- TikTok

Every account has one of these states: `pending`, `verified`, `expired`, `disconnected`, or `failed`. A typed URL can be displayed as an unverified link, but its metrics must never affect Creator Score. OAuth or a platform-approved ownership challenge is required for verification.

Public display is independently controlled per platform. Disconnecting an account removes future collection immediately; the UI explains how long historical aggregates are retained.

### Creator Score

The score is optional, ranges from **0–100**, and is displayed only when:

- at least one social account is verified;
- the data is no more than 30 days old;
- minimum audience/activity thresholds are met; and
- the member opts into public display.

The profile shows a band and “updated” date, not false precision:

- **Emerging:** 20–39
- **Growing:** 40–59
- **Established:** 60–79
- **Leading:** 80–100

Below the display threshold, show **Building audience insights** privately to the member. Never show a public low-score badge.

Initial weighting:

- 25% verified audience reach, normalized logarithmically
- 25% recent engagement quality, normalized by platform and audience size
- 20% consistency over the last 90 days
- 15% cross-platform authenticity and audience quality
- 15% TrickBook relevance: sport fit, useful content, and later qualified Instructor Outcomes

Compute platform sub-scores first, then combine them so one huge account does not erase all other signals. Cap outlier posts, detect suspicious growth/engagement, and send anomalous accounts to review. Publish the categories, weights, freshness date, and appeal path; keep abuse thresholds private. Never claim the score measures personal worth, athletic ability, or guaranteed campaign performance.

### Brand inquiries

Members enable **Open to partnerships** and choose:

- deal types: sponsored post, product review, event appearance, affiliate, ambassador, content licensing, or other;
- sports, categories, preferred compensation type, regions, and whether they accept gifted-only opportunities;
- a private minimum budget, optional in v1, used for filtering but never publicly shown.

Brands must have an authenticated organization profile before contacting creators. A structured inquiry includes brand, campaign summary, deliverables, timeline, compensation range and type, usage rights, exclusivity, location, and contact person.

The creator sees the inquiry in TrickBook and chooses **Interested**, **Decline**, or **Report**. Email/contact details remain hidden until the creator accepts. Apply rate limits, block/report controls, organization review, and an audit trail. Minors cannot receive brand inquiries in v1; age-appropriate guardian and legal flows are a later project.

## Discovery

Extend `/riders` rather than creating separate people directories.

Instructor filters:

- sport and discipline
- location plus distance, using coarse public coordinates
- online/in-person
- price range and currency
- skill level, language, verified credential, and availability

Creator/brand filters, available only to approved brand accounts:

- sport/category fit, location, platform, Creator Score band, verified audience band, engagement band, and partnership type

Public users may see social links and a public Creator Score. Detailed audience analytics and brand-fit search require an approved brand workspace and creator consent.

## Data model

Keep authentication data in `users`; add role-specific embedded summaries or dedicated collections as volume grows. Do not overload the current free-form `riderProfile` object with OAuth tokens or private commercial preferences.

```typescript
interface ProfileCapabilities {
  roles: Array<'rider' | 'instructor' | 'creator'>;
  instructor?: {
    status: 'draft' | 'published' | 'paused' | 'suspended';
    formats: Array<'in_person' | 'online'>;
    sports: Array<{ sport: string; disciplines: string[] }>;
    serviceAreas: Array<{ label: string; geo: GeoJSONPoint; radiusKm: number }>;
    pricing: {
      mode: 'hourly' | 'starting_at' | 'range' | 'contact';
      currency?: string;
      amountMinor?: number;
      maxAmountMinor?: number;
    };
    languages: string[];
    skillLevels: string[];
    bio: string;
  };
  partnerships?: {
    enabled: boolean;
    dealTypes: string[];
    categories: string[];
    compensationTypes: Array<'cash' | 'product' | 'affiliate'>;
    giftedOnlyAccepted: boolean;
    regions: string[];
  };
}

interface SocialAccount {
  userId: ObjectId;
  platform: 'instagram' | 'youtube' | 'tiktok';
  platformAccountId: string;
  handle: string;
  profileUrl: string;
  verificationStatus: 'pending' | 'verified' | 'expired' | 'disconnected' | 'failed';
  public: boolean;
  tokenCiphertext?: string;
  scopes: string[];
  metrics?: {
    followers?: number;
    averageViews?: number;
    engagementRate?: number;
    sampledAt: Date;
  };
  createdAt: Date;
  updatedAt: Date;
}

interface CreatorScoreSnapshot {
  userId: ObjectId;
  score: number;
  band: 'emerging' | 'growing' | 'established' | 'leading';
  components: Record<string, number>;
  inputFreshness: Record<string, Date>;
  modelVersion: number;
  status: 'private' | 'public' | 'stale' | 'under_review';
  calculatedAt: Date;
}

interface PartnershipInquiry {
  creatorUserId: ObjectId;
  organizationId: ObjectId;
  campaignSummary: string;
  deliverables: string[];
  compensation: { type: string; currency?: string; minMinor?: number; maxMinor?: number };
  usageRights: string;
  exclusivity?: string;
  timeline: { start?: Date; end?: Date };
  status: 'sent' | 'interested' | 'declined' | 'withdrawn' | 'reported' | 'expired';
  createdAt: Date;
  updatedAt: Date;
}
```

Required indexes include geospatial instructor service areas, unique `(userId, platform)`, unique `(platform, platformAccountId)`, public score band, and inquiry inbox/status. OAuth tokens are encrypted with a managed key, excluded from every profile projection, and deleted on disconnect when no longer required.

## API surface

```text
PATCH  /api/profile/capabilities
PUT    /api/profile/instructor
POST   /api/profile/instructor/publish
POST   /api/social/:platform/connect
GET    /api/social/:platform/callback
DELETE /api/social/:platform
GET    /api/profile/creator-insights
PATCH  /api/profile/creator-score-visibility
GET    /api/riders?offersLessons=true&near=...&sport=...
POST   /api/organizations
POST   /api/partnership-inquiries
GET    /api/partnership-inquiries/inbox
PATCH  /api/partnership-inquiries/:id/status
POST   /api/partnership-inquiries/:id/report
```

The public profile endpoint must use an allowlist projection. It must never return precise coordinates, private pricing thresholds, raw audience datasets, OAuth credentials, birth date, email, or brand-inquiry history.

## Monetization

Validate demand before charging transaction fees:

1. Free instructor and creator profiles establish marketplace supply.
2. Charge brands for approved workspaces, advanced discovery, shortlists, and outreach allowances.
3. Offer optional promoted placement, always visibly labeled and never mixed into organic Creator Score.
4. Add campaign workflow and a success fee only after TrickBook provides contracts, deliverable approval, payments, tax handling, refunds, and disputes.

Never let payment purchase a higher Creator Score or a verified credential.

## Metrics and safeguards

Primary funnel:

- lesson opt-in → instructor profile published → search impression → profile view → inquiry → accepted contact
- social connect started → verified → score eligible → partnerships enabled → brand inquiry → interested → reported deal

Guardrails:

- signup completion and instructor-setup abandonment
- spam/report/block rate by organization
- inquiry acceptance and response time
- score appeals, suspicious-account rate, and stale-data rate
- geographic privacy incidents
- concentration of impressions among the top score band

## Delivery plan

### Phase 1 — instructor discovery

- Add “Do you offer lessons?” as a skippable post-account onboarding card.
- Build draft/publish instructor setup, safe service areas, pricing modes, public profile module, and `/riders` filters.
- Use inquiry/contact requests; no scheduling or payment.

### Phase 2 — social identity

- Add Instagram, YouTube, and TikTok profile links.
- Implement approved account verification one platform at a time, beginning with the platform whose production API access is available.
- Display verification and data-freshness states.

### Phase 3 — Creator Score pilot

- Compute private score previews for a consenting cohort.
- Back-test platform normalization and fraud controls; let members appeal.
- Publicly launch bands only after score stability and fairness review.

### Phase 4 — brand marketplace

- Add approved organization profiles, creator opt-in, structured inquiries, private inbox, reporting, and brand subscriptions.
- Pilot with a small group of action-sports brands and creators; keep deal execution off-platform.

### Phase 5 — managed deals

- Only after the inquiry marketplace proves demand, evaluate contracts, payments/escrow, deliverable verification, commissions, tax compliance, and minor/guardian support as a separate specification.

## Acceptance criteria for the first release

- A normal member can finish signup without seeing or completing instructor fields.
- An instructor can publish or pause a searchable profile and choose hourly, starting-at, range, or contact pricing.
- Search never reveals a precise address or exact private location.
- Unverified social links never contribute to Creator Score.
- Creator Score displays its band, components, freshness, and model version explanation.
- A creator must opt into partnerships before appearing in brand discovery.
- A brand cannot obtain direct contact details before the creator accepts its inquiry.
- Paid promotion cannot alter organic score, verification, or credential status.
- Disconnecting a social account revokes access and makes stale-score behavior deterministic.
