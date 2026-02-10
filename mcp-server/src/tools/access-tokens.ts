import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { supabase } from "../supabase.js";
import { requireAuth } from "../auth-guard.js";

export function registerAccessTokenTools(server: McpServer): void {
  // List access tokens (QR codes)
  server.tool(
    "list_access_tokens",
    "Get all QR codes/access tokens for a project with their session statistics, enabled status, and daily limits.",
    {
      card_id: z.string().uuid().describe("The project ID"),
    },
    async ({ card_id }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("get_card_access_tokens", {
        p_card_id: card_id,
      });
      if (error) {
        return {
          content: [{ type: "text" as const, text: `Error: ${error.message}` }],
          isError: true,
        };
      }
      return {
        content: [
          { type: "text" as const, text: JSON.stringify(data, null, 2) },
        ],
      };
    }
  );

  // Create access token
  server.tool(
    "create_access_token",
    "Create a new QR code/access token for a project. Each QR code gets a unique URL that visitors scan to access the experience. A default QR code is auto-created with the project.",
    {
      card_id: z.string().uuid().describe("The project ID"),
      name: z
        .string()
        .optional()
        .default("Default")
        .describe("Display name for this QR code (e.g., 'Main Entrance', 'Table 5')"),
      daily_session_limit: z
        .number()
        .nullable()
        .optional()
        .default(null)
        .describe("Max sessions per day (null for unlimited)"),
    },
    async ({ card_id, name, daily_session_limit }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("create_access_token", {
        p_card_id: card_id,
        p_name: name,
        p_daily_session_limit: daily_session_limit,
      });
      if (error) {
        return {
          content: [{ type: "text" as const, text: `Error: ${error.message}` }],
          isError: true,
        };
      }
      return {
        content: [
          {
            type: "text" as const,
            text: `QR code created.\n${JSON.stringify(data, null, 2)}`,
          },
        ],
      };
    }
  );

  // Update access token
  server.tool(
    "update_access_token",
    "Update a QR code's name, enabled status, or daily session limit.",
    {
      token_id: z.string().uuid().describe("The access token ID to update"),
      name: z.string().optional().describe("New display name"),
      is_enabled: z
        .boolean()
        .optional()
        .describe("Enable or disable the QR code"),
      daily_session_limit: z
        .number()
        .nullable()
        .optional()
        .describe("New daily session limit (null for unlimited)"),
    },
    async ({ token_id, name, is_enabled, daily_session_limit }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("update_access_token", {
        p_token_id: token_id,
        p_name: name ?? null,
        p_is_enabled: is_enabled ?? null,
        p_daily_session_limit:
          daily_session_limit === undefined
            ? null
            : daily_session_limit === null
              ? -1
              : daily_session_limit,
      });
      if (error) {
        return {
          content: [{ type: "text" as const, text: `Error: ${error.message}` }],
          isError: true,
        };
      }
      return {
        content: [
          { type: "text" as const, text: `QR code updated.\n${JSON.stringify(data, null, 2)}` },
        ],
      };
    }
  );

  // Delete access token
  server.tool(
    "delete_access_token",
    "Delete a QR code/access token. Visitors will no longer be able to access the experience through this QR code.",
    {
      token_id: z.string().uuid().describe("The access token ID to delete"),
    },
    async ({ token_id }) => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("delete_access_token", {
        p_token_id: token_id,
      });
      if (error) {
        return {
          content: [{ type: "text" as const, text: `Error: ${error.message}` }],
          isError: true,
        };
      }
      return {
        content: [
          { type: "text" as const, text: `QR code deleted.\n${JSON.stringify(data, null, 2)}` },
        ],
      };
    }
  );
}
