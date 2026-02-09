---
sidebar_position: 3
---

# Authentication

TrickBook uses JWT-based authentication with Google SSO and Apple Sign-In.

## Authentication Methods

### 1. Email/Password

Traditional email and password authentication with bcrypt hashing.

```javascript
// Registration - password hashing
const salt = await bcrypt.genSalt(10);
const hashedPassword = await bcrypt.hash(password, salt);

// Login - password verification
const validPassword = await bcrypt.compare(password, user.password);
```

### 2. Google SSO

OAuth2 authentication using Google Identity Services. Supports web, iOS, and Android clients.

```javascript
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Verify Google ID token (accepts multiple client IDs)
const ticket = await client.verifyIdToken({
  idToken: googleIdToken,
  audience: [
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_IOS_CLIENT_ID,
    process.env.GOOGLE_ANDROID_CLIENT_ID,
  ]
});

const { email, name, picture } = ticket.getPayload();
```

- Auto-creates user if email doesn't exist
- Updates profile on subsequent logins

### 3. Apple Sign-In

Apple identity token verification using `apple-signin-auth`.

```javascript
const appleSignin = require('apple-signin-auth');

// Verify Apple identity token
const appleUser = await appleSignin.verifyIdToken(identityToken);
const { email, sub: appleUserId } = appleUser;

// Link Apple ID to existing email or create new user
// Fallback name: "Apple User" (Apple only sends name on first auth)
```

- Links `appleUserId` to existing email accounts
- Supports first-time and returning Apple auth flows

## JWT Token Structure

Tokens are generated using the `jsonwebtoken` package:

```javascript
const jwt = require('jsonwebtoken');

const token = jwt.sign(
  {
    _id: user._id,
    name: user.name,
    email: user.email,
    imageUri: user.imageUri,
    role: user.role
  },
  'jwtPrivateKey'  // Should be env variable!
);
```

:::danger Security Issue
The JWT secret is currently hardcoded as `"jwtPrivateKey"`. This must be changed to use `process.env.JWT_SECRET`.
:::

### Token Payload

```json
{
  "_id": "user_object_id",
  "name": "John Doe",
  "email": "john@example.com",
  "imageUri": "https://s3.amazonaws.com/...",
  "role": "admin"  // or null for regular users
}
```

:::warning Missing Expiration
Tokens currently have no expiration. Should add:
```javascript
jwt.sign(payload, secret, { expiresIn: '1h' });
```
:::

## Middleware

### Basic Auth (`middleware/auth.js`)

Validates JWT token on protected routes.

```javascript
const auth = (req, res, next) => {
  const token = req.header("x-auth-token");

  if (!token) {
    return res.status(401).send("Access denied. No token provided.");
  }

  try {
    const decoded = jwt.verify(token, "jwtPrivateKey");
    req.user = decoded;
    next();
  } catch (error) {
    res.status(400).send("Invalid token.");
  }
};
```

**Usage:**
```javascript
router.get('/protected', auth, (req, res) => {
  // req.user contains decoded token
  res.json({ userId: req.user._id });
});
```

### Admin Auth (`middleware/authAdmin.js`)

Extends basic auth to require admin role.

```javascript
const authAdmin = async (req, res, next) => {
  const token = req.header("x-auth-token");

  if (!token) {
    return res.status(401).send("Access denied.");
  }

  try {
    const decoded = jwt.verify(token, "jwtPrivateKey");

    // Check admin role in database
    const user = await db.collection("users").findOne({
      _id: new ObjectId(decoded._id)
    });

    if (user.role !== "admin") {
      return res.status(403).send("Access denied. Admin only.");
    }

    req.user = decoded;
    next();
  } catch (error) {
    res.status(400).send("Invalid token.");
  }
};
```

:::note Performance Issue
Admin check queries the database on every request. Consider caching or including role in JWT payload with short expiration.
:::

### Account or Admin (`middleware/authAccountOrAdmin.js`)

Allows access if user is the account owner OR an admin.

```javascript
const authAccountOrAdmin = async (req, res, next) => {
  // Uses Authorization: Bearer token
  const authHeader = req.header("Authorization");
  const token = authHeader?.replace("Bearer ", "");

  const decoded = jwt.verify(token, "jwtPrivateKey");

  // Allow if admin
  const user = await db.collection("users").findOne({...});
  if (user.role === "admin") {
    return next();
  }

  // Allow if account owner
  if (decoded.email === req.body.email ||
      decoded._id === req.params.id) {
    return next();
  }

  return res.status(403).send("Access denied.");
};
```

### Subscription Check (`middleware/subscription.js`)

Enforces freemium limits on certain endpoints.

```javascript
const checkSubscription = async (req, res, next) => {
  const user = await db.collection("users").findOne({
    _id: new ObjectId(req.user._id)
  });

  // Premium users bypass all limits
  if (user.subscription?.plan === "premium" &&
      user.subscription?.status === "active") {
    return next();
  }

  // Check limits for free users
  const spotListCount = await db.collection("spotlists")
    .countDocuments({ userId: req.user._id });

  if (spotListCount >= 3) {
    return res.status(403).json({
      error: "Upgrade to premium for unlimited spot lists"
    });
  }

  next();
};
```

## Token Storage (Mobile App)

The mobile app stores tokens securely using Expo Secure Store:

```javascript
// app/auth/storage.js
import * as SecureStore from 'expo-secure-store';

const key = 'authToken';

const storeToken = async (authToken) => {
  await SecureStore.setItemAsync(key, authToken);
};

const getToken = async () => {
  return await SecureStore.getItemAsync(key);
};

const removeToken = async () => {
  await SecureStore.deleteItemAsync(key);
};
```

## Request Flow

```
Client                              Server
  │                                   │
  │─── POST /api/auth ───────────────▶│
  │    {email, password}              │
  │                                   │
  │                          ┌────────┴────────┐
  │                          │ Verify password │
  │                          │ Generate JWT    │
  │                          └────────┬────────┘
  │                                   │
  │◀──── {token: "eyJ..."} ───────────│
  │                                   │
  │ Store in Secure Store             │
  │                                   │
  │─── GET /api/listings ────────────▶│
  │    x-auth-token: eyJ...           │
  │                                   │
  │                          ┌────────┴────────┐
  │                          │ auth middleware │
  │                          │ Verify JWT      │
  │                          │ Set req.user    │
  │                          └────────┬────────┘
  │                                   │
  │◀──── [list data] ─────────────────│
```

## Role-Based Access Control

Current roles:
- `null` - Regular user
- `"admin"` - Full access to admin endpoints

Admin-only endpoints:
- `POST /api/trickipedia` - Create tricks
- `PUT /api/trickipedia/:id` - Update tricks
- `DELETE /api/trickipedia/:id` - Delete tricks
- `POST /api/blog` - Create blog posts
- `PATCH /api/blog/:id` - Update blog posts
- `DELETE /api/blog/:id` - Delete blog posts

## Security Recommendations

1. **Use environment variable for JWT secret**
   ```javascript
   jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });
   ```

2. **Add token expiration**
   ```javascript
   { expiresIn: '1h' }  // or '7d' with refresh tokens
   ```

3. **Implement refresh tokens** for better security

4. **Add rate limiting** on auth endpoints
   ```javascript
   const rateLimit = require('express-rate-limit');

   const authLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 5 // 5 attempts
   });

   router.post('/auth', authLimiter, loginHandler);
   ```

5. **Hash sensitive data** in JWT payload or use opaque tokens
