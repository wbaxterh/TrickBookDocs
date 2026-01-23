---
sidebar_position: 2
---

# Spots

Community-driven skate spot and action sports location database.

## Overview

The Spots feature allows users to discover, share, and organize action sports locations. Users can browse a global map of spots, create personal spot lists, and contribute new locations. The Chrome Extension enables bulk importing from Google Maps.

## Frontend Implementation

### Website (Next.js)

**Location:** `/pages/spots/`

| File | Purpose |
|------|---------|
| `index.js` | Main spots page with interactive map |
| `[state]/index.js` | State-specific spot listing |
| `[state]/[city].js` | City-specific spot listing |
| `[state]/[city]/[spot].js` | Individual spot detail page |

**Components:**

| Component | Location | Purpose |
|-----------|----------|---------|
| `SpotCard.js` | `/components/SpotCard.js` | Spot preview with image, name, rating |
| `SpotMap.js` | `/components/SpotMap.js` | Interactive Google Maps with markers |
| `SpotFilters.js` | `/components/SpotFilters.js` | Filter by type, amenities, rating |
| `StateCard.js` | `/components/spots/StateCard.js` | State navigation card |

**Key Features:**
- Interactive map with clustered markers
- Filter by spot type (park, street, DIY, etc.)
- Filter by amenities (lights, bathroom, free entry)
- State/city hierarchical navigation
- User ratings and reviews
- Photo galleries
- Directions integration (Google Maps, Apple Maps)

### Map Integration

**Google Maps Setup:**
```javascript
// /components/SpotMap.js
import { GoogleMap, Marker, MarkerClusterer } from "@react-google-maps/api";

const SpotMap = ({ spots, center, zoom }) => {
  return (
    <GoogleMap
      mapContainerStyle={{ width: "100%", height: "500px" }}
      center={center}
      zoom={zoom}
    >
      <MarkerClusterer>
        {(clusterer) =>
          spots.map((spot) => (
            <Marker
              key={spot._id}
              position={{ lat: spot.latitude, lng: spot.longitude }}
              clusterer={clusterer}
              onClick={() => handleMarkerClick(spot)}
            />
          ))
        }
      </MarkerClusterer>
    </GoogleMap>
  );
};
```

### Mobile App (React Native)

**Location:** `/TrickList/screens/`

| Screen | Purpose |
|--------|---------|
| `SpotsScreen.js` | Browse spots with map view |
| `SpotDetailScreen.js` | View spot details, photos, directions |
| `SpotListsScreen.js` | User's personal spot collections |
| `AddSpotScreen.js` | Submit new spot with location picker |

**Map Library:** `react-native-maps`

## Backend Implementation

### Database Schema

**Collection: `spots`**

```javascript
{
  _id: ObjectId,
  name: String,              // "Venice Beach Skatepark"
  slug: String,              // "venice-beach-skatepark" (URL-safe)
  description: String,
  latitude: Number,          // 33.9850
  longitude: Number,         // -118.4695
  address: String,           // Full street address
  city: String,              // "Los Angeles"
  state: String,             // "CA" or "California"
  country: String,           // "USA"
  postalCode: String,

  // Classification
  type: String,              // "park", "street", "diy", "plaza"
  sportTypes: [String],      // ["skateboarding", "bmx"]
  tags: [String],            // ["bowl", "street", "transitions"]

  // Amenities
  amenities: {
    lights: Boolean,
    bathroom: Boolean,
    water: Boolean,
    shade: Boolean,
    freeEntry: Boolean,
    rental: Boolean
  },

  // Media
  images: [String],          // S3 URLs
  thumbnailUrl: String,      // Primary image

  // Ratings
  rating: Number,            // Average (1-5)
  ratingCount: Number,       // Number of ratings

  // Meta
  googlePlaceId: String,     // For Google Maps integration
  submittedBy: ObjectId,     // User who added spot
  isVerified: Boolean,       // Admin verified
  isActive: Boolean,         // Soft delete flag

  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `{ latitude: 1, longitude: 1 }` - Geospatial queries
- `{ state: 1, city: 1 }` - Location hierarchy
- `{ slug: 1 }` - URL lookups
- `{ sportTypes: 1, type: 1 }` - Filtered queries
- `{ "location": "2dsphere" }` - Geospatial index (if using GeoJSON)

**Collection: `spotlists`** (User's saved spot collections)

```javascript
{
  _id: ObjectId,
  user: ObjectId,
  name: String,              // "LA Weekend Spots"
  description: String,
  isPublic: Boolean,
  spots: [ObjectId],         // References to spots collection
  coverImage: String,        // S3 URL
  createdAt: Date,
  updatedAt: Date
}
```

**Collection: `spot_ratings`**

```javascript
{
  _id: ObjectId,
  spot: ObjectId,
  user: ObjectId,
  rating: Number,            // 1-5
  review: String,            // Optional text review
  images: [String],          // User-submitted photos
  createdAt: Date
}
```

### API Endpoints

**Base URL:** `https://api.thetrickbook.com/api`

