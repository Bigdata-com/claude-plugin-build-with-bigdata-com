# Contributing

This plugin is part of the **Anthropic plugin directory**. Changes merged to `main` should be tested locally before merging. **GitHub Releases** (with the installable zip) are created when you push a **version tag** (see [Creating a Release](#creating-a-release)), not automatically on every merge to `main`.

## Local Testing

Before opening a pull request or merging to `main`, build and install the plugin locally to verify your changes work correctly in Claude.

### 1. Build the plugin zip

From the repository root, run:

```bash
./scripts/build-plugin.sh
```

This reads the version from `.claude-plugin/plugin.json` and produces a zip file at:

```
dist/claude-plugin-build-with-bigdata-com_<version>.zip
```

The zip contains `.claude-plugin/`, `commands/`, `skills/` (including the **build-with-bigdata** skill and API reference markdown), and `.mcp.json` (optional Docs MCP config)—everything the build script packs for Claude to load the plugin.

### 2. Install in your local Claude environment

1. Open **Claude Desktop** and go to **Settings > Plugins**.
2. Choose **Install from file…** and select the zip from the `dist/` folder.
3. Confirm the plugin appears in the plugin list and is enabled.

### 3. Verify your changes

- Exercise the specific commands or features you modified.
- Confirm there are no errors in the Claude plugin logs.
- If you changed `plugin.json` metadata, verify the name, description, and version display correctly.

> **Tip:** If you need to iterate, re-run `./scripts/build-plugin.sh` and reinstall the updated zip. The version in `plugin.json` does not need to change during local testing — only bump it when preparing a release.

## Creating a Release

This repository uses GitHub Actions to automatically create releases when a new tag is pushed. The workflow will zip the folder and attach it to the release.

### Tag Format

Tags must follow this format: `v<major>.<minor>.<patch>`

| Tag | Valid? |
|-----|--------|
| `v0.0.1` | ✅ |
| `v1.2.3` | ✅ |
| `v2.0.0-beta` | ✅ |
| `0.0.1` | ❌ (missing `v` prefix) |
| `version1` | ❌ (wrong format) |

### Steps

1. **Test locally** using the workflow above.
2. Update the `version` field in `.claude-plugin/plugin.json` to match the new tag.
3. Tag and push:

```bash
git tag v0.0.1
git push origin v0.0.1
```

This will trigger the CI/CD pipeline and create a GitHub Release with the plugin zip attached. Because this plugin is listed in the Anthropic plugin directory, the release is immediately available to all users.
