import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { backendFetch } from "../backend.js";
import { requireAuth } from "../auth-guard.js";

export function registerAIConfigTools(server: McpServer): void {
  server.tool(
    "generate_ai_settings",
    `Auto-generate AI assistant configuration for a project using OpenAI. Analyzes the project's content to create tailored persona, knowledge base, and welcome messages.

WORKFLOW: 1) create_project → 2) create_content_items_batch → 3) generate_ai_settings → 4) update_project with the returned settings + conversation_ai_enabled=true

Returns ai_instruction, ai_knowledge_base, ai_welcome_general, ai_welcome_item. Pass all four to update_project.`,
    {
      card_id: z
        .string()
        .uuid()
        .describe("The project ID (content items will be fetched automatically for context)"),
      card_name: z.string().describe("The project name"),
      card_description: z
        .string()
        .optional()
        .default("")
        .describe("The project description"),
      original_language: z
        .string()
        .optional()
        .default("en")
        .describe("Language for the generated AI settings"),
      content_mode: z
        .string()
        .optional()
        .default("list")
        .describe("Content display mode"),
      is_grouped: z
        .boolean()
        .optional()
        .default(false)
        .describe("Whether content is grouped"),
      billing_type: z
        .string()
        .optional()
        .default("digital")
        .describe("Billing type"),
    },
    async (params) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      try {
        const result = (await backendFetch("/api/ai/generate-ai-settings", {
          cardId: params.card_id,
          cardName: params.card_name,
          cardDescription: params.card_description,
          originalLanguage: params.original_language,
          contentMode: params.content_mode,
          isGrouped: params.is_grouped,
          billingType: params.billing_type,
        })) as {
          success: boolean;
          data?: {
            ai_instruction: string;
            ai_knowledge_base: string;
            ai_welcome_general: string;
            ai_welcome_item: string;
          };
        };

        if (!result.success || !result.data) {
          return {
            content: [
              {
                type: "text" as const,
                text: "AI settings generation failed. No data returned.",
              },
            ],
            isError: true,
          };
        }

        const { ai_instruction, ai_knowledge_base, ai_welcome_general, ai_welcome_item } =
          result.data;

        return {
          content: [
            {
              type: "text" as const,
              text: `AI settings generated successfully.\n\n**AI Instruction:**\n${ai_instruction}\n\n**Knowledge Base:**\n${ai_knowledge_base}\n\n**Welcome (General):**\n${ai_welcome_general}\n\n**Welcome (Item):**\n${ai_welcome_item}\n\nUse update_project to save these settings with conversation_ai_enabled=true.`,
            },
          ],
        };
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "AI generation failed";
        return {
          content: [{ type: "text" as const, text: `Error: ${message}` }],
          isError: true,
        };
      }
    }
  );

  server.tool(
    "optimize_description",
    "Use AI to polish and improve a project or content item description. Returns an optimized version of the text. Use update_project or update_content_item to save the result.",
    {
      description: z.string().min(1).describe("The description text to optimize"),
      card_id: z.string().uuid().optional().describe("Project ID for context (optional, improves quality)"),
      card_name: z.string().optional().describe("Project name for context (optional)"),
      original_language: z.string().optional().default("en").describe("Language of the description"),
    },
    async (params) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      try {
        const result = (await backendFetch("/api/ai/optimize-description", {
          description: params.description,
          cardId: params.card_id,
          cardName: params.card_name,
          originalLanguage: params.original_language,
        })) as { success: boolean; data?: { description: string } };

        if (!result.success || !result.data) {
          return {
            content: [{ type: "text" as const, text: "Description optimization failed." }],
            isError: true,
          };
        }

        return {
          content: [
            {
              type: "text" as const,
              text: `Optimized description:\n\n${result.data.description}\n\nUse update_project or update_content_item to save this.`,
            },
          ],
        };
      } catch (err) {
        const message = err instanceof Error ? err.message : "Optimization failed";
        return {
          content: [{ type: "text" as const, text: `Error: ${message}` }],
          isError: true,
        };
      }
    }
  );
}
