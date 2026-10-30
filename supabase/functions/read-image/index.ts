// read-image: reads photos for the pit dashboard (laminated checklist pages,
// the Battery Beak screen) and returns the JSON the prompt asks for.
//
// Request:  POST { prompt: string, images: [{ media_type, data (base64) }] }
//           with the signed-in user's Supabase access token.
// Response: 200 { json } or an error status with { code } (codes match scanErr() in index.html).
//
// Secrets: ANTHROPIC_API_KEY (supabase secrets set ANTHROPIC_API_KEY=...).
// SUPABASE_URL and SUPABASE_ANON_KEY are provided by Supabase.

import Anthropic from "npm:@anthropic-ai/sdk";
import { createClient } from "npm:@supabase/supabase-js@2";

const MAX_IMAGES = 5;
const IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/gif"]);
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const anthropic = new Anthropic(); // reads ANTHROPIC_API_KEY

const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
const fail = (status: number, code: string) => reply(status, { code });

// The prompts ask for JSON only; take the outermost {...} in case of stray text.
function parseJson(text: string): unknown {
  const a = text.indexOf("{"), b = text.lastIndexOf("}");
  if (a < 0 || b <= a) return undefined;
  try {
    return JSON.parse(text.slice(a, b + 1));
  } catch {
    return undefined;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return fail(405, "bad_request");

  // Only people on the board (pit_members) can spend photo reads.
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: role, error: roleErr } = await sb.rpc("pit_role");
  if (roleErr) return fail(401, "session_expired");
  if (!role) return fail(403, "not_granted");

  let body: { prompt?: unknown; images?: unknown };
  try {
    body = await req.json();
  } catch {
    return fail(400, "bad_request");
  }
  const prompt = typeof body.prompt === "string" ? body.prompt : "";
  const images = Array.isArray(body.images) ? body.images : [];
  if (!prompt || !images.length) return fail(400, "bad_request");
  if (images.length > MAX_IMAGES) return fail(413, "prompt_too_large");
  for (const im of images) {
    if (!IMAGE_TYPES.has(im?.media_type) || typeof im?.data !== "string" || !im.data) return fail(415, "image_rejected");
  }

  try {
    const msg = await anthropic.beta.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      output_config: { effort: "medium" },
      // If a safety classifier declines, the API retries on a fallback model in the same call.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      messages: [{
        role: "user",
        content: [
          ...images.map((im: { media_type: "image/jpeg" | "image/png" | "image/webp" | "image/gif"; data: string }) => ({
            type: "image" as const,
            source: { type: "base64" as const, media_type: im.media_type, data: im.data },
          })),
          { type: "text" as const, text: prompt },
        ],
      }],
    });
    if (msg.stop_reason === "refusal") return fail(422, "refused");
    const text = msg.content.map((b) => (b.type === "text" ? b.text : "")).join("");
    const json = parseJson(text);
    if (json === undefined) return fail(502, "unreadable");
    return reply(200, { json });
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) return fail(429, "rate_limited");
    if (e instanceof Anthropic.BadRequestError) {
      return fail(400, /too long|too large|too many/i.test(e.message) ? "prompt_too_large" : "image_rejected");
    }
    if (e instanceof Anthropic.APIError) {
      console.error("anthropic", e.status, e.message);
      return fail(502, "failed");
    }
    console.error(e);
    return fail(500, "failed");
  }
});
