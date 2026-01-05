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

:::warning Current Anti-Pattern
Each route file creates its own connection. Should use a centralized connection pool.
:::

## Collections

### users

User accounts and subscription information.

```javascript
{
  _id: ObjectId,
  name: String,              // Display name
  email: String,             // Unique, used for login
  password: String,          // bcrypt hashed (null for Google SSO)
  imageUri: String,          // S3 URL for profile picture
  role: String,              // "admin" or null
  isGoogleSSO: Boolean,      // true if registered via Google

  subscription: {
    plan: String,            // "free" or "premium"
    status: String,          // "active", "canceled", "past_due"
    stripeCustomerId: String,
    stripeSubscriptionId: String,
    currentPeriodEnd: Date,
    lastPaymentDate: Date
  }
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
  imageURL: String,          // S3 or external URL
  description: String,
  rating: Number,            // 0-5
  tags: String,              // Comma-separated
  city: String,
  state: String
}
```

**Indexes:**
- Geospatial index on `{latitude, longitude}` (recommended)

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
