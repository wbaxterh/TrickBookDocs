---
sidebar_position: 1
---

# Mobile App Overview

The TrickBook mobile app is built with React Native and Expo, targeting both iOS and Android from a single codebase.

## Quick Start

```bash
cd TrickList
npm install
npx expo start --dev-client
```

## Project Structure

```
TrickList/
├── app/
│   ├── api/                    # API service layer
│   │   ├── client.js          # API client (apisauce)
│   │   ├── auth.js            # Auth endpoints
│   │   ├── users.js           # User endpoints
│   │   ├── tricks.js          # Trick list endpoints
│   │   ├── trick.js           # Individual trick endpoints
│   │   └── image.js           # Image upload
│   │
│   ├── assets/                # Static assets
│   │   ├── icon.png
│   │   ├── splash.png
│   │   ├── adaptive-icon.png
│   │   └── TrickBookLogo.png
│   │
│   ├── auth/                  # Authentication
│   │   ├── context.js         # Auth context provider
│   │   └── storage.js         # Secure token storage
│   │
│   ├── components/            # Reusable UI components
│   │   ├── AppButton.js
│   │   ├── AppText.js
│   │   ├── AppTextInput.js
│   │   ├── Screen.js
│   │   ├── Trick.js
│   │   ├── ListItem.js
│   │   ├── ImageInput.js
│   │   ├── RoundedLineBar.js
│   │   └── forms/
│   │       ├── AppForm.js
│   │       ├── AppFormField.js
│   │       ├── ErrorMessage.js
│   │       └── SubmitButton.js
│   │
│   ├── config/                # App configuration
│   │   ├── colors.js          # Color palette
│   │   └── styles.js          # Common styles
│   │
│   ├── navigation/            # Navigation setup
│   │   ├── AppNavigator.js
│   │   ├── AuthNavigator.js
│   │   ├── TrickNavigator.js
│   │   ├── AccountNavigator.js
│   │   ├── GuestNavigator.js
│   │   └── routes.js
│   │
│   └── screens/               # Screen components
│       ├── WelcomeScreen.js
│       ├── LoginScreen.js
│       ├── RegisterScreen.js
│       ├── AccountScreen.js
│       ├── TrickListScreen.js
│       ├── ListTrickListsScreen.js
│       ├── AddTrickScreen.js
│       ├── SpinTheWheelScreen.js
│       └── ...
│
├── plugins/                   # Expo config plugins
│   └── fix-cpp-build-error.js
│
├── App.js                     # Root component
├── index.js                   # Entry point
├── app.json                   # Expo configuration
├── eas.json                   # EAS Build configuration
├── package.json
└── babel.config.js
```

## Key Features

### Trick Lists
- Create personal trick lists
- Add/edit/delete tricks
- Track completion progress
- Drag and drop reordering

### Trickipedia
- Browse global trick encyclopedia
- Filter by category and difficulty
- View detailed trick instructions

### Spot Lists (Premium)
- Save skate spot locations
- Organize into collections
- View on map

### User Features
- Profile management
- Image upload
- Guest mode (offline)
- Spin the wheel (random trick)

## App Configuration

### app.json

```json
{
  "expo": {
    "name": "TrickBook",
    "slug": "TrickBook",
    "version": "1.0.8",
    "ios": {
      "bundleIdentifier": "com.thetrickbook.trickbook",
      "supportsTablet": true
    },
    "android": {
      "package": "com.thetrickbook.trickbook",
      "versionCode": 4,
      "adaptiveIcon": {
        "foregroundImage": "./app/assets/adaptive-icon.png"
      }
    }
  }
}
```

### eas.json Build Profiles

| Profile | Purpose |
|---------|---------|
| `development` | Local dev builds with dev-client |
| `preview` | Internal testing distribution |
| `testflight` | iOS App Store submission |
| `playstore` | Google Play submission |

## Development Workflow

### Running Locally

```bash
# Start Expo dev server
npx expo start --dev-client

# Run on iOS simulator
npx expo start --ios

# Run on Android emulator
npx expo start --android
```

### Building for Production

```bash
# iOS build
eas build --platform ios --profile testflight

# Android build
eas build --platform android --profile playstore

# Both platforms
eas build --platform all --profile production
```

## Code Stats

| Metric | Count |
|--------|-------|
| JavaScript files | 60 |
| Screen components | 18 |
| Reusable components | 20 |
| API modules | 5 |
| Navigation stacks | 7 |

## Dependencies Overview

### Core
- React Native 0.74.5
- Expo SDK 51.0.0
- React 18.2.0

### Navigation
- React Navigation 6.x

### State & Forms
- React Context (auth)
- Formik + Yup (forms)
- AsyncStorage (persistence)

### UI
- react-native-reanimated
- react-native-gesture-handler
- @expo/vector-icons
