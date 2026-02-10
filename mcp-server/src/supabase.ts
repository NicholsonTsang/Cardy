import { createClient, SupabaseClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    "Missing required environment variables: SUPABASE_URL, SUPABASE_ANON_KEY"
  );
  process.exit(1);
}

export const supabase: SupabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY
);

/** Whether the user has authenticated via the login tool */
let _authenticated = false;

export function isAuthenticated(): boolean {
  return _authenticated;
}

/**
 * Sign in with email/password provided by the user via the login tool.
 * The Supabase JS client automatically handles JWT refresh after sign-in.
 * All RPC calls will use auth.uid() from the session — RLS enforces ownership.
 */
export async function authenticate(
  email: string,
  password: string
): Promise<{ success: true; email: string; userId: string } | { success: false; error: string }> {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    return { success: false, error: error.message };
  }

  _authenticated = true;
  console.error(`Authenticated as ${data.user.email} (${data.user.id})`);
  return { success: true, email: data.user.email!, userId: data.user.id };
}
