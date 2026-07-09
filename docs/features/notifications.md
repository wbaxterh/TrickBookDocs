---
title: Notifications
sidebar_label: Notifications
---

# Notifications — Feature Spec & Implementation Plan

Status: **Approved — ready to implement** · Author: Wes / Claude pair · Last updated: 2026-06-14

**Locked decisions (2026-06-14):**
1. **Reminder delivery: hybrid local + server backfill.**
2. **Permission prompt: soft-ask first**, OS prompt only after user accepts in-app.
3. **Web push (Phase 4): deferred** to a later release. v2.x is mobile-only.
4. **v2.x scope: Phases 0 + 1 + 2 + 3 + 5** — messages AND reminders ship together.

Cross-platform push & in-app notifications for the TrickBook ecosystem (iOS, Android, Web). First two categories shipping in v2.x: **Messages** and **Trick reminders**. Per-category opt-in/out toggles in user preferences on every platform.

This document is the source of truth for what we are building, why, and how — written after a deep research pass over current (2025-2026) Apple, Google, MDN, and Expo guidance. Citations live at the bottom.

---

## 1. Goals & Non-Goals

### Goals
1. Reliable push delivery for **direct messages** (Socket.io chat already in backend) on iOS, Android, and Web.
2. Reliable scheduled **trick reminders** ("Hey, you haven't landed `kickflip` on your `street tricks` list this week — go session it.") on iOS and Android. Web reminders are a stretch goal in this round.
3. **Per-category** preferences (Messages on/off, Reminders on/off, plus per-list reminder cadence) editable from both the mobile profile screen and the web account settings page.
4. Backend that respects OS-level state (cleans up dead tokens, never spams users whose OS permission is denied).
5. Foundation that lets us add new categories later (likes, comments, friend requests, weekly digest) without re-architecting.

### Non-Goals (this round)
- Marketing/broadcast notifications (no campaign tool, no segmentation engine).
- Rich-media notifications (images, action buttons) — passive payloads only for v1.
- iOS Live Activities / Dynamic Island / Lock Screen Widgets.
- Notification history / inbox UI inside the app.
- A/B testing of copy or cadence.
- Server-Sent Events / web push for messages (web messages will still use the existing Socket.io connection while the page is open; web push is reserved for reminders and out-of-tab events in a later phase).

---

## 2. User Stories

### Messages
- **US-M1** As a logged-in user, when another user sends me a DM and the TrickBook app is **backgrounded or closed**, I receive a push notification with the sender's display name and a one-line message preview, so I can tap to open the conversation.
- **US-M2** As a logged-in user, when I have the **app in the foreground**, I do **not** see a system notification banner for a message in the chat I'm already viewing; I see the in-app inline indicator instead.
- **US-M3** As a logged-in user, I can **mute message notifications** entirely from my profile preferences without affecting other categories.
- **US-M4** As a logged-in user signed in on **multiple devices**, message pushes are delivered to all of them; tapping one and reading the message **clears the badge/banner on the others** (best-effort; badge sync is OS-permitting).
- **US-M5** As an iOS user with **Focus mode** on, message notifications respect Focus by default (`active` interruption level) unless I have explicitly marked the sender as a VIP (deferred — out of scope this round).
- **US-M6** As a sender, my **own messages never push back to my own devices**.

### Trick reminders
- **US-R1** As a user with a trick list (e.g. "Street goals"), I can opt into **periodic reminders** to land the unfinished tricks on that list.
- **US-R2** Reminder cadence is **per-list, user-chosen**: off / daily / 3× week / weekly. Default for new lists: **weekly**.
- **US-R3** Reminders fire **in my local timezone** between a configurable quiet-hours window (default 9:00–20:00 local).
- **US-R4** A reminder names **one trick at a time** (the longest-outstanding unfinished trick on that list) and deep-links me into the trick's detail / video page.
- **US-R5** From a reminder I can **"snooze 1 week"** or **"mark this trick as done"** directly (action buttons — stretch; falls back to deep link).
- **US-R6** As a user, I can **globally disable** reminders from profile preferences regardless of per-list cadence.
- **US-R7** Reminders **do not fire** for lists I haven't opened in 60+ days (auto-pause to prevent decay-fatigue), and the app prompts me on next open: "Resume reminders for [list]?"

### Preferences
- **US-P1** As a user, on **iOS, Android, and Web**, my profile preferences page exposes one toggle per category (Messages, Reminders) plus the per-list reminder cadence selector.
- **US-P2** As a user who has **denied the OS-level notification permission**, the in-app toggles still work but render a banner: *"Notifications are turned off in your phone settings — [Open Settings]"*. Tapping deep-links to the system app-settings page.
- **US-P3** As a user, preference changes **propagate across devices within seconds** (preferences live server-side, mobile and web read from the same `/users/me/notification-preferences` endpoint).
- **US-P4** As a user, when I **log out**, my push tokens for that device are **invalidated server-side** so a future user on the same device doesn't receive my notifications.
- **US-P5** As a brand-new user just signing up, I am **not** prompted for notification permission immediately. We use the **soft-ask pattern**: ask in-app first ("Want a heads-up when friends message you?"), then trigger the OS prompt only if they say yes.

