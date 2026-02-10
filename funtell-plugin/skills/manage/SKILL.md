---
name: manage
description: Create and manage FunTell content experience projects. Turn any information — products, venues, courses, knowledge bases, portfolios, and more — into AI-powered experiences with AI assistants and distribution via QR codes, links, or embeds. Supports PDF/DOCX/website import with images.
argument-hint: "[action] e.g. create museum project, list my projects, import menu.pdf, scrape website"
allowed-tools: Bash(python *)
---

# FunTell Project Management

You have access to the FunTell MCP server tools. Use them to turn any information into AI-powered content experiences. Projects can cover products, venues (museums, restaurants, events), education (courses, tutorials), knowledge bases, portfolios, storytelling, print materials, and more. Audiences access content via QR codes, direct links, or embeds.

## Authentication

**Always start by calling `login`** with the creator's FunTell platform credentials (email + password). All other tools require authentication.

After login, optionally call `get_subscription` to check the creator's tier and limits:
- **Free**: 3 projects, 50 sessions/month, no translations
- **Starter**: 5 projects, $40 session budget, max 2 translation languages
- **Premium**: 35 projects, $280 session budget, unlimited translations

## Four Creation Modes

Choose the mode based on the user's input.

### Mode A: Document with images (PDF/Word → archive ZIP)

**Use when:** The user uploads a PDF or Word document (.docx) that contains **embedded images** they want included in their project.

MCP tools cannot handle images. This mode runs a local script to extract text + images into a ZIP archive, which the user imports via the web portal.

**Steps:**

1. Check dependencies are installed:
   ```bash
   python3 -c "import fitz; import docx" 2>/dev/null || pip3 install -r funtell-plugin/skills/manage/scripts/requirements-doc.txt
   ```

2. Determine the best options from the document content:
   - `--name`: Project name (ask user or infer from document title)
   - `--mode`: `list` / `grid` / `cards` / `single` (use Content Mode Decision Guide below)
   - `-g`: Add if document has clear sections/categories
   - `--language`: Detect from document text (default: `en`)

3. Run the script:
   ```bash
   python3 funtell-plugin/skills/manage/scripts/doc-to-archive.py <file_path> --name "Project Name" --mode list -g
   ```

4. Check the summary output. If category/item count looks wrong, unzip, edit `project.json`, re-zip.

5. Tell the user:
   > Your archive is ready at `{output_path}`. To import:
   > 1. Open the FunTell web portal
   > 2. Go to **Dashboard > Import**
   > 3. Upload the ZIP file
   > 4. Review and confirm the import

6. After import, the user can configure AI settings via the web portal or ask you to use `generate_ai_settings` + `update_project` MCP tools.

For archive format details, see [scripts/format-reference.md](scripts/format-reference.md).

### Mode B: Website scraping (URL → archive ZIP)

**Use when:** The user provides a website URL and wants to convert web content into a FunTell project.

This mode scrapes website content (text + images), follows internal links, and generates a ZIP archive for import via the web portal.

**Steps:**

1. Check dependencies are installed:
   ```bash
   python3 -c "import bs4; import requests; import PIL" 2>/dev/null || pip3 install -r funtell-plugin/skills/manage/scripts/requirements-web.txt
   ```

2. Ask the user for scraping parameters:
   - **Starting URL**: The website to scrape
   - **Max depth** (default: 1, range: 1-3): How many levels of links to follow
   - **Max pages** (default: 20, range: 1-100): Maximum number of pages to scrape
   - **Same domain only** (default: yes): Restrict scraping to the same domain
   - **Delay** (default: 1.0s): Time between requests (minimum 1 second for rate limiting)

3. Determine the best options:
   - `--name`: Project name (infer from page title or domain if not provided)
   - `--mode`: `list` / `grid` / `cards` / `single` (use Content Mode Decision Guide below)
   - `-g`: Add if website has clear sections/categories
   - `--language`: Detect from content (default: `en`)

4. Run the script:
   ```bash
   python3 funtell-plugin/skills/manage/scripts/web-to-archive.py <url> \
     --name "Project Name" \
     --mode list \
     -g \
     --max-depth 2 \
     --max-pages 20 \
     --delay 1.0
   ```

5. Check the summary output for:
   - Pages scraped vs. skipped
   - Images downloaded
   - Warnings (robots.txt blocks, failed images, etc.)

6. Tell the user:
   > Your archive is ready at `{output_path}`. To import:
   > 1. Open the FunTell web portal
   > 2. Go to **Dashboard > Import**
   > 3. Upload the ZIP file
   > 4. Review and confirm the import

7. After import, the user can configure AI settings via the web portal or ask you to use `generate_ai_settings` + `update_project` MCP tools.

**Best Practices:**
- **Start small**: Begin with max-depth 1 and 10-20 pages to preview structure
- **Respect robots.txt**: Script automatically checks and obeys robots.txt rules
- **Rate limiting**: Always use delay ≥ 1.0 seconds to avoid overloading servers
- **Preview first**: For large sites, scrape a subset first to verify structure

**Limitations:**
- No JavaScript rendering (static HTML only)
- No authentication (public pages only)
- Social media platforms are blocked (Twitter, Facebook, Instagram, etc.)
- Respects robots.txt — if blocked, the script will exit with an error

