## Set Up Projects with AI Assistants

Already have your content in a PDF or Word document? Just share it with an AI assistant and it creates the entire project for you — extracting text, images, and structure automatically. You can also describe what you want through conversation if you don't have a document ready.

FunTell connects to AI assistants through **MCP** (Model Context Protocol), an open standard supported by many popular AI tools. You can also use the **FunTell Plugin** for Claude Code, which adds document import support for PDF and Word files with embedded images.

---

## Supported AI Tools

| AI Tool | How to Connect |
|---------|---------------|
| **Claude Desktop** | Settings → Developer → Edit Config |
| **ChatGPT Desktop** | Settings → MCP Servers |
| **Claude Code** | Edit `.mcp.json` or `~/.claude.json` |
| **Cursor** | Settings → MCP → Add new MCP server |
| **Windsurf** | Settings → MCP → Add Server |

---

## Connect Your AI Tool

### Step 1: Open MCP Settings

Open your AI tool and find the MCP server settings. Each tool is slightly different:

**Claude Desktop:**
1. Open Claude Desktop
2. Go to **Settings** (gear icon)
3. Click **Developer** → **Edit Config**

**ChatGPT Desktop:**
1. Open ChatGPT Desktop
2. Go to **Settings** → **MCP Servers**
3. Add a new server

**Cursor / Windsurf:**
1. Open your editor
2. Go to **Settings** → **MCP**
3. Click **Add Server**

### Step 2: Add the FunTell Server

Add this configuration. The JSON format works for Claude Desktop and Claude Code. For Cursor and Windsurf, use their UI to enter the same information.

**Server URL:**
```
https://funtell-mcp-623144682535.asia-northeast1.run.app/mcp
```

**JSON configuration** (for Claude Desktop / Claude Code):
```json
{
  "mcpServers": {
    "funtell": {
      "type": "http",
      "url": "https://funtell-mcp-623144682535.asia-northeast1.run.app/mcp"
    }
  }
}
```

- **Claude Desktop** — paste into `claude_desktop_config.json`
- **Claude Code** — paste into `.mcp.json` in your project folder, or `~/.claude.json` for global access

**Cursor / Windsurf** — enter in the UI:
- **Name:** `funtell`
- **Type:** HTTP
- **URL:** `https://funtell-mcp-623144682535.asia-northeast1.run.app/mcp`

### Step 3: Restart and Verify

1. **Restart** your AI tool (or refresh the MCP connection)
2. Try asking: *"Log in to FunTell"* — the AI should prompt you for your email and password

:::warning Security Note
Your credentials are sent directly to the FunTell API over HTTPS. They are never stored by your AI tool.
:::

---

## FunTell Plugin for Claude Code

If you use **Claude Code** (terminal), the FunTell Plugin gives you extra features on top of MCP:

- **Workflow guidance** — teaches Claude the optimal project creation sequence
- **Document import** — import PDF and Word files (.pdf, .docx, .doc) with embedded images automatically extracted

### Install

```bash
claude --plugin-dir /path/to/funtell-plugin
```

### Use

Import a document:

```
/funtell:manage import restaurant_menu.pdf
```

Or describe what you want — Claude will use the skill automatically:

```
Set up a restaurant menu with appetizers, mains, and desserts
```

---

## Two Ways to Create a Project

### From a Document (PDF / Word) — Recommended

The fastest way to get started. Upload or share a PDF or Word file with the AI — it extracts the text and structure, then creates the project for you. If you use the **Claude Code Plugin**, embedded images are also extracted automatically.

**Supported formats:** `.pdf`, `.docx`, `.doc`

### Through Conversation

Don't have a document? Just describe your project idea and the AI builds it step by step — recommending the best layout, organizing your content into categories, and setting up the AI assistant.

---

## Choose Your Content Layout

Before creating, decide which layout fits your content:

| Layout | Best For |
|--------|----------|
| **List** | Restaurant menus, course modules, FAQ, knowledge bases |
| **Grid** | Product catalogs, photo galleries, team directories |
| **Cards** | News, exhibition highlights, featured products |
| **Single** | Articles, announcements, company profiles |

**Grouping** — organize items into named sections (e.g., "Appetizers", "Main Course", "Desserts") or keep them as a flat list.

| Use Case | Layout | Grouped? |
|----------|--------|----------|
| Restaurant menu | List | Yes (by course) |
| Museum / gallery | List or Cards | Yes (by wing/floor) |
| Product catalog | Grid | Yes (by type) |
| Online course | List | Yes (by module) |
| Knowledge base / FAQ | List | Yes (by topic) |
| Portfolio / showcase | Grid | No |
| Event / conference | Cards | No |
| Link-in-bio | List | No |
| Article / blog post | Single | No |

---

## Prompt Templates

### From a Document

Already have your content in a file? Use this template:

```
Log in to FunTell with email: YOUR_EMAIL and password: YOUR_PASSWORD

Import the attached document and create a FunTell project.
Name it "YOUR PROJECT NAME".
Use [list / grid / cards / single] mode, [with grouped categories / without grouping].
Language: [English / Chinese / Japanese / etc.]

Generate AI settings and enable the AI assistant.
The AI should act as a [describe the role: friendly guide / product advisor / support agent / etc.].
Create QR codes for [location names, e.g. "Table 1", "Main Entrance"].
```

:::info How It Works
Share your PDF or Word file alongside this prompt. The AI reads your document, extracts the content and structure (and images if using Claude Code Plugin), then builds the project automatically.
:::

### Through Conversation

No document? Describe your content directly:

```
Log in to FunTell with email: YOUR_EMAIL and password: YOUR_PASSWORD

Create a FunTell project called "YOUR PROJECT NAME".
Use [list / grid / cards / single] mode, [with grouped categories / without grouping].
Language: [English / Chinese / Japanese / etc.]

[Category Name 1]:
- [Item Name] — [Description with details, price, specs, etc.]
- [Item Name] — [Description]

[Category Name 2]:
- [Item Name] — [Description]
- [Item Name] — [Description]

[Add more categories and items as needed]

Generate AI settings and enable the AI assistant.
The AI should act as a [describe the role: friendly guide / product advisor / support agent / etc.].
Create QR codes for [location names, e.g. "Table 1", "Main Entrance"].
```

:::info What to Fill In
- **Project name** — your business, brand, or product name
- **Layout mode** — pick from the layout table above (list, grid, cards, or single)
- **Categories** — your section names (e.g., "Starters", "Main Course" for a restaurant)
- **Items** — each item with a name and detailed description. The more detail you provide, the better the AI assistant works for your visitors.
- **AI role** — what persona the assistant should have
- **QR codes** — how many and where they'll be placed
:::

:::tip Tips for Better Results
- **Be detailed** — Include names, descriptions, prices, and specs. The more you provide, the better the AI assistant works for your visitors.
- **Mention the layout** — Tell the AI which layout to use (list, grid, cards, single) and whether to group items into categories.
- **Describe the AI persona** — Say what role the assistant should play, like "friendly waiter" or "product advisor".
- **Ask for QR codes** — Specify how many and what to name them (e.g., "Table 1", "Main Entrance").
:::

:::tip You Can Always Edit Later
The AI creates a working first version quickly. Then refine in the **FunTell dashboard**:
- **Upload images** for each item
- **Edit descriptions** to add more detail
- **Add translations** for international visitors
- **Test the AI** by scanning a QR code and chatting with the assistant
:::
