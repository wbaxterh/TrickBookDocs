---
sidebar_position: 2
---

# Data Model

Understanding the data structures used by the Chrome extension and how they map to the TrickBook API.

## Extracted Spot Data

When a user visits a Google Maps place page, the extension extracts the following:

### Raw Extraction (Client-Side)

```javascript
{
  name: "Lincoln Park Skatepark",      // From URL path
  lat: "40.8034311",                   // String from URL @lat,lon
  lon: "-74.0706182",                  // String from URL @lat,lon
  imageUrl: "https://lh3.googleusercontent.com/...",
  description: "",                      // User-provided
  tags: [],                            // User-selected
  city: "Jersey City",                 // From geocoding
  state: "NJ",                         // From geocoding
  createdAt: "2024-01-15T12:00:00Z"   // ISO timestamp
}
```

### Data Sources

| Field | Source | Fallback |
|-------|--------|----------|
| name | URL path segment | DOM title element |
| lat/lon | URL `@lat,lon,zoom` pattern | None |
| imageUrl | Google CDN `lh3.googleusercontent.com` | Placeholder |
| city | Google Geocoding API | DOM address parsing |
| state | Google Geocoding API | DOM address parsing |

## API Schema Transformation

The extension transforms local data to match the API schema before sync:

### Transformation Rules

```javascript
// Client format → API format
{
  name: spotData.name,
  latitude: parseFloat(spotData.lat),   // String → Float
  longitude: parseFloat(spotData.lon),  // String → Float
  imageURL: spotData.imageUrl,          // Note: different casing
  description: spotData.description,
  rating: 0,                            // Default value
  tags: spotData.tags.join(", "),       // Array → comma-separated string
  city: spotData.city,
  state: spotData.state
}
```

### API Spot Schema

```javascript
{
  _id: ObjectId,              // MongoDB ID (server-generated)
  name: String,               // Required
  latitude: Number,           // Required, float
  longitude: Number,          // Required, float
  imageURL: String,           // Optional
  description: String,        // Optional
  rating: Number,             // 0-5
  tags: String,               // Comma-separated
  city: String,               // Optional
  state: String,              // Optional
  createdAt: Date,            // Server timestamp
  updatedAt: Date             // Server timestamp
}
```

## Spot List Schema

```javascript
{
  _id: ObjectId,              // MongoDB ID
  name: String,               // Required, e.g., "NYC Street Parks"
  description: String,        // Optional
  userId: ObjectId,           // Reference to users collection
  spotIds: [ObjectId],        // Array of spot references
  createdAt: Date,
  updatedAt: Date
}
```

## Tag System

Available tags for categorizing spots:

| Tag | Description |
|-----|-------------|
| `bowl` | Has transition/bowl features |
| `street` | Street-style obstacles |
| `lights` | Has lighting for night sessions |
| `indoor` | Indoor facility |
| `beginner` | Suitable for beginners |
| `advanced` | Advanced features/obstacles |

## Local Storage Schema

The extension stores data locally using `chrome.storage.local`:

```javascript
// Auth token
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}

// Local spot cache (legacy)
{
  "skateparkList": [
    { name, lat, lon, imageUrl, tags, city, state, createdAt }
  ]
}

// Selected list preference
{
  "selectedListId": "list_id"
}
```

## Bulk Sync Request/Response

### Request

```http
POST /api/spots/bulk
Content-Type: application/json
x-auth-token: jwt_token

{
  "parks": [
    {
      "name": "Venice Beach Skatepark",
      "latitude": 33.985,
      "longitude": -118.469,
      "imageURL": "https://...",
      "description": "Famous beachside park",
      "tags": "park, transitions",
      "city": "Los Angeles",
      "state": "CA"
    }
  ]
}
```

### Response

```json
{
  "success": true,
  "spots": [
    {
      "_id": "spot_id_1",
      "name": "Venice Beach Skatepark",
      ...
    }
  ]
}
```

## Add Spot to List

### Request

```http
POST /api/spotlists/:listId/spots
Content-Type: application/json
x-auth-token: jwt_token

{
  "spotId": "spot_id_1"
}
```

### Response

```json
{
  "_id": "list_id",
  "name": "My Spots",
  "spotIds": ["spot_id_1", "spot_id_2"]
}
```
