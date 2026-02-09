---
sidebar_position: 3
---

# Testing Strategy

TrickBook currently has **zero tests** across 98+ mobile source files and 24 backend route files. This document defines the testing strategy and the first tests to write.

## Testing Stack

### TrickList (Mobile)

| Tool | Purpose |
|------|---------|
| [Jest](https://jestjs.io/) | Test runner (included with Expo) |
| [React Native Testing Library](https://callstack.github.io/react-native-testing-library/) | Component testing |
| [@testing-library/jest-native](https://github.com/testing-library/jest-native) | Additional matchers |

### Backend

| Tool | Purpose |
|------|---------|
| [Jest](https://jestjs.io/) | Test runner |
| [Supertest](https://github.com/ladakh/supertest) | HTTP endpoint testing |
| [mongodb-memory-server](https://github.com/nodkz/mongodb-memory-server) | In-memory MongoDB for tests |

## Setup

### TrickList

```bash
cd TrickList

npm install --save-dev jest @testing-library/react-native @testing-library/jest-native
```

Add to `package.json`:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "jest": {
    "preset": "jest-expo",
    "setupFilesAfterSetup": ["@testing-library/jest-native/extend-expect"],
    "collectCoverageFrom": [
      "src/**/*.{ts,tsx}",
      "!src/**/*.d.ts"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 20,
        "functions": 20,
        "lines": 20,
        "statements": 20
      }
    }
  }
}
```

### Backend

```bash
cd Backend

npm install --save-dev jest supertest mongodb-memory-server
```

Add to `package.json`:

```json
{
  "scripts": {
    "test": "jest --runInBand --forceExit",
    "test:watch": "jest --watch --runInBand",
    "test:coverage": "jest --coverage --runInBand --forceExit"
  },
  "jest": {
    "testEnvironment": "node",
    "coverageThreshold": {
      "global": {
        "branches": 20,
        "functions": 20,
        "lines": 20,
        "statements": 20
      }
    }
  }
}
```

## Priority: First 10 Tests to Write

These are ordered by risk. If something breaks here, users notice immediately.

### Mobile (TrickList)

#### 1. API Client (`src/lib/api/client.ts`)

The single point of failure for all API communication.

```typescript
// src/lib/api/client.test.ts
import { apiClient } from './client';

describe('API Client', () => {
  it('should attach auth token to requests', async () => {
    // Mock authStore to return a token
    // Verify Authorization header is set
  });

  it('should handle 401 by clearing auth state', async () => {
    // Mock a 401 response
    // Verify authStore.logout() is called
  });

  it('should handle network errors gracefully', async () => {
    // Mock fetch to throw
    // Verify error is caught and formatted
  });
});
```

#### 2. Auth Store (`src/lib/stores/authStore.ts`)

Controls login, logout, and session persistence.

```typescript
// src/lib/stores/authStore.test.ts
import { useAuthStore } from './authStore';

describe('Auth Store', () => {
  it('should start logged out', () => {
    expect(useAuthStore.getState().user).toBeNull();
    expect(useAuthStore.getState().isAuthenticated).toBe(false);
  });

  it('should set user on login', async () => {
    // Call login with mock credentials
    // Verify user state is set
  });

  it('should clear state on logout', async () => {
    // Set up authenticated state
    // Call logout
    // Verify state is cleared
  });
});
```

#### 3. Trick Status Logic

Business logic for trick progression.

```typescript
// src/types/trickbook.test.ts
describe('Trick Status', () => {
  it('should calculate progress percentage correctly', () => {
    // Test with 0/5 tricks landed
    // Test with 3/5 tricks landed
    // Test with 5/5 tricks landed
  });
});
```

#### 4-5. Two critical screen smoke tests

```typescript
// Verify screens render without crashing
describe('HomeScreen', () => {
  it('renders without crashing', () => {
    render(<HomeScreen />);
  });
});
```

### Backend

#### 6. Auth Endpoint (`routes/auth.js`)

```javascript
// __tests__/auth.test.js
const request = require('supertest');
const app = require('../index');

describe('POST /api/auth', () => {
  it('should return 400 with invalid credentials', async () => {
    const res = await request(app)
      .post('/api/auth')
      .send({ email: 'bad@email.com', password: 'wrong' });
    expect(res.status).toBe(400);
  });

  it('should return JWT token with valid credentials', async () => {
    // Create test user, login, verify token
  });

  it('should reject requests without email', async () => {
    const res = await request(app)
      .post('/api/auth')
      .send({ password: 'test' });
    expect(res.status).toBe(400);
  });
});
```

#### 7. User Registration (`routes/users.js`)

```javascript
// __tests__/users.test.js
describe('POST /api/users', () => {
  it('should create a new user', async () => { /* ... */ });
  it('should reject duplicate email', async () => { /* ... */ });
  it('should hash the password', async () => { /* ... */ });
});
```

#### 8. Auth Middleware (`middleware/auth.js`)

```javascript
// __tests__/middleware/auth.test.js
describe('Auth Middleware', () => {
  it('should reject requests without token', () => { /* ... */ });
  it('should reject invalid tokens', () => { /* ... */ });
  it('should set req.user for valid tokens', () => { /* ... */ });
});
```

#### 9-10. Trick list CRUD and Spots endpoints

Core data operations that users depend on daily.

## Test File Location

**Colocated tests** (test file next to source file):

```
src/
├── lib/
│   ├── api/
│   │   ├── client.ts
│   │   └── client.test.ts      # Right next to the source
│   └── stores/
│       ├── authStore.ts
│       └── authStore.test.ts
├── components/
│   ├── ui/
│   │   ├── Button.tsx
│   │   └── Button.test.tsx
```

This makes it obvious when a file has no test, and keeps related code together.

## Coverage Targets

Start low, ratchet up as you add tests:

| Phase | Target | Timeline |
|-------|--------|----------|
| Phase 1 | 20% lines | First session |
| Phase 2 | 40% lines | Two weeks |
| Phase 3 | 60% lines | One month |
| Steady state | 70%+ lines | Ongoing |

Coverage thresholds in Jest config will **fail CI** if coverage drops below the target.

## What NOT to Test

- Expo/React Native internals
- Third-party library behavior
- Pixel-perfect UI (use snapshot tests sparingly)
- Implementation details (test behavior, not how it's done)

## CI Integration

Tests run on every PR as part of the `validate` job. See [CI/CD Pipeline](/docs/deployment/ci-cd).

```yaml
- name: Run Tests
  run: npm test -- --coverage --ci
```
