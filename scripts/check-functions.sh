#!/bin/bash

# Check if required functions exist in database

if [ -z "$DATABASE_URL" ]; then
    echo "❌ Set DATABASE_URL first"
    exit 1
fi

echo "Checking for required functions..."
echo ""

# Functions to check
FUNCTIONS=(
    "get_user_cards"
    "get_user_profile"
    "create_card"
    "update_card"
    "delete_card"
    "get_card_by_id"
    "issue_card_batch"
    "get_card_batches"
    "get_public_card_content"
)

# Check each function
for func in "${FUNCTIONS[@]}"; do
    result=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = '$func');" 2>/dev/null)
    
    if [[ $result == *"t"* ]]; then
        echo "✅ $func exists"
    else
        echo "❌ $func is MISSING"
    fi
done

echo ""
echo "To deploy missing functions, run:"
echo "./deploy-db.sh"