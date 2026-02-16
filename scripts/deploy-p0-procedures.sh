#!/bin/bash

# Deploy P0 Stored Procedures to Supabase
# Uses Supabase CLI to deploy UPDATED existing files with P0 features

set -e

echo "🚀 Deploying P0 Stored Procedures to Supabase"
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Install it with:"
    echo "   npm install -g supabase"
    exit 1
fi

# Check if linked to project
if [ ! -f ".supabase/config.toml" ]; then
    echo "⚠️  Project not linked to Supabase."
    echo "   Run: supabase link --project-ref mzgusshseqxrdrkvamrg"
    echo ""
    read -p "Link now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        supabase link --project-ref mzgusshseqxrdrkvamrg
    else
        exit 1
    fi
fi

echo "📄 Deploying updated stored procedures..."
echo ""

# Deploy the two updated files that contain P0 features
echo "1. Deploying 02_card_management.sql (includes get_card_with_content)..."
supabase db execute --file sql/storeproc/client-side/02_card_management.sql

echo "2. Deploying 03_content_management.sql (includes bulk operations)..."
supabase db execute --file sql/storeproc/client-side/03_content_management.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully deployed P0 stored procedures:"
    echo "   From 02_card_management.sql:"
    echo "     • get_card_with_content()"
    echo ""
    echo "   From 03_content_management.sql:"
    echo "     • bulk_create_content_items()"
    echo "     • bulk_delete_content_items()"
    echo ""
    echo "🎉 P0 features are now ready to use!"
else
    echo ""
    echo "❌ Deployment failed. Check the error above."
    exit 1
fi
