#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

PLUGIN_ID="claude-plugin-build-with-bigdata-com"
OUTPUT_DIR="dist"
MANIFEST=".claude-plugin/plugin.json"

if [ ! -f "${MANIFEST}" ]; then
  echo "ERROR: Plugin manifest not found: ${MANIFEST}" >&2
  exit 1
fi

VERSION_FROM_MANIFEST=$(python3 -c "import json; print(json.load(open('${MANIFEST}'))['version'])")

# Optional first argument: git ref (e.g. v0.1.0). CI passes "${{ github.ref_name }}" so the zip
# name matches what gh release create attaches. Local runs omit this and use the manifest version only.
if [ "${1:-}" != "" ]; then
  ZIP_LABEL="$1"
else
  ZIP_LABEL="${VERSION_FROM_MANIFEST}"
fi

OUTPUT_FILE="${OUTPUT_DIR}/${PLUGIN_ID}_${ZIP_LABEL}.zip"

mkdir -p "${OUTPUT_DIR}"

echo "Building plugin package: ${OUTPUT_FILE}"
rm -f "${OUTPUT_FILE}"

zip -r "${OUTPUT_FILE}" \
  .claude-plugin/ \
  .mcp.json \
  commands/ \
  skills/

echo "Created: ${OUTPUT_FILE}"
