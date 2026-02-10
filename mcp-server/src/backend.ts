import { supabase } from "./supabase.js";

const BACKEND_URL = process.env.BACKEND_URL;
if (!BACKEND_URL) {
  console.error("Warning: BACKEND_URL not set. AI tools will fail.");
}

const DEFAULT_TIMEOUT_MS = 60_000; // 60 seconds

/**
 * Make an authenticated POST request to the Express backend.
 * Uses the current Supabase session token (auto-refreshed).
 * @param timeoutMs Override default timeout
 */
export async function backendFetch(
  path: string,
  body: Record<string, unknown>,
  timeoutMs: number = DEFAULT_TIMEOUT_MS,
): Promise<unknown> {
  if (!BACKEND_URL) {
    throw new Error("BACKEND_URL is not configured. Cannot reach the backend server.");
  }

  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session?.access_token) {
    throw new Error(
      "No active session. Authentication may have expired. Please call the login tool again."
    );
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(`${BACKEND_URL}${path}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    if (!response.ok) {
      const err = (await response.json().catch(() => ({
        message: response.statusText,
      }))) as { message?: string };
      throw new Error(err.message || `HTTP ${response.status}`);
    }

    return response.json();
  } catch (err) {
    if (err instanceof Error && err.name === "AbortError") {
      throw new Error(`Backend request timed out after ${timeoutMs / 1000}s: ${path}`);
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }
}
