---
sidebar_position: 1
---

# Engineering Standards

Baseline engineering standards for the TrickBook project. These apply to **all repositories** (TrickList, Backend, docs) and must be in place before any new feature work.

## Current State

| Standard | TrickList (Mobile) | Backend | Docs |
|----------|-------------------|---------|------|
| Linting & Formatting | None | None | None |
| Testing | 0 tests / 98+ files | 0 tests / 24 route files | N/A |
| Pre-commit Hooks | None | None | None |
| CI/CD Pipeline | Manual EAS only | Manual deploy | GitHub Actions |
| Error Boundary | None | No global handler | N/A |
| Error Tracking | None | None | N/A |
| Structured Logging | console.log (54 calls) | console.log (410+ calls) | N/A |
| API Response Validation | Zod in 2 files only | Joi in 8/24 routes | N/A |
| .env.example | Missing | Missing | N/A |
| TypeScript Strict | Basic `strict: true` | No TypeScript | N/A |
| Docker | N/A | Missing | N/A |
| Health Check | N/A | Missing | N/A |

## Implementation Order

These standards should be implemented in this exact order. Each builds on the previous.

### Phase 1: Code Quality Foundation (Day 1)

1. **[Biome (Lint + Format)](/docs/engineering/linting-formatting)** - Single tool for both repos
2. **[Pre-commit Hooks](/docs/engineering/pre-commit-hooks)** - Prevent bad code from entering the repo

### Phase 2: Safety Net (Day 1-2)

3. **[Error Handling](/docs/engineering/error-handling)** - Error boundaries (mobile) + global handler (backend)
4. **[Error Tracking (Sentry)](/docs/engineering/error-handling#sentry-integration)** - Know when production breaks

### Phase 3: Testing (Day 2-3)

5. **[Testing Strategy](/docs/engineering/testing)** - Start with critical paths, expand outward

### Phase 4: Automation (Day 3)

6. **[CI/CD Pipeline](/docs/deployment/ci-cd)** - Automated quality gates on every PR
7. **[Structured Logging](/docs/engineering/logging)** - Replace console.log everywhere

### Phase 5: Cleanup (Day 4)

8. **[Code Quality](/docs/engineering/code-quality)** - Remove dead deps, consolidate libraries, validate API responses

## Standards Per Repository

### TrickList (Mobile)

```
TrickList/
├── biome.json              # Lint + format config
├── .husky/
│   └── pre-commit          # Runs: biome check --staged
├── src/
│   ├── components/
│   │   ├── Button.tsx
│   │   └── Button.test.tsx  # Colocated tests
│   ├── lib/
│   │   ├── api/
│   │   │   ├── client.ts
│   │   │   └── client.test.ts
│   │   └── stores/
│   │       ├── authStore.ts
│   │       └── authStore.test.ts
│   └── app/
│       └── _layout.tsx      # ErrorBoundary wraps root
├── .env.example             # Template for required vars
└── package.json             # Scripts: lint, test, typecheck, validate
```

### Backend

```
Backend/
├── biome.json
├── .husky/
│   └── pre-commit
├── Dockerfile
├── docker-compose.yml
├── middleware/
│   ├── errorHandler.js      # Global error handler
│   └── rateLimiter.js
├── __tests__/               # Or colocated
│   ├── auth.test.js
│   └── users.test.js
├── .env.example
└── package.json             # Scripts: lint, test, validate
```

## Package.json Scripts (Both Repos)

Every repo must have these scripts:

```json
{
  "scripts": {
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "typecheck": "tsc --noEmit",
    "validate": "biome check . && tsc --noEmit && jest"
  }
}
```

The `validate` script runs everything. CI runs `validate`. Pre-commit runs `biome check --staged`.
