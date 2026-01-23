---
sidebar_position: 4
---

# Media

Video streaming platform featuring The Couch (curated films) and Feed (user content).

## Overview

Media is TrickBook's video and content platform with two main sections:

1. **The Couch** - Curated action sports films, documentaries, and professional edits
2. **Feed** - User-generated content with social features (reactions, comments)

## The Couch

### Overview

The Couch is a streaming platform for full-length action sports videos, hosted on Bunny.net CDN with HLS adaptive streaming.

### Frontend Implementation (Website)

**Location:** `/pages/media/`

| File | Purpose |
|------|---------|
| `index.js` | Media hub with tabs for Couch/Feed |
| `couch/index.js` | The Couch video library |
| `couch/[id].js` | Individual video player page |

**Components:**

| Component | Location | Purpose |
|-----------|----------|---------|
| `VideoCard.js` | `/components/media/VideoCard.js` | Video thumbnail with metadata |
| `VideoPlayer.js` | `/components/media/VideoPlayer.js` | HLS video player with controls |
| `VideoFilters.js` | `/components/media/VideoFilters.js` | Filter by sport, type, year |

**Key Features:**
- HLS adaptive bitrate streaming
- Sport type filtering (skateboarding, snowboarding, surfing, BMX)
- Content type filtering (film, documentary, contest, part)
- Featured videos carousel
- Video reactions (love, respect)
- View count tracking
- Responsive video player

### Video Player Implementation

**File:** `/components/media/VideoPlayer.js`

```javascript
import Hls from "hls.js";
import { useRef, useEffect } from "react";

export default function VideoPlayer({ src, poster, autoPlay, controls }) {
  const videoRef = useRef(null);

  useEffect(() => {
    const video = videoRef.current;
    if (!video || !src) return;

    if (src.includes(".m3u8") && Hls.isSupported()) {
      const hls = new Hls({
        maxLoadingDelay: 4,
        maxBufferLength: 30,
        maxBufferSize: 60 * 1000 * 1000,
      });
      hls.loadSource(src);
      hls.attachMedia(video);
      return () => hls.destroy();
    } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
      // Safari native HLS support
      video.src = src;
    }
  }, [src]);

  return (
    <video
      ref={videoRef}
      poster={poster}
      autoPlay={autoPlay}
      controls={controls}
      playsInline
      className="w-full h-full object-contain"
    />
  );
}
```

### Admin Panel

**Location:** `/pages/admin/couch/`

| File | Purpose |
|------|---------|
| `index.js` | Video management list |
| `new.js` | Add new video |
| `edit/[id].js` | Edit video details |

**Admin Features:**
- YouTube metadata import (title, description, thumbnail)
- Direct video upload to Bunny.net
- Thumbnail upload to S3 (file upload or URL)
- Sport type and tag management
- Featured video toggle
- Publish/unpublish controls
- Rider and sponsor credits

**Thumbnail Upload Implementation:**

```javascript
// File upload to S3
const handleThumbnailUpload = async (e) => {
  const file = e.target.files?.[0];
  if (!file) return;

  // Validate
  if (!file.type.startsWith("image/")) {
    setError("Please select an image file");
    return;
  }
  if (file.size > 5 * 1024 * 1024) {
    setError("Thumbnail must be less than 5MB");
    return;
  }

  setUploadingThumbnail(true);
  const result = await uploadImageToS3(file, token, setThumbnailProgress);

  setFormData(prev => ({
    ...prev,
    thumbnails: { ...prev.thumbnails, poster: result.fileUrl }
  }));
  setUploadingThumbnail(false);
};
```

### Backend Implementation

**Collection: `couch_videos`**

```javascript
{
  _id: ObjectId,
  title: String,
  description: String,

  // Classification
  sportTypes: [String],        // ["skateboarding", "snowboarding"]
  type: String,                // "film", "documentary", "part", "contest"
  tags: [String],              // ["street", "vert", "classic"]

  // Credits
  releaseYear: Number,
  producedBy: String,
  riders: [String],
  sponsors: [String],
  duration: Number,            // Seconds

  // Video Sources
  bunnyVideoId: String,        // Bunny.net video ID
  hlsUrl: String,              // HLS playlist URL
  driveFileId: String,         // Legacy Google Drive
  driveThumbnail: String,      // Legacy thumbnail
  youtubeUrl: String,          // YouTube link (fallback)

  // Thumbnails
  thumbnails: {
    poster: String,            // S3 URL - main thumbnail
    backdrop: String           // S3 URL - wide banner
  },

  // Stats
  stats: {
    viewCount: Number,
    loveCount: Number,
    respectCount: Number,
    commentCount: Number
  },

  // Publishing
  isPublished: Boolean,
  isFeatured: Boolean,

  createdAt: Date,
  updatedAt: Date
}
```

