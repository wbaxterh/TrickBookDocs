---
title: Instagram Automation
description: Operating model and safeguards for TrickBook's automated Instagram engagement and creator-research sessions.
---

# Instagram Automation

TrickBook operates two separate Instagram-related cron workflows. One may perform limited public engagement; the other is research-only. Keeping those scopes separate is an important safety and reporting boundary.

The live cron registry is the source of truth for whether a job is enabled and when it runs. The values below were verified on September 15, 2026.

## Public engagement and reply sessions

**Job:** `trickbook-ig-comment-replies-funny`  
**Job ID:** `a74aa68b-87bd-431a-b935-f3637c61ea70`  
**Schedule:** `17 9,13,17 * * *` in `America/Los_Angeles`  
**Runs:** 9:17 AM, 1:17 PM, and 5:17 PM Pacific daily  
**Execution:** isolated agent session, immediate wake, no routine delivery announcement  
**Browser identity:** OpenClaw browser profile `openclaw`  
**Activity log:** `C:\Users\wesle\clawd\trickbook-engagement-log.md`

### Session workflow

1. Open Instagram as `@trickbook.app` and inspect new notifications first.
2. Identify comments that are eligible and do not already have a TrickBook reply.
3. Draft four short, context-specific reply candidates.
4. Score the candidates for humor, relatability, natural tone, soft conversion, and brand safety.
5. Post only the strongest candidate.
6. Verify that the reply appears and that no duplicate was created.
7. Log the timestamp, post link, candidates, scores, winner, confirmation, counts, and skipped reasons.
8. If there are no eligible inbound replies, optionally perform a small outbound pass on no more than two relevant skate or snowboard posts.

### Voice and safety rules

- Replies must relate to the actual post or comment.
- Keep replies to one or two lines.
- Use zero to two context-appropriate emojis; never force or repeat them mechanically.
- Do not use generic filler, fake personal identity, or unsupported location/personal-experience claims.
- Do not duplicate a previous reply or engagement.
- Outbound comments are non-salesy; conversion language should remain soft.
- Skip uncertain, sensitive, hostile, restricted, or already-handled items.
- Browser failure is a valid no-action result. Never claim an interaction succeeded without verification.
- The automation does not publish feed posts, send DMs, negotiate partnerships, or speak as Wes.

### Why the job exists

The job keeps the account responsive and creates a limited amount of authentic participation between publishing cycles. Its success should be judged by meaningful conversations, profile visits, qualified app traffic, and signups—not raw comment count.

## Creator research and CRM refresh

**Job:** `TrickBook Instagram skate creator research`  
**Job ID:** `379d79e8-59e9-4ead-a384-743c378f4100`  
**Schedule:** `30 6 * * *` in `America/New_York`  
**Runs:** 6:30 AM Eastern daily  
**Execution:** isolated agent session, immediate wake, 20-minute timeout, no routine delivery announcement  
**Runbook:** `C:\Users\wesle\clawd\trickbook-crm\deployment\cron-refresh-prompt.md`

This job discovers and rechecks skateboard tutorial/progression creators, verifies public profile signals, deduplicates candidates, and inserts or refreshes research records in the TrickBook CRM.

It is strictly research-only:

- No follows, likes, comments, replies, or DMs.
- No external outreach.
- No changes to human-managed CRM fields.
- Public information must be verified before it is recorded.
- Existing records should be refreshed rather than duplicated.
- Production health should be checked after ingest.

This research pool supports later pro tutorial recruitment, but outreach requires a separate, explicitly approved workflow.

## Monitoring and incident handling

For both jobs:

- Check the cron registry for last status, duration, consecutive errors, and next run.
- Review the relevant log or CRM ingest result before attributing an outcome to automation.
- Treat timeouts, stale browser references, login challenges, comment restrictions, and missing composers as no-action conditions.
- Preserve evidence of partial runs; never convert an attempted action into a reported success.
- Repeatedly failing jobs should be paused or repaired instead of retrying risky UI actions indefinitely.
- Schedule changes must preserve adequate runtime buffers so gateway-heavy jobs do not overlap and interrupt one another.

## Measurement

Public engagement should report:

- Eligible inbound comments found.
- Replies posted and verified.
- Duplicate/safety/restriction skips.
- Outbound comments posted and verified.
- Profile visits, tagged-link sessions, and signups when attribution exists.

Creator research should report:

- New qualified creators inserted.
- Existing creators refreshed.
- Rejected or deferred candidates by reason.
- CRM total and ingest health.
- Candidates later approved for outreach or tutorial production.

Do not use likes or comments alone as proof of acquisition. Use tagged links and signup events wherever possible.

## Related marketing workflow

The engagement cron supports, but does not replace, the tutorial publishing and monetization system described in [Content and Value Ladder](./content-and-value-ladder.md). Human-created tutorials remain the primary acquisition asset; automation handles bounded response and research work around them.