---

## 3. UX Flows

### 3.1 First-run permission flow (mobile)
1. User signs up / logs in. **No OS prompt yet.**
2. After they reach the home tab (or after their first trick interaction — whichever comes first), a non-blocking in-app sheet appears: *"Get a heads-up when your homies message you?"* with **"Yes, notify me"** and **"Not now"**.
3. If "Yes" → call `Notifications.requestPermissionsAsync()` → OS prompt → on grant, register push token with backend.
4. If "Not now" → store `softAskDeferredAt` locally; offer again no sooner than 7 days later, and only on a contextually relevant moment (e.g., "you got a new message" toast in-app).
5. If OS-denied → record `osPermission: denied` in user prefs; do not re-prompt programmatically. Profile screen instead shows the *"Open Settings"* banner.

> **Why this matters:** Both Apple and Google explicitly recommend the soft-ask pattern. Asking on app launch results in ~50% denial rates and the OS won't let you re-ask. (See Sources §1, §3.)

### 3.2 Notification preferences screen (mobile)
```
┌──────────────────────────────────────────────┐
│  Notifications                          [⨯]  │
├──────────────────────────────────────────────┤
│  [ ⚠ Notifications are off in iOS Settings ] │← shown only if OS-denied
│  [          Open Settings →                ] │
│                                              │
│  Push                                        │
│  ──────────────────────────────────────────  │
│  Direct messages              [ ●━━━ on    ] │
│  Trick reminders              [ ●━━━ on    ] │
│                                              │
│  Quiet hours                                 │
│  ──────────────────────────────────────────  │
│  Don't notify between        9:00 PM – 9:00 AM
│                                              │
│  Per-list reminder cadence                   │
│  ──────────────────────────────────────────  │
│  Street goals                 Weekly       › │
│  Tranny tricks                Daily        › │
│  Snowboard 25/26              Off          › │
└──────────────────────────────────────────────┘
```

- The "Open Settings" banner appears only when OS permission is denied **and** the user toggled at least one category on. Behavior matches Slack / WhatsApp.
- Quiet hours apply to **reminders only**, not messages (people expect real-time messaging).
- Per-list cadence list is paginated/scrollable; only lists the user owns or has saved are shown.

### 3.3 Notification preferences (web)
Mirror of mobile, lives at `/account/notifications` in `TrickBookWebsite`. The "Open Settings" banner is replaced with: *"Allow notifications in this browser"* (button calls `Notification.requestPermission()`). On iOS Safari, render an install-as-PWA prompt because **Safari refuses to even surface the permission prompt unless the site is installed to home screen** (Sources §7).

### 3.4 Receiving a message push (iOS)
- Payload includes `threadId = conversationId` so iOS groups all messages from the same conversation under one stack. (Sources §2)
- Tap → deep links into `/messages/[conversationId]`.
- Badge count = unread-conversations count (server tracks it; we update on each send and on read receipts).

### 3.5 Receiving a reminder
- Title: `Time to send it 🛹`
- Body: `You've still got [trickName] on [listName] — go land it.`
- Tap → `/spots-or-trick-detail/[trickId]?listId=[listId]&fromReminder=1` (the `fromReminder` query param lets analytics attribute completions).
- Action buttons (stretch): `[Mark landed]` `[Snooze 1 week]`.

---

## 4. Data Model

### 4.1 MongoDB — `users` collection additions
Existing users currently store `expoPushToken` as a single string in a **legacy in-memory store** that is not wired to the real Mongo `users` collection — **this stub will be removed**. Replace with:

```js
// users document — new fields
{
  // ... existing fields
  notificationPreferences: {
    messages: { push: true,  inApp: true,  email: false },
    reminders: { push: true,  inApp: false, email: false },
    quietHours: { start: '21:00', end: '09:00', timezone: 'America/New_York' },
    osPermission: { ios: 'unknown', android: 'unknown', web: 'unknown' }, // 'granted'|'denied'|'unknown'|'provisional'
    updatedAt: ISODate
  }
}
```

### 4.2 New collection — `pushTokens`
One document per (user, device). Keeping these in their own collection (not embedded on `users`) so a single user with 5 devices doesn't bloat the user doc and so token cleanup is a simple delete.

