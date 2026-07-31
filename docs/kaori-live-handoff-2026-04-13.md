---
unlisted: true
title: Kaori Live Handoff (2026-04-13)
description: Deployment/debug handoff for Kaori Live VRM + voice stack
---

# Kaori Live Handoff (Apr 13, 2026)

## Goal
Ship `/kaori-live` with:
- Live DM chat with Kaori
- Correct chat bubble sides (user right/yellow, Kaori left)
- ElevenLabs voice playback after Kaori response
- Three.js character stage using VRM model

## What was completed

### Amplify / deploy pipeline
- Confirmed production branch is `main` for app `d23kwealrnh9ae`.
- Fixed repeated build failures from `npm ci` lock mismatch by adding `amplify.yml` install strategy.
- Fixed Next.js build error (`fs` in client bundle) by removing node-only fallback logic from `lib/api.js`.

### Kaori Live UX / behavior
- Bubble ownership fixed to use authenticated `userId`.
- Voice sequencing fixed to wait for fresh post-send Kaori response.
- ElevenLabs URL prioritized over browser TTS fallback.
- Realtime message updates added via `/messages` socket subscription.

### VRM integration
- Added dependencies:
  - `three`
  - `@pixiv/three-vrm`
- Added VRM model path:
  - `public/kaori/kaori_sample.vrm`
- Implemented VRM loader (`GLTFLoader` + `VRMLoaderPlugin`) and basic state/emote hooks.
- Added fallback and runtime stage status text for diagnostics.

## Current known issue
Character still not rendering for Wes in browser despite deploy iterations.

### Important finding
- Build `186` was **CANCELLED** by Amplify with message: `no diff detected from previous commit`.
- A forced rebuild commit was pushed after that (`557a0b1`) to ensure a new deployment runs.

## Relevant commits (TrickBookWebsite)
- `e6ef3ee` add `amplify.yml`
- `94cdda8` remove node-only imports from client path
- `1b1baa3` bubble sides + visible animated placeholder
- `9fa0012` voice sequencing + latest ElevenLabs preference
- `d375056` realtime socket updates for Kaori messages
- `76dd0c3` three-vrm integration
- `b38a973` VRM fallback + auto-fit into frame
- `ee8432a` hardened auto-fit bounds handling
- `a0f1638` stage diagnostics + guaranteed fallback avatar path
- `e49f600` Three init timing fix (run after loading)
- `557a0b1` forced rebuild + visible build tag in stage caption

## Immediate next actions (next session)
1. Verify latest Amplify job status for commit `557a0b1`.
2. Load `/kaori-live?v=187` and confirm caption includes build tag `build-187-force`.
3. If stage remains blank:
   - Open browser console and capture runtime errors from `kaori-live.js`.
   - Confirm `GET /kaori/kaori_sample.vrm` returns 200 in Network panel.
   - Temporarily render raw `gltf.scene` with a bright test material override to isolate shader/material issues.
4. Once render is visible, tune:
   - camera framing
   - Y-offset
   - expression mapping for idle/listening/thinking/speaking

## Notes
- This handoff doc is intended to allow seamless continuation from another machine/session while local machine is used for Siemens TIA Portal VM work.
