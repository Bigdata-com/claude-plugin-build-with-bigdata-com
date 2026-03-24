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

## Response limit

The `results.volume` array is capped at **1000 entries**. If the requested date range contains more than 1000 days with data, older entries are silently truncated.

**Handling large date ranges:**
- After receiving a response, check if the oldest returned date is newer than your requested `start`. If so, data was truncated.
- Re-query from your original `start` up to one day before the oldest returned date, then merge the two result arrays.
- Repeat if necessary (e.g. for multi-year ranges).
- Do **not** split preemptively — many date ranges contain fewer than 1000 days with actual data and require only one call.

## Best practices

- Volume uses the same `filters` as Search, so volume counts reflect what a Search call would return for that window.
- Use volume to decide date ranges or entity baskets before running larger Search jobs (e.g. smart batching).

## Example

```python
import os
import requests
from datetime import datetime, timedelta

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = os.environ.get("BIGDATA_API_BASE_URL", "https://api.bigdata.com")
HEADERS = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}


def fetch_volume(query_text, start: str, end: str, entity_ids: list[str]) -> list[dict]:
    """Fetch volume data for the given range, handling the 1000-entry cap via pagination."""
    all_entries = []
    current_end = end

    while True:
        payload = {
            "query": {
                "text": query_text,
                "auto_enrich_filters": False,
                "filters": {
                    "timestamp": {"start": start, "end": current_end},
                    "entity": {"all_of": entity_ids, "any_of": [], "none_of": []},
                },
            }
        }
        resp = requests.post(f"{BASE_URL}/v1/search/volume", headers=HEADERS, json=payload)
        resp.raise_for_status()
        entries = resp.json().get("results", {}).get("volume", [])

        if not entries:
            break

        all_entries = entries + all_entries  # prepend older data

        # Get the oldest date returned
        oldest = min(e.get("date") or e.get("day") for e in entries)

        # If the oldest date is already at or before our start, we're done
        if oldest <= start[:10]:
            break

        # If fewer than 1000 entries were returned, no truncation occurred
        if len(entries) < 1000:
            break

        # Truncation likely occurred: re-query the missing older range
        current_end = (datetime.fromisoformat(oldest) - timedelta(days=1)).strftime("%Y-%m-%dT23:59:59Z")

    return all_entries


entries = fetch_volume(
    query_text="tariffs impact on supply chain",
    start="2022-01-01T00:00:00Z",
    end="2025-12-31T23:59:59Z",
    entity_ids=["228D42"],
)

print(f"Total entries retrieved: {len(entries)}")
for day in entries[:5]:
    d = day.get("date") or day.get("day")
    print(d, "docs:", day.get("documents"), "chunks:", day.get("chunks"))
```
