# Delete a document — `DELETE https://api.bigdata.com/contents/v1/documents/{document_id}`

Permanently removes a document you own.

## Request

```
DELETE https://api.bigdata.com/contents/v1/documents/{document_id}
Headers: X-API-KEY
```

## Response

- **200 OK** — empty/null body on success
- **401** — invalid or missing API key
- **403** — you do not have permission to delete this document (not the owner)
- **404** — `{"statusCode": 404, "message": "Document not found", "errorCode": "PRIVATE_CONTENT_NOT_FOUND", "requestId": "..."}`

## Python

```python
r = requests.delete(f"{BASE}/documents/{document_id}", headers=HEADERS)
r.raise_for_status()
```
