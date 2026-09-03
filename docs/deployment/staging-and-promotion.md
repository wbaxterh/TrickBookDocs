---
title: Staging and Production Promotion
---

# Staging and Production Promotion

All TrickBook web and backend features follow this path:

`feature/*` → pull request to `staging` → automated checks → staging deploy → manual QA → pull request from `staging` to production

Production branches are `main` for the website and `master` for the backend. The promotion check rejects production pull requests whose source branch is not `staging`.

## Environment isolation

| Concern | Staging | Production |
|---|---|---|
| Web | Amplify `staging` branch | Amplify `main` branch |
| API | Separate EC2 worktree/process/port | Existing EC2 production process |
| MongoDB | Separate database selected with `MONGODB_DATABASE` | `TrickList2` |
| Neo4j | Staging graph/database | Production graph/database after readiness review |
| Secrets | Branch/process environment | Production environment |

Never copy production secrets into source control or expose them in build logs. Test data may be seeded from sanitized public fields, not by cloning credentials, tokens, messages, or private account fields.

## Required QA before promotion

1. CI passes in both repositories.
2. Staging health and API smoke checks pass.
3. Anonymous and authenticated browser paths pass.
4. Data mutations are confirmed against the staging database.
5. Error and process logs are clean during the test run.
6. A human approves the `staging` → production PR.

Emergency production fixes require an explicit incident note and must be merged back into `staging` immediately after production recovery.
