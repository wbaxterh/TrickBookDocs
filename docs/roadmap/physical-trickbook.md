---
title: Physical TrickBook
description: Product roadmap for a printed trick progression journal connected to the TrickBook app.
---

# Physical TrickBook

Status: **Product concept; validation and prototype not started**  
Last updated: **October 21, 2026**

## Product vision

The Physical TrickBook is a durable, sport-specific progression journal that connects riding in the real world with the TrickBook digital platform. It is part field guide, part trick checklist, part session journal, and part record of a rider's personal history.

The book should not attempt to print the entire changing Trickipedia catalog. The app remains the live source for videos, expanded instructions, progression graphs, spots, events, and community. The physical book gives riders something better suited to a backpack, lodge, skatepark, road trip, coaching session, or screen-free reflection.

The core loop is:

```text
Choose a goal in the book
        ↓
Scan a durable TrickBook code for the current lesson
        ↓
Practice and record attempts in the real world
        ↓
Mark progress in the book and app
        ↓
Choose the next recommended trick
```

## Why it belongs in the product

The physical book can do several things the app cannot do as naturally:

- become an object riders keep for years;
- make progression visible without opening a phone;
- support coaches, camps, schools, clubs, shops, and parents;
- create a giftable retail product with clear perceived value;
- bring TrickBook into shops and resorts without asking someone to install an app first;
- produce organic app acquisition through useful QR/deep links;
- document the story around learning, not just the final make;
- reinforce TrickBook's identity as the place where action-sports progression is recorded.

The book is not merchandise with a logo placed on blank pages. It must solve a real progression and memory problem.

## Recommended first edition

Start with **The Skateboarding TrickBook: Foundations & First Progressions**.

Why skateboarding first:

- practice is frequent and session-based;
- trick names and progression relationships are comparatively discrete;
- riders already use checklists, notes, filming, and game-of-SKATE structures;
- the product works year-round and does not depend on resort access;
- skate shops, camps, instructors, and parents provide clear wholesale channels;
- the app already has substantial Trickipedia, rider, spot, and film context.

The second edition should be snowboarding after the skate format is validated. Surfing, BMX, scooter, MTB, skiing, and rollerblading should use the same system but receive sport-native page structures rather than simple word substitutions.

## Who it is for

Primary audiences:

- beginner and progressing riders who want a path rather than a random trick list;
- younger riders and parents looking for a constructive progression tool;
- instructors, camps, clubs, and after-school programs;
- returning riders rebuilding confidence and consistency;
- committed riders who want a permanent session archive;
- gift buyers who understand the sport but may not know which technical product to buy.

Avoid positioning it as a substitute for coaching, supervision, protective equipment, or judgment about terrain and conditions.

## Book structure

### 1. Set up your TrickBook

- owner name, start date, home spot, and optional TrickBook username;
- regular/goofy stance and basic equipment setup;
- current ability, confidence, and goals;
- QR/code to create or connect a TrickBook account;
- short explanation of the mark system used throughout the book.

Recommended progress marks:

- `SEEN` — understand what the trick is;
- `TRIED` — attempted intentionally;
- `LANDED` — completed once;
- `CONSISTENT` — repeatable in normal conditions;
- `OWNED` — can perform it with control, style, and variations.

The language should reward attempts and consistency without turning progression into a false certification system.

### 2. Foundations map

A visual dependency map shows the important foundations before named tricks:

- stance and pushing;
- rolling control and safe stopping;
- balance and body position;
- turning/carving;
- riding off small features;
- falling and risk awareness;
- switch exposure;
- terrain and session etiquette.

Each foundation links to the current digital lesson. The printed page explains why it matters and leaves space for a rider or coach to mark readiness.

### 3. Trick progression chapters

Organize chapters by progression family rather than alphabetically. A skate first edition might include:

- board control and manuals;
- ollies and obstacle fundamentals;
- shove-it family;
- kickflip/heelflip foundations;
- transition basics;
- grinds and slides;
- switch, fakie, and nollie introductions;
- lines, consistency, and style.

Every trick page should include:

- canonical name and useful aliases;
- a clear sequence illustration or small set of key positions;
- prerequisites and suggested next tricks;
- concise cues, not a wall of prose;
- common mistakes and a safe way to reduce difficulty;
- terrain/equipment notes;
- QR/NFC-friendly short code to the live Trickipedia page;
- attempt, landed, consistent, and owned dates;
- notes for stance, speed, obstacle, or personal cues;
- optional coach/witness field without implying formal accreditation.

### 4. Session logs

The session log is the repeat-use engine of the book. Each spread should capture:

- date, spot, conditions, and who was there;
- session goal and warm-up;
- tricks attempted and best make;
- fear/confidence before and after;
- one thing learned;
- one clip or photo reference;
- next-session intention;
- app sync code or a QR shortcut to log the session digitally.

Include both structured spreads and flexible dot-grid pages. Riders should not feel punished for missing a day or forced into a daily streak.

### 5. Spot and line pages

