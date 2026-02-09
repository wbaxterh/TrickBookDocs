---
sidebar_position: 6
---

# Structured Logging

TrickBook uses `console.log` with ad-hoc `[API]` prefixes everywhere. There are 410+ console statements in the backend and 54+ in the mobile app. In production, these are unsearchable, unfilterable, and mix debug noise with actual errors.

## The Problem

```javascript
// Current state - scattered across 14+ files
console.log('[Auth] Attempting login for:', email);
console.log('[TrickLists] Fetching:', url);
console.log('[TrickLists] Success, count:', data?.length || 0);
console.error('Error during Google authentication:', error);
console.log('DEBUG Stats - searching for userId:', id);
```

No log levels. No structured output. No way to filter errors from debug noise. Potential PII leaks (logging emails, user IDs).

## Backend: Logger Setup

### Option A: Winston (full-featured)

```bash
cd Backend
npm install winston
```

```javascript
// lib/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    process.env.NODE_ENV === 'production'
      ? winston.format.json()
      : winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        )
  ),
  defaultMeta: { service: 'trickbook-api' },
  transports: [
    new winston.transports.Console(),
  ],
});

module.exports = logger;
```

### Option B: Pino (faster, simpler)

```bash
cd Backend
npm install pino pino-pretty
```

```javascript
// lib/logger.js
const pino = require('pino');

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV !== 'production'
    ? { target: 'pino-pretty' }
    : undefined,
});

module.exports = logger;
```

### Usage

```javascript
const logger = require('../lib/logger');

// Instead of console.log
logger.info('User logged in', { userId: user._id });
logger.warn('Rate limit approaching', { ip: req.ip, count: 90 });
logger.error('Database query failed', { error: err.message, collection: 'users' });

// NEVER log sensitive data
logger.info('Login attempt', { email }); // BAD - PII
logger.info('Login attempt', { userId }); // GOOD - internal ID only
```

### HTTP Request Logging

```bash
npm install morgan
```

```javascript
// index.js
const morgan = require('morgan');
const logger = require('./lib/logger');

// Pipe Morgan through your logger
const morganStream = {
  write: (message) => logger.info(message.trim(), { type: 'http' }),
};

app.use(morgan(':method :url :status :res[content-length] - :response-time ms', {
  stream: morganStream,
}));
```

## Mobile: Logger Setup

For React Native, wrap console with levels and disable in production:

```typescript
// src/lib/logger.ts
type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LOG_LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const currentLevel: LogLevel = __DEV__ ? 'debug' : 'warn';

function shouldLog(level: LogLevel): boolean {
  return LOG_LEVELS[level] >= LOG_LEVELS[currentLevel];
}

export const logger = {
  debug: (message: string, data?: Record<string, unknown>) => {
    if (shouldLog('debug')) console.log(`[DEBUG] ${message}`, data ?? '');
  },
  info: (message: string, data?: Record<string, unknown>) => {
    if (shouldLog('info')) console.log(`[INFO] ${message}`, data ?? '');
  },
  warn: (message: string, data?: Record<string, unknown>) => {
    if (shouldLog('warn')) console.warn(`[WARN] ${message}`, data ?? '');
  },
  error: (message: string, data?: Record<string, unknown>) => {
    if (shouldLog('error')) console.error(`[ERROR] ${message}`, data ?? '');
  },
};
```

In production, only `warn` and `error` output. All the `[API] Fetching...` debug noise is silenced.

## Migration Strategy

Don't rewrite all 400+ console statements at once. Follow this approach:

1. **Add the logger module** to both repos
2. **Update Biome config** to warn on `console.log`
3. **Migrate file-by-file** as you touch code
4. **New code** must use the logger (enforced by lint rule)

The `noConsoleLog` Biome rule will flag every `console.log` as a warning, creating a natural migration pressure.

## Log Levels Guide

| Level | When to Use | Example |
|-------|-------------|---------|
| `error` | Something broke, needs attention | Database connection failed |
| `warn` | Something unexpected but handled | Rate limit approaching |
| `info` | Normal operations worth noting | User logged in, server started |
| `debug` | Detailed info for troubleshooting | API request/response details |
