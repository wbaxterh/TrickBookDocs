---
sidebar_position: 4
---

# Database

TrickBook uses MongoDB Atlas for data storage.

## Connection

**Database:** `TrickList2`
**Host:** MongoDB Atlas (cloud)

```javascript
const { MongoClient } = require("mongodb");

const ATLAS_URI = process.env.ATLAS_URI;
// mongodb+srv://user:pass@cluster.mongodb.net/TrickList2

const client = new MongoClient(ATLAS_URI);
await client.connect();
const db = client.db("TrickList2");
```

:::info[Connection pooling]
`db.js` opens one pooled `MongoClient` at boot and every route factory receives the shared `db` handle. Route files do not open their own connections.
:::

## Schema layer

The backend uses the raw driver, not Mongoose, so for a long time a collection's shape was whatever each `insertOne` wrote. Since September 2026 every collection the code touches has a declared `$jsonSchema` in `schemas/collections/*.js` (49 collections, grouped by domain: identity, tricks, spots, feed, media, social, community).

How it works:

- `schemas/index.js` loads the files into a registry. `test/schema-registry.test.js` fails CI when any `collection('name')` call in the code has no schema, so the registry cannot drift silently.
- On every boot `schemas/apply.js` pushes each schema to Atlas as a collection validator with `collMod`. It never creates a collection, and a failing `collMod` is logged, not fatal.
- `SCHEMA_VALIDATION_ACTION` is `warn` by default (violations go to the server log only), `error` rejects non-conforming writes, `off` skips the apply. `SCHEMA_VALIDATION_LEVEL` is `moderate` (inserts and updates to already-valid documents) or `strict`.
- `npm run schema:report` samples the newest documents in each collection and validates them app-side with `schemas/validate.js`. This is the feedback loop on the free Atlas tier, where the server's warn log cannot be read. Promote a collection to `error` only after the report is clean for it.

Every schema is open (`additionalProperties` is never false) because production holds fields the current code no longer writes. Each entry carries `writers` (the files that insert or `$set` it) and `notes` that record where writers disagree.

### User id shapes

`req.user.userId` comes out of the JWT as a 24-character hex string. Some writers store it as that string, some convert it with `new ObjectId()`, and rows from the original app hold a DBRef (`tricklists.user`). The schemas list every shape that exists per field rather than the shape we wish existed. `utils/ids.js` (`toObjectId`, `idEquals`, `anyIdShape`) reads and queries across them. New code stores ObjectId; converging the existing data is a separate migration.

:::warning[Reading the collection sketches below]
The field lists that follow predate the schema layer and are illustrative. The files under `schemas/collections/` are the source of truth for field names and types.
:::

## Collections

### users

User accounts and subscription information.

