#!/bin/bash

# Combine stored procedures with DROP statements

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$PROJECT_ROOT/sql/all_stored_procedures.sql"

# Clear output file
> "$OUTPUT_FILE"

echo "-- Combined Stored Procedures" >> "$OUTPUT_FILE"
echo "-- Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Add drop all functions at the beginning
echo "-- Drop all existing functions first" >> "$OUTPUT_FILE"
cat "$PROJECT_ROOT/sql/drop_all_functions_simple.sql" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process each SQL file
process_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo "-- File: $filename" >> "$OUTPUT_FILE"
    echo "-- -----------------------------------------------------------------" >> "$OUTPUT_FILE"
    
    # Extract function names for DROP statements
    grep -E "^CREATE OR REPLACE FUNCTION" "$file" | while read -r line; do
        # Extract function name (handle both public.function_name and just function_name)
        func_name=$(echo "$line" | sed -E 's/^CREATE OR REPLACE FUNCTION (public\.)?([a-zA-Z0-9_]+)\(.*/\2/')
        if [[ "$func_name" != "" && "$func_name" != "$line" ]]; then
            echo "DROP FUNCTION IF EXISTS $func_name CASCADE;" >> "$OUTPUT_FILE"
        fi
    done
    
    echo "" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Client-side procedures
echo "-- =================================================================" >> "$OUTPUT_FILE"
echo "-- CLIENT-SIDE PROCEDURES" >> "$OUTPUT_FILE"
echo "-- =================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for file in "$PROJECT_ROOT"/sql/storeproc/client-side/*.sql; do
    [ -f "$file" ] && process_file "$file"
done

# Server-side procedures
echo "-- =================================================================" >> "$OUTPUT_FILE"
echo "-- SERVER-SIDE PROCEDURES" >> "$OUTPUT_FILE"
echo "-- =================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for file in "$PROJECT_ROOT"/sql/storeproc/server-side/*.sql; do
    [ -f "$file" ] && process_file "$file"
done

echo "✅ Combined into: $OUTPUT_FILE"
echo "🚀 Deploy: psql \"\$DATABASE_URL\" -f sql/all_stored_procedures.sql"