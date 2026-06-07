import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export async function getRequestUser(req: Request, client: SupabaseClient) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "");
  if (!token) {
    return null;
  }
  const { data, error } = await client.auth.getUser(token);
  if (error) {
    return null;
  }
  return data.user;
}

export async function isAdminUser(userId: string, client: SupabaseClient) {
  const { data } = await client
    .from("profiles")
    .select("is_admin")
    .eq("id", userId)
    .maybeSingle();
  return data?.is_admin === true;
}
