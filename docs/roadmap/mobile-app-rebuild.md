---
sidebar_position: 5
title: Mobile App Rebuild Plan
description: Complete plan for rebuilding the TrickBook mobile app with new design
---

# TrickBook Mobile App Rebuild Plan

**Document Type:** Technical Implementation Plan
**Date:** January 2026
**Current Version:** 1.0.8
**Target Version:** 2.0.0

---

## Executive Summary

Rebuild the TrickBook mobile app to match the new NanoBananaPro design while preserving App Store and Play Store listings. The new app will include all features from the web platform: TrickBook (trick progression), Spots (location discovery), Homies (social), and Media (video content).

---

## Package Identifiers (PRESERVE THESE)

```json
{
  "ios": {
    "bundleIdentifier": "com.thetrickbook.trickbook",
    "buildNumber": "5"
  },
  "android": {
    "package": "com.thetrickbook.trickbook",
    "versionCode": 5
  },
  "eas": {
    "projectId": "5fbfc8fe-e3e5-4663-b3af-2a6f903a974f"
  },
  "version": "2.0.0"
}
```

---

## Tech Stack

| Layer | Technology | Reason |
|-------|------------|--------|
| Framework | Expo SDK 52+ | Latest features, EAS builds |
| Navigation | Expo Router | File-based routing, simpler than React Navigation |
| State | Zustand | Lightweight, simple, TypeScript-friendly |
| API | Axios + React Query | Caching, background refresh |
| Real-time | Socket.IO Client | Match backend WebSocket |
| Forms | React Hook Form + Zod | Better performance than Formik |
| Styling | NativeWind (Tailwind) | Consistent with web, faster development |
| Maps | react-native-maps | Spots feature |
| Video | expo-av | Couch + Feed video playback |
| Images | expo-image | Better performance than Image |

---

## Project Structure

```
TrickList/
├── app/                          # Expo Router screens
│   ├── (auth)/                   # Auth group (unauthenticated)
│   │   ├── _layout.tsx
│   │   ├── welcome.tsx
│   │   ├── login.tsx
│   │   └── register.tsx
│   │
│   ├── (tabs)/                   # Main tab group (authenticated)
│   │   ├── _layout.tsx           # Tab bar configuration
│   │   ├── index.tsx             # Home (dashboard)
│   │   ├── trickbook/
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx         # Trickipedia + My Lists toggle
│   │   │   ├── [trickId].tsx     # Trick detail
│   │   │   └── list/
│   │   │       └── [listId].tsx  # TrickList detail
│   │   ├── spots/
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx         # Map + List view
│   │   │   ├── [spotId].tsx      # Spot detail
│   │   │   └── add.tsx           # Add spot
│   │   ├── homies/
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx         # My Homies + Find
│   │   │   ├── [userId].tsx      # User profile
│   │   │   └── chat/
│   │   │       └── [conversationId].tsx
│   │   └── media/
│   │       ├── _layout.tsx
│   │       ├── index.tsx         # Couch + Feed toggle
│   │       ├── couch/
│   │       │   └── [videoId].tsx
│   │       └── feed/
│   │           ├── index.tsx     # Feed scroll
│   │           └── upload.tsx
│   │
│   ├── profile/
│   │   ├── index.tsx             # My profile
│   │   ├── edit.tsx              # Edit profile
│   │   └── settings.tsx          # Settings
│   │
│   ├── notifications.tsx
│   ├── _layout.tsx               # Root layout
│   └── +not-found.tsx
│
├── components/
│   ├── ui/                       # Base UI components
│   ├── trickbook/                # Trick components
│   ├── spots/                    # Spot components
│   ├── homies/                   # Social components
│   ├── media/                    # Video components
│   ├── home/                     # Dashboard components
│   └── layout/                   # Layout components
│
├── lib/
│   ├── api/                      # API clients
│   ├── stores/                   # Zustand stores
│   ├── hooks/                    # Custom hooks
│   └── socket.ts                 # Socket.IO client
│
├── constants/
│   ├── colors.ts                 # Theme colors
│   └── layout.ts                 # Dimensions
│
└── assets/                       # Images, icons, fonts
```

---

## Color System

### Theme Tokens

