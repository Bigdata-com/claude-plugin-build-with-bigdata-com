---
description: Generate a complete, ready-to-run Python script that implements the Bigdata.com Batch Search API workflow.
---

The script must:

1. Read the API key from the `BIGDATA_API_KEY` environment variable
2. Create a batch job via `POST https://api.bigdata.com/v1/search/batches`
3. Build a `.jsonl` input file with example search queries
4. Upload the input file to the presigned URL returned by the API
5. Poll `GET /v1/search/batches/{batch_id}` until the status is `completed`
6. Download and parse the `.jsonl` results from `output_file_url`
7. Print a summary of the results to stdout

Requirements:

- Use only the `requests` standard library (plus `os`, `json`, `time`)
- Authenticate with the `X-API-KEY` header
- Include error handling for each API call (raise on non-2xx responses)
- Include clear inline comments explaining each workflow step
- Set a reasonable polling interval (e.g., 30 seconds)
- Handle terminal statuses (`failed`, `cancelled`) gracefully
- Save the script to the current working directory

Use the `build-with-bigdata` skill for the correct base URL, headers, endpoint paths, and Batch Search API details.
