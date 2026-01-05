---
sidebar_position: 3
---

# Efficiency Improvements

Recommendations for faster workflows and production deployments.

## Development Workflow

### 1. Unified Monorepo Structure

Current structure works but could be improved:

```
/TrickBook (root)
├── apps/
│   ├── mobile/          # React Native app
│   └── web/             # Website (if applicable)
├── packages/
│   ├── api/             # Backend API
│   ├── shared/          # Shared types/utilities
│   └── ui/              # Shared UI components
├── docs/                # Documentation
└── package.json         # Workspace root
```

Benefits:
- Shared dependencies
- Unified versioning
- Single CI/CD pipeline
- Code sharing between apps

### 2. TypeScript Migration

Add TypeScript incrementally:

```bash
# Mobile app
cd TrickList
npm install typescript @types/react @types/react-native

# Create tsconfig.json
npx tsc --init
```

Start with new files, migrate existing gradually:
```
app/
├── api/
│   ├── client.js       # Existing
│   └── users.ts        # New TypeScript
```

### 3. Shared Configuration

Create shared ESLint/Prettier configs:

```javascript
// .eslintrc.js (root)
module.exports = {
  extends: ['eslint:recommended'],
  rules: {
    // Shared rules
  }
};

// Backend/.eslintrc.js
module.exports = {
  extends: ['../.eslintrc.js'],
  env: { node: true }
};

// TrickList/.eslintrc.js
module.exports = {
  extends: ['../.eslintrc.js', '@react-native-community']
};
```

---

## CI/CD Optimization

### 1. Parallel Builds

```yaml
# .github/workflows/ci.yml
jobs:
  backend-test:
    runs-on: ubuntu-latest
    # ...

  mobile-lint:
    runs-on: ubuntu-latest
    # ...

  # Run in parallel, deploy after both pass
  deploy:
    needs: [backend-test, mobile-lint]
    # ...
```

### 2. Caching Strategy

```yaml
# Cache node_modules
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
      */node_modules
    key: ${{ runner.os }}-modules-${{ hashFiles('**/package-lock.json') }}

# Cache Expo/EAS
- uses: actions/cache@v4
  with:
    path: |
      ~/.expo
      ~/.eas
    key: ${{ runner.os }}-expo-${{ hashFiles('**/package-lock.json') }}
```

### 3. Conditional Builds

Only build what changed:

```yaml
on:
  push:
    paths:
      - 'Backend/**'
      - '.github/workflows/backend.yml'

# Or use path filtering
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      backend: ${{ steps.filter.outputs.backend }}
      mobile: ${{ steps.filter.outputs.mobile }}
    steps:
      - uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            backend:
              - 'Backend/**'
            mobile:
              - 'TrickList/**'

  backend:
    needs: changes
    if: ${{ needs.changes.outputs.backend == 'true' }}
    # ...
```

### 4. Preview Deployments

Deploy PRs to preview environments:

```yaml
# For backend
- name: Deploy preview
  if: github.event_name == 'pull_request'
  run: |
    railway up --environment pr-${{ github.event.number }}

# For mobile
- name: Build preview
  if: github.event_name == 'pull_request'
  run: |
    eas build --profile preview --message "PR #${{ github.event.number }}"
```

---

## Backend Performance

### 1. Connection Pooling

Already covered in security fixes. Benefits:
- Reduced connection overhead
- Better resource utilization
- Faster response times

### 2. Add Caching Layer

```bash
npm install node-cache
```

```javascript
// cache.js
const NodeCache = require('node-cache');

const cache = new NodeCache({
  stdTTL: 300,      // 5 minute default TTL
  checkperiod: 60   // Check for expired keys every 60s
});

// Usage in routes
router.get('/categories', async (req, res) => {
  const cacheKey = 'categories';

  // Check cache first
  const cached = cache.get(cacheKey);
  if (cached) {
    return res.json(cached);
  }

  // Fetch from database
  const db = await getDb();
  const categories = await db.collection('categories').find().toArray();

  // Store in cache
  cache.set(cacheKey, categories);

  res.json(categories);
});
```

### 3. Database Indexes

Ensure proper indexes exist:

```javascript
// scripts/createIndexes.js
const { getDb } = require('../db');

async function createIndexes() {
  const db = await getDb();

  // Users
  await db.collection('users').createIndex({ email: 1 }, { unique: true });

  // Trick lists
  await db.collection('tricklists').createIndex({ user: 1 });

  // Trickipedia
  await db.collection('trickipedia').createIndex({ url: 1 }, { unique: true });
  await db.collection('trickipedia').createIndex({ category: 1 });
  await db.collection('trickipedia').createIndex(
    { name: 'text', description: 'text' }
  );

  console.log('Indexes created');
}

createIndexes();
```