```typescript
// constants/colors.ts

export const colors = {
  // Brand
  primary: '#FFD700',        // TrickBook Gold
  primaryDark: '#E6C200',    // Pressed state
  secondary: '#1976D2',      // Blue accent

  // Semantic
  success: '#4CAF50',
  error: '#F44336',
  warning: '#FF9800',
  info: '#2196F3',
  premium: '#1DA1F2',        // Verified badge

  // Dark theme
  dark: {
    background: '#121212',
    surface: '#1E1E1E',
    surfaceElevated: '#2C2C2C',
    text: '#FFFFFF',
    textSecondary: '#A0A0A0',
    border: '#333333',
  },

  // Light theme
  light: {
    background: '#FFFFFF',
    surface: '#F5F5F5',
    surfaceElevated: '#EEEEEE',
    text: '#1A1A1A',
    textSecondary: '#666666',
    border: '#E0E0E0',
  },

  // Status badges
  status: {
    notStarted: '#666666',
    learning: '#FF9800',
    landed: '#4CAF50',
    mastered: '#FFD700',
  }
};
```

---

## Screen Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Initialize Expo Router project
- [ ] Configure NativeWind
- [ ] Set up Zustand stores
- [ ] Set up React Query
- [ ] Create base UI components
- [ ] Implement theme system (light/dark)
- [ ] Configure API client

### Phase 2: Authentication
- [ ] Welcome screen
- [ ] Login screen
- [ ] Register screen
- [ ] Auth flow with secure storage
- [ ] Google Sign-In

### Phase 3: Home Tab
- [ ] Home dashboard layout
- [ ] Current Goals section
- [ ] Progress Stats section
- [ ] Quick Actions grid
- [ ] Homie Activity feed
- [ ] Notifications screen
- [ ] Settings screen

### Phase 4: TrickBook Tab
- [ ] Trickipedia browser
- [ ] Trick detail screen
- [ ] My TrickLists screen
- [ ] TrickList detail screen
- [ ] Add trick to list
- [ ] Update trick status
- [ ] Homie TrickLists view

### Phase 5: Spots Tab
- [ ] Spots map view
- [ ] Spots list view
- [ ] Spot detail screen
- [ ] My Spot Lists
- [ ] SpotList detail
- [ ] Add spot form
- [ ] Category/tag filtering

### Phase 6: Homies Tab
- [ ] My Homies list
- [ ] Find Riders search
- [ ] Pending requests
- [ ] User profile view
- [ ] Messages list
- [ ] Chat screen (WebSocket)
- [ ] Share spot/trick in chat

### Phase 7: Media Tab
- [ ] The Couch (video library)
- [ ] Video player screen
- [ ] Collection detail
- [ ] The Feed (vertical scroll)
- [ ] Feed post detail
- [ ] Comments bottom sheet
- [ ] Upload content flow

### Phase 8: Profile & Polish
- [ ] My profile screen
- [ ] Edit profile screen
- [ ] Full settings screen
- [ ] Subscription/billing
- [ ] Push notifications
- [ ] Loading states
- [ ] Error states
- [ ] Empty states
- [ ] Animations

---

## Migration Strategy

### Step 1: Create New Branch
```bash
cd /Users/weshuber/Reactnative/TrickList
git checkout -b v2-rebuild
```

### Step 2: Backup & Reset
```bash
# Backup important files
cp app.json app.json.backup
cp eas.json eas.json.backup

# Clear app directory (keep assets)
mv app/assets ./assets-backup
rm -rf app/*
```

### Step 3: Initialize New Structure
```bash
# Install new dependencies
npx expo install expo-router react-native-safe-area-context react-native-screens

# Install additional packages
npm install zustand @tanstack/react-query axios nativewind tailwindcss
npm install react-native-maps expo-av socket.io-client
npm install react-hook-form zod @hookform/resolvers
```

### Step 4: Restore Config
- Copy bundle IDs from backup to new app.json
- Keep EAS project ID
- Increment version to 2.0.0

### Step 5: Build & Test
```bash
# Development
npx expo start

# Preview build
eas build --profile preview --platform ios
eas build --profile preview --platform android

# Production
eas build --profile production --platform all
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| App Store rejection | Keep same bundle ID, increment version properly |
| Data loss | Backend unchanged, user data preserved |
| User confusion | Add "What's New" screen on first launch |
| Build failures | Test preview builds before production |
