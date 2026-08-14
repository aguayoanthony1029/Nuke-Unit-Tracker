import Fastify from "fastify";
import { config } from "./config.js";
import { listPicks, upsertDeviceToken } from "./db.js";
import { startDiscordBot } from "./discord.js";

const app = Fastify({ logger: true });

app.get("/health", async () => ({ status: "ok" }));
app.get("/v1/free-picks", async request => {
  const query = request.query as { limit?: string; before?: string };
  const limit = Math.min(Math.max(Number(query.limit ?? 20), 1), 50);
  const before = query.before ? new Date(query.before) : undefined;
  const rows = await listPicks(limit, before);
  return { items: rows.map(row => ({ id: row.discord_message_id, content: row.content, imageURLs: row.image_urls, postedAt: row.posted_at, editedAt: row.edited_at, discordURL: row.discord_url })), nextCursor: rows.length ? rows.at(-1)?.posted_at.toISOString() : null };
});
app.post("/v1/device-tokens", async (request, reply) => {
  const body = request.body as { token?: string; timezone?: string; quietStart?: number; quietEnd?: number };
  if (!body.token || !body.timezone || !Number.isInteger(body.quietStart) || !Number.isInteger(body.quietEnd)) return reply.code(400).send({ error: "token, timezone, quietStart, and quietEnd are required" });
  await upsertDeviceToken(body.token, body.timezone, body.quietStart as number, body.quietEnd as number);
  return reply.code(204).send();
});

await app.listen({ port: config.port, host: "0.0.0.0" });
startDiscordBot();
