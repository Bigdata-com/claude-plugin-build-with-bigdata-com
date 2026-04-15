# Content API — Documents

Manage user-uploaded documents on Bigdata.com: **list**, **get metadata**, and **upload (enrich)**.
Upload is a **two-step flow**: `POST /contents/v1/documents` returns a pre-signed S3 `url` + content `id`; then **PUT** the raw file bytes to that `url` (do not send `X-API-KEY` to S3 — the URL is already signed). Enrichment is async — poll `GET /contents/v1/documents/{id}` until `status` transitions `processing` → `completed`.

Base URL: `https://api.bigdata.com` · Auth header: `X-API-KEY: <api_key>`

**Live reference:** [docs.bigdata.com/api-reference/documents/list-documents](https://docs.bigdata.com/api-reference/documents/list-documents)

---

## 1. List documents — `GET /contents/v1/documents`

Paginated list of documents the user has uploaded or that are shared with their organization.

### Query parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `origin` | enum | — | `email` or `file_upload` |
| `from_date` | ISO 8601 | — | Documents created on/after this date |
| `ownership` | enum | `all` | `all`, `owned`, or `shared` |
| `owner` | string | — | Filter by uploader user ID |
| `page` | integer | 1 | Page number (min 1) |
| `page_size` | integer | 50 | 1–100 |
| `sort_by` | enum | `created_at` | `created_at`, `updated_at`, `file_name`, `raw_size`, `content_type`, `status` |
| `sort_order` | enum | `desc` | `asc` or `desc` |
| `file_name` | string | — | Case-insensitive partial match |
| `rp_collection_id` | string | — | Filter by collection |
| `connector` | UUID | — | Filter by connector |
| `tags` | string (repeatable) | — | OR logic across tag names |

### Response (200)

```json
{
  "results": [
    {
      "id": "7FA511999C3984CB75005890B15A7096",
      "file_name": "research_report.pdf",
      "user_id": "user_id_001",
      "org_id": "org_id_001",
      "raw_size": 654,
      "request_origin": "file_upload",
      "content_type": "application/pdf",
      "status": "completed",
      "created_at": "2025-06-15T10:30:00Z",
      "updated_at": "2025-06-15T10:35:00Z",
      "published_at": "2025-06-15T10:30:00Z",
      "tags": [{ "id": "...", "name": "Research Team" }]
    }
  ]
}
```

`id` is the 32-char uppercase hex content ID used by other endpoints. `status` is one of `pending`, `processing`, `completed`, `failed`.

---

## 2. Get document metadata — `GET /contents/v1/documents/{content_id}`

Returns the same schema as a single `results` item above.

### Errors

| Status | Meaning |
|---|---|
| 401 | Invalid or missing API key |
| 403 | Document not shared with your org |
| 404 | Document not found |

---

## 3. Upload (enrich) a document

Two-step flow: request a pre-signed URL, then PUT the file bytes.

### Step 1 — `POST /contents/v1/documents`

| Field | Type | Required | Description |
|---|---|---|---|
| `file_name` | string | Yes | e.g. `report.pdf` |
| `published_ts` | ISO 8601 | No | Publication timestamp for ordering |
| `tags` | array of strings | No | Tag names for categorization |
| `share_with_org` | boolean | No | `true` = org members can access |

Response:

```json
{
  "url": "https://s3.amazonaws.com/.../uploads/F22BC027BCE166BC89DD2A81358DA2F1?AWSAccessKeyId=...",
  "id": "F22BC027BCE166BC89DD2A81358DA2F1"
}
```

### Step 2 — PUT the file bytes to `url`

```bash
curl -X PUT 'URL_FROM_STEP_1' --data-binary '@/path/to/report.pdf'
```

Do **not** send the `X-API-KEY` header to the S3 URL — it is already signed.

### Step 3 (optional) — poll for enrichment

Call Get Metadata with the returned `id` and watch `status` transition `processing` → `completed`. Once `completed`, the document is indexed and searchable via the Search API and the Research Agent.

---

## Python pattern

```python
import os
import requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE = "https://api.bigdata.com/contents/v1"
HEADERS = {"X-API-KEY": API_KEY}

# List
requests.get(f"{BASE}/documents", headers=HEADERS, params={"page_size": 10}).json()

# Get
requests.get(f"{BASE}/documents/{content_id}", headers=HEADERS).json()

# Upload
r = requests.post(
    f"{BASE}/documents",
    headers={**HEADERS, "Content-Type": "application/json"},
    json={"file_name": "report.pdf", "tags": ["Research"], "share_with_org": True},
).json()
with open("/path/to/report.pdf", "rb") as f:
    requests.put(r["url"], data=f).raise_for_status()
doc_id = r["id"]  # use with Get Metadata to poll status
```

## Related

- Getting started: https://docs.bigdata.com/getting-started/upload_your_own_content
- Content API intro: https://docs.bigdata.com/api-rest/content_introduction
