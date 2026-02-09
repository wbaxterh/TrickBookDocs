---
sidebar_position: 1
slug: /
---

# TrickBook Documentation

Welcome to the TrickBook technical documentation. This site covers the architecture, development, and deployment of the TrickBook mobile application and backend services.

## What is TrickBook?

TrickBook is a mobile platform for skateboarders and action sports enthusiasts to track trick progression, discover skate spots, connect with friends ("homies"), share media, and explore curated action sports content.

## Platform Overview

| Component | Technology | Status |
|-----------|------------|--------|
| **Mobile App** | React Native + Expo SDK 54 (TypeScript) | Production (iOS) |
| **Backend API** | Node.js + Express + MongoDB + Socket.IO | Production |
| **Website** | Next.js (shares backend API) | Production |
| **Chrome Extension** | Spot scraper for Google Maps | Production |
| **iOS** | App Store | Live |
| **Android** | Google Play | Pending |

## Quick Links

### For Developers

- [Architecture Overview](/docs/architecture/overview) - System design and components
- [Backend API](/docs/backend/overview) - API documentation and endpoints
- [Mobile App](/docs/mobile/overview) - React Native app structure
- [Features](/docs/features/overview) - Feature documentation

### For Deployment

- [App Store Deployment](/docs/deployment/app-store) - iOS submission process
- [Google Play Deployment](/docs/deployment/google-play) - Android submission process
- [Backend Deployment](/docs/deployment/backend) - Server deployment

### Current Priorities

- [Priority Roadmap](/docs/roadmap/priorities) - What needs to be done
- [Security Fixes](/docs/roadmap/security-fixes) - Critical security improvements

## Repository Structure

```
/Reactnative
├── Backend/          # Node.js Express API + Socket.IO
├── TrickList/        # React Native mobile app (TypeScript + Expo Router)
└── docs/             # This documentation site
```

## Current Versions

| Component | Version |
|-----------|---------|
| Mobile App | 2.0.0 |
| iOS Bundle | com.thetrickbook.trickbook |
| Android Package | com.thetrickbook.trickbook |
| Expo SDK | 54.0.0 |
| React Native | 0.81.5 |
| TypeScript | 5.9.2 |
| Node.js (Mobile) | 20.18.0 |
| Node.js (Backend) | 12.6.x (needs upgrade) |

## Key Features

| Feature | Description |
|---------|-------------|
| **TrickBook** | Create and track trick lists with progress tracking |
| **Trickipedia** | Browse global trick encyclopedia with tutorials |
| **Spots** | Discover skate spots on a map, leave reviews and ratings |
| **Homies** | Connect with friends, send/accept friend requests |
| **Feed/Media** | Share videos and photos, react with love/respect |
| **The Couch** | Curated action sports video library |
| **Direct Messages** | Real-time chat with friends |
| **Subscriptions** | Freemium model with Stripe payments |

## Getting Started

### Running the Mobile App

```bash
cd TrickList
npm install
npx expo start --dev-client
```

### Running the Backend

```bash
cd Backend
npm install
npm start
```

### Running These Docs

```bash
cd docs
npm install
npm start
```
