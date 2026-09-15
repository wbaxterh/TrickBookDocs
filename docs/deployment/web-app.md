---
sidebar_position: 3
title: Web App Deployment
---

# Web App Deployment

The Next.js web app is hosted by AWS Amplify Web Compute.

| Environment | Git branch | Amplify branch | Public role |
|---|---|---|---|
| Staging | `staging` | `staging` | Feature QA |
| Production | `main` | `main` | `https://thetrickbook.com` |

## Production promotion

1. Merge feature PRs into `staging` after the repository's `validate` check passes.
2. Test the Amplify staging deployment.
3. Open one PR from `staging` to `main`. The `production-promotion` check rejects other source branches.
4. Review the complete comparison because the promotion includes every commit currently ahead on `staging`.
5. Merge only after `validate`, `production-promotion`, and security checks pass.
6. Amplify automatically starts a production build for the new `main` commit.

Merging the GitHub PR is not sufficient evidence that the site is live. Wait for the matching Amplify job to report `SUCCEED`.

## Monitor Amplify

The production Amplify app is `TrickBookWebsite` (`d23kwealrnh9ae`) in `us-east-1`.

```bash
aws amplify list-jobs \
  --app-id d23kwealrnh9ae \
  --branch-name main \
  --max-results 5

aws amplify get-job \
  --app-id d23kwealrnh9ae \
  --branch-name main \
  --job-id <job-id>
```

The job commit ID must equal the merged `main` SHA. A CloudFront 404 or old page during a running build usually means the previous artifact is still serving.

## Production smoke test

- Confirm the Amplify job succeeded for the intended SHA.
- Request the changed route and expect the intended 2xx/redirect response.
- Confirm server-rendered title, canonical URL, and structured data for SEO pages.
- Exercise the production API request used by the page.
- Check `https://thetrickbook.com/sitemap.xml` when routes or indexing changed.
- Test an authenticated path when the release touches sessions, saves, profiles, or account state.
- Check browser console and network errors.

## Rollback

Prefer a revert PR on `main`, preserving the audit trail. After merge, monitor the new Amplify job and repeat the smoke test. Amplify can redeploy a previous successful job for urgent hosting recovery, but reconcile Git immediately afterward so `main` still represents production.