### API Endpoints (The Couch)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/media/couch` | List videos with filters | No |
| GET | `/media/couch/:id` | Get video details | No |
| GET | `/media/couch/:id/stream` | Get stream URL | No |
| POST | `/media/couch/:id/view` | Increment view count | No |
| POST | `/media/couch/:id/reaction` | Add reaction | JWT |
| DELETE | `/media/couch/:id/reaction` | Remove reaction | JWT |
| POST | `/media/couch` | Create video (admin) | Admin |
| PUT | `/media/couch/:id` | Update video (admin) | Admin |
| DELETE | `/media/couch/:id` | Delete video (admin) | Admin |

### Bunny.net Integration

**Video Upload Flow:**

1. Admin enters video title
2. Backend creates Bunny video entry via API
3. Frontend uploads file directly to Bunny.net
4. Bunny processes and creates HLS streams
5. Backend stores `bunnyVideoId` and `hlsUrl`

**File:** `/lib/apiMedia.js`

```javascript
export async function createBunnyVideo(title, token) {
  const response = await axios.post(
    `${API_BASE}/media/couch/bunny/create`,
    { title },
    { headers: { "x-auth-token": token } }
  );
  return response.data;  // { guid, libraryId, uploadKey, cdnHostname }
}
```

**Backend Bunny API Call:**

```javascript
// Create video in Bunny library
const bunnyResponse = await axios.post(
  `https://video.bunnycdn.com/library/${BUNNY_LIBRARY_ID}/videos`,
  { title },
  { headers: { AccessKey: BUNNY_API_KEY } }
);

return {
  guid: bunnyResponse.data.guid,
  libraryId: BUNNY_LIBRARY_ID,
  uploadKey: BUNNY_API_KEY,
  cdnHostname: BUNNY_CDN_HOSTNAME
};
```

---

## Feed

### Overview

The Feed is a user-generated content platform where riders can share clips, photos, and updates with the community.

### Frontend Implementation (Website)

**Location:** `/pages/media/`

| File | Purpose |
|------|---------|
| `feed/index.js` | Main feed view |
| `feed/[id].js` | Individual post page |
| `feed/upload.js` | Upload new post |

**Components:**

| Component | Location | Purpose |
|-----------|----------|---------|
| `FeedPost.js` | `/components/media/FeedPost.js` | Post card with media, reactions, comments |
| `VideoPlayer.js` | `/components/media/VideoPlayer.js` | Video player with autoplay on scroll |
| `CommentSection.js` | `/components/media/CommentSection.js` | Comments with replies |
| `ReactionBar.js` | `/components/media/ReactionBar.js` | Love/respect buttons |

**Key Features:**
- Video and image posts
- Autoplay videos when in viewport (IntersectionObserver)
- Audio on by default for feed videos
- Love and Respect reactions
- Comments with nested replies
- Trick tags linking to Trickipedia
- Sport type tags
- User profile links
- Share and save functionality

### FeedPost Component

**File:** `/components/media/FeedPost.js`

```javascript
export default function FeedPost({ post, onReaction, autoPlay = false }) {
  const [loved, setLoved] = useState(post.userReactions?.includes("love"));
  const [respected, setRespected] = useState(post.userReactions?.includes("respect"));
  const [showComments, setShowComments] = useState(false);
  const [isInView, setIsInView] = useState(false);
  const containerRef = useRef(null);

  // Autoplay when in viewport
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => setIsInView(entry.isIntersecting && entry.intersectionRatio >= 0.5),
      { threshold: 0.5 }
    );
    if (containerRef.current) observer.observe(containerRef.current);
    return () => observer.disconnect();
  }, []);

  const handleReaction = async (type) => {
    // Optimistic update
    if (type === "love") {
      setLoved(!loved);
      setLoveCount(c => loved ? c - 1 : c + 1);
    }
    // ... API call with rollback on error
  };

  return (
    <div ref={containerRef}>
      {/* Creator header */}
      {/* Video/Image content */}
      <VideoPlayer
        src={post.hlsUrl || post.videoUrl}
        poster={post.thumbnailUrl}
        autoPlay={autoPlay && isInView}
        controls
      />
      {/* Reaction bar */}
      {/* Comments section */}
    </div>
  );
}
```

### Backend Implementation (Feed)

**Collection: `feed_posts`**

```javascript
{
  _id: ObjectId,
  user: ObjectId,              // Post author

  // Content
  mediaType: String,           // "video", "image"
  caption: String,

  // Video fields
  videoUrl: String,            // Direct video URL
  hlsUrl: String,              // HLS stream URL
  thumbnailUrl: String,
  aspectRatio: String,         // "9:16", "16:9", "1:1"
  duration: Number,

  // Image fields
  imageUrls: [String],         // Multiple images

  // Tags
  tricks: [String],            // Trick names (link to Trickipedia)
  sportTypes: [String],
  location: {
    name: String,
    coordinates: [Number]      // [lng, lat]
  },

  // Stats
  stats: {
    loveCount: Number,
    respectCount: Number,
    commentCount: Number,
    shareCount: Number,
    viewCount: Number
  },

  // Privacy
  visibility: String,          // "public", "homies", "private"

  createdAt: Date,
  updatedAt: Date
}
```

**Collection: `feed_reactions`**

```javascript
{
  _id: ObjectId,
  postId: ObjectId,
  userId: ObjectId,
  type: String,                // "love", "respect"
  createdAt: Date
}
// Index: { postId: 1, userId: 1, type: 1 } unique
```

**Collection: `feed_comments`**

```javascript
{
  _id: ObjectId,
  postId: ObjectId,
  userId: ObjectId,
  content: String,
  parentCommentId: ObjectId,   // For replies (null if top-level)

  // Stats
  loveCount: Number,
  replyCount: Number,

  isDeleted: Boolean,          // Soft delete
  createdAt: Date,
  updatedAt: Date
}
```

### API Endpoints (Feed)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/feed` | Get feed posts (paginated) | No |
| GET | `/feed/:id` | Get single post | No |
| POST | `/feed` | Create post | JWT |
| DELETE | `/feed/:id` | Delete post | JWT |
| POST | `/feed/:id/reaction` | Add reaction | JWT |
| DELETE | `/feed/:id/reaction/:type` | Remove reaction | JWT |
| GET | `/feed/:id/comments` | Get comments | No |
| POST | `/feed/:id/comments` | Add comment | JWT |
| DELETE | `/feed/:id/comments/:commentId` | Delete comment | JWT |
| POST | `/feed/:id/comments/:commentId/love` | Love comment | JWT |

