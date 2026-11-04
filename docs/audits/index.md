---
title: Audits
description: Dated TrickBook product and engineering audits, evidence, priorities, and remediation tracking.
sidebar_position: 1
---

# Audits

Dated inspections of TrickBook's live experience and supporting systems. Each audit records what was tested, what worked, reproducible failures, evidence, and acceptance criteria for fixes.

An audit is a point-in-time record, not a claim that every finding is still present. Keep the original observations intact and record subsequent remediation separately with issue, PR, and verification links.

## Audit log

<div style={{ overflowX: 'auto' }}>

| Date | Audit | Coverage | Results | Follow-up |
| --- | --- | --- | --- | --- |
| 2026-11-04 | [Website responsive UX and Kaori](./website-responsive-ux-2026-11-04.md) | 150 route/viewport samples, 12 base sizes, breakpoint tests, targeted WebKit checks | 14 findings: 6 P1, 7 P2, 1 P3. Desktop foundation is strong; mobile navigation and Kaori need reliability fixes. | Findings recorded as UX-01 through UX-14; GitHub issues not yet filed. |

</div>

## How to use an audit

1. Read its scope and limitations before interpreting a pass or failure.
2. Use the stable finding ID and anchor when creating a GitHub issue in the repository that owns the fix.
3. Carry the reproduction details, evidence, and acceptance criteria into the issue. Split cross-cutting findings into smaller issues when appropriate, retaining the parent finding ID.
4. Update the audit's finding register with the issue and implementation PR links.
5. Mark a finding verified only after repeating its acceptance checks on the relevant deployed environment. A merged PR alone is not verification.

**Priority definitions:** P1 = broken task, serious access problem, material resource waste, or trust issue; P2 = meaningful usability/accessibility friction; P3 = polish. These are audit priorities, not production incident severities.

## Historical reviews

Older reviews remain at their original URLs to preserve existing links:

- [Kaori system audit — May 2026](../architecture/kaori-audit-2026-05.md) — superseded architectural snapshot.
- [Signup and onboarding audit](../roadmap/signup-onboarding-audit.md).
- [Companions launch review](../roadmap/companions-launch.md).

New audits belong in this section. Include an audit date, live environment, method, coverage, limitations, successful behavior, prioritized findings, evidence, and verification criteria. Do not publish credentials, signed media URLs, private messages, or raw analytics payloads as evidence.
