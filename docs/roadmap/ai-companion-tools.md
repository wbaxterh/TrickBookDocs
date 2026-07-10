---
sidebar_position: 6
title: "AI Companion Tool Calling"
---

# AI Companion Tool Calling — Implementation Plan

Status: **Shipped (2026)** — implemented as kaori-tools.js in TB-Backend with 8 tools on Gemini Flash via OpenRouter; see [Kaori AI Architecture](/docs/architecture/kaori) for the live system. This document is preserved as the original plan.

This document covers the full implementation of tool calling (function calling) for TrickBook's AI companions, enabling them to perform actions like creating tricklists, searching spots, and submitting new spots on behalf of users.

## Overview

**Goal:** Transform AI companions from chat-only bots into action-capable assistants that can read and write TrickBook data through natural conversation.

**Approach:** OpenRouter tool calling (native function calling API) integrated into the existing `kaori-server.js`. No framework dependencies (LangGraph, ElizaOS) — just clean tool definitions and a tool execution loop.

**Model:** `nousresearch/hermes-3-llama-3.1-70b` (already deployed, supports tool calling)

## Phase 1: Tool Calling Infrastructure

**Files modified:** `kaori-server.js`

### 1.1 Define Tool Schemas

Add tool definitions that get passed to every OpenRouter API call:

```javascript
const TOOLS = [
  {
    type: "function",
    function: {
      name: "search_spots",
      description: "Search TrickBook spots by name, city, state, country, or type. Use when user asks about spots, parks, or places to skate/ride.",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "Search term (spot name, city, etc.)" },
          type: { type: "string", enum: ["skatepark", "street", "diy", "snow"], description: "Filter by spot type" },
          limit: { type: "number", description: "Max results, default 5" }
        },
        required: ["query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "get_user_tricklists",
      description: "Get the current user's tricklists with trick names and completion status. Use when user asks about their lists, tricks they've landed, or progress.",
      parameters: {
        type: "object",
        properties: {
          listName: { type: "string", description: "Optional: filter to a specific list by name" }
        }
      }
    }
  },
  {
    type: "function",
    function: {
      name: "create_tricklist",
      description: "Create a new tricklist for the user. Use when user asks you to make them a list or suggests tricks they want to learn.",
      parameters: {
        type: "object",
        properties: {
          name: { type: "string", description: "Tricklist name" },
          tricks: { type: "array", items: { type: "string" }, description: "Trick names to add (matched against trickipedia)" },
          category: { type: "string", description: "Sport category: skateboard, snowboard, bmx, etc." }
        },
        required: ["name", "tricks"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "search_trickipedia",
      description: "Search the trickipedia for tricks. Use when user asks about specific tricks, how to do something, or wants trick suggestions.",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "Trick name or keyword" },
          category: { type: "string", description: "Optional: skateboard, snowboard, bmx" }
        },
        required: ["query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "create_spot_draft",
      description: "Submit a new spot for approval. Use when user shares a Maps link or describes a spot they want to add to TrickBook.",
      parameters: {
        type: "object",
        properties: {
          name: { type: "string", description: "Spot name" },
          mapsUrl: { type: "string", description: "Google or Apple Maps URL" },
          latitude: { type: "number", description: "Manual latitude if no maps URL" },
          longitude: { type: "number", description: "Manual longitude if no maps URL" },
          city: { type: "string" },
          state: { type: "string" },
          country: { type: "string" },
          type: { type: "string", enum: ["skatepark", "street", "diy", "snow", "mountain", "resort"] },
          description: { type: "string" }
        },
        required: ["name", "type"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "share_content",
      description: "Share a TrickBook item (spot, tricklist, trick) as a rich card in the chat. Use when you want to link the user to specific content.",
      parameters: {
        type: "object",
        properties: {
          type: { type: "string", enum: ["spot", "tricklist", "trick"] },
          id: { type: "string", description: "MongoDB ObjectId of the item" }
        },
        required: ["type", "id"]
      }
    }
  }
];
```

### 1.2 Tool Execution Loop

Modify the `/api/chat` endpoint to handle tool calls:

```javascript
app.post('/api/chat', async (req, res) => {
  const { userId, message } = req.body;
  
  // ... existing: save message, get history, build system prompt ...

  let messages = [{ role: 'system', content: systemPrompt }, ...history];
  let richContent = null;
  let iterations = 0;
  const MAX_ITERATIONS = 3; // prevent infinite tool loops

  while (iterations < MAX_ITERATIONS) {
    const response = await callOpenRouter(messages, TOOLS);
    const choice = response.choices[0];

    // If model wants to call a tool
    if (choice.finish_reason === 'tool_calls' || choice.message.tool_calls) {
      const toolCalls = choice.message.tool_calls;
      messages.push(choice.message); // add assistant's tool_calls message

      for (const tc of toolCalls) {
        const args = JSON.parse(tc.function.arguments);
        const result = await executeTool(tc.function.name, args, userId);
        
        // Capture rich content from tool results
        if (result.richContent) {
          richContent = result.richContent;
        }

        messages.push({
          role: 'tool',
          tool_call_id: tc.id,
          content: JSON.stringify(result.data)
        });
      }
      iterations++;
      continue; // let model generate final response with tool results
    }

    // Final text response
    const botResponse = choice.message.content;
    // Save and return with optional richContent
    return res.json({ response: botResponse, text: botResponse, richContent });
  }
});
```

