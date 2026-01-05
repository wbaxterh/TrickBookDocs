---
sidebar_position: 3
---

# Backend Deployment

Guide for deploying the TrickBook backend API.

## Current Setup

| Item | Value |
|------|-------|
| Production URL | https://api.thetrickbook.com |
| Database | MongoDB Atlas |
| File Storage | AWS S3 |
| Payments | Stripe |

## Recommended Hosting Options

### Option 1: Railway (Recommended)

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
