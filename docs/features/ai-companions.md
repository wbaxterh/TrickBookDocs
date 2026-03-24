---
sidebar_position: 5
title: AI Companions
---

# AI Companions

TrickBook's AI Companions are intelligent chat agents that live inside the app's DM system. They can have natural conversations, access your TrickBook data, and **perform actions on your behalf** — creating tricklists, finding spots, and more.

## Current Companions

### Kaori 🏔️
- **Character:** Based on Kaori Nishidake from SSX Tricky
- **Personality:** Japanese snowboarder, Gen Z texting energy, chaotic but sweet
- **Model:** Hermes 3 Llama 3.1 70B via OpenRouter
- **Specialties:** Snowboarding, trick advice, TrickBook features, snowboard industry news

### Planned
- **Tony** 🛹 — Skateboard companion
- **Rico** 🏄 — Surf companion
- **Max** 🚲 — BMX companion
- **Zoe** ⛷️ — Ski companion

## Architecture

```
User (Mobile App / Web)
  └─ DM Message
      └─ TB-Backend (dm.js)
          └─ HTTP POST localhost:3001/api/chat
              └─ kaori-server.js
                  ├── Character personality (kaori.json)
                  ├── Conversation memory (PostgreSQL)
                  ├── TrickBook data (MongoDB)
                  ├── RAG knowledge base (pgvector)
                  └── OpenRouter LLM + Tool Calling
                      └─ Tool execution (create list, search spots, etc.)
                          └─ Response with optional rich content
```

### Data Stores

| Store | Purpose | Tech |
|-------|---------|------|
| MongoDB (TrickList2) | App data — tricklists, spots, users, feed | Atlas cluster |
| PostgreSQL (elizaos) | Conversation history, RAG embeddings | Local on EC2 |
| pgvector | Snowboard news embeddings (384-dim) | Extension on Postgres |

## Tool Calling (Function Calling)

AI companions can execute actions through OpenRouter's tool calling API. When a user's message implies an action (e.g., "make me a park tricklist"), the model selects the appropriate tool, executes it, and returns the result embedded in the conversation.

### Available Tools

#### `search_spots`
Search for skate/snow spots by name, city, or type.

```json
{
  "name": "search_spots",
  "description": "Search TrickBook spots by name, city, state, country, or type",
  "parameters": {
    "query": "string — search term",
    "type": "string — optional: skatepark, street, diy, snow",
    "limit": "number — max results (default 5)"
  }
}
```

**Returns:** Array of spot objects with `_id`, `name`, `city`, `state`, `type`, `rating`. Rendered as tappable spot cards in chat.

#### `get_spot_details`
Get full details for a specific spot.

```json
{
  "name": "get_spot_details",
  "description": "Get full details for a spot including address, photos, reviews",
  "parameters": {
    "spotId": "string — MongoDB ObjectId of the spot"
  }
}
```

**Returns:** Full spot object. Rendered as a rich spot card with photo, map link, and "View Spot" button.

#### `get_user_tricklists`
Fetch the current user's tricklists with trick names.

```json
{
  "name": "get_user_tricklists",
  "description": "Get all tricklists for the current user with trick names and completion status",
  "parameters": {
    "listName": "string — optional: filter to a specific list name"
  }
}
```

**Returns:** Array of tricklists with resolved trick names and `checked` status.

#### `create_tricklist`
Create a new tricklist for the user with specified tricks.

```json
{
  "name": "create_tricklist",
  "description": "Create a new tricklist for the user with given tricks from trickipedia",
  "parameters": {
    "name": "string — list name",
    "tricks": "string[] — array of trick names to add (matched against trickipedia)",
    "category": "string — optional: skateboard, snowboard, bmx, etc."
  }
}
```

**Returns:** Created tricklist with `_id` and deep link. Rendered as a tappable "View Tricklist" card.

#### `search_trickipedia`
Search the trickipedia for tricks by name or category.

```json
{
  "name": "search_trickipedia",
  "description": "Search trickipedia for tricks by name, category, or difficulty",
  "parameters": {
    "query": "string — trick name or keyword",
    "category": "string — optional: skateboard, snowboard, etc."
  }
}
```

**Returns:** Matching tricks with name, category, difficulty, tutorial links.

#### `create_spot_draft`
Create a new spot submission from a Maps URL or manual coordinates.

