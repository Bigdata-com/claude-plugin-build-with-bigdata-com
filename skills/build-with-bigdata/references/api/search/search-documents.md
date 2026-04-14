# Search Documents API

Semantic search over financial documents, news, earnings transcripts, analyst reports, SEC filings, and user-uploaded content. Returns relevance-ranked chunks with source and timestamp.

- API reference: [docs.bigdata.com/api-reference/search/search-documents](https://docs.bigdata.com/api-reference/search/search-documents) (includes `ranking_params.content_diversification`)
- Full schema: OpenAPI [openapi_search_service.json](https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json) — path `POST /v1/search`

## Endpoint

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/search` | Search documents; body has `query` (and optional `search_mode`, `include_audit`) |

## Request body (key fields)

- **query** (required): Object with:
  - **text**: Natural-language search string (optional if filtering only by entity/keyword).
  - **filters**: Optional. Common: `timestamp` (`start`, `end` in ISO date-time, e.g. `2024-01-01T00:00:00Z`), **entity** (`any_of`, `all_of`, `none_of` arrays of entity IDs; optional `search_in`: `HEADLINE` \| `BODY` \| `ALL`). See OpenAPI for full list (`document_type`, `source`, `category`, `keyword`, `sentiment`, etc.).
  - **ranking_params**: Optional.
    - **freshness_boost** (number), **source_boost** (number). Use `freshness_boost: 0` for unbiased/backtesting.
    - **content_diversification**: **Enabled by default.** Balances results across a wider range of premium sources and viewpoints to reduce single-source bias and redundant content. To disable and use undiversified ranking, set **`ranking_params.content_diversification.enabled`** to **`false`** explicitly.
  - **max_chunks**: Integer (e.g. 10–100). Higher values for broader coverage; consider multiple calls for different angles.
  - **auto_enrich_filters**: Boolean. Set to **false** when you control entity/filters explicitly (recommended for reproducible queries).

- **search_mode** (optional): `"fast"` (default) or `"smart"`. Use `fast` when you supply filters; `smart` auto-derives filters from text (only timestamp and source filters allowed).
- **include_audit** (optional): If true, response includes resolved queries for debugging.

### `document_type` highlights

- **INVESTMENT_RESEARCH**: Filter to investment research documents. Includes subtypes such as `COMPANY_REPORT`, `COVERAGE_ANALYSIS`, `ECONOMIC_REPORT`, `FIXED_INCOME_REPORT`, `FUND_REPORT`, `FX_AND_DERIVATIVES_REPORT`, `GENERIC_REPORT`, `INDEX_REPORT`, `INDUSTRY_REPORT`, `MARKET_UPDATE`, `PORTFOLIO_STRATEGY`, `PORTFOLIO_SUMMARY`, `RATING_REPORT`, `RESEARCH_NOTE`, `THEMATIC_ANALYSIS` (see OpenAPI / live docs for the exact filter shape).
- When **type** is **FILING**, you can use subtype **SEC_DEF_14A** to narrow to definitive proxy statements (Form DEF 14A).

## Response

- **results**: Array of documents. Each has `id`, `headline`, `timestamp`, `source` (e.g. `name`), `url`, **chunks** (array of `text`, `relevance`, `cnum`).
- Each chunk may include an optional **text_locations** array: entries with **paragraph_num** and **sentence_num** to locate the chunk in the source document. The field is optional and may be absent per chunk.

## Best practices

- Use **semantic** queries (natural language); avoid relying only on keywords.
- Set **auto_enrich_filters: false** when using entity or keyword filters to avoid unintended enrichment.
- For backtesting or unbiased retrieval, set **freshness_boost: 0**.
- If you need legacy-style ranking without diversification, set **`ranking_params.content_diversification.enabled: false`**.
- Tune **max_chunks** (e.g. 20–50 for focused queries); split into multiple calls for different aspects rather than one very large request.
- Resolve company names to entity IDs via the Knowledge Graph before filtering; use those IDs in `filters.entity.any_of` (or `all_of` / `none_of`).

## Example

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = os.environ.get("BIGDATA_API_BASE_URL", "https://api.bigdata.com")
HEADERS = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}

query = {
    "query": {
        "text": "cloud computing revenue growth outlook",
        "auto_enrich_filters": False,
        "filters": {
            "timestamp": {"start": "2024-01-01T00:00:00Z", "end": "2024-12-31T23:59:59Z"},
            "entity": {"any_of": ["D8442A", "228D42"], "all_of": [], "none_of": []},
        },
        "ranking_params": {
            "freshness_boost": 0,
            "source_boost": 0,
            # content_diversification is on by default; uncomment to disable:
            # "content_diversification": {"enabled": False},
        },
        "max_chunks": 20,
    }
}

resp = requests.post(f"{BASE_URL}/v1/search", headers=HEADERS, json=query)
resp.raise_for_status()
data = resp.json()
for doc in data.get("results", []):
    print(doc.get("headline"), doc.get("source", {}).get("name"))
    for ch in doc.get("chunks", []):
        print("  ", ch.get("relevance"), ch.get("text", "")[:80])
```
