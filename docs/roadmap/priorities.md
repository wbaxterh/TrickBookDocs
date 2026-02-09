---
sidebar_position: 1
---

# Priority Roadmap

Current priorities for TrickBook. Engineering standards come first - no new features until the safety net is in place.

## Priority Matrix

### P0 - Engineering Standards (Next Session)

These are blocking. Ship no new features until these are done.

| # | Task | Repo | Effort | Docs |
|---|------|------|--------|------|
| 1 | Add Biome (lint + format) | Both | 30 min | [Setup](/docs/engineering/linting-formatting) |
| 2 | Add pre-commit hooks (Husky + lint-staged) | Both | 30 min | [Setup](/docs/engineering/pre-commit-hooks) |
| 3 | Add ErrorBoundary component | Mobile | 1 hour | [Guide](/docs/engineering/error-handling) |
| 4 | Add Sentry error tracking | Both | 1 hour | [Guide](/docs/engineering/error-handling#sentry-integration) |
| 5 | Write first 10 tests (critical paths) | Both | Half day | [Strategy](/docs/engineering/testing) |
| 6 | Add CI/CD with quality gates | Both | 1 hour | [Pipeline](/docs/deployment/ci-cd) |
| 7 | Add global error handler middleware | Backend | 1 hour | [Guide](/docs/engineering/error-handling#backend-global-error-handler) |
| 8 | Create .env.example files | Both | 15 min | [Template](/docs/engineering/code-quality#envexample-files) |

**Definition of done:** Every commit is linted, every PR runs tests, every production error is tracked.

### P1 - Security Hardening (Same Sprint)

| Task | Repo | Status | Docs |
|------|------|--------|------|
| Rotate exposed credentials | Backend | Pending | [Guide](/docs/roadmap/security-fixes) |
| Upgrade Node.js 12 to 20 LTS | Backend | Pending | [Guide](/docs/roadmap/security-fixes#critical-nodejs-upgrade) |
| Fix JWT secret (env var + expiration) | Backend | Pending | [Guide](/docs/roadmap/security-fixes#critical-jwt-security) |
| Add rate limiting | Backend | Pending | [Guide](/docs/roadmap/security-fixes#high-rate-limiting) |
| Add input sanitization (NoSQL injection) | Backend | Pending | [Guide](/docs/engineering/code-quality#backend-input-sanitization) |
| Restrict CORS whitelist | Backend | Pending | [Guide](/docs/roadmap/security-fixes#high-cors-whitelist) |
| Update helmet to v8 | Backend | Pending | [Guide](/docs/roadmap/security-fixes#high-update-security-packages) |
| Add health check endpoint | Backend | Pending | [Guide](/docs/engineering/error-handling#backend-health-check-endpoint) |
| Add graceful shutdown | Backend | Pending | [Guide](/docs/engineering/error-handling#backend-graceful-shutdown) |

### P2 - Code Cleanup (Following Sprint)

| Task | Repo | Effort | Docs |
|------|------|--------|------|
| Remove 6 dead dependencies | Mobile | 30 min | [Details](/docs/engineering/code-quality#dead-dependencies) |
| Remove aws-sdk v2 (v3 already installed) | Backend | 15 min | [Details](/docs/roadmap/gap-analysis#19-old-aws-sdk-v2-still-installed-backend) |
| Add Zod schemas for all API responses | Mobile | 1 day | [Guide](/docs/engineering/code-quality#api-response-validation) |
| Replace console.log with structured logger | Both | 2 hours | [Guide](/docs/engineering/logging) |
| Centralize MongoDB connection pool | Backend | Half day | [Guide](/docs/roadmap/security-fixes#medium-centralize-database-connection) |
| Pick one MongoDB driver (drop unused one) | Backend | Half day | [Details](/docs/engineering/code-quality#backend-mixed-mongodb-drivers) |
| Dockerize backend | Backend | 1 hour | [Guide](/docs/engineering/code-quality#backend-dockerize) |
| Tighten TypeScript strict settings | Mobile | 1 hour | [Details](/docs/engineering/code-quality#typescript-strictness-tricklist) |

### P3 - Feature Work (After Standards Are Met)

| Task | Repo | Notes |
|------|------|-------|
| Google Play submission | Mobile | Store listing, screenshots, review |
| Push notifications | Mobile | Expo push + backend triggers |
| Offline mode improvements | Mobile | Queue mutations, sync on reconnect |
| Refresh tokens | Backend | Access token (15m) + refresh (7d) |
| Expand test coverage to 40% | Both | Add tests as you touch files |
| API versioning | Backend | `/api/v1/` prefix |

---

## Sprint Plan: Engineering Standards

**Goal:** Go from 0 quality gates to full CI/CD pipeline in one session.

### Hour 1: Biome + Pre-commit (Both Repos)

```bash
# TrickList
cd TrickList
npm install --save-dev @biomejs/biome husky lint-staged
npx @biomejs/biome init
npx husky init
# Configure biome.json, lint-staged, .husky/pre-commit
npm run lint:fix  # Auto-fix everything
# Commit the formatting pass

# Backend
cd Backend
npm install --save-dev @biomejs/biome husky lint-staged
npx @biomejs/biome init
npx husky init
npm run lint:fix
# Commit
```

### Hour 2: Error Handling + Sentry

```bash
# TrickList
cd TrickList
npx expo install @sentry/react-native
# Create src/components/ErrorBoundary.tsx
# Wire up in app/_layout.tsx
# Add EXPO_PUBLIC_SENTRY_DSN to .env

# Backend
cd Backend
npm install @sentry/node express-mongo-sanitize
# Create middleware/errorHandler.js
# Create utils/AppError.js
# Add Sentry.init to index.js
# Add graceful shutdown handlers
# Add health check endpoint
```

### Hours 3-4: First Tests

```bash
# TrickList
cd TrickList
npm install --save-dev @testing-library/react-native @testing-library/jest-native
# Write tests: client.test.ts, authStore.test.ts, trickStatus.test.ts
# 2 screen smoke tests

# Backend
cd Backend
npm install --save-dev jest supertest mongodb-memory-server
# Write tests: auth.test.js, users.test.js, auth-middleware.test.js
# trick-lists.test.js, spots.test.js
```

### Hour 5: CI/CD

```bash
# TrickList - create .github/workflows/ci.yml
# Backend - create .github/workflows/ci.yml
# Configure branch protection rules on GitHub
# Create .env.example for both repos
```

---

## Feature Roadmap

### Q1: Foundation (Current)

- [x] Core trick list functionality
- [x] User authentication (email + Google + Apple)
- [x] iOS App Store launch
- [x] Feed/social features
- [x] Direct messaging
- [x] Spot discovery with maps
- [ ] **Engineering standards** (this sprint)
- [ ] Security hardening (this sprint)
- [ ] Google Play launch

### Q2: Growth

- [ ] Push notifications
- [ ] Offline mode
- [ ] Analytics dashboard
- [ ] Performance optimization
- [ ] Expand test coverage to 60%

### Q3: Expansion

- [ ] Community features
- [ ] Premium feature expansion
- [ ] API versioning
- [ ] International expansion

### Q4: Scale

- [ ] Additional sport support
- [ ] Partner integrations
- [ ] Automated E2E testing

---

## Metrics to Track

### Engineering Health

| Metric | Current | Target |
|--------|---------|--------|
| Test coverage | 0% | 40% (Q1), 70% (Q2) |
| Lint errors | Unknown (no linter) | 0 |
| CI pass rate | N/A (no CI) | >95% |
| Mean time to detect error | Days (user report) | Minutes (Sentry alert) |
| Crash-free sessions | Unknown | >99.5% |

### App Metrics

- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- Retention (Day 1, 7, 30)
- Session duration
- Tricks completed per user

### Business Metrics

- Downloads (iOS vs Android)
- Premium conversion rate
- Revenue per user
- App Store rating
