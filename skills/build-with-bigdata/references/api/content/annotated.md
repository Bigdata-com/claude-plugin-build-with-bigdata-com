# Fetch the processed JSON — `GET https://api.bigdata.com/contents/v1/documents/{document_id}/annotated`

Returns the structured result of Bigdata's processing: title/body blocks plus analytics (sentiment, detected entities, events, metrics). This is different from [download.md](download.md), which returns the raw original file.

Only available once metadata `status` is `completed`.

## Request

```
GET https://api.bigdata.com/contents/v1/documents/{document_id}/annotated
Headers: X-API-KEY
```

## Response 200

```json
{
  "url":        "<pre-signed URL, valid ~24h>",
  "document":   { /* metadata */ },
  "content":    { /* title and body blocks */ },
  "profiling":  { /* processor timestamps */ },
  "analytics":  { /* metrics, events, entities */ }
}
```

## Python

```python
r = requests.get(f"{BASE}/documents/{document_id}/annotated", headers=HEADERS)
r.raise_for_status()
data = r.json()
# data["content"]["body"] for the processed text blocks
# data["analytics"]["entities"] for detected entities, etc.
```
