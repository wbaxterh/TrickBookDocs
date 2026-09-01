---
sidebar_position: 0
---

# Features Overview

Comprehensive documentation for TrickBook's core features.

## Platform Features

TrickBook is a platform dedicated to action sports, providing tools for riders to track progress, discover spots, connect with friends, and watch content.

```mermaid
flowchart LR
    subgraph Core["Core Features"]
        TB[📘 Trickipedia]
        SP[📍 Spots]
        HM[🤝 Homies]
        MD[🎬 Media]
        EV[📅 Events]
    end

    subgraph TB_Sub["Trick System"]
        TB --> Encyclopedia["Global Encyclopedia"]
        TB --> Lists["Personal Lists"]
        TB --> Progress["Progress Tracking"]
    end

    subgraph SP_Sub["Location System"]
        SP --> Map["Interactive Map"]
        SP --> SpotLists["Spot Collections"]
        SP --> Discovery["Spot Discovery"]
    end

    subgraph HM_Sub["Social System"]
        HM --> Friends["Friend Connections"]
        HM --> DM["Direct Messages"]
        HM --> Activity["Activity Feed"]
    end

    subgraph MD_Sub["Content System"]
        MD --> Couch["The Couch (Films)"]
        MD --> Feed["User Feed"]
        MD --> Comments["Comments"]
    end

    subgraph EV_Sub["Event System"]
        EV --> Nearby["Nearby Discovery"]
        EV --> Enter["Registration Links"]
        EV --> Watch["Tickets and Livestreams"]
        EV --> Alerts["Saved Events and Alerts"]
    end
```

## Feature Summary

| Feature | Description | Status |
|---------|-------------|--------|
| [Trickipedia](/docs/features/trickbook) | Trick encyclopedia and personal lists | ✅ Live |
| [Spots](/docs/features/spots) | Skate spot database with maps | ✅ Live |
| [Homies](/docs/features/homies) | Social connections and messaging | ✅ Live |
| [Media](/docs/features/media) | Video streaming and user content | ✅ Live |
| [Events](/docs/features/events) | Multi-sport discovery and registration/watch links; alerts remain planned | 🟡 Partial MVP |

## Recent Updates (March 2026)

### Spots & Resorts (Mar 22–29)
- **Resort info UI** — ratings, stats, features display for ski/snowboard spots
- **Photo carousel + lodging cards** on spot detail pages
- Connected tricks, spots, and feed videos — spot/video tagging on tricklists, trick history on spot pages, spot tagging on feed uploads
- Fixed infinite loading on spot list detail and my-spots pages

### Kaori AI Companion (Mar 23)
- AI companion in messages — bot companions section, AI badge, auto-conversation creation
- Bio, location, AI badge on profile page + Kaori full rider profile
- Uses OpenRouter (Claude 3 Haiku) via backend

### Social & Profiles (Mar 23–24)
- Message bubble sides fixed (mine right, other left)
- Search bar + pagination on Find Homies tab
- Media hero image fallback to poster/driveThumbnail

### Trickipedia (Mar 10–25)
- Backend `videos[]` array field — multiple tutorials per trick
- Frontend "Tutorials & Videos" display with platform chips
- BMX 180 and 360 thumbnail images
- Category routing fix for BMX/Inline Skating via `CATEGORY_MAP`

---

## Earlier Updates (January 2026)

### Homepage Redesign
- Updated hero text: "The platform dedicated to Action Sports"
- New feature slider showcasing Trickipedia, Spots, Homies, Media
- Conditional CTAs based on login state
- Emojis matching navigation: 📘 📍 🤝 🎬

### Media Enhancements
- **The Couch:** Admin thumbnail upload (file + URL options)
- **Feed:** Audio enabled by default for videos
- **Video Player:** Fixed double-play issue on The Couch

### Authentication Pages
- Animated input placeholders on login/signup/reset pages
- Icon and text fade out on focus
- Consistent styling across auth flows

### Infrastructure
- S3 bucket public access configured for images
- Bunny.net CDN for video streaming
- HLS adaptive bitrate support

## Architecture Overview

### Frontend Stack

| Platform | Technology | Key Libraries |
|----------|------------|---------------|
| Website | Next.js 14 | React, TailwindCSS, shadcn/ui |
| Mobile | React Native | Expo SDK 51, React Navigation |
| Extension | Chrome Extension | Manifest V3, React |

### Backend Stack

| Component | Technology |
|-----------|------------|
| API Server | Node.js + Express |
| Database | MongoDB Atlas |
| Auth | JWT + Google SSO |
| Storage | AWS S3 (images), Bunny.net (video) |
| Real-time | Socket.IO |
| Payments | Stripe |

### Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Website   │     │  Mobile App │     │  Extension  │
│  (Next.js)  │     │   (Expo)    │     │  (Chrome)   │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Backend   │
                    │  (Express)  │
                    └──────┬──────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
┌──────▼──────┐     ┌──────▼──────┐     ┌──────▼──────┐
│   MongoDB   │     │    AWS S3   │     │  Bunny.net  │
│   (Data)    │     │  (Images)   │     │  (Video)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Mobile Development Notes

When implementing these features on mobile:

### Trickipedia
- Use FlatList with pagination
- Cache trick data in AsyncStorage
- Support offline browsing of cached tricks
- Implement search with debouncing

### Spots
- Use react-native-maps for map view
- Request location permissions
- Cache spot lists for offline access
- Implement nearby spots with geolocation

### Homies
- Integrate push notifications for requests/messages
- Use Socket.IO client for real-time messaging
- Handle background message sync
- Implement typing indicators

### Media
- Use expo-av for video playback
- Support HLS streams natively
- Implement infinite scroll feed
- Handle video upload with progress

## API Base URLs

| Environment | URL |
|-------------|-----|
| Production | `https://api.thetrickbook.com/api` |
| Development | `http://localhost:5000/api` |

## Related Documentation

- [Architecture Overview](/docs/architecture/overview)
- [API Endpoints](/docs/backend/api-endpoints)
- [Mobile Development](/docs/mobile/overview)
- [Deployment](/docs/deployment/backend)
