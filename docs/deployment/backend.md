---
sidebar_position: 2
---

# Backend Deployment

Runbook for the production TrickBook backend API on AWS EC2.

## Current Setup

| Item | Value |
|------|-------|
| Production URL | https://api.thetrickbook.com |
| Database | MongoDB Atlas |
| File Storage | AWS S3 |
| Payments | Stripe |
| Production branch | `master` |
| EC2 instance | One instance behind nginx; identifiers live in the internal runbook (not in this repo) |
| Checkout | `/home/ubuntu/TB-Backend` |
| PM2 process | `TB-Backend` (port 9000) |

:::warning Current deployment status

GitHub Actions validates production promotions but does **not** currently deploy the backend. After merging `staging` into `master`, production must be fast-forwarded on EC2 and the `TB-Backend` process restarted. Do not restart `TB-Backend-staging` or unrelated PM2 services.

The production checkout currently contains operational files and a local `index.js` customization. Never use `git reset --hard`, `git clean`, or a forced checkout during deployment.

:::

## Current production procedure

Before deployment, confirm the promotion PR passed CI and record the expected `master` SHA.

```bash
ssh ubuntu@<backend-host>   # host and key name: internal runbook
cd /home/ubuntu/TB-Backend

git fetch origin master
git status --short
git diff --name-only HEAD..origin/master
git merge --ff-only origin/master

. ~/.nvm/nvm.sh
npm ci --omit=dev # only when package manifests changed
pm2 restart TB-Backend --update-env
pm2 show TB-Backend
pm2 logs TB-Backend --lines 50 --nostream
```

The deployment must stop if an incoming file overlaps a local tracked modification. Preserve and reconcile the server change through source control before continuing.

After restart, compare `git rev-parse HEAD` with the expected production SHA and smoke-test `https://api.thetrickbook.com/api` plus the changed endpoint.

## Planned automatic deployment: GitHub OIDC + SSM

Do not create an IAM user or store long-lived AWS keys/SSH keys in GitHub. The target design is:

1. Attach an EC2 instance profile with `AmazonSSMManagedInstanceCore` to the backend instance.
2. Confirm the instance appears as an online Systems Manager managed node.
3. Add the GitHub OIDC provider in AWS IAM with audience `sts.amazonaws.com`.
4. Create a deployment role whose trust policy is restricted to `wbaxterh/TB-Backend` and the protected `production` GitHub Environment.
5. Grant only the Systems Manager document/instance permissions required to send the deploy command and read its result.
6. Give the workflow `id-token: write` and `contents: read`; assume the role with `aws-actions/configure-aws-credentials`.
7. Run a guarded fast-forward/restart command through SSM, wait for completion, then smoke-test the API.

The production Environment should require approval. The command must refuse non-fast-forward updates, verify the expected commit, restart only `TB-Backend`, and fail the workflow when the health check fails.

Longer term, move runtime code to a clean release checkout and keep operational/import scripts outside it. This makes automated rollback and dirty-worktree protection reliable.

## Alternative hosting reference

The options below are historical/future alternatives, not the current production topology.

## Hosting Options

### Option 1: Railway

Quick deployment with automatic scaling.

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
cd Backend
railway init

# Deploy
railway up

# Set environment variables
railway variables set ATLAS_URI="mongodb+srv://..."
railway variables set JWT_SECRET="your-secret"
railway variables set AWS_KEY="..."
# ... set all env vars
```

### Option 2: Render

Similar to Railway with free tier.

1. Connect GitHub repository
2. Select `Backend` directory
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Add environment variables

### Option 3: DigitalOcean App Platform

```bash
# Install doctl
brew install doctl

# Authenticate
doctl auth init

# Create app from spec
doctl apps create --spec app.yaml
```

### Option 4: AWS EC2/ECS

For maximum control:

```bash
# Build Docker image
docker build -t trickbook-api .

# Push to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin xxx.dkr.ecr.region.amazonaws.com
docker tag trickbook-api:latest xxx.dkr.ecr.region.amazonaws.com/trickbook-api:latest
docker push xxx.dkr.ecr.region.amazonaws.com/trickbook-api:latest

