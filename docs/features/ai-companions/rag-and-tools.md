---
sidebar_position: 6
title: "RAG & Internal Tools"
---

# Making Companions Smart — RAG & Internal Tool Calls

Status: **Current state audited + architecture researched 2026-07-12**

The goal: companions that **RAG on our own knowledgebase** (Trickipedia, coaching content, the docs) and **operate TrickBook itself** through internal tool calls — tricklists, spots, videos, feed. This page documents exactly what exists today, the full inventory of tool-call targets, and the recommended architecture.

:::tip Related pages
Hub: [AI Companions](/docs/features/ai-companions) · Brain internals: [Kaori AI Architecture](/docs/architecture/kaori) · Original plan (historical): [AI Companion Tool Calling](/docs/roadmap/ai-companion-tools)
:::

## What exists today

### The tool loop

`kaori-ai-response.js` calls OpenRouter (`google/gemini-3.5-flash`, `tool_choice: 'auto'`, `max_tokens: 400`, temp 0.7, non-streaming, no model fallback) in a loop capped at **3 iterations**. The 8 shipped tools (`kaori-tools.js`):

| Tool | Reads | Writes | Guardrails |
|------|-------|--------|------------|
| `search_spots` | `spots` (approved only) | — | disclosure instruction for off-DB suggestions |
| `search_trickipedia` | `trickipedia` (regex on name/description) | — | truncated results |
| `get_user_tricklists` | `tricklists` + `tricks` | — | last 3 lists, 5 tricks each |
| `create_tricklist` | — | `tricklists` | `createdBy: 'kaori'`, scoped to user |
| `add_trick_to_list` | `tricklists` | `tricks` + list push | ownership check |
| `update_trick_status` | `tricks`, `tricklists` | `tricks` | ownership via `list_id` |
| `lookup_boardsport_knowledge` | `kaori-knowledge.json` (in-memory) | — | — |
| `remember_user_info` | — | `companion_profiles` (upsert) | rejects empty input |

