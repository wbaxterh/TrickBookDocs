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

### Apple Sign-In

```http
POST /api/auth/apple-auth
```

**Request:**
```json
{
  "identityToken": "apple_identity_token",
  "user": {
    "email": "user@icloud.com",
    "name": { "firstName": "John", "lastName": "Doe" }
  }
}
```

**Response:**
```json
{
  "token": "jwt_token",
  "user": { "_id": "user_id", "email": "user@icloud.com", "name": "John Doe" }
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

### Get Current User

```http
GET /api/user/me
```

**Headers:** `x-auth-token: jwt_token`

### Get User by ID

```http
GET /api/user/:id
```

**Headers:** `x-auth-token: jwt_token`

### Get Public Profile

```http
GET /api/user/:id/public
```

*No authentication required.*

### Get User Stats

```http
GET /api/user/:id/stats
```

**Response:**
```json
{
  "trickCount": 42,
  "postCount": 15,
  "spotCount": 8,
  "loveCount": 120,
  "respectCount": 85
}
```

### Get User Activity

```http
GET /api/user/:id/activity
```

### Get User Count

```http
GET /api/user/count
```

*No authentication required.*

### Check Homie Status

```http
GET /api/user/homie-status/:targetId
```

**Headers:** `x-auth-token: jwt_token`

**Response:**
```json
{
  "status": "friends" | "pending_sent" | "pending_received" | "none"
}
```

### Update User

```http
PUT /api/user/:id
```

**Headers:** `x-auth-token: jwt_token`

### Delete User

```http
DELETE /api/users/:id
```

**Headers:** `x-auth-token: jwt_token` (must be account owner or admin)

### Get All Users (Admin)

```http
GET /api/users/all
```

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
    "isPublic": false,
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

### Get Public Trick Lists

```http
GET /api/listings/public
```

### Toggle Visibility

```http
PUT /api/listings/:id/visibility
```

**Headers:** `x-auth-token: jwt_token`

### Count User's Lists

```http
GET /api/listings/countTrickLists
```

### Delete Trick List

```http
DELETE /api/listings/:id
```

---

## Individual Tricks

### Get Tricks in List

```http
GET /api/listing?list_id=xxx
```

### Get All User's Tricks

```http
GET /api/listing/allTricks?userId=xxx
```

### Get Trick Completion Graph

```http
GET /api/listing/graph
```

### Add Trick to List

```http
POST /api/listing
```

**Request:**
```json
{
  "list_id": "list_id",
  "name": "Kickflip",
  "checked": "Not Started"
}
```

### Update Trick Status

```http
PUT /api/listing/:id
```

**Request:**
```json
{
  "checked": "Landed"
}
```

### Edit Trick Details

```http
PUT /api/listing/edit
```

### Delete Trick

```http
DELETE /api/listing/:id
```

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

## Spots

### Get All Spots

```http
GET /api/spots
```

**Headers:** `x-auth-token: jwt_token`

### Get Spot by ID

```http
GET /api/spots/:id
```

### Create Spot

```http
POST /api/spots
```

**Headers:** `x-auth-token: jwt_token`

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
  "state": "CA",
  "sportTypes": ["skateboarding"],
  "category": "park"
}
```

### Update Spot

```http
PUT /api/spots/:id
```

### Delete Spot

```http
DELETE /api/spots/:id
```

### Get Sport Types

```http
GET /api/spots/sport-types
```

### Google Places Search

```http
GET /api/spots/places-search?query=skatepark
```

**Headers:** `x-auth-token: jwt_token`

---

## Spot Lists

### Get User's Spot Lists

```http
GET /api/spotlists
```

**Headers:** `x-auth-token: jwt_token`

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
Free users limited to 3 spot lists, 5 spots per list, 15 total spots.
:::

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

### Remove Spot from List

```http
DELETE /api/spotlists/:id/spots/:spotId
```

### Get Spots in List

```http
GET /api/spotlists/:id/spots
```

### Get Subscription Usage

```http
GET /api/spotlists/usage
```

---

## Spot Reviews

### Get Reviews for Spot

```http
GET /api/spot-reviews?spotId=xxx
```

### Create Review

```http
POST /api/spot-reviews
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "spotId": "spot_id",
  "rating": 4,
  "content": "Great park with smooth concrete"
}
```

### Update Review

```http
PUT /api/spot-reviews/:id
```

