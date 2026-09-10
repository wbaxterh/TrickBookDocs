---
title: TrickBook MCP
description: Connect AI assistants and agents to TrickBook's action-sports knowledge.
---

# TrickBook MCP

TrickBook provides a public, read-only Model Context Protocol (MCP) server for AI assistants and agents.

**Server URL:** `https://api.thetrickbook.com/mcp`

The connector searches TrickBook's curated action-sports data and returns source links that an assistant can include in its answer. No TrickBook account or API key is required for the public tools.

## Available tools

- `search_spots` — find skateparks, resorts, surf breaks, and other places to ride
- `get_spot` — retrieve public details for a specific spot
- `search_trickipedia` — find trick tutorials and progression information
- `get_trick` — retrieve a specific trick tutorial and progression data
- `search_events` — find upcoming competitions, premieres, and community events
- `get_event` — retrieve full details for an event
- `search_films` — search TrickBook's action-sports film catalog
- `lookup_boardsport_knowledge` — look up boardsport culture, media, events, and organizations

All tools are read-only. Personal trick lists, saved spots, account details, and administrative data are not exposed.

## Connect from Claude

1. Open **Customize → Connectors**.
2. Select **Add custom connector**.
3. Enter `https://api.thetrickbook.com/mcp`.
4. Name it **TrickBook** and enable it for a conversation.

On Team and Enterprise plans, an organization owner must add the connector before members can enable it.

## Connect from ChatGPT

1. Enable developer mode under **Settings → Apps → Advanced settings**.
2. Create a custom app and enter `https://api.thetrickbook.com/mcp` as the MCP endpoint.
3. Scan the tools, create the app, and enable it in a new chat.

ChatGPT plan and workspace policies determine whether custom MCP apps are available.

## Connect from an MCP client

Use Streamable HTTP transport with the server URL:

```json
{
  "mcpServers": {
    "trickbook": {
      "type": "http",
      "url": "https://api.thetrickbook.com/mcp"
    }
  }
}
```

The server is stateless and accepts MCP requests over HTTPS `POST`. A health response is available at `https://api.thetrickbook.com/mcp/health`.

## Example prompts

- “Use TrickBook to find skateparks around Minneapolis.”
- “What snowboard events are coming up in Colorado?”
- “Find a tutorial for a backside boardslide.”
- “What trick should I learn after a kickflip?”
- “Find snowboard films featuring this rider.”

## Usage and attribution

Clients should preserve the `source_url` returned by tools when presenting TrickBook data. Automated bulk extraction, resale of the data, and attempts to access non-public information are prohibited.
