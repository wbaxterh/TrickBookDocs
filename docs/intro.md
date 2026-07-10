---
sidebar_position: 1
slug: /
---

# TrickBook Documentation

Welcome to the TrickBook technical documentation. This site covers the architecture, development, and deployment of the TrickBook mobile app, website, backend services, and AI companions.

## What is TrickBook?

TrickBook is a platform for skateboarders and action sports enthusiasts to track trick progression, discover skate spots, connect with friends ("homies"), share media, explore curated action sports content — and ride with **AI companions** that chat, talk out loud, and demonstrate tricks as 3D characters.

## Platform Overview

| Component | Technology | Status |
|-----------|------------|--------|
| **Mobile App** | React Native + Expo SDK 54 (TypeScript) | ✅ iOS App Store (live) · 🚧 Android Google Play (closed alpha) |
| **Backend API** | Node.js + Express + MongoDB + Socket.IO | ✅ Production (EC2, `api.thetrickbook.com`) |
| **Website** | Next.js (shares backend API) | ✅ Production ([thetrickbook.com](https://thetrickbook.com)) |
| **AI / Voice Services** | Kaori: OpenRouter LLM + Kith voice sidecar (ElevenLabs TTS) on EC2 | ✅ Production |
| **Docs** | Docusaurus | ✅ [docs.thetrickbook.com](https://docs.thetrickbook.com) |
| **Chrome Extension** | Spot scraper for Google Maps | ✅ Production |

## Key Features

| Feature | Description |
|---------|-------------|
| **AI Companions** | Kaori: chat with tool actions, live-voice 3D companion stage on mobile (awaiting new build), `kaori-live` on web |
| **TrickBook** | Create and track trick lists with progress tracking |
| **Trickipedia** | Browse global trick encyclopedia with tutorials |
| **Spots** | Discover skate spots on a map, leave reviews and ratings |
| **Homies** | Connect with friends, send/accept friend requests |
| **Feed/Media** | Share videos and photos, react with love/respect |
| **The Couch** | Curated action sports video library |
| **Direct Messages** | Real-time chat with friends |
| **Notifications** | Push notifications, live in v3.1.x |
| **Subscriptions** | Freemium model with Stripe payments |

## Quick Links

### AI Companions (Current Focus)

- [AI Companions](/docs/features/ai-companions) - What Kaori is and how she works for users
- [Kaori AI Architecture](/docs/architecture/kaori) - LLM brain, tools, voice pipeline, 3D stage
- [Companions Launch Audit](/docs/roadmap/companions-launch) - How far from users, gap list
- [Priority Roadmap](/docs/roadmap/priorities) - Implementation order and current priorities

### For Developers

- [Architecture Overview](/docs/architecture/overview) - System design and components
- [Backend API](/docs/backend/overview) - API documentation and endpoints
- [Mobile App](/docs/mobile/overview) - React Native app structure
- [Features](/docs/features/overview) - Feature documentation
- [Engineering Standards](/docs/engineering/overview) - Code quality, testing, workflow

### For Deployment

- [CI/CD Pipeline](/docs/deployment/ci-cd) - Automated quality gates and deployment
- [App Store Deployment](/docs/deployment/app-store) - iOS submission process
- [Google Play Deployment](/docs/deployment/google-play) - Android submission process
- [Backend Deployment](/docs/deployment/backend) - Server deployment

### Security

- [Security Fixes](/docs/roadmap/security-fixes) - Critical security improvements
- [Backend Security](/docs/backend/security) - Current vulnerabilities and fixes

## Repository Structure

```
Documents/TrickBook/repos
├── Backend/            # Node.js Express API + Socket.IO + Kith voice sidecar
├── TrickList/          # React Native mobile app (TypeScript + Expo Router)
├── TrickBookWebsite/   # Next.js website (thetrickbook.com)
└── docs/               # This documentation site
```

## Current Versions

| Component | Version |
|-----------|---------|
| Mobile App | 3.1.x (3.2.0 next — Kaori companion release) |
| iOS Bundle | com.thetrickbook.trickbook |
| Android Package | com.thetrickbook.trickbook |
| Expo SDK | 54.0.0 |
| React Native | 0.81.5 |
| TypeScript | 5.9.2 |
| Node.js | 20.x |

## Getting Started

### Running the Mobile App

```bash
cd repos/TrickList
npm install
npx expo start --dev-client
```

### Running the Backend

```bash
cd repos/Backend
npm install
npm start
```

### Running These Docs

```bash
cd repos/docs
npm install
npm start
```
