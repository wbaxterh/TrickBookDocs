---
sidebar_position: 1
---

# Mobile App Overview

The TrickBook mobile app is built with React Native, Expo SDK 54, and TypeScript. It uses Expo Router for file-based navigation and NativeWind for Tailwind CSS styling.

## Quick Start

```bash
cd TrickList
npm install
npx expo start --dev-client
```

## Project Structure

```
TrickList/
├── app/                           # Expo Router app directory
│   ├── _layout.tsx                # Root layout (providers, auth gate)
│   ├── notifications.tsx          # Notifications screen
│   │
│   ├── (auth)/                    # Auth group (unauthenticated users)
│   │   ├── _layout.tsx            # Auth navigation layout
│   │   ├── welcome.tsx            # Landing/intro screen
│   │   ├── login.tsx              # Email/password + SSO login
│   │   └── register.tsx           # New user registration
│   │
│   ├── (tabs)/                    # Main tab navigation
│   │   ├── _layout.tsx            # Tab bar configuration
│   │   ├── index.tsx              # Home/Dashboard
│   │   ├── trickbook/             # TrickBook screens
│   │   ├── spots/                 # Spots screens
│   │   ├── homies/                # Homies screens
│   │   ├── media/                 # Feed/Media screens
│   │   └── profile/               # Profile (hidden from tab bar)
│   │
│   ├── profile/                   # Profile settings screens
│   │   ├── index.tsx              # Profile view
│   │   ├── edit.tsx               # Edit profile
│   │   ├── settings.tsx           # App settings
│   │   ├── account.tsx            # Account management
│   │   ├── change-password.tsx    # Password update
│   │   ├── notifications.tsx      # Notification preferences
│   │   ├── privacy.tsx            # Privacy settings
│   │   ├── theme.tsx              # Theme selection
│   │   └── support.tsx            # Help/support
│   │
│   ├── api/                       # Legacy API layer (migration in progress)
│   ├── auth/                      # Legacy auth context
│   ├── config/                    # Styling configuration
│   └── assets/                    # Images, icons, splash screen
│
├── src/                           # New TypeScript source structure
│   ├── components/                # Reusable UI components
│   │   ├── ui/                    # Base: Button, Card, Avatar, Badge, ProgressBar
│   │   ├── home/                  # GoalCard, StatsCard, QuickActions, ActivityCard
│   │   ├── trickbook/             # TrickCard, TrickRow, TrickListCard, StatusBadge
│   │   ├── spots/                 # SpotMap, SpotCard, ReviewCard, StarRatingInput
│   │   ├── feed/                  # CommentsBottomSheet
│   │   ├── homies/                # Homie components
│   │   ├── media/                 # Media components
│   │   ├── layout/                # Layout wrappers
│   │   └── share/                 # ShareToHomieModal
│   │
│   ├── lib/                       # Business logic and utilities
│   │   ├── api/                   # API service layer
│   │   │   ├── client.ts          # HTTP client (auth token handling)
│   │   │   ├── auth.ts            # Authentication endpoints
│   │   │   ├── trickbook.ts       # TrickBook CRUD operations
│   │   │   ├── feed.ts            # Feed/social content API
│   │   │   ├── homies.ts          # Friends/homies API
│   │   │   ├── spots.ts           # Spots/locations API
│   │   │   ├── spotReviews.ts     # Spot reviews API
│   │   │   ├── spotlists.ts       # Spot lists API
│   │   │   ├── messages.ts        # Direct messaging API
│   │   │   ├── couch.ts           # "The Couch" curated media API
│   │   │   ├── user.ts            # User profile API
│   │   │   └── upload.ts          # File upload API
│   │   │
│   │   ├── stores/                # Zustand state management
│   │   │   └── authStore.ts       # Authentication state
│   │   │
│   │   ├── hooks/                 # Custom React hooks
│   │   ├── providers/             # Context providers
│   │   │   └── ThemeProvider.tsx   # Dark/Light theme provider
│   │   └── utils.ts               # Utility functions
│   │
│   ├── types/                     # TypeScript type definitions
│   │   ├── trickbook.ts           # TrickList, Trick, TrickStatus types
│   │   └── spots.ts               # Spot, SpotList types
│   │
│   ├── constants/                 # App constants
│   │   ├── api.ts                 # API endpoints and configuration
│   │   ├── colors.ts              # Color system and theme
│   │   └── layout.ts              # Layout constants
│   │
│   └── assets/                    # Images and static assets
│
├── android/                       # Android native configuration
├── ios/                           # iOS native configuration
├── patches/                       # Patch-package patches
├── plugins/                       # Expo plugins
│
├── package.json                   # Dependencies and scripts
├── app.json                       # Expo configuration
├── tsconfig.json                  # TypeScript configuration
├── tailwind.config.js             # Tailwind CSS configuration
├── metro.config.js                # Metro bundler (with NativeWind)
├── babel.config.js                # Babel transpiler
├── eas.json                       # EAS build profiles
└── index.js                       # Entry point
```

## Key Features

### TrickBook
- Create and manage personal trick lists
- Track progress: "Not Started" → "Learning" → "Landed" → "Mastered"
- Browse Trickipedia (global trick encyclopedia with tutorials)
- Public/private trick list sharing

### Spots
- Discover skate spots on a map
- Find spots near current location (GPS)
- Leave reviews and star ratings
- Organize spots into collections (spot lists)
- Google Places integration for search

### Homies
- Find and connect with friends
- Send/accept homie requests
- View friends' profiles, stats, and trick lists
- Toggle discoverable network status

### Feed/Media
- Upload videos and photos
- React with "Love" and "Respect"
- Comments and threaded replies
- Trending/algorithmic feed
- Filter by sport type
- Post visibility: public, homies-only, private

### The Couch
- Curated action sports video library
- Browse films, documentaries, and edits
- Stream via Bunny.net CDN

### Direct Messages
- Real-time chat with homies (Socket.IO)
- Share tricks, spots, and videos in messages
- Read receipts and unread counts

### User Features
- Customizable profiles with avatar and stats
- Multi-auth: Email/password, Apple Sign-In, Google SSO
- Dark/Light theme toggle
- Notification preferences and privacy settings
- Stripe subscription management

## Design System

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary (Gold) | `#FCF150` | Brand color, mastered status |
| Secondary (Dark) | `#1f1f1f` | Secondary brand |
| Accent (Blue) | `#1976D2` | Links, actions |
| Not Started | `#666666` | Gray status |
| Learning | `#FF9800` | Orange status |
| Landed | `#4CAF50` | Green status |

### Themes

| Theme | Background | Surface |
|-------|------------|---------|
| Dark | `#121212` | `#1E1E1E` |
| Light | `#FFFFFF` | `#F5F5F5` |

## Dependencies Overview

### Core
- React Native 0.81.5
- Expo SDK 54.0.0
- TypeScript 5.9.2

### Navigation
- Expo Router 6.x (file-based)

### State & Data
- Zustand 5.x (auth state)
- React Query 5.x (server state)
- React Hook Form 7.x + Zod (forms)

### Styling
- NativeWind 4.x (Tailwind CSS)

### Real-time
- Socket.IO Client 4.8.3

### Node.js
- 20.18.0 (via .nvmrc)

## Build Profiles

| Profile | Purpose |
|---------|---------|
| `development` | Local dev builds with dev-client |
| `preview` | Internal testing distribution |
| `production` | Generic production build |
| `testflight` | iOS App Store submission |
| `playstore` | Google Play submission |
