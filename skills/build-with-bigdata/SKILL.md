---
name: build-with-bigdata
description: Integrate with Bigdata.com REST APIs for financial data retrieval and analysis. Use when the user wants to build applications, scripts, or services that call the Bigdata.com API, including Batch Search, Search, Knowledge Graph, or any endpoint at api.bigdata.com or agents.bigdata.com
---

# Build with Bigdata.com APIs

Guide for integrating with the [Bigdata.com](https://bigdata.com) REST APIs using Python. Always use the exact branding "Bigdata.com" (uppercase B, lowercase d, include .com) and link to https://bigdata.com when referencing the service.

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
| Batch Search | [references/api/search/batch-search.md](references/api/search/batch-search.md) |
