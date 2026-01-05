---
sidebar_position: 1
---

# App Store Deployment (iOS)

Guide for deploying TrickBook to the Apple App Store via TestFlight.

## Prerequisites

- Apple Developer Account ($99/year)
- Xcode installed (for local testing)
- EAS CLI installed (`npm install -g eas-cli`)
- Logged into EAS (`eas login`)

## Current Status

| Item | Status |
|------|--------|
| Bundle ID | `com.thetrickbook.trickbook` |
| Current Version | 1.0.8 |
| App Store | Live |
| TestFlight | Available |

## Deployment Steps

### Step 1: Pre-Flight Checks

```bash
cd TrickList

# Ensure dependencies are up to date
npm install

# Verify app.json configuration
cat app.json | grep -A5 '"ios"'

# Check EAS configuration
eas build:list --platform ios --limit 3
```

### Step 2: Build for TestFlight

```bash
# Start the build
eas build --platform ios --profile testflight

# Monitor build progress
eas build:view
```

Build takes approximately 15-30 minutes.

### Step 3: Submit to TestFlight

```bash
# Auto-submit to TestFlight
eas submit --platform ios --latest

# Or specify build ID
eas submit --platform ios --id BUILD_ID
```

### Step 4: TestFlight Configuration

In App Store Connect:

1. Go to **My Apps** → **TrickBook**
2. Click **TestFlight** tab
3. Under **Test Information**:
   - Add beta app description
   - Add contact email
   - Add test notes for reviewers

4. Under **Internal Testing**:
   - Add internal testers (up to 100)
   - Testers receive invite via email

5. Under **External Testing** (requires review):
   - Create test group
   - Add external testers
   - Submit for Beta App Review

### Step 5: App Store Submission

When ready for production:

1. In App Store Connect → **App Store** tab
2. Create new version (e.g., 1.0.9)
3. Fill out:
   - Version description / What's New
   - Keywords
   - Support URL
   - Marketing URL
   - Screenshots (required sizes)
   - App Preview videos (optional)

4. Select build from TestFlight
5. Submit for App Review

## App Store Connect Checklist

### App Information
- [x] App name: TrickBook
- [x] Bundle ID: com.thetrickbook.trickbook
- [x] SKU: trickbook
- [x] Primary language: English

### Privacy
- [x] Privacy Policy URL
- [ ] Data collection declarations
- [x] No encryption (ITSAppUsesNonExemptEncryption: false)

### App Review Information
- [ ] Contact name
- [ ] Contact phone
- [ ] Contact email
- [ ] Demo account (if login required)

### Screenshots Required

| Device | Size | Required |
|--------|------|----------|
| iPhone 6.7" | 1290 x 2796 | 3 minimum |
| iPhone 6.5" | 1284 x 2778 | 3 minimum |
| iPhone 5.5" | 1242 x 2208 | Optional |
| iPad 12.9" | 2048 x 2732 | If supporting iPad |

## iOS-Specific Configuration

### Info.plist Permissions

```json
// app.json
"ios": {
  "infoPlist": {
    "NSCameraUsageDescription": "This app uses the camera to access photos for a profile image.",
    "ITSAppUsesNonExemptEncryption": false
  }
}
```

### Capabilities

Currently configured:
- Push Notifications: Not enabled
- Sign in with Apple: Not enabled
- Background modes: Not enabled

## Troubleshooting

### Build Failures

```bash
# View build logs
eas build:view --logs

# Clear cache and rebuild
eas build --platform ios --profile testflight --clear-cache
```

### Signing Issues

```bash
# Regenerate certificates
eas credentials --platform ios

# Reset and recreate
eas credentials --platform ios --reset
```

### Submission Rejection

Common reasons:
1. **Missing privacy policy** - Add URL in App Store Connect
2. **Crasher/bug** - Test thoroughly before submission
3. **Incomplete metadata** - Fill all required fields
4. **Guideline violation** - Review Apple's guidelines

## Version Bumping

EAS handles version increments automatically with `autoIncrement: true`.

Manual override:
```bash
# Set specific version
eas build:version:set --platform ios --build-number 15
```

## Monitoring

### View Analytics

App Store Connect → **Analytics**:
- Downloads
- Sales
- Usage
- Crashes

### Crash Reports

App Store Connect → **App Analytics** → **Metrics** → **Crashes**

Or integrate crash reporting:
```bash
# Add Sentry
npx expo install @sentry/react-native
```

## Release Checklist

Before each release:

- [ ] Test all features on physical device
- [ ] Test on multiple iOS versions (15, 16, 17)
- [ ] Verify API endpoints work
- [ ] Check push notifications (if enabled)
- [ ] Update version number
- [ ] Write release notes
- [ ] Take new screenshots (if UI changed)
- [ ] Submit for review
- [ ] Monitor for issues after release
