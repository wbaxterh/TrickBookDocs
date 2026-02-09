---
sidebar_position: 5
---

# Build Configuration

TrickBook uses EAS (Expo Application Services) for building and deploying native apps.

## EAS Configuration

### eas.json

```json
{
  "cli": {
    "version": ">= 3.7.2",
    "appVersionSource": "remote"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "node": "20.18.0",
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.1"
      }
    },
    "preview": {
      "distribution": "internal",
      "node": "20.18.0",
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.1"
      }
    },
    "production": {
      "node": "20.18.0",
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.1"
      },
      "android": {
        "buildType": "app-bundle"
      }
    },
    "testflight": {
      "distribution": "store",
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.1",
        "autoIncrement": true
      },
      "node": "20.18.0",
      "env": {
        "EXPO_NO_DOTENV": "1"
      }
    },
    "playstore": {
      "distribution": "store",
      "node": "20.18.0",
      "android": {
        "buildType": "app-bundle",
        "image": "latest",
        "autoIncrement": true
      },
      "env": {
        "EXPO_NO_DOTENV": "1",
        "NODE_ENV": "production"
      }
    }
  },
  "submit": {
    "production": {},
    "playstore": {
      "android": {
        "track": "internal",
        "releaseStatus": "draft"
      }
    }
  }
}
```

### Build Profiles

| Profile | Platform | Distribution | Node.js | Use Case |
|---------|----------|--------------|---------|----------|
| `development` | iOS/Android | Internal | 20.18.0 | Local dev with dev-client |
| `preview` | iOS/Android | Internal | 20.18.0 | QA testing |
| `production` | iOS/Android | N/A | 20.18.0 | Generic production build |
| `testflight` | iOS | Store | 20.18.0 | App Store submission |
| `playstore` | Android | Store | 20.18.0 | Google Play submission |

## App Configuration

### app.json

```json
{
  "expo": {
    "name": "TrickBook",
    "slug": "TrickBook",
    "version": "2.0.0",
    "privacy": "public",
    "orientation": "portrait",
    "scheme": "trickbook",
    "userInterfaceStyle": "automatic",
    "icon": "./assets/images/icon.png",
    "splash": {
      "image": "./assets/images/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#121212"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.thetrickbook.trickbook",
      "buildNumber": "5",
      "config": {
        "googleMapsApiKey": "..."
      },
      "infoPlist": {
        "NSCameraUsageDescription": "TrickBook uses the camera to take photos...",
        "NSPhotoLibraryUsageDescription": "TrickBook needs access to your photos...",
        "NSLocationWhenInUseUsageDescription": "TrickBook uses your location to find nearby spots.",
        "ITSAppUsesNonExemptEncryption": false
      }
    },
    "android": {
      "package": "com.thetrickbook.trickbook",
      "versionCode": 5,
      "adaptiveIcon": {
        "foregroundImage": "./assets/images/adaptive-icon.png",
        "backgroundColor": "#121212"
      },
      "config": {
        "googleMaps": { "apiKey": "..." }
      },
      "permissions": [
        "ACCESS_COARSE_LOCATION",
        "ACCESS_FINE_LOCATION"
      ]
    },
    "plugins": [
      "expo-secure-store",
      "expo-router",
      "expo-video",
      "expo-apple-authentication",
      ["expo-location", { "locationWhenInUsePermission": "..." }]
    ],
    "experiments": {
      "typedRoutes": true
    }
  }
}
```

### Key Configuration Options

| Field | Value | Purpose |
|-------|-------|---------|
| `name` | TrickBook | Display name |
| `slug` | TrickBook | URL-safe identifier |
| `version` | 2.0.0 | Semantic version |
| `scheme` | trickbook | Deep link scheme |
| `bundleIdentifier` | com.thetrickbook.trickbook | iOS app ID |
| `package` | com.thetrickbook.trickbook | Android app ID |
| `buildNumber` | 5 | iOS build number |
| `versionCode` | 5 | Android build number |
| `userInterfaceStyle` | automatic | Supports dark/light mode |

### Expo Plugins

| Plugin | Purpose |
|--------|---------|
| `expo-secure-store` | Secure token storage |
| `expo-router` | File-based navigation |
| `expo-video` | Video playback |
| `expo-apple-authentication` | Apple Sign-In |
| `expo-location` | GPS location access |

### Typed Routes

With `experiments.typedRoutes: true`, Expo Router generates TypeScript types for all route paths, providing compile-time safety for navigation.

## Build Commands

### Development Build

```bash
# iOS development build
eas build --platform ios --profile development

# Android development build
eas build --platform android --profile development
```

### Preview Build

```bash
# Internal distribution for testing
eas build --platform all --profile preview
```

### Production Builds

```bash
# iOS for TestFlight
eas build --platform ios --profile testflight

# Android for Google Play
eas build --platform android --profile playstore

# Both platforms
eas build --platform all --profile production
```

## Submission

### iOS (TestFlight/App Store)

```bash
# Submit latest iOS build
eas submit --platform ios --latest

# Or specify a build
eas submit --platform ios --id BUILD_ID
```

### Android (Google Play)

```bash
# Submit latest Android build (internal track, draft)
eas submit --platform android --latest --profile playstore
```

## Version Management

With `appVersionSource: "remote"` in eas.json:

- Version is managed in EAS dashboard
- `autoIncrement: true` bumps version on each build
- No need to manually update app.json version

### Manual Version Bump

```bash
# Set app version
eas build:version:set --platform ios --build-number 10
eas build:version:set --platform android --version-code 6
```

## Environment Variables

For production builds, sensitive values come from EAS secrets:

```bash
# Set EAS secrets
eas secret:create --name API_URL --value "https://api.thetrickbook.com"
```

The `EXPO_NO_DOTENV: "1"` flag in testflight/playstore profiles prevents loading local `.env` files during builds.

## Build Monitoring

Track builds in EAS dashboard or via CLI:

```bash
# List recent builds
eas build:list

# View build details
eas build:view BUILD_ID
```

## iOS Build Environment

| Setting | Value |
|---------|-------|
| macOS | Sonoma 14.6 |
| Xcode | 16.1 |
| Resource Class | m-medium |
| Node.js | 20.18.0 |
