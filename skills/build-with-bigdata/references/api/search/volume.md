# Volume API

Get document and chunk volume statistics over time for a search query, aggregated by date with optional sentiment. Use to plan downstream search jobs or to analyze coverage time series.

- API reference: [docs.bigdata.com/api-reference/search/get-volume-data](https://docs.bigdata.com/api-reference/search/get-volume-data)
- Full schema: OpenAPI [openapi_search_service.json](https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json) — path `POST /v1/search/volume`

## Endpoint

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/search/volume` | Return volume (and totals) for the given query over the requested time range |

## Request body

Single property **query** (no `max_chunks`, no `ranking_params`):

- **text**: Natural-language search string (optional if filtering only).
- **filters**: Optional. `timestamp` (`start`, `end` in ISO date-time), `entity` (`any_of`, `all_of`, `none_of`; optional `search_in`), `document_type`, `source`, `category`, `keyword`, `sentiment`, etc. See OpenAPI for full list.
- **auto_enrich_filters**: Optional boolean; set to `false` for explicit control.

## Response

- **results.volume**: Array of daily stats. Each object has:
  - **date**: Date in YYYY-MM-DD format.
  - **documents**: Number of documents matching the query on that date.
  - **chunks**: Number of chunks on that date.
  - **sentiment**: Average sentiment score for chunks on that date (-1.00 to 1.00).
- **results.total**: Aggregated totals: **documents**, **chunks**, **sentiment**.

(Some implementations may return `day` instead of `date`; prefer `date` per OpenAPI and handle either when parsing.)

## Best practices

- Volume uses the same `filters` as Search, so volume counts reflect what a Search call would return for that window.
- Use volume to decide date ranges or entity baskets before running larger Search jobs (e.g. smart batching).

## Example

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = os.environ.get("BIGDATA_API_BASE_URL", "https://api.bigdata.com")
HEADERS = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}

query = {
    "query": {
        "text": "tariffs impact on supply chain",
        "auto_enrich_filters": False,
        "filters": {
            "timestamp": {"start": "2024-01-01T00:00:00Z", "end": "2024-06-30T23:59:59Z"},
            "entity": {"any_of": ["228D42"], "all_of": [], "none_of": []},
        },
    }
}

resp = requests.post(f"{BASE_URL}/v1/search/volume", headers=HEADERS, json=query)
resp.raise_for_status()
data = resp.json()
totals = data.get("results", {}).get("total", {})
print("Total documents:", totals.get("documents"), "chunks:", totals.get("chunks"))
for day in data.get("results", {}).get("volume", [])[:5]:
    d = day.get("date") or day.get("day")
    print(d, "docs:", day.get("documents"), "chunks:", day.get("chunks"))
```
