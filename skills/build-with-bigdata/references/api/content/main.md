# Content API — Documents

Manage user-uploaded documents on Bigdata.com: upload and download files, and list, read metadata, fetch the processed JSON, or delete existing ones. After an upload, processing the file is **async** — poll metadata until `status` goes from `pending`/`processing` → `completed`.

## Base

- **Host:** `https://api.bigdata.com`
- **Auth:** `X-API-KEY: <api_key>` on every request to `api.bigdata.com`. Do **not** send it on pre-signed data-plane URLs (see upload / download) — those URLs already carry authorization and any extra header risks `403 SignatureDoesNotMatch`.

## Tooling

Prefer Python `requests` for programmatic flows — the per-operation pages use it as the canonical example. Fall back to `curl` only for one-off calls or when `requests` isn't installed. Both speak HTTP just fine; the preference is about readability of multi-step flows.

## If a call returns HTTP 400

The shape documented in this skill may be stale. Check the live reference first, then query the `docs.bigdata.com` Docs MCP server (`server="docs.bigdata.com"`) before debugging the rest of your code — the API can add required fields or rename parameters between skill releases.

**Live reference:** [docs.bigdata.com/api-reference/documents/](https://docs.bigdata.com/api-reference/documents/)

## Path pitfall — `contents` is plural

Base path is `/contents/v1/documents`. Calling `/content/v1/...` (singular) or any unknown sub-path (e.g. `/download`, `/file`) returns AWS API Gateway's `{"message": "Missing Authentication Token"}` — which **looks like** an auth failure but means "no such route." If a call with a valid key returns `MissingAuthenticationToken`, check the path spelling before anything else.

## Available operations

| Operation | File | Endpoint |
|---|---|---|
| Upload a file (two-step) | [upload.md](upload.md) | `POST /contents/v1/documents` → `PUT <presigned url>` |
| Download the original file (two-step) | [download.md](download.md) | `GET /contents/v1/documents/{id}/original` → `GET <presigned url>` |
| List documents / get one document's metadata | [metadata.md](metadata.md) | `GET /contents/v1/documents` and `GET /contents/v1/documents/{id}` |
| Fetch the processed JSON (sentiment, entities, events…) | [annotated.md](annotated.md) | `GET /contents/v1/documents/{id}/annotated` |
| Delete a document | [delete.md](delete.md) | `DELETE /contents/v1/documents/{id}` |
