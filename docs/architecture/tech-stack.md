---
sidebar_position: 2
---

# Technology Stack

Complete list of technologies used across the TrickBook platform.

## Mobile App (TrickList)

### Core Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| React Native | 0.81.5 | Cross-platform mobile framework |
| React | 19.x | UI library |
| Expo | 54.0.0 | Development platform and native modules |
| TypeScript | 5.9.2 | Type safety |

### Navigation

| Package | Version | Purpose |
|---------|---------|---------|
| expo-router | 6.0.22 | File-based routing (like Next.js) |
| react-native-screens | - | Native screen management |
| react-native-safe-area-context | 5.6.0 | Safe area handling |

### State Management

| Package | Version | Purpose |
|---------|---------|---------|
| zustand | 5.0.10 | Auth state management |
| @tanstack/react-query | 5.90.20 | Server state / data fetching / caching |
| jotai | 1.11.2 | Atomic state (available) |
| React Context | (built-in) | Theme provider |

### Forms & Validation

| Package | Version | Purpose |
|---------|---------|---------|
| react-hook-form | 7.71.1 | Efficient form handling |
| zod | 3.25.76 | Schema validation |
| @hookform/resolvers | 5.2.2 | Hook form + Zod integration |
| formik | 2.2.9 | Legacy form management |
| yup | 0.32.11 | Legacy schema validation |

### API & Networking

| Package | Version | Purpose |
|---------|---------|---------|
| Custom fetch client | - | HTTP client with auth token injection |
| axios | 1.13.3 | HTTP client |
| socket.io-client | 4.8.3 | Real-time communication |
| jwt-decode | 3.1.2 | JWT token parsing |

### Styling

| Package | Version | Purpose |
|---------|---------|---------|
| nativewind | 4.2.1 | Tailwind CSS for React Native |
| tailwindcss | 3.3.2 | Utility-first CSS framework |
| clsx | 2.1.1 | Conditional CSS classes |

### UI & Animation

| Package | Version | Purpose |
|---------|---------|---------|
| react-native-reanimated | 4.1.1 | Animations |
| react-native-gesture-handler | 2.28.0 | Gestures |
| react-native-maps | 1.20.1 | Map integration |
| @expo/vector-icons (Ionicons) | - | Icon library |

### Expo Modules

| Package | Version | Purpose |
|---------|---------|---------|
| expo-secure-store | 15.0.8 | Secure token storage |
| expo-file-system | 19.0.21 | File system access |
| expo-image-picker | 17.0.10 | Image selection |
| expo-image-manipulator | 14.0.8 | Image processing |
| expo-image | 3.0.11 | Optimized image component |
| expo-video | 3.0.15 | Video playback |
| expo-av | 16.0.8 | Audio/video playback |
| expo-location | 19.0.8 | GPS location access |
| expo-apple-authentication | 8.0.8 | Sign in with Apple |
| expo-auth-session | 7.0.10 | OAuth authentication flow |
| expo-crypto | 15.0.8 | Cryptographic functions |

### Build Tools

| Package | Version | Purpose |
|---------|---------|---------|
| patch-package | 8.0.0 | Dependency patching |
| metro | - | React Native bundler (via Expo) |
| babel | 7.12.9 | JavaScript transpiler |

---

## Backend API

### Runtime & Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 12.6.x | JavaScript runtime (**needs upgrade**) |
| Express.js | 4.17.1 | Web framework |
| Socket.IO | 4.8.3 | Real-time WebSocket server |

### Database

| Package | Version | Purpose |
|---------|---------|---------|
| mongodb | 4.13.0 | MongoDB driver |

### Authentication

| Package | Version | Purpose |
|---------|---------|---------|
| jsonwebtoken | 8.5.1 | JWT token generation |
| bcrypt | 6.0.0 | Password hashing |
| google-auth-library | 9.11.0 | Google SSO |
| apple-signin-auth | 2.0.0 | Apple Sign-In |

### Security

| Package | Version | Purpose |
|---------|---------|---------|
| helmet | 3.22.0 | HTTP security headers (**outdated**) |
| cors | 2.8.5 | Cross-origin requests |

### Payments

| Package | Version | Purpose |
|---------|---------|---------|
| stripe | 18.3.0 | Payment processing |

### File Upload & Media

| Package | Version | Purpose |
|---------|---------|---------|
| @aws-sdk/client-s3 | 3.252.0 | S3 uploads |
| aws-sdk | 2.1297.0 | AWS services (legacy) |
| multer | 1.4.2 | File upload middleware |
| multer-s3-v2 | - | S3 upload integration |
| sharp | 0.25.4 | Image processing |

### Video Streaming

| Package | Version | Purpose |
|---------|---------|---------|
| bunny.net API | - | Video CDN and streaming |
| Signed URLs | - | Protected video delivery |

### External Services

| Package | Version | Purpose |
|---------|---------|---------|
| googleapis | 170.1.0 | Google Drive ("The Couch") |
| Google Places API | - | Spot location search |

### Push Notifications

| Package | Version | Purpose |
|---------|---------|---------|
| expo-server-sdk | 3.5.0 | Expo push notifications |

### Email

| Package | Version | Purpose |
|---------|---------|---------|
| nodemailer | 6.9.15 | Email sending (via Gmail) |

### Validation & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| joi | 14.3.1 | Input validation (**outdated**) |
| dotenv | 16.0.3 | Environment variables |
| config | 3.3.1 | Configuration management |
| compression | 1.7.4 | Response compression |
| body-parser | 1.20.1 | Request parsing |
| axios | 1.13.4 | HTTP client |
| uuid | 13.0.0 | Unique ID generation |

---

## Infrastructure

### Cloud Services

| Service | Provider | Purpose |
|---------|----------|---------|
| Database | MongoDB Atlas | Data storage |
| File Storage | AWS S3 | Image uploads |
| Video CDN | Bunny.net | Video streaming and delivery |
| Payments | Stripe | Subscriptions |
| Places API | Google | Spot location search |

### Build & Deployment

| Service | Purpose |
|---------|---------|
| EAS Build | Mobile app builds |
| EAS Submit | App store submissions |
| App Store Connect | iOS distribution |
| Google Play Console | Android distribution |

---

## Outdated Dependencies (Action Required)

| Package | Current | Latest | Priority |
|---------|---------|--------|----------|
| Node.js (Backend) | 12.6.x | 22.x | **CRITICAL** |
| helmet | 3.22.0 | 7.x | HIGH |
| joi | 14.3.1 | 17.x | MEDIUM |
| jsonwebtoken | 8.5.1 | 9.x | MEDIUM |
| sharp | 0.25.4 | 0.33.x | MEDIUM |
| aws-sdk | v2 | v3 | LOW |