- sketch or photo-reference area;
- obstacle/terrain description;
- line order;
- speed and setup notes;
- hazards, permissions, hours, and etiquette reminders;
- QR shortcut to search or open the corresponding TrickBook spot;
- attempts and completion date.

### 6. Challenges and milestones

Use milestone pages that celebrate meaningful progression without encouraging unsafe escalation:

- first five-trick line;
- first trick filmed cleanly;
- first switch session;
- first new spot;
- first trick taught to a friend;
- comeback after a break;
- personal trick family completion;
- seasonal/year-end reflection.

### 7. Personal archive

The final section records:

- favorite tricks and spots;
- films, riders, and crews that mattered;
- injuries/breaks at a non-medical summary level;
- best clips and links;
- people met through riding;
- next-edition goals;
- a letter to the rider's future self.

This is what makes a completed book worth keeping.

## Connection to the app

### Durable links

Printed QR codes must point to stable TrickBook redirect URLs, never directly to fragile screen paths or third-party videos.

Example:

```text
https://thetrickbook.com/go/tb-skate-001
                         ↓
server resolves current canonical lesson
                         ↓
app deep link when installed, responsive web fallback otherwise
```

The redirect record should support:

- permanent printed code;
- destination changes without reprinting;
- sport, edition, printing, page, and campaign metadata;
- app/web fallback;
- privacy-conscious aggregate scan analytics;
- disabled/recalled destination state;
- locale-aware routing;
- offline-friendly human-readable short code.

Never require account creation merely to view the basic lesson promised by the printed page.

### Optional book linking

Each copy may include a one-time edition code that links the physical copy to an account and unlocks:

- digital checklist matching the edition;
- book-specific badges or profile shelf item;
- downloadable replacement session pages;
- companion prompts based on the current chapter;
- backup of milestone dates entered by the rider;
- a discount or trial for TrickBook Plus.

The printed book must remain fully useful without activation. Do not make paper pages a disguised software paywall.

### Data model

```javascript
physical_editions: {
  editionId,
  sport,
  title,
  version,
  locale,
  isbn,
  publishedAt,
  trickMapVersion,
  printings: []
}

physical_codes: {
  code,
  editionId,
  printingId,
  pageKey,
  destinationType,
  destinationId,
  active,
  replacementDestinationId
}

physical_activations: {
  activationHash,
  editionId,
  userId,
  activatedAt,
  source,
  status
}
```

Do not store raw activation codes after redemption. Treat scan analytics as product analytics, not surveillance.

## Editorial system

The printed taxonomy must derive from canonical Trickipedia IDs, not a separate spreadsheet of names. Before layout lock:

1. Freeze the edition's trick list and prerequisite graph.
2. Resolve aliases to canonical tricks.
3. Run instructor/editor review for progression order and safety language.
4. Validate every printed short code in staging and production.
5. Store the exact content/version snapshot used by the printing.
6. Create a corrections page that remains available for the life of the edition.

Digital lessons can improve after printing, but the destination must not silently change into a different trick or product offer.

## Format and manufacturing

### Prototype format

- 6×9 or 7×10 inches;
- lay-flat spiral or durable sewn binding for practical session use;
- matte, scuff-resistant cover;
- 140–220 pages depending on edition;
- mostly one- or two-color interior for affordable annotation;
- heavier uncoated paper that tolerates pencil and pen;
- strong page numbers and section edge markers;
- weather-resistant field notebook edition considered after validation.

Prototype with print-on-demand or a short digital run to avoid inventory risk. POD is for learning, not necessarily the final unit economics. Move to offset printing only after demand, page count, return rate, and wholesale interest are known.

### Accessibility and usability

- readable contrast and type size;
- no meaning conveyed by color alone;
- left-handed and gloved-use testing where relevant;
- plain-language cues with diagrams;
- captions/transcripts on linked videos;
- measurements in both imperial and metric where needed;
- avoid tiny QR codes near the binding;
- test codes after proofing, lamination/coating, and real-world wear.

## Monetization and distribution

### Initial offer

Recommended hypothesis to test—not final pricing:

- standard edition: **$24.99–$29.99**;
- book + three months of Plus bundle: **$39.99–$49.99**;
- coach/camp packs with facilitator guide and replaceable log pages;
- wholesale terms for independent shops, resorts, indoor parks, schools, and events;
- signed/artist-cover limited editions only after the core utility is proven.

The economics model must include printing, proofing, freight, storage, pick/pack, payment fees, damaged/returned copies, wholesale discount, creator/illustrator royalties, complimentary review copies, and unsold inventory.

### Sales channels

Launch in this order:

1. direct preorder through TrickBook;
2. local shop/instructor pilot;
3. events, camps, and resort/shop wholesale;
4. broader direct fulfillment;
5. Amazon or book distribution only when margins and returns are understood.

Use preorder deposits only with clear delivery windows and refund terms. Do not manufacture a large first run based on social engagement alone.

### Strategic value beyond book margin

Track:

