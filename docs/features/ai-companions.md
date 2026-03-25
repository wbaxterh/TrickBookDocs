---
sidebar_position: 5
title: AI Companions
---

# AI Companions

TrickBook's AI Companions are intelligent chat agents that live inside the app's DM system. They can have natural conversations, access your TrickBook data, and **perform actions on your behalf** — creating tricklists, finding spots, and more.

:::tip Deep Dive
For the full technical architecture, diagrams, and implementation details, see [**Kaori AI Architecture**](/docs/architecture/kaori).
:::

## Current Companions

### Kaori 🏔️
- **Character:** Based on Kaori Nishidake from SSX Tricky
- **Personality:** Japanese snowboarder, Gen Z texting energy, chaotic but sweet
- **Model:** Gemini 2.0 Flash via OpenRouter (with tool calling)
- **Specialties:** Snowboarding, trick advice, TrickBook features, snowboard industry news
- **Knowledge:** RAG-powered with 566 embedded chunks from Torment Magazine + snowboard industry sources

### Planned
- **Tony** 🛹 — Skateboard companion
- **Rico** 🏄 — Surf companion
- **Max** 🚲 — BMX companion
- **Zoe** ⛷️ — Ski companion

## What Can Kaori Do?

### Conversational
- Natural chat with personality (not a corporate chatbot)
- Remembers your conversation history (20-message context window)
- Knows snowboard industry news via RAG knowledge base

### Tool Actions
- **Search spots** — "any parks near Brooklyn?" → returns tappable spot cards
- **View your tricklists** — "what's on my HOMESICK list?" → shows your tricks with completion status
- **Create tricklists** — "make me a beginner park list" → creates a real tricklist in your account
- **Search trickipedia** — "how do I do a backside 180?" → finds tricks with tutorials
- **Submit new spots** — paste a Google Maps link → creates a spot draft for admin review
- **Share content** — shares spots, tricklists, or tricks as interactive cards in chat

### Rich Content Cards
When Kaori performs an action, she can embed interactive cards in the chat:
- **Spot cards** — photo, name, city, rating → tap to view spot
- **Tricklist cards** — name, trick count → tap to open list
- **Trick cards** — name, difficulty, tutorials → tap to learn
- **Spot draft confirmations** — shows pending approval status

## How It Works (Overview)

```
User sends DM → dm.js detects bot → forwards to Kaori Server v2
→ Builds context (history + user data + RAG)
→ Calls OpenRouter with tool definitions
→ Model may call tools (search spots, create list, etc.)
→ Returns text + optional rich content cards
→ Frontend renders message with interactive cards
```

Every user gets Kaori as an automatic friend ("homie") on signup. She appears in the AI Companions section of the Homies screen with a green "Online" indicator.

## Safety & Guardrails

- **No deletion tools** — Kaori can create and read, but never delete your data
- **Spot moderation** — AI-submitted spots go to a review queue, not directly live
- **Rate limits** — Max 5 write operations per user per hour
- **Audit trail** — All AI-created content flagged with `createdBy: 'kaori'`
- **No canned responses** — If the AI fails, she says so honestly instead of faking it
- **Tool loop limit** — Max 3 tool call iterations per message

## Implementation Status

| Feature | Status |
|---------|--------|
| Basic chat with personality | ✅ Live |
| Conversation memory (PostgreSQL) | ✅ Live |
| TrickBook data context | ✅ Live |
| RAG snowboard knowledge | ✅ Live |
| Auto-homie on signup | ✅ Live |
| Tool calling (search, create, share) | ✅ Live |
| `search_spots` | ✅ Live |
| `get_user_tricklists` | ✅ Live |
| `create_tricklist` | ✅ Live |
| `search_trickipedia` | ✅ Live |
| `create_spot_draft` | ✅ Live |
| `share_content` | ✅ Live |
| Rich chat message rendering (frontend) | 🔧 In Progress |
| Frontend card components | 🔧 In Progress |
| AI Companions section on Homies screen | 🔧 In Progress |
| Spot draft admin approval flow | 📋 Planned |
| File uploads in DM | 📋 Planned |
| Additional companions (Tony, Rico, etc.) | 📋 Planned |
