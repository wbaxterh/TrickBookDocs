---
sidebar_position: 3
---

# Data Flow

How data moves through the TrickBook application.

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant Zustand as Zustand Store
    participant Backend
    participant DB as MongoDB

    User->>App: Enter email & password
    App->>Backend: POST /api/auth
    Backend->>DB: Find user by email
    DB-->>Backend: User document
    Backend->>Backend: bcrypt.compare(password)
    Backend-->>App: JWT token + user data
    App->>Zustand: authStore.login(token, user)
    Zustand->>Zustand: SecureStore.setItem(token)
    Zustand->>Zustand: Set user state
    App-->>User: Navigate to (tabs) layout
```

## App Startup Flow

```typescript
// app/_layout.tsx - Simplified
const RootLayout = () => {
  const { user, isLoading, loadStoredAuth } = useAuthStore();

  useEffect(() => {
    loadStoredAuth(); // Restore token from SecureStore
  }, []);

  if (isLoading) return <SplashScreen />;

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <Stack>
          {user ? (
            <Stack.Screen name="(tabs)" />
          ) : (
            <Stack.Screen name="(auth)" />
          )}
        </Stack>
      </ThemeProvider>
    </QueryClientProvider>
  );
};
```

## Data Fetching with React Query

All API data flows through React Query for caching, deduplication, and automatic refetching.

```typescript
// Example: Fetching trick lists
const { data: trickLists, isLoading, refetch } = useQuery({
  queryKey: ['trickLists'],
  queryFn: () => trickbookApi.getTrickLists(),
  staleTime: 5 * 60 * 1000, // 5 minutes
});

// Example: Creating a trick list (mutation)
const createMutation = useMutation({
  mutationFn: (data: CreateTrickListData) =>
    trickbookApi.createTrickList(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['trickLists'] });
  },
});
```

```
React Query Cache Flow:

Component mounts → Check cache
    │
    ├── Cache fresh → Return cached data
    │
    ├── Cache stale → Return cached data + refetch in background
    │
    └── No cache → Fetch from API
                       │
                       ▼
                  apiClient.get('/listings')
                       │
                       ▼
                  Auto-inject x-auth-token header
                       │
                       ▼
                  Return data → Cache → Component
```

## Trick List Data Flow

### Creating a Trick List

```
1. User taps "+" button
           │
           ▼
2. Form with React Hook Form + Zod validation
           │
           ▼
3. useMutation → POST /api/listings
   { name: "Kickflips to learn" }
           │
           ▼
4. Backend creates in MongoDB
   db.tricklists.insertOne({...})
           │
           ▼
5. Return { _id, name, tricks: [] }
           │
           ▼
6. Invalidate ['trickLists'] query → auto-refetch
           │
           ▼
7. Navigate to trick list detail screen
```

### Tracking Trick Progress

```
PUT /api/listing/{trickId}
{
  checked: "Landed"  // "Not Started" | "Learning" | "Landed" | "Mastered"
}
           │
           ▼
Update in MongoDB
           │
           ▼
Invalidate query cache
           │
           ▼
Update StatusBadge + ProgressBar UI
```

## Social Feed Data Flow

### Creating a Post

```mermaid
sequenceDiagram
    participant User
    participant App
    participant API as Backend API
    participant S3 as AWS S3
    participant Bunny as Bunny.net
    participant DB as MongoDB
    participant Socket as Socket.IO

    User->>App: Record/select video
    App->>API: POST /api/upload (video file)
    API->>Bunny: Upload to Bunny.net CDN
    Bunny-->>API: Video URL + thumbnail
    API-->>App: Media URLs
    App->>API: POST /api/feed/posts
    API->>DB: Insert feed_post
    API->>Socket: Emit new post event
    Socket-->>App: Real-time feed update
```

### Feed Algorithm Scoring

```
Feed posts are ranked by a scoring algorithm:

score = (engagement * 0.35) + (recency * 0.25) +
        (completion * 0.25) + (interaction * 0.15)

Homie boost: Posts from friends get 2.5x multiplier
Recency: 48-hour half-life decay
```

## Image Upload Flow

```mermaid
flowchart TD
    A[User selects image] --> B[expo-image-picker]
    B --> C[expo-image-manipulator]
    C --> D["Resize + compress"]
    D --> E[Create FormData]
    E --> F["POST /api/image/upload"]
    F --> G[multer parses multipart]
    G --> H[multer-s3 streams to S3]
    H --> I[(AWS S3)]
    I --> J[Return S3 URL]
    J --> K[Update record in MongoDB]
    K --> L[Display new image]
```

## Direct Messaging Flow

```mermaid
sequenceDiagram
    participant UserA as User A
    participant AppA as App A
    participant Socket as Socket.IO
    participant API as Backend
    participant DB as MongoDB
    participant AppB as App B
    participant UserB as User B

    UserA->>AppA: Type message
    AppA->>Socket: Emit typing indicator
    Socket-->>AppB: Show "typing..."
    UserA->>AppA: Send message
    AppA->>API: POST /api/dm/messages
    API->>DB: Insert dm_message
    API->>Socket: Emit new message
    Socket-->>AppB: Real-time message delivery
    AppB-->>UserB: Show new message
    UserB->>AppB: Read message
    AppB->>API: PUT /api/dm/messages/:id/read
```

## Subscription Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant API as Backend API
    participant Stripe
    participant DB as MongoDB

    User->>App: Tap "Upgrade"
    App->>API: POST /api/payments/create-checkout-session
    API->>Stripe: Create checkout session
    Stripe-->>API: Session URL
    API-->>App: Redirect URL
    App->>Stripe: Open Stripe Checkout
    User->>Stripe: Complete payment
    Stripe->>API: Webhook: invoice.paid
    API->>DB: Update user.subscription
    Note over DB: plan: "premium"<br/>status: "active"
    App->>API: Next API request
    API->>API: Subscription middleware check
    API-->>App: Premium features enabled
```

## Real-Time Data Flow

```
Socket.IO Connection Lifecycle:

App Launch
    │
    ▼
Connect to Socket.IO server
    │
    ├── Auth: Pass JWT in handshake
    │
    ├── /feed namespace
    │       │
    │       ├── Join room: user:{userId}
    │       ├── Listen: 'post:update' → update React Query cache
    │       ├── Listen: 'reaction:update' → update reaction counts
    │       └── Listen: 'comment:new' → show notification
    │
    └── /messages namespace
            │
            ├── Join room: user:{userId}
            ├── Listen: 'message:new' → add to conversation
            ├── Listen: 'typing' → show indicator
            └── Listen: 'read' → update read receipts
```

## API Request Pattern

All authenticated requests flow through a custom fetch client:

```typescript
// src/lib/api/client.ts
const apiClient = {
  get: async (url: string) => {
    const token = await SecureStore.getItemAsync('authToken');
    const response = await fetch(`${BASE_URL}${url}`, {
      headers: {
        'x-auth-token': token ?? '',
        'Content-Type': 'application/json',
      },
    });
    return response.json();
  },
  // post, put, delete follow same pattern
};
```

Features:
- Auto-injects auth token from Secure Store
- Retry logic (3 attempts with 1s delay)
- Custom timeouts (30s default, 120s for uploads)
- Environment-aware base URL (dev vs production)
