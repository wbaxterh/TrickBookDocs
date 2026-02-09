---
sidebar_position: 5
---

# Error Handling & Monitoring

TrickBook currently has no error boundaries, no global error handler, and no production error tracking. One uncaught error crashes the entire mobile app with a white screen.

## Mobile: React Native Error Boundary

### Root Error Boundary

Create a root error boundary that catches any unhandled error in the component tree:

```typescript
// src/components/ErrorBoundary.tsx
import React, { Component, ErrorInfo, ReactNode } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import * as Sentry from '@sentry/react-native';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Report to Sentry
    Sentry.captureException(error, { extra: { componentStack: errorInfo.componentStack } });
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback;

      return (
        <View style={styles.container}>
          <Text style={styles.title}>Something went wrong</Text>
          <Text style={styles.message}>The app ran into an unexpected error.</Text>
          <TouchableOpacity style={styles.button} onPress={this.handleReset}>
            <Text style={styles.buttonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return this.props.children;
  }
}
```

### Wrap Root Layout

```typescript
// app/_layout.tsx
import { ErrorBoundary } from '@/components/ErrorBoundary';

export default function RootLayout() {
  return (
    <ErrorBoundary>
      <Providers>
        <Stack />
      </Providers>
    </ErrorBoundary>
  );
}
```

## Backend: Global Error Handler

### Error Handler Middleware

Currently every route handles errors independently with try/catch. Add a centralized handler:

```javascript
// middleware/errorHandler.js
const Sentry = require('@sentry/node');

const errorHandler = (err, req, res, next) => {
  // Report to Sentry
  Sentry.captureException(err);

  // Log structured error
  console.error({
    message: err.message,
    stack: err.stack,
    method: req.method,
    path: req.path,
    userId: req.user?._id,
    timestamp: new Date().toISOString(),
  });

  // Operational errors (expected)
  if (err.isOperational) {
    return res.status(err.statusCode || 400).json({
      error: err.message,
    });
  }

  // Programming errors (unexpected) - don't leak details
  res.status(500).json({
    error: 'Internal server error',
  });
};

module.exports = errorHandler;
```

### Register as Last Middleware

```javascript
// index.js
const errorHandler = require('./middleware/errorHandler');

// ... all routes ...

// Must be AFTER all routes
app.use(errorHandler);
```

### Custom Error Class

```javascript
// utils/AppError.js
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
```

Usage in routes:

```javascript
const AppError = require('../utils/AppError');

router.get('/trick/:id', auth, async (req, res, next) => {
  try {
    const trick = await db.collection('tricks').findOne({ _id: id });
    if (!trick) throw new AppError('Trick not found', 404);
    res.json(trick);
  } catch (error) {
    next(error); // Passes to global error handler
  }
});
```

## Sentry Integration

### Mobile Setup

```bash
cd TrickList
npx expo install @sentry/react-native
```

```typescript
// app/_layout.tsx
import * as Sentry from '@sentry/react-native';

Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  environment: __DEV__ ? 'development' : 'production',
  tracesSampleRate: 0.2,
  enableAutoSessionTracking: true,
});
```

### Backend Setup

```bash
cd Backend
npm install @sentry/node
```

```javascript
// index.js (top of file, before other imports)
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV || 'development',
  tracesSampleRate: 0.2,
});

// After Express app is created
Sentry.setupExpressErrorHandler(app);
```

### What Sentry Captures

| Event | Mobile | Backend |
|-------|--------|---------|
| Unhandled exceptions | Yes | Yes |
| Unhandled promise rejections | Yes | Yes |
| HTTP errors (4xx, 5xx) | Via interceptor | Via middleware |
| Slow transactions | Yes (traces) | Yes (traces) |
| User context | Attached via Sentry.setUser() | Attached via middleware |
| Release tracking | Via EAS build | Via deploy tag |

### Sentry Environment Variables

Add to `.env.example` for both repos:

```bash
# TrickList
EXPO_PUBLIC_SENTRY_DSN=https://xxx@o123.ingest.sentry.io/456

# Backend
SENTRY_DSN=https://xxx@o123.ingest.sentry.io/789
```

## Backend: Graceful Shutdown

The backend currently has no shutdown handling. Abrupt stops can corrupt WebSocket connections and leave database operations incomplete.

```javascript
// index.js
const { closeConnection } = require('./db');

const gracefulShutdown = async (signal) => {
  console.log(`Received ${signal}. Starting graceful shutdown...`);

  // Stop accepting new connections
  server.close(async () => {
    console.log('HTTP server closed');

    // Close Socket.IO connections
    io.close();
    console.log('Socket.IO closed');

    // Close database connection
    await closeConnection();
    console.log('Database connection closed');

    process.exit(0);
  });

  // Force shutdown after 10 seconds
  setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
```

## Backend: Health Check Endpoint

Add a health check for load balancers and monitoring:

```javascript
// routes/health.js
router.get('/health', async (req, res) => {
  try {
    // Check database connectivity
    const db = await getDb();
    await db.command({ ping: 1 });

    res.json({
      status: 'healthy',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: 'Database connection failed',
    });
  }
});
```
