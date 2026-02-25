#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="$(cd "${ROOT_DIR}/.." && pwd)/dist"
WXS_FILE="${SCRIPT_DIR}/xsecuritas-watermark-bootstrap.wxs"
OUTPUT_MSI="${DIST_DIR}/xsecuritas-watermark-bootstrap.msi"

mkdir -p "${DIST_DIR}"

wixl -o "${OUTPUT_MSI}" "${WXS_FILE}"

echo "Built MSI: ${OUTPUT_MSI}"