#### Spots (Public)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/spots` | List all spots with filtering | No |
| GET | `/spots/:id` | Get spot by ID | No |
| GET | `/spots/slug/:slug` | Get spot by URL slug | No |
| GET | `/spots/state/:state` | Get spots by state | No |
| GET | `/spots/city/:state/:city` | Get spots by city | No |
| GET | `/spots/nearby` | Get spots near coordinates | No |
| POST | `/spots` | Create new spot | JWT |
| PUT | `/spots/:id` | Update spot | JWT/Admin |
| DELETE | `/spots/:id` | Delete spot | Admin |
| POST | `/spots/bulk` | Bulk import spots | Admin |

**Query Parameters for GET /spots:**
- `lat` & `lng` - Center point for nearby search
- `radius` - Search radius in miles (default 25)
- `type` - Filter by spot type
- `sportType` - Filter by sport
- `state` - Filter by state
- `city` - Filter by city
- `limit` - Pagination (default 50)
- `skip` - Offset

#### Spot Lists (User Collections)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/spotlists` | Get user's spot lists | JWT |
| POST | `/spotlists` | Create spot list | JWT |
| GET | `/spotlists/:id` | Get spot list details | JWT |
| PUT | `/spotlists/:id` | Update spot list | JWT |
| DELETE | `/spotlists/:id` | Delete spot list | JWT |
| POST | `/spotlists/:id/spots` | Add spot to list | JWT |
| DELETE | `/spotlists/:id/spots/:spotId` | Remove spot from list | JWT |

#### Spot Ratings

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/spots/:id/ratings` | Get spot ratings | No |
| POST | `/spots/:id/ratings` | Add rating | JWT |
| PUT | `/spots/:id/ratings/:ratingId` | Update rating | JWT |
| DELETE | `/spots/:id/ratings/:ratingId` | Delete rating | JWT |

### Routes Implementation

**File:** `/Backend/routes/spots.js`

```javascript
// Nearby spots with geospatial query
router.get("/nearby", async (req, res) => {
  const { lat, lng, radius = 25 } = req.query;

  const spots = await Spot.find({
    latitude: {
      $gte: parseFloat(lat) - (radius / 69),
      $lte: parseFloat(lat) + (radius / 69)
    },
    longitude: {
      $gte: parseFloat(lng) - (radius / 54.6),
      $lte: parseFloat(lng) + (radius / 54.6)
    },
    isActive: true
  }).limit(100);

  res.json(spots);
});

// Spots by state with city grouping
router.get("/state/:state", async (req, res) => {
  const spots = await Spot.aggregate([
    { $match: { state: req.params.state, isActive: true } },
    { $group: {
      _id: "$city",
      spots: { $push: "$$ROOT" },
      count: { $sum: 1 }
    }},
    { $sort: { count: -1 } }
  ]);

  res.json(spots);
});
```

## Chrome Extension Integration

The Chrome Extension (Map Scraper) extracts spots from Google Maps and syncs to the backend.

**Flow:**
1. User browses Google Maps searching for skate spots
2. Extension extracts: name, address, coordinates, rating, photos
3. User categorizes with tags (park, street, lights, etc.)
4. Bulk sync to TrickBook via `/spots/bulk` endpoint

**Data Extraction:**
```javascript
// Extension extracts from Google Maps DOM
{
  name: "Venice Beach Skatepark",
  address: "1800 Ocean Front Walk, Venice, CA 90291",
  latitude: 33.9850,
  longitude: -118.4695,
  googlePlaceId: "ChIJ...",
  rating: 4.5,
  photos: ["url1", "url2"]
}
```

See [Chrome Extension Documentation](/docs/chrome-extension/overview) for details.

## Image Storage

Spot images stored in AWS S3:
- **Bucket:** `trickbook`
- **Path:** `/spots/{spot-id}/`
- **Thumbnail generation:** Automatic resize to 400x300

## Mobile Considerations

### Offline Mode
- Spots in user's lists cached locally
- Map tiles cached for offline viewing
- Sync when connection restored

### Location Services
- Request location permission for nearby spots
- Background location for "spots near me" notifications
- Geofencing for spot check-ins (future)

### Performance
- Cluster markers for large datasets
- Lazy load images
- Pagination with infinite scroll

## Related Documentation

- [Chrome Extension](/docs/chrome-extension/overview) - Map scraper for bulk import
- [API Endpoints](/docs/backend/api-endpoints) - Full API reference
- [Database Schema](/docs/backend/database) - MongoDB collections
