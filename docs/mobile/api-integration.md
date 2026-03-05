---
sidebar_position: 4
---

# API Integration

The mobile app uses a typed API layer in `src/lib/api/*` and a shared HTTP client in `src/lib/api/client.ts`.

## Base Configuration

Source of truth: `src/constants/api.ts`

- `API_CONFIG.baseUrl`
  - dev: `http://<DEV_API_HOST>:9000/api`
  - prod: `https://api.thetrickbook.com/api`
- `API_CONFIG.socketUrl`
  - dev: `http://<DEV_API_HOST>:9000`
  - prod: `https://api.thetrickbook.com`

## HTTP Client Contract

Source of truth: `src/lib/api/client.ts`

- Automatically injects `x-auth-token` from Expo Secure Store key `auth_token`
- Supports `skipAuth` for public endpoints
- Uses request timeout + abort controller
- Normalizes network and API errors to a consistent shape

## API Module Map

| Module | Primary endpoint group |
|--------|-------------------------|
| `auth.ts` | `/auth`, `/users`, `/user` |
| `trickbook.ts` | `/trickipedia`, `/listings`, `/listing`, `/categories` |
| `spots.ts` | `/spots` |
| `spotlists.ts` | `/spotlists` |
| `spotReviews.ts` | `/spot-reviews` |
| `homies.ts` | `/users/*` |
| `messages.ts` | `/dm/*` |
| `feed.ts` | `/feed/*` |
| `couch.ts` | `/couch/*` |
| `upload.ts` | `/upload/*` |
| `user.ts` | `/user/*` |

## Authentication And Realtime

- REST auth header: `x-auth-token`
- Socket auth token: handshake `auth.token`
- Active socket namespaces from backend:
  - `/feed`
  - `/messages`

## Important Notes

1. The repository still contains legacy code under `app/api/*`; new feature work should use `src/lib/api/*`.
2. Endpoint constants in `src/constants/api.ts` are the canonical mobile contract definitions.
3. If backend routes change, update both endpoint constants and any direct URL usage in the API modules.

## Related Docs

- [Architecture Overview](/docs/architecture/overview)
- [Repo Dependency Map](/docs/architecture/repo-dependency-map)
- [Backend API Endpoints](/docs/backend/api-endpoints)
