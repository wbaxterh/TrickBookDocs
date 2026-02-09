---
sidebar_position: 1
---

# Backend Overview

The TrickBook backend is a Node.js Express API with Socket.IO for real-time features. It serves the mobile app, website, and Chrome extension.

## Quick Start

```bash
cd Backend
npm install
npm start
```

The server runs on port 9000 in development.

## Project Structure

```
Backend/
├── config/                 # Configuration files
│   ├── default.json       # Default settings
│   ├── development.json   # Dev environment
│   ├── production.json    # Prod environment
│   └── stripe.js          # Stripe initialization
│
├── middleware/            # Express middleware
│   ├── auth.js           # JWT authentication
│   ├── authAdmin.js      # Admin-only access
│   ├── authAccountOrAdmin.js  # Owner or admin
│   ├── subscription.js   # Freemium limits
│   ├── validation.js     # Request validation
│   └── delay.js          # Delay middleware
│
├── routes/               # API endpoints (26 files)
│   ├── auth.js          # Email/password, Google, Apple auth
│   ├── user.js          # User profile management
│   ├── users.js         # User CRUD operations
│   ├── listings.js      # Trick list collections
│   ├── listing.js       # Individual tricks in lists
│   ├── trickipedia.js   # Global trick encyclopedia
│   ├── trickImage.js    # Trick image uploads to S3
│   ├── spots.js         # Skate spot management
│   ├── spotlists.js     # Spot list collections
│   ├── spotReviews.js   # Spot reviews & ratings
│   ├── feed.js          # Social feed (posts, reactions, comments)
│   ├── dm.js            # Direct messages
│   ├── couch.js         # "The Couch" curated videos
│   ├── payments.js      # Stripe subscription handling
│   ├── media.js         # Media file management
│   ├── blog.js          # Blog post management
│   ├── blogImage.js     # Blog image uploads
│   ├── categories.js    # Content categories
│   ├── messages.js      # Legacy messages
│   ├── contact.js       # Contact form
│   ├── expoPushTokens.js # Push notification tokens
│   ├── image.js         # Profile image handling
│   ├── upload.js        # File uploads
│   └── my.js            # User's personal data
│
├── services/             # Business logic & integrations
│   ├── s3Upload.js      # AWS S3 upload utility
│   ├── googlePlaces.js  # Google Places API
│   └── bunnyStream.js   # Bunny.net video streaming
│
├── socket/               # Socket.IO real-time features
│   ├── index.js         # Socket server initialization
│   ├── feedSocket.js    # Feed real-time updates
│   └── messageSocket.js # Message real-time updates
│
├── store/               # Data access layer
│   ├── listings.js
│   ├── messages.js
│   └── users.js
│
├── mappers/             # Data transformation
│   └── listings.js
│
├── index.js             # App entry point
├── socket.js            # Socket.IO setup
├── package.json
└── .env                 # Environment variables
```

## Environment Variables

Create a `.env` file with:

```bash
# Database
ATLAS_URI=mongodb+srv://user:pass@cluster.mongodb.net/TrickList2

# AWS
AWS_KEY=your_aws_access_key
AWS_SECRET=your_aws_secret_key
AWS_REGION=us-east-1

# Auth
JWT_SECRET=your_secure_jwt_secret
GOOGLE_CLIENT_ID=your_google_oauth_client_id
GOOGLE_IOS_CLIENT_ID=your_ios_client_id
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id

# Stripe
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PREMIUM_PRICE_ID=price_xxx
STRIPE_PREMIUM_YEARLY_PRICE_ID=price_xxx

# Email
EMAIL_USER=admin@thetrickbook.com
EMAIL_PASSWORD=app_specific_password

# Bunny.net CDN
BUNNY_API_KEY=your_bunny_api_key
BUNNY_LIBRARY_ID=583522
BUNNY_CDN_HOSTNAME=your_cdn_hostname
BUNNY_STREAM_TOKEN_KEY=your_stream_token

# Google Services
GOOGLE_PLACES_API_KEY=your_places_key
GOOGLE_DRIVE_FOLDER_ID=your_folder_id

# App
FRONTEND_URL=https://thetrickbook.com
PORT=9000
```

:::danger Security Warning
Never commit `.env` files to version control. The current repository has exposed credentials that need to be rotated.
:::

## Middleware Stack

Request processing order:

```
Request
   │
   ▼
┌──────────────┐
│    CORS      │  Allow cross-origin requests (all origins)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Helmet     │  Security headers
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Body Parser  │  Parse JSON (10MB limit)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Compression  │  Gzip responses
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Auth (JWT)  │  Per-route authentication
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Subscription │  Freemium limit enforcement
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Routes     │  Handle request
└──────┬───────┘
       │
       ▼
Response
```

## Real-Time (Socket.IO)

The backend uses Socket.IO for real-time features alongside the REST API.

**Namespaces:**
- `/feed` - Live post updates, reaction counts, engagement metrics
- `/messages` - Real-time message delivery, typing indicators, read receipts

**Authentication:** JWT token passed in `socket.handshake.auth.token`

Each user joins a personal room (`user:{userId}`) for targeted events.

## Database Connection

Currently, each route file creates its own connection (anti-pattern):

```javascript
const { MongoClient } = require("mongodb");
const client = new MongoClient(process.env.ATLAS_URI);
await client.connect();
const db = client.db("TrickList2");
```

:::tip Improvement Needed
Should use a centralized connection pool. See [Efficiency Improvements](/docs/roadmap/efficiency-improvements).
:::

## API Response Format

Successful response:
```json
{
  "data": [...],
  "message": "Success"
}
```

Error response:
```json
{
  "error": "Error message",
  "status": 400
}
```

## Freemium Model

The subscription middleware enforces limits:

| Feature | Free | Premium ($10/mo) |
|---------|------|-------------------|
| Spot Lists | 3 max | Unlimited |
| Spots per List | 5 max | Unlimited |
| Total Spots | 15 max | Unlimited |
| Trick Lists | Unlimited | Unlimited |
| Feed Posts | Unlimited | Unlimited |
| Direct Messages | Unlimited | Unlimited |

Admin override is available for testing via `POST /api/payments/admin/toggle-subscription`.

## Third-Party Integrations

| Service | Purpose | Route |
|---------|---------|-------|
| Stripe | Subscriptions & payments | `routes/payments.js` |
| AWS S3 | Image storage & CDN | `services/s3Upload.js` |
| Bunny.net | Video streaming CDN | `services/bunnyStream.js` |
| Google Places | Spot location search | `services/googlePlaces.js` |
| Google Drive | "The Couch" video library | `routes/couch.js` |
| Expo Push | Mobile notifications | `routes/expoPushTokens.js` |
| Nodemailer | Email via Gmail | `routes/contact.js` |
