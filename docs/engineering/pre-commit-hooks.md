---
sidebar_position: 4
---

# Pre-commit Hooks

Pre-commit hooks prevent broken code from being committed. Every commit is automatically checked for lint errors, formatting issues, and type errors before it enters git history.

## Setup (Both Repos)

### Install Husky + lint-staged

```bash
# In TrickList/ or Backend/
npm install --save-dev husky lint-staged

# Initialize Husky
npx husky init
```

This creates a `.husky/` directory with a `pre-commit` hook.

### Configure the Hook

Replace `.husky/pre-commit` contents:

```bash
npx lint-staged
```

### Configure lint-staged

Add to `package.json`:

#### TrickList (Mobile)

```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "biome check --write --no-errors-on-unmatched",
      "biome format --write --no-errors-on-unmatched"
    ],
    "*.{json,md}": [
      "biome format --write --no-errors-on-unmatched"
    ]
  }
}
```

#### Backend

```json
{
  "lint-staged": {
    "*.js": [
      "biome check --write --no-errors-on-unmatched",
      "biome format --write --no-errors-on-unmatched"
    ],
    "*.{json,md}": [
      "biome format --write --no-errors-on-unmatched"
    ]
  }
}
```

## What Runs on Commit

```
git commit -m "feat: add trick list"
       │
       ▼
  lint-staged
       │
       ├── biome check --write (lint + auto-fix staged files)
       ├── biome format --write (format staged files)
       │
       ▼
  Pass? ──── Yes ──── Commit created
       │
       No
       │
       ▼
  Commit blocked, errors printed
```

Only **staged files** are checked, so it's fast even in large repos.

## Optional: Add Typecheck

For TrickList, you can add a full typecheck on commit. This is slower but catches type errors:

```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "biome check --write --no-errors-on-unmatched",
      "biome format --write --no-errors-on-unmatched"
    ]
  },
  "scripts": {
    "precommit:typecheck": "tsc --noEmit"
  }
}
```

And update `.husky/pre-commit`:

```bash
npx lint-staged
npm run precommit:typecheck
```

## Bypassing Hooks

In rare cases (emergency hotfix, WIP commit), hooks can be bypassed:

```bash
git commit --no-verify -m "hotfix: emergency fix"
```

This should be rare. CI will still catch any issues on the PR.

## Troubleshooting

### Hook not running

```bash
# Ensure hooks are executable
chmod +x .husky/pre-commit

# Reinstall hooks
npx husky install
```

### Biome not found

```bash
# Ensure it's in devDependencies
npm install --save-dev @biomejs/biome
```
