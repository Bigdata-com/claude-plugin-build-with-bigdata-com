# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## v0.3.0

### Added

- **Content API — new operations** — Expanded the Content reference from list/metadata/upload to the full operation set:
  - **Download** (`GET …/original`) — two-step pre-signed URL flow; documents the critical no-headers rule on the S3 PUT (any extra header causes `403 SignatureDoesNotMatch`) and a proxy note for `content.bigdata.com`.
  - **Annotated JSON** (`GET …/annotated`) — returns Bigdata's processed output (title/body blocks, sentiment, entities, events, metrics); only available after `status: completed`.
  - **Delete** (`DELETE …/{id}`) — permanent removal; documents the `PRIVATE_CONTENT_NOT_FOUND` error shape.

### Changed

- **SKILL.md** — Content section updated to list all six operations and link to the new content structure.

### Removed

- **`references/api/content/documents.md`** — superseded by the per-operation files.

## v0.2.0

### Changed

- **Search (documents) reference** — Major expansion based on empirical API exploration (~115 live requests):
  - Added **Limits & constraints** table: `entity` arrays capped at 500 IDs, `source.values` capped at 500, `max_chunks` max 1000, `chunk.from` is 1-based, `fiscal_quarter` range 1–4. Includes exact error messages for each limit.
  - Rewrote **search modes** section with a parameter-level fast vs smart comparison table; clarifies that `ranking_params` and all filters except `timestamp`/`source` are auto-only in smart mode (HTTP 400 if passed manually).
  - Added **complete `document_type` enumeration** — all five top-level types (`FILING`, `INVESTMENT-RESEARCH`, `NEWS`, `TRANSCRIPT`, `TRANSCRIPT-PRESENTATION`) with every validated subtype (e.g. all SEC filing subtypes, all 15 investment research subtypes, all 12 transcript subtypes).
  - Added **`category` filter values** — full lowercase-only list (`news`, `news_premium`, `news_public`, `transcripts`, `filings`, `research`, `research_investment_research`, `research_academic_journals`, `podcasts`, `expert_interviews`, `expert_networks`, `newsletters`, `my_files`, `regulatory`). Uppercase returns 400.
  - Added **`sentiment.ranges`** documentation as the current form; noted deprecated `values` must be lowercase (`positive`/`negative`/`neutral`).
  - Added new filter sections: **`topic`** (comma-path format, `search_in`), **`reporting_entities`/`reporting_periods`** (fiscal period rules), **`chunk`** (context expansion with `document` ID filter), **`document`** ID filter.
  - Added **reranker threshold** empirical guide (0.8 cuts ~half results, 0.9 leaves very few, 1.0 returns nothing).
  - Added **error patterns** table for common 400/401/429 shapes.
- **SKILL.md** — Added concise callouts for filter limits (500 IDs, 1000 max_chunks), smart mode restrictions (ranking_params also auto-only), complete document type note, lowercase-only category values, and chunk context expansion pattern.
- **Release workflow** — `actions/checkout@v6`; `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` for JavaScript actions (Node 20 deprecation). If a release for the tag already exists, `gh release upload … --clobber` instead of failing `gh release create` on reruns.

## v0.1.0

### Added

- **README** — Work-in-progress notice; table of APIs covered by bundled references; prominent link to [bigdata-cookbook Sample_Scripts](https://github.com/Bigdata-com/bigdata-cookbook/tree/main/API_Tutorials/Sample_Scripts); direct links to [build-with-bigdata SKILL.md](skills/build-with-bigdata/SKILL.md) (repository path + GitHub); documents `.mcp.json` in “What’s included.”
- **Search (documents) reference** — Document `ranking_params.content_diversification` (enabled by default; disable via `enabled: false`); `document_type` **INVESTMENT_RESEARCH** and subtypes; optional chunk **text_locations** (`paragraph_num`, `sentence_num`); **SEC_DEF_14A** filing subtype for proxy statements.
- **Co-mentions reference** — Document optional **`query.entity_categories`** to filter returned entity buckets.

### Changed

- **SKILL.md** — Knowledge Graph link now points to [knowledge-graph/main.md](skills/build-with-bigdata/references/api/knowledge-graph/main.md); Search and Co-mentions summaries updated for diversification and `entity_categories`.

### Removed

- **`tests/bigdata_use_cases_tests.md`** and the `tests/` directory — example prompts and workflows are maintained in [bigdata-cookbook Sample_Scripts](https://github.com/Bigdata-com/bigdata-cookbook/tree/main/API_Tutorials/Sample_Scripts) instead to keep the plugin package small.

### Fixed

- **Release workflow** — `build-plugin.sh` now uses the git tag passed by CI (e.g. `v0.1.0`) for the zip filename so `gh release create` finds `dist/claude-plugin-build-with-bigdata-com_<tag>.zip`. Local builds without arguments still use the version from `plugin.json`.
- **Release workflow** — Build and `gh release create` run in a **single** step with an **absolute** path to the zip; `zip` is installed via `apt-get` on the runner. Avoids `gh` reporting “no matches found” when the asset path did not resolve to an existing file between steps.

## v0.0.1

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