- activated books and scans per active book;
- app registrations attributable to edition/page;
- repeat session-log use at 30/90 days;
- Plus conversion and retention from book owners;
- wholesale reorder rate;
- percentage completed versus abandoned;
- most-used trick chapters and missing progressions;
- gifting versus self-purchase;
- support and correction rate by printing.

The product may be valuable even at modest direct margin if it acquires durable, high-retention riders and creates a defensible instructor/shop channel.

## Legal, safety, and rights checklist

- Register and use the TrickBook trademark consistently; verify title/subtitle availability before ISBN and packaging.
- Secure written work-for-hire or license terms for illustrations, photography, guest writing, cover art, and athlete likenesses.
- Do not copy trick explanations, diagrams, or photography from other books/sites.
- Obtain permission for quotes, logos, sponsor marks, and recognizable private locations where required.
- Use a reviewed participation/safety disclaimer without suggesting the book guarantees safety.
- Avoid medical advice; direct injury, return-to-sport, and protective-equipment questions to qualified professionals.
- Review children's privacy implications before collecting activation or progress data from minors.
- Publish clear bundle/subscription terms and do not auto-enroll a book buyer without affirmative consent.
- Preserve revision, correction, recall, and printing records.
- Obtain an ISBN for retail/book-channel editions and confirm barcode/price requirements for each channel.

## Validation plan

### Discovery

Interview at least:

- 10 beginner/progressing riders;
- 5 parents of younger riders;
- 5 instructors/coaches/camp operators;
- 5 independent shops or resort retailers;
- 3 experienced riders who already keep notes or film sessions.

Test the problem, not only whether people “like the idea.” Ask what they record today, what gets abandoned, where phones are inconvenient, what they would carry, and what they have purchased before.

### Prototype 1: printable workbook

Create a 20–30 page skateboarding sample containing foundations, 8–12 tricks, two session spreads, one spot/line page, and real durable redirect codes. Give it to 20–30 riders for four weeks.

Success signals:

- at least half use it in more than one session;
- riders write on it without being prompted;
- QR lessons are scanned repeatedly, not only once during onboarding;
- progression order is understandable;
- instructors would use or recommend it;
- at least 30% express credible purchase intent at the proposed range.

### Prototype 2: bound pilot

Produce 50–100 short-run copies with two cover/binding options. Sell rather than give away most copies; paid behavior is the useful signal. Instrument edition codes and interview buyers after 30 and 90 days.

### Production gate

Approve a full first edition only after:

- editorial and safety review;
- stable canonical trick IDs and redirects;
- verified print quotes and contribution margin;
- a fulfillment/returns plan;
- at least three committed pilot retailers or program partners;
- demonstrated repeat use from the bound pilot;
- counsel review of rights, safety, privacy, and commercial terms.

## Delivery roadmap

### Phase 1 — concept recovery and validation (2–4 weeks)

- interview users and partners;
- inventory existing Trickipedia content suitable for print;
- define first-edition rider level and trick count;
- choose progress language and visual system;
- price POD/short-run prototypes.

### Phase 2 — printable prototype (3–5 weeks)

- create the sample workbook;
- implement durable redirect codes;
- recruit and observe the test cohort;
- revise progression, writing density, and session pages.

### Phase 3 — bound pilot (4–8 weeks)

- commission original illustrations and cover system;
- complete editorial/instructor review;
- manufacture 50–100 copies;
- test direct sales and 3–5 partner locations;
- measure repeat use, scans, conversion, and defects.

### Phase 4 — first retail edition (8–16 weeks)

- lock manuscript and art;
- legal/prepress/proof review;
- ISBN, barcode, metadata, and fulfillment setup;
- preorder and retail partner launch;
- connect activation and digital checklist to production.

### Phase 5 — sport system

- publish snowboarding second;
- turn the validated page grammar into an edition toolkit;
- add instructor guides and institutional packs;
- localize only after redirects, content, and support are locale-aware;
- release revised editions based on real progression data rather than arbitrary annual updates.

## Open decisions

- Was the original concept primarily a progression journal, a visual trick encyclopedia, or a hybrid?
- Is the first buyer the rider, parent, instructor, or gift buyer?
- Should editions target true beginners, beginner-to-intermediate progression, or one discipline family?
- Spiral lay-flat, sewn softcover, or weather-resistant field format?
- How much app functionality is bundled without reducing the usefulness of the standalone book?
- Should coaches receive a separate facilitator edition?
- Which contributors or athletes should shape the first edition?

These decisions should be settled through prototype use, not taste alone.

## Immediate next actions

1. Recover any original sketches, messages, or notes and reconcile them with this reconstruction.
2. Choose skateboarding foundations as the working first-edition hypothesis.
3. Select 8–12 existing Trickipedia lessons for a printable pilot.
4. Interview riders, parents, instructors, and shops.
5. Build permanent `/go/:code` redirects before printing any QR codes.
6. Price two prototype formats and produce a 20–30 page test workbook.
7. Recruit a four-week pilot cohort and measure actual repeat use.

