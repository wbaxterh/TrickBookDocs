---
sidebar_position: 3
---

# Homies

Social networking and friend connections for action sports riders.

## Overview

Homies is TrickBook's social feature that allows users to connect with other riders, follow their progress, and communicate directly. Users can send homie requests, exchange direct messages, and see their friends' activity in the feed.

## Frontend Implementation

### Website (Next.js)

**Location:** `/pages/`

| File | Purpose |
|------|---------|
| `homies/index.js` | Homies list and discovery page |
| `profile/[id].js` | User profile with homie status |
| `messages/index.js` | Conversation list (DMs) |
| `messages/[conversationId].js` | Individual chat view |

**Components:**

| Component | Location | Purpose |
|-----------|----------|---------|
| `HomieCard.js` | `/components/HomieCard.js` | User preview card with action buttons |
| `HomieRequestCard.js` | `/components/HomieRequestCard.js` | Pending request with accept/decline |
| `UserSearchBar.js` | `/components/UserSearchBar.js` | Search for users to add as homies |
| `ChatBubble.js` | `/components/messages/ChatBubble.js` | Message bubble (sent/received) |
| `ConversationItem.js` | `/components/messages/ConversationItem.js` | Conversation preview in list |
| `TypingIndicator.js` | `/components/messages/TypingIndicator.js` | Shows when other user is typing |

**Key Features:**
- Homie request system (send, accept, decline)
- User search and discovery
- Direct messaging between homies
- Real-time message delivery (Socket.IO)
- Typing indicators
- Read receipts
- Unread message badges
- Online/offline status

### Mobile App (React Native)

**Location:** `/TrickList/screens/`

| Screen | Purpose |
|--------|---------|
| `HomiesScreen.js` | List of homies with search |
| `HomieRequestsScreen.js` | Pending homie requests |
| `UserProfileScreen.js` | View other user's profile |
| `MessagesScreen.js` | Conversation list |
| `ChatScreen.js` | Individual chat view |

**Push Notifications:**
- New homie request received
- Homie request accepted
- New message received

## Backend Implementation

### Database Schema

**Collection: `users`** (Homies stored as array)

```javascript
{
  _id: ObjectId,
  name: String,
  email: String,
  imageUri: String,
  // ... other user fields

  // Homies system
  homies: [ObjectId],           // Accepted homie user IDs
  homieRequests: {
    sent: [ObjectId],           // Requests sent by this user
    received: [ObjectId]        // Requests received by this user
  },

  // Privacy settings
  privacy: {
    profileVisibility: String,  // "public", "homies", "private"
    allowMessages: String,      // "everyone", "homies", "none"
    showOnlineStatus: Boolean
  },

  // Activity
  lastSeen: Date,
  isOnline: Boolean
}
```

**Collection: `conversations`**

```javascript
{
  _id: ObjectId,
  participants: [ObjectId, ObjectId],  // Sorted user IDs for consistent lookup
  lastMessage: {
    content: String,
    senderId: ObjectId,
    createdAt: Date
  },
  unreadCount: {
    [userId]: Number              // Unread count per participant
  },
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `{ participants: 1 }` - Find conversations by users
- `{ updatedAt: -1 }` - Sort by recent activity

**Collection: `messages`**

```javascript
{
  _id: ObjectId,
  conversationId: ObjectId,
  senderId: ObjectId,
  content: String,
  status: String,                // "sent", "delivered", "read"
  readAt: Date,                  // When recipient read message
  createdAt: Date
}
```

**Indexes:**
- `{ conversationId: 1, createdAt: 1 }` - Messages in conversation order

### API Endpoints

**Base URL:** `https://api.thetrickbook.com/api`

#### Homies

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/user/homies` | Get current user's homies | JWT |
| GET | `/user/homie-requests` | Get pending requests | JWT |
| POST | `/user/homie-request/:userId` | Send homie request | JWT |
| PUT | `/user/homie-request/:userId/accept` | Accept request | JWT |
| PUT | `/user/homie-request/:userId/decline` | Decline request | JWT |
| DELETE | `/user/homie/:userId` | Remove homie | JWT |
| GET | `/users/search` | Search users by name/email | JWT |
| GET | `/users/:id/profile` | Get user's public profile | JWT |

#### Direct Messages

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/dm/conversations` | List user's conversations | JWT |
| GET | `/dm/conversations/:id` | Get conversation details | JWT |
| GET | `/dm/conversations/:id/messages` | Get messages (paginated) | JWT |
| POST | `/dm/conversations` | Start new conversation | JWT |
| POST | `/dm/conversations/:id/messages` | Send message | JWT |
| PUT | `/dm/conversations/:id/read` | Mark as read | JWT |
| GET | `/dm/unread-count` | Get total unread count | JWT |

### Routes Implementation

**File:** `/Backend/routes/user.js` (Homies)

```javascript
// Send homie request
router.post("/homie-request/:userId", auth, async (req, res) => {
  const targetUser = await User.findById(req.params.userId);
  if (!targetUser) return res.status(404).json({ error: "User not found" });

  // Check if already homies
  if (req.user.homies.includes(req.params.userId)) {
    return res.status(400).json({ error: "Already homies" });
  }

  // Check if request already sent
  if (req.user.homieRequests.sent.includes(req.params.userId)) {
    return res.status(400).json({ error: "Request already sent" });
  }

  // Add to sent/received arrays
  await User.findByIdAndUpdate(req.user._id, {
    $addToSet: { "homieRequests.sent": req.params.userId }
  });

  await User.findByIdAndUpdate(req.params.userId, {
    $addToSet: { "homieRequests.received": req.user._id }
  });

  // Send push notification
  await sendPushNotification(targetUser.expoPushToken, {
    title: "New Homie Request",
    body: `${req.user.name} wants to be your homie!`
  });

  res.json({ success: true });
});

// Accept homie request
router.put("/homie-request/:userId/accept", auth, async (req, res) => {
  // Add to both users' homies arrays
  await User.findByIdAndUpdate(req.user._id, {
    $addToSet: { homies: req.params.userId },
    $pull: { "homieRequests.received": req.params.userId }
  });

  await User.findByIdAndUpdate(req.params.userId, {
    $addToSet: { homies: req.user._id },
    $pull: { "homieRequests.sent": req.user._id }
  });

  res.json({ success: true });
});
```

