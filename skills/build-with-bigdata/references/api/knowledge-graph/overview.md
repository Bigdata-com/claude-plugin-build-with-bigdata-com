# Knowledge Graph API

Resolve company and entity names to IDs, and IDs back to names and metadata. Use entity IDs in Search, Volume, and Co-mentions filters. Discover sources by rank, category, or country.

- API reference: [docs.bigdata.com/api-reference/knowledge-graph](https://docs.bigdata.com/api-reference/knowledge-graph)
- Full schema: OpenAPI [openapi_knowledge_graph.json](https://docs.bigdata.com/api-rest/openapi/openapi_knowledge_graph.json)

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/knowledge-graph/companies` | Find companies by name, ticker, website, ISIN, etc. |
| POST | `/v1/knowledge-graph/entities/id` | Resolve up to 100 entity IDs to full entity details |
| POST | `/v1/knowledge-graph/sources` | Find sources by name; filter by country, rank, category |
| GET | `/v1/knowledge-graph/companies/sectors` | List available sectors for company filters |

## Companies — `POST /v1/knowledge-graph/companies`

**Request (FindCompaniesRequest):** At least one of:

- **query**: Partial or complete company name, webpage, ticker, ISIN, SEDOL, or CUSIP.
- **types**: Array of `"PUBLIC"` or `"PRIVATE"`.
- **countries**: ISO 3166-1 alpha-2 codes (e.g. `["US", "FR"]`).
- **sectors**: Array of sector names (use `/companies/sectors` to list).

**Response:** `{"results": [...]}` — a wrapper object whose `results` key is an array of **Company** objects: `id`, `name`, `type`, `country`, `sector`, `industry_group`, `industry`, `webpage`, `listing_values`, `isin_values`, etc. Use `id` in Search/Volume/Co-mentions entity filters. **Always call `.get("results", [])` on the parsed JSON — do NOT treat the response as a bare list.**

## Entities by ID — `POST /v1/knowledge-graph/entities/id`

**Request (GetEntitiesByIdRequest):**

- **values**: Array of RavenPack entity IDs. **Maximum 100 IDs per request.**

**Response (GetEntitiesByIdResponse):** **results** object — keys are entity IDs, values are **Entity** objects with `id`, `name`, `category`, `type`, `country`, `sector`, and identifier arrays. Use to resolve IDs from Search chunks or Co-mentions responses.

## Sources — `POST /v1/knowledge-graph/sources`

**Request (FindSourcesRequest):** Optional filters:

- **query**: Search by source name or description.
- **countries**: ISO 3166-1 alpha-2 codes.
- **ranks**: `["RANK_1", "RANK_2", ... "RANK_5"]` (RANK_1 is highest quality).
- **categories**: e.g. `["transcripts", "research", "podcasts", "news", "filings", "expert_interviews"]`.

**Response:** Source list (see OpenAPI FindSourcesResponse). Use source IDs in Search/Volume `filters.source`.

## Looking up People (no dedicated endpoint)

There is **no `/v1/knowledge-graph/people` endpoint**. To find a person's entity ID (e.g. "Jensen Huang", "Elon Musk"), use this pattern:

1. Call Co-mentions with `text="<person name>"` and `auto_enrich_filters: true`.
2. The **top result in the `people` category** is the person themselves (highest chunk count).
3. Resolve that ID with `entities/id` to confirm the name, then use the ID in Search/Volume filters.

```python
# Discover a person's entity ID via Co-mentions
body = {
    "query": {
        "text": "Jensen Huang",
        "auto_enrich_filters": True,   # API resolves the person entity automatically
        "filters": {"timestamp": {"start": "...", "end": "..."}},
    },
    "limit": 5,
}
resp = requests.post(f"{BASE_URL}/v1/search/co-mentions/entities", headers=HEADERS, json=body)
people = resp.json().get("results", {}).get("people", [])
person_id = people[0]["id"]  # top result = the focal person

# Confirm name
names = requests.post(
    f"{BASE_URL}/v1/knowledge-graph/entities/id",
    headers=HEADERS,
    json={"values": [person_id]},
).json().get("results", {})
print(names[person_id]["name"])  # e.g. "Jensen Huang"
```

## Best practices

- Resolve company names to IDs **before** calling Search or Volume when you need entity-scoped results.
- Use **entities/id** to resolve Co-mentions entity IDs to names for display or filtering.
- Prefer a single identifier per companies request (e.g. ticker or name); avoid combining multiple identifiers in one query string.
- Batch entity resolution with **entities/id** (up to 100 IDs per call) instead of one-by-one.
- To look up a **person** entity ID, use the Co-mentions `people` category (see above) — there is no direct people search endpoint.

## Example: companies and entities by ID

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE_URL = "https://api.bigdata.com"
HEADERS = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}

# Find companies by name
companies_resp = requests.post(
    f"{BASE_URL}/v1/knowledge-graph/companies",
    headers=HEADERS,
    json={"query": "Apple", "types": ["PUBLIC"]},
)
companies_resp.raise_for_status()
companies = companies_resp.json().get("results", [])  # response is {"results": [...]}
entity_ids = [c["id"] for c in companies[:3]]

# Resolve entity IDs to details (max 100 per request)
entities_resp = requests.post(
    f"{BASE_URL}/v1/knowledge-graph/entities/id",
    headers=HEADERS,
    json={"values": entity_ids},
)
entities_resp.raise_for_status()
results = entities_resp.json().get("results", {})
for eid, ent in results.items():
    print(eid, ent.get("name"), ent.get("category"))
```
