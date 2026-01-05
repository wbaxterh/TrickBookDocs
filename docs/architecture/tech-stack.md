---
sidebar_position: 2
---

# Technology Stack

Complete list of technologies used across the TrickBook platform.

## Mobile App (TrickList)

### Core Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| React Native | 0.74.5 | Cross-platform mobile framework |
| React | 18.2.0 | UI library |
| Expo | 51.0.0 | Development platform and native modules |

### Navigation

| Package | Version | Purpose |
|---------|---------|---------|
| @react-navigation/native | 6.1.1 | Navigation container |
| @react-navigation/bottom-tabs | 6.5.2 | Bottom tab navigation |
| @react-navigation/native-stack | 6.9.6 | Stack navigation |

### State Management

| Package | Version | Purpose |
|---------|---------|---------|
| React Context | (built-in) | Global auth state |
| Jotai | 1.11.2 | Atomic state management |
| @react-native-async-storage/async-storage | 1.23.0 | Local data persistence |

### Forms & Validation

| Package | Version | Purpose |
|---------|---------|---------|
| Formik | 2.2.9 | Form state management |
| Yup | 0.32.11 | Schema validation |

### API & Networking

| Package | Version | Purpose |
|---------|---------|---------|
| apisauce | 1.1.1 | HTTP client (axios wrapper) |
| jwt-decode | 3.1.2 | JWT token parsing |
| form-data | 4.0.4 | Multipart form uploads |

### UI & Animation

| Package | Version | Purpose |
|---------|---------|---------|
| react-native-reanimated | 3.10.0 | Animations |
| react-native-gesture-handler | 2.16.0 | Gestures |
| react-native-screens | 3.31.0 | Native screens |
| react-beautiful-dnd | 13.1.1 | Drag and drop |
| @expo/vector-icons | - | Icon library |

### Expo Modules

| Package | Version | Purpose |
|---------|---------|---------|
| expo-splash-screen | 0.27.0 | Splash screen management |
| expo-status-bar | 1.12.0 | Status bar styling |
| expo-secure-store | 13.0.0 | Secure token storage |
| expo-file-system | 17.0.0 | File system access |
| expo-image-picker | 15.1.0 | Image selection |
| expo-image-manipulator | 12.0.0 | Image processing |
| expo-dev-client | 4.0.0 | Development builds |
| expo-updates | 0.25.0 | OTA updates |

### Build Tools

| Package | Version | Purpose |
|---------|---------|---------|
| @expo/config-plugins | 8.0.0 | Native configuration |
| patch-package | 8.0.0 | Dependency patching |

---

## Backend API

### Runtime & Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 12.6.x | JavaScript runtime (**needs upgrade**) |
| Express.js | 4.17.1 | Web framework |

### Database

| Package | Version | Purpose |
|---------|---------|---------|
| mongodb | 4.13.0 | MongoDB driver |
| mongoose | 8.15.1 | ODM (currently unused) |

### Authentication

| Package | Version | Purpose |
|---------|---------|---------|
| jsonwebtoken | 8.5.1 | JWT token generation |
| bcrypt | 6.0.0 | Password hashing |
| google-auth-library | 9.11.0 | Google SSO |

### Security

| Package | Version | Purpose |
|---------|---------|---------|
| helmet | 3.22.0 | HTTP security headers (**outdated**) |
| cors | 2.8.5 | Cross-origin requests |

### Payments

| Package | Version | Purpose |
|---------|---------|---------|
| stripe | 18.3.0 | Payment processing |

### File Upload

| Package | Version | Purpose |
|---------|---------|---------|
| aws-sdk | 2.1297.0 | AWS services |
| @aws-sdk/client-s3 | 3.252.0 | S3 uploads |
| multer | 1.4.2 | File upload middleware |
| multer-s3 | 2.10.0 | S3 upload integration |
| sharp | 0.25.4 | Image processing |

### Push Notifications

| Package | Version | Purpose |
|---------|---------|---------|
| expo-server-sdk | 3.5.0 | Expo push notifications |

### Validation & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| joi | 14.3.1 | Input validation (**outdated**) |
| dotenv | 16.0.3 | Environment variables |
| config | 3.3.1 | Configuration management |
| compression | 1.7.4 | Response compression |
| body-parser | 1.20.1 | Request parsing |
| nodemailer | 6.9.15 | Email sending |

---

## Infrastructure

### Cloud Services

| Service | Provider | Purpose |
|---------|----------|---------|
| Database | MongoDB Atlas | Data storage |
| File Storage | AWS S3 | Image uploads |
| Payments | Stripe | Subscriptions |

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
| Node.js | 12.6.x | 22.x | **CRITICAL** |
| helmet | 3.22.0 | 7.x | HIGH |
| joi | 14.3.1 | 17.x | MEDIUM |
| jsonwebtoken | 8.5.1 | 9.x | MEDIUM |
| sharp | 0.25.4 | 0.33.x | MEDIUM |
| aws-sdk | v2 | v3 | LOW |
