---
sidebar_position: 6
title: "ADR-006: Web UI Kit Consolidation"
---

# ADR-006: Consolidate the Website on Radix + Tailwind

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | September 24, 2026 |
| **Deciders** | Wes Huber |
| **Related** | [Web app deployment](/docs/deployment/web-app) · TrickBookWebsite branch `chore/remove-bootstrap` |

## Context

As of 2026-09-24 the website stacked three UI kits at once:

- **MUI**: `@mui/material` components and `@mui/icons-material` icons, with a `MuiThemeProvider` in `_app.js`.
- **Bootstrap**: `bootstrap/dist/css/bootstrap.css` imported globally in `_app.js`, plus `react-bootstrap` `Navbar`, `Nav` and `NavDropdown` in `Header.js` and `LanguageSelector.js`, and bootstrap grid and card classes in about a dozen admin and blog pages.
- **Radix + Tailwind**: shadcn-style primitives in `components/ui/*` (button, card, dialog, select, tabs, toast and others), `lucide-react` icons, and Tailwind utilities across most newer pages.

Three kits meant two CSS resets loaded on every page (bootstrap reboot and Tailwind preflight), three button styles, three dropdown implementations, and a bundle that shipped all of them to every visitor. New work had no default, so each page picked whatever its author knew.

## Decision

1. **Bootstrap is removed.** The global stylesheet import, `react-bootstrap` and `bootstrap` are dropped. `Header.js` and `LanguageSelector.js` move to the Radix `DropdownMenu` plus Tailwind, and bootstrap grid and card classes are rewritten as Tailwind utilities or existing `components/ui` primitives. Done on branch `chore/remove-bootstrap` in TrickBookWebsite.
2. **Radix + Tailwind is the target kit.** All new UI uses `components/ui/*`, Tailwind utilities and `lucide-react`. No new MUI import is added anywhere.
3. **MUI stays only where it already is.** Existing MUI files keep working until each is migrated. Migration is file by file: icons first (swap `@mui/icons-material` for `lucide-react`), then components (`Typography`, `Button`, `Chip`, `CircularProgress`, `Box`, `TextField`, `Alert`, the table set), then the theme provider in `_app.js` last.

### MUI inventory at the decision date

27 files under `pages/` and `components/` import from `@mui/`.

| Group | Count | Files |
|-------|-------|-------|
| Icons only (`@mui/icons-material`) | 1 | `pages/signup.js` |
| Components and icons | 11 | `Header.js`, `TrickProgressionSection.js`, `pages/admin/blog.js`, `categories.js`, `create-blog-post.js`, `create-trick.js`, `pending-spots.js`, `spots.js`, `trickipedia.js`, `pages/trickipedia/[category].js`, `pages/trickipedia/[category]/[trick].js` |
| Components only (`@mui/material`) | 15 | `AdminLayout.js`, `AdminNav.js`, `BlogCard.js`, `CustomArrow.js`, `PageHeader.js`, `TrickCard.js`, `pages/_app.js` (theme provider), `about.js`, `admin/create-spot.js`, `admin/index.js`, `admin/spot-enrichment.js`, `blog.js`, `blog/[slug].js`, `questions-support.js`, `tricklist.js` |

Most-used MUI components by import count: `Typography` (10), `Button` (6), `CircularProgress`, `Chip`, `Box` (4 each), `TextField` (3). Each already has a `components/ui` or plain-Tailwind equivalent.

## Consequences

- Two kits remain until the MUI list above reaches zero; the count is the migration metric.
- Tailwind preflight is now the only CSS reset. Bootstrap's reboot rules (its body font stack, heading margins, `img` display, form control defaults) are gone, so any page that leaned on them without saying so needs an explicit Tailwind class.
- The header and language dropdowns are keyboard and screen-reader accessible through Radix rather than bootstrap's JavaScript.
- The `.navbar-*`, `.dropdown-*` and `.profile-dropdown` overrides in `styles/global.css` are replaced by classes that target the Radix markup.
- Bundle size drops by the bootstrap CSS and `react-bootstrap` runtime on every page.

## Rejected alternatives

**Standardize on MUI:** rejected because the newer half of the site (spots, media, riders, shops, events) is already Radix + Tailwind and MUI's emotion runtime is the heaviest of the three.

**Keep bootstrap for the grid only:** rejected because Tailwind's grid and flex utilities already cover every bootstrap grid usage found (`row`, `col-*`, `container-fluid`, `g-4`), and a partial bootstrap still ships its full reset.

**Big-bang rewrite of all three:** rejected because there is no visual regression suite yet; file-by-file keeps each change reviewable.

## Rollout

1. Remove bootstrap (this ADR's date).
2. Add a lint rule or CI grep that fails on new `@mui/` imports outside the inventory list.
3. Migrate icons-only and icons-and-components files to `lucide-react` icons.
4. Migrate component files, admin pages last since they are internal.
5. Remove `MuiThemeProvider`, `@mui/material`, `@mui/icons-material`, `@emotion/*` and `material-icons` from `package.json`.
