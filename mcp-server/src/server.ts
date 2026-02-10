import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { authenticate, isAuthenticated } from "./supabase.js";
import { registerProjectTools } from "./tools/projects.js";
import { registerContentTools } from "./tools/content.js";
import { registerAccessTokenTools } from "./tools/access-tokens.js";
import { registerAIConfigTools } from "./tools/ai-config.js";
import { registerAccountTools } from "./tools/account.js";

// Server instructions — sent to every MCP client on initialize.
// This teaches any LLM (OpenAI, Gemini, Claude, etc.) the correct workflow
// without requiring platform-specific features like Claude Code Skills.
const SERVER_INSTRUCTIONS = `FunTell MCP Server — Turn any information into AI-powered, multilingual content experiences.

## Authentication
Always call \`login\` first with the creator's FunTell email and password. All other tools require authentication.

## Two Creation Modes

### Mode A: Document-based (user provides a file)
When the user provides a PDF, Word doc, spreadsheet, or other file:
1. Read and extract all text content and structure from the document.
2. Analyze the content and automatically determine the best settings:
   - **content_mode**: single/list/grid/cards based on content structure
   - **is_grouped**: true if the document has clear sections/chapters/categories
   - **Category names**: derived from document headings or sections
   - **original_language**: detected from the document text
3. Create the project and populate all content — no questions needed.
4. Generate AI settings and enable AI.
5. Present a summary of what was created and remind the user to add images and translations via the FunTell web portal.

### Mode B: Consultative (interactive Q&A)
When the user describes what they want without providing source material:
1. Ask what the project is about and its purpose (museum, restaurant, course, etc.).
2. Based on the answer, **recommend** a content_mode and is_grouped setting with clear reasoning, but present alternatives and let the user choose. Example: "I recommend **list mode with grouped categories** for your restaurant menu — this shows items organized by section (Appetizers, Mains, etc.). Alternatively, **grid mode** works well if you have photos for every dish. Which do you prefer?"
3. Ask about the content structure — suggest category names based on the use case, let the user confirm or adjust.
4. Ask about content items — gather names and descriptions.
5. Confirm all settings with the user before creating.
6. Create everything based on the confirmed answers.

**Key principle:** Always present your recommendation as the suggested option with reasoning, but give the user clear alternatives and let them make the final decision. Never silently decide project settings — the user should approve before creation.

Choose the mode based on whether the user provides source material or describes their need conversationally. If unclear, ask which approach they prefer.

## Project Setup Sequence
Both modes follow this tool sequence:
1. \`create_project\` — leave conversation_ai_enabled: false
2. \`create_content_items_batch\` — use "default" category for non-grouped
3. \`generate_ai_settings\` — analyzes content to create AI persona
4. \`update_project\` — apply AI settings + conversation_ai_enabled: true
5. \`list_content_items\` — verify and adjust
6. \`create_access_token\` — for additional QR codes/access points
7. Remind the user to complete the following in the FunTell web portal:
   - **Upload images** for content items
   - **Add translations** if multilingual content is needed

## Content Modes
- \`single\`: 1 featured item (article, announcement)
- \`list\`: vertical list (menus, resources, courses)
- \`grid\`: 2-column visual grid (products, galleries)
- \`cards\`: full-width cards (news, featured items)

## Markdown Formatting for Content Descriptions
Content renders on mobile (dark background). Write clean, scannable markdown:
- Do NOT start with the item name (already shown as the title)
- Use short paragraphs (2-4 sentences), **bold** for key terms, bullet lists for structured info
- Use ### or #### for subsections, > blockquotes for highlights, --- for section breaks
- Do NOT use tables (no mobile styling) — convert tabular data to bullet lists instead
- No code blocks, no HTML tags, no h1/h2 headings, max 2 nesting levels for lists

Use is_grouped: true for categorized content (museum wings, menu sections, product categories).

## Supported Languages
en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th

Call \`get_workflow\` anytime for the full detailed workflow guide.`;