# Deploy to ECS
aws ecs update-service --cluster trickbook --service api --force-new-deployment
```

## Docker Configuration

Create `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source
COPY . .

# Expose port
EXPOSE 9000

# Start server
CMD ["npm", "start"]
```

Create `.dockerignore`:

```
node_modules
.env
.git
*.md
```

### Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "9000:9000"
    environment:
      - NODE_ENV=development
      - ATLAS_URI=${ATLAS_URI}
      - JWT_SECRET=${JWT_SECRET}
      - AWS_KEY=${AWS_KEY}
      - AWS_SECRET=${AWS_SECRET}
    volumes:
      - .:/app
      - /app/node_modules
```

```bash
# Run locally
docker-compose up
```

## Environment Variables

Required environment variables:

```bash
# Database
ATLAS_URI=mongodb+srv://user:pass@cluster.mongodb.net/TrickList2

# Authentication
JWT_SECRET=your-very-secure-jwt-secret-minimum-32-chars

# AWS
AWS_KEY=[your-aws-access-key]
AWS_SECRET=[your-aws-secret-key]
AWS_REGION=us-east-1

# Stripe
STRIPE_SECRET_KEY=sk_live_xxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxx
STRIPE_PREMIUM_PRICE_ID=price_xxxxxxxx

# Email (Optional)
EMAIL_USER=admin@thetrickbook.com
EMAIL_PASSWORD=app-specific-password

# Google OAuth
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com

# Server
PORT=9000
NODE_ENV=production
```

## Pre-Deployment Checklist

### Security

- [ ] Rotate all exposed credentials
- [ ] Update JWT secret to secure random string
- [ ] Upgrade Node.js to v18+
- [ ] Update helmet to v7.x
- [ ] Add rate limiting
- [ ] Configure CORS whitelist
- [ ] Add HTTPS redirect

### Configuration

- [ ] Set all environment variables
- [ ] Verify MongoDB connection
- [ ] Verify AWS S3 access
- [ ] Verify Stripe webhook endpoint
- [ ] Set NODE_ENV=production

### Testing

- [ ] All API endpoints working
- [ ] Authentication flow complete
- [ ] Image upload functional
- [ ] Stripe payments processing

## Deployment Script

```bash
#!/bin/bash
# deploy.sh

set -e

echo "Starting deployment..."

# Pull latest code
git pull origin master

# Install dependencies
npm ci --only=production

# Run any migrations (if applicable)
# npm run migrate

# Restart server
pm2 restart trickbook-api

echo "Deployment complete!"
```

## PM2 Configuration (VPS)

For VPS deployments with PM2:

```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'trickbook-api',
    script: 'index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 9000
    },
    env_production: {
      NODE_ENV: 'production'
    }
  }]
};
```

```bash
# Start with PM2
pm2 start ecosystem.config.js --env production

# Save PM2 process list
pm2 save

# Setup startup script
pm2 startup
```

## Health Check Endpoint

Add health check for monitoring:

```javascript
// Add to index.js
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

## Monitoring

### Logging

Add structured logging:

```bash
npm install winston
```

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console());
}
```

### Error Tracking

Add Sentry for production errors:

```bash
npm install @sentry/node
```

```javascript
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV
});

app.use(Sentry.Handlers.requestHandler());
// ... routes ...
app.use(Sentry.Handlers.errorHandler());
```

### Uptime Monitoring

Use services like:
- UptimeRobot (free tier)
- Better Uptime
- Pingdom

Monitor: `https://api.thetrickbook.com/health`

## SSL/HTTPS

Most platforms handle SSL automatically. For custom setup:

```bash
# Certbot for Let's Encrypt
sudo certbot --nginx -d api.thetrickbook.com
```

## Database Backups

MongoDB Atlas provides automatic backups. For manual:

```bash
# Export database
mongodump --uri="mongodb+srv://..." --out=./backup

# Restore
mongorestore --uri="mongodb+srv://..." ./backup
```

## Rollback Procedure

If deployment fails:

```bash
# Revert to previous commit
git revert HEAD
git push origin master

# Or checkout specific version
git checkout v1.0.7
npm ci --only=production
pm2 restart trickbook-api
```
