#!/bin/bash

echo "🚀 Setting up Supabase MCP Server for Cardy CMS..."

# Check if required environment variables are set
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo "❌ Missing required environment variables:"
    echo "   SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/settings/api"
    echo "2. Copy the 'service_role' key (starts with eyJhbGciOiJIUzI1NiIsI...)"
    echo "3. Export it: export SUPABASE_SERVICE_ROLE_KEY=your_key_here"
    echo "4. Export URL: export SUPABASE_URL=https://mzgusshseqxrdrkvamrg.supabase.co"
    exit 1
fi

# Make the script executable
chmod +x mcp-server/supabase-mcp-server.js

# Test the MCP server
echo "🔧 Testing MCP server connection..."
cd mcp-server && timeout 5s npm start 2>&1 | head -10
cd ..

echo ""
echo "✅ Supabase MCP Server setup complete!"
echo ""
echo "📋 Available MCP Tools:"
echo "   • query_database - Execute SQL queries"
echo "   • call_rpc - Call stored procedures"
echo "   • get_table_schema - Get table schema info"
echo "   • list_functions - List available functions"
echo "   • get_batch_stats - Get card batch statistics"
echo "   • manage_edge_functions - Manage Edge Functions"
echo ""
echo "🎯 Usage Examples:"
echo "   claude mcp call supabase call_rpc '{\"function_name\": \"get_user_issuance_stats\"}'"
echo "   claude mcp call supabase get_table_schema '{\"table_name\": \"cards\"}'"
echo "   claude mcp call supabase query_database '{\"query\": \"SELECT COUNT(*) FROM cards\"}'"
echo ""
echo "📚 Add to your Claude configuration:"
echo "   Edit ~/.config/claude/config.json and add the MCP server configuration"