// Full workflow text returned by the get_workflow tool — more detailed than instructions
const WORKFLOW_GUIDE = `# FunTell Project Management — Full Workflow Guide

## Authentication
Always start by calling \`login\` with the creator's FunTell platform credentials (email + password). All other tools require authentication.

After login, optionally call \`get_subscription\` to check the creator's tier and limits:
- Free: 3 projects, 50 sessions/month, no translations
- Starter: 5 projects, $40 session budget, max 2 translation languages
- Premium: 35 projects, $280 session budget, unlimited translations

## Two Creation Modes

Choose the creation mode based on whether the user provides source material or describes their need conversationally.

### Mode A: Document-based (user provides a file)

Best when the user uploads a PDF, Word doc, spreadsheet, or any structured source material.

**How it works:**
1. Read and extract all text content from the document.
2. Identify the document structure — sections, headings, chapters, categories, individual items.
3. Analyze the content and automatically determine:
   - **content_mode**: Use the Content Mode Decision Guide below
   - **is_grouped**: true if the document has clear sections/chapters/categories
   - **Category names**: derived from document headings, sections, or logical groupings
   - **original_language**: detected from the document text
4. Create the project with the determined settings.
5. Create all content items with detailed descriptions.
6. Generate AI settings and enable the AI assistant.
7. Present a summary of what was created.
8. **Remind the user** to upload images and add translations via the FunTell web portal.

**Key principles for document-based mode:**
- Maximize automation — make all decisions based on the document content.
- Write rich, detailed descriptions for each item (these directly impact AI quality).
- Use \`optimize_description\` to polish extracted descriptions if they're rough or brief.
- Present your decisions (content mode, grouping, categories) to the user and ask for confirmation before proceeding if the structure is ambiguous.

### Mode B: Consultative (interactive Q&A)

Best when the user describes what they want without providing source material, or when they need guidance on how to structure their content.

**Question flow:**
1. **Purpose**: "What is this project about?" — Understand the use case (museum, restaurant, course, product catalog, etc.)
2. **Content mode**: Based on the answer, **recommend** a content_mode and is_grouped setting with clear reasoning, but present alternatives and let the user choose. Example: "I recommend **list mode with grouped categories** for your restaurant menu — this shows items organized by section. Alternatively, **grid mode** works well if you have photos for every dish. Which do you prefer?"
3. **Structure**: "How should the content be organized?" — Suggest category names based on the use case, let the user confirm or adjust.
4. **Content items**: "What items should be in each category?" — Gather item names and ask for descriptions, or offer to generate descriptions based on brief notes.
5. **Confirm before creating**: Present a summary of all planned settings (content mode, grouping, categories) and ask for the user's approval before creating the project.
6. Create everything based on the confirmed answers.

**Key principles for consultative mode:**
- Always present your recommendation as the suggested option with clear reasoning, but give alternatives and let the user make the final decision.
- Never silently decide project settings — the user should approve content mode, grouping, and categories before creation.
- Ask focused, one-topic-at-a-time questions — don't overwhelm.
- Use the Content Mode Decision Guide to make smart suggestions.
- Offer to generate content descriptions from brief user input.

## Content Mode Decision Guide

Use this to determine the best content_mode and is_grouped setting:

| Content Pattern | Mode | Grouped? | Example |
|----------------|------|----------|---------|
| Multiple items with images that need visual browsing | grid | Depends | Product catalog, photo gallery, team directory |
| Long list of items organized by section | list | Yes | Restaurant menu, course modules, museum wings |
| Flat list of items without sections | list | No | Link-in-bio, resource list, flat FAQ |
| Featured items that each deserve full attention | cards | Depends | News feed, exhibition highlights, featured products |
| Single article, profile, or announcement | single | No | Blog post, company profile, event announcement |

**Decision logic:**
- If the content has images and visual comparison matters → \`grid\`
- If items are text-heavy and best read sequentially → \`list\`
- If each item is a standalone feature/story → \`cards\`
- If there's only one piece of content → \`single\`
- If there are clear sections/categories → \`is_grouped: true\`
- If items are flat/homogeneous → \`is_grouped: false\`

**Common use cases:**
| Use Case | Mode | Grouped? | Example Categories |
|----------|------|----------|--------------------|
| Museum | list or cards | Yes | Wings, Floors, Exhibitions |
| Restaurant | list | Yes | Appetizers, Mains, Desserts, Drinks |
| Hotel | list | Yes | Amenities, Dining, Activities |
| Event | cards | No | default |
| Product catalog | grid | Yes | Product categories |
| Online course | list | Yes | Modules, Units, Chapters |
| Knowledge base | list | Yes | Topics, Departments, FAQ sections |
| Portfolio | grid | No | default |
| Print materials | list or cards | Yes | Sections, Chapters |
| Article/Blog | single | No | default |
| Link-in-bio | list | No | default |

## Project Setup Sequence

Both creation modes follow this tool sequence:

### Step 1: Create the project
Call \`create_project\` with name, content_mode, is_grouped, original_language, billing_type.
Leave conversation_ai_enabled: false — enable after AI setup.

### Step 2: Add content
Call \`create_content_items_batch\` with categories and items:
- Non-grouped (is_grouped: false): Use a single category named "default"
- Grouped (is_grouped: true): Use named categories
Each item needs: name, description (detailed markdown), optional ai_knowledge_base (max 500 words).

**Markdown formatting rules for descriptions:**
Content renders on mobile with a dark background. Write clean, reader-friendly markdown:
- Do NOT start with the item name — it is already displayed as the title above the description.
- Use short paragraphs (2-4 sentences) for mobile readability.
- Use **bold** for key terms, names, prices, and highlights.
- Use bullet lists for structured info (specifications, features, ingredients, hours, prices).
- Use ### or #### for subsections within longer descriptions.
- Use > blockquotes for quotes, highlights, or special notes.
- Use --- to separate major sections in long descriptions.
- Separate all blocks with blank lines.
- Do NOT use tables — they have no mobile styling. Convert tabular data to labeled bullet lists:
  - **Hours:** 9:00 AM – 5:00 PM
  - **Price:** $25 adults, $15 children
- Do NOT use code blocks, HTML tags, h1/h2 headings, or deeply nested lists (max 2 levels).

### Step 3: Generate AI settings
Call \`generate_ai_settings\` with project ID and name. Returns: ai_instruction, ai_knowledge_base, ai_welcome_general, ai_welcome_item.

### Step 4: Enable AI assistant
Call \`update_project\` with all four AI settings from step 3 + conversation_ai_enabled: true.

### Step 5: Verify content
\`list_content_items\` to review. Then:
- \`reorder_content_item\`: adjust display order
- \`move_content_item\`: reorganize between categories
- \`update_content_item\`: fix descriptions
- \`delete_content_item\`: remove items (deleting a category cascades)

### Step 6: Manage distribution
A default QR code is auto-created. Use:
- \`list_access_tokens\`: see existing QR codes and scan URLs
- \`create_access_token\`: additional access points (e.g., "Main Entrance", "Table 5")
- \`update_access_token\`: set daily session limits or disable
- \`delete_access_token\`: remove obsolete QR codes

### Step 7: Remind user about remaining tasks
After project setup is complete, remind the user to do the following in the **FunTell web portal**:
- **Upload images** for each content item (enhances the visual experience)
- **Add translations** if multilingual content is needed (supports: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th)

## Tips
- Description quality matters: detailed descriptions directly improve the AI assistant.
- Use \`optimize_description\` to polish descriptions before saving.
- Use \`create_content_items_batch\` over individual \`create_content_item\` calls.
- Generate AI settings AFTER adding all content.
- Check subscription limits before creating projects.
- Supported languages: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th`;

