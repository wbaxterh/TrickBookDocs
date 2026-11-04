---
title: Website responsive UX audit — November 4, 2026
description: Playwright audit of 150 TrickBook route/viewport samples, with 14 prioritized findings covering Kaori, mobile navigation, discovery, media loading, and trust.
sidebar_label: 2026-11-04 — Website UX and Kaori
sidebar_position: 2
---

# TrickBook responsive UX audit

**Live site:** https://thetrickbook.com · **Audit date:** November 4, 2026 · **Method:** Playwright browser testing and read-only source review

**Record status:** Audit complete; remediation not started in this change. The finding IDs below are stable references for subsequent GitHub issues. Issue creation is a separate follow-up; no finding is being represented as fixed.

## Finding register

<details>
<summary>14 open findings — 6 P1, 7 P2, 1 P3</summary>

<div style={{ overflowX: 'auto' }}>

| ID | Priority | Finding | Remediation status | GitHub issue |
| --- | --- | --- | --- | --- |
| [UX-01](#ux-01) | P1 | Tablet header wraps and blocks Kaori's sign-in close control | Open | Not filed |
| [UX-02](#ux-02) | P1 | Kaori account gate clips on short screens | Open | Not filed |
| [UX-03](#ux-03) | P1 | Landscape menu hides login and signup | Open | Not filed |
| [UX-04](#ux-04) | P1 | Media search leads to a 404 | Open | Not filed |
| [UX-05](#ux-05) | P1 | Feed initializes offscreen video streams | Open | Not filed |
| [UX-06](#ux-06) | P1 | Privacy promise conflicts with analytics | Open | Not filed |
| [UX-07](#ux-07) | P2 | Kaori modal does not manage keyboard focus | Open | Not filed |
| [UX-08](#ux-08) | P2 | Kaori text and touch controls are undersized | Open | Not filed |
| [UX-09](#ux-09) | P2 | Floating chat preview obscures core content | Open | Not filed |
| [UX-10](#ux-10) | P2 | Event and shop filters delay useful phone results | Open | Not filed |
| [UX-11](#ux-11) | P2 | Spots presents inconsistent totals | Open | Not filed |
| [UX-12](#ux-12) | P2 | Controls lack accessible names and adequate hit areas | Open | Not filed |
| [UX-13](#ux-13) | P2 | Couch poster request returns HTTP 400 | Open | Not filed |
| [UX-14](#ux-14) | P3 | Semantic structure and editorial polish are inconsistent | Open | Not filed |

</div>

</details>

## Verdict

**Desktop is a solid foundation. Mobile is not uniformly broken, but navigation and Kaori have real, reproducible failures. Fix those before investing in a visual redesign.**

The core content layouts generally adapt successfully from 320px phones through 1920px desktops. The broad sweep found no document-level horizontal overflow or uncaught JavaScript exceptions. However, a layout fitting inside the viewport does not mean all its controls are usable: fixed headers, oversized menus, and floating chat elements obscure important actions.

Your concern about Kaori is justified, with an important distinction: **the guest widget opens and accepts typing on normal portrait phones. Sending the first message intentionally opens an account gate.** I did not authenticate, so this audit does not establish whether signed-in AI replies, voice, or video calls fail on mobile.

### Fix first

1. Repair Kaori's short-height layout and its collision with the tablet header.
2. Make the expanded mobile menu scrollable; keep login/signup reachable in landscape.
3. Fix the media search button, which leads to a 404.
4. Stop offscreen feed videos from downloading immediately.
5. Reconcile the privacy promise with the analytics actually running.

## Coverage and limitations

### Screen-size matrix

<div style={{ overflowX: 'auto' }}>

| Class | Viewports tested, CSS pixels | Assessment |
|---|---|---|
| Small phones | 320×568, 360×800, 375×667 | Content reflows; chat takes substantial space; short-height and touch-target concerns |
| Current phones | 390×844, 430×932 | Core cards/search are readable; floating chat competes with content and video controls |
| Phone landscape | 667×375 | **Fail:** menu account actions fall below screen; Kaori sign-in content clips |
| Portrait tablets | 768×1024, 820×1180 | Main layouts are generally successful; persistent chat still obscures content |
| Tablet/small desktop | 1024×768 | **Fail:** desktop navigation wraps and overlaps Kaori's sign-in close control |
| Laptops/desktops | 1280×800, 1440×900, 1920×1080 | Stronger visual hierarchy and usable space; shared functional/accessibility defects remain |

</div>

Additional boundary checks: widths **599, 600, 601, 1023, 1024, 1025**. Short-height stress tests: **320×300 and 390×300**, plus a manual 390×360 check. These are constrained-viewport simulations, **not a real software-keyboard test**.

- **150 route/viewport samples:** ten primary routes at twelve sizes, plus ten secondary/detail routes at three sizes. One additional recorded error is a Kaori interaction failure at 1024px, not an extra page sample.
- Primary routes: home, TrickBook, Spots, Events, Shops, Riders, Couch, Feed, login, signup.
- Secondary/detail routes: about, blog, contact, privacy, terms, Ollie lesson, Kill Harry film, Kaori Live guest screen, media search, France spots.
- Chromium for the broad sweep; **WebKit corroboration of Kaori at 390×844, 667×375 and 1440×900**, plus the landscape menu. Windows WebKit is not an actual iPhone or full Safari certification.
- Phone contexts used mobile/touch emulation. Screenshots include different pixel densities; layout measurements are CSS pixels.
- Default dark theme was the main test surface. Representative light-theme home/chat captures are supplementary, not a complete light-theme contrast audit.
- Browser automation and local source inspection only. No source edits, deployments, account creation, contact submissions, reactions, uploads, or purchases. Normal page visits generated ordinary analytics/heartbeat traffic.
- No physical iOS/Android keyboard, screen reader, microphone/camera, signed-in chat, billing, throttled-network benchmark, or Core Web Vitals certification. No invented Lighthouse scores.
- `thetrickboo.com`, the originally supplied URL, failed DNS resolution. The working TrickBook domain was used instead.

## What is working

- **Desktop presentation:** clear visual hierarchy, legible headline, strong primary CTA, useful product imagery and consistent branding.
- **Responsive content:** Trickipedia changes from a single phone column to wider grids; shop/event forms stack instead of overflowing. All 150 page samples had no measured document-level horizontal overflow. Some intentional carousels contain offscreen items; those are not automatically defects.
- **Trick discovery:** typing “ollie” updated results to relevant tricks. The lesson contains concrete instructions, safety guidance, credited tutorials and progression suggestions.
- **Couch filtering:** selecting Skateboarding produced skateboard films and persisted the sport in the URL after settling.
- **Kaori portrait basics:** launcher, greeting, typing, account-gate presentation and gate dismissal worked at the ordinary portrait sizes. Escape closed chat in eleven completed chat-flow samples. The 1024px flow was interrupted by the blocked account-gate close button.
- **Draft protection:** the guest draft survived closing the gate. “Use email instead” reached the login URL with a Kaori callback, and `tb_kaori_widget_pending_draft` retained the test text. Restoration after successful login remains untested.
- **Contact form:** readable, explicitly labeled fields; no submission was made.

## Prioritized findings

**P1:** broken task, serious access problem, material resource waste, or trust issue. **P2:** meaningful friction/accessibility issue. **P3:** polish. These are audit priorities, not claims of production incident severity.

### UX-01 · P1 · Tablet header wraps and blocks Kaori's sign-in close control {/* #ux-01 */}

**Confirmed at 1024×768; wrap/overlap also visible in adjacent breakpoint checks.** Navigation moves to a second row, and “Sign up free” wraps into a tall, narrow button. The header is approximately **171px high**, while Kaori starts at y=136. Playwright's ordinary click on **Close sign in** timed out because the site header intercepted pointer events. This reproduced in the main sweep and the independent breakpoint probe.

**Likely source:** `styles/global.css:325–345` fixes the header above everything with `z-index: 999999`; desktop navigation begins at 1024px (`:845–866`). `components/KaoriWidget.module.css:1–5` uses z-index 1100. The local source is consistent with the symptom; deployed commit parity was not established.

**Fix:** keep navigation collapsed until its actual content fits, prevent the signup label wrapping, and establish a small shared layer scale. Put modal UI above navigation, preferably through a portal rather than escalating arbitrary z-index values.

**Accept:** at 1023/1024/1025 and 1100/1280px, header/account actions fit; both chat close controls remain visible and normally clickable.

![Tablet header wraps and covers Kaori's sign-in close control at 1024×768](/img/audits/2026-11-04/kaori-1024x768-auth.png)

### UX-02 · P1 · Kaori's account gate clips on short screens {/* #ux-02 */}

**Confirmed in Chromium and WebKit at 667×375.** The avatar and bottom reassurance text extend outside the chat panel. More seriously, at **390×300**, “Use email instead” starts around y=295, below the dialog's bottom at y=287; it is clipped and unavailable through normal tapping. At 320×300, the Apple option is partially clipped too.

**Likely source:** the panel hides overflow; `.authGate` centers a tall stack with 30px padding but has no scrollable overflow. Landscape switches to the desktop-width widget because the mobile rule is only `max-width: 600px`. The existing portrait rule already uses `100dvh`; simply replacing `vh` everywhere is not the whole fix.

**Fix:** a mobile full-screen sheet with a stable header, scrollable body, and visible composer/sign-in actions. Allow the auth gate to scroll from its top, reduce decorative content at short heights, and account for safe areas and the visual viewport.

**Accept:** no essential control is clipped at 320px width or 300px available height; rotation and opening/closing an actual iOS/Android keyboard preserve typing and dismissal.

![Kaori sign-in gate clips email access at a constrained 390×300 viewport](/img/audits/2026-11-04/focused-chromium-390x300-auth.png)

[WebKit landscape corroboration at 667×375](/img/audits/2026-11-04/focused-webkit-667x375-auth.png)

### UX-03 · P1 · Landscape mobile menu hides login and signup {/* #ux-03 */}

At **667×375**, the expanded fixed header's menu extends to y≈626. Login is at y≈560 and signup at y≈549. The menu has `overflow-y: visible`, not its own scrolling. A wheel-scroll probe left those account links in the same offscreen positions. WebKit reproduced the layout.

**Fix:** constrain the expanded menu to the available viewport height, use internal vertical scrolling, keep the toggle/close reachable, and manage background scrolling deliberately.

**Accept:** a rider can open the menu and reach every link, theme/language option and account action by touch in portrait and landscape, including 320×568 and 667×375.

![Expanded landscape menu in WebKit, with account actions below the visible viewport](/img/audits/2026-11-04/focused-webkit-landscape-menu.png)

### UX-04 · P1 · Media search leads to a 404 {/* #ux-04 */}

The magnifying-glass link in the media header points to **`/media/search`**, which returned **404** at phone, tablet and desktop widths. This is a broken discovery task, not a cosmetic problem.

**Fix:** implement the destination or replace the link with a working inline search. Give the icon an accessible name and remove nested button/link semantics.

**Accept:** clicking media search exposes a labeled search field; a real query yields results or a helpful empty state, not a 404.

![Media search destination returns a 404 on a phone viewport](/img/audits/2026-11-04/extra-media-search-390.png)

### UX-05 · P1 · Feed initializes many offscreen video streams {/* #ux-05 */}

On a fresh **390×844** feed visit, **without scrolling or pressing play**, the eight-second observation recorded **17 video elements, requests for 17 distinct CDN stream IDs, and 131 CDN requests**. This demonstrates unnecessary upfront loading; it is not a measured battery or mobile data-plan benchmark.

**Likely source:** `components/media/FeedPost.js:208–223` mounts every `VideoPlayer`. Its intersection observer controls autoplay, but `components/media/VideoPlayer.js:34–94` initializes HLS and loads the source regardless of visibility. Pausing autoplay does not prevent downloading.

**Fix:** render posters for distant items, attach HLS only near the viewport or on explicit play, stop loading offscreen streams, clean up players, and limit simultaneous buffering. Respect reduced-data preferences where available.

**Accept:** before interaction, only the visible/nearby item may initialize; distant feed items make no stream-segment requests. Compare transferred bytes on a repeatable constrained-network run.

**Evidence:** [published measurement summary](#measurement-summary) and source pointers above. Request counting used a fresh mobile/touch context with no scrolling or playback interaction; see the [evidence provenance](#evidence-and-reproducibility) for the retained local traces.

### UX-06 · P1 · Privacy promise conflicts with observed analytics {/* #ux-06 */}

The public privacy page states **“No tracking pixels or third-party analytics”** and **“No behavioral profiling or ad targeting.”** Browser network inspection observed requests to PostHog, including successful event traffic. Local `lib/posthog.js:12–17` enables PostHog with `autocapture: true`.

This establishes an analytics-disclosure mismatch; it does **not** establish data sale, advertising use, or the truth of other claims such as message encryption.

**Fix:** have the product/privacy owner reconcile disclosure and implementation, including what is collected, retention and consent requirements. Do not just silently remove the promise or add a generic banner without review.

**Accept:** the published policy accurately describes actual third-party traffic and collection behavior.

### UX-07 · P2 · Kaori's modal does not manage keyboard focus {/* #ux-07 */}

After opening the sign-in dialog, focus stayed on **Reply to Kaori** behind it. Tabbing visited the gate's four buttons, then escaped to the document, home link, navigation and hero CTA despite `aria-modal="true"`.

**Fix:** use an accessible dialog primitive with initial focus, focus containment, inert background, predictable Escape behavior and focus restoration. The project already depends on Radix Dialog.

**Accept:** Tab/Shift+Tab stay inside the modal; closing returns focus to its invoking control; screen-reader navigation agrees with the visual state.

**Evidence:** The recorded focus sequence was Reply to Kaori → Close sign in → Google → Apple → email → document body → home link → navigation → hero CTA. Focus did not move into the modal when it opened, and it escaped the modal after the email action.

### UX-08 · P2 · Kaori mobile text and touch controls are undersized {/* #ux-08 */}

The chat textarea computes to **13px** at every measured size; the close control is **34×34px** and send is **42×42px**. The input is small for sustained mobile conversation. Sub-16px inputs are a known iOS focus-zoom risk, **not a reproduced physical-iPhone result here**.

**Fix:** use at least 16px input text on mobile, a readable message size, and approximately 44×44px touch areas for key actions. Add `min-width: 0` to the shrinking composer area when refactoring.

**Accept:** typing on an actual iPhone does not unexpectedly zoom or hide the composer; controls are comfortable to tap at 320px width.

### UX-09 · P2 · Kaori's floating preview competes with core content {/* #ux-09 */}

The persistent launcher and greeting cover the bottom-right of trick cards, feed video controls, and the contact page's Back to Home action. The preview adds another band of content obstruction on phones. It has no separate visible dismiss action.

**Fix:** use a compact launcher on phones, make the greeting dismissible, suppress it during media viewing/forms or after dismissal, and reserve clearance where a fixed launcher remains.

**Accept:** the last visible card/form/media action is reachable without opening Kaori or guessing a scroll position. Validate with the chat closed as well as open.

![Kaori launcher covers part of the contact page's Back to Home action](/img/audits/2026-11-04/extra-contact-390.png)

[Feed overlap at 390×844](/img/audits/2026-11-04/media-tab-feed-390x844.png)

### UX-10 · P2 · Event and shop filters consume the phone's first screen {/* #ux-10 */}

At 390px, Shops allocates roughly the first **600px** to heading/filter/toolbar UI before the first result image; its first shop title is around **y=945**. Events has a similar dense filter stack, with the first event title around **y=1008**. This is not overflow: it is excessive setup before useful discovery.

**Fix:** show search plus one important filter, then a “Filters (n)” sheet for advanced criteria. Keep a result count and location action close to actual results. Prefer practical defaults over requiring every choice upfront.

**Accept:** the initial 390×844 screen exposes a meaningful first result or clear preview, and advanced filters remain available in one tap.

[Shops at 390×844](/img/audits/2026-11-04/shops-390x844.png) · [Events at 390×844](/img/audits/2026-11-04/events-390x844.png)

### UX-11 · P2 · Spots presents inconsistent totals {/* #ux-11 */}

The same unfiltered Spots screen displayed **“4,961 spots · 43 countries”** and **“7,819 spots worldwide.”** List mode was built from the former grouping. The UI does not explain different datasets or completeness.

**Likely source:** `lib/apiSpots.js:53–71` fetches a maximum of 5,000 records and groups them client-side; `pages/spots.js:274–327` excludes unknown state groups when counting; `components/SpotsMap.js` uses the separate map-pins endpoint. Exact reconciliation requires backend/data review, but the display inconsistency is confirmed.

**Fix:** use authoritative server totals and consistent filter semantics for map/list; paginate instead of downloading the directory just to calculate counts. Clearly distinguish displayed results from global totals.

**Accept:** map/list totals reconcile for identical filters, or the scope difference is explicitly labeled.

### UX-12 · P2 · Key controls lack names and adequate hit areas {/* #ux-12 */}

The TrickBook search input has no associated label or ARIA name; its nearby “Search tricks...” text is not a programmatic label. The mobile sidebar toggle is unnamed. Phone Spots map/list/add icon buttons and the media search control also lack names in the accessibility snapshot. Feed controls include unlabeled 20×20px buttons; signup's password-visibility button measures 16×16px.

**Fix:** add explicit labels, stateful accessible names and enlarged clickable areas; use a single link or button per action rather than nesting them. These are targeted DOM findings, not a complete WCAG conformance verdict.

**Accept:** each interactive icon announces its purpose and state, keyboard order is sensible, and core phone controls meet a 44px touch-area design target. Check label wrappers before treating a small native checkbox itself as a failure.

### UX-13 · P2 · Couch poster request consistently returns HTTP 400 {/* #ux-13 */}

The Next image optimizer returned **400** for the JW Player poster with media ID `VrCg12aD` across all twelve broad-sweep sizes. The page stayed usable and the broken-image detector did not consistently retain a failed visible image, so fallback behavior may hide the error. It is still a repeatable content/network defect.

**Fix:** check remote-image allowlisting, upstream availability and query handling; provide a stable poster fallback. Do not infer that every film image is broken.

**Accept:** this poster loads successfully or a deliberate fallback displays without repeated 400 requests.

### UX-14 · P3 · Semantic structure and editorial polish are inconsistent {/* #ux-14 */}

Home, TrickBook and some detail layouts contain nested main landmarks; TrickBook, About and the Ollie page lack an H1. The blog includes an “AI Companions for Action Sports” card with a bare **“By”** and no visible author/date. Footer X and YouTube links point to the platforms' generic homepages rather than a TrickBook profile.

**Fix:** one primary main landmark, a meaningful page H1, sensible heading levels, conditional author/date rendering, and real social destinations or no link.

**Accept:** key templates have a coherent heading outline; no empty attribution or placeholder destination is published.

## Recommended Kaori mobile interaction

**Keep the personality; simplify the container.**

1. Closed: compact, dismissible launcher that does not cover primary page controls.
2. Open on phones: a full-height sheet, not a desktop chat box squeezed above page content.
3. Stable header: Kaori identity, AI disclosure and a large close action; optional voice/video under a secondary action.
4. Scrollable conversation: `flex: 1; min-height: 0; overflow-y: auto`, with deliberate overscroll behavior.
5. Stable composer: 16px text, growing textarea with a capped height, large send button, keyboard/safe-area accommodation.
6. Guest state: make “Sign in to send” clear before the first submission. Preserve the draft and return to it after authentication.
7. Account gate: an accessible, scrollable dialog that never removes email or close access on short screens.

This is a proposed direction, not an implemented design or a claim that the backend needs replacement.

## Implementation order and validation

<div style={{ overflowX: 'auto' }}>

| Batch | Scope | Proof before release |
|---|---|---|
| 1 — reliability | UX-01/02/03/04: header, mobile menu, Kaori shell/gate, media search | Click-through at 320/390/667/768/1024/1280 widths; short-height checks; real phone keyboard and rotation |
| 2 — access and mobile cost | UX-05/07/08/09/12: lazy video, focus, input sizes, overlay clearance, labels | Network-request budget; keyboard focus tests; touch and screen-reader smoke test |
| 3 — discovery and trust | UX-06/10/11/13/14: policy alignment, compact filters, totals, posters, semantics | Owner-approved policy; map/list count assertions; result visibility; no known 404/400 assets |

</div>

### Required device checks after fixes

- iPhone Safari: small and large phones, keyboard shown/hidden, rotation, browser bars expanded/collapsed, safe-area padding and increased text size.
- Android Chrome: narrow phone, keyboard and Back-button behavior, slow network, scrolling and media playback.
- Tablet: 768/820 portrait and approximately 1024 landscape, including header and modal collisions.
- Desktop: 1280/1440/1920, keyboard-only operation and 200% browser zoom.
- Signed-in Kaori: open → connect → send → receive → retry on failure; long messages; reconnect; allowance exhausted; voice permission rejection; explicit text-only fallback. Verify draft restoration after Google/Apple/email login without duplicate sends.

### Signals to monitor

- Kaori opened → draft entered → account gate → authentication completed → first message sent → response received, segmented by viewport/device and authentication state.
- Failed sends, reply latency, early closes and repeated opens; never log raw message content merely to measure the funnel.
- Mobile search-to-result/detail rate and time to first useful result.
- Feed initial transferred bytes, stream initialization count, stalled playback and errors.
- Menu/account-navigation failures, 404s, image errors and user feedback about covered controls.

Existing local analytics includes Kaori events such as `kaori_opened`, `kaori_account_wall_viewed`, `kaori_message_sent`, `kaori_message_failed` and `kaori_response_completed`. Reuse appropriately once collection/disclosure is reconciled.

## Measurement summary

<div style={{ overflowX: 'auto' }}>

| Probe | Observed result | Interpretation |
| --- | --- | --- |
| Primary route/viewport coverage | 120 page samples; all HTTP 200; no measured document-level horizontal overflow or uncaught page exceptions | Layout foundation works; not a guarantee of usability or accessibility |
| Secondary route/viewport coverage | 30 page samples: 27 HTTP 200 and three HTTP 404 | Media search was the 404 at all three sizes |
| Kaori guest flows | Eleven completed dismissal/draft checks; one interrupted at 1024px by intercepted account-close clicks | Portrait basics work; tablet layering fails |
| Tablet header | About 171px high at 1024×768; header z-index 999999 versus widget 1100 | Wrapped header covers the account-gate close target |
| Landscape menu | Menu bottom about y=626 at 667×375; login y≈560; signup y≈549; overflow visible | Account actions remain outside the viewport after scroll attempt |
| Short-height Kaori gate | At 390×300, dialog bottom y=287; email action begins y≈295 | Email access is clipped in the constrained-viewport simulation |
| Fresh Feed, first eight seconds | 17 video elements; 17 distinct CDN stream IDs requested; 131 CDN requests | Offscreen streams initialize before interaction |
| Spots, unfiltered | Header 4,961 spots; map 7,819 spots worldwide | Dataset/count scope is inconsistent or unexplained |
| Couch poster | HTTP 400 at all twelve primary sizes for JW Player media ID `VrCg12aD` | Repeatable poster loading defect |
| Privacy policy | Says no third-party analytics; PostHog assets/flags and event traffic observed | Disclosure/implementation mismatch requires owner review |

</div>

## Supporting captures

These captures document successful layouts as well as failures. Image pixels may be 2× CSS dimensions because phone contexts used device pixel ratio 2.

![Desktop home with readable headline, primary action, and product imagery at 1440×900](/img/audits/2026-11-04/home-1440x900.png)

![TrickBook cards successfully reflow into two columns at 768×1024](/img/audits/2026-11-04/trickbook-768x1024.png)

[Portrait guest chat opens and accepts typing at 390×844](/img/audits/2026-11-04/kaori-390x844-open.png)

## Evidence and reproducibility

**Source reviewed:** [TrickBookWebsite](https://github.com/wbaxterh/TrickBookWebsite), local HEAD `1de4424`, working tree clean at audit start. Source paths above refer to that checkout; they are not proof the live deployment ran the same commit.

The original report, Playwright scripts, and detailed JSON traces remain in the audit operator's local archive, `reports/trickbook-ux-audit-2026-11-04`. This page publishes the findings, measurements, and twelve selected screenshots; it does **not** expose raw request logs, signed playback URLs, local machine paths, or analytics payloads. Reproduce fixes against the relevant deployed environment using the viewport matrix and per-finding acceptance criteria above.

The retained local evidence consists of `results.json` (120 primary samples plus the separate chat error), `focused-results.json` (breakpoints/WebKit), `journey-results.json` (30 secondary samples and five interactions), `probe-results.json` (feed and navigation measurements), `verification-results.json` (rechecks/light theme), and the five Playwright scripts `audit.cjs`, `focused.cjs`, `journeys.cjs`, `probes.cjs`, and `verify.cjs`.

**Interpretation cautions:** document overflow was measured, not every clipped descendant. Navigation cancellations (`ERR_ABORTED`) for previous-page analytics/video requests are not confirmed site failures. A transient old URL after switching media tabs is not treated as a confirmed routing bug. One-off homepage image failures were not consistently reproduced and are not escalated. The repeatable media-poster 400 is tracked separately. In primary JSON records, `height` is document height; use `viewport.h` for viewport height.

**Rider outcome targeted:** open coaching, find a trick/spot/event, and watch a clip without fighting the screen. **Trust checks performed:** live navigation, result filtering, guest draft retention, focus traversal, short-height/breakpoint geometry, cross-engine corroboration and source review. **No fixes were applied**, so improved rider outcomes remain the acceptance goal rather than a measured result.