### 1.3 Tool Executor

```javascript
async function executeTool(name, args, userId) {
  switch (name) {
    case 'search_spots':
      return await toolSearchSpots(args);
    case 'get_user_tricklists':
      return await toolGetTricklists(userId, args);
    case 'create_tricklist':
      return await toolCreateTricklist(userId, args);
    case 'search_trickipedia':
      return await toolSearchTrickipedia(args);
    case 'create_spot_draft':
      return await toolCreateSpotDraft(userId, args);
    case 'share_content':
      return await toolShareContent(args);
    default:
      return { data: { error: 'Unknown tool' } };
  }
}
```

## Phase 2: Read-Only Tools

Implement tools that only query data (no writes). Safe to ship first.

### 2.1 `search_spots`

```javascript
async function toolSearchSpots({ query, type, limit = 5 }) {
  const filter = {};
  if (type) filter.type = type;
  
  // Text search across name, city, state
  const regex = new RegExp(query, 'i');
  filter['$or'] = [
    { name: regex },
    { city: regex },
    { state: regex },
    { description: regex }
  ];

  const spots = await mongoDB.collection('ck_spots')
    .find(filter)
    .limit(limit)
    .project({ name: 1, city: 1, state: 1, country: 1, type: 1, rating: 1, imageUrl: 1 })
    .toArray();

  return {
    data: { spots, count: spots.length },
    richContent: spots.length > 0 ? {
      type: 'spots_list',
      data: spots.map(s => ({
        _id: s._id.toString(),
        name: s.name,
        city: s.city,
        state: s.state,
        rating: s.rating,
        imageUrl: s.imageUrl,
        deepLink: `trickbook://spot/${s._id}`
      }))
    } : null
  };
}
```

### 2.2 `get_user_tricklists` (refactored from existing)

Already works in `getUserContext()` — extract into a standalone tool function that returns structured data instead of text.

### 2.3 `search_trickipedia`

```javascript
async function toolSearchTrickipedia({ query, category }) {
  const filter = { name: new RegExp(query, 'i') };
  if (category) filter.category = new RegExp(category, 'i');
  
  const tricks = await mongoDB.collection('tricks')
    .find(filter)
    .limit(10)
    .project({ name: 1, category: 1, difficulty: 1, videos: 1 })
    .toArray();

  return { data: { tricks, count: tricks.length } };
}
```

## Phase 3: Write Tools

Tools that create/modify data. Need careful validation.

### 3.1 `create_tricklist`

```javascript
async function toolCreateTricklist(userId, { name, tricks, category }) {
  const { ObjectId } = require('mongodb');
  
  // Resolve trick names to ObjectIds from trickipedia
  const resolvedTricks = [];
  for (const trickName of tricks) {
    const trick = await mongoDB.collection('tricks')
      .findOne({ name: new RegExp('^' + trickName + '$', 'i') });
    if (trick) {
      resolvedTricks.push({ _id: trick._id, checked: false });
    }
  }

  // Create the tricklist using DBRef pattern (matches existing schema)
  const newList = {
    name: name,
    user: { '$ref': 'users', '$id': new ObjectId(userId) },
    tricks: resolvedTricks,
    category: category || 'skateboard',
    createdAt: new Date(),
    createdBy: 'kaori' // flag for AI-created lists
  };

  const result = await mongoDB.collection('tricklists').insertOne(newList);

  return {
    data: {
      _id: result.insertedId.toString(),
      name: name,
      trickCount: resolvedTricks.length,
      matchedTricks: resolvedTricks.length,
      requestedTricks: tricks.length
    },
    richContent: {
      type: 'tricklist_card',
      data: {
        _id: result.insertedId.toString(),
        name: name,
        trickCount: resolvedTricks.length,
        deepLink: `trickbook://tricklist/${result.insertedId}`
      }
    }
  };
}
```

### 3.2 `create_spot_draft`

```javascript
async function toolCreateSpotDraft(userId, args) {
  let { name, mapsUrl, latitude, longitude, city, state, country, type, description } = args;

  // Extract coordinates from Maps URL
  if (mapsUrl && (!latitude || !longitude)) {
    const coords = extractCoordinates(mapsUrl);
    if (coords) {
      latitude = coords.lat;
      longitude = coords.lng;
    }
  }

  const draft = {
    name,
    type: type || 'skatepark',
    latitude: latitude || null,
    longitude: longitude || null,
    city: city || null,
    state: state || null,
    country: country || null,
    description: description || null,
    mapsUrl: mapsUrl || null,
    submittedBy: userId,
    submittedVia: 'kaori',
    status: 'pending_approval',
    createdAt: new Date()
  };

  const result = await mongoDB.collection('spot_drafts').insertOne(draft);

  return {
    data: {
      _id: result.insertedId.toString(),
      name,
      status: 'pending_approval'
    },
    richContent: {
      type: 'spot_draft_confirmation',
      data: {
        _id: result.insertedId.toString(),
        name,
        city,
        state,
        status: 'pending_approval'
      }
    }
  };
}
```

### 3.3 `share_content`

```javascript
async function toolShareContent({ type, id }) {
  const { ObjectId } = require('mongodb');
  const oid = new ObjectId(id);

  if (type === 'spot') {
    const spot = await mongoDB.collection('ck_spots').findOne({ _id: oid });
    if (!spot) return { data: { error: 'Spot not found' } };
    return {
      data: { found: true },
      richContent: {
        type: 'spot_card',
        data: { _id: id, name: spot.name, city: spot.city, state: spot.state, rating: spot.rating, imageUrl: spot.imageUrl, deepLink: `trickbook://spot/${id}` }
      }
    };
  }
  // ... similar for tricklist, trick
}
```

## Phase 4: Backend API Routes

New routes in TB-Backend for admin/spot-draft management:

### `POST /api/spots/draft` — Create spot draft
### `GET /api/spots/drafts` — List pending drafts (admin)
### `PUT /api/spots/drafts/:id/approve` — Approve draft → create real spot
### `PUT /api/spots/drafts/:id/reject` — Reject draft

## Phase 5: Frontend Changes

### 5.1 Rich Message Rendering

Update `ConversationScreen` to detect `richContent` in messages and render the appropriate card component:

```jsx
{message.richContent && (
  <RichContentCard
    type={message.richContent.type}
    data={message.richContent.data}
    onPress={(deepLink) => Linking.openURL(deepLink)}
  />
)}
```

### 5.2 Card Components

- `<SpotCard>` — Image, name, city, rating, tap to navigate
- `<TricklistCard>` — Name, trick count, sport icon, tap to navigate
- `<TrickCard>` — Name, difficulty badge, category, tap to navigate
- `<SpotDraftCard>` — Name, location, "Pending Approval" badge
- `<SpotsList>` — Horizontal scroll of `SpotCard`s

### 5.3 File Upload in DM

Add image picker button to DM compose bar. Upload via existing media endpoint, pass URL to bot with the message.

### 5.4 Maps Link Detection

Auto-detect Google Maps and Apple Maps URLs in user messages. Show a "Create Spot?" prompt or let Kaori handle it naturally via tool calling.

## Phase 6: dm.js Updates

Update `generateKaoriResponse` to pass through `richContent`:

```javascript
async function generateKaoriResponse(content, db, conversationId, senderId) {
  return new Promise((resolve, reject) => {
    // ... existing HTTP call to kaori-server ...
    res.on('end', () => {
      const parsed = JSON.parse(data);
      resolve({
        text: parsed.response || parsed.text,
        richContent: parsed.richContent || null
      });
    });
  });
}
```

Update the message-sending code to store `richContent` on the `dm_messages` document.

## Rollout Order

| Step | What | Risk | Effort |
|------|------|------|--------|
| 1 | Tool calling infrastructure in kaori-server.js | Low | 2h |
| 2 | `search_spots` + `search_trickipedia` + `get_user_tricklists` | Low | 2h |
| 3 | Test tools work via curl | Low | 30m |
| 4 | `create_tricklist` | Medium | 2h |
| 5 | `create_spot_draft` + Maps URL parsing | Medium | 3h |
| 6 | `share_content` | Low | 1h |
| 7 | Update dm.js to pass richContent | Low | 1h |
| 8 | Frontend: rich message rendering + card components | Medium | 4h |
| 9 | Frontend: file upload in DM | Medium | 3h |
| 10 | Spot draft admin approval flow | Low | 2h |

**Total estimated effort: ~20 hours**

## Safety & Guardrails

- **Rate limiting:** Max 5 write operations per user per hour via bot
- **Validation:** All tool inputs validated before execution (name length, coordinate ranges, etc.)
- **Audit trail:** `createdBy: 'kaori'` flag on all AI-created content
- **Spot moderation:** AI-submitted spots go to `spot_drafts` (pending approval), not directly to `ck_spots`
- **No deletion tools:** Bots can create and read, but never delete user data
- **Tool loop limit:** Max 3 tool call iterations per message to prevent runaway
