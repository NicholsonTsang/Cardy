import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { supabase } from "../supabase.js";
import { requireAuth } from "../auth-guard.js";

export function registerAccountTools(server: McpServer): void {
  // Get subscription info
  server.tool(
    "get_subscription",
    "Get the current user's subscription tier (free/starter/premium), project limits, and session budget. Use this to check what actions are available before creating projects.",
    {},
    async () => {
      const loginErr = requireAuth(); if (loginErr) return loginErr;
      // Get the user ID from the JWT
      const {
        data: { user },
        error: userErr,
      } = await supabase.auth.getUser();
      if (userErr || !user) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Error getting user: ${userErr?.message || "Not authenticated"}`,
            },
          ],
          isError: true,
        };
      }

      const { data, error } = await supabase.rpc(
        "get_or_create_subscription",
        { p_user_id: user.id }
      );
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

  // Get credit balance
  server.tool(
    "get_credit_balance",
    "Get the current user's credit balance and usage statistics, including total credits, consumed credits, and monthly breakdown.",
    {},
    async () => {
      const authErr = requireAuth(); if (authErr) return authErr;
      const { data, error } = await supabase.rpc("get_user_credits");
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
}
