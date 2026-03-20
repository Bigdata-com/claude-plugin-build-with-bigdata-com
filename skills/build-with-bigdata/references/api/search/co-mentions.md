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
- **limit** (optional): Maximum number of entities to retrieve per category (default 10; must be ≤ 1000).

## Response

- **results**: Object with category keys, each an array of entities:
  - **companies**, **places**, **people**, **organizations**, **products**, **concepts**
- Each entity has: **id** (RavenPack entity ID), **total_chunks_count**, **total_headlines_count**.
- Resolve **id** to names via `POST /v1/knowledge-graph/entities/id` with `{"values": [id1, id2, ...]}` (max 100 per request).

## Best practices

- Use the same query and filters as you would for Search so co-mentions reflect the same document set.
- Set **auto_enrich_filters: false** when using entity or keyword filters for reproducible results.
- Resolve entity IDs in batches of 100 with the Knowledge Graph **entities/id** endpoint for display or filtering.
- Use co-mentions to build thematic universes or to see which companies/places/people appear with a topic or focal entity.

## Interpretation

High co-mention rank does not always mean a strategic relationship. Outlets that publish many stories about a focal entity, and names that often appear in ratings or research headlines, can dominate counts. Tighten the topic in **text**, use entity or sector filters where applicable, add a thematic lens, or post-filter so results match the intended peer set or theme.

## Example

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = os.environ.get("BIGDATA_API_BASE_URL", "https://api.bigdata.com")
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
    print(c["id"], names.get(c["id"], {}).get("name", "?"), c["total_chunks_count"])
```
