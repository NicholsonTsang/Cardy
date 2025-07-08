# Supabase MCP Setup for Claude Code

## Quick Setup (Local Scope)

### 1. Get Your Personal Access Token
1. Go to: https://supabase.com/dashboard/account/tokens
2. Click "Generate new token"
3. Name it: "Claude Code MCP"
4. Copy the token immediately!

### 2. Add Supabase MCP Server

Run this command in your terminal:

```bash
claude mcp add supabase npx -- -y @supabase/mcp-server-supabase@latest --read-only --project-ref=mzgusshseqxrdrkvamrg -e SUPABASE_ACCESS_TOKEN=YOUR_TOKEN_HERE
```

Replace `YOUR_TOKEN_HERE` with your actual token.

## Project-Wide Setup (Recommended)

### 1. Create Project Configuration

Create a `.mcp.json` file in your project root:

```bash
claude mcp add --scope project supabase npx -- -y @supabase/mcp-server-supabase@latest --read-only --project-ref=mzgusshseqxrdrkvamrg
```

### 2. Set Environment Variable

Add to your `.env` file:
```bash
SUPABASE_ACCESS_TOKEN=your_personal_access_token_here
```

Or export it in your shell:
```bash
export SUPABASE_ACCESS_TOKEN=your_personal_access_token_here
```

## Alternative: Manual Configuration

Create `.mcp.json` in your project root:

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
        "SUPABASE_ACCESS_TOKEN": "${SUPABASE_ACCESS_TOKEN}"
      }
    }
  }
}
```

## Verify Installation

```bash
# List configured MCP servers
claude mcp list

# Test the connection
claude mcp test supabase
```

## Available Commands

Once configured, you can use Supabase tools in Claude Code:

### Database Operations
```bash
# Query your database
claude "Show me all cards in the database"

# Get table schema
claude "What's the schema for the card_batches table?"

# Check statistics
claude "How many active cards are there?"
```

### Edge Functions
```bash
# List Edge Functions
claude "List all my Edge Functions"

# Check function logs
claude "Show logs for create-checkout-session function"
```

## Configuration Options

### Enable Write Access (Use with Caution!)
Remove the `--read-only` flag:
```bash
claude mcp add supabase npx -- -y @supabase/mcp-server-supabase@latest --project-ref=mzgusshseqxrdrkvamrg -e SUPABASE_ACCESS_TOKEN=YOUR_TOKEN
```

### Enable Specific Features
```bash
claude mcp add supabase npx -- -y @supabase/mcp-server-supabase@latest --project-ref=mzgusshseqxrdrkvamrg --features=database,functions,storage -e SUPABASE_ACCESS_TOKEN=YOUR_TOKEN
```

Available features: `account`, `docs`, `database`, `debug`, `development`, `functions`, `storage`, `branching`

## Remove MCP Server

If you need to remove the configuration:
```bash
claude mcp remove supabase
```

## Troubleshooting

### "No MCP servers configured"
- Run the add command above
- Check if `.mcp.json` exists in your project
- Verify token is set correctly

### Connection Issues
- Ensure Node.js is installed: `node --version`
- Check your internet connection
- Verify your personal access token is valid

### Permission Errors
- Make sure you're using a valid personal access token
- Check the token hasn't expired
- Try generating a new token

## Security Notes

⚠️ **Important**:
- Never commit your personal access token to git
- Add `.env` to `.gitignore` if using environment variables
- Use `--read-only` flag by default for safety
- Consider using project scope for team collaboration
- Rotate tokens regularly

## Benefits for Cardy CMS Development

With Supabase MCP in Claude Code, you can:
- Query database directly while coding
- Debug stored procedures
- Check Edge Function logs
- Generate TypeScript types
- Analyze user data
- Test SQL queries
- View real-time statistics

All without leaving your terminal!