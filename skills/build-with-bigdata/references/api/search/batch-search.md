# Batch Search API

Process large volumes of search queries asynchronously at **50% lower cost** ($0.0075 vs $0.015 per query unit). One `.jsonl` file in, one `.jsonl` file out — no client-side rate limiting or retry logic needed.

- API reference: [docs.bigdata.com/api-reference/batch-search](https://docs.bigdata.com/api-reference/batch-search/create-a-batch-job)
- How-to guide: [docs.bigdata.com/how-to-guides/search/batch_search](https://docs.bigdata.com/how-to-guides/search/batch_search)

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/search/batches` | Create a batch job → returns `batch_id` + `presigned_url` |
| PUT | `presigned_url` | Upload `.jsonl` input file to the presigned S3 URL |
| GET | `/v1/search/batches/{batch_id}` | Poll job status → returns `status` + `output_file_url` |
| GET | `output_file_url` | Download `.jsonl` results (available when status is `completed`) |

## Workflow

```
1. POST /v1/search/batches         → get batch_id + presigned_url
2. PUT  presigned_url              → upload .jsonl input file
3. GET  /v1/search/batches/{id}    → poll until status = "completed"
4. GET  output_file_url            → download .jsonl results
```

## Step 1: Create a batch job

```python
resp = requests.post(f"{BASE_URL}/v1/search/batches", headers=HEADERS)
resp.raise_for_status()
data = resp.json()
batch_id = data["batch_id"]
presigned_url = data["presigned_url"]
```

Response schema:

| Field | Type | Description |
|-------|------|-------------|
| `batch_id` | string | Unique job identifier |
| `presigned_url` | string (URI) | Temporary S3 URL for uploading the input file |

## Step 2: Prepare and upload the input file

Each line in the `.jsonl` file is an independent search request with a `query` object. Supports all [Search Documents](https://docs.bigdata.com/api-reference/search/search-documents) filters.

### Input file format

```json
{"query": {"text": "Impact of tariffs on semiconductor industry", "filters": {"timestamp": {"start": "2026-01-01", "end": "2026-03-01"}}, "max_chunks": 10}}
{"query": {"text": "Central bank interest rate decisions", "filters": {"timestamp": {"start": "2026-01-01", "end": "2026-03-01"}}, "max_chunks": 10}}
```

### Python: write and upload

```python
import json

queries = [
    {"query": {"text": "Impact of tariffs on semiconductor industry",
               "filters": {"timestamp": {"start": "2026-01-01", "end": "2026-03-01"}},
               "max_chunks": 10}},
    {"query": {"text": "Central bank interest rate decisions",
               "filters": {"timestamp": {"start": "2026-01-01", "end": "2026-03-01"}},
               "max_chunks": 10}},
]

input_path = "batch_input.jsonl"
with open(input_path, "w") as f:
    for q in queries:
        f.write(json.dumps(q) + "\n")

with open(input_path, "rb") as f:
    upload_resp = requests.put(
        presigned_url,
        headers={"Content-Type": "application/jsonl"},
        data=f,
    )
    upload_resp.raise_for_status()
```

## Step 3: Poll for completion

Status progression: `pending` → `processing` → `completed` (or `failed` / `cancelled`).

```python
import time

while True:
    status_resp = requests.get(
        f"{BASE_URL}/v1/search/batches/{batch_id}", headers=HEADERS
    )
    status_resp.raise_for_status()
    info = status_resp.json()

    if info["status"] == "completed":
        output_url = info["output_file_url"]
        break
    elif info["status"] in ("failed", "cancelled"):
        raise RuntimeError(f"Batch job {info['status']}: {info}")

    time.sleep(30)
```

Status response schema:

| Field | Type | Description |
|-------|------|-------------|
| `batch_id` | string | Job identifier |
| `status` | string | `pending`, `processing`, `completed`, `failed`, or `cancelled` |
| `output_file_url` | string (URI) or null | Presigned download URL (only when `completed`) |

## Step 4: Download results

```python
results_resp = requests.get(output_url)
results_resp.raise_for_status()

results = [json.loads(line) for line in results_resp.text.strip().splitlines()]
```

### Output file format

Each line in the results `.jsonl` contains:

| Field | Type | Description |
|-------|------|-------------|
| `line_number` | int | **1-indexed** line number matching the input file. Use `line_number - 1` to index into a 0-based Python list. |
| `status` | string | `success`, `error`, `timeout`, or `exception` |
| `query` | object | Original search query submitted |
| `response` | object | Search response for this query |
| `code` | int | HTTP status code |
| `error` | string | Error description (only present if failed) |