**File:** `/Backend/routes/dm.js` (Direct Messages)

```javascript
// Start or get existing conversation
router.post("/conversations", auth, async (req, res) => {
  const { targetUserId } = req.body;

  // Verify users are homies (only homies can message)
  const user = await User.findById(req.user._id);
  if (!user.homies.includes(targetUserId)) {
    return res.status(403).json({ error: "Can only message homies" });
  }

  // Sort participant IDs for consistent lookup
  const participants = [req.user._id, targetUserId].sort();

  // Find existing or create new
  let conversation = await Conversation.findOne({ participants });

  if (!conversation) {
    conversation = await Conversation.create({
      participants,
      unreadCount: { [req.user._id]: 0, [targetUserId]: 0 }
    });
  }

  res.json(conversation);
});

// Send message
router.post("/conversations/:id/messages", auth, async (req, res) => {
  const { content } = req.body;
  const conversation = await Conversation.findById(req.params.id);

  // Create message
  const message = await Message.create({
    conversationId: req.params.id,
    senderId: req.user._id,
    content,
    status: "sent"
  });

  // Update conversation
  const otherUserId = conversation.participants.find(
    p => p.toString() !== req.user._id.toString()
  );

  await Conversation.findByIdAndUpdate(req.params.id, {
    lastMessage: { content, senderId: req.user._id, createdAt: new Date() },
    $inc: { [`unreadCount.${otherUserId}`]: 1 },
    updatedAt: new Date()
  });

  // Emit via Socket.IO for real-time delivery
  io.to(`user:${otherUserId}`).emit("message:new", message);

  res.json(message);
});
```

## Real-Time Communication (Socket.IO)

### Server Setup

**File:** `/Backend/socket/index.js`

```javascript
const socketIO = require("socket.io");
const jwt = require("jsonwebtoken");

function initializeSocket(server) {
  const io = socketIO(server, {
    cors: {
      origin: ["https://thetrickbook.com", "http://localhost:3000"],
      credentials: true
    }
  });

  // JWT authentication middleware
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.user.id;
      next();
    } catch (err) {
      next(new Error("Authentication error"));
    }
  });

  io.on("connection", (socket) => {
    // Join user's personal room
    socket.join(`user:${socket.userId}`);

    // Update online status
    User.findByIdAndUpdate(socket.userId, { isOnline: true, lastSeen: new Date() });

    // Handle typing indicators
    socket.on("typing:start", ({ conversationId }) => {
      socket.to(`conversation:${conversationId}`).emit("typing:start", {
        userId: socket.userId
      });
    });

    socket.on("typing:stop", ({ conversationId }) => {
      socket.to(`conversation:${conversationId}`).emit("typing:stop", {
        userId: socket.userId
      });
    });

    // Join conversation room
    socket.on("join:conversation", ({ conversationId }) => {
      socket.join(`conversation:${conversationId}`);
    });

    socket.on("disconnect", () => {
      User.findByIdAndUpdate(socket.userId, { isOnline: false, lastSeen: new Date() });
    });
  });

  return io;
}
```

### Client Setup (Next.js)

**File:** `/lib/socket.js`

```javascript
import { io } from "socket.io-client";

let socket = null;

export function connectSocket(token) {
  if (socket?.connected) return socket;

  socket = io(process.env.NEXT_PUBLIC_SOCKET_URL, {
    auth: { token },
    transports: ["websocket", "polling"]
  });

  return socket;
}

export function disconnectSocket() {
  socket?.disconnect();
  socket = null;
}

export function getSocket() {
  return socket;
}
```

### Socket Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `message:new` | Server → Client | New message received |
| `typing:start` | Bidirectional | User started typing |
| `typing:stop` | Bidirectional | User stopped typing |
| `messages:read` | Server → Client | Messages marked as read |
| `homie:request` | Server → Client | New homie request |
| `homie:accepted` | Server → Client | Homie request accepted |

## Privacy & Security

### Message Privacy
- Only homies can send messages
- Messages encrypted in transit (TLS)
- No message content logged on server

### Blocking (Future)
- Block users from sending requests
- Block from viewing profile
- Remove from homies list

### Reporting (Future)
- Report inappropriate messages
- Report user profiles
- Admin review queue

## Mobile Considerations

### Push Notifications
- New homie request
- Request accepted
- New message (when app backgrounded)
- Badge count for unread messages

### Background Message Sync
- Sync messages when app opens
- Show notification badges
- Local notification for new messages

### Offline Mode
- Queue outgoing messages
- Show pending status
- Sync when connection restored

## UI/UX Patterns

### Homie Request Flow
1. User searches for rider
2. Taps "Add Homie" button
3. Request sent, button shows "Pending"
4. Target user sees request in notifications
5. Accept/Decline options
6. Both users now see each other as homies

### Message Read Receipts
- Single checkmark: Sent
- Double checkmark: Delivered
- Yellow checkmarks: Read

## Related Documentation

- [Authentication](/docs/backend/authentication) - JWT and user auth
- [Backend Overview](/docs/backend/overview) - Backend architecture and integrations
- [API Endpoints](/docs/backend/api-endpoints) - Full API reference
