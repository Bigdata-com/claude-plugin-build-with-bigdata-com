# Upload a document

Two-step flow: ask the API for a pre-signed URL, then PUT the raw bytes to it. Processing is async — call [metadata.md](metadata.md) on the returned `id` to check `status`.

## Step 1 — `POST /contents/v1/documents`

Reserve a slot and get the pre-signed upload URL.

**Request**

```
POST https://api.bigdata.com/contents/v1/documents
Headers: X-API-KEY, Content-Type: application/json
Body:
{
  "file_name":       "report.pdf",       // required
  "published_ts":    "<ISO 8601>",       // optional
  "tags":            ["Research Team"],  // optional
  "share_with_org":  true                // optional
}
```

**Response 200**

```json
{
  "id":  "F22BC027BCE166BC89DD2A81358DA2F1",
  "url": "https://s3.amazonaws.com/.../uploads/F22BC027BCE166BC89DD2A81358DA2F1?AWSAccessKeyId=..."
}
```

Getting an `id` back only means the slot is reserved. The file is **not uploaded yet** — Step 2 is the upload.

## Step 2 — `PUT <url>`

Send the raw file bytes to the pre-signed URL.

**Critical:** send **no headers** — not `X-API-KEY`, not `Content-Type`, not `x-amz-*`. The URL was signed with an empty header set; any header you add changes the canonical request S3 rebuilds and you get `403 SignatureDoesNotMatch`.

```
PUT <url>
Headers: (none)
Body:    raw file bytes
```

**Response 200** (empty body).

## Canonical Python

```python
import os, requests

API_KEY = os.environ["BIGDATA_API_KEY"]
BASE    = "https://api.bigdata.com/contents/v1"

def upload_file(path, tags=None, share_with_org=False):
    body = {"file_name": os.path.basename(path)}
    if tags:           body["tags"] = tags
    if share_with_org: body["share_with_org"] = True

    init = requests.post(
        f"{BASE}/documents",
        headers={"X-API-KEY": API_KEY, "Content-Type": "application/json"},
        json=body,
    )
    init.raise_for_status()
    init = init.json()

    # CRITICAL: no headers= on this request. The URL is already signed.
    with open(path, "rb") as f:
        requests.put(init["url"], data=f).raise_for_status()

    return init["id"]
```

## curl equivalent

```bash
INIT=$(curl -sf -X POST 'https://api.bigdata.com/contents/v1/documents' \
  -H "X-API-KEY: $BIGDATA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"file_name\": \"$(basename "$FILE")\"}")

URL=$(echo "$INIT" | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])")

# -T sends raw bytes without adding any Content-Type. Do NOT use --data-binary
# (it adds Content-Type: application/x-www-form-urlencoded and breaks the signature).
curl -sf -X PUT "$URL" -T "$FILE"
```

## Symptom to recognize

POST returns an `id` but later `GET /contents/v1/documents/{id}` shows `raw_size: 0` and `status: pending` indefinitely → the PUT silently failed, almost always because a header got added. Re-run Step 2 with no headers.
