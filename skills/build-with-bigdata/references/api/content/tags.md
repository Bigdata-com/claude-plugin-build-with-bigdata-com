# Tags

Tags label documents so you can filter them in List documents ([metadata.md](metadata.md)) and in Search / Research Agent. They live under a **separate resource** from documents: `https://api.bigdata.com/contents/v1/tags` (note: `tags`, not `documents`).

Some tags are created automatically by connectors: `label:Connector Name` for any connector, `from:user@email.com` / `to:user@email.com` for email, and `broker:Broker Name` for investment research. You can also create your own.

**Tag IDs vs names:** assigning a tag to an existing document (PATCH, see [metadata.md](metadata.md)) requires the tag **ID** (a UUID). Tag **names** are only accepted at upload time ([upload.md](upload.md)). So the usual flow is: create or list a tag here to get its `id`, then PATCH the document with that `id`.

## Create — `POST https://api.bigdata.com/contents/v1/tags`

Create a custom tag in your organization.

**Request**

```
POST https://api.bigdata.com/contents/v1/tags
Headers: X-API-KEY, Content-Type: application/json
Body:
{
  "tag_name": "Research Team"    // required — display name for the new tag
}
```

**Response 200**

```json
{
  "id":         "019e3a99-6952-7dd4-adf5-b0b341959e11",
  "name":       "Research Team",
  "created_at": "2026-05-18T10:19:53.044285Z",
  "updated_at": "2026-05-18T10:19:53.044290Z",
  "file_count": 0
}
```

Keep the returned `id` — that's what you pass in the `tags` array when updating a document.

**Errors**

| Status | Meaning |
|---|---|
| 400 | Invalid body — e.g. missing or empty `tag_name` |
| 401 | Invalid or missing API key |

## List — `GET https://api.bigdata.com/contents/v1/tags`

Return all tags visible to your org, each with the number of documents it's attached to.

**Request**

```
GET https://api.bigdata.com/contents/v1/tags
Headers: X-API-KEY
Query params (optional):
  prefix   return only tags whose name starts with this string, e.g. broker: | label: | from: | to:
```

**Response 200**

```json
{
  "results": [
    {
      "id":         "019a48b4-e573-7203-945a-2e7c4c164217",
      "name":       "from:user@email.com",
      "created_at": "2025-11-03T07:53:26.150858Z",
      "updated_at": "2025-11-03T07:53:26.150859Z",
      "file_count": 40
    }
  ]
}
```

Use `name` when filtering documents (the `tags` query param of List documents, Search, or Research Agent); use `id` when assigning via PATCH.

**Errors**

| Status | Meaning |
|---|---|
| 401 | Invalid or missing API key |

## Assign a tag to a document

There is no "add tag to document" endpoint. You set a document's tags through the document **Update** call documented in [metadata.md](metadata.md):

`PATCH https://api.bigdata.com/contents/v1/documents/{document_id}` with a `tags` array of tag **IDs**.

That array **replaces** the document's entire tag set (it does not merge), so send the full list you want applied. See [metadata.md](metadata.md) for the body, the replace-not-merge semantics, and the `400 INVALID_TAGS_ERROR` you get for unknown IDs.

## Python

```python
# 1. Create a tag (or list tags) to get its id.
r = requests.post(
    "https://api.bigdata.com/contents/v1/tags",
    headers=HEADERS,
    json={"tag_name": "Research Team"},
)
r.raise_for_status()
tag_id = r.json()["id"]

# Or look up an existing tag by name prefix.
r = requests.get(
    "https://api.bigdata.com/contents/v1/tags",
    headers=HEADERS,
    params={"prefix": "broker:"},
)
r.raise_for_status()
tags = r.json()["results"]

# 2. Assign it to a document (replaces the document's current tag set).
r = requests.patch(
    f"https://api.bigdata.com/contents/v1/documents/{document_id}",
    headers=HEADERS,
    json={"tags": [tag_id]},
)
r.raise_for_status()
```
