# Official Supabase MCP Setup for Cardy CMS

## Quick Setup Steps

### 1. Create Personal Access Token
1. Go to: https://supabase.com/dashboard/account/tokens
2. Click "Generate new token"
3. Name: "Claude MCP Server"
4. Copy the token immediately!

### 2. Configure Claude Desktop
1. Open Claude Desktop
2. Go to Settings → Developer tab
3. Click "Edit Config"
4. Add this configuration:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--read-only",
        "--project-ref=mzgusshseqxrdrkvamrg"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "YOUR_TOKEN_HERE"
      }
    }
  }
}
```

5. Replace `YOUR_TOKEN_HERE` with your personal access token
6. Save the file
7. Restart Claude Desktop

### 3. Verify Connection
Once configured, you should see:
- Green active status in Claude settings
- Access to Supabase tools in your conversations

## Available Features

The official Supabase MCP provides these tool groups:

### 🗄️ Database Tools
- Query tables
- View schemas
- Execute SQL (read-only by default)
- Inspect relationships

### 📚 Documentation Tools
- Access Supabase docs
- Get API references
- View examples

### ⚡ Edge Functions
- List functions
- View function details
- Check logs

### 💾 Storage
- List buckets
- View storage policies
- Check file metadata

### 🔧 Development Tools
- Database migrations
- Type generation
- Schema introspection

## Configuration Options

### Enable All Features (Advanced)
```json
{
  "args": [
    "-y",
    "@supabase/mcp-server-supabase@latest",
    "--project-ref=mzgusshseqxrdrkvamrg",
    "--features=account,docs,database,debug,development,functions,storage,branching"
  ]
}
```

### Enable Write Access (Caution!)
Remove the `--read-only` flag to allow write operations:
```json
{
  "args": [
    "-y",
    "@supabase/mcp-server-supabase@latest",
    "--project-ref=mzgusshseqxrdrkvamrg"
  ]
}
```

## Troubleshooting

### Token Issues
- Ensure token is valid and not expired
- Check token has necessary permissions
- Try generating a new token

### Connection Failed
- Verify Node.js is installed: `node --version`
- Check internet connectivity
- Ensure project reference is correct

### No Tools Available
- Restart Claude Desktop after configuration
- Check MCP status in Claude settings
- Verify JSON syntax is correct

## Security Notes

⚠️ **Important Security Considerations:**
- Keep your personal access token secure
- Use `--read-only` flag by default
- Be cautious with write access
- Rotate tokens regularly
- Never commit tokens to git

## Benefits for Cardy CMS

With Supabase MCP connected, you can:
- ✅ Query card statistics directly
- ✅ Inspect database schemas
- ✅ Debug stored procedures
- ✅ View Edge Function logs
- ✅ Analyze user data patterns
- ✅ Generate TypeScript types
- ✅ Access Supabase documentation

## Example Usage

Once connected, you can ask Claude:
- "Show me the schema for the cards table"
- "How many active card batches are there?"
- "List all Edge Functions in my project"
- "Show recent errors from Edge Function logs"
- "Generate TypeScript types for my database"

## Image

![Oceans: The Blue Frontier](https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80)