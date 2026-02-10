import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { supabase } from "../supabase.js";
import { requireAuth } from "../auth-guard.js";

export function registerContentTools(server: McpServer): void {
  server.tool(
    "list_content_items",
    "Get all content items for a project, including categories (parent items) and their children. Items with parent_id=null are categories; items with a parent_id are content items within that category.",
    { card_id: z.string().uuid().describe("The project ID") },
    async ({ card_id }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("get_card_content_items", { p_card_id: card_id });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
    }
  );

  server.tool(
    "create_content_item",
    "Create a single content item within a project. For grouped content, set parent_id to a category's ID. For non-grouped content, first create a category (parent_id=null) then add items to it. Returns the new item ID.",
    {
      card_id: z.string().uuid().describe("The project ID"),
      name: z.string().describe("Item name/title"),
      parent_id: z.string().uuid().nullable().optional().default(null).describe("Parent category ID (null to create a category)"),
      description: z.string().optional().default("").describe("Item description in markdown. Do NOT start with the item name. Use short paragraphs, **bold** for key terms, bullet lists for structured info. No tables — use bullet lists instead."),
      ai_knowledge_base: z.string().optional().default("").describe("Additional facts for AI assistant about this item (max 500 words)"),
    },
    async ({ card_id, name, parent_id, description, ai_knowledge_base }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("create_content_item", {
        p_card_id: card_id, p_name: name, p_parent_id: parent_id,
        p_content: description, p_image_url: null,
        p_original_image_url: null, p_crop_parameters: null,
        p_ai_knowledge_base: ai_knowledge_base,
      });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: `Content item created.\nID: ${data}\nParent: ${parent_id || "none (this is a category)"}` }] };
    }
  );

  server.tool(
    "create_content_items_batch",
    `Create multiple content items organized by categories in a single batch. This is the primary tool for populating a project from document content.

Structure: Each category becomes a Layer 1 parent, and its items become Layer 2 children.

IMPORTANT:
- Non-grouped projects (is_grouped=false): Use a SINGLE category named "default" containing all items
- Grouped projects (is_grouped=true): Use multiple categories (e.g., "Appetizers", "Main Course", "Desserts")
- Descriptions MUST be well-formatted markdown for mobile readability (see formatting rules below)

## Markdown Formatting Rules for Descriptions

Content is rendered on mobile with a dark background. Write clean, scannable markdown:

**Use freely:** paragraphs, **bold**, *italic*, ### headings (h3/h4 only), bullet lists, numbered lists, [links](url), > blockquotes, --- horizontal rules
**Do NOT use:** tables (no styling — convert to bullet lists instead), code blocks, HTML tags, h1/h2 headings, deeply nested lists (max 2 levels)

**Structure rules:**
- Do NOT start with the item name — it is already displayed as the title above the description
- Use short paragraphs (2-4 sentences) for mobile readability
- Use **bold** for key terms, names, prices, and highlights
- Use bullet lists for structured info (specifications, features, ingredients, details)
- Use ### or #### for subsections within longer descriptions
- Use > blockquotes for quotes, highlights, or special notes
- Use --- to separate major sections in long descriptions
- Separate all blocks with blank lines (paragraph, then blank line, then list, etc.)
- For tabular data (specs, hours, prices), use a labeled bullet list instead of a table:
  - **Hours:** 9:00 AM – 5:00 PM
  - **Price:** $25 adults, $15 children
  - **Duration:** 90 minutes`,
    {
      card_id: z.string().uuid().describe("The project ID to add content to"),
      categories: z.array(z.object({
        name: z.string().describe('Category name (use "default" for non-grouped content)'),
        items: z.array(z.object({
          name: z.string().describe("Content item name/title"),
          description: z.string().describe("Item description in markdown. Do NOT start with the item name. Use short paragraphs, **bold** for key terms, bullet lists for structured info. No tables — use bullet lists instead. Be detailed — description quality directly impacts AI assistant."),
          ai_knowledge_base: z.string().optional().default("").describe("Additional facts for AI assistant"),
        })),
      })).describe("Categories with their content items"),
    },
    async ({ card_id, categories }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const results: string[] = [];
      let totalCreated = 0;
      let totalFailed = 0;

      for (const category of categories) {
        const { data: parentId, error: parentErr } = await supabase.rpc("create_content_item", {
          p_card_id: card_id, p_name: category.name, p_parent_id: null,
          p_content: "", p_image_url: null, p_original_image_url: null,
          p_crop_parameters: null, p_ai_knowledge_base: "",
        });
        if (parentErr) {
          results.push(`Failed to create category "${category.name}": ${parentErr.message}`);
          totalFailed += category.items.length;
          continue;
        }
        results.push(`Created category "${category.name}" (${parentId})`);

        for (const item of category.items) {
          const { data: itemId, error: itemErr } = await supabase.rpc("create_content_item", {
            p_card_id: card_id, p_name: item.name, p_parent_id: parentId,
            p_content: item.description, p_image_url: null,
            p_original_image_url: null, p_crop_parameters: null,
            p_ai_knowledge_base: item.ai_knowledge_base,
          });
          if (itemErr) { results.push(`  Failed "${item.name}": ${itemErr.message}`); totalFailed++; }
          else { results.push(`  Created "${item.name}" (${itemId})`); totalCreated++; }
        }
      }

      results.push(`\nSummary: ${totalCreated} items created, ${totalFailed} failed, ${categories.length} categories`);
      return { content: [{ type: "text" as const, text: results.join("\n") }], isError: totalFailed > 0 && totalCreated === 0 };
    }
  );

  server.tool(
    "update_content_item",
    "Update an existing content item's name, description, or AI knowledge base.",
    {
      content_item_id: z.string().uuid().describe("The content item ID to update"),
      name: z.string().optional(), description: z.string().optional(),
      ai_knowledge_base: z.string().optional(),
    },
    async (params) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data: current, error: fetchErr } = await supabase.rpc("get_content_item_by_id", { p_content_item_id: params.content_item_id });
      if (fetchErr || !current) return { content: [{ type: "text" as const, text: `Error: ${fetchErr?.message || "Item not found"}` }], isError: true };
      const item = Array.isArray(current) ? current[0] : current;
      const { error } = await supabase.rpc("update_content_item", {
        p_content_item_id: params.content_item_id,
        p_name: params.name ?? item.name,
        p_content: params.description ?? item.content,
        p_image_url: item.image_url,
        p_original_image_url: item.original_image_url,
        p_crop_parameters: item.crop_parameters,
        p_ai_knowledge_base: params.ai_knowledge_base ?? item.ai_knowledge_base,
      });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: "Content item updated successfully." }] };
    }
  );

  server.tool(
    "delete_content_item",
    "Delete a content item. If deleting a category (parent), all its child items will also be deleted.",
    { content_item_id: z.string().uuid().describe("The content item ID to delete") },
    async ({ content_item_id }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { error } = await supabase.rpc("delete_content_item", { p_content_item_id: content_item_id });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: "Content item deleted successfully." }] };
    }
  );

  server.tool(
    "reorder_content_item",
    "Change the display order of a content item. Use list_content_items first to see current sort_order values, then set the new position. Items are displayed in ascending sort_order.",
    {
      content_item_id: z.string().uuid().describe("The content item ID to reorder"),
      new_sort_order: z.number().int().describe("New sort position (0-based). Other items shift automatically."),
    },
    async ({ content_item_id, new_sort_order }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { error } = await supabase.rpc("update_content_item_order", {
        p_content_item_id: content_item_id,
        p_new_sort_order: new_sort_order,
      });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: `Content item reordered to position ${new_sort_order}.` }] };
    }
  );

  server.tool(
    "move_content_item",
    "Move a content item to a different category (parent). Use this to reorganize grouped content. The item keeps its content but changes which category it belongs to.",
    {
      content_item_id: z.string().uuid().describe("The content item ID to move"),
      new_parent_id: z.string().uuid().nullable().describe("New parent category ID (null to make it a top-level category)"),
      new_sort_order: z.number().int().nullable().optional().default(null).describe("Position within new parent (null for end)"),
    },
    async ({ content_item_id, new_parent_id, new_sort_order }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("move_content_item_to_parent", {
        p_content_item_id: content_item_id,
        p_new_parent_id: new_parent_id,
        p_new_sort_order: new_sort_order,
      });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
    }
  );
}
