---
sidebar_position: 2
---

# API Endpoints

Complete reference for all TrickBook API endpoints.

**Base URL:** `https://api.thetrickbook.com/api`

## Authentication

### Login

```http
POST /api/auth
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Google SSO

```http
POST /api/auth/google-auth
```

**Request:**
```json
{
  "idToken": "google_id_token_here"
}
```

**Response:**
```json
{
  "token": "jwt_token",
  "user": {
    "_id": "user_id",
    "email": "user@gmail.com",
    "name": "User Name"
  }
}
```

---

## Users

### Register User

```http
POST /api/users
```

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepass123"
}
```

**Response:** `201 Created`

### Get User by Email

```http
GET /api/users?email=user@example.com
```

**Headers:** `x-auth-token: jwt_token`

### Get Current User

```http
GET /api/user/me
```

**Headers:** `x-auth-token: jwt_token`

### Update User

```http
PUT /api/user
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "name": "New Name",
  "imageUri": "https://s3.amazonaws.com/..."
}
```

### Delete User

```http
DELETE /api/users/:id
```

**Headers:** `Authorization: Bearer jwt_token`

---

## Trick Lists

### Get User's Trick Lists

```http
GET /api/listings
```

**Headers:** `x-auth-token: jwt_token`

**Response:**
```json
[
  {
    "_id": "list_id",
    "name": "Kickflips to learn",
    "user": "user_id",
    "completed": 2,
    "tricks": [...]
  }
]
```

### Create Trick List

```http
POST /api/listings
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "name": "New Trick List"
}
```

### Count User's Lists

```http
GET /api/listings/countTrickLists
```

**Headers:** `x-auth-token: jwt_token`

---

## Individual Tricks

### Get Tricks in List

```http
GET /api/listing?list_id=xxx
```

**Headers:** `x-auth-token: jwt_token`

### Add Trick to List

```http
PUT /api/listing
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "list_id": "list_id",
  "name": "Kickflip",
  "checked": false
}
```

### Update Trick

```http
PUT /api/listing/:id
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "checked": true
}
```

### Delete Trick

```http
DELETE /api/listing/:id
```

**Headers:** `x-auth-token: jwt_token`

---

## Trickipedia (Global Encyclopedia)

### Get All Tricks

```http
GET /api/trickipedia
```

**Query Parameters:**
- `category` - Filter by category
- `difficulty` - Filter by difficulty
- `search` - Search by name

### Get Trick by ID

```http
GET /api/trickipedia/:id
```

### Get Tricks by Category

```http
GET /api/trickipedia/category/:category
```

### Create Trick (Admin)

```http
POST /api/trickipedia
```

**Headers:** `x-auth-token: admin_jwt_token`

**Request:**
```json
{
  "name": "Kickflip",
  "category": "Flip Tricks",
  "difficulty": "Intermediate",
  "description": "A flip trick...",
  "steps": ["Step 1", "Step 2"],
  "videoUrl": "https://youtube.com/...",
  "url": "kickflip"
}
```

### Update Trick (Admin)

```http
PUT /api/trickipedia/:id
```

### Delete Trick (Admin)

```http
DELETE /api/trickipedia/:id
```

---

## Spot Lists

### Create Spot List

```http
POST /api/spotlists
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "name": "LA Spots",
  "description": "Best spots in Los Angeles"
}
```

:::note Subscription Limits
Free users limited to 3 spot lists.
:::

### Get User's Spot Lists

```http
GET /api/spotlists
```

### Get Spot List

```http
GET /api/spotlists/:id
```

### Update Spot List

```http
PUT /api/spotlists/:id
```

### Delete Spot List

```http
DELETE /api/spotlists/:id
```

### Add Spot to List

```http
POST /api/spotlists/:id/spots
```

**Request:**
```json
{
  "spotId": "spot_object_id"
}
```

### Get Spots in List

```http
GET /api/spotlists/:id/spots
```

---

## Spots

### Create Spot

```http
POST /api/spots
```

**Request:**
```json
{
  "name": "Venice Beach Skatepark",
  "latitude": 33.9850,
  "longitude": -118.4695,
  "description": "Famous beachside park",
  "rating": 5,
  "tags": "park, transitions",
  "city": "Los Angeles",
  "state": "CA"
}
```

### Get All Spots

```http
GET /api/spots
```

### Bulk Insert Spots

```http
POST /api/spots/bulk
```

---

## Payments (Stripe)

### Create Checkout Session

```http
POST /api/payments/create-checkout-session
```

**Headers:** `x-auth-token: jwt_token`

**Response:**
```json
{
  "sessionId": "cs_xxx",
  "url": "https://checkout.stripe.com/..."
}
```

### Get Subscription Status

```http
GET /api/payments/subscription
```

**Headers:** `x-auth-token: jwt_token`

**Response:**
```json
{
  "plan": "premium",
  "status": "active",
  "currentPeriodEnd": "2024-12-31T00:00:00Z"
}
```

### Cancel Subscription

```http
POST /api/payments/cancel-subscription
```

### Reactivate Subscription

```http
POST /api/payments/reactivate-subscription
```

### Stripe Webhook

```http
POST /api/payments/webhook
```

*Handles Stripe events (invoice.paid, subscription.updated, etc.)*

---

## Image Upload

### Upload Profile Image

```http
POST /api/image/upload
Content-Type: multipart/form-data
```

**Form Fields:**
- `file` - Image file
- `email` - User email

**Response:**
```json
{
  "imageUri": "https://trickbook.s3.amazonaws.com/..."
}
```

### Upload Trick Image

```http
POST /api/trickImage/upload
Content-Type: multipart/form-data
```

### Delete Trick Images

```http
DELETE /api/trickImage/delete-folder/:slug
```

---

## Blog

### Get All Posts

```http
GET /api/blog
```

### Get Post by ID

```http
GET /api/blog/:id
```

### Get Post by URL Slug

```http
GET /api/blog/url/:url
```

### Create Post (Admin)

```http
POST /api/blog
```

### Update Post (Admin)

```http
PATCH /api/blog/update/:id
```

### Delete Post (Admin)

```http
DELETE /api/blog/:id
```

---

## Categories

### Get All Categories

```http
GET /api/categories
```

**Response:**
```json
[
  {
    "_id": "cat_id",
    "name": "Flip Tricks",
    "icon": "rotate-3d",
    "backgroundColor": "#4A90D9",
    "color": "#fff"
  }
]
```

---

## Other Endpoints

### Contact Form

```http
POST /api/contact
```

### Get Messages

```http
GET /api/messages
```

### Register Push Token

```http
POST /api/expoPushTokens
```

**Request:**
```json
{
  "token": "ExponentPushToken[xxx]"
}
```