```js
{
  _id: ObjectId,
  userId: ObjectId,           // indexed
  platform: 'ios'|'android'|'web',
  transport: 'expo'|'fcm'|'apns'|'webpush',
  token: String,              // ExpoPushToken[…], FCM registration id, or web push subscription JSON
  endpoint: String,           // web-push only — endpoint URL
  keys: { p256dh: String, auth: String }, // web-push only
  appVersion: String,
  deviceModel: String,
  locale: String,
  timezone: String,           // IANA, e.g. "America/Los_Angeles"
  lastSeenAt: Date,
  createdAt: Date,
  // marked dead by receipt poller — kept ~30 days for debugging then purged
  deadReason: 'DeviceNotRegistered'|'410-Gone'|null,
  deadAt: Date|null
}

// Indexes
db.pushTokens.createIndex({ userId: 1, platform: 1 })
db.pushTokens.createIndex({ token: 1 }, { unique: true })
db.pushTokens.createIndex({ deadAt: 1 }, { expireAfterSeconds: 2592000 }) // 30d TTL on dead tokens
```

### 4.3 New collection — `scheduledNotifications`
Lightweight queue for server-scheduled reminders. (Local scheduled notifications on the device are still preferred for the next-firing-soon case; this collection handles long-horizon scheduling so a user who reinstalls the app doesn't lose their reminder.)

```js
{
  _id: ObjectId,
  userId: ObjectId,
  category: 'reminder',
  listId: ObjectId,
  trickId: ObjectId,
  scheduledFor: Date,         // UTC, indexed
  status: 'pending'|'sent'|'cancelled'|'failed',
  idempotencyKey: String,     // hash(userId+listId+trickId+scheduledFor) — prevents dup sends
  attemptCount: Number,
  lastAttemptAt: Date,
  createdAt: Date
}

db.scheduledNotifications.createIndex({ scheduledFor: 1, status: 1 })
db.scheduledNotifications.createIndex({ idempotencyKey: 1 }, { unique: true })
db.scheduledNotifications.createIndex({ userId: 1, listId: 1 })
```

### 4.4 New collection — `notificationDeliveryLog` (optional, debug)
Append-only audit log keyed by `expoTicketId`. Useful when debugging "I didn't get the message" complaints. 30-day TTL.

---

## 5. API Endpoints

All under `/api`. All require `auth` middleware unless noted.

### Tokens
- `POST /push-tokens` — register/upsert. Body: `{ token, platform, transport, appVersion, deviceModel, timezone, locale }`. Server upserts by `token` (unique). Returns 201.
- `DELETE /push-tokens/:token` — explicit logout / device removal.
- `DELETE /push-tokens?platform=web&endpoint=...` — web-push unsubscribe.

### Preferences
- `GET /users/me/notification-preferences` — returns the `notificationPreferences` subdocument.
- `PATCH /users/me/notification-preferences` — partial update. Body: `{ messages: { push: false }, quietHours: { start: '22:00' } }`. Server merges, validates with Joi.
- `GET /users/me/reminder-cadence` — returns `[{ listId, cadence }]` per saved list.
- `PUT /users/me/reminder-cadence/:listId` — `{ cadence: 'off'|'daily'|'3x-week'|'weekly' }`. Server (re)plans `scheduledNotifications` rows for the next 30 days.

### Web push
- `GET /push/vapid-public-key` — returns `{ publicKey }`. Skip-auth (public, needed before subscribe).
- `POST /push-tokens` (same endpoint as above) handles the web push subscription JSON when `transport='webpush'`.

### Admin / debug (auth-admin only)
- `POST /admin/notifications/test` — `{ userId, category, body }` sends a test push to all of that user's live tokens. Useful for support tickets and QA.

---

## 6. Backend Architecture

### 6.1 Sender service
A single `services/notificationSender.js` module is the only thing that calls `expo-server-sdk`. Every other caller (messages route, reminder cron, admin test endpoint) goes through it.

```js
// pseudocode
async function send({ userId, category, title, body, data, threadId, channelId, interruptionLevel }) {
  const prefs = await getPrefs(userId);
  if (!prefs[category]?.push) return { skipped: 'in-app-pref-off' };
  if (category === 'reminder' && inQuietHours(prefs)) return { skipped: 'quiet-hours' };

  const tokens = await getLiveTokens(userId);
  if (tokens.length === 0) return { skipped: 'no-tokens' };

  const messages = tokens.map(t => buildMessageForPlatform(t, { title, body, data, threadId, channelId, interruptionLevel }));
  const chunks = expo.chunkPushNotifications(messages); // ≤100 per chunk per Expo docs
  const tickets = await sendChunksWithRetry(chunks);
  await persistTickets(tickets, userId, category);
}
```

Key correctness points (all verified in research):
- **Always chunk** via `expo.chunkPushNotifications()` — Expo enforces a hard 100-per-request cap.
- **Always run `Expo.isExpoPushToken(t)` first** — drop malformed tokens with a warn-log.
- **Never await in a `forEach`** (the current `pushNotifications.js` does this — bug to fix; tickets are silently dropped).
- **Persist ticket IDs** so the receipts worker can look them up.

### 6.2 Receipts worker
A cron (every 15 min) that fetches receipts for tickets older than 30 min:

```js
const receiptChunks = expo.chunkPushNotificationReceiptIds(pendingIds);
for (const chunk of receiptChunks) {
  const receipts = await expo.getPushNotificationReceiptsAsync(chunk);
  for (const [id, r] of Object.entries(receipts)) {
    if (r.status === 'error' && r.details?.error === 'DeviceNotRegistered') {
      await pushTokens.updateOne({ /* match ticket→token */ }, { $set: { deadAt: new Date(), deadReason: 'DeviceNotRegistered' } });
    }
    // log MessageRateExceeded, MessageTooBig, MismatchSenderId for ops visibility
  }
}
```

Expo retains receipts at least 24h; we poll well within that window.

### 6.3 Reminder scheduler
**Hybrid local + server approach** — for each list with cadence ≠ off:

1. **Server pre-plans the next 30 days** of `scheduledNotifications` rows when cadence changes or a new trick is added to a list. Each row has a UTC `scheduledFor` computed from user's quiet-hours window + cadence + tz.
2. **Mobile app on launch** queries `GET /users/me/scheduled-notifications?within=14d`, then uses `Notifications.scheduleNotificationAsync()` to register them as **local** notifications on-device. Local notifications survive backgrounding, kill, and offline.
3. **Server cron fires** any rows that local scheduling missed (user uninstalled and reinstalled, multi-device user where one device is offline).
4. **De-dup**: every fire path uses the `idempotencyKey` — local notifications include it as `data.idempotencyKey`, and the server marks the row `sent` only after one path confirms delivery.

**Why hybrid:** local-only loses the reminder on uninstall and doesn't sync across devices. Server-only is subject to Doze/App Standby on Android (delivery delayed up to ~2h on aggressive battery) and silently fails on Web until the next foreground. Hybrid covers both.

### 6.4 Web push backend
- Add `web-push` npm package.
- Generate VAPID keys once with `web-push.generateVAPIDKeys()`, store both in env vars (`VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`) per project secrets policy.
- `sendWebPush()` reads the subscription JSON from `pushTokens`, calls `webPush.sendNotification(subscription, payload, { TTL, urgency, topic })`.
- On `410 Gone` response: mark token dead (subscription expired/revoked).
- TTL: `60` seconds for messages (only relevant if delivered fresh), `86400` for reminders (today's reminder OK to deliver up to a day late).
- `urgency: 'high'` for messages, `'normal'` for reminders.
- `topic: 'msg-{conversationId}'` for messages — push service collapses queued duplicates per RFC 8030.

---

## 7. Platform-specific Implementation Notes

### 7.1 iOS (Expo)
- **APNs setup**: provision via EAS — Expo CLI generates the .p8 key or uploads our existing one. Required: `.p8` file + Key ID + Team ID. EAS stores all three; no manual JWT signing needed when sending through Expo's proxy.
- **Provisional authorization** (`UNAuthorizationOptionProvisional`): NOT used in v1. Provisional sends quiet, non-interruptive notifications without asking — useful for a "trial" period — but we have a clear soft-ask, and provisional reminders that go to Notification Center silently aren't useful.
- **Interruption levels**:
  - Messages → `active` (default; respects Focus / Sleep).
  - Reminders → `active`.
  - We do **not** use `timeSensitive` (breaks Focus — reserved for actually-urgent stuff). We do **not** use `critical` (requires Apple entitlement we don't have).
- **threadId** → set to `conversationId` for messages so iOS stacks them. For reminders, set to `reminder-{listId}` so per-list reminders stack.
- **Badge counts**: backend tracks unread conversation count per user; send `badge: count` on each message push and on every read-receipt push (with `_displayInForeground: false`).
- **Silent notifications**: not used in v1. (`content-available: 1` requires `aps-environment` entitlement and is throttled by iOS.)
- **iOS 18**: Apple Intelligence may auto-summarize stacked notifications on iPhone 15 Pro+; our message payloads should keep the sender name in the title (not the body) so summaries make sense. No code change required, but **copy guideline**: title = sender name, body = message preview.
- **Expo Go limitation**: remote push works in Expo Go on iOS, **not** on Android (since SDK 53). All notification dev/test on Android must use a development build.

### 7.2 Android (Expo)
- **FCM v1 migration** is mandatory — legacy FCM was sunset September 2024. Expo's `eas credentials` flow handles uploading the `google-services.json` and configuring FCM v1 service-account credentials. **Action item**: confirm `eas credentials` shows "FCM V1" not "FCM (Legacy)" for the project; if legacy, run the migration before the next Android build.
- **Notification channels must exist BEFORE the OS permission prompt** is shown, and before `getDevicePushTokenAsync()` / `getExpoPushTokenAsync()` is called. Two channels for v1:
  ```js
  await Notifications.setNotificationChannelAsync('messages', {
    name: 'Direct Messages',
    importance: Notifications.AndroidImportance.HIGH, // heads-up
    sound: 'default',
    enableVibrate: true,
    lockscreenVisibility: Notifications.AndroidNotificationVisibility.PRIVATE,
  });
  await Notifications.setNotificationChannelAsync('reminders', {
    name: 'Trick Reminders',
    importance: Notifications.AndroidImportance.DEFAULT, // no heads-up
    sound: 'default',
  });
  ```
- **Android 13+ runtime permission**: call `Notifications.requestPermissionsAsync()` from our soft-ask flow. Pre-check via `Notifications.getPermissionsAsync()` and respect "denied + don't ask again" — second-chance prompt shows a rationale screen, then the system Settings deep-link.
- **Android 14 foreground service types**: not relevant to us (we don't run FGS).
- **Android 14 USE_FULL_SCREEN_INTENT**: not used (we're not a calling/alarms app — Play would revoke it anyway).
- **Doze / App Standby**: server-sent push delivery to a Dozing device may delay by ~15 min. Acceptable for both categories — we are not an emergency-alert app.
- **Notification grouping**: Android groups by channel by default. Add `group: conversationId` for messages so multiple messages in one chat collapse into a summary notification.

### 7.3 Web (NextJS)
- **VAPID keys** generated once with `web-push` library, stored as env vars on the Amplify-hosted site (public key bundled to client) and on the backend (private key, server-only).
- **Service worker** at `/sw.js` registers in `app/layout.tsx` (or `_app.tsx`). The SW handles `push` and `notificationclick` events, deep-links via `clients.openWindow()`.
- **Permission prompt**: only fired from a click handler on the "Enable notifications" button in `/account/notifications`. **Never** on page load — Chrome's "quieter UI" will hide the prompt entirely.
- **Browser support reality**:
  - Chrome / Firefox / Edge desktop & Android — fully supported.
  - Safari macOS 16+ — supported.
  - Safari iOS 16.4+ — **only after the site is added to the home screen as a PWA**. Render an "Install to home screen" callout in our settings page on iOS Safari.
- **Subscription endpoint goes stale**: on `410 Gone` from web-push send, mark the token dead. Common after browser clears site data, device reset, etc.

### 7.4 Cross-platform copy guidelines
- Title: subject of the notification (sender name, list name). 30 chars max.
- Body: one-line preview, no emoji-only payloads. 80 chars max.
- Deep-link via `data.url = '/<route>?...'` consumed by `expo-router` (mobile) or `next/router` (web).
- Always include `data.category` so analytics can attribute taps.

---

## 8. Edge Cases & Open Decisions

| # | Edge case | Decision |
|---|-----------|----------|
| 1 | OS permission denied, in-app toggle still ON | Token registration is skipped; in-app banner prompts Open Settings. We do not call `requestPermissionsAsync()` repeatedly. |
| 2 | User toggles OFF in-app, then back ON | We re-query OS permission. If still granted, just flip server pref. If revoked, run soft-ask again. |
| 3 | Sender = receiver | `notificationSender` short-circuits if `data.fromUserId === userId`. |
| 4 | User reads message in another device first | Read-receipt event also fires a low-priority "update badge" push to the other devices with `_displayInForeground: false`. |
| 5 | Reminder fires but trick has been completed | `notificationSender` re-checks trick status at send time. If complete, mark scheduled row `cancelled`. |
| 6 | User in air mode / no connection | Local-scheduled fires on-device. Server backfill on next reconnect — idempotency key dedupes. |
| 7 | Quiet hours span midnight | `inQuietHours()` handles wrap (e.g. 21:00–09:00). Stored as two HH:mm strings + IANA timezone. |
| 8 | Timezone change while travelling | `pushTokens.timezone` updates on each app foreground; reminder rescheduling on tz-change is a stretch (acceptable to fire at "wrong" local time until next foreground). |
| 9 | Multiple devices, badge sync | iOS / Android badges are best-effort; we send badge updates but don't guarantee synchronization (no Apple "shared badge state" API). |
| 10 | Same trick in two lists, both reminding | Idempotency key includes listId; user gets two reminders. Acceptable v1; deferred dedup. |

---

## 9. Phased Implementation Plan

Each phase is independently shippable. **Phases 1 + 2 + 5 are the MVP** (messages + preferences). Reminders (3 + 4) can ship in a follow-up build if needed.

### Phase 0 — Pre-work (no app code yet)
- [ ] Confirm `eas credentials` is on **FCM v1**, not legacy. Run migration if needed.
- [ ] Verify APNs `.p8` key is registered in EAS for `com.thetrickbook.trickbook` (re-use existing or generate via `eas credentials`).
- [ ] Generate VAPID keypair (one time): `npx web-push generate-vapid-keys`. Store in Backend `.env` and Amplify env. Add to `.env.example` placeholders.
- [ ] Delete legacy `Backend/store/users.js` references from `routes/expoPushTokens.js` and replace with real Mongo wiring (Phase 1 absorbs this).
- **Done when**: EAS shows FCM V1 + valid APNs key; VAPID keys present in all three env stores.

### Phase 1 — Backend foundation
**Files touched:** `Backend/routes/pushTokens.js` (renamed from `expoPushTokens.js`), `Backend/routes/notificationPreferences.js` (new), `Backend/services/notificationSender.js` (new, replaces `utilities/pushNotifications.js`), `Backend/workers/receiptsPoller.js` (new), `Backend/index.js` (mount new routes).

**Scope:**
- New `pushTokens` collection + indexes (Section 4.2).
- `notificationPreferences` subdoc added to `users` (Section 4.1) with safe defaults backfilled for existing users via one-time migration script.
- `POST /push-tokens`, `DELETE /push-tokens/:token`.
- `GET/PATCH /users/me/notification-preferences`.
- `notificationSender.send()` with chunking, `isExpoPushToken` validation, ticket persistence.
- Receipts poller cron (15 min interval) that flips `pushTokens.deadAt` for `DeviceNotRegistered`.
- Delete legacy `utilities/pushNotifications.js` and the broken-by-design `store/users.js`-based `expoPushTokens.js`.

**Acceptance:** Manual `curl` POST to `/push-tokens` writes to Mongo; admin test endpoint sends to a real device; killing the app and re-installing → next push returns `DeviceNotRegistered` → token gets `deadAt` set within 30 min.

**Risk:** existing `expoPushTokens.js` is mounted in `index.js:81` but writes to a no-op in-memory store. Removing it is safe (no real consumers). Sanity-check `git grep expoPushToken` in mobile app before deletion.

### Phase 2 — Mobile push (messages)
**Files touched:** `TrickList/src/lib/notifications/` (new dir with `index.ts`, `permissions.ts`, `channels.ts`, `tokens.ts`), `TrickList/app/_layout.tsx` (wire init), `TrickList/src/lib/api/notifications.ts` (new client), `TrickList/app/(tabs)/profile/notifications.tsx` (new screen), backend `routes/messages.js` (call sender on new message), `TrickList/app.config.js` (`expo-notifications` plugin config).

**Scope:**
- `npx expo install expo-notifications`.
- Android channels created on app start (before any token call).
- Soft-ask sheet component, gated on `softAskDeferredAt` and `osPermission` state.
- Token registration on permission grant + on every foreground (refresh staleness).
- Foreground notification handler (suppress for current chat; show for others).
- `expo-router` deep-link handler reads `data.url`.
- Backend `messages.js` POST handler invokes `notificationSender.send()` after persisting the message — fire-and-forget (no awaiting send for socket emit responsiveness).
- iOS payload includes `threadId`; Android payload includes `channelId: 'messages'` and `group: conversationId`.

**Acceptance:** Two physical devices logged in as two users; send DM; receiver gets banner within 5s; tap deep-links to conversation; badge increments. App in foreground viewing the chat → no banner. Profile → Notifications → toggle Messages off → next push is skipped (verify via server log).

**Risk:** badge math races (read receipts vs new messages arriving). Mitigate with last-write-wins and a fallback "clear badge on app foreground" sweep.

### Phase 3 — Reminder engine
**Files touched:** `Backend/services/reminderPlanner.js`, `Backend/workers/reminderSender.js`, `Backend/routes/reminderCadence.js`, mobile `TrickList/src/lib/notifications/scheduledLocal.ts`, mobile profile reminder cadence picker UI.

**Scope:**
- `scheduledNotifications` collection (Section 4.3).
- `reminderPlanner.planNext30Days(userId, listId, cadence)` — called on cadence change or trick-list mutation.
- `reminderSender` cron (every 5 min) fires `pending` rows where `scheduledFor <= now` AND `idempotencyKey` not already `sent`.
- Local pre-scheduling on mobile via `Notifications.scheduleNotificationAsync()` for next 14 days, refreshed on every app foreground.
- Idempotency dedup between local and server paths.
- Auto-pause: lists with no opens in 60d set cadence to `off` and surface re-engagement prompt on next list open.

**Acceptance:** Set a list to "daily" at 10:00 local; reminder fires at 10:00 local in user's tz, on at least the device where they last opened the list. Mark trick complete → next reminder skips that trick. Toggle Reminders off globally → no reminders fire even if cadence is on.

**Risk:** Doze on Android delays delivery up to ~15 min — surface that in copy *("approximate time")* if it becomes a complaint.

### Phase 4 — Web push (DEFERRED to a later release)
Not in v2.x scope. The web `/account/notifications` preferences page will still ship in v2.x (Phase 5) — toggles work, the only thing missing is delivery to a browser when the user is offline. While the web app is open, the existing Socket.io connection continues to deliver messages in real time.

**When this phase is reactivated, files touched will be:** `TrickBookWebsite/public/sw.js`, `TrickBookWebsite/app/account/notifications/page.tsx`, `TrickBookWebsite/lib/pushClient.ts`, backend `notificationSender` web-push branch — VAPID flow, service worker registration, iOS PWA install callout, 410-Gone cleanup. All web-push design from Sections 4.2 / 6.4 / 7.3 is already locked so the future phase is a straight implement.

### Phase 5 — Preferences UX polish & QA
**Scope:**
- "Open Settings" deep-link banner on mobile. On web, the same prefs page renders but the *"Allow notifications in this browser"* button is hidden behind a "Coming soon" pill (Phase 4 reactivates it).
- Quiet-hours picker (mobile + web — web is read-only display until Phase 4? **No** — web *can* edit it; the value is server-side and applies to mobile delivery, so web users editing it from desktop is valid).
- Logout invalidates this device's token server-side.
- Analytics: track open-rate and toggle-rate per category.
- Empty states, loading states, error states for the prefs screen.
- Release notes page in Docusaurus (`docs/docs/releases/`) per project convention.

**Acceptance:** Every flow in Section 3 works end-to-end on iOS, Android, Chrome, Safari (PWA). QA checklist (Section 11) is all green.

---

## 10. Acceptance Criteria — Master Checklist

Tied to user stories:

- [ ] **US-M1** Receiving DM while backgrounded shows push within 5s on iOS + Android.
- [ ] **US-M2** Receiving DM in current chat foreground shows in-app indicator, not OS banner.
- [ ] **US-M3** Toggling Messages off stops pushes within 1 request cycle of the change.
- [ ] **US-M4** Multi-device receives on both; badges roughly sync (best-effort).
- [ ] **US-M6** Sender never gets own-message push.
- [ ] **US-R1..R7** Reminders fire per per-list cadence, in local tz, within quiet hours, deep-link to trick.
- [ ] **US-P1** Per-category toggles render on mobile and web prefs screens.
- [ ] **US-P2** OS-denied state shows Open Settings banner; tap opens system app settings.
- [ ] **US-P3** Toggle change on mobile reflects on web within 10s (manual refresh OK).
- [ ] **US-P4** Logout deletes the token row server-side.
- [ ] **US-P5** No OS permission prompt on first launch; soft-ask happens in-context.

Plus:
- [ ] No legacy `store/users.js` based notification code remains in the backend.
- [ ] `eas credentials` reports FCM V1 (not Legacy).
- [ ] DeviceNotRegistered receipts cause token cleanup within 30 min.
- [ ] No secrets (VAPID private key, APNs key) committed to git — checked by `git diff --staged` review pre-push.

---

## 11. QA / Rollout Checklist

Before submitting to TestFlight / Play Store:

**Device matrix** (minimum):
- iOS 17 device, iOS 18 device.
- Android 13 device, Android 14 device, Android 15 emulator.
- Chrome 130+, Firefox 130+, Safari 17+ desktop, Safari 18 iOS as PWA.

**Functional:**
- [ ] Soft-ask sheet shows after first home-tab reach, not on cold start.
- [ ] Granting OS permission registers token within 5s.
- [ ] Denying OS permission does not re-prompt.
- [ ] Killing the app, then sending a DM → wakes app, deep-links correctly.
- [ ] Quiet hours suppress reminders but not messages.
- [ ] Logging out of one device does not break notifications on other devices.

**Regression:**
- [ ] Existing Socket.io message flow still works when app is foregrounded.
- [ ] No crash on iOS when entering app from a notification cold start.
- [ ] Existing Google Maps API key + EAS secrets path untouched.

**Privacy / security:**
- [ ] Push payloads do NOT include message body for "preview off" users (future setting; for v1 we always include preview).
- [ ] No PII in notification logs beyond user id and ticket id.

**Documentation:**
- [ ] Update `docs/docs/releases/vX.Y.Z.md` with screenshots and known issues.
- [ ] Mention "first release of push notifications" in TestFlight / Play Store release notes.

---

## 12. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| FCM credentials still on legacy | M | H — Android push silently broken | Phase 0 verifies; trivial fix via `eas credentials` |
| Existing `expoPushTokens` route has callers in unknown places | L | M — breaks something on rename | `git grep expoPushToken` before deletion; the route writes to a no-op store so callers are already broken |
| Soft-ask fatigue (users ignore it twice) | M | M — install→token conversion drops | 7-day cooldown between soft-asks; contextual triggers |
| Doze delays reminders on Android | M | L — slightly late reminders | Acceptable; copy uses "around" instead of exact time |
| Safari iOS PWA install friction | H | L — fewer web push opt-ins on iOS | This is the platform reality; we surface the install callout but don't block on it |
| Notification spam complaints | L | M — bad reviews | Default cadence = weekly; auto-pause after 60d list inactivity |
| Cross-device idempotency edge | M | M — duplicate reminders | `idempotencyKey` unique index; local + server paths both write it |

---

## 13. Out of scope (revisit in v2 of this feature)

- Comments / likes / follows pushes.
- Rich notifications (images, action buttons beyond snooze).
- Per-conversation mute (mute specific person).
- VIP / Time-Sensitive overrides on iOS.
- Notification inbox / history inside the app.
- Email and SMS fallbacks.
- Reminder content personalization via the trick library (e.g. "this is the easiest unfinished trick on your list").

---

## 14. Sources

Verified during deep research (primary sources unless noted). All accessed June 2026.

1. **Apple — UNNotificationInterruptionLevel** — https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel
2. **Apple — Establishing a token-based connection to APNs** — https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns
3. **Google — Android notification permission (Android 13+)** — https://developer.android.com/develop/ui/views/notifications/notification-permission
4. **Google — Android 14 behavior changes** — https://developer.android.com/about/versions/14/behavior-changes-14
5. **Google — Android 15 behavior changes** — https://developer.android.com/about/versions/15/behavior-changes-15
6. **Google — FCM HTTP v1 migration** — https://firebase.google.com/docs/cloud-messaging/migrate-v1
7. **Expo — Push notifications setup** — https://docs.expo.dev/push-notifications/push-notifications-setup/
8. **Expo — FCM v1 credentials** — https://docs.expo.dev/push-notifications/fcm-credentials
9. **Expo — Sending notifications (Expo proxy)** — https://docs.expo.dev/push-notifications/sending-notifications/
10. **Expo — Sending notifications direct via FCM/APNs** — https://docs.expo.dev/push-notifications/sending-notifications-custom/
11. **Expo — Notifications SDK reference** — https://docs.expo.dev/versions/latest/sdk/notifications/
12. **Expo — Push FAQ** — https://docs.expo.dev/push-notifications/faq/
13. **Expo — expo-server-sdk-node** — https://github.com/expo/expo-server-sdk-node
14. **MDN — PushManager.subscribe()** — https://developer.mozilla.org/en-US/docs/Web/API/PushManager/subscribe
15. **MDN — Notification.requestPermission()** — https://developer.mozilla.org/en-US/docs/Web/API/Notification/requestPermission_static
16. **MDN — Re-engageable Notifications + Push (PWA tutorial)** — https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Tutorials/js13kGames/Re-engageable_Notifications_Push
17. **RFC 8292 — VAPID for Web Push** — https://datatracker.ietf.org/doc/html/rfc8292
18. **GitHub — web-push-libs/web-push** — https://github.com/web-push-libs/web-push

Blog corroboration (used for context, not as sole source for any decision):

- Batch — iOS 18 / Apple Intelligence push impact: https://batch.com/blog/posts/ios18-apple-intelligence-push-notifications-email-marketing
- ProAndroidDev — Full-screen-intent changes Android 14/15: https://proandroiddev.com/full-screen-intent-fsi-notifications-in-android-14-15-what-changed-why-its-breaking-and-e5e862a75936
- MagicBell — PWA iOS limitations: https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide
- OneSignal — iOS Focus modes & interruption levels: https://documentation.onesignal.com/docs/en/ios-focus-modes-and-interruption-levels
- OneSignal — Deliver by timezone: https://onesignal.com/blog/deliver-by-timezone-push-notification/

### Items flagged as best-current-knowledge (not fully verified in research pass)
- iOS 18 specific behavior changes beyond Apple Intelligence summaries — confirm against Apple's What's New in iOS 18 release notes before shipping.
- Exact Safari iOS PWA install requirements (manifest fields, gesture timing) — confirm against current WebKit docs before Phase 4.
- Doze delivery delay numbers (~15 min, up to 2h on aggressive battery) — derived from older Android docs and field reports; treat as approximate.

---

## 15. Decisions (locked 2026-06-14)

1. **Reminder delivery:** Hybrid local + server backfill (Section 6.3).
2. **Permission prompt:** Soft-ask first; no OS prompt on signup.
3. **Web push (Phase 4):** Deferred — not in v2.x.
4. **Reminder defaults:** Weekly cadence per list, quiet hours 21:00–09:00 local. *(Open to override per-user; defaults applied at user creation.)*
5. **v2.x phase scope:** Phases 0, 1, 2, 3, and 5 — messages + reminders in the same release.
