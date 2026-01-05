---
sidebar_position: 1
---

# Priority Roadmap

Current priorities and action items for TrickBook development.

## Priority Matrix

### P0 - Critical (Do Immediately)

| Task | Component | Status | Notes |
|------|-----------|--------|-------|
| Rotate exposed credentials | Backend | Pending | AWS, MongoDB, email passwords exposed |
| Set up Android signing | Mobile | Pending | Required for Google Play |
| Create Google Play listing | Mobile | Pending | Store presence needed |
| Build Android AAB | Mobile | Pending | `eas build --platform android --profile playstore` |
| Submit to Google Play | Mobile | Pending | First Android release |

### P1 - High (This Week)

| Task | Component | Status | Notes |
|------|-----------|--------|-------|
| Upgrade Node.js to 18+ | Backend | Pending | Current v12 is EOL |
| Fix JWT secret | Backend | Pending | Currently hardcoded |
| Add token expiration | Backend | Pending | Tokens never expire |
| Update helmet to v7 | Backend | Pending | Security headers outdated |
| Centralize DB connection | Backend | Pending | Currently per-route connections |

### P2 - Medium (This Sprint)

| Task | Component | Status | Notes |
|------|-----------|--------|-------|
| Add rate limiting | Backend | Pending | No brute-force protection |
| Add structured logging | Backend | Pending | Only console.log currently |
| Set up CI/CD pipeline | Both | Pending | Manual deployments currently |
| Add error tracking (Sentry) | Both | Pending | No crash reporting |
| Dockerize backend | Backend | Pending | For consistent deployments |

### P3 - Low (Backlog)

| Task | Component | Status | Notes |
|------|-----------|--------|-------|
| Add unit tests | Both | Pending | No test coverage |
| Add TypeScript | Both | Pending | JavaScript only |
| Implement refresh tokens | Backend | Pending | Better security |
| Add push notifications | Mobile | Pending | Not implemented |
| Performance optimization | Both | Pending | No caching layer |

---

## Google Play Launch Checklist

**Goal:** Get TrickBook on Google Play Store

### Week 1: Setup

- [ ] Create Google Play Developer account ($25)
- [ ] Generate Android signing keystore via EAS
- [ ] Build first Android App Bundle
- [ ] Create store listing draft

### Week 2: Store Listing

- [ ] Write app description
- [ ] Create feature graphic (1024x500)
- [ ] Take screenshots on Android device/emulator
- [ ] Complete content rating questionnaire
- [ ] Fill out data safety form

### Week 3: Testing & Submit

- [ ] Test on multiple Android versions
- [ ] Test on different screen sizes
- [ ] Fix any Android-specific bugs
- [ ] Submit for review
- [ ] Monitor review status

### Week 4: Launch

- [ ] Address any review feedback
- [ ] Configure staged rollout (20% → 50% → 100%)
- [ ] Monitor crash reports
- [ ] Respond to user reviews

---

## Backend Security Sprint

**Goal:** Address critical security vulnerabilities

### Day 1: Credentials

```bash
# 1. Rotate MongoDB password in Atlas
# 2. Create new AWS access keys
# 3. Update email app password
# 4. Generate secure JWT secret
openssl rand -base64 32
```

### Day 2: Code Updates

```javascript
// 1. Update JWT signing
jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });

// 2. Add token expiration check
const decoded = jwt.verify(token, process.env.JWT_SECRET);

// 3. Update CORS
app.use(cors({
  origin: ['https://thetrickbook.com'],
  credentials: true
}));
```

### Day 3: Dependencies

```bash
# Update critical packages
npm install helmet@latest
npm install jsonwebtoken@latest
npm install express-rate-limit
```

### Day 4: Node.js Upgrade

```json
// Update package.json
{
  "engines": {
    "node": ">=18.0.0"
  }
}
```

### Day 5: Testing & Deploy

- [ ] Test all endpoints
- [ ] Verify auth flow
- [ ] Deploy to production
- [ ] Monitor for issues

---

## Feature Roadmap

### Q1: Foundation

- [x] Core trick list functionality
- [x] User authentication
- [x] iOS App Store launch
- [ ] **Google Play launch**
- [ ] Security hardening
- [ ] CI/CD pipeline

### Q2: Enhancement

- [ ] Push notifications
- [ ] Offline mode improvements
- [ ] Social features (share lists)
- [ ] Analytics dashboard
- [ ] Performance optimization

### Q3: Expansion

- [ ] Trickipedia video integration
- [ ] Community features
- [ ] Spot sharing/discovery
- [ ] Premium feature expansion
- [ ] API versioning

### Q4: Scale

- [ ] International expansion
- [ ] Additional sport support
- [ ] Partner integrations
- [ ] Enterprise features
- [ ] White-label options

---

## Technical Debt

### Backend

| Item | Effort | Impact |
|------|--------|--------|
| Centralize DB connections | Medium | High |
| Add request validation | Medium | Medium |
| Implement caching | High | High |
| Add API versioning | Medium | Medium |
| Remove unused mongoose | Low | Low |

### Mobile

| Item | Effort | Impact |
|------|--------|--------|
| Add error boundaries | Low | Medium |
| Implement offline sync | High | High |
| Add TypeScript | High | Medium |
| Improve state management | Medium | Medium |
| Add deep linking | Medium | Low |

---

## Metrics to Track

### App Metrics

- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- Retention (Day 1, 7, 30)
- Tricks completed per user
- Session duration

### Technical Metrics

- API response time (p50, p95, p99)
- Error rate
- Crash-free sessions
- App size
- Build time

### Business Metrics

- Downloads (iOS vs Android)
- Premium conversion rate
- Churn rate
- Revenue per user
- Customer acquisition cost
