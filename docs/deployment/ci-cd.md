---
sidebar_position: 4
---

# CI/CD Pipeline

Automated build and deployment configuration for TrickBook.

## Recommended Setup

```
GitHub Repository
       │
       ├── Push to main/master
       │       │
       │       ▼
       │   GitHub Actions
       │       │
       │       ├── Backend tests & deploy
       │       │
       │       └── Mobile builds via EAS
       │
       └── Pull Request
               │
               ▼
           Run tests only
```

## GitHub Actions Workflows

### Backend CI/CD

Create `.github/workflows/backend.yml`:

```yaml
name: Backend CI/CD

on:
  push:
    branches: [master, main]
    paths:
      - 'Backend/**'
  pull_request:
    branches: [master, main]
    paths:
      - 'Backend/**'

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: Backend/package-lock.json

      - name: Install dependencies
        working-directory: Backend
        run: npm ci

      - name: Run linter
        working-directory: Backend
        run: npm run lint --if-present

      - name: Run tests
        working-directory: Backend
        run: npm test --if-present
        env:
          NODE_ENV: test
          ATLAS_URI: ${{ secrets.TEST_ATLAS_URI }}
          JWT_SECRET: test-secret

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      # Option 1: Deploy to Railway
      - name: Deploy to Railway
        uses: bervProject/railway-deploy@main
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: trickbook-api

      # Option 2: Deploy to Render
      # - name: Deploy to Render
      #   run: curl -X POST ${{ secrets.RENDER_DEPLOY_HOOK }}

      # Option 3: Deploy to custom server
      # - name: Deploy via SSH
      #   uses: appleboy/ssh-action@v1.0.0
      #   with:
      #     host: ${{ secrets.SSH_HOST }}
      #     username: ${{ secrets.SSH_USER }}
      #     key: ${{ secrets.SSH_KEY }}
      #     script: |
      #       cd /var/www/trickbook-api
      #       git pull
      #       npm ci --only=production
      #       pm2 restart trickbook-api
```

### Mobile App CI/CD

Create `.github/workflows/mobile.yml`:

```yaml
name: Mobile CI/CD

on:
  push:
    branches: [master, main]
    paths:
      - 'TrickList/**'
  pull_request:
    branches: [master, main]
    paths:
      - 'TrickList/**'

jobs:
  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: TrickList/package-lock.json

      - name: Install dependencies
        working-directory: TrickList
        run: npm ci

      - name: Run linter
        working-directory: TrickList
        run: npm run lint --if-present

  build:
    needs: lint
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: TrickList/package-lock.json

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Install dependencies
        working-directory: TrickList
        run: npm ci

      - name: Build iOS
        working-directory: TrickList
        run: eas build --platform ios --profile testflight --non-interactive

      - name: Build Android
        working-directory: TrickList
        run: eas build --platform android --profile playstore --non-interactive

  submit:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Submit to App Store
        working-directory: TrickList
        run: eas submit --platform ios --latest --non-interactive

      - name: Submit to Google Play
        working-directory: TrickList
        run: eas submit --platform android --latest --non-interactive
```

### Documentation Site

Create `.github/workflows/docs.yml`:

```yaml
name: Deploy Docs

on:
  push:
    branches: [master, main]
    paths:
      - 'docs/**'

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: docs/package-lock.json

      - name: Install dependencies
        working-directory: docs
        run: npm ci

      - name: Build docs
        working-directory: docs
        run: npm run build

      # Deploy to GitHub Pages
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/build

      # Or deploy to Vercel
      # - name: Deploy to Vercel
      #   uses: amondnet/vercel-action@v25
      #   with:
      #     vercel-token: ${{ secrets.VERCEL_TOKEN }}
      #     vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
      #     vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
      #     working-directory: ./docs
```

## Required Secrets

Set these in GitHub repository settings → Secrets:

### Backend Secrets
| Secret | Description |
|--------|-------------|
| `RAILWAY_TOKEN` | Railway deployment token |
| `TEST_ATLAS_URI` | Test database connection |

### Mobile Secrets
| Secret | Description |
|--------|-------------|
| `EXPO_TOKEN` | Expo access token |

### Docs Secrets
| Secret | Description |
|--------|-------------|
| `VERCEL_TOKEN` | Vercel deployment token (optional) |

## Getting Tokens

### Expo Token
```bash
# Generate token
eas login
eas secret:list

# Or via Expo dashboard
# https://expo.dev/accounts/[username]/settings/access-tokens
```

### Railway Token
```bash
railway login
railway token
```

## Branch Protection

Recommended branch protection rules for `main`/`master`:

1. **Require pull request reviews**
   - Required approving reviews: 1
   - Dismiss stale reviews

2. **Require status checks**
   - Require branches to be up to date
   - Required checks: `lint`, `test`

3. **Require conversation resolution**

4. **Do not allow bypassing**

## Workflow Triggers

### Manual Triggers

Add manual trigger option:

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

### Scheduled Builds

Run tests nightly:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
```

## Notifications

### Slack Notifications

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    fields: repo,message,commit,author
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

### Discord Notifications

```yaml
- name: Notify Discord
  uses: sarisia/actions-status-discord@v1
  if: always()
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK }}
```

## Caching

Speed up builds with caching:

```yaml
- name: Cache node modules
  uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

## Environment Files

For different environments:

```yaml
- name: Create env file
  run: |
    echo "API_URL=${{ secrets.API_URL }}" >> .env
    echo "SENTRY_DSN=${{ secrets.SENTRY_DSN }}" >> .env
```

## Summary

Complete CI/CD setup:

1. **On PR**: Run linting and tests
2. **On merge to main**: Build and deploy
3. **Manual trigger**: For hotfixes or rollbacks
4. **Notifications**: Slack/Discord alerts

This ensures:
- Code quality via automated checks
- Consistent deployments
- Quick feedback on issues
- Audit trail of all deployments
