---
sidebar_position: 4
---

# Spots Inventory Automation

OpenClaw runs a geographic inventory job that discovers, verifies, enriches, and publishes operating public skateparks to TrickBook. It started with Greater Santiago and now advances through a configurable Chile city queue while periodically re-auditing completed metros.

## Current Job

- **Owner:** Squid / OpenClaw `main` agent
- **Schedule:** Every 30 minutes (`*/30 * * * *`, America/New_York)
- **Session:** Isolated agent turn
- **Timeout:** 25 minutes
- **Delivery:** Summary to the private TrickBook Spots operations channel
- **State:** `memory/spot-inventory-state.json`
- **Discovery:** `scripts/discover-city-skateparks.js --metro <key>`
- **Legacy Santiago discovery:** `scripts/discover-santiago-skateparks.js`

Channel IDs, credentials, API keys, and the complete private job payload are intentionally excluded from this repository.

## City Queue

The active queue begins with:

1. Greater Valparaíso
2. Greater Concepción
3. La Serena-Coquimbo
4. Antofagasta
5. Temuco-Padre Las Casas
6. Puerto Montt-Puerto Varas
7. Rancagua-Machalí
8. Talca
9. Chillán-Chillán Viejo
10. Iquique-Alto Hospicio

Each metro defines localities and a geographic bounding box in the discovery script. When a metro is complete, the job records the result, advances `activeMetro`, and retains the completed metro for periodic maintenance.

## Qualification Rules

Include a candidate only when current evidence supports an operating public skatepark with dedicated skate terrain. Consolidate aliases, parent-park listings, and nearby duplicate map pins into one facility.

Exclude:

- Private or paywalled facilities
- Ordinary street spots without dedicated public skate terrain
- Pump tracks and bike-only facilities
- Roller-only rinks
- Closed, removed, or unbuilt parks
- Map pins that cannot be independently verified

## Per-Spot Workflow

1. Run fresh metro discovery and compare it with production and prior state.
2. Research current operating status, official name, address, coordinates, access, hours, rules, and facility details.
3. De-duplicate aliases and nearby listings.
4. Curate media manually, retaining a layout-first hero and only useful additional views.
5. Copy retained media to TrickBook-controlled storage.
6. Publish or update the production record with source provenance.
7. Audit every retained image, source, and video URL.
8. Render the live page and every carousel slide in headless Chrome; check UTF-8, broken images, and console errors.
9. Checkpoint progress and report counts plus direct URLs for every touched spot.

The job is idempotent: existing records are matched before insertion, and incomplete research is checkpointed rather than published as fact.

## Greater Santiago Audit

Audit date: **August 31, 2026**

- **34 of 34 communes reviewed (100%)**
- **30 communes with at least one qualifying public skatepark**
- **4 communes with no qualifying facility:** Conchalí, La Reina, San Miguel, and Vitacura
- **57 verified operating public skateparks in production**
- **57/57 have curated images, source links, approved status, and operating status**
- **77 raw candidates in the latest discovery pass**, including duplicates and non-qualifying results
- **0 known Santiago candidates remaining**

Santiago is complete for the defined Greater Santiago scope. Remaining work is maintenance rather than initial coverage: rerun discovery periodically, validate changed hours/status/source links, replace weak or dead media, and investigate genuinely new candidates.

## Success and Failure Handling

A successful batch reports added, updated, excluded, and consolidated counts; media review totals; URL-audit results; browser-render results; and direct TrickBook URLs. A run must report only completed, verified work.

If discovery, production writes, audits, or rendering fail, the agent leaves the candidate pending, records the blocker, and retries in a later run. It must not publish an unverified record to satisfy the schedule.

## Operations

```powershell
# Discover one configured metro
node scripts/discover-city-skateparks.js --metro valparaiso

# Inspect scheduled jobs and state
openclaw cron list --json
Get-Content memory/spot-inventory-state.json
```

To pause, replay, or change the queue, update the OpenClaw job and state file together so the durable state and live schedule do not diverge.
