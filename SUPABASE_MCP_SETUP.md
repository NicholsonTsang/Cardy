# Supabase MCP Server Setup Guide

## Overview
The Supabase MCP (Model Context Protocol) Server provides enhanced database operations and management capabilities for Cardy CMS.

## Setup Steps

### 1. Get Supabase Service Role Key
1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/settings/api)
2. Copy the **service_role** key (starts with `eyJhbGciOiJIUzI1NiIsI...`)
3. **⚠️ IMPORTANT**: This key has elevated privileges - keep it secure!

### 2. Set Environment Variables
```bash
export SUPABASE_URL=https://mzgusshseqxrdrkvamrg.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

### 3. Run Setup Script
```bash
./setup-mcp.sh
```

### 4. Deploy Supporting Edge Function
```bash
supabase functions deploy exec-sql
```

## Available MCP Tools

### 🗄️ Database Operations
- **`query_database`** - Execute safe SQL queries
- **`get_table_schema`** - Inspect table structures
- **`list_functions`** - List stored procedures

### 🔧 Business Logic
- **`call_rpc`** - Execute stored procedures
- **`get_batch_stats`** - Get card batch analytics

### ⚡ Edge Functions
- **`manage_edge_functions`** - View and manage Edge Functions

## Usage Examples

### Query Database
```bash
claude mcp call supabase query_database '{
  "query": "SELECT COUNT(*) as total_cards FROM cards"
}'
```

### Get Batch Statistics
```bash
claude mcp call supabase get_batch_stats '{}'
```

### Call Stored Procedure
```bash
claude mcp call supabase call_rpc '{
  "function_name": "get_user_issuance_stats"
}'
```

### Get Table Schema
```bash
claude mcp call supabase get_table_schema '{
  "table_name": "card_batches"
}'
```

### List Available Functions
```bash
claude mcp call supabase list_functions '{
  "schema": "public"
}'
```

## Integration with Claude

Add to your Claude MCP configuration:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "node",
      "args": ["./mcp-server/supabase-mcp-server.js"],
      "env": {
        "SUPABASE_URL": "https://mzgusshseqxrdrkvamrg.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "your_service_role_key_here"
      }
    }
  }
}
```

## Security Notes

1. **Service Role Key**: Has full database access - never expose in client code
2. **SQL Safety**: Destructive operations are blocked by default
3. **Query Limits**: Large result sets may be truncated
4. **Environment**: Use different keys for development/production

## Troubleshooting

### Connection Issues
- Verify SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set
- Check network connectivity to Supabase
- Ensure service role key is valid

### Permission Errors
- Confirm you're using the service_role key, not anon key
- Check RLS policies if queries return empty results

### Function Errors
- Deploy the exec-sql Edge Function
- Verify stored procedure exists and has correct parameters
- Check Supabase function logs for detailed errors

## Benefits

✅ **Enhanced Database Access** - Direct SQL querying capabilities
✅ **Stored Procedure Management** - Easy RPC function execution  
✅ **Schema Introspection** - Understand database structure
✅ **Analytics & Monitoring** - Built-in batch statistics
✅ **Edge Function Management** - Monitor and manage serverless functions
✅ **Development Acceleration** - Rapid database operations during development