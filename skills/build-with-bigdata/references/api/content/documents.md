# Content API — Documents

Manage user-uploaded documents on Bigdata.com: **list**, **get metadata**, **upload (enrich)**, and **download the original file**.
Upload is a **two-step flow**: `POST /contents/v1/documents` returns a pre-signed S3 `url` + content `id`; then **PUT** the raw file bytes to that `url` (do not send `X-API-KEY` to S3 — the URL is already signed). Enrichment is async — poll `GET /contents/v1/documents/{id}` until `status` transitions `processing` → `completed`. Download is also a two-step flow: `GET /contents/v1/documents/{id}/original` returns a pre-signed `url` on `content.bigdata.com`; then **GET** that URL for the raw bytes.

Base URL: `https://api.bigdata.com` · Auth header: `X-API-KEY: <api_key>`

**Live reference:** [docs.bigdata.com/api-reference/documents/list-documents](https://docs.bigdata.com/api-reference/documents/list-documents)

### Path pitfall — `contents` is plural

The base path is `/contents/v1/documents` (plural **contents**). Calling `/content/v1/...` (singular) hits AWS API Gateway's "no such route" handler and returns:

```json
{"message": "Missing Authentication Token"}
```

That error is **misleading** — it does not mean your `X-API-KEY` is wrong. If a call with a valid key starts returning `MissingAuthenticationToken`, the first thing to check is the path spelling. The same error appears for any unknown sub-path (e.g. `/contents/v1/documents/{id}/download`, `/download-url`, `/file`). The only supported download suffix is `/original` — don't guess, use that.

### Tooling note

Prefer Python `requests` for any multi-step or programmatic flow — it is the cleaner choice and the canonical examples in this document use it. Use `curl` for quick one-off calls or when `requests` is genuinely unavailable.

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

### What "success" means

A successful upload is **all three of these**, in order:

1. `POST /contents/v1/documents` → HTTP 200, body contains `id` and `url`
2. `PUT <url>` (raw bytes, no extra headers) → HTTP 200 (empty body)
3. `GET /contents/v1/documents/{id}` eventually shows `raw_size > 0` and `status` not `failed`

**Do not stop after step 1.** Getting an `id` back means the slot was reserved — the file is not uploaded yet. The upload is the PUT. Both must succeed.

---

### The exact contract

```
POST /contents/v1/documents
  Headers: X-API-KEY, Content-Type: application/json
  Body:     {"file_name": "report.pdf"}   ← only required field
  Returns:  {"id": "<32-char hex>", "url": "<presigned S3 url>"}

PUT <url>
  Headers:  (none — not even Content-Type)
  Body:     raw file bytes
  Returns:  200 OK, empty body
```

That's it. Do not add to it.

---

### Step 1 — `POST /contents/v1/documents`

| Field | Type | Required | Description |
|---|---|---|---|
| `file_name` | string | **Yes** | e.g. `report.pdf` |
| `published_ts` | ISO 8601 | No | Publication timestamp for ordering |
| `tags` | array of strings | No | Tag names for categorization |
| `share_with_org` | boolean | No | `true` = org members can access |

```bash
# Minimal — only file_name is required
curl -X POST 'https://api.bigdata.com/contents/v1/documents' \
  -H 'X-API-KEY: YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"file_name": "report.pdf"}'

# With optional fields
curl -X POST 'https://api.bigdata.com/contents/v1/documents' \
  -H 'X-API-KEY: YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "file_name": "report.pdf",
    "published_ts": "2025-06-15T10:30:00Z",
    "tags": ["Research Team"],
    "share_with_org": true
  }'
```

Response:

```json
{
  "url": "https://s3.amazonaws.com/.../uploads/F22BC027BCE166BC89DD2A81358DA2F1?AWSAccessKeyId=...",
  "id": "F22BC027BCE166BC89DD2A81358DA2F1"
}
```

### Step 2 — PUT the file bytes to `url`

```bash
curl -X PUT "$URL" -T "/path/to/report.pdf"
```

Use `-T` (`--upload-file`), not `--data-binary`. `-T` sends raw bytes with **no headers added by curl** — exactly what the presigned URL requires. `--data-binary` silently adds `Content-Type: application/x-www-form-urlencoded`, which breaks the S3 signature.

On success, S3 returns an empty `200 OK`. curl may appear to hang briefly while the connection closes — that is normal.

> **Silent failure symptom:** POST succeeds (you get an `id`) but `GET /contents/v1/documents/{id}` shows `raw_size: 0` and `status: pending` indefinitely. This means the PUT silently failed — most likely due to a bad header. Re-run the PUT with no extra headers.

### Step 3 (optional) — poll for enrichment status

Call Get Metadata with the `id` from Step 1 and watch `status`:
- `processing` — Bigdata is enriching the document
- `completed` — indexed and searchable via Search API and Research Agent
- `failed` — enrichment failed; check `error_code`

**List endpoint is eventually consistent.** After a successful PUT, the document may not appear immediately in `GET /contents/v1/documents`. If list verification is part of your flow, wait 3–5 seconds and retry before declaring failure.

---

### ❌ Anti-patterns — do not do any of these

| What | Why it breaks |
|---|---|
| `PUT` with `--data-binary` | Silently adds `Content-Type: application/x-www-form-urlencoded`, which changes the S3 canonical request hash → `403 SignatureDoesNotMatch`. Use `-T` instead. |
| `PUT` with `-H "Content-Type: application/pdf"` (or any value) | The presigned URL was signed with no `Content-Type`. Any value you add changes the S3 canonical request hash → `403 SignatureDoesNotMatch` |
| `PUT` with `-H "X-API-KEY: ..."` | S3 doesn't know your API key; adding it changes the canonical request hash → `403 SignatureDoesNotMatch` |
| Stopping after POST returns an `id` | The file has not been uploaded yet. The PUT is the upload. |
| Declaring list-verify failed immediately after PUT | The list endpoint has eventual consistency — retry after a short delay |
| Probing response fields for fallback keys | The contract is fixed: `id` and `url`. No fallback parsing. |
| Changing MIME type or request shape "to be helpful" | Boring is correct. Follow the contract exactly. |

---

### Canonical single-file upload script

This is the exact known-good pattern. Copy it first; vary it only if you have a specific reason.

**curl:**

```bash
FILE="/path/to/report.pdf"
API_KEY="YOUR_API_KEY"

# Step 1 — init
INIT=$(curl -sf -X POST 'https://api.bigdata.com/contents/v1/documents' \
  -H "X-API-KEY: $API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"file_name\": \"$(basename $FILE)\"}")

URL=$(echo "$INIT" | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])")
ID=$(echo  "$INIT" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

# Step 2 — upload (no extra headers; -T sends raw bytes without adding Content-Type)
curl -sf -X PUT "$URL" -T "$FILE"

echo "Uploaded. id=$ID"
```

**Python:**

```python
import os, time, requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE    = "https://api.bigdata.com/contents/v1"
HEADERS = {"X-API-KEY": API_KEY}

def upload_file(file_path, tags=None, share_with_org=False):
    # Step 1 — init
    payload = {"file_name": os.path.basename(file_path)}
    if tags:            payload["tags"] = tags
    if share_with_org:  payload["share_with_org"] = True

    r = requests.post(
        f"{BASE}/documents",
        headers={**HEADERS, "Content-Type": "application/json"},
        json=payload,
    )
    r.raise_for_status()
    init = r.json()

    # Step 2 — upload
    # CRITICAL: do NOT pass headers= here. The presigned URL is already signed
    # with no Content-Type. Any added header breaks the S3 signature → 403.
    with open(file_path, "rb") as f:
        put_r = requests.put(init["url"], data=f)
    put_r.raise_for_status()  # S3 returns 200 with empty body on success

    return init["id"]

doc_id = upload_file("/path/to/report.pdf", tags=["Research"], share_with_org=True)
print(f"Uploaded. id={doc_id}")
```

---

### Batch upload recipe

Use the single-file pattern in a loop. Do not invent orchestration.

```python
import os, time, requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE    = "https://api.bigdata.com/contents/v1"
HEADERS = {"X-API-KEY": API_KEY}

files = ["/path/to/a.pdf", "/path/to/b.pdf", "/path/to/c.pdf"]
results = []

for file_path in files:
    r = requests.post(
        f"{BASE}/documents",
        headers={**HEADERS, "Content-Type": "application/json"},
        json={"file_name": os.path.basename(file_path)},
    )
    r.raise_for_status()
    init = r.json()

    with open(file_path, "rb") as f:
        requests.put(init["url"], data=f).raise_for_status()

    results.append({"file": file_path, "id": init["id"]})
    print(f"  uploaded {os.path.basename(file_path)} → {init['id']}")

print(f"\nDone. {len(results)} files uploaded.")
```

---

### Reporting format

When reporting an upload to the user, include:

| Field | Example |
|---|---|
| File path | `/path/to/report.pdf` |
| File size | `42 KB` |
| Tags | `["Research Team"]` |
| Returned `id` | `F22BC027BCE166BC89DD2A81358DA2F1` |
| Init HTTP status | `200` |
| Upload (PUT) HTTP status | `200` |
| Verify HTTP status | `200` (or "skipped") |
| Init duration | `0.3 s` |
| Upload duration | `1.1 s` |
| Verify duration | `0.2 s` (or "delayed — retried after 4 s") |
| Total duration | `1.6 s` |

---

### Troubleshooting

| Symptom | Most likely cause | Fix |
|---|---|---|
| `403 SignatureDoesNotMatch` on PUT | Extra header on the PUT request | Re-run PUT with no headers at all (or just `-H "Content-Type:"` in curl to strip it) |
| `raw_size: 0`, `status: pending` forever | PUT silently failed | Check PUT shape; re-run without extra headers |
| File not in list right after PUT | Eventual consistency lag | Wait 3–5 s and retry the list call before concluding it failed |
| POST succeeds, PUT returns 403 | Added `X-API-KEY` or `Content-Type` to PUT | Strip all headers from the PUT |
| `{"message": "Missing Authentication Token"}` | Wrong path (singular `content` instead of plural `contents`) | Check path spelling |

## 4. Download the original file — `GET /contents/v1/documents/{content_id}/original`

Fetch the raw bytes of a document you previously uploaded. Like upload, this is a **two-step flow**.

### Step 1 — Request a pre-signed download URL

```bash
curl -s "https://api.bigdata.com/contents/v1/documents/$CONTENT_ID/original" \
  -H "X-API-KEY: $BIGDATA_API_KEY"
```

Response:

```json
{
  "url": "https://content.bigdata.com/original-documents/.../report.pdf?AWSAccessKeyId=..."
}
```

The URL is time-limited (~24h). `X-API-KEY` is required on the `api.bigdata.com` call; on the signed `content.bigdata.com` URL it is **not** needed (and adding headers can break the signature, same as upload).

### Step 2 — GET the bytes from `content.bigdata.com`

```bash
curl -o report.pdf "$URL"
```

The response carries the correct `Content-Type` and a `Content-Disposition: attachment; filename="..."` header with the original file name.

**Do not send `X-API-KEY` (or any other auth/`Content-Type` header) to the signed `content.bigdata.com` URL.** Same rule as upload: the URL is already signed and any added header changes the canonical request S3 hashes, producing `403 SignatureDoesNotMatch`. Use `curl "$URL"` with no `-H` flags. In Python, don't pass `headers=` to the second `requests.get`.

### Errors

| Status | Meaning |
|---|---|
| 401 | Invalid or missing API key |
| 403 | Document not shared with your org |
| 404 | Document not found (or not yet `completed`) |

### Python pattern

```python
r = requests.get(
    f"{BASE}/documents/{content_id}/original",
    headers=HEADERS,
).json()
# Do NOT pass headers= to the content.bigdata.com GET — the URL is already signed.
with open("report.pdf", "wb") as f:
    f.write(requests.get(r["url"]).content)
```

> **Network note:** the signed URL lives on `content.bigdata.com`, a different host from `api.bigdata.com`. Egress proxies / firewalls that allowlist only `api.bigdata.com` will block this step. From inside a NemoClaw sandbox, `content.bigdata.com` must be in the `bigdata.yaml` preset with `access: full` (CONNECT tunnel) so the pre-signed signature survives.

---

## Related

- Getting started: https://docs.bigdata.com/getting-started/upload_your_own_content
- Content API intro: https://docs.bigdata.com/api-rest/content_introduction
- Download reference: https://docs.bigdata.com/api-reference/documents/get-original-document
