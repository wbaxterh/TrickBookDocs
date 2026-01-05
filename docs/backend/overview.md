---
sidebar_position: 1
---

# Backend Overview

The TrickBook backend is a Node.js Express API that serves both the mobile app and website.

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
│   └── subscription.js   # Freemium limits
│
├── routes/               # API endpoints (15+ files)
│   ├── auth.js          # Authentication
│   ├── users.js         # User management
│   ├── listings.js      # Trick lists
│   ├── trickipedia.js   # Trick encyclopedia
│   ├── payments.js      # Stripe subscriptions
│   ├── spots.js         # Skate spots
│   ├── spotlists.js     # Spot collections
│   ├── blog.js          # Blog content
│   ├── image.js         # Image uploads
│   └── ...
│
├── utilities/            # Helper functions
│   └── pushNotifications.js
│
├── store/               # Legacy in-memory stores
│   └── users.js
│
├── index.js             # App entry point
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

# Auth
JWT_SECRET=your_secure_jwt_secret
GOOGLE_CLIENT_ID=your_google_oauth_client_id

# Stripe
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PREMIUM_PRICE_ID=price_xxx

# Email
EMAIL_USER=admin@thetrickbook.com
EMAIL_PASSWORD=app_specific_password
```

:::danger Security Warning
Never commit `.env` files to version control. The current repository has exposed credentials that need to be rotated.
:::

## Configuration

The `config` package loads environment-specific settings:

```javascript
// config/default.json
{
  "maxImageCount": 3,
  "delay": 1000
}

// config/development.json
{
  "apiUrl": "http://192.168.86.91:9000",
  "port": 9000
}
```

Access in code:
```javascript
const config = require('config');
const port = config.get('port');
```

## Middleware Stack

Request processing order:

```
Request
   │
   ▼
┌──────────────┐
│    CORS      │  Allow cross-origin requests
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Helmet     │  Security headers
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Body Parser  │  Parse JSON/form data
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Compression  │  Gzip responses
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

## Database Connection

Currently, each route file creates its own connection (anti-pattern):

```javascript
// Current pattern (in each route file)
const { MongoClient } = require("mongodb");
const client = new MongoClient(process.env.ATLAS_URI);
await client.connect();
const db = client.db("TrickList2");
```

:::tip Improvement Needed
Should use a centralized connection pool. See [Security Fixes](/docs/roadmap/security-fixes).
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

| Feature | Free | Premium |
|---------|------|---------|
| Spot Lists | 3 max | Unlimited |
| Spots per List | 5 max | Unlimited |
| Total Spots | 15 max | Unlimited |
| Trick Lists | Unlimited | Unlimited |

```javascript
// middleware/subscription.js
const limits = {
  maxSpotLists: 3,
  maxSpotsPerList: 5,
  maxTotalSpots: 15
};
```
