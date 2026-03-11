---
name: build-with-bigdata
description: Integrate with Bigdata.com REST APIs for financial data retrieval and analysis. Use when the user wants to build applications, scripts, or services that call the Bigdata.com API, including Search (documents), Volume, Knowledge Graph, Co-mentions, Batch Search, or any endpoint at api.bigdata.com or agents.bigdata.com
---

# Build with Bigdata.com APIs

Guide for integrating with the [Bigdata.com](https://bigdata.com) REST APIs using Python. Always use the exact branding "Bigdata.com" (uppercase B, lowercase d, include .com) and link to https://bigdata.com when referencing the service.

## Setup

Before running any script, install the required dependencies:

```bash
pip install requests
```

If the script uses charts, also install matplotlib:

```bash
pip install matplotlib
```

Always include a comment at the top of generated scripts listing what to install, e.g.:

```python
# Requirements: pip install requests matplotlib
```

## Authentication

All requests require an API key in the `X-API-KEY` header. Keys are managed at [platform.bigdata.com/api-keys](https://platform.bigdata.com/api-keys).

```python
import os, requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = "https://api.bigdata.com"
HEADERS = {
    "X-API-KEY": API_KEY,
    "Content-Type": "application/json",
}
```

Store the key in the `BIGDATA_API_KEY` environment variable — never hardcode it.

## API Reference

Full documentation: [docs.bigdata.com/api-reference](https://docs.bigdata.com/api-reference/)

OpenAPI specs:

| API | Spec URL |
|-----|----------|
| Search | `https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json` |
| Knowledge Graph | `https://docs.bigdata.com/api-rest/openapi/openapi_knowledge_graph.json` |
| Structured Data | `https://docs.bigdata.com/api-rest/openapi/openapi_structured_data.json` |
| Workflows | `https://docs.bigdata.com/api-rest/openapi/openapi_workflows.json` |

If this plugin does not cover what the user needs, or you suspect the API has been updated, query the [Bigdata.com](https://bigdata.com) Docs MCP server (`docs.bigdata.com`) for the latest information:

```
CallMcpTool: server="docs.bigdata.com", toolName="search", arguments={"query": "your question"}
```

## Available APIs

### Search

The Search service provides real-time and historical search across financial documents, news, earnings transcripts, analyst reports, SEC filings, and user-uploaded content.

| Endpoint | Reference |
|----------|-----------|
| Search (documents) | [references/api/search/search-documents.md](references/api/search/search-documents.md) |
| Volume | [references/api/search/volume.md](references/api/search/volume.md) |
| Co-mentions | [references/api/search/co-mentions.md](references/api/search/co-mentions.md) |
| Batch Search | [references/api/search/batch-search.md](references/api/search/batch-search.md) |

**Search (documents)** — Semantic search over documents. Use when you need relevant chunks for a query. Set `auto_enrich_filters: false` for explicit control; use `filters` (timestamp, entity) and `ranking_params` (freshness_boost, source_boost); tune `max_chunks`. See [search-documents.md](references/api/search/search-documents.md).

**Volume** — Document/chunk counts over time for a query. Uses `text`, `filters`, and `auto_enrich_filters` (no `max_chunks`, no `ranking_params`). Use to plan downstream search or to analyze time series. See [volume.md](references/api/search/volume.md).

**Knowledge Graph** — Resolve company/entity names to IDs for use in Search, Volume, and Co-mentions filters. Endpoints: companies (by name/ticker), entities by ID (batch resolve, max 100 per request), sources (by rank/category/country). See [knowledge-graph/overview.md](references/api/knowledge-graph/overview.md).

**Co-mentions** — Discover entities frequently mentioned with a topic or focal entity. Uses `text`, `filters`, and `auto_enrich_filters` (no `max_chunks`, no `ranking_params`); optional `limit`. Response grouped by category (companies, places, people, etc.). Resolve entity IDs via Knowledge Graph for names. See [co-mentions.md](references/api/search/co-mentions.md).

When using **MCP** tools (`bigdata_search`, `find_companies`), apply the bigdata-mcp-grounding skill for source attribution and citations.