```javascript
{
  _id: ObjectId,
  name: String,              // Display name
  email: String,             // Unique, used for login
  password: String,          // bcrypt hashed (null for SSO users)
  imageUri: String,          // S3 URL for profile picture
  role: String,              // "admin" or null
  isGoogleSSO: Boolean,      // true if registered via Google
  appleUserId: String,       // Apple Sign-In identifier
  sports: [String],          // Array of sport types
  riderProfile: Object,      // User's rider info

  // Social features
  network: Object,           // User connections
  homies: [ObjectId],        // Array of friend user IDs
  homieRequests: {
    sent: [ObjectId],        // Outgoing requests
    received: [ObjectId]     // Incoming requests
  },

  subscription: {
    plan: String,            // "free" or "premium"
    status: String,          // "active", "canceled", "past_due"
    stripeCustomerId: String,
    stripeSubscriptionId: String,
    currentPeriodEnd: Date,
    lastPaymentDate: Date,
    adminOverride: Boolean   // For testing
  },

  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `email` (unique)

---

### tricklists

User's personal trick lists.

```javascript
{
  _id: ObjectId,
  name: String,              // List name
  user: ObjectId,            // Reference to users._id
  completed: Number,         // Count of checked tricks
  tricks: [
    {
      _id: ObjectId,
      name: String,
      checked: Boolean
    }
  ]
}
```

**Relationships:**
- `user` → `users._id`

---

### tricks

Individual tricks (legacy collection, embedded in tricklists).

```javascript
{
  _id: ObjectId,
  list_id: String,           // Reference to tricklists._id
  name: String,
  checked: Boolean
}
```

---

### trickipedia

Global trick encyclopedia (admin-managed).

```javascript
{
  _id: ObjectId,
  name: String,              // Trick name
  category: String,          // e.g., "Flip Tricks", "Grinds"
  difficulty: String,        // e.g., "Beginner", "Intermediate"
  description: String,       // Full description
  steps: [String],           // Step-by-step instructions
  images: [String],          // S3 URLs
  videoUrl: String,          // YouTube/external video
  source: String,            // Attribution
  url: String,               // URL slug for SEO
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `url` (unique)
- `category`
- `name` (text index for search)

---

### spotlists

User's spot list collections.

```javascript
{
  _id: ObjectId,
  name: String,
  description: String,
  userId: String,            // User's ObjectId as string
  spotIds: [ObjectId],       // References to spots
  createdAt: Date,
  updatedAt: Date
}
```

**Relationships:**
- `userId` → `users._id`
- `spotIds[]` → `spots._id`

---

### spots

Skate spot locations.

```javascript
{
  _id: ObjectId,
  name: String,
  latitude: Number,
  longitude: Number,
  images: [String],          // Array of image URLs
  description: String,
  rating: Number,            // 0-5
  tags: String,              // Comma-separated
  city: String,
  state: String,
  sportTypes: [String],      // skateboarding, bmx, etc.
  category: String,          // park, street, indoor, diy, other
  userId: ObjectId,          // Creator reference
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- Geospatial index on `{latitude, longitude}` (recommended)

---

### feed_posts

Social feed posts with media content.

```javascript
{
  _id: ObjectId,
  userId: ObjectId,          // Creator reference
  caption: String,
  description: String,
  mediaType: String,         // "video" or "image"
  mediaUrl: String,          // CDN URL
  thumbnailUrl: String,      // Video thumbnail
  tricks: [String],          // Associated trick names
  stats: {
    loveCount: Number,
    respectCount: Number,
    commentCount: Number,
    shareCount: Number,
    viewCount: Number
  },
  engagement: {
    completionRate: Number
  },
  createdAt: Date,
  updatedAt: Date
}
```

---

### reactions

Love/respect reactions on feed posts.

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  postId: ObjectId,
  type: String,              // "love" or "respect"
  createdAt: Date
}
```

---

### feed_comments

Comments on feed posts.

```javascript
{
  _id: ObjectId,
  postId: ObjectId,
  userId: ObjectId,
  content: String,
  createdAt: Date
}
```

---

### saved_posts

User bookmarked posts.

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  postId: ObjectId,
  createdAt: Date
}
```

---

### conversations

Direct message conversations.

```javascript
{
  _id: ObjectId,
  participants: [ObjectId],  // User IDs
  lastMessage: Object,       // Preview of last message
  createdAt: Date,
  updatedAt: Date
}
```

---

### dm_messages

Individual direct messages.

```javascript
{
  _id: ObjectId,
  conversationId: ObjectId,
  senderId: ObjectId,
  content: String,
  read: Boolean,
  createdAt: Date
}
```

---

### blog

Website blog posts.

```javascript
{
  _id: ObjectId,
  title: String,
  author: String,
  date: Date,
  content: String,           // HTML or Markdown
  url: String,               // URL slug
  images: [String]           // S3 URLs
}
```

**Indexes:**
- `url` (unique)

---

### categories

Trick categories for the app.

```javascript
{
  _id: ObjectId,
  name: String,              // e.g., "Flip Tricks"
  icon: String,              // Icon name for MaterialCommunityIcons
  backgroundColor: String,   // Hex color
  color: String              // Text color
}
```

---

### expoPushTokens

Push notification tokens.

```javascript
{
  _id: ObjectId,
  token: String,             // ExponentPushToken[xxx]
  userId: ObjectId
}
```

---

### messages

Contact form submissions.

```javascript
{
  _id: ObjectId,
  name: String,
  email: String,
  message: String,
  createdAt: Date
}
```

## Data Relationships

```
users
  │
  ├──< tricklists (user field)
  │       │
  │       └──< tricks (embedded or list_id)
  │
  ├──< spotlists (userId field)
  │       │
  │       └──< spots (spotIds array)
  │
  ├──< feed_posts (userId field)
  │       │
  │       ├──< reactions (postId field)
  │       ├──< feed_comments (postId field)
  │       └──< saved_posts (postId field)
  │
  ├──< conversations (participants array)
  │       │
  │       └──< dm_messages (conversationId field)
  │
  ├──< homies (users.homies array → users._id)
  │
  └──< expoPushTokens (userId field)

trickipedia (standalone, admin-managed)

blog (standalone, admin-managed)

categories (standalone, admin-managed)
```

## Query Examples

### Get User's Trick Lists with Tricks

```javascript
const tricklists = await db.collection("tricklists")
  .find({ user: new ObjectId(userId) })
  .toArray();
```

### Search Trickipedia

```javascript
const tricks = await db.collection("trickipedia")
  .find({
    $or: [
      { name: { $regex: searchTerm, $options: "i" } },
      { description: { $regex: searchTerm, $options: "i" } }
    ],
    category: categoryFilter,
    difficulty: difficultyFilter
  })
  .toArray();
```

### Get Spots in List

```javascript
const spotlist = await db.collection("spotlists")
  .findOne({ _id: new ObjectId(listId) });

const spots = await db.collection("spots")
  .find({ _id: { $in: spotlist.spotIds } })
  .toArray();
```

### Update Subscription

```javascript
await db.collection("users").updateOne(
  { _id: new ObjectId(userId) },
  {
    $set: {
      "subscription.plan": "premium",
      "subscription.status": "active",
      "subscription.stripeSubscriptionId": subscriptionId,
      "subscription.currentPeriodEnd": new Date(periodEnd * 1000)
    }
  }
);
```

## Recommended Indexes

```javascript
// users
db.users.createIndex({ email: 1 }, { unique: true });

// tricklists
db.tricklists.createIndex({ user: 1 });

// trickipedia
db.trickipedia.createIndex({ url: 1 }, { unique: true });
db.trickipedia.createIndex({ category: 1 });
db.trickipedia.createIndex({ name: "text", description: "text" });

// spotlists
db.spotlists.createIndex({ userId: 1 });

// spots (for geospatial queries)
db.spots.createIndex({ latitude: 1, longitude: 1 });

// blog
db.blog.createIndex({ url: 1 }, { unique: true });
```

## Backup Strategy

MongoDB Atlas provides:
- Continuous backups
- Point-in-time recovery
- Snapshot backups

Access via Atlas dashboard → Backup → Snapshots.
