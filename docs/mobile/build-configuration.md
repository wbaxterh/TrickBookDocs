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
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.0"
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.0"
      }
    },
    "production": {
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.0"
      },
      "android": {
        "buildType": "app-bundle"
      }
    },
    "testflight": {
      "distribution": "store",
      "ios": {
        "resourceClass": "m-medium",
        "image": "macos-sonoma-14.6-xcode-16.0",
        "autoIncrement": true
      },
      "env": {
        "EXPO_NO_DOTENV": "1",
        "NODE_ENV": "production"
      }
    },
    "playstore": {
      "distribution": "store",
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
    "production": {}
  }
}
```

### Build Profiles

| Profile | Platform | Distribution | Use Case |
|---------|----------|--------------|----------|
| `development` | iOS/Android | Internal | Local dev with dev-client |
| `preview` | iOS/Android | Internal | QA testing |
| `production` | iOS/Android | N/A | Generic production build |
| `testflight` | iOS | Store | App Store submission |
| `playstore` | Android | Store | Google Play submission |

## App Configuration

### app.json

```json
{
  "expo": {
    "name": "TrickBook",
    "slug": "TrickBook",
    "version": "1.0.8",
    "privacy": "public",
    "orientation": "portrait",
    "icon": "./app/assets/icon.png",
    "splash": {
      "image": "./app/assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "updates": {
      "fallbackToCacheTimeout": 0
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.thetrickbook.trickbook",
      "infoPlist": {
        "NSCameraUsageDescription": "This app uses the camera to access photos for a profile image.",
        "ITSAppUsesNonExemptEncryption": false
      }
    },
    "android": {
      "package": "com.thetrickbook.trickbook",
      "versionCode": 4,
      "adaptiveIcon": {
        "foregroundImage": "./app/assets/adaptive-icon.png",
        "backgroundColor": "#FFFFFF"
      }
    },
    "plugins": [
      "./plugins/fix-cpp-build-error"
    ]
  }
}
```

### Key Configuration Options

| Field | Value | Purpose |
|-------|-------|---------|
| `name` | TrickBook | Display name |
| `slug` | TrickBook | URL-safe identifier |
| `version` | 1.0.8 | Semantic version |
| `bundleIdentifier` | com.thetrickbook.trickbook | iOS app ID |
| `package` | com.thetrickbook.trickbook | Android app ID |
| `versionCode` | 4 | Android build number |

## Native Plugins

### Custom C++ Build Fix

Fixes gesture handler build issues:

```javascript
// plugins/fix-cpp-build-error.js
const { withGradleProperties } = require('@expo/config-plugins');

module.exports = function withFixCppBuildError(config) {
  return withGradleProperties(config, (config) => {
    config.modResults.push({
      type: 'property',
      key: 'android.enableJetifier',
      value: 'true'
    });
    return config;
  });
};
```

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
# Submit latest Android build
eas submit --platform android --latest
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
eas build:version:set --platform android --version-code 5
```

## Environment Variables

For production builds, sensitive values come from EAS secrets:

```bash
# Set EAS secrets
eas secret:create --name API_URL --value "https://api.thetrickbook.com"
eas secret:create --name SENTRY_DSN --value "https://xxx@sentry.io/xxx"
```

Access in app:

```javascript
const apiUrl = process.env.API_URL || 'https://api.thetrickbook.com/api';
```

## Android Signing

EAS manages signing automatically. For manual setup:

```bash
# Generate new keystore
eas credentials --platform android

# View current credentials
eas credentials --platform android
```

## iOS Signing

EAS handles certificates and provisioning profiles:

```bash
# Configure iOS credentials
eas credentials --platform ios

# Use Apple Developer Portal credentials
eas credentials --platform ios
```

## Build Validation Script

Pre-build validation for Android:

```bash
#!/bin/bash
# validate-android-build.sh

echo "Validating Android build configuration..."

# Check gradle.properties
if ! grep -q "android.enableJetifier=true" android/gradle.properties 2>/dev/null; then
  echo "Warning: android.enableJetifier not set"
fi

# Check build.gradle
if ! grep -q "com.thetrickbook.trickbook" android/app/build.gradle 2>/dev/null; then
  echo "Warning: Package name mismatch in build.gradle"
fi

# Check for AAB format
if ! grep -q "app-bundle" eas.json; then
  echo "Warning: Android not configured for App Bundle"
fi

echo "Validation complete"
```

## OTA Updates

Over-the-air updates enabled via expo-updates:

```javascript
// Updates configuration in app.json
"updates": {
  "fallbackToCacheTimeout": 0
}
```

```bash
# Publish OTA update
eas update --branch production --message "Bug fix"
```

## Build Monitoring

Track builds in EAS dashboard:
- https://expo.dev/accounts/[username]/projects/TrickBook/builds

Or via CLI:
```bash
# List recent builds
eas build:list

# View build details
eas build:view BUILD_ID
```