No `richContent` mechanism exists on the backend — tool results are plain JSON fed back to the model, replies are plain text. (Mobile already ships the [card renderer](/docs/features/ai-companions/mobile-app#rich-content-cards) waiting for this.)

### The "knowledgebase" — and why it must be replaced

`kaori-knowledge.json` is the entire knowledge layer: **~1,570 words** of hand-curated JSON across 5 sports (magazines / instagram / events / culture each). "Retrieval" is exact enum-key dictionary access — `topic: 'all'` dumps a whole sport object into context. Its limits, precisely:

- **No search** — the tool schema's enums are the only retrieval mechanism
- **No article content** — despite the system prompt claiming knowledge of "Torment Mag articles"
- **Factually corrupted** — many Instagram handles are hallucinated/garbled (e.g. `@toraboramag` for what should be Torment's handle); do not treat its contents as verified
- **Frozen** — event dates/venues are static text with no update path

**The RAG hook exists but is dead code:** `queryRAGContext()` requires `./kaori-rag/kaori-query` inside a try/catch — the directory does not exist (a remnant of the retired pgvector setup), so `ragContext` is always empty and silently so. The system-prompt injection slot it feeds is a useful hook to keep.

### Memory (working today, worth knowing)

Cross-surface history merges the last 8 `dm_messages` + last 8 `bot_chats` chronologically into a 12-message window, deduped against the current prompt. On top: `companion_profiles` (relationship stage by interaction count — stranger `<5` → acquaintance `<20` → friend `<60` → close_friend `<150` → bestie — plus name, sports, known facts, last mood), injected into the system prompt each turn.

### What doesn't exist yet

No per-user rate limiting on the AI endpoints, no usage metering (`requireVoiceTokens` from the [monetization plan](/docs/roadmap/monetization) is not built), no OpenRouter spend tracking. Non-Kaori bots have **no working brain** — `botChat.js` routes them to the dead ElizaOS hop and a canned fallback; `dm.js` answers every bot as Kaori regardless of character. Multi-companion = the brain needs a persona/character parameter.

## Tool-call targets — the REST surface companions can grow into

The backend already exposes everything the vision needs. Inventory by area (all JWT-auth'd via `x-auth-token` unless noted):

| Area | Routes | Best companion tools to build |
|------|--------|-------------------------------|
| **Tricklists** | `/api/listings` (CRUD, visibility, public lists) | ✅ mostly covered by shipped tools |
| **Tricks** | `/api/listing` (CRUD, trick→spot link, trick→video attach) | link a landed trick to a spot/clip — the "did you land it" loop |
| **Trickipedia** | `/api/trickipedia` (public read; name/category/difficulty/steps) | upgrade `search_trickipedia` from regex to hybrid vector search |
| **Spots** | `/api/spots` (search, map-pins, my-spots, saved, one-tap save, photos, Places proxies) | `save_spot`, "spots near me" with geo, spot details/photos |
| **Spot lists** | `/api/spotlists` (subscription-gated) | ⚠️ writes hit the paywall middleware — companion writes interact with entitlements |
| **Spot reviews / trick history** | `/api/spot-reviews`, `/api/spot-tricks` ("who did what trick here", verify/upvote) | spot lore — strong conversational material |
| **Videos / media** | `/api/media` (library, collections, featured, search by sport), `/api/upload` (Bunny) | surface tutorial videos for a trick; register views |
| **Feed** | `/api/feed` (posts, reactions, comments, trick/spot linking) | read the user's sessions to coach on; posting *as* a companion is a product decision (bots are `users` docs — they can author) |
| **Users / homies** | `/api/user` (stats, activity), `/api/users` (homies graph) | personalize coaching from real stats |

### trickbook-mcp: not what it sounds like

`repos/trickbook-mcp` is a **devops MCP server** (query API, PM2 status/restart, SSH logs, project list over stdio) — not a companion tool layer. It's also unmaintained: not a git repo, not registered in any MCP config, stale hardcoded project paths, and its `query_api` sends `Authorization: Bearer` where the backend expects `x-auth-token`. Treat it as a from-scratch rebuild candidate, not a foundation.

## Recommended architecture

### 1. Vector store: MongoDB Atlas Vector Search

We're already on Atlas, and **Vector Search works on every tier** in 2026 (including free M0; Flex at $8–30/mo supports Search, Vector Search, and Change Streams). Embeddings live next to the Trickipedia/spots data, reusing the `db` handle the tool executor already receives — no new infrastructure.

```js
// index: { type: 'vectorSearch', fields: [
//   { type: 'vector', path: 'embedding', numDimensions: 1536, similarity: 'cosine' },
//   { type: 'filter', path: 'sport' }, { type: 'filter', path: 'docType' } ] }
const hits = await db.collection('knowledge_chunks').aggregate([
  { $vectorSearch: { index: 'knowledge_vec', path: 'embedding',
      queryVector: qVec, numCandidates: 100, limit: 5,
      filter: { sport: 'snowboarding' } } },
  { $project: { text: 1, source: 1, score: { $meta: 'vectorSearchScore' } } },
]).toArray();
```

`$vectorSearch` must be the first pipeline stage; at our corpus size (thousands of chunks) `exact: true` ENN is fine. **The sport pre-filter is the highest-leverage precision trick** — a "kickflip" query should never retrieve BMX content; the model already emits a sport enum in today's knowledge tool, so carry that pattern forward.

### 2. Embeddings: cheap and pinned

`text-embedding-3-small` (1536d, **$0.02/M tokens**) — and OpenRouter now serves embeddings (`POST /api/v1/embeddings`, OpenAI-compatible), so the existing OpenRouter key covers chat *and* embeddings. Our whole corpus (Trickipedia + docs + coaching content) is well under 5M tokens: **a full embed costs ~$0.10**. Rule: pin one embedding model + dimension per index forever — query and corpus vectors must come from the same model, so specify the exact model, never a router alias.

### 3. Chunking by source

- **Trickipedia:** one chunk per trick (split >512-token tricks by field, prepend the trick name to every chunk); metadata `{sport, trickName, difficulty, trickId}` so results can deep-link.
- **Docusaurus docs:** header-based structural chunking (split on `#/##/###`, heading path in metadata) — the strongest default for markdown.
- **Coaching content:** author it *as* chunks — one tip/drill/progression per doc, 100–400 tokens, tagged `{sport, skillLevel, topic}`.

### 4. Retrieval-as-a-tool (agentic RAG)

Most Kaori turns are social and need zero retrieval — always-on RAG would waste cost and latency on every "what's up." The right pattern for a chat companion is **the model decides to search**, which is exactly the architecture we already have (`tool_choice: 'auto'`):

- Replace `lookup_boardsport_knowledge`'s static-JSON body with a **`search_knowledge(query, sport?, docType?)`** tool backed by `$vectorSearch`.
- Upgrade `search_trickipedia` from regex to hybrid regex + vector.
- Keep the existing `ragContext` system-prompt slot for *push*-style context (user's stance/sport, session summary); tools handle *pull*-style knowledge.
- **Skip reranking initially** — with sport pre-filtering at this corpus size, top-5 vector hits are usually right; add Cohere Rerank ($2/1k searches) only if the eval below shows recall problems.

### 5. Harden the tool loop (do this alongside)

Known Gemini-Flash-via-OpenRouter issues make these worth fixing before the tool count grows:

- **Raise `MAX_ITERATIONS` 3 → 5–6** (a RAG turn is realistically search → refine → answer), and stop counting transient API errors against the tool budget.
- On the final iteration, **force a text answer with `tool_choice: 'none'`** instead of returning the canned "hmm that got complicated" string.
- **Log tool-argument `JSON.parse` failures** instead of silently executing with `{}` — arg hallucination currently degrades invisibly.
- **Keep tool descriptions terse** — Gemini Flash via OpenRouter has documented failures with many long tool descriptions; prefer one consolidated `search_knowledge` over per-source tools.
- Keep pushing the assistant tool-call message back **verbatim** (Gemini 3.x `thought_signature` requirement — the current code already does this correctly).
- Add an OpenRouter **`models` fallback array** (e.g. `anthropic/claude-haiku-4.5`, the strongest small model on multi-turn tool use) so provider outages and tool-heavy turns don't burn iterations.

### 6. One tool registry, many consumers

Extract the tool bodies out of `kaori-tools.js` into a transport-agnostic registry module (zod schema + handler taking `{db, userId}` per tool), then adapt it twice:

1. **In-process** for the brain (OpenAI-format definitions + executor — zero network hop; do *not* make the brain call itself over MCP/HTTP on the same box).
2. **MCP server** as a second transport for Claude Desktop/Code and future agents — stdio locally (avoids the OAuth 2.1 requirement network MCP servers carry). User-scoped tools must take an explicit user-context binding; an MCP client must never be able to impersonate arbitrary users.

This "define once, many consumers" shape is current best practice, and it's also how a rebuilt product-focused `trickbook-mcp` should be built — wrapping the same registry, not duplicating it.

### 7. Freshness + eval

- **Trickipedia:** re-embed per document — simplest is a `reembedTrick(id)` call inside the existing update routes; MongoDB Change Streams (Flex+) are the event-driven upgrade.
- **Docs:** a hash-diff upsert script (chunk → content hash → upsert changed, delete orphans) run on docs deploy or daily cron. A weekly full rebuild costs cents and is an acceptable safety net.
- **Eval before tuning:** 50–200 golden queries mapped to expected chunk IDs, measure recall@5/MRR (under $0.10 per run; bootstrap by generating questions *from* the chunks). Plus ~20 transcript assertions that the model calls `search_knowledge` for knowledge questions and *doesn't* for small talk — the decision failure reranking can't fix.

## Cost summary

Atlas: $0 extra on an existing paid tier (else Flex $8–30/mo) · embeddings ~$0.10 one-time + pennies/mo · reranking deferred ($0) · chat unchanged (Haiku fallback only on tool-heavy turns) · eval under $1/mo. **Total incremental: roughly a coffee per month.** The work is in the plumbing, not the bill.

## Build order

1. Shared tool registry extraction + tool-loop hardening (no behavior change, de-risks everything after)
2. `knowledge_chunks` collection + Atlas vector index + embed Trickipedia and the coaching-relevant docs
3. `search_knowledge` tool + hybrid `search_trickipedia`; retire `kaori-knowledge.json`
4. Golden-set eval; iterate chunking/filters
5. New action tools in priority order: `save_spot` / spots-near-me → tutorial-video surfacing → trick↔spot/video linking → feed reads
6. `richContent` on tool results → the mobile card renderer lights up
7. Product MCP entrypoint over the same registry
