---
sidebar_position: 2
---

# API Endpoints

Live route signatures from the backend implementation in `/Users/weshuber/Reactnative/Backend/routes/*.js`.

Base URL: `https://api.thetrickbook.com/api`

## Conventions

- Authenticated routes use `x-auth-token: <jwt>`.
- Some route files include admin/account checks in middleware; see the route file for exact authorization rules.
- This page documents implemented signatures (method + path), not payload schema details.

## Auth (`/api/auth`)

- `POST /api/auth`
- `POST /api/auth/google-auth`
- `POST /api/auth/apple-auth`

## User Profile (`/api/user`)

- `GET /api/user/me`
- `GET /api/user/count`
- `GET /api/user/:id`
- `GET /api/user/:id/public`
- `GET /api/user/:id/stats`
- `PUT /api/user/:id`
- `GET /api/user/:id/activity`
- `GET /api/user/homie-status/:targetId`

## Users And Network (`/api/users`)

- `POST /api/users`
- `GET /api/users`
- `GET /api/users/all`
- `DELETE /api/users/:id`
- `POST /api/users/forgot-password`
- `POST /api/users/reset-password`
- `GET /api/users/network-status`
- `PUT /api/users/:id/network`
- `GET /api/users/discoverable`
- `POST /api/users/:id/homie-request`
- `POST /api/users/:id/accept-homie`
- `POST /api/users/:id/reject-homie`
- `GET /api/users/homies`
- `GET /api/users/homie-requests`
- `DELETE /api/users/homie/:id`
- `GET /api/users/homie-status/:targetId`

## Trick Lists (`/api/listings`)

- `GET /api/listings`
- `GET /api/listings/countTrickLists`
- `POST /api/listings`
- `DELETE /api/listings/:id`
- `PUT /api/listings/edit`
- `GET /api/listings/all`
- `GET /api/listings/public`
- `PUT /api/listings/:id/visibility`

## Tricks In Lists (`/api/listing`)

- `GET /api/listing`
- `GET /api/listing/allData`
- `GET /api/listing/allTricks`
- `GET /api/listing/graph`
- `DELETE /api/listing/:id`
- `PUT /api/listing/edit`
- `PUT /api/listing/update`
- `PUT /api/listing`

## Trickipedia (`/api/trickipedia`)

- `GET /api/trickipedia`
- `GET /api/trickipedia/category/:category`
- `GET /api/trickipedia/:id`
- `POST /api/trickipedia`
- `PUT /api/trickipedia/:id`
- `DELETE /api/trickipedia/:id`

## Categories (`/api/categories`)

- `GET /api/categories`
- `GET /api/categories/:id`
- `POST /api/categories`
- `PUT /api/categories/:id`
- `DELETE /api/categories/:id`

## Spots (`/api/spots`)

- `GET /api/spots/sport-types`
- `GET /api/spots/places-search`
- `GET /api/spots/places/:placeId`
- `GET /api/spots/reverse-geocode`
- `POST /api/spots`
- `POST /api/spots/bulk`
- `GET /api/spots`
- `GET /api/spots/all`
- `GET /api/spots/pending`
- `GET /api/spots/search`
- `GET /api/spots/my-spots`
- `GET /api/spots/:id`
- `PUT /api/spots/:id`
- `PUT /api/spots/:id/approve`
- `PUT /api/spots/:id/reject`
- `DELETE /api/spots/:id`
- `GET /api/spots/:id/lists`
- `GET /api/spots/:id/places-info`
- `GET /api/spots/:id/photos`
- `POST /api/spots/:id/photos`
- `DELETE /api/spots/:id/photos/:photoKey`

## Spot Lists (`/api/spotlists`)

- `POST /api/spotlists`
- `GET /api/spotlists/usage`
- `GET /api/spotlists`
- `GET /api/spotlists/:id`
- `PUT /api/spotlists/:id`
- `DELETE /api/spotlists/:id`
- `POST /api/spotlists/:id/spots`
- `DELETE /api/spotlists/:id/spots/:spotId`
- `GET /api/spotlists/:id/spots`

## Spot Reviews (`/api/spot-reviews`)

- `GET /api/spot-reviews/:spotId`
- `POST /api/spot-reviews`
- `PUT /api/spot-reviews/:reviewId`
- `DELETE /api/spot-reviews/:reviewId`
- `POST /api/spot-reviews/:reviewId/helpful`
- `GET /api/spot-reviews/user/:userId`

## Feed (`/api/feed`)

