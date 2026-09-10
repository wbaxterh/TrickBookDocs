---
sidebar_position: 3
title: "Companion Intelligence Progress"
---

# Companion Intelligence Progress

Status: **Phases 1–3 and the multi-companion backend foundation are live in production** · Last verified: 2026-09-10

This is the implementation record for grounding TrickBook companions in platform data. The objective is not merely better chat: companions should answer with TrickBook tricks, tutorials, films, spots, riders, and user progression—and expose relationships a general-purpose model cannot know.

## Production snapshot

- **Backend:** production `master` at `355e1af` after promotion PR #27
- **Runtime:** `TB-Backend` and `trickbook-mcp` online under PM2
- **MCP surface:** health check reports **14 tools**
- **Verification:** 10/10 registry, RAG, embedding, and graph tests passing on the production host
- **Data isolation:** persona, bot identity, relationship profile, DM history, and bot-chat history are scoped per companion

## Phase 1 — platform tools and grounding

Shipped and deployed:

- `search_films` searches the published TrickBook film catalog by title, rider, producer, sport, and year and returns TrickBook deep links.
- `search_trickipedia` now returns aliases, curated tutorials, prerequisites, next steps, and Trickipedia deep links instead of discarding that data.
- `recommend_next_trick` uses a rider's completed tricks plus TrickBook's progression relationships to recommend a defensible next step.
- The system prompt prefers platform content, requires links when available, and avoids inventing external tutorials.

## Phase 2 — Atlas RAG

Shipped and deployed:

- The formerly missing `kaori-rag` module now contains document normalization, stable identities/content hashes, batched embeddings, ingestion, and retrieval.
- Knowledge sources cover Trickipedia, films, spots, and events.
- Embeddings are normalized vectors generated with one pinned model; the same model embeds the user's query.
- Atlas Vector Search performs semantic retrieval, while lexical matching supplies a fallback and protects useful exact terms.
- Retrieved records retain source metadata and deep links so the model can ground its answer in TrickBook.
- Dedicated PM2 indexing configuration supports repeatable refreshes without coupling indexing to API startup.

The retrieval flow is:

```text
platform document → normalized searchable text → embedding vector → Atlas index
user question → query embedding → semantic + lexical retrieval → grounded model context
```

Embeddings store meaning, not a copy of model knowledge. Texts such as “spin backwards on a rail” and “backside boardslide” can land near one another even without identical wording. The original source text and metadata remain the material shown to the model.

## Phase 3 — relationship graph

Shipped and deployed:

- A repeatable graph builder derives stable, evidence-aware edges from existing TrickBook records.
- The graph connects tricks, films, spots, riders, and progression evidence rather than introducing a second database prematurely.
- Four traversal tools are live:
  - `films_featuring_trick`
  - `tricks_at_spot`
  - `similar_tricks`
  - `learning_path`
- Existing progression data also powers `recommend_next_trick`.

This is the differentiating layer: a companion can traverse TrickBook's own relationships instead of asking the base model to guess them.

## Multi-companion backend foundation

Shipped and deployed after Phase 3:

- `companion-registry.js` loads companion definitions from JSON.
- `generateCompanionResponse` builds the persona dynamically; `generateKaoriResponse` remains as a compatibility wrapper.
- Registered companions share the same 14-tool, Atlas RAG, and graph capabilities.
- Profiles and histories are isolated by companion/bot identity.
- Unknown legacy characters retain the Eliza fallback path during migration.
- Kaori is the first registered production companion; adding another brain no longer requires editing the response engine.

## What remains

### P0 — prove and protect production behavior

1. Build a golden retrieval/evaluation set across tricks, films, spots, events, and graph questions; track recall@5, grounding/link accuracy, and correct tool choice.
2. Add endpoint rate limits, OpenRouter usage/cost telemetry, and structured logs for retrieval/tool failures.
3. Authenticate the Kith voice WebSocket, meter voice usage, and cap concurrent per-user sessions.
4. Automate RAG and graph refreshes after source changes, with freshness monitoring and alerts.

### P1 — finish the product loop

1. Return typed `richContent` from companion replies so the already-built mobile cards become tappable tricks, films, spots, and lists.
2. Add high-value action tools: nearby spots, save spot, link a landed trick to a spot/video, and read recent rider activity for coaching.
3. Add explicit citations/source labels to companion answers and refusal behavior when TrickBook has no supporting result.
4. Create and test the first additional companion definition—Tony is the current skateboard candidate—then expose roster ordering and capabilities through the API.
5. Remove Kaori-only client gates: hardcoded model/stage checks, bundled VRM assumptions, environment, voice, and trick-library selection.

### P2 — scale demonstration and monetization

1. Ship regular/goofy stance onboarding and stance-aware coaching.
2. Move VRM/models to CDN delivery and add a mocap/VRMA trick library alongside procedural demonstrations.
3. Add companion entitlements, free samples, voice-token allowances, and board/outfit unlocks.
4. Retire the Eliza fallback after every supported companion is registry-backed.

## Promotion history

- PR #23: Phase 2 implementation promoted to staging
- PR #24: Phase 3 implementation promoted to staging
- PR #25: Phases 2 and 3 promoted to production (`78874d8`)
- PR #26: registry-driven multi-companion engine promoted to staging
- PR #27: multi-companion engine promoted to production (`355e1af`)

