---
sidebar_position: 1
---

# Engineering Standards

Baseline engineering standards for the TrickBook project. These apply to **all repositories** (TrickList, Backend, Website, Docs) and must be in place before any new feature work.

## Current State

| Standard | TrickList (Mobile) | Backend | Website (NextJS) | Docs |
|----------|-------------------|---------|-----------------|------|
| Linting & Formatting | Biome | Biome | Biome | Biome |
| Testing | 0 tests / 98+ files | 0 tests / 24 route files | None | N/A |
| Pre-commit Hooks | Husky + lint-staged | Husky + lint-staged | Husky + lint-staged | Husky + lint-staged |
| CI/CD Pipeline | GitHub Actions (lint + typecheck) + EAS | GitHub Actions (lint) + PM2 deploy | GitHub Actions (lint + build) | GitHub Actions (lint + typecheck + build + deploy) |
| Error Boundary | None | No global handler | None | N/A |
| Error Tracking | None | None | None | N/A |
| Structured Logging | console.log (warnings) | console.log (410+ calls) | console.log (warnings) | N/A |
| API Response Validation | Zod in 2 files only | Joi in 8/24 routes | None | N/A |
| .env.example | `.env.example` | `.env.example` | `.env.example` | N/A |
| TypeScript Strict | Basic `strict: true` | No TypeScript | No TypeScript | Basic `strict: true` |
| Docker | N/A | Missing | N/A | N/A |
| Health Check | N/A | Missing | N/A | N/A |

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

### Website (NextJS)

```
TrickBookWebsite/
├── biome.json              # Lint + format config (JS, CSS Modules, Tailwind)
├── .husky/
│   └── pre-commit          # Runs: lint-staged
├── pages/                  # Next.js page routes
├── components/             # React components
├── lib/                    # Utilities and API calls
├── styles/                 # CSS Modules + Tailwind
├── .env.example            # Template for required vars
└── package.json            # Scripts: lint, format, validate
```

## Package.json Scripts (All Repos)

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
