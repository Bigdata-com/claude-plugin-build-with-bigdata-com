# Download the original file

Two-step flow: ask the API for a pre-signed download URL, then GET the bytes from it.

## Step 1 — `GET /contents/v1/documents/{document_id}/original`

**Request**

```
GET https://api.bigdata.com/contents/v1/documents/{document_id}/original
Headers: X-API-KEY
```

**Response 200**

```json
{
  "url": "https://content.bigdata.com/original-documents/.../report.pdf?AWSAccessKeyId=..."
}
```

URL is time-limited (~24h). Host is `content.bigdata.com`, **not** `api.bigdata.com`.

## Step 2 — `GET <url>`

**Critical:** send **no headers** — not `X-API-KEY`, not `Content-Type`, nothing. The URL was signed with an empty header set; any added header produces `403 SignatureDoesNotMatch`. The response carries `Content-Type` and `Content-Disposition: attachment; filename="..."` set by the server.

## Canonical Python

```python
import requests

BASE    = "https://api.bigdata.com/contents/v1"
HEADERS = {"X-API-KEY": API_KEY}

def download_file(document_id, out_path):
    meta = requests.get(f"{BASE}/documents/{document_id}/original", headers=HEADERS)
    meta.raise_for_status()
    # CRITICAL: no headers= here — the URL is already signed.
    bytes_ = requests.get(meta.json()["url"]).content
    with open(out_path, "wb") as f:
        f.write(bytes_)
```

## curl equivalent

```bash
URL=$(curl -sf "https://api.bigdata.com/contents/v1/documents/$DOCUMENT_ID/original" \
  -H "X-API-KEY: $BIGDATA_API_KEY" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])")

curl -o report.pdf "$URL"     # no -H flags
```

## Errors

| Status | Meaning |
|---|---|
| 401 | Invalid or missing API key |
| 403 | Document not shared with your org |
| 404 | Document not found (or not yet `completed`) |

## Network note

The signed URL lives on `content.bigdata.com`, a different host from `api.bigdata.com`. Egress proxies/firewalls that allowlist only `api.bigdata.com` will block Step 2. If you run behind one, allow `content.bigdata.com:443` as a **CONNECT tunnel** — the proxy must not terminate TLS or modify headers, or the signature fails.
