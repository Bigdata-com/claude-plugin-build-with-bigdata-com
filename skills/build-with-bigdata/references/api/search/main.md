# Search service (overview)

Bigdata.com Search service endpoints documented in this folder. Use the linked pages for request shapes, examples, and links to live API docs.

| Topic | File |
|-------|------|
| Semantic document search | [search-documents.md](search-documents.md) |
| Volume (aggregates over time) | [volume.md](volume.md) |
| Co-mentioned entities | [co-mentions.md](co-mentions.md) |
| Batch Search (async JSONL) | [batch-search.md](batch-search.md) |

**OpenAPI:** [openapi_search_service.json](https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json)

**Live reference:** [docs.bigdata.com/api-reference](https://docs.bigdata.com/api-reference/)

Most Search-family requests send a JSON body with a top-level **`query`** object. See each file for fields (`text`, `filters`, `auto_enrich_filters`, and Search-only `ranking_params` / `max_chunks`).
