---
sidebar_position: 1
slug: /
---

# TrickBook Documentation

Welcome to the TrickBook technical documentation. This site covers the architecture, development, and deployment of the TrickBook mobile application and backend services.

## What is TrickBook?

TrickBook is a mobile application for skateboarders (and other action sports enthusiasts) to track their trick progression, manage trick lists, discover new tricks, and find skate spots.

## Platform Overview

| Component | Technology | Status |
|-----------|------------|--------|
| **Mobile App** | React Native + Expo SDK 51 | Production (iOS) |
| **Backend API** | Node.js + Express + MongoDB | Production |
| **Website** | Shares backend API | Production |
| **iOS** | App Store | Live |
| **Android** | Google Play | Pending |

## Quick Links

### For Developers

- [Architecture Overview](/docs/architecture/overview) - System design and components
- [Backend API](/docs/backend/overview) - API documentation and endpoints
- [Mobile App](/docs/mobile/overview) - React Native app structure

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
├── Backend/          # Node.js Express API
├── TrickList/        # React Native mobile app
└── docs/             # This documentation site
```

## Current Versions

| Component | Version |
|-----------|---------|
| Mobile App | 1.0.8 |
| iOS Bundle | com.thetrickbook.trickbook |
| Android Package | com.thetrickbook.trickbook |
| Expo SDK | 51.0.0 |
| React Native | 0.74.5 |
| Node.js (Backend) | 12.6.x (needs upgrade) |

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
