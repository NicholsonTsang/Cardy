# FunTell Plugin for Claude Code

A Claude Code plugin that connects to the FunTell MCP server and guides AI through turning any information into AI-powered, multilingual content experiences. Create and manage projects for products, venues, education, knowledge bases, portfolios, and more.

## What's included

- **MCP server connection** (`.mcp.json`) — auto-connects Claude to the FunTell MCP tools
- **Workflow skill** (`/funtell:manage`) — teaches Claude the optimal project creation sequence, including document import with images (.pdf, .doc, .docx)

## Installation

### Option 1: Plugin (recommended)

```bash
claude --plugin-dir /path/to/funtell-plugin
```

This auto-registers both the MCP server and the workflow skill.

### Option 2: Marketplace

Once published to a marketplace:

```
/plugin install funtell
```

## Usage

Claude automatically uses the workflow when you ask it to create or manage projects:

```
Set up a restaurant menu with appetizers, mains, and desserts
```

```
Create a product catalog for my outdoor gear store with 4 categories
```

Or invoke the skill directly:

```
/funtell:manage create a museum project for the City Art Gallery with 3 exhibition wings
```

```
/funtell:manage set up an online course with 5 modules on web development
```

For documents with images (PDF/Word), the skill automatically uses a local script to extract text + images into a project archive ZIP:

```
/funtell:manage import museum_guide.pdf
```

```
/funtell:manage import restaurant_menu.docx
```

```
/funtell:manage import product_catalog.doc
```

## Plugin structure

```
funtell-plugin/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── .mcp.json                 # MCP server connection config
├── skills/
│   └── manage/
│       ├── SKILL.md          # Workflow guide (loaded by Claude)
│       ├── reference.md      # Full tool parameter reference
│       └── scripts/
│           ├── doc-to-archive.py    # PDF/DOC/DOCX → archive converter
│           ├── format-reference.md  # Archive format specs
│           └── requirements-doc.txt # Python dependencies
└── README.md
```

## Configuration

The bundled `.mcp.json` points to the production FunTell MCP server. To use a local server during development, update the URL:

```json
{
  "mcpServers": {
    "funtell": {
      "type": "http",
      "url": "http://localhost:3001/mcp"
    }
  }
}
```
