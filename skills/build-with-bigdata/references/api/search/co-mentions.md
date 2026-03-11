# Co-mentions API

Discover entities frequently mentioned together with your search query or focal entity. Returns entities grouped by category (companies, places, people, organizations, products, concepts) with chunk and headline counts. Use for thematic baskets, competitive mapping, and relationship discovery.

- API reference: [docs.bigdata.com/api-reference/search/get-co-mentions](https://docs.bigdata.com/api-reference/search/get-co-mentions)
- Full schema: OpenAPI [openapi_search_service.json](https://docs.bigdata.com/api-rest/openapi/openapi_search_service.json) — path `POST /v1/search/co-mentions/entities`

## Endpoint

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/search/co-mentions/entities` | Connected entities for the given query; optional **limit** (max 1000) |

## Request body

- **query** (required): **text**, **filters** (timestamp, entity, document_type, source, category, keyword, sentiment, etc.), **auto_enrich_filters**. No `max_chunks`, no `ranking_params`.
- **limit** (optional): Total number of entities to retrieve across **all entity types** (default 10; must be ≤ 1000). The budget is shared across companies, places, people, organizations, products, and concepts — so a small limit (e.g. 20) may return very few companies. **Use 200–500** to ensure a sufficient pool when filtering to a specific category.

## Response

- **results**: Object with category keys, each an array of entities:
  - **companies**, **places**, **people**, **organizations**, **products**, **concepts**
- Each entity has: **id** (RavenPack entity ID), **total_chunks_count** *(optional)*, **total_headlines_count** *(optional)*. Always use `.get("total_chunks_count")` / `.get("total_headlines_count")` to avoid `KeyError`.
- **Pattern for category-specific ranking**: fetch with a large `limit` (e.g. 500), extract the target category (e.g. `results["companies"]`), then sort client-side by your primary metric with the other as a tiebreaker — many entities will only have one of the two counts populated (whichever ranking they qualified for). Example for chunk-first ranking:
  ```python
  companies.sort(
      key=lambda e: (e.get("total_chunks_count", 0), e.get("total_headlines_count", 0)),
      reverse=True,
  )
  ```
- Resolve **id** to names via `POST /v1/knowledge-graph/entities/id` with `{"values": [id1, id2, ...]}` (max 100 per request).

## Best practices

- Use the same query and filters as you would for Search so co-mentions reflect the same document set.
- Set **auto_enrich_filters: false** when using explicit entity filters for reproducible results.
- Set **auto_enrich_filters: true** when the `text` is a person or entity name and you have no entity ID yet — the API resolves the entity automatically. The **top result in the matching category** (e.g. `people[0]`) will be the focal entity itself.
- Resolve entity IDs in batches of 100 with the Knowledge Graph **entities/id** endpoint for display or filtering.
- Use co-mentions to build thematic universes or to see which companies/places/people appear with a topic or focal entity.
- After getting co-mention entity IDs, use **`entity.all_of: [id_a, id_b]`** in Search to fetch chunks where **both** appear together. If `all_of` returns no results (narrow window or rare entity), fall back to `any_of: [company_id]` + text query for the person name.

## Example

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = "https://api.bigdata.com"
HEADERS = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}

# Co-mentions for a topic
body = {
    "query": {
        "text": "cloud computing adoption",
        "auto_enrich_filters": False,
        "filters": {
            "timestamp": {"start": "2024-01-01T00:00:00Z", "end": "2024-12-31T23:59:59Z"},
            "entity": {"any_of": [], "all_of": [], "none_of": []},
        },
    },
    "limit": 10,
}
resp = requests.post(f"{BASE_URL}/v1/search/co-mentions/entities", headers=HEADERS, json=body)
resp.raise_for_status()
data = resp.json()
results = data.get("results", {})

# Top companies co-mentioned
companies = results.get("companies", [])[:5]
ids = [c["id"] for c in companies]
# Resolve IDs to names (max 100 per call)
entities_resp = requests.post(
    f"{BASE_URL}/v1/knowledge-graph/entities/id",
    headers=HEADERS,
    json={"values": ids},
)
entities_resp.raise_for_status()
names = entities_resp.json().get("results", {})
for c in companies:
    # total_chunks_count and total_headlines_count are optional fields
    print(c["id"], names.get(c["id"], {}).get("name", "?"), c.get("total_chunks_count", 0))
```
