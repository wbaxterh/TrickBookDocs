---
sidebar_position: 7
---

# Code Quality

Cleanup tasks to reduce technical debt and bring TrickBook to professional standards. These are the issues a senior engineer would flag in a code review.

## Dead Dependencies

Both repos have unused packages inflating bundle size and adding confusion.

### TrickList: Remove These

```bash
cd TrickList

# Form libraries - neither is actually imported anywhere
npm uninstall formik yup

# State management - Jotai installed but 0 imports (Zustand is used)
npm uninstall jotai

# HTTP client - apisauce installed but replaced by custom fetch client
npm uninstall apisauce

# Old AWS SDK - if not needed
npm uninstall aws-sdk  # v2 deprecated, check if v3 @aws-sdk/* covers usage
```

**Current state:**
- `formik` (^2.2.9) - **0 imports** found
- `yup` (^0.32.11) - **0 imports** found
- `react-hook-form` (^7.71.1) - **0 imports** found
- `@hookform/resolvers` (^5.2.2) - **0 imports** found
- `jotai` (^1.11.2) - **0 imports** found
- `apisauce` (^1.1.1) - **0 imports** found

That's 6 dead packages. After removing them, pick ONE form solution if you need forms:

**Recommended:** React Hook Form + Zod (already have Zod for validation)

### Backend: Remove These

```bash
cd Backend

# Old AWS SDK v2 - v3 @aws-sdk/client-s3 is already installed
npm uninstall aws-sdk
```

## API Response Validation

Zod is installed in TrickList but barely used (2 files). Every API response should be validated at runtime:

```typescript
// src/lib/api/schemas/user.ts
import { z } from 'zod';

export const UserSchema = z.object({
  _id: z.string(),
  name: z.string(),
  email: z.string().email(),
  imageUri: z.string().nullable(),
});

export type User = z.infer<typeof UserSchema>;

// src/lib/api/auth.ts
import { UserSchema } from './schemas/user';

export async function login(email: string, password: string) {
  const response = await apiClient.post('/auth', { email, password });
  const user = UserSchema.parse(response.user); // Throws if invalid
  return { token: response.token, user };
}
```

**Why this matters:** TypeScript types vanish at runtime. If the API returns `{ name: null }` when you expect `string`, TypeScript won't catch it. Zod will.

### Priority schemas to create:

1. `UserSchema` - auth responses
2. `TrickSchema` / `TrickListSchema` - core data
3. `SpotSchema` - map data
4. `FeedPostSchema` - feed items
5. `ConversationSchema` / `MessageSchema` - DMs

## .env.example Files

Neither repo has a `.env.example`. New developers (or future you after a fresh clone) have no idea what environment variables are needed.

### TrickList `.env.example`

```bash
# API
EXPO_PUBLIC_API_URL=http://localhost:5000/api

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Sentry (optional)
EXPO_PUBLIC_SENTRY_DSN=
```

### Backend `.env.example`

```bash
# Server
PORT=5000
NODE_ENV=development

# Database
ATLAS_URI=mongodb+srv://user:password@cluster.mongodb.net/TrickList2

# Authentication
JWT_SECRET=generate-with-openssl-rand-base64-32
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_IOS_CLIENT_ID=your_google_ios_client_id
GOOGLE_ANDROID_CLIENT_ID=your_google_android_client_id
APPLE_CLIENT_ID=your_apple_client_id
APPLE_TEAM_ID=your_apple_team_id

# AWS S3
AWS_KEY=your_aws_access_key
AWS_SECRET=your_aws_secret_key
AWS_REGION=us-east-1
S3_BUCKET_NAME=your_bucket_name

# Bunny.net CDN
BUNNY_API_KEY=your_bunny_api_key
BUNNY_LIBRARY_ID=your_bunny_library_id
BUNNY_CDN_URL=your_bunny_cdn_url

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PREMIUM_PRICE_ID=price_xxx

# Email
EMAIL_USER=your_email
EMAIL_PASSWORD=your_app_specific_password

# Google Services
GOOGLE_PLACES_API_KEY=your_google_places_api_key
GOOGLE_DRIVE_FOLDER_ID=your_folder_id
GOOGLE_DRIVE_CREDENTIALS_PATH=./config/google-drive-credentials.json

# Sentry (optional)
SENTRY_DSN=
```

## Backend: Input Sanitization

No protection against NoSQL injection or XSS:

```bash
cd Backend
npm install express-mongo-sanitize
```

```javascript
// index.js
const mongoSanitize = require('express-mongo-sanitize');

app.use(mongoSanitize()); // Strips $ and . from req.body, req.query, req.params
```

This prevents attacks like:

```json
// Without sanitization, this bypasses password check
{ "email": "admin@test.com", "password": { "$gt": "" } }
```

## Backend: Consolidate MongoDB Connection

Currently every route file creates its own MongoDB connection. This is 24 separate connections instead of 1 shared pool. See [Security Fixes](/docs/roadmap/security-fixes#medium-centralize-database-connection) for the fix.

## Backend: Mixed MongoDB Drivers

The backend uses both `mongodb` (native driver) and `mongoose` (ODM) simultaneously:

```json
{
  "mongodb": "^4.13.0",
  "mongoose": "^8.15.1"
}
```

**Pick one.** Mixing them leads to:
- Two connection pools
- Inconsistent query patterns
- Double the surface area for bugs

**Recommendation:** Since routes already use the native `mongodb` driver extensively, either commit to it fully or migrate to Mongoose for schema validation. Don't keep both.

## File Size Discipline

Target ~500 lines of code per file. Current large files to consider splitting:

### TrickList

| File | Lines | Action |
|------|-------|--------|
| `src/lib/api/feed.ts` | 538 | Split into `feed-posts.ts`, `feed-reactions.ts`, `feed-comments.ts` |
| `src/lib/api/trickbook.ts` | 397 | Fine for now |
| `src/lib/api/spots.ts` | 343 | Fine for now |
| `src/lib/api/couch.ts` | 312 | Fine for now |

### Backend

Audit route files that handle too many concerns. Each route file should handle one resource.

## TypeScript Strictness (TrickList)

Current `tsconfig.json` has `strict: true` but is missing additional safety flags:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "forceConsistentCasingInFileNames": true,
    "allowUnreachableCode": false,
    "allowUnusedLabels": false
  }
}
```

`noUncheckedIndexedAccess` is the most impactful - it forces you to handle `undefined` when accessing arrays and objects by index.

## Backend: Dockerize

No Dockerfile exists. Add one for consistent deployments:

```dockerfile
# Backend/Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/api/health || exit 1

CMD ["node", "index.js"]
```

```yaml
# Backend/docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "5000:5000"
    env_file:
      - .env
    restart: unless-stopped
```
