# Search Documents API

Semantic search over financial documents, news, earnings transcripts, analyst reports, SEC filings, and user-uploaded content. Returns relevance-ranked chunks with source and timestamp.

- API reference: [docs.bigdata.com/api-reference/search/search-documents](https://docs.bigdata.com/api-reference/search/search-documents) (includes `ranking_params.content_diversification`)
- Full schema: OpenAPI [openapi_search_service.json](https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json) — path `POST /v1/search`

## Endpoint

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/search` | Search documents; body has `query` (and optional `search_mode`, `include_audit`) |

## Limits & constraints

Empirically verified. Exceeding any limit returns HTTP 400.

| Field | Limit | Error |
|-------|-------|-------|
| `filters.entity.any_of` / `all_of` / `none_of` | **500 IDs** | "Your query is too complex. Simplify your query." |
| `filters.source.values` | **500 IDs** | "List should have at most 500 items" |
| `max_chunks` | **1000** | "Input should be less than or equal to 1000" |
| `filters.chunk.from` | min **1** (1-based) | 400 if 0 or negative |
| `filters.chunk.from` vs `to` | `from` ≤ `to` | 400 if reversed |
| `filters.reporting_periods[].fiscal_quarter` | **1–4** | 400 if 5+ |
| Knowledge Graph `entities/id` batch | **100 IDs** | Separate endpoint limit |
| `filters.keyword` arrays | No hard limit tested up to 500 | — |

## Request body (key fields)

- **query** (required): Object with:
  - **text**: Natural-language search string (optional if filtering only by entity/keyword).
  - **filters**: Optional. See sections below for each filter type.
  - **ranking_params**: Optional. See [Ranking parameters](#ranking-parameters) below.
  - **max_chunks**: Integer, 1–1000. Higher values for broader coverage; consider multiple calls for different angles.
  - **auto_enrich_filters**: Boolean. Set to **false** when you control entity/filters explicitly (recommended for reproducible queries). When `true` (default), the system automatically extracts and adds entities and keywords from the `text` field.

- **search_mode** (optional): `"fast"` (default) or `"smart"`. See [Search modes](#search-modes) below.
- **include_audit** (optional): If `true`, response includes the resolved queries actually executed (useful for debugging `auto_enrich_filters` and `smart` mode).

## Search modes

**Fast mode** gives you full control over all filters for precise, deterministic, low-latency results. Use when you pre-process the query or supply explicit filters.

**Smart mode** handles query understanding automatically — it infers intent, applies filters, and may run multiple sub-queries for broader coverage. Ideal for passing raw user questions without pre-processing. Higher latency than fast mode.

| Request parameter | Fast | Smart |
|-------------------|------|-------|
| `text` | ✅ | ✅ |
| `filters.timestamp` | ✅ manual | ✅ manual or auto |
| `filters.source` | ✅ manual | ✅ manual or auto |
| `filters.document_type` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.entity` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.reporting_entities` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.reporting_periods` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.keyword` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.sentiment` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.category` | ✅ manual | ❌ auto-only (400 if set) |
| `filters.topic` | ✅ manual | ❌ auto-only (400 if set) |
| `ranking_params` | ✅ manual | ❌ auto-only (400 if set) |
| `ranking_params.content_diversification` | ✅ manual | ❌ auto-only |

**Smart mode error when disallowed filter is passed:** `"Search filter not supported in smart search mode. They will be defined automatically. Please remove them from the request."`

Use `include_audit: true` to inspect which filters and sub-queries smart mode actually ran.

## Filter reference

### `timestamp`

```json
"timestamp": {
  "start": "2024-01-01T00:00:00Z",
  "end":   "2024-12-31T23:59:59Z"
}
```

ISO 8601 UTC. Both fields optional individually.

### `entity`

```json
"entity": {
  "any_of":   ["D8442A", "228D42"],
  "all_of":   [],
  "none_of":  [],
  "search_in": "ALL"
}
```

- `search_in`: `"HEADLINE"` | `"BODY"` | `"ALL"` (default `ALL`)
- **Max 500 IDs per array.** Exceeding returns "Your query is too complex."
- Resolve company names to IDs via `POST /v1/knowledge-graph/companies` before filtering.

### `document_type`

Complete, validated type/subtype enumeration (extracted from API validation errors):

```json
"document_type": {
  "mode": "INCLUDE",
  "values": [
    { "type": "TRANSCRIPT", "subtypes": ["EARNINGS_CALL"] }
  ]
}
```

**Top-level types:** `FILING` | `INVESTMENT-RESEARCH` | `NEWS` | `TRANSCRIPT` | `TRANSCRIPT-PRESENTATION`

| Type | Valid `subtypes` |
|------|-----------------|
| `FILING` | `SEC_10_K`, `SEC_10_Q`, `SEC_8_K`, `SEC_20_F`, `SEC_S_1`, `SEC_S_3`, `SEC_6_K`, `SEC_DEF_14A` |
| `INVESTMENT-RESEARCH` | `COMPANY_REPORT`, `COVERAGE_ANALYSIS`, `ECONOMIC_REPORT`, `FIXED_INCOME_REPORT`, `FUND_REPORT`, `FX_AND_DERIVATIVES_REPORT`, `GENERIC_REPORT`, `INDEX_REPORT`, `INDUSTRY_REPORT`, `MARKET_UPDATE`, `PORTFOLIO_STRATEGY`, `PORTFOLIO_SUMMARY`, `RATING_REPORT`, `RESEARCH_NOTE`, `THEMATIC_ANALYSIS` |
| `TRANSCRIPT` / `TRANSCRIPT-PRESENTATION` | `EARNINGS_CALL`, `EARNINGS_RELEASE`, `GUIDANCE_CALL`, `SALES_REVENUE_CALL`, `SALES_REVENUE_RELEASE`, `CONFERENCE_CALL`, `ANALYST_INVESTOR_SHAREHOLDER_MEETING`, `SHAREHOLDERS_MEETING`, `GENERAL_PRESENTATION`, `SPECIAL_SITUATION_MA`, `MANAGEMENT_PLAN_ANNOUNCEMENT`, `INVESTOR_CONFERENCE_CALL` |
| `NEWS` | (no subtypes) |

`subtypes` is optional — omit it to match all subtypes of a type.

### `source`

```json
"source": {
  "mode": "INCLUDE",
  "values": ["D4B903", "A1B2C3"]
}
```

**Max 500 source IDs.** Discover source IDs via `POST /v1/knowledge-graph/sources`.

### `category`

Selects a group of sources by content category. Values are **lowercase** (uppercase returns 400).

```json
"category": {
  "mode": "INCLUDE",
  "values": ["transcripts", "research"]
}
```

Valid values: `news`, `news_premium`, `news_public`, `transcripts`, `filings`, `research`, `research_investment_research`, `research_academic_journals`, `podcasts`, `expert_interviews`, `expert_networks`, `newsletters`, `my_files`, `regulatory`

### `keyword`

```json
"keyword": {
  "all_of":    ["EBITDA"],
  "any_of":    ["revenue", "guidance"],
  "none_of":   ["lawsuit"],
  "search_in": "BODY"
}
```

- `search_in`: `"HEADLINE"` | `"BODY"` | `"ALL"` (default `ALL`)
- No hard limit on array size (500+ tested without error).

### `sentiment`

Use `ranges` (current). The `values` field is deprecated but still works with **lowercase** strings.

```json
"sentiment": {
  "ranges": [
    { "min": 0.5, "max": 1.0 }
  ]
}
```

- Range: `min`/`max` are floats from **−1.0 to 1.0** (−1 = most negative, 0 = neutral, 1 = most positive).
- Multiple ranges allowed: `[{"min": 0.5, "max": 1.0}, {"min": -1.0, "max": -0.5}]` returns positive OR negative.
- **Deprecated** `values` (still works with lowercase only): `"positive"`, `"negative"`, `"neutral"`. Uppercase fails.

### `topic`

Filter by hierarchical topic path (comma-separated levels, most-specific last).

```json
"topic": {
  "any_of":   ["business,stock-prices,stock-price-volatility,down"],
  "all_of":   [],
  "none_of":  [],
  "search_in": "ALL"
}
```

- Path format: `"parent,child,grandchild"` — e.g. `"business,earnings"`, `"business,stock-prices"`.
- `search_in`: `"HEADLINE"` | `"BODY"` | `"ALL"` (default `ALL`).
- Topic values appear to be case-insensitive.

### `reporting_entities` and `reporting_periods`

Scope results to documents that *report on* specific companies for specific fiscal periods. Useful for earnings-related searches.

```json
"reporting_entities": ["D8442A"],
"reporting_periods": [
  { "fiscal_year": 2024, "fiscal_quarter": 4 },
  { "fiscal_year": 2025, "fiscal_quarter": 1 }
]
```

- `reporting_entities`: array of entity IDs (no hard limit tested).
- `reporting_periods`: each entry requires `fiscal_year`; `fiscal_quarter` is optional (omit for full-year). Valid quarters: **1–4** (5+ returns 400).
- Both fields can be used independently or combined.

### `document` (document ID filter)

Restrict search to specific documents by ID (e.g., from a previous search response). Use with `chunk` for context expansion.

```json
"document": {
  "mode": "INCLUDE",
  "values": ["57BB2AD919..."]
}
```

### `chunk` (context expansion)

Narrow results to a chunk range within a document. **1-based indexing.** `from` must be ≤ `to`.

```json
"chunk": { "from": 3, "to": 8 }
```

Typical pattern — retrieve surrounding context for a chunk you already found:

```python
# You found chunk cnum=5 in document doc_id
# Retrieve chunks 3–8 for context
payload = {
    "search_mode": "fast",
    "query": {
        "text": "your original query",
        "filters": {
            "document": {"mode": "INCLUDE", "values": [doc_id]},
            "chunk": {"from": 3, "to": 8},
        },
        "max_chunks": 10,
        "auto_enrich_filters": False,
    },
}
```

## Ranking parameters

```json
"ranking_params": {
  "freshness_boost": 1.0,
  "source_boost": 1.0,
  "content_diversification": { "enabled": true },
  "reranker": { "enabled": true, "threshold": 0.2 }
}
```

| Parameter | Default | Range | Notes |
|-----------|---------|-------|-------|
| `freshness_boost` | 1.0 | 0–10 | 0 = timestamp ignored (use for backtesting) |
| `source_boost` | 1.0 | 0–10 | 0 = source rank ignored |
| `content_diversification.enabled` | **true** | bool | Balances results across providers/viewpoints. Set `false` for legacy undiversified ranking. |
| `reranker.enabled` | true | bool | Cross-encoder second-pass ranking |
| `reranker.threshold` | 0.2 | 0.0–1.0 | Higher = fewer but more precise results. At 0.9+ very few results survive; 1.0 returns nothing. |

**Reranker threshold guide (empirical):**
- 0.0–0.7: minimal filtering, quantity-focused
- 0.8: noticeably fewer results (~half)
- 0.9: very few results (high precision)
- 1.0: no results returned

## Response

- **results**: Array of documents. Each has `id`, `headline`, `timestamp`, `source` (`id`, `name`, `rank`), `url`, `document_type`, **chunks**.
- Each **chunk**: `cnum` (1-based chunk number), `text`, `relevance`, `sentiment` (−1 to 1), `detections` (entity spans), optional `text_locations` (`paragraph_num`, `sentence_num`).
- **metadata**: `request_id`, `timestamp`, optional `audit` (when `include_audit: true`).
- **usage**: `api_query_units`.

## Error patterns

| HTTP | Cause | Body shape |
|------|-------|------------|
| 400 | Validation failure | `{"errors": [{"message": "N validation errors for PublicSearchRequest\n<field>\n  <reason>"}]}` |
| 400 | Filter in smart mode | `{"errors": [{"message": "Search filter not supported in smart search mode..."}]}` |
| 400 | Query too complex (entity > 500) | `{"errors": [{"message": "...Your query is too complex. Simplify your query."}]}` |
| 401/403 | Bad/missing API key | HTML error page from WAF |
| 429 | Rate limit | Retry with backoff |

## Best practices

- Use **semantic** queries (natural language); avoid relying only on keywords.
- Set **`auto_enrich_filters: false`** when using entity or keyword filters to avoid unintended enrichment.
- For backtesting or unbiased retrieval, set **`freshness_boost: 0`**.
- Disable diversification with `content_diversification.enabled: false` if you want traditional single-ranking behavior.
- Tune **`max_chunks`** (e.g. 20–50 for focused queries); split into multiple calls for different angles rather than one very large request.
- Resolve company names to entity IDs via the Knowledge Graph before filtering; use those IDs in `filters.entity.any_of`.
- Prefer `sentiment.ranges` over the deprecated `sentiment.values`. If you must use the deprecated form, values are **lowercase only** (`positive`, `negative`, `neutral`).
- Raise **`reranker.threshold`** (e.g. to 0.5–0.7) when you want fewer, higher-confidence results.
- Use `document` + `chunk` filters together to expand context around a previously retrieved chunk.

## Example

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = os.environ.get("BIGDATA_API_BASE_URL", "https://api.bigdata.com")
HEADERS = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}

query = {
    "search_mode": "fast",
    "query": {
        "text": "cloud computing revenue growth outlook",
        "auto_enrich_filters": False,
        "filters": {
            "timestamp": {"start": "2024-01-01T00:00:00Z", "end": "2024-12-31T23:59:59Z"},
            "entity": {"any_of": ["D8442A", "228D42"]},
            "document_type": {
                "mode": "INCLUDE",
                "values": [{"type": "TRANSCRIPT", "subtypes": ["EARNINGS_CALL"]}],
            },
        },
        "ranking_params": {
            "freshness_boost": 0,
            "source_boost": 1,
            "reranker": {"enabled": True, "threshold": 0.2},
            # content_diversification is on by default; disable if needed:
            # "content_diversification": {"enabled": False},
        },
        "max_chunks": 20,
    },
}

resp = requests.post(f"{BASE_URL}/v1/search", headers=HEADERS, json=query)
resp.raise_for_status()
data = resp.json()
for doc in data.get("results", []):
    print(doc.get("headline"), doc.get("source", {}).get("name"))
    for ch in doc.get("chunks", []):
        print("  ", ch.get("relevance"), ch.get("text", "")[:80])
```
