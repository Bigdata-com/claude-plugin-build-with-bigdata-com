---
name: build-with-bigdata
description: Integrate with Bigdata.com REST APIs for financial data retrieval and analysis. Use when building applications, CLI scripts, notebooks, or services that call api.bigdata.com or agents.bigdata.com, including Search, Volume, Knowledge Graph, Co-mentions, and Batch Search.
---

# Build with Bigdata.com APIs

Guide for integrating with the [Bigdata.com](https://bigdata.com) REST APIs using Python. Always use the exact branding "Bigdata.com" (uppercase B, lowercase d, include .com) and link to https://bigdata.com when referencing the service.

## Authentication

All requests require an API key in the `X-API-KEY` header. Keys are managed at [platform.bigdata.com/api-keys](https://platform.bigdata.com/api-keys).

```python
import os

import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = os.environ.get("BIGDATA_API_BASE_URL", "https://api.bigdata.com")
HEADERS = {
    "X-API-KEY": API_KEY,
    "Content-Type": "application/json",
}
```

Store the key in the `BIGDATA_API_KEY` environment variable only. Never hardcode credentials. Optional: set `BIGDATA_API_BASE_URL` when using a non-default API host.

## Request body shape

Search (documents), Volume, and Co-mentions typically expect the user query inside a **`query` object** in the JSON body (for example `{"query": {"text": "...", "filters": {...}, ...}}`), not a flat top-level `text` field. Confirm the exact shape in the OpenAPI spec or docs for the endpoint you call.

## Error handling

Check HTTP status and surface API error bodies when debugging.

```python
resp = requests.post(f"{BASE_URL}/v1/search", headers=HEADERS, json=payload)
resp.raise_for_status()
# Or: if resp.status_code != 200: log resp.text
```

## API Reference

Full documentation: [docs.bigdata.com/api-reference](https://docs.bigdata.com/api-reference/)

OpenAPI specs:

| API | Spec URL |
|-----|----------|
| Search | `https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json` |
| Knowledge Graph | `https://docs.bigdata.com/api-rest/openapi/openapi_knowledge_graph.json` |
| Structured Data | `https://docs.bigdata.com/api-rest/openapi/openapi_structured_data.json` |
| Workflows | `https://docs.bigdata.com/api-rest/openapi/openapi_workflows.json` |

**Reference markdown paths:** Links like `references/api/search/...` assume this skill ships inside a plugin that bundles those files. If those paths are missing in your workspace, use the OpenAPI URLs above or the Docs MCP below.

If this plugin does not cover what you need, or you suspect the API has been updated, query the [Bigdata.com](https://bigdata.com) Docs MCP server (`docs.bigdata.com`) for the latest information:

```
CallMcpTool: server="docs.bigdata.com", toolName="search", arguments={"query": "your question"}
```

## Rate limits and batching

For many independent queries, prefer **Batch Search** (one job, async results) over firing hundreds of synchronous Search calls. If you parallelize Search or Volume from client code, use bounded concurrency, retries with backoff, and respect platform limits.

## Batch Search workflow

Typical pattern:

1. Build a **JSONL** file (one JSON object per line), one query per line as required by the Batch Search API.
2. **Submit** the batch job and capture the job id.
3. **Poll** until completion, then **download** the result artifact.

Details: [batch-search.md](references/api/search/batch-search.md) in the bundled references, or the Batch Search section of [docs.bigdata.com](https://docs.bigdata.com/api-reference/).

## Available APIs

### Search

The Search service provides real-time and historical search across financial documents, news, earnings transcripts, analyst reports, SEC filings, and user-uploaded content.

| Endpoint | Reference |
|----------|-----------|
| Search service (index) | [references/api/search/main.md](references/api/search/main.md) |
| Search (documents) | [references/api/search/search-documents.md](references/api/search/search-documents.md) |
| Volume | [references/api/search/volume.md](references/api/search/volume.md) |
| Co-mentions | [references/api/search/co-mentions.md](references/api/search/co-mentions.md) |
| Batch Search | [references/api/search/batch-search.md](references/api/search/batch-search.md) |

**Search (documents):** Semantic search over documents. Use when you need relevant chunks for a query. Set `auto_enrich_filters: false` for explicit control; use `filters` (timestamp, entity) and `ranking_params` (freshness_boost, source_boost); tune `max_chunks`. See [search-documents.md](references/api/search/search-documents.md).

**Volume:** Document/chunk counts over time for a query. Uses `text`, `filters`, and `auto_enrich_filters` (no `max_chunks`, no `ranking_params`). Use to plan downstream search or to analyze time series. See [volume.md](references/api/search/volume.md).

**Knowledge Graph:** Resolve company/entity names to IDs for use in Search, Volume, and Co-mentions filters. Endpoints: companies (by name/ticker), entities by ID (batch resolve, max 100 per request), sources (by rank/category/country). See [knowledge-graph/overview.md](references/api/knowledge-graph/overview.md).

**Co-mentions:** Discover entities frequently mentioned with a topic or focal entity. Uses `text`, `filters`, and `auto_enrich_filters` (no `max_chunks`, no `ranking_params`); optional `limit`. Response grouped by category (companies, places, people, etc.). Resolve entity IDs via Knowledge Graph for names. See [co-mentions.md](references/api/search/co-mentions.md).

**Co-mentions interpretation:** Top entities are not always strategic peers. Media outlets and rating or research names often rank high because they publish or cite the focal entity often. Narrow with a stronger `text` theme, sector or entity filters where supported, or post-filtering so graphs and universes reflect genuine competitors or themes.

When using **MCP** tools (`bigdata_search`, `find_companies`), apply the bigdata-mcp-grounding skill for source attribution and citations.