```json
{
  "name": "create_spot_draft",
  "description": "Create a spot draft for approval from a Google/Apple Maps link or coordinates",
  "parameters": {
    "name": "string — spot name",
    "mapsUrl": "string — optional: Google or Apple Maps URL (lat/lng extracted automatically)",
    "latitude": "number — optional: manual latitude",
    "longitude": "number — optional: manual longitude",
    "city": "string — optional",
    "state": "string — optional",
    "country": "string — optional",
    "type": "string — skatepark, street, diy, snow, etc.",
    "description": "string — optional description"
  }
}
```

**Returns:** Draft spot object pending admin approval. Confirmation card shown in chat.

#### `share_content`
Share a spot, tricklist, or trickipedia entry as a rich card in the chat.

```json
{
  "name": "share_content",
  "description": "Share a TrickBook item as a tappable card in the conversation",
  "parameters": {
    "type": "string — 'spot' | 'tricklist' | 'trick'",
    "id": "string — MongoDB ObjectId of the item"
  }
}
```

**Returns:** Rich card with preview image, title, subtitle, and deep link.

## Rich Chat Messages

When a tool returns a result, the bot message includes structured `richContent` alongside the text response. The frontend renders this as interactive cards.

### Message Schema Extension

```javascript
// dm_messages collection
{
  _id: ObjectId,
  conversationId: ObjectId,
  senderId: "69c15e55c7ebe2c6884f1267", // Kaori's user ID
  content: "omg yes here's a solid park list for you!! 🔥",
  richContent: {
    type: "tricklist_card",  // or "spot_card", "trick_card", "spot_draft_confirmation"
    data: {
      _id: "...",
      name: "Park Essentials",
      trickCount: 8,
      deepLink: "trickbook://tricklist/..."
    }
  },
  timestamp: Date,
  read: false
}
```

### Card Types

| Type | Description | Frontend Component |
|------|-------------|--------------------|
| `spot_card` | Spot with photo, name, city, rating | `<SpotCard>` — tappable, navigates to spot detail |
| `tricklist_card` | Tricklist with name, trick count, sport | `<TricklistCard>` — tappable, navigates to list |
| `trick_card` | Trickipedia entry with name, difficulty, video | `<TrickCard>` — tappable, navigates to trick |
| `spot_draft_confirmation` | Confirmation that a spot draft was submitted | `<DraftCard>` — shows pending status |
| `spots_list` | Multiple spot results from search | `<SpotsList>` — scrollable horizontal cards |

## Maps URL Parsing

When a user pastes a Google Maps or Apple Maps link, the system extracts coordinates:

```javascript
// Supported URL formats:
// Google Maps: https://maps.google.com/?q=40.7128,-74.0060
// Google Maps: https://www.google.com/maps/place/.../@40.7128,-74.0060,...
// Google Maps: https://goo.gl/maps/... (resolved via redirect)
// Apple Maps: https://maps.apple.com/?ll=40.7128,-74.0060
// Apple Maps: https://maps.apple.com/?address=...

function extractCoordinates(url) {
  // Google Maps @lat,lng pattern
  const googleAt = url.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
  if (googleAt) return { lat: parseFloat(googleAt[1]), lng: parseFloat(googleAt[2]) };
  
  // Google Maps ?q=lat,lng pattern
  const googleQ = url.match(/[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)/);
  if (googleQ) return { lat: parseFloat(googleQ[1]), lng: parseFloat(googleQ[2]) };
  
  // Apple Maps ?ll=lat,lng
  const apple = url.match(/[?&]ll=(-?\d+\.\d+),(-?\d+\.\d+)/);
  if (apple) return { lat: parseFloat(apple[1]), lng: parseFloat(apple[2]) };
  
  return null;
}
```

## File Uploads in DM

Users can attach images to messages sent to AI companions. Photos are:
1. Stored via existing media upload pipeline
2. URL passed to the bot as context
3. Used for spot submissions (spot photo) or trick clip sharing

## Implementation Status

| Feature | Status |
|---------|--------|
| Basic chat with personality | ✅ Done |
| Conversation memory (postgres) | ✅ Done |
| TrickBook data context (tricklists, spots) | ✅ Done |
| RAG snowboard knowledge | ✅ Done |
| Auto-homie on signup | ✅ Done |
| OpenRouter tool calling | 🔧 In Progress |
| `search_spots` tool | 🔧 In Progress |
| `get_user_tricklists` tool | 🔧 In Progress |
| `create_tricklist` tool | 📋 Planned |
| `create_spot_draft` tool | 📋 Planned |
| `search_trickipedia` tool | 📋 Planned |
| `share_content` tool | 📋 Planned |
| Rich chat message rendering | 📋 Planned |
| Maps URL parsing | 📋 Planned |
| File uploads in DM | 📋 Planned |
| Frontend card components | 📋 Planned |
