# Build with Bigdata.com — Claude Plugin

A Claude plugin that helps developers integrate with [Bigdata.com](https://bigdata.com) REST APIs. It ships a skill with reference material for the Search family (document search, volume, co-mentions, batch search) and the Knowledge Graph—**more API coverage will be added over time** (work in progress).

## Skills

| Skill | Description |
|-------|-------------|
| [build-with-bigdata](skills/build-with-bigdata/SKILL.md) | API integration guide and bundled reference markdown (`references/api/...`). |

On GitHub: [skills/build-with-bigdata/SKILL.md](https://github.com/Bigdata-com/claude-plugin-build-with-bigdata-com/blob/main/skills/build-with-bigdata/SKILL.md).

## APIs documented in this plugin

Reference docs live under [skills/build-with-bigdata/references/api/](skills/build-with-bigdata/references/api/). Covered today:

| Area | Endpoints (summary) |
|------|---------------------|
| **Search (documents)** | `POST /v1/search` |
| **Volume** | `POST /v1/search/volume` |
| **Co-mentions** | `POST /v1/search/co-mentions/entities` |
| **Batch Search** | `POST /v1/search/batches` (create job, poll, download results) |
| **Knowledge Graph** | `POST /v1/knowledge-graph/companies`, `POST /v1/knowledge-graph/entities/id`, `POST /v1/knowledge-graph/sources`, `GET /v1/knowledge-graph/companies/sectors` |

See the [build-with-bigdata](skills/build-with-bigdata/SKILL.md) skill for links to each reference file. For the full platform API surface, use [docs.bigdata.com/api-reference](https://docs.bigdata.com/api-reference/).

## Getting Started

1. **Install the plugin**: Add `build-with-bigdata-com` to your Claude environment (or build from this repo; see [CONTRIBUTING.md](CONTRIBUTING.md)).
2. **Get an API key**: Sign up at [Bigdata.com](https://bigdata.com) and [generate an API key](https://platform.bigdata.com/api-keys).
3. **Explore the APIs**: Browse [docs.bigdata.com/api-reference](https://docs.bigdata.com/api-reference/) for endpoint details, request/response schemas, and authentication (`X-API-KEY`).
4. **Try the playgrounds**: The [Developer Platform](https://platform.bigdata.com/) includes interactive playgrounds with example requests and responses.

## Example scripts (external)

Runnable Python samples for many workflows (co-mention maps, volume spikes, batch earnings sentiment, and more) are maintained in the **[bigdata-cookbook — API_Tutorials/Sample_Scripts](https://github.com/Bigdata-com/bigdata-cookbook/tree/main/API_Tutorials/Sample_Scripts)** repository. See that repo’s [README](https://github.com/Bigdata-com/bigdata-cookbook/blob/main/API_Tutorials/Sample_Scripts/README.md) for a use-case index. They use the same APIs as this plugin’s skill and are kept out of the plugin package to keep installs small.

## What’s Included

| Component | Description |
|-----------|-------------|
| [skills/build-with-bigdata/](skills/build-with-bigdata/) | Skill ([SKILL.md](skills/build-with-bigdata/SKILL.md)) and API reference markdown. |
| `commands/` | Slash commands for common integration tasks. |
| `.mcp.json` | Optional Docs MCP server config for [docs.bigdata.com](https://docs.bigdata.com/). |
| `.claude-plugin/plugin.json` | Plugin manifest. |

## Useful Links

- [API documentation](https://docs.bigdata.com/api-reference/)
- [Developer Platform & Playgrounds](https://platform.bigdata.com/)
- [Bigdata.com](https://bigdata.com)

## License

See [LICENSE](LICENSE) for details.
