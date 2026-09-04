---
title: Staging and Production Promotion
---

# Staging and Production Promotion

All TrickBook web and backend features follow this path:

`feature/*` → pull request to `staging` → automated checks → staging deploy → manual QA → pull request from `staging` to production

Production branches are `main` for the website and `master` for the backend. The promotion check rejects production pull requests whose source branch is not `staging`.

## Environment isolation

| Concern | Staging | Production |
|---|---|---|
| Web | Amplify `staging` branch | Amplify `main` branch |
| API | Separate EC2 worktree/process/port | Existing EC2 production process |
| MongoDB | Separate database selected with `MONGODB_DATABASE` | `TrickList2` |
| Neo4j | Staging graph/database | Production graph/database after readiness review |
| Secrets | Branch/process environment | Production environment |

Never copy production secrets into source control or expose them in build logs. Test data may be seeded from sanitized public fields, not by cloning credentials, tokens, messages, or private account fields.

## Current parity gap (September 3, 2026)

The first staging slice proves branch isolation and the Riders API, but it is **not yet a production-parity environment**. The staging database intentionally began empty and currently contains only sanitized Rider fixtures. Most application pages therefore appear empty, and authentication providers have not been configured with staging callback URLs. Treat staging as feature-limited until every gate below is complete.

## Production-parity plan

### Phase 1: environment contract and safety rails

Create one versioned environment-variable manifest containing variable names, owners, consumers, and whether each value is shared or isolated. Values remain in AWS/EC2 secret storage, never in Git. The staging configuration must explicitly set:

- `NEXTAUTH_URL` and `FRONTEND_URL` to the staging web origin;
- `NEXT_PUBLIC_API_BASE_URL`, Socket.IO, and Kith WebSocket URLs to staging routes;
- a staging-only `MONGODB_DATABASE` and staging CORS origins;
- environment-scoped JWT/session secrets;
- safe Stripe, email, push, S3, Bunny, analytics, and AI settings.

The backend must expose an environment marker through its health response, and the frontend must show a persistent **STAGING** banner. Any staging process that resolves the production database name must refuse to boot.

### Phase 2: authentication parity

Register staging as an authorized web origin and callback/redirect URI in both provider consoles.

**Google:** Prefer a separate OAuth client named `TrickBook Web Staging`. Add the exact staging origin and `https://<staging-host>/api/auth/callback/google`. Configure the backend's staging Google audience explicitly when backend token exchange is used.

**Apple:** Add `https://<staging-host>/api/auth/callback/apple` to the Services ID configuration, or use a dedicated staging Services ID if required. Keep the private key only in protected environment configuration.

**Sessions and credentials:** Use staging-specific `NEXTAUTH_SECRET` and backend `JWT_SECRET` values so production sessions cannot be replayed. Validate secure cookies, `SameSite`, callback URLs, logout, provider-mismatch recovery, and Forgot Password. Create designated staging test accounts; never authenticate staging against production user documents.

### Phase 3: representative sanitized data

Build a repeatable, idempotent refresh job from production to staging. It must use collection-specific allowlists and transformations rather than copying the database.

- Copy public/reference content needed for realistic browsing: categories, Trickipedia, approved spots, events, public Couch catalog metadata, and approved editorial Riders.
- Create synthetic member identities for authenticated flows. Public member cards may be copied only from opted-in public fields.
- Preserve relationship shape with remapped staging IDs when testing Homies, messages, lists, claims, and ownership.
- Never copy password hashes, OAuth subject IDs, reset tokens, JWTs, email addresses, private messages, push tokens, billing identifiers, precise private locations, private lists, or companion memory.
- Media records may reference production read-only CDN assets for display testing; staging uploads must use isolated storage/library prefixes.
- Record refresh version, source snapshot time, transformed counts, exclusions, and verification results.

### Phase 4: service parity without production side effects

| Service | Staging policy |
|---|---|
| MongoDB | Separate database; guarded startup and importer checks |
| S3/images | Separate bucket or mandatory `staging/` prefix with restricted IAM |
| Bunny/Couch | Production catalog may be read-only; uploads use a staging library |
| Stripe | Test-mode keys, products, prices, and webhook endpoint only |
| Email | Capture/sink provider or strict allowlist; never send to copied addresses |
| Push notifications | Disabled by default or limited to registered staging devices |
| Socket.IO/Kith | Dedicated staging paths/processes and explicit frontend URLs |
| PostHog/Sentry/logging | Separate project/environment tags and no production user PII |
| AI providers | Separate budgets, rate limits, and staging telemetry |
| Neo4j | Separate database/instance built only from staging Mongo projections |

### Phase 5: deployment automation

- Amplify automatically deploys `staging`; `main` remains production.
- EC2 deployment updates `/home/ubuntu/TB-Backend-staging`, installs from the lockfile, runs checks, restarts only `TB-Backend-staging`, and verifies health.
- Failed staging deployments retain the previous healthy revision for rollback.
- Database migrations and indexes run against staging first and are idempotent.
- Production promotion remains a PR from `staging` only and requires a recorded staging revision plus QA result.

### Phase 6: parity test suite

Automate browser/API tests for:

1. anonymous navigation and public data pages;
2. email/password registration, login, logout, reset, and session persistence;
3. Google and Apple SSO, including provider-mismatch recovery;
4. profile editing, Riders/Homies, messages, lists, media, Couch, spots, events, and claims;
5. upload/playback using staging storage;
6. pagination, search, filters, responsive layout, images, WebSockets, and error states;
7. zero browser console errors, failed first-party requests, or unexpected production writes.

## Parity readiness gate

Staging is production-like only when both SSO providers pass end to end; the sanitized refresh supplies every core surface; all external services are isolated or explicitly read-only; authenticated and anonymous browser suites pass; telemetry identifies staging; and a destructive-write canary proves staging cannot mutate production data, storage, billing, email, or push systems.

## Required QA before promotion

1. CI passes in both repositories.
2. Staging health and API smoke checks pass.
3. Anonymous and authenticated browser paths pass.
4. Data mutations are confirmed against the staging database.
5. Error and process logs are clean during the test run.
6. A human approves the `staging` → production PR.

Emergency production fixes require an explicit incident note and must be merged back into `staging` immediately after production recovery.
