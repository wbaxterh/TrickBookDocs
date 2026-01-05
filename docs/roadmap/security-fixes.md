---
sidebar_position: 2
---

# Security Fixes

Detailed guide for addressing security vulnerabilities in TrickBook.

## Critical: Credential Rotation

### 1. MongoDB Atlas Password

1. Log into [MongoDB Atlas](https://cloud.mongodb.com)
2. Go to **Database Access**
3. Edit user → **Edit Password**
4. Generate new secure password
5. Update `ATLAS_URI` in production environment

```bash
# New connection string format
mongodb+srv://[user]:[NEW_PASSWORD]@cluster.mongodb.net/TrickList2
```

### 2. AWS Access Keys

1. Log into [AWS Console](https://console.aws.amazon.com)
2. Go to **IAM** → **Users** → Your user
3. **Security credentials** → **Create access key**
4. Delete old access key
5. Update environment variables:

```bash
AWS_KEY=[your-new-aws-access-key]
AWS_SECRET=[your-new-aws-secret-key]
```

### 3. Email Password

1. Go to email provider settings
2. Generate new app-specific password
3. Update `EMAIL_PASSWORD` in environment

### 4. JWT Secret

Generate cryptographically secure secret:

```bash
# Generate 32-byte random secret
openssl rand -base64 32
# Example output: K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=
```

Update in environment:
```bash
JWT_SECRET=K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=
```

---

## Critical: JWT Security

### Current Issue

```javascript
// INSECURE - Current code
jwt.sign(payload, "jwtPrivateKey");
```

### Fix: Environment Variable + Expiration

```javascript
// middleware/auth.js - Updated
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}

// Token generation (in auth route)
const generateToken = (user) => {
  return jwt.sign(
    {
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role
    },
    JWT_SECRET,
    { expiresIn: '1h' }  // Token expires in 1 hour
  );
};

// Token verification (in middleware)
const auth = (req, res, next) => {
  const token = req.header('x-auth-token');

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
};
```

### Mobile App: Handle Token Expiration

```javascript
// app/api/client.js
import authStorage from '../auth/storage';
import jwtDecode from 'jwt-decode';

const isTokenExpired = (token) => {
  try {
    const decoded = jwtDecode(token);
    return decoded.exp * 1000 < Date.now();
  } catch {
    return true;
  }
};

// Check token before requests
const checkAuth = async () => {
  const token = await authStorage.getToken();

  if (!token || isTokenExpired(token)) {
    // Redirect to login
    await authStorage.removeToken();
    return null;
  }

  return token;
};
```

---

## Critical: Node.js Upgrade

### Current: Node.js 12.6.x (EOL)

### Target: Node.js 18 LTS or 20 LTS

### Steps

1. **Update package.json**:
```json
{
  "engines": {
    "node": ">=18.0.0"
  }
}
```

2. **Test locally**:
```bash
# Install Node 18 via nvm
nvm install 18
nvm use 18

# Install dependencies
rm -rf node_modules package-lock.json
npm install

# Run and test
npm start
```

3. **Fix compatibility issues**:
   - Most packages should work
   - Check for deprecated APIs
   - Update any native modules

4. **Update CI/CD**:
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '18'
```

5. **Update hosting**:
   - Railway/Render auto-detect from package.json
   - For VPS: Install Node 18

---

## High: Update Security Packages

### helmet (v3 → v7)

```bash
npm install helmet@latest
```

```javascript
// index.js
const helmet = require('helmet');

app.use(helmet());

// Or with custom configuration
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false,
}));
```

### jsonwebtoken (v8 → v9)

```bash
npm install jsonwebtoken@latest
```

No code changes needed, API is compatible.

### joi (v14 → v17)

```bash
npm install joi@latest
```

Minor syntax changes:
```javascript
// Old (v14)
const schema = Joi.object().keys({
  email: Joi.string().email().required()
});

// New (v17) - same, but some methods renamed
const schema = Joi.object({
  email: Joi.string().email().required()
});
```

---

## High: Rate Limiting

### Install

```bash
npm install express-rate-limit
```

### Configure

```javascript
// middleware/rateLimiter.js
const rateLimit = require('express-rate-limit');