### Real-Time Comments (Socket.IO)

**Events:**

| Event | Direction | Description |
|-------|-----------|-------------|
| `join:post` | Client → Server | Subscribe to post comments |
| `leave:post` | Client → Server | Unsubscribe |
| `comment:new` | Server → Client | New comment added |
| `comment:deleted` | Server → Client | Comment removed |
| `reaction:update` | Server → Client | Reaction count changed |

---

## Video Upload Pipeline

### User Upload Flow (Feed)

1. User selects video file
2. Frontend validates (format, size, duration)
3. Create feed post entry in database
4. Upload video to Bunny.net via TUS protocol
5. Bunny processes video (transcoding, HLS)
6. Backend updates post with stream URLs
7. Post appears in feed

### TUS Upload Implementation

**File:** `/lib/apiUpload.js`

```javascript
export async function uploadVideoTUS(file, credentials, onProgress) {
  const tus = await import("tus-js-client");

  return new Promise((resolve, reject) => {
    const upload = new tus.Upload(file, {
      endpoint: credentials.tusEndpoint,
      retryDelays: [0, 3000, 5000, 10000, 20000],
      headers: {
        AuthorizationSignature: credentials.headers.AuthorizationSignature,
        AuthorizationExpire: credentials.headers.AuthorizationExpire,
        VideoId: credentials.headers.VideoId,
        LibraryId: credentials.headers.LibraryId,
      },
      metadata: {
        filename: file.name,
        filetype: file.type,
      },
      onProgress: (bytesUploaded, bytesTotal) => {
        const percentage = (bytesUploaded / bytesTotal) * 100;
        onProgress?.(percentage);
      },
      onSuccess: () => resolve({ videoId: credentials.videoId, success: true }),
      onError: (error) => reject(error),
    });

    upload.findPreviousUploads().then((previousUploads) => {
      if (previousUploads.length > 0) {
        upload.resumeFromPreviousUpload(previousUploads[0]);
      }
      upload.start();
    });
  });
}
```

---

## Infrastructure

### Video Hosting: Bunny.net

- **Library ID:** Configured in environment
- **CDN Hostname:** `{library}.b-cdn.net`
- **Features:** HLS adaptive streaming, global CDN, thumbnails

### Image Storage: AWS S3

- **Bucket:** `trickbook`
- **Paths:** `/feed/{postId}/`, `/couch/{videoId}/`
- **Access:** Public read via bucket policy

### Environment Variables

```bash
# Bunny.net
BUNNY_API_KEY=xxx
BUNNY_LIBRARY_ID=xxx
BUNNY_CDN_HOSTNAME=xxx.b-cdn.net

# AWS S3
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
AWS_S3_BUCKET=trickbook
AWS_REGION=us-east-1
```

---

## Mobile Considerations

### Video Playback
- Use `expo-av` for video playback
- HLS support via native players
- Background audio handling
- Picture-in-picture (future)

### Feed Optimization
- Preload next videos
- Pause off-screen videos
- Cache thumbnails
- Infinite scroll pagination

### Upload
- Background upload support
- Progress tracking
- Resume interrupted uploads
- Compress before upload

## Related Documentation

- [API Endpoints](/docs/backend/api-endpoints) - Full API reference
- [Authentication](/docs/backend/authentication) - JWT auth
- [Deployment](/docs/deployment/backend) - Server configuration
