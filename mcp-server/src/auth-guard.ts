import { isAuthenticated } from "./supabase.js";

interface ToolResult {
  [key: string]: unknown;
  content: Array<{ type: "text"; text: string }>;
  isError?: boolean;
}

/**
 * Returns an error result if the user is not authenticated.
 * Call at the top of every tool handler (except login).
 * Returns null if authenticated.
 */
export function requireAuth(): ToolResult | null {
  if (!isAuthenticated()) {
    return {
      content: [
        {
          type: "text" as const,
          text: 'Not logged in. Please call the "login" tool first with your FunTell creator account credentials.',
        },
      ],
      isError: true,
    };
  }
  return null;
}
