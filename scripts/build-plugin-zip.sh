#!/bin/bash
# Build the FunTell plugin zip for Claude Cowork
# Output: funtell-plugin.zip in the project root

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_DIR="$PROJECT_ROOT/funtell-plugin"
OUTPUT="$PROJECT_ROOT/funtell-plugin.zip"

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: funtell-plugin directory not found at $PLUGIN_DIR"
  exit 1
fi

# Remove old zip if exists
rm -f "$OUTPUT"

# Build zip from plugin directory
cd "$PLUGIN_DIR"
zip -r "$OUTPUT" . -x "*.DS_Store" -x "__MACOSX/*"

echo ""
echo "Built: $OUTPUT"
echo "Contents:"
unzip -l "$OUTPUT"
