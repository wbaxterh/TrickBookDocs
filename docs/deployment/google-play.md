---
sidebar_position: 2
---

# Google Play Deployment (Android)

Guide for deploying TrickBook to the Google Play Store.

## Prerequisites

- Google Play Developer Account ($25 one-time)
- EAS CLI installed (`npm install -g eas-cli`)
- Logged into EAS (`eas login`)

## Current Status

| Item | Status |
|------|--------|
| Package Name | `com.thetrickbook.trickbook` |
| Version Code | 4 |
| Google Play | **Not yet submitted** |

## Deployment Steps

### Step 1: Google Play Console Setup

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill out:
   - App name: **TrickBook**
   - Default language: English
   - App or game: App
   - Free or paid: Free

### Step 2: Store Listing

Fill out all required fields:

#### Main Store Listing
- **Short description** (80 chars max):
  ```
  Track your skateboarding trick progress and discover new tricks
  ```

- **Full description** (4000 chars max):
  ```
  TrickBook is the ultimate companion app for skateboarders...
  [Full description of features]
  ```

#### Graphics Assets

| Asset | Dimensions | Required |
|-------|------------|----------|
| App icon | 512 x 512 | Yes |
| Feature graphic | 1024 x 500 | Yes |
| Phone screenshots | min 320px, max 3840px | 2-8 required |
| Tablet screenshots | min 320px, max 3840px | Optional |

### Step 3: Content Rating

1. Go to **Policy** → **App content** → **Content rating**
2. Complete the IARC questionnaire
3. Categories to declare:
   - No violence
   - No sexual content
   - No controlled substances
   - User-generated content (optional)

### Step 4: Data Safety

Declare what data the app collects:

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Email | Yes | No | Account creation |
| Name | Yes | No | Profile |
| Photos | Yes | No | Profile picture |
| App activity | Yes | No | Analytics |

### Step 5: Build for Google Play

```bash
cd TrickList

# Build Android App Bundle
eas build --platform android --profile playstore
```

Build takes approximately 15-30 minutes.

### Step 6: Download and Upload

**Option A: Auto-submit via EAS**
```bash
# Configure service account first (one-time setup)
eas credentials --platform android

# Submit to Play Store
eas submit --platform android --latest
```

**Option B: Manual Upload**
1. Download `.aab` file from EAS dashboard
2. In Play Console → **Production** → **Create new release**
3. Upload the `.aab` file
4. Add release notes
5. Review and roll out

### Step 7: Review and Release

1. **Testing tracks** (optional but recommended):
   - Internal testing (up to 100 testers)
   - Closed testing (invite-only)
   - Open testing (anyone can join)

2. **Production release**:
   - Google reviews apps (usually 1-3 days)
   - Once approved, choose rollout percentage
   - Start with 20% → 50% → 100%

## Android-Specific Configuration

### app.json Android Config

```json
{
  "expo": {
    "android": {
      "package": "com.thetrickbook.trickbook",
      "versionCode": 4,
      "adaptiveIcon": {
        "foregroundImage": "./app/assets/adaptive-icon.png",
        "backgroundColor": "#FFFFFF"
      },
      "permissions": [
        "CAMERA",
        "READ_EXTERNAL_STORAGE"
      ]
    }
  }
}
```

### Signing Configuration

EAS manages signing automatically. To view:

```bash
eas credentials --platform android
```

To manually manage:
```bash
# Generate new keystore
eas credentials --platform android

# View SHA-1 fingerprint (needed for Google Sign-In)
eas credentials --platform android
```

## Setting Up EAS Submit

### Create Service Account

1. Go to Google Cloud Console
2. Create project or select existing
3. Enable **Google Play Android Developer API**
4. Create service account with role: **Service Account User**
5. Generate JSON key file

### Link to Play Console

1. In Play Console → **Settings** → **API access**
2. Link to Google Cloud project
3. Grant service account access:
   - **Admin** for full access
   - **Release manager** for submissions only

### Configure EAS

```bash
# Set service account credentials
eas credentials --platform android
# Select "service account" and upload JSON key
```

## Play Console Checklist

### Before First Release

- [ ] Create developer account
- [ ] Complete identity verification (if required)
- [ ] Add payment profile (for paid apps/IAP)
- [ ] Accept Developer Distribution Agreement

### App Setup

- [ ] Set app category (Lifestyle or Sports)
- [ ] Set content rating
- [ ] Complete data safety form
- [ ] Add privacy policy URL
- [ ] Set target age group

### Store Listing

- [ ] App name
- [ ] Short description
- [ ] Full description
- [ ] App icon (512x512)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone)
- [ ] Screenshots (tablet) - optional
- [ ] Video URL - optional

## Version Management

With `autoIncrement: true`:
```bash
# versionCode auto-increments on each build
eas build --platform android --profile playstore
```

Manual version set:
```bash
eas build:version:set --platform android --version-code 10
```

## Troubleshooting

### Build Failures

```bash
# View logs
eas build:view --logs

# Clear cache
eas build --platform android --profile playstore --clear-cache
```

### Signing Issues

```bash
# Reset credentials
eas credentials --platform android --reset
```

### Upload Errors

Common issues:
- **Version code too low** - Increment versionCode
- **Package name mismatch** - Must match exactly
- **Target SDK too low** - Update Expo SDK

### Review Rejections

Common reasons:
1. **Privacy policy missing** - Add URL in store listing
2. **Crash on launch** - Test on multiple devices
3. **Deceptive behavior** - Ensure app does what it says
4. **Insufficient content** - App must have real functionality

## Release Checklist

Before each release:

- [ ] Test on physical Android device
- [ ] Test on Android 10, 11, 12, 13
- [ ] Test on different screen sizes
- [ ] Verify all permissions work
- [ ] Update versionCode
- [ ] Write release notes
- [ ] Take new screenshots (if UI changed)
- [ ] Submit for review
- [ ] Monitor for ANRs and crashes after release

## Monitoring

### Play Console Analytics

- **Statistics** → Installs, uninstalls, ratings
- **Android Vitals** → Crashes, ANRs, battery usage
- **Ratings and reviews** → User feedback

### Crash Reporting

Enable Firebase Crashlytics or Sentry:
```bash
npx expo install @sentry/react-native
```

## First-Time Setup Summary

```bash
# 1. Build the app
eas build --platform android --profile playstore

# 2. Create Play Console listing (web)

# 3. Set up EAS submit credentials
eas credentials --platform android

# 4. Submit to Play Store
eas submit --platform android --latest

# 5. Complete store listing in Play Console

# 6. Submit for review
```
