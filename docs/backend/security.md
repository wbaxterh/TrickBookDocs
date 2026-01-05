---
sidebar_position: 5
---

# Security

Current security status and required improvements for the TrickBook backend.

## Critical Issues

:::danger Immediate Action Required
The following issues must be addressed before any further development.
:::

### 1. Exposed Credentials

**Status:** CRITICAL

The `.env` file contains plaintext credentials that may be committed to git:

```bash
# EXPOSED - Rotate these immediately
ATLAS_URI=mongodb+srv://[REDACTED]@cluster.mongodb.net/...
AWS_KEY=[REDACTED]
AWS_SECRET=[REDACTED]
EMAIL_PASSWORD=[REDACTED]
```

**Fix:**
1. Rotate ALL credentials immediately
2. Add `.env` to `.gitignore`
3. Use secrets manager (AWS Secrets Manager, Doppler, etc.)
4. Create `.env.example` with placeholder values

### 2. Hardcoded JWT Secret

**Status:** CRITICAL

```javascript
// Current code - INSECURE
jwt.sign(payload, "jwtPrivateKey");
```

**Fix:**
```javascript
jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });
```

### 3. No Token Expiration

**Status:** CRITICAL

JWT tokens never expire, meaning a leaked token grants permanent access.

**Fix:**
```javascript
const token = jwt.sign(payload, process.env.JWT_SECRET, {
  expiresIn: '1h'  // Short-lived access token
});

// Implement refresh tokens for better UX
const refreshToken = jwt.sign(
  { _id: user._id },
  process.env.REFRESH_SECRET,
  { expiresIn: '7d' }
);
```

### 4. End-of-Life Node.js

**Status:** CRITICAL

Node.js 12.6.x reached end-of-life in April 2022. No security patches available.

**Fix:**
```json
// package.json
{
  "engines": {
    "node": ">=18.0.0"
  }
}
```

---

## High Priority Issues

### 5. Outdated helmet

**Current:** 3.22.0 (2019)
**Latest:** 7.x

Missing security headers and protections.

**Fix:**
```bash
npm install helmet@latest
```

```javascript
const helmet = require('helmet');
app.use(helmet());
```

### 6. No Rate Limiting

Login and API endpoints have no protection against brute force attacks.

**Fix:**
```bash
npm install express-rate-limit
```

```javascript
const rateLimit = require('express-rate-limit');

// Strict limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: 'Too many login attempts, try again later'
});

router.post('/auth', authLimiter, loginHandler);

// General API limit
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100
});

app.use('/api/', apiLimiter);
```

### 7. CORS Wildcard

**Current:**
```javascript
app.use(cors());  // Allows all origins
```

**Fix:**
```javascript
const corsOptions = {
  origin: [
    'https://thetrickbook.com',
    'https://www.thetrickbook.com',
    'https://admin.thetrickbook.com'
  ],
  credentials: true
};

app.use(cors(corsOptions));
```

### 8. Unrestricted Public Endpoints

These endpoints expose data without authentication:

| Endpoint | Risk |
|----------|------|
| `GET /api/users/all` | Exposes all user emails |
| `GET /api/listings/all` | Exposes all user data |
| `GET /api/spots` | May be intentional |

**Fix:** Add authentication or remove if not needed.

---

## Medium Priority Issues

### 9. Weak Password Requirements

**Current:**
```javascript
password: Joi.string().min(5).required()
```

**Fix:**
```javascript
password: Joi.string()
  .min(8)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
  .required()
  .messages({
    'string.pattern.base': 'Password must contain uppercase, lowercase, and number'
  })
```

### 10. No Input Sanitization

User input used directly in regex patterns:

```javascript
// Vulnerable
{ name: { $regex: userInput, $options: "i" } }
```

**Fix:**
```javascript
const escapeRegex = (str) => str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

{ name: { $regex: escapeRegex(userInput), $options: "i" } }
```

### 11. Missing HTTPS Redirect

Ensure all traffic uses HTTPS:

```javascript
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    return res.redirect(`https://${req.header('host')}${req.url}`);
  }
  next();
});
```

### 12. No Request Size Limits

Large payloads could cause DoS:

```javascript
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ limit: '10kb', extended: true }));
```

---

## Security Checklist

### Authentication
- [ ] Move JWT secret to environment variable
- [ ] Add token expiration (1 hour)
- [ ] Implement refresh tokens
- [ ] Add password complexity requirements
- [ ] Add account lockout after failed attempts

### Authorization
- [ ] Review all public endpoints
- [ ] Add authentication to `/api/users/all`
- [ ] Verify admin checks on all admin routes

### Network
- [ ] Update CORS whitelist
- [ ] Add rate limiting
- [ ] Enforce HTTPS
- [ ] Add request size limits

### Dependencies
- [ ] Upgrade Node.js to 18+
- [ ] Update helmet to 7.x
- [ ] Update jsonwebtoken to 9.x
- [ ] Update joi to 17.x
- [ ] Run `npm audit` and fix vulnerabilities

### Credentials
- [ ] Rotate MongoDB password
- [ ] Rotate AWS access keys
- [ ] Rotate email password
- [ ] Create new JWT secret
- [ ] Add `.env` to `.gitignore`
- [ ] Set up secrets manager

### Monitoring
- [ ] Add error logging (Winston/Pino)
- [ ] Set up Sentry for error tracking
- [ ] Monitor for suspicious activity
- [ ] Set up alerts for failed auth attempts

---

## Secure Configuration Template

```javascript
// index.js - Secure setup

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();

// Security headers
app.use(helmet());

// CORS whitelist
app.use(cors({
  origin: ['https://thetrickbook.com'],
  credentials: true
}));

// Rate limiting
app.use(rateLimit({
  windowMs: 60 * 1000,
  max: 100
}));

// Request size limits
app.use(express.json({ limit: '10kb' }));

// HTTPS redirect (behind proxy)
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    return res.redirect(301, `https://${req.header('host')}${req.url}`);
  }
  next();
});

// Validate required env vars
const required = ['ATLAS_URI', 'JWT_SECRET', 'AWS_KEY'];
required.forEach(key => {
  if (!process.env[key]) {
    console.error(`Missing required env var: ${key}`);
    process.exit(1);
  }
});
```
