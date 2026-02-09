---
sidebar_position: 2
---

# Linting & Formatting

TrickBook uses [Biome](https://biomejs.dev/) for both linting and formatting across all repositories. One tool, one config, zero debate about semicolons.

## Why Biome Over ESLint + Prettier

| | Biome | ESLint + Prettier |
|---|---|---|
| Config files | 1 (`biome.json`) | 3+ (`.eslintrc`, `.prettierrc`, eslint-config-prettier) |
| Speed | 10-100x faster (Rust-based) | Slow on large codebases |
| TypeScript | Native support | Requires parser plugins |
| JSX/TSX | Native support | Requires plugins |
| Conflicts | Impossible (one tool) | Prettier vs ESLint conflicts are common |

## Setup

### TrickList (Mobile)

```bash
cd TrickList

# Initialize Biome
npx @biomejs/biome init

# Add to devDependencies
npm install --save-dev @biomejs/biome
```

### Backend

```bash
cd Backend

# Initialize Biome
npx @biomejs/biome init

# Add to devDependencies
npm install --save-dev @biomejs/biome
```

## Configuration

### `biome.json` (shared across repos)

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": {
          "level": "warn",
          "options": { "maxAllowedComplexity": 15 }
        }
      },
      "suspicious": {
        "noConsoleLog": "warn",
        "noDebugger": "error"
      },
      "style": {
        "noNonNullAssertion": "warn",
        "useConst": "error"
      },
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "always",
      "trailingCommas": "all"
    }
  },
  "files": {
    "ignore": [
      "node_modules",
      "build",
      "dist",
      ".expo",
      "ios",
      "android",
      "coverage"
    ]
  }
}
```

### TrickList-Specific Overrides

The mobile app may need slightly different rules for React Native patterns:

```json
{
  "overrides": [
    {
      "include": ["**/*.test.ts", "**/*.test.tsx"],
      "linter": {
        "rules": {
          "suspicious": {
            "noConsoleLog": "off"
          }
        }
      }
    }
  ]
}
```

## Package.json Scripts

Add to both repos:

```json
{
  "scripts": {
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "format:check": "biome format ."
  }
}
```

## Usage

```bash
# Check for issues (lint + format)
npm run lint

# Auto-fix everything
npm run lint:fix

# Check only formatting
npm run format:check

# Fix only formatting
npm run format
```

## Editor Integration

### VS Code

Install the [Biome extension](https://marketplace.visualstudio.com/items?itemName=biomejs.biome).

Add to `.vscode/settings.json`:

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  }
}
```

### Cursor

Same as VS Code - Biome extension works in Cursor.

## First Run Strategy

On first setup, the linter will report hundreds of issues across the codebase. Handle this in stages:

1. **Run `biome check --write .`** to auto-fix formatting and safe lint fixes
2. **Commit the formatting pass** separately (big diff, but no logic changes)
3. **Address remaining lint warnings** incrementally per file as you touch them
4. **Do not suppress warnings globally** unless there's a clear reason

## CI Integration

Biome check runs as the first step in CI. See [CI/CD Pipeline](/docs/deployment/ci-cd) for the full workflow.

```yaml
- name: Lint & Format Check
  run: npx biome check .
```