// Strict limit for authentication
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: {
    error: 'Too many login attempts. Please try again in 15 minutes.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// General API limit
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: {
    error: 'Too many requests. Please slow down.'
  },
});

// Strict limit for registration
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 registrations per hour per IP
  message: {
    error: 'Too many accounts created. Please try again later.'
  },
});

module.exports = { authLimiter, apiLimiter, registerLimiter };
```

### Apply

```javascript
// index.js
const { authLimiter, apiLimiter, registerLimiter } = require('./middleware/rateLimiter');

// Apply to all API routes
app.use('/api/', apiLimiter);

// routes/auth.js
router.post('/', authLimiter, loginHandler);

// routes/users.js
router.post('/', registerLimiter, registerHandler);
```

---

## High: CORS Whitelist

### Current (Insecure)

```javascript
app.use(cors()); // Allows all origins
```

### Fixed

```javascript
const corsOptions = {
  origin: function (origin, callback) {
    const whitelist = [
      'https://thetrickbook.com',
      'https://www.thetrickbook.com',
      'https://admin.thetrickbook.com',
      // Add localhost for development
      process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : null
    ].filter(Boolean);

    if (!origin || whitelist.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'x-auth-token', 'Authorization']
};

app.use(cors(corsOptions));
```

---

## Medium: Centralize Database Connection

### Current Anti-Pattern

```javascript
// Every route file does this
const client = new MongoClient(process.env.ATLAS_URI);
await client.connect();
const db = client.db('TrickList2');
```

### Fixed: Connection Pool

```javascript
// db.js
const { MongoClient } = require('mongodb');

let client = null;
let db = null;

async function connectToDatabase() {
  if (db) return db;

  client = new MongoClient(process.env.ATLAS_URI, {
    maxPoolSize: 10,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
  });

  await client.connect();
  db = client.db('TrickList2');

  console.log('Connected to MongoDB');
  return db;
}

async function getDb() {
  if (!db) {
    await connectToDatabase();
  }
  return db;
}

async function closeConnection() {
  if (client) {
    await client.close();
    client = null;
    db = null;
  }
}

module.exports = { getDb, connectToDatabase, closeConnection };
```

### Usage in Routes

```javascript
// routes/users.js
const { getDb } = require('../db');

router.get('/', async (req, res) => {
  try {
    const db = await getDb();
    const users = await db.collection('users').find().toArray();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Database error' });
  }
});
```

### Initialize on Startup

```javascript
// index.js
const { connectToDatabase } = require('./db');

const startServer = async () => {
  await connectToDatabase();

  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
};

startServer().catch(console.error);
```

---

## Medium: Environment Validation

```javascript
// config/validateEnv.js
const required = [
  'ATLAS_URI',
  'JWT_SECRET',
  'AWS_KEY',
  'AWS_SECRET',
  'STRIPE_SECRET_KEY'
];

const validateEnv = () => {
  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.error('Missing required environment variables:');
    missing.forEach(key => console.error(`  - ${key}`));
    process.exit(1);
  }

  // Validate JWT_SECRET length
  if (process.env.JWT_SECRET.length < 32) {
    console.error('JWT_SECRET must be at least 32 characters');
    process.exit(1);
  }
};

module.exports = validateEnv;
```

```javascript
// index.js
require('dotenv').config();
const validateEnv = require('./config/validateEnv');

validateEnv(); // Exit if missing env vars

// ... rest of app
```

---

## Security Checklist

### Immediate (Today)
- [ ] Rotate MongoDB password
- [ ] Rotate AWS access keys
- [ ] Generate new JWT secret
- [ ] Add `.env` to `.gitignore`

### This Week
- [ ] Update JWT to use env variable
- [ ] Add token expiration
- [ ] Upgrade Node.js to 18+
- [ ] Update helmet to v7

### This Sprint
- [ ] Add rate limiting
- [ ] Fix CORS whitelist
- [ ] Centralize DB connection
- [ ] Add environment validation
- [ ] Add structured logging

### Ongoing
- [ ] Regular dependency updates (`npm audit`)
- [ ] Security testing
- [ ] Penetration testing (annual)
- [ ] Code reviews for security
