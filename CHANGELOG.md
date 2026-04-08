# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- **Search (documents)** — Reference doc and skill section for `POST /v1/search`: semantic search, request/response shape, filters (timestamp, entity), `ranking_params` (freshness_boost, source_boost), `max_chunks`, `auto_enrich_filters`. Includes minimal Python sample aligned with OpenAPI.
- **Volume** — Reference doc and skill section for `POST /v1/search/volume`: same query shape as Search, response `results.volume` (date, documents, chunks, sentiment) and `results.total`. Includes minimal Python sample.
- **Knowledge Graph** — Reference doc and skill section for companies, entities by ID (max 100 per request), and sources: endpoints, request/response fields, and Python sample for companies + entity resolution.
- **Co-mentions** — Reference doc and skill section for `POST /v1/search/co-mentions/entities`: query shape, response by category (companies, places, people, etc.), optional `limit`, and sample resolving entity IDs via Knowledge Graph.
- **build-with-bigdata skill** — Extended description and "Available APIs" table with links to all four new references; short subsections for when to use each endpoint; note to apply bigdata-mcp-grounding when using MCP tools.
- **OpenAPI alignment** — Reference docs use parameter and response field names from the local OpenAPI specs (`openapi_search_service.json`, `openapi_knowledge_graph.json`); sample code request bodies match the specs.
- **Use-case tests** — Added `tests/bigdata_use_cases_tests.md` with 10 end-to-end use cases (co-mention maps, volume spike extraction, earnings sentiment, competitor comparison, macro radar, person profiler, daily briefing, source quality benchmark, geopolitical heatmap, thematic universe builder) including example prompts and expected API workflows.

### Fixed

- Volume and Co-mentions reference docs and SKILL.md summaries incorrectly listed `ranking_params` (freshness_boost, source_boost) as supported parameters. Per the OpenAPI spec, only `POST /v1/search` supports `ranking_params`; Volume and Co-mentions accept `text`, `filters`, and `auto_enrich_filters` only.

### Changed

- Skill `build-with-bigdata` now covers Search (documents), Volume, Knowledge Graph, and Co-mentions in addition to Batch Search.