**Common use cases:**
- Convert blog posts into mobile experiences
- Create product catalogs from e-commerce pages
- Build knowledge bases from documentation sites
- Turn event/venue websites into interactive guides

For archive format details, see [scripts/format-reference.md](scripts/format-reference.md).

### Mode C: Document without images (text-only → MCP tools)

**Use when:** The user uploads a PDF, Word doc, or other file and **doesn't need images** included, or the document has no meaningful images.

This mode is faster — it creates the project directly via MCP tools with no manual import step.

**Steps:**
1. Read and extract all text content from the document.
2. Identify structure — sections, headings, chapters, categories, items.
3. Automatically determine settings (content_mode, is_grouped, categories, original_language).
4. Create project and content via MCP tools (see Project Setup Sequence below).
5. Generate AI settings and enable AI.
6. Present summary. Remind user to upload images and add translations via the web portal.

**Key principles:**
- Maximize automation — make all decisions based on the document content.
- Write rich, detailed descriptions for each item (directly impacts AI quality).
- Use `optimize_description` to polish rough descriptions.
- Present your decisions and ask for confirmation if the structure is ambiguous.

### Mode D: Consultative (interactive Q&A)

**Use when:** The user describes what they want without providing source material.

**Question flow:**
1. **Purpose**: "What is this project about?" — Understand the use case.
2. **Content mode**: Recommend a content_mode and is_grouped setting with reasoning, but present alternatives. Example: "I recommend **list mode with grouped categories** for your restaurant menu. Alternatively, **grid mode** works well if you have photos for every dish. Which do you prefer?"
3. **Structure**: Suggest category names, let user confirm or adjust.
4. **Content items**: Gather names and descriptions, or offer to generate from brief notes.
5. **Confirm** all settings before creating.
6. Create everything via MCP tools (see Project Setup Sequence below).

**Key principles:**
- Present recommendations with reasoning, but let the user decide.
- Never silently decide project settings.
- Ask focused, one-topic-at-a-time questions.

If unclear which mode the user prefers, ask: "Would you like to upload a document, or shall I walk you through setting up the project step by step?"

## Content Mode Decision Guide

| Use Case | Recommended Mode | Grouped? | Example Categories |
|----------|-----------------|----------|--------------------|
| Museum | `list` or `cards` | Yes | Wings, Floors, Exhibitions |
| Restaurant | `list` | Yes | Appetizers, Mains, Desserts, Drinks |
| Hotel | `list` | Yes | Amenities, Dining, Activities |
| Event | `cards` | No | Single "default" category |
| Product catalog | `grid` | Yes | Product categories |
| Online course | `list` | Yes | Modules, Units, Chapters |
| Knowledge base | `list` | Yes | Topics, Departments, FAQ sections |
| Portfolio | `grid` | No | Single "default" category |
| Article/Blog | `single` | No | Single "default" category |
| Link-in-bio | `list` | No | Single "default" category |

## Project Setup Sequence (for Modes C and D)

### 1. Create the project

Call `create_project` with name, content_mode, is_grouped, original_language, billing_type.
Leave `conversation_ai_enabled: false` — enable after AI setup.

### 2. Add content

Call `create_content_items_batch` with categories and items:
- **Non-grouped** (`is_grouped: false`): Single category named `"default"`
- **Grouped** (`is_grouped: true`): Multiple named categories

Each item needs: `name`, `description` (detailed markdown), optional `ai_knowledge_base` (max 500 words).

#### Markdown Formatting Rules

Content renders on a mobile dark-background UI:

**Use:** paragraphs, **bold**, *italic*, `###`/`####` headings, bullet lists, numbered lists, `[links](url)`, `> blockquotes`, `---` rules

**Do NOT use:** tables, code blocks, HTML tags, h1/h2 headings, nested lists beyond 2 levels

**Rules:**
- Do NOT start with the item name (already displayed as title)
- Short paragraphs (2-4 sentences) for mobile readability
- **Bold** for key terms, prices, highlights
- Bullet lists for structured info (specs, features, hours)
- For tabular data, use labeled bullets instead of tables

### 3. Generate AI settings

Call `generate_ai_settings` with project ID and name. Returns ai_instruction, ai_knowledge_base, ai_welcome_general, ai_welcome_item.

### 4. Enable AI assistant

Call `update_project` with all four AI settings + `conversation_ai_enabled: true`.

### 5. Verify content

`list_content_items` to review, then adjust with `reorder_content_item`, `move_content_item`, `update_content_item`, `delete_content_item`.

### 6. Manage distribution

Default QR code is auto-created. Use `list_access_tokens`, `create_access_token`, `update_access_token`, `delete_access_token`.

### 7. Remind user about remaining tasks

- **Upload images** (if not already included via Mode A)
- **Add translations** if multilingual content is needed (supports: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th)

For detailed tool parameters, see [reference.md](reference.md).

## Ongoing Management

- `list_projects` — overview of all projects with stats
- `get_project` — full project details
- `get_credit_balance` — monitor remaining credits
- `optimize_description` — AI-polish any description

## Tips

- **Description quality matters**: Detailed descriptions directly improve AI assistant responses.
- **Batch creation is preferred**: Use `create_content_items_batch` over individual calls.
- **Check subscription first**: Session limits depend on the creator's tier.
- **Supported languages**: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th
