# TrickBook Documentation

Technical documentation for the TrickBook mobile app and platform.

## Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build

# Serve production build locally
npm run serve
```

## PDF Export

Generate PDF versions of the documentation:

```bash
# Generate individual PDFs for each page
npm run pdf:all

# Generate a single combined PDF
npm run pdf:combined

# Generate PDFs for a specific section
npm run pdf:section docs/backend/
```

PDFs are output to the `pdf-exports/` directory.

## Deployment

### GitHub Pages (Automatic)

Push to `main` branch triggers automatic deployment via GitHub Actions.

**Live URL:** https://wbaxterh.github.io/TrickBookDocs/

### Manual Deployment

```bash
npm run build
npm run deploy
```

## Documentation Structure

```
docs/
├── intro.md                    # Getting started
├── architecture/
│   ├── overview.md            # System design
│   ├── tech-stack.md          # Technologies used
│   └── data-flow.md           # Data flow diagrams
├── backend/
│   ├── overview.md            # Backend structure
│   ├── api-endpoints.md       # API reference
│   ├── authentication.md      # Auth system
│   ├── database.md            # MongoDB schema
│   └── security.md            # Security status
├── mobile/
│   ├── overview.md            # App structure
│   ├── navigation.md          # React Navigation
│   ├── state-management.md    # State patterns
│   ├── api-integration.md     # API client
│   └── build-configuration.md # EAS/Expo config
├── deployment/
│   ├── app-store.md           # iOS deployment
│   ├── google-play.md         # Android deployment
│   ├── backend.md             # Server deployment
│   └── ci-cd.md               # GitHub Actions
└── roadmap/
    ├── priorities.md          # Task priorities
    ├── security-fixes.md      # Security TODOs
    └── efficiency-improvements.md
```

## Features

- **Mermaid Diagrams** - Interactive flowcharts and sequence diagrams
- **Dark Mode** - Automatic theme switching
- **PDF Export** - Generate documentation as PDFs
- **Search** - Full-text documentation search
- **Mobile Responsive** - Works on all devices

## Technologies

- [Docusaurus 3](https://docusaurus.io/) - Documentation framework
- [Mermaid](https://mermaid.js.org/) - Diagram generation
- [md-to-pdf](https://github.com/simonhaenisch/md-to-pdf) - PDF export

## License

Private - TrickBook
