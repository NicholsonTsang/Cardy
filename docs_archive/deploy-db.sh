#!/bin/bash

# Deploy all database objects

if [ -z "$DATABASE_URL" ]; then
    echo "Set DATABASE_URL first"
    exit 1
fi

# Optional: Drop all functions first (use --clean flag)
if [ "$1" = "--clean" ]; then
    echo "Dropping all functions first..."
    psql "$DATABASE_URL" -f sql/drop_all_functions.sql
fi

# Deploy in order
psql "$DATABASE_URL" -f sql/schema.sql
psql "$DATABASE_URL" -f sql/triggers.sql
psql "$DATABASE_URL" -f sql/policy.sql

# Option 1: Deploy from combined file (if exists)
if [ -f "sql/all_stored_procedures.sql" ]; then
    psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
else
    # Option 2: Deploy individual files
    for file in sql/storeproc/client-side/*.sql; do
        [ -f "$file" ] && psql "$DATABASE_URL" -f "$file"
    done
    for file in sql/storeproc/server-side/*.sql; do
        [ -f "$file" ] && psql "$DATABASE_URL" -f "$file"
    done
fi

echo "Done"