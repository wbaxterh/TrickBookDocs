---
sidebar_position: 4
---

# Chrome Extension Integration Plan

This document outlines the plan to fully integrate the Map Scraper Chrome extension into the TrickBook ecosystem, enabling seamless spot discovery and sharing across all platforms.

## Current State

The Chrome extension currently:
- Extracts spot data from Google Maps
- Syncs spots to TrickBook via `/api/spots/bulk`
- Manages spot lists via `/api/spotlists` endpoints
- Uses existing JWT authentication

## Integration Goals

1. **Unified Spot Experience** - Spots saved via extension appear instantly in mobile app and website
2. **Cross-Platform Lists** - Users can access their spot lists from any platform
3. **Enhanced Discovery** - Enable spot sharing and community discovery features
4. **Chrome Web Store Publication** - Make the extension publicly available

---

## Phase 1: API Enhancements

### Priority: P1 (High)

Enhance the backend to better support the extension workflow.

### 1.1 Spot Deduplication

Prevent duplicate spots when syncing from extension.

```javascript
// New endpoint: POST /api/spots/bulk-upsert
// Deduplicates by lat/lon within ~50m radius

// Request
{
  "parks": [
    { "name": "...", "latitude": 40.8034, "longitude": -74.0706, ... }
  ]
}

// Response
{
  "created": [{ "_id": "...", ... }],
  "existing": [{ "_id": "...", ... }],
  "updated": []
}
```

**Backend Changes:**
```javascript
// routes/spots.js
router.post('/bulk-upsert', auth, async (req, res) => {
  const { parks } = req.body;
  const results = { created: [], existing: [], updated: [] };

  for (const park of parks) {
    // Find existing spot within 50m
    const existing = await Spot.findOne({
      latitude: { $gte: park.latitude - 0.0005, $lte: park.latitude + 0.0005 },
      longitude: { $gte: park.longitude - 0.0005, $lte: park.longitude + 0.0005 }
    });

    if (existing) {
      results.existing.push(existing);
    } else {
      const spot = await Spot.create(park);
      results.created.push(spot);
    }
  }

  res.json(results);
});
```

### 1.2 Spot Attribution

Track which user/source created each spot.

```javascript
// Update Spot schema
{
  // ... existing fields
  createdBy: { type: ObjectId, ref: 'users' },
  source: { type: String, enum: ['app', 'web', 'extension', 'import'] },
  googlePlaceId: String,  // For future Google integration
}
```

### 1.3 Image Proxy/Storage

Move images from Google CDN to S3 for reliability.

```javascript
// New endpoint: POST /api/spots/:id/upload-image
// Downloads image from URL and stores in S3

router.post('/:id/upload-image', auth, async (req, res) => {
  const { imageUrl } = req.body;
  const spot = await Spot.findById(req.params.id);

  // Download and upload to S3
  const s3Url = await uploadToS3(imageUrl, `spots/${spot._id}`);

  spot.imageURL = s3Url;
  await spot.save();

  res.json({ imageURL: s3Url });
});
```

---

## Phase 2: Mobile App Integration

### Priority: P1 (High)

Enable mobile users to view and interact with extension-synced spots.

### 2.1 Spot List Screen Updates

The mobile app already has spot list functionality. Ensure it:
- Displays all spots including those synced from extension
- Shows spot source indicator (optional)
- Renders Google-sourced images correctly

### 2.2 Map View Enhancement

Add a map view for spot lists:

```jsx
// screens/SpotMapScreen.js
import MapView, { Marker } from 'react-native-maps';

const SpotMapScreen = ({ spots }) => (
  <MapView
    initialRegion={calculateRegion(spots)}
    style={{ flex: 1 }}
  >
    {spots.map(spot => (
      <Marker
        key={spot._id}
        coordinate={{ latitude: spot.latitude, longitude: spot.longitude }}
        title={spot.name}
        description={spot.description}
      />
    ))}
  </MapView>
);
```

### 2.3 Spot Detail Screen

Create a detailed view for individual spots:

| Field | Display |
|-------|---------|
| Name | Large header |
| Image | Full-width hero |
| Location | City, State with map preview |
| Tags | Pill badges |
| Description | Text block |
| Rating | Star display |
| Actions | "Get Directions" button |

---

## Phase 3: Website Integration

### Priority: P2 (Medium)

Add spot features to the TrickBook website.

### 3.1 Spot Explorer Page

Public page showing community-shared spots:

```
/spots                    # Browse all spots
/spots?city=Los+Angeles   # Filter by city
/spots?tags=bowl          # Filter by tags
/spots/:id                # Individual spot detail
```

### 3.2 User Spot Lists

Private spot list management:

```
/my/spots                 # User's spot lists
/my/spots/:listId         # Individual list view
```

### 3.3 Embeddable Map Widget

Allow users to embed their spot map:

```html
<iframe
  src="https://thetrickbook.com/embed/spots/user123"
  width="600"
  height="400"
></iframe>
```

---

## Phase 4: Extension Enhancements

### Priority: P2 (Medium)

Improve the extension based on user feedback and integration needs.

### 4.1 Real-time Sync Status

Show sync status in popup:

```javascript
// Show sync indicator
const syncStatus = {
  lastSync: '2 minutes ago',
  pendingSpots: 3,
  syncErrors: []
};
```

### 4.2 Offline Queue

Queue spots when offline, sync when connection restored:

```javascript
// utils.js
async function queueForSync(spot) {
  const queue = await chrome.storage.local.get('syncQueue') || [];
  queue.push({ ...spot, queuedAt: Date.now() });
  await chrome.storage.local.set({ syncQueue: queue });
}

async function processSyncQueue() {
  const { syncQueue } = await chrome.storage.local.get('syncQueue');
  if (!syncQueue?.length) return;

  try {
    await syncSpots(syncQueue);
    await chrome.storage.local.remove('syncQueue');
  } catch (err) {
    console.error('Sync failed, will retry', err);
  }
}
```

### 4.3 Quick Actions

Add right-click context menu:

```javascript
// background.js
chrome.contextMenus.create({
  id: 'save-spot',
  title: 'Save to TrickBook',
  contexts: ['page'],
  documentUrlPatterns: ['*://www.google.com/maps/*']
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'save-spot') {
    chrome.tabs.sendMessage(tab.id, { action: 'extractAndSave' });
  }
});
```

---

## Phase 5: Chrome Web Store Publication

### Priority: P2 (Medium)

Make the extension publicly available.

### 5.1 Pre-Publication Checklist

- [ ] Update manifest.json with production URLs
- [ ] Create extension icons (16x16, 48x48, 128x128)
- [ ] Write store description
- [ ] Create promotional screenshots
- [ ] Create demo video
- [ ] Privacy policy page on website
- [ ] Terms of service

### 5.2 Store Listing Content

**Title:** TrickBook Spot Saver - Save Skateparks from Google Maps

**Short Description:**
Save skateparks and street spots from Google Maps directly to your TrickBook account. Tag, organize, and sync spots across all your devices.

**Category:** Productivity

### 5.3 Privacy Policy Requirements

Document data collection:
- Location data (coordinates from Google Maps)
- User authentication tokens
- Spot images (from Google CDN)

---

## Phase 6: Community Features

### Priority: P3 (Backlog)

Enable spot sharing and discovery.

### 6.1 Public Spot Database

Allow users to contribute spots to a public database:

```javascript
// New field on spots
{
  visibility: { type: String, enum: ['private', 'public'], default: 'private' },
  verifiedBy: [{ type: ObjectId, ref: 'users' }],
  reportCount: Number
}
```

### 6.2 Spot Discovery Feed

API endpoint for discovering new spots:

```http
GET /api/spots/discover?lat=40.80&lon=-74.07&radius=50
```

### 6.3 Spot Ratings & Reviews

```javascript
// New collection: spotReviews
{
  spotId: ObjectId,
  userId: ObjectId,
  rating: Number,  // 1-5
  review: String,
  visitedAt: Date,
  photos: [String]
}
```

---

## Implementation Timeline

| Phase | Priority | Dependencies |
|-------|----------|--------------|
| Phase 1: API Enhancements | P1 | None |
| Phase 2: Mobile Integration | P1 | Phase 1 |
| Phase 3: Website Integration | P2 | Phase 1 |
| Phase 4: Extension Enhancements | P2 | Phase 1 |
| Phase 5: Web Store Publication | P2 | Phase 4 |
| Phase 6: Community Features | P3 | Phase 1-3 |

---

## Technical Debt to Address

| Item | Effort | Impact | Notes |
|------|--------|--------|-------|
| Move Google API key to backend | Low | High | Security concern |
| Add image caching layer | Medium | Medium | Reduce Google CDN dependency |
| Implement spot search | Medium | High | Required for discovery |
| Add geospatial indexing | Low | High | MongoDB 2dsphere index |
| Rate limit bulk endpoints | Low | Medium | Prevent abuse |

---

## Metrics to Track

### Extension Metrics

- Extension installs (Chrome Web Store)
- Active users (weekly)
- Spots extracted per user
- Sync success rate
- Sync error types

### Spot Metrics

- Total spots in database
- Spots by source (app/web/extension)
- Average spots per user
- Most popular cities/states
- Tag distribution

### Engagement Metrics

- Cross-platform usage (users using both app + extension)
- List creation rate
- Spots per list average
- Map view engagement

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Google Maps scraping blocked | Add fallback manual entry mode |
| Google CDN images expire | Implement S3 proxy (Phase 1.3) |
| Rate limiting by Google | Cache geocoding results, batch requests |
| Extension review rejection | Follow Chrome Web Store policies strictly |
| Duplicate spots flooding DB | Implement deduplication (Phase 1.1) |

---

## Success Criteria

**Phase 1 Complete When:**
- Bulk upsert endpoint deployed
- No duplicate spots created
- Source attribution on all new spots

**Phase 2 Complete When:**
- Extension spots visible in mobile app
- Map view functional
- Deep linking from extension to app works

**Full Integration Complete When:**
- Extension published on Chrome Web Store
- 100+ users actively using extension
- Cross-platform sync works reliably
- Community discovery features launched
