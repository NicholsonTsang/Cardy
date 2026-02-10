# FunTell MCP Server — Creator Usage Guide

## What is the FunTell MCP Server?

The FunTell MCP (Model Context Protocol) server lets you manage your FunTell projects using AI assistants like Claude, ChatGPT, or Gemini. FunTell turns any information into an AI-powered, multilingual content experience — whether that is a product catalog, museum exhibit, online course, knowledge base, restaurant menu, portfolio, or anything else. Instead of clicking through the dashboard, you describe what you want and the AI handles it — creating projects, adding content, configuring AI assistants, and setting up distribution via QR codes, links, or embeds.

## Getting Started

### 1. Install the FunTell Plugin (Claude Code)

The FunTell plugin bundles both the MCP server connection and workflow guidance.

**Local testing:**
```bash
claude --plugin-dir /path/to/funtell-plugin
```

**After marketplace publication:**
```
/plugin install funtell
```

### 2. Manual MCP Setup (Any LLM)

If not using the plugin, configure the MCP server connection directly.

**Claude Code / Claude Desktop:**

Add to `.mcp.json`:
```json
{
  "mcpServers": {
    "funtell": {
      "type": "http",
      "url": "https://funtell-mcp-xxxxx.run.app/mcp"
    }
  }
}
```

**OpenAI Agents SDK (Python):**
```python
from agents import Agent
from agents.mcp import MCPServerStreamableHttp

mcp = MCPServerStreamableHttp(url="https://funtell-mcp-xxxxx.run.app/mcp")
agent = Agent(name="FunTell Assistant", mcp_servers=[mcp])
```

**Google Gemini SDK (Python):**
```python
from google.genai.types import McpTool, McpToolStreamableHttp

mcp_tool = McpTool(
    streamable_http=McpToolStreamableHttp(
        url="https://funtell-mcp-xxxxx.run.app/mcp"
    )
)
```

### 3. Authenticate

Every session starts with login. Tell your AI:

> "Log in to FunTell with email: my@email.com and password: mypassword"

The AI calls the `login` tool with your FunTell platform credentials. All subsequent actions use your account.

## Available Tools (22)

### Account
| Tool | What it does |
|------|-------------|
| `login` | Authenticate with your FunTell email and password |
| `get_workflow` | Get the full project creation workflow guide |
| `get_subscription` | Check your tier (Free/Starter/Premium), limits, and features |
| `get_credit_balance` | View remaining credits and usage |

### Projects
| Tool | What it does |
|------|-------------|
| `list_projects` | See all your projects with stats |
| `get_project` | Get full details for one project |
| `create_project` | Create a new project |
| `update_project` | Change project settings |
| `delete_project` | Permanently remove a project |

### Content
| Tool | What it does |
|------|-------------|
| `list_content_items` | View all content in a project |
| `create_content_item` | Add a single item |
| `create_content_items_batch` | Add many items at once (recommended) |
| `update_content_item` | Edit an item's name or description |
| `delete_content_item` | Remove an item (cascades for categories) |
| `reorder_content_item` | Change display order |
| `move_content_item` | Move item between categories |

### AI Configuration
| Tool | What it does |
|------|-------------|
| `generate_ai_settings` | Auto-create AI persona from your content |
| `optimize_description` | Polish a description with AI |

### QR Codes
| Tool | What it does |
|------|-------------|
| `list_access_tokens` | See all QR codes and their stats |
| `create_access_token` | Create a new QR code |
| `update_access_token` | Enable/disable or set session limits |
| `delete_access_token` | Remove a QR code |

## Workflow Examples

### Example 1: Create a Museum Project

```
You: Create a museum project called "City Art Museum" with 3 exhibition wings:
     - Modern Art (5 pieces with descriptions)
     - Classical Gallery (4 pieces)
     - Sculpture Garden (3 pieces)
     Enable AI assistant.
```

The AI will:
1. Call `create_project` with `content_mode: "list"`, `is_grouped: true`
2. Call `create_content_items_batch` with 3 categories and 12 items
3. Call `generate_ai_settings` to create an AI persona
4. Call `update_project` to enable AI with the generated settings
5. Remind you to upload images and add translations via the web portal

### Example 2: Set Up a Restaurant Menu

```
You: Create a restaurant menu for "Bella Italia" with:
     Antipasti: Bruschetta, Caprese Salad, Arancini
     Pasta: Carbonara, Pesto Linguine, Bolognese
     Dolci: Tiramisu, Panna Cotta
     Include prices and descriptions. Enable AI in Italian.
```

### Example 3: Update Existing Content

```
You: List my projects and show me the content of "City Art Museum".
     Then update the Mona Lisa description to include its history
     and add a new item "Water Lilies" to the Modern Art wing.
```

### Example 4: Manage QR Codes

```
You: Create separate QR codes for "Bella Italia":
     one for "Main Entrance" and one for "Terrace".
     Set the terrace QR to max 100 sessions per day.
```

### Example 5: Build a Product Catalog

```
You: Create a product catalog for "Alpine Gear Co." with categories:
     - Jackets (3 products with descriptions and prices)
     - Backpacks (4 products)
     - Accessories (5 products)
     Use grid mode so products display visually. Enable AI assistant
     so customers can ask questions about sizing and materials.
```

The AI will:
1. Call `create_project` with `content_mode: "grid"`, `is_grouped: true`
2. Call `create_content_items_batch` with 3 categories and 12 items
3. Call `generate_ai_settings` to create a product-expert AI persona
4. Call `update_project` to enable AI with the generated settings
5. Remind you to upload product images and add translations via the web portal

### Example 6: Create an Online Course

```
You: Set up an online course called "Introduction to Photography" with modules:
     - Camera Basics (4 lessons)
     - Composition (3 lessons)
     - Lighting (3 lessons)
     - Post-Processing (2 lessons)
     Each lesson should have a detailed description. Enable AI so students
     can ask follow-up questions about any lesson.
```

## Content Modes

Choose based on how visitors will browse your content:

| Mode | Best for | Example |
|------|----------|---------|
| `single` | One featured article | Blog post, announcement, company profile |
| `list` | Scrollable list of items | Restaurant menu, course modules, knowledge base, resource links |
| `grid` | 2-column visual layout | Product catalog, photo gallery, team directory, portfolio |
| `cards` | Full-width featured items | News feed, exhibition highlights, featured stories |

### Grouping

- **Grouped** (`is_grouped: true`): Items organized into named categories. Use for multi-section content like museum wings, menu courses, product categories, or course modules.
- **Non-grouped** (`is_grouped: false`): Flat list of items. Use for simple collections like link-in-bio, single articles, or flat resource lists.

## Subscription Tiers

| Feature | Free | Starter ($40/mo) | Premium ($280/mo) |
|---------|------|-------------------|-------------------|
| Projects | 3 | 5 | 35 |
| Sessions | 50/month | $40 budget | $280 budget |
| AI Assistant | Yes | Yes | Yes |

## Tips

- **Write detailed descriptions** — they directly improve the AI assistant's quality. Include context, history, fun facts.
- **Use batch creation** — `create_content_items_batch` is faster and more reliable than creating items one by one.
- **Generate AI settings after content** — the AI persona is generated from your content, so add everything first.
- **Use `optimize_description`** — let AI polish your descriptions before saving.
- **Check subscription first** — call `get_subscription` to know your limits before creating projects.
- **After setup** — upload images and add translations via the FunTell web portal.
