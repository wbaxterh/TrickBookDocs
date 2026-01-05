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
    participant Backend
    participant DB as MongoDB

    User->>App: Enter email & password
    App->>Backend: POST /api/auth
    Backend->>DB: Find user by email
    DB-->>Backend: User document
    Backend->>Backend: bcrypt.compare(password)
    Backend-->>App: JWT token
    App->>App: jwt-decode (extract user data)
    App->>App: SecureStore.setItem(token)
    App->>App: setUser(decoded)
    App-->>User: Navigate to AppNavigator
```

## App Startup Flow

```javascript
// App.js - Simplified
const App = () => {
  const [user, setUser] = useState();
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    restoreToken();
  }, []);

  const restoreToken = async () => {
    const token = await authStorage.getToken();
    if (token) {
      const decoded = jwtDecode(token);
      const userProfile = await usersApi.getUser(decoded.email);
      setUser({ ...decoded, ...userProfile.data });
    }
    setIsReady(true);
  };

  if (!isReady) return <SplashScreen />;

  return (
    <AuthContext.Provider value={{ user, setUser }}>
      {user ? <AppNavigator /> : <AuthNavigator />}
    </AuthContext.Provider>
  );
};
```

## Trick List Data Flow

### Creating a Trick List

```
1. User taps "+" button
           │
           ▼
2. CreateTrickListScreen renders
           │
           ▼
3. User enters list name
           │
           ▼
4. Formik validates with Yup schema
           │
           ▼
5. POST /api/listings
   {
     name: "Kickflips to learn",
     user: "userId"
   }
           │
           ▼
6. Backend creates in MongoDB
   db.tricklists.insertOne({...})
           │
           ▼
7. Return { _id, name, tricks: [] }
           │
           ▼
8. Navigate to TrickListScreen
```

### Adding a Trick

```
1. User on TrickListScreen
           │
           ▼
2. Tap "Add Trick" button
           │
           ▼
3. AddTrickScreen modal
           │
           ▼
4. Enter trick name
           │
           ▼
5. PUT /api/listing
   {
     list_id: "listId",
     name: "Kickflip",
     checked: false
   }
           │
           ▼
6. Backend adds to tricks array
           │
           ▼
7. Return updated list
           │
           ▼
8. UI updates with new trick
```

### Checking Off a Trick

```
PUT /api/listing/{trickId}
{
  checked: true
}
           │
           ▼
Update in MongoDB
           │
           ▼
Recalculate completion %
           │
           ▼
Update RoundedLineBar UI
```

## Image Upload Flow

```mermaid
flowchart TD
    A[User selects image] --> B[expo-image-picker]
    B --> C[expo-image-manipulator]
    C --> D["Resize to 640px<br/>Compress to 0.2 quality"]
    D --> E[Create FormData]
    E --> F["POST /api/image/upload"]
    F --> G[multer parses multipart]
    G --> H[multer-s3 streams to S3]
    H --> I[(AWS S3)]
    I --> J[Return S3 URL]
    J --> K[Update user.imageUri in MongoDB]
    K --> L[Display new profile image]
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

## Guest Mode Data Flow

Guest mode stores data locally without backend sync:

```javascript
// AsyncStorage key: @guest_trick_list
{
  tricks: [
    { id: 1, name: "Kickflip", checked: false },
    { id: 2, name: "Heelflip", checked: true }
  ]
}
```

```
Guest adds trick
       │
       ▼
AsyncStorage.setItem('@guest_trick_list', JSON.stringify(list))
       │
       ▼
On app restart
       │
       ▼
AsyncStorage.getItem('@guest_trick_list')
       │
       ▼
Restore local state
```

## API Request Pattern

All authenticated requests follow this pattern:

```javascript
// app/api/client.js
const apiClient = create({
  baseURL: "https://api.thetrickbook.com/api",
});

// Usage in components
const response = await tricksApi.getTricks(userId);

if (!response.ok) {
  // Handle error
  return;
}

// Use response.data
setTricks(response.data);
```

Response format:
```javascript
{
  ok: true,           // Success indicator
  data: [...],        // Response payload
  status: 200,        // HTTP status
  problem: null       // Error type if failed
}
```