export function createServer(): McpServer {
  const server = new McpServer(
    { name: "funtell", version: "1.0.0" },
    { instructions: SERVER_INSTRUCTIONS },
  );

  // Login tool — must be called before any other tool
  server.tool(
    "login",
    "Sign in to FunTell with your creator account email and password. This must be called before using any other tool. Ask the user for their FunTell platform login credentials (NOT Supabase admin credentials).",
    {
      email: z.string().email().describe("FunTell creator account email"),
      password: z.string().describe("FunTell creator account password"),
    },
    async ({ email, password }) => {
      if (isAuthenticated()) {
        return {
          content: [
            { type: "text" as const, text: "Already logged in. Use other tools to manage your projects." },
          ],
        };
      }

      const result = await authenticate(email, password);

      if (!result.success) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Login failed: ${result.error}\nMake sure you're using your FunTell platform login, not your Supabase admin credentials.`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: "text" as const,
            text: `Logged in successfully as ${result.email}.\nYou can now manage your projects, content, and AI settings.`,
          },
        ],
      };
    }
  );

  // Workflow guide tool — on-demand access for any agent
  server.tool(
    "get_workflow",
    "Get the complete FunTell project creation workflow guide. Call this to learn the correct sequence of tool calls for creating projects, adding content, configuring AI, and managing distribution. Useful as a reference at any point during project management.",
    {},
    async () => {
      return {
        content: [{ type: "text" as const, text: WORKFLOW_GUIDE }],
      };
    }
  );

  // Register all tools
  registerProjectTools(server);
  registerContentTools(server);
  registerAccessTokenTools(server);
  registerAIConfigTools(server);
  registerAccountTools(server);

  return server;
}
