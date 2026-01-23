---
sidebar_position: 1
---

# Trickipedia

The trick encyclopedia and personal trick list management system.

## Overview

Trickipedia is the core feature of TrickBook - a comprehensive trick encyclopedia covering skateboarding, snowboarding, surfing, and other action sports. Users can browse the global encyclopedia, track their personal progress, and discover new tricks to learn.

## Frontend Implementation

### Website (Next.js)

**Location:** `/pages/trickbook/`

| File | Purpose |
|------|---------|
| `index.js` | Main Trickipedia browse page with filtering |
| `[slug].js` | Individual trick detail page |
| `category/[category].js` | Category-specific trick listing |

**Components:**

| Component | Location | Purpose |
|-----------|----------|---------|
| `TrickCard.js` | `/components/TrickCard.js` | Displays trick preview with image, name, difficulty |
| `TrickFilters.js` | `/components/TrickFilters.js` | Filter by sport type, difficulty, category |

**Key Features:**
- Sport type filtering (skateboarding, snowboarding, surfing, BMX)
- Difficulty level filtering (beginner, intermediate, advanced, expert)
- Category filtering (flip tricks, grinds, grabs, etc.)
- Search functionality
- Responsive grid layout
- S3-hosted trick images with `unoptimized` prop for external URLs

### Mobile App (React Native)

**Location:** `/TrickList/screens/`

| Screen | Purpose |
|--------|---------|
| `TrickipediaScreen.js` | Browse global trick encyclopedia |
| `TrickDetailScreen.js` | View trick details, steps, video tutorials |
| `TrickListScreen.js` | User's personal trick lists |
| `AddTrickScreen.js` | Add tricks from Trickipedia to personal list |

**State Management:**
- Trick data cached in AsyncStorage for offline access
- Personal lists synced with backend when online
- Guest mode stores lists locally only

## Backend Implementation

### Database Schema

**Collection: `trickipedia`**

```javascript
{
  _id: ObjectId,
  name: String,              // "Kickflip"
  url: String,               // "kickflip" (URL slug)
  category: String,          // "Flip Tricks"
  difficulty: String,        // "Intermediate"
  description: String,       // Detailed description
  steps: [String],           // Step-by-step instructions
  tips: [String],            // Pro tips
  videoUrl: String,          // YouTube tutorial link
  imageUrl: String,          // S3 image URL
  sportTypes: [String],      // ["skateboarding"]
  prerequisites: [String],   // Tricks to learn first
  relatedTricks: [String],   // Similar tricks
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `{ url: 1 }` - Unique, for slug lookups
- `{ sportTypes: 1, category: 1 }` - For filtered queries
- `{ name: "text", description: "text" }` - Full-text search

**Collection: `tricklists`** (User's personal lists)

```javascript
{
  _id: ObjectId,
  user: ObjectId,            // Reference to users collection
  name: String,              // "Kickflips to learn"
  description: String,
  isPublic: Boolean,         // Share with community
  tricks: [{
    trickId: ObjectId,       // Reference to trickipedia
    name: String,            // Denormalized for performance
    checked: Boolean,        // Completed status
    notes: String,           // Personal notes
    addedAt: Date
  }],
  completed: Number,         // Count of checked tricks
  createdAt: Date,
  updatedAt: Date
}
```

### API Endpoints

**Base URL:** `https://api.thetrickbook.com/api`

#### Trickipedia (Public Encyclopedia)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/trickipedia` | List all tricks with filtering | No |
| GET | `/trickipedia/:id` | Get trick by ID | No |
| GET | `/trickipedia/url/:slug` | Get trick by URL slug | No |
| GET | `/trickipedia/category/:category` | Get tricks by category | No |
| POST | `/trickipedia` | Create trick | Admin |
| PUT | `/trickipedia/:id` | Update trick | Admin |
| DELETE | `/trickipedia/:id` | Delete trick | Admin |

**Query Parameters for GET /trickipedia:**
- `sportType` - Filter by sport (skateboarding, snowboarding, etc.)
- `category` - Filter by category
- `difficulty` - Filter by difficulty level
- `search` - Full-text search
- `limit` - Pagination limit (default 50)
- `skip` - Pagination offset

#### Personal Trick Lists

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/listings` | Get user's trick lists | JWT |
| POST | `/listings` | Create new list | JWT |
| GET | `/listings/countTrickLists` | Count user's lists | JWT |
| GET | `/listing?list_id=xxx` | Get tricks in list | JWT |
| PUT | `/listing` | Add trick to list | JWT |
| PUT | `/listing/:id` | Update trick status | JWT |
| DELETE | `/listing/:id` | Remove trick from list | JWT |

### Routes Implementation

**File:** `/Backend/routes/trickipedia.js`

```javascript
// Key route handlers

// GET /trickipedia - List with filters
router.get("/", async (req, res) => {
  const { sportType, category, difficulty, search, limit = 50, skip = 0 } = req.query;

  const query = {};
  if (sportType) query.sportTypes = sportType;
  if (category) query.category = category;
  if (difficulty) query.difficulty = difficulty;
  if (search) query.$text = { $search: search };

  const tricks = await Trickipedia.find(query)
    .limit(parseInt(limit))
    .skip(parseInt(skip))
    .sort({ name: 1 });

  res.json(tricks);
});

// GET /trickipedia/url/:slug - By URL slug
router.get("/url/:slug", async (req, res) => {
  const trick = await Trickipedia.findOne({ url: req.params.slug });
  if (!trick) return res.status(404).json({ error: "Trick not found" });
  res.json(trick);
});
```

## Image Storage

Trick images are stored in AWS S3:
- **Bucket:** `trickbook`
- **Path:** `/tricks/{slug}/`
- **Formats:** JPG, PNG, WebP
- **CDN:** CloudFront (optional)

**Upload Flow:**
1. Admin uploads image via admin panel
2. Backend generates presigned S3 URL
3. Frontend uploads directly to S3
4. Backend stores S3 URL in trick document

## Mobile-Specific Considerations

### Offline Support
- Trickipedia data cached on first load
- Personal lists stored in AsyncStorage
- Sync when connection restored

### Guest Mode
- Browse Trickipedia without account
- Create local-only trick lists
- Prompt to create account to sync

### Performance
- Lazy load trick images
- Pagination with infinite scroll
- Search debouncing (300ms)

## Admin Panel

**Location:** `/pages/admin/trickbook/`

Features:
- CRUD operations for tricks
- Bulk import from CSV
- Image upload to S3
- Category management
- Analytics dashboard

## Related Documentation

- [API Endpoints](/docs/backend/api-endpoints) - Full API reference
- [Mobile State Management](/docs/mobile/state-management) - AsyncStorage patterns
- [Database Schema](/docs/backend/database) - MongoDB collections
