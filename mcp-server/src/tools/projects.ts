import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { supabase } from "../supabase.js";
import { requireAuth } from "../auth-guard.js";
import { LANGUAGE_CODES } from "../constants.js";

export function registerProjectTools(server: McpServer): void {
  server.tool(
    "list_projects",
    "List all projects owned by the current user with session statistics, QR code counts, and content mode. Call this first to see existing projects before creating new ones.",
    {},
    async () => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("get_user_cards");
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
    }
  );

  server.tool(
    "get_project",
    "Get detailed information about a specific project by ID, including content mode, AI settings, and billing configuration",
    { card_id: z.string().uuid().describe("The project ID") },
    async ({ card_id }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("get_card_by_id", { p_card_id: card_id });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
    }
  );

  server.tool(
    "create_project",
    `Create a new FunTell project. Returns the project ID for use with other tools.

Content modes (pick based on content type):
- single: 1 featured item (e.g., article, announcement, company profile)
- list: Vertical list (e.g., restaurant menu, course modules, knowledge base, resource links)
- grid: 2-column visual grid (e.g., product catalog, photo gallery, team directory, portfolio)
- cards: Full-width cards (e.g., news, featured items, exhibition highlights)

Grouping (is_grouped):
- false: Flat list of items (still needs a parent category internally)
- true: Items organized into named categories (e.g., museum wings, menu sections, product categories, course modules, FAQ topics)

WORKFLOW: create_project → create_content_items_batch → generate_ai_settings → update_project(ai settings + conversation_ai_enabled=true)`,
    {
      name: z.string().describe("Project name"),
      description: z.string().optional().default("").describe("Project description (markdown supported)"),
      billing_type: z.enum(["digital", "physical"]).optional().default("digital"),
      content_mode: z.enum(["single", "list", "grid", "cards"]).optional().default("list"),
      is_grouped: z.boolean().optional().default(false),
      group_display: z.enum(["expanded", "collapsed"]).optional().default("expanded"),
      original_language: z.enum(LANGUAGE_CODES).optional().default("en"),
      conversation_ai_enabled: z.boolean().optional().default(false),
      ai_instruction: z.string().optional().default(""),
      ai_knowledge_base: z.string().optional().default(""),
      ai_welcome_general: z.string().optional().default(""),
      ai_welcome_item: z.string().optional().default(""),
      default_daily_session_limit: z.number().optional().default(500),
    },
    async (params) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("create_card", {
        p_name: params.name,
        p_description: params.description,
        p_image_url: null,
        p_original_image_url: null,
        p_crop_parameters: null,
        p_conversation_ai_enabled: params.conversation_ai_enabled,
        p_ai_instruction: params.ai_instruction,
        p_ai_knowledge_base: params.ai_knowledge_base,
        p_ai_welcome_general: params.ai_welcome_general,
        p_ai_welcome_item: params.ai_welcome_item,
        p_qr_code_position: "BR",
        p_original_language: params.original_language,
        p_content_mode: params.content_mode,
        p_is_grouped: params.is_grouped,
        p_group_display: params.group_display,
        p_billing_type: params.billing_type,
        p_default_daily_session_limit: params.billing_type === "digital" ? params.default_daily_session_limit : null,
      });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return {
        content: [{
          type: "text" as const,
          text: `Project created successfully.\nID: ${data}\nUse this ID with create_content_items_batch to add content, then generate_ai_settings to configure AI.`,
        }],
      };
    }
  );

  server.tool(
    "update_project",
    "Update an existing project's settings. Only provide the fields you want to change.",
    {
      card_id: z.string().uuid().describe("The project ID to update"),
      name: z.string().optional(),
      description: z.string().optional(),
      content_mode: z.enum(["single", "list", "grid", "cards"]).optional(),
      is_grouped: z.boolean().optional(),
      group_display: z.enum(["expanded", "collapsed"]).optional(),
      original_language: z.enum(LANGUAGE_CODES).optional(),
      conversation_ai_enabled: z.boolean().optional(),
      ai_instruction: z.string().optional(),
      ai_knowledge_base: z.string().optional(),
      ai_welcome_general: z.string().optional(),
      ai_welcome_item: z.string().optional(),
      default_daily_session_limit: z.number().optional(),
    },
    async (params) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data: current, error: fetchErr } = await supabase.rpc("get_card_by_id", { p_card_id: params.card_id });
      if (fetchErr || !current) {
        return { content: [{ type: "text" as const, text: `Error fetching project: ${fetchErr?.message || "Not found"}` }], isError: true };
      }
      const card = Array.isArray(current) ? current[0] : current;
      const { error } = await supabase.rpc("update_card", {
        p_card_id: params.card_id,
        p_name: params.name ?? card.name,
        p_description: params.description ?? card.description,
        p_image_url: card.image_url,
        p_original_image_url: card.original_image_url,
        p_crop_parameters: card.crop_parameters,
        p_conversation_ai_enabled: params.conversation_ai_enabled ?? card.conversation_ai_enabled,
        p_ai_instruction: params.ai_instruction ?? card.ai_instruction,
        p_ai_knowledge_base: params.ai_knowledge_base ?? card.ai_knowledge_base,
        p_ai_welcome_general: params.ai_welcome_general ?? card.ai_welcome_general,
        p_ai_welcome_item: params.ai_welcome_item ?? card.ai_welcome_item,
        p_qr_code_position: card.qr_code_position,
        p_original_language: params.original_language ?? card.original_language,
        p_content_mode: params.content_mode ?? card.content_mode,
        p_is_grouped: params.is_grouped ?? card.is_grouped,
        p_group_display: params.group_display ?? card.group_display,
        p_billing_type: card.billing_type,
        p_default_daily_session_limit: params.default_daily_session_limit ?? card.default_daily_session_limit,
      });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: "Project updated successfully." }] };
    }
  );

  server.tool(
    "delete_project",
    "Permanently delete a project and all its content items, QR codes, and translations. This action cannot be undone.",
    { card_id: z.string().uuid().describe("The project ID to delete") },
    async ({ card_id }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { error } = await supabase.rpc("delete_card", { p_card_id: card_id });
      if (error) return { content: [{ type: "text" as const, text: `Error: ${error.message}` }], isError: true };
      return { content: [{ type: "text" as const, text: "Project deleted successfully." }] };
    }
  );
}