### Delete Review

```http
DELETE /api/spot-reviews/:id
```

---

## Social Feed

### Get Feed

```http
GET /api/feed
```

**Headers:** `x-auth-token: jwt_token`

*Returns posts ranked by algorithm (engagement, recency, homie boost).*

### Get Post Details

```http
GET /api/feed/:postId
```

### Create Post

```http
POST /api/feed/posts
```

**Headers:** `x-auth-token: jwt_token`

**Request:**
```json
{
  "caption": "First kickflip!",
  "mediaType": "video",
  "mediaUrl": "https://cdn.example.com/video.mp4",
  "thumbnailUrl": "https://cdn.example.com/thumb.jpg",
  "tricks": ["Kickflip"]
}
```

### Update Post

```http
PUT /api/feed/:postId
```

### Delete Post

```http
DELETE /api/feed/:postId
```

### React to Post

```http
POST /api/feed/:postId/reactions
```

**Request:**
```json
{
  "type": "love" | "respect"
}
```

### Get Comments

```http
GET /api/feed/:postId/comments
```

### Add Comment

```http
POST /api/feed/:postId/comments
```

**Request:**
```json
{
  "content": "Sick clip!"
}
```

### Delete Comment

```http
DELETE /api/feed/:postId/comments/:commentId
```

### Feed Algorithm

Posts are ranked using a weighted scoring algorithm:

| Factor | Weight | Description |
|--------|--------|-------------|
| Engagement | 0.35 | Reactions, comments, shares, views |
| Recency | 0.25 | 48-hour half-life decay |
| Completion | 0.25 | User engagement rate |
| Interaction | 0.15 | User-specific interaction history |
| Homie boost | 2.5x | Multiplier for posts from friends |

---

## Direct Messages

### Get Conversations

```http
GET /api/dm/conversations
```

**Headers:** `x-auth-token: jwt_token`

### Get Conversation

```http
GET /api/dm/conversations/:conversationId
```

### Send Message

```http
POST /api/dm/messages
```

**Request:**
```json
{
  "conversationId": "conv_id",
  "content": "Hey, want to skate today?"
}
```

### Get Messages

```http
GET /api/dm/messages/:conversationId
```

### Mark as Read

```http
PUT /api/dm/messages/:messageId/read
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

### Admin Toggle Subscription

```http
POST /api/payments/admin/toggle-subscription
```

**Headers:** `x-auth-token: admin_jwt_token`

### Stripe Webhook

```http
POST /api/payments/webhook
```

*Handles: checkout.session.completed, invoice.paid, customer.subscription.updated/deleted*

---

## The Couch

### Get Videos

```http
GET /api/couch
```

*Returns curated action sports videos from Google Drive/Bunny.net CDN.*

---

## Media & Uploads

### Upload Media

```http
POST /api/media
Content-Type: multipart/form-data
```

### Upload Profile Image

```http
POST /api/image/upload
Content-Type: multipart/form-data
```

**Form Fields:**
- `file` - Image file
- `email` - User email

### Upload Trick Image

```http
POST /api/trickImage/upload?trickUrl=kickflip
Content-Type: multipart/form-data
```

### Delete Trick Images

```http
DELETE /api/trickImage/delete-folder/:slug
```

### Upload Blog Image

```http
POST /api/blogImage
Content-Type: multipart/form-data
```

---

## Blog

### Get All Posts

```http
GET /api/blog
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

## Other Endpoints

### Categories

```http
GET /api/categories
```

### Contact Form

```http
POST /api/contact
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

### Get Messages (Legacy)

```http
GET /api/messages
```

---

## Real-Time (Socket.IO)

In addition to REST endpoints, the backend provides real-time features via Socket.IO.

**Connection:** `wss://api.thetrickbook.com`
**Auth:** JWT token passed in `socket.handshake.auth.token`

### Feed Namespace (`/feed`)

| Event | Direction | Description |
|-------|-----------|-------------|
| `post:update` | Server → Client | Post data changed |
| `reaction:update` | Server → Client | Reaction counts changed |
| `comment:new` | Server → Client | New comment on post |

### Messages Namespace (`/messages`)

| Event | Direction | Description |
|-------|-----------|-------------|
| `message:new` | Server → Client | New message received |
| `typing` | Client → Server | User typing indicator |
| `read` | Client → Server | Message read receipt |
