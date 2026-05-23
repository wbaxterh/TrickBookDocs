---
sidebar_position: 1
title: "ADR-001: Native Google Sign-In"
---

# ADR-001: Migrate to Native Google Sign-In

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | May 2026 |
| **Deciders** | Wes Huber |

## Context

TrickBook used `expo-auth-session` for Google authentication. This library implements a browser-based OAuth flow: it opens a web browser, the user signs in on Google's web page, and Google redirects back to the app via a redirect URI.

On production Android builds distributed through the Google Play Store, the redirect URI uses a custom scheme (`trickbook://`). However, Google's web OAuth clients only accept `https://` redirect URIs. This mismatch caused **Error 400: invalid_request** for every Play Store user attempting to sign in with Google.

The issue did not surface during development because Expo Go and dev client builds use a different redirect flow (`https://auth.expo.io`), masking the production incompatibility.

## Decision

Switch from `expo-auth-session` to `@react-native-google-signin/google-signin`, which uses the **native Android Google Sign-In SDK** instead of a browser redirect.

### Key Implementation Details

**SHA-1 Fingerprint Registration**

The native Google Sign-In SDK requires SHA-1 fingerprints registered in Google Cloud Console. Two Android OAuth clients are needed because Google Play re-signs APKs with its own app signing key:

| Environment | Key Type | SHA-1 Prefix |
|-------------|----------|-------------|
| Development | Upload key | `60:74:90:D9:...` |
| Play Store (production) | App signing key | `A2:9D:C9:0E:...` |

Both SHA-1 fingerprints must be registered in the Google Cloud Console under their respective Android OAuth client credentials.

**Backend Verification**

The native SDK accepts a `webClientId` parameter that sets the audience on the returned ID token. This means backend token verification continues to work with the existing `GOOGLE_CLIENT_ID` environment variable -- no backend changes required.

**Expo Configuration**

A config plugin was added to `app.config.js` with an `iosUrlScheme` for the iOS reverse client ID. This is required for the native iOS Google Sign-In flow.

```js
// app.config.js (excerpt)
[
  "@react-native-google-signin/google-signin",
  {
    iosUrlScheme: "com.googleusercontent.apps.YOUR_CLIENT_ID",
  },
];
```

## Alternatives Considered

### Expo Auth Proxy

The Expo auth proxy (`auth.expo.io`) handled redirect URIs server-side, avoiding the custom scheme problem. However, this service has been **deprecated** by Expo and is no longer a viable long-term solution.

### Fixing Redirect URIs

Google's web OAuth client type does not support custom URI schemes (`trickbook://`). There is no configuration that makes `expo-auth-session` work with custom schemes on production Android builds. The Android OAuth client type could theoretically work, but `expo-auth-session` is designed around the web OAuth flow.

## Consequences

### Positive

- **Production reliability**: Google Sign-In works correctly for all Play Store users. The Error 400 issue is fully resolved.
- **Better UX**: Users get native one-tap sign-in instead of being bounced to a browser window.
- **Platform consistency**: The same library handles both iOS and Android with platform-appropriate native flows.

### Negative

- **Requires native rebuild**: The app can no longer run in Expo Go for testing Google Sign-In. Development and preview builds must use a dev client (`npx expo run:android` or EAS development builds).
- **SHA-1 management**: Two Android OAuth clients must be maintained. If the upload key or app signing key changes, the corresponding SHA-1 must be updated in Google Cloud Console.
- **Config plugin dependency**: The Expo config plugin must be kept in sync with library updates.
