---
title: Publishing Workflow
description: Adobe production workflow and handoff format for TrickBook Skateboarding Level 1.
---

# Publishing workflow

## Recommended toolchain

Use **Adobe InDesign as the master publishing application**. It is the best fit for a long illustrated book because it provides paragraph and character styles, master pages, anchored images, cross-references, preflight, accessible PDF export, EPUB export, and print-ready packaging.

- **InDesign:** Page design, typography, navigation, final PDF, EPUB, and print package
- **Illustrator:** Reusable vector diagrams, board anatomy, trick sequences, maps, icons, arrows, and line art
- **Photoshop:** Photo correction, compositing, texture, and cleanup of raster-generated illustrations
- **Adobe Fonts:** Licensed production typography with dependable packaging
- **Acrobat Pro:** Accessibility review, link testing, metadata, final preflight, and proof comments

Do not compose the master book in Photoshop, Illustrator, Canva, or a word processor. Those tools can contribute assets, but InDesign should own the pages.

## Source package for each chapter

Every chapter should be delivered as a numbered production folder:

```text
01-history/
  01-copy.md
  02-sidebars.md
  03-captions.md
  04-art-briefs.md
  05-source-notes.md
  art/
    vector/
    raster/
    reference/
  approvals/
```

Copy, captions, source notes, and art briefs remain separate so revisions do not require dismantling page layouts.

## InDesign setup

Create these foundations before laying out the whole manuscript:

- Trim size and bleed for the intended print vendor
- Parent pages for chapter openers, standard text, trick pages, timelines, and reference pages
- Paragraph styles for title, heading, body, captions, quotes, Mack, Kaori, sources, and lists
- Character styles for trick names, emphasis, interface references, and glossary terms
- Object styles for illustrations, QR codes, callouts, diagrams, and photos
- Named color swatches that also remain readable in grayscale
- A baseline grid and fixed spacing system
- Automatic page numbers, running heads, table of contents, and bookmarks

## Image production

Generate images in batches by illustration type, not randomly page by page. A batch should share one approved character sheet, stroke system, palette, framing rule, and export specification.

Recommended final formats:

- Diagrams and line art: AI or SVG source, placed PDF for print
- Full-color raster art: layered PSD or TIFF, 300 ppi at final size
- Transparent raster elements: PSD or PNG, 300 ppi at final size
- Web review previews: compressed PNG or JPEG

AI-generated artwork is a draft asset until anatomy, board geometry, stance, direction, hands, feet, trucks, and obstacle interaction have been checked. Technically important trick diagrams should be redrawn or corrected in Illustrator.

## Publishing outputs

Maintain one source document and export purpose-specific editions:

- Interactive PDF for direct sales
- Fixed-layout EPUB when store compatibility is confirmed
- Print-ready PDF/X file for print-on-demand or offset printing
- Lightweight review PDF with comments enabled
- Web excerpts and social images derived from the same approved assets

## Review gates

1. Outline approved
2. Chapter manuscript approved
3. Source and factual review complete
4. Art briefs approved
5. Rough layout approved
6. Final art and captions approved
7. Proofread and accessibility review complete
8. Print proof approved
9. Store metadata, ISBN, pricing, and launch assets approved

The first chapter should be used to establish the design system before the remaining chapters are produced in batches.
