---
sidebar_position: 1
title: Deployment Overview
slug: /deployment
---

# Deployment Overview

This section is the source of truth for shipping every TrickBook application. Feature work reaches production through a reviewed promotion from `staging`; merging a feature branch is not itself a production deployment.

## Platform map

| Application | Production branch | Runtime/distribution | Deployment |
|---|---|---|---|
| Backend API | `master` | AWS EC2 + PM2 | Manual EC2 fast-forward today; GitHub OIDC + SSM planned |
| Web app | `main` | AWS Amplify Web Compute | Automatic after the production promotion merges |
| iOS app | Mobile release branch | EAS Build, TestFlight, App Store Connect | EAS build/submit plus App Store review |
| Android app | Mobile release branch | EAS Build, Google Play | EAS build/submit plus Play Console promotion |
| Documentation | `main` | GitHub Pages | Automatic GitHub Actions deployment |

## Choose a runbook

- [Backend API deployment](./backend.md): EC2 checkout, PM2 process, validation, rollback, and planned OIDC/SSM automation.
- [Web app deployment](./web-app.md): staging and production Amplify branches, promotion, build monitoring, and smoke tests.
- [App Store deployment](./app-store.md): iOS preflight, TestFlight, App Store Connect, review, and release monitoring.
- [Google Play deployment](./google-play.md): Android App Bundle builds, submission, testing tracks, and Play Console release.
- [Staging and production promotion](./staging-and-promotion.md): shared branch policy and QA gates.
- [Infrastructure overview](./infrastructure.md): hosts, processes, DNS, storage, and external services.
- [CI/CD pipeline](./ci-cd.md): current checks and deployment automation status.

## Standard production release order

When a web feature depends on an API change:

1. Merge feature PRs into each repository's `staging` branch only after CI passes.
2. Validate the paired staging revisions.
3. Open `staging` → production promotion PRs (`master` for the API, `main` for the web app).
4. Merge and deploy the backend first.
5. Smoke-test the production API.
6. Merge the web promotion and wait for the Amplify production job to succeed.
7. Smoke-test the live page, its API calls, and any sitemap or metadata changes.

Mobile releases may consume the same API. Confirm backward compatibility with the current App Store and Play Store builds before deploying breaking backend changes.

## Release evidence

Record these items in the promotion PR or release notes:

- production commit SHA;
- successful CI and hosting/build job;
- deployment target and timestamp;
- smoke-test results;
- migrations or index changes;
- rollback revision;
- App Store or Play review state when applicable.

Never place signing keys, SSH keys, store credentials, JWT secrets, database URIs, or provider tokens in documentation, source control, workflow output, or PR descriptions.
