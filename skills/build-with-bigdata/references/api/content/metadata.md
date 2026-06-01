# List documents / Get document metadata

Two related read endpoints that return the same per-document record shape.

## List — `GET https://api.bigdata.com/contents/v1/documents`

Paginated list of documents you uploaded or that are shared with your org.

**Request**

```
GET https://api.bigdata.com/contents/v1/documents
Headers: X-API-KEY
Query params (all optional):
  origin            email | file_upload
  from_date         ISO 8601 — documents created on/after this date
  ownership         all (default) | owned | shared
  owner             user id
  file_name         case-insensitive partial match
  tags              repeatable; OR across values
  rp_collection_id  filter by collection
  connector         UUID
  page              integer, default 1, min 1
  page_size         integer, default 50, max 100
  sort_by           created_at (default) | updated_at | file_name | raw_size | content_type | status
  sort_order        desc (default) | asc
```

**Response 200**

```json
{
  "results": [
    {
      "id":             "7FA511999C3984CB75005890B15A7096",
      "file_name":      "research_report.pdf",
      "user_id":        "user_id_001",
      "org_id":         "org_id_001",
      "raw_size":       654,
      "request_origin": "file_upload",
      "content_type":   "application/pdf",
      "status":         "completed",
      "created_at":     "2025-06-15T10:30:00Z",
      "updated_at":     "2025-06-15T10:35:00Z",
      "published_at":   "2025-06-15T10:30:00Z",
      "tags": [{ "id": "...", "name": "Research Team" }]
    }
  ]
}
```

`status` ∈ `pending` | `processing` | `completed` | `failed`.

**Eventual consistency:** right after an upload, the document may not appear immediately. Wait 3–5 seconds and retry before concluding it's missing.

## Get — `GET https://api.bigdata.com/contents/v1/documents/{document_id}`

Fetch a single document's metadata. Returns the same schema as one entry in `results[]` above.

**Request**

```
GET https://api.bigdata.com/contents/v1/documents/{document_id}
Headers: X-API-KEY
```

**Response 200** — the document record (same schema as above).

**Errors**

| Status | Meaning |
|---|---|
| 401 | Invalid or missing API key |
| 403 | Document not shared with your org |
| 404 | Document not found |

## Update — `PATCH https://api.bigdata.com/contents/v1/documents/{document_id}`

Partially update a document's metadata. Send **only** the fields you want to change. Returns the updated document record (same schema as List / Get above).

**Request**

```
PATCH https://api.bigdata.com/contents/v1/documents/{document_id}
Headers: X-API-KEY, Content-Type: application/json
Body (all fields optional — include only what you change):
{
  "share_with_org": false,                              // bool — true: whole org can access; false: only you
  "tags": ["019e3a99-6952-7dd4-adf5-b0b341959e11"]      // array of tag IDs (UUIDs); REPLACES the current set
}
```

- **`share_with_org`** — `true` makes the document available to all members of your org; `false` restricts it to you.
- **`tags`** — the full list of tag **IDs** you want applied. This **replaces** the document's current tag set (it does not merge), so to add or remove a tag, send the complete list you want to end up with. Send `[]` to clear all tags.

**Tag IDs vs names — common 400:** unlike [upload.md](upload.md), where `tags` are passed by **name** (e.g. `["Research Team"]`), PATCH requires tag **IDs** (UUIDs). Get IDs from [tags.md](tags.md) (create or list tags). Any ID that doesn't exist makes the whole call fail with `400 INVALID_TAGS_ERROR`.

**Response 200** — the updated document record (same schema as List / Get).

**Errors**

| Status | Meaning |
|---|---|
| 400 | Invalid body — e.g. one or more tag IDs do not exist (`errorCode: INVALID_TAGS_ERROR`) |
| 401 | Invalid or missing API key |
| 403 | You do not have permission to update this document |
| 404 | Document not found |

**Python**

```python
# Share with the whole org and replace its tag set in one call.
r = requests.patch(
    f"{BASE}/documents/{document_id}",
    headers=HEADERS,
    json={
        "share_with_org": True,
        "tags": ["019e3a99-6952-7dd4-adf5-b0b341959e11"],  # tag IDs, not names
    },
)
r.raise_for_status()
updated = r.json()
```

## Typical use

Poll Get right after an upload to watch `status` go `pending` → `processing` → `completed`:

```python
import time, requests

while True:
    r = requests.get(f"{BASE}/documents/{doc_id}", headers=HEADERS)
    r.raise_for_status()
    status = r.json()["status"]
    if status in ("completed", "failed"):
        break
    time.sleep(2)
```