- `GET /api/feed`
- `GET /api/feed/trending`
- `GET /api/feed/user/:userId`
- `GET /api/feed/sport/:sportType`
- `GET /api/feed/:postId`
- `GET /api/feed/:postId/stream`
- `GET /api/feed/debug-token/:videoId`
- `POST /api/feed`
- `PUT /api/feed/:postId`
- `DELETE /api/feed/:postId`
- `POST /api/feed/:postId/reaction`
- `DELETE /api/feed/:postId/reaction/:type`
- `GET /api/feed/:postId/comments`
- `POST /api/feed/:postId/comments`
- `DELETE /api/feed/:postId/comments/:commentId`
- `GET /api/feed/:postId/comments/:commentId/replies`
- `POST /api/feed/:postId/comments/:commentId/love`
- `POST /api/feed/:postId/save`
- `GET /api/feed/saved`
- `POST /api/feed/:postId/view`
- `POST /api/feed/:postId/report`

## Direct Messages (`/api/dm`)

- `GET /api/dm/conversations`
- `GET /api/dm/conversations/:conversationId`
- `GET /api/dm/conversations/:conversationId/messages`
- `POST /api/dm/conversations`
- `POST /api/dm/conversations/:conversationId/messages`
- `PUT /api/dm/conversations/:conversationId/read`
- `GET /api/dm/unread-count`

## Media Library (`/api/media`)

- `GET /api/media/library`
- `GET /api/media/library/:id`
- `GET /api/media/featured`
- `GET /api/media/collections`
- `GET /api/media/collections/:id`
- `GET /api/media/search`
- `POST /api/media/library/:id/rate`
- `POST /api/media/library/:id/view`
- `GET /api/media/library/:id/related`
- `GET /api/media/library/sport/:sportType`
- `POST /api/media/library`
- `PUT /api/media/library/:id`
- `DELETE /api/media/library/:id`
- `POST /api/media/collections`

## The Couch (`/api/couch`)

- `GET /api/couch/videos`
- `GET /api/couch/featured`
- `GET /api/couch/videos/:id`
- `GET /api/couch/videos/:id/stream`
- `GET /api/couch/collections`
- `GET /api/couch/collections/:id`
- `GET /api/couch/videos/:id/reaction`
- `POST /api/couch/videos/:id/reaction`
- `DELETE /api/couch/videos/:id/reaction/:type`
- `GET /api/couch/videos/:id/comments`
- `POST /api/couch/videos/:id/comments`
- `DELETE /api/couch/videos/:videoId/comments/:commentId`
- `POST /api/couch/requests`
- `GET /api/couch/requests/mine`
- `POST /api/couch/admin/sync`
- `GET /api/couch/admin/videos`
- `POST /api/couch/admin/youtube-metadata`
- `POST /api/couch/admin/bunny/create-video`
- `GET /api/couch/admin/bunny/upload-url/:bunnyVideoId`
- `GET /api/couch/admin/bunny/video/:bunnyVideoId`
- `POST /api/couch/admin/videos`
- `PUT /api/couch/admin/videos/:id`
- `DELETE /api/couch/admin/videos/:id`
- `POST /api/couch/admin/collections`
- `PUT /api/couch/admin/collections/:id`
- `GET /api/couch/admin/requests`
- `PUT /api/couch/admin/requests/:id`

## Upload (`/api/upload`)

- `POST /api/upload/video/create`
- `GET /api/upload/video/:videoId/status`
- `DELETE /api/upload/video/:videoId`
- `POST /api/upload/video/:videoId/thumbnail`
- `GET /api/upload/videos`
- `POST /api/upload/image/presign`
- `POST /api/upload/image/base64`
- `DELETE /api/upload/image`

## Payments (`/api/payments`)

- `POST /api/payments/create-checkout-session`
- `GET /api/payments/subscription`
- `POST /api/payments/admin/toggle-subscription`
- `POST /api/payments/cancel-subscription`
- `POST /api/payments/reactivate-subscription`
- `POST /api/payments/webhook`

## Blog (`/api/blog`)

- `POST /api/blog`
- `GET /api/blog`
- `GET /api/blog/:id`
- `GET /api/blog/url/:url`
- `PATCH /api/blog/update/:id`
- `PATCH /api/blog/:id`
- `DELETE /api/blog/:id`

## Image Upload Routes

### Profile Image (`/api/image`)

- `GET /api/image`
- `POST /api/image`

### Trick Images (`/api/trickImage`)

- `POST /api/trickImage/upload`
- `DELETE /api/trickImage/delete-folder/:slug`

### Blog Images (`/api/blogImage`)

- `POST /api/blogImage/upload`
- `DELETE /api/blogImage/delete-folder/:slug`

## Utility And Legacy

- `GET /api/messages`
- `POST /api/messages`
- `GET /api/my/listings`
- `POST /api/expoPushTokens`
- `POST /api/contact/send-email`
- `POST /api/newsletter/subscribe`
- `GET /api/newsletter/stats`
- `POST /api/newsletter/unsubscribe`

## Socket.IO Namespaces

- `/feed`
- `/messages`

Common event patterns implemented in socket handlers:
- Feed rooms/events: `join:post`, `leave:post`, `comment:new`, `comment:deleted`, `comment:loved`
- Messaging rooms/events: `join:conversation`, `leave:conversation`, `typing:start`, `typing:stop`, `message:new`, `messages:read`