### 4. Compression

Already using `compression` middleware. Verify it's applied:

```javascript
const compression = require('compression');

app.use(compression({
  level: 6,  // Balance between speed and compression
  threshold: 1024  // Only compress responses > 1KB
}));
```

---

## Mobile App Performance

### 1. Image Optimization

Already doing resize before upload. Also optimize assets:

```bash
# Install sharp-cli for asset optimization
npm install -g sharp-cli

# Optimize all PNG assets
sharp -i app/assets/*.png -o app/assets/optimized/ --quality 80
```

### 2. Lazy Loading Screens

```javascript
// navigation/AppNavigator.js
import { lazy, Suspense } from 'react';

const StatsScreen = lazy(() => import('../screens/StatsScreen'));
const SettingsScreen = lazy(() => import('../screens/SettingsScreen'));

// Wrap with Suspense
<Stack.Screen name="Stats">
  {() => (
    <Suspense fallback={<ActivityIndicator />}>
      <StatsScreen />
    </Suspense>
  )}
</Stack.Screen>
```

### 3. Memoization

```javascript
// Prevent unnecessary re-renders
import { memo, useMemo, useCallback } from 'react';

const TrickItem = memo(({ trick, onToggle, onDelete }) => {
  // Component only re-renders if props change
  return (
    <Swipeable renderRightActions={() => <DeleteAction />}>
      <TouchableOpacity onPress={() => onToggle(trick._id)}>
        <Text>{trick.name}</Text>
      </TouchableOpacity>
    </Swipeable>
  );
});

// In parent component
const handleToggle = useCallback((id) => {
  // Toggle logic
}, []);

const sortedTricks = useMemo(() => {
  return tricks.sort((a, b) => a.name.localeCompare(b.name));
}, [tricks]);
```

### 4. FlatList Optimization

```javascript
<FlatList
  data={tricks}
  keyExtractor={(item) => item._id}
  renderItem={renderTrick}
  // Performance props
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  windowSize={5}
  initialNumToRender={10}
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

---

## Deployment Automation

### 1. Single Deploy Script

```bash
#!/bin/bash
# deploy-all.sh

set -e

echo "🚀 Starting deployment..."

# Backend
echo "📦 Deploying backend..."
cd Backend
railway up --detach
cd ..

# Mobile - Both platforms
echo "📱 Building mobile apps..."
cd TrickList
eas build --platform all --profile production --non-interactive

# Auto-submit
echo "📤 Submitting to stores..."
eas submit --platform all --latest --non-interactive

echo "✅ Deployment complete!"
```

### 2. Version Sync Script

```bash
#!/bin/bash
# sync-version.sh

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./sync-version.sh 1.0.9"
  exit 1
fi

# Update package.json files
jq ".version = \"$VERSION\"" Backend/package.json > tmp.json && mv tmp.json Backend/package.json
jq ".version = \"$VERSION\"" TrickList/package.json > tmp.json && mv tmp.json TrickList/package.json

# Update app.json
jq ".expo.version = \"$VERSION\"" TrickList/app.json > tmp.json && mv tmp.json TrickList/app.json

echo "Version updated to $VERSION"
```

### 3. Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT

      - name: Deploy backend
        run: ./scripts/deploy-backend.sh

      - name: Build and submit apps
        run: |
          eas build --platform all --profile production --non-interactive
          eas submit --platform all --latest --non-interactive

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
```

---

## Monitoring & Observability

### 1. Structured Logging

```bash
npm install winston
```

```javascript
// logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'trickbook-api' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

module.exports = logger;
```

### 2. Request Logging

```javascript
const morgan = require('morgan');
const logger = require('./logger');

// Create Morgan stream
const stream = {
  write: (message) => logger.http(message.trim()),
};

app.use(morgan('combined', { stream }));
```

### 3. Health Checks

```javascript
// routes/health.js
router.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
  };

  // Check database
  try {
    const db = await getDb();
    await db.command({ ping: 1 });
    health.database = 'connected';
  } catch (error) {
    health.database = 'disconnected';
    health.status = 'degraded';
  }

  res.status(health.status === 'ok' ? 200 : 503).json(health);
});
```

---

## Summary: Quick Wins

| Improvement | Effort | Impact | Priority |
|-------------|--------|--------|----------|
| Add caching | Low | High | P1 |
| Database indexes | Low | High | P1 |
| CI/CD caching | Low | Medium | P2 |
| Parallel CI jobs | Low | Medium | P2 |
| FlatList optimization | Low | Medium | P2 |
| Structured logging | Medium | High | P1 |
| TypeScript migration | High | High | P3 |
| Monorepo setup | High | Medium | P3 |
