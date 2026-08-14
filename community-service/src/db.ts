import { Pool } from "pg";
import { config } from "./config.js";

export const pool = new Pool({ connectionString: config.databaseURL, ssl: process.env.NODE_ENV === "production" ? { rejectUnauthorized: false } : undefined });

export type FreePickRow = {
  discord_message_id: string; content: string; image_urls: string[]; posted_at: Date; edited_at: Date | null; discord_url: string | null;
};

export async function upsertPick(input: { id: string; channelID: string; authorID: string; content: string; imageURLs: string[]; discordURL?: string }) {
  await pool.query(`INSERT INTO free_picks (discord_message_id, channel_id, author_id, content, image_urls, discord_url, posted_at)
    VALUES ($1,$2,$3,$4,$5,$6,NOW())
    ON CONFLICT (discord_message_id) DO UPDATE SET content = EXCLUDED.content, image_urls = EXCLUDED.image_urls, discord_url = EXCLUDED.discord_url, edited_at = NOW(), deleted_at = NULL`,
    [input.id, input.channelID, input.authorID, input.content, JSON.stringify(input.imageURLs), input.discordURL ?? null]);
}

export async function removePick(id: string) { await pool.query("UPDATE free_picks SET deleted_at = NOW() WHERE discord_message_id = $1", [id]); }

export async function listPicks(limit: number, before?: Date): Promise<FreePickRow[]> {
  const result = await pool.query<FreePickRow>(`SELECT discord_message_id, content, image_urls, posted_at, edited_at, discord_url FROM free_picks
    WHERE deleted_at IS NULL AND ($2::timestamptz IS NULL OR posted_at < $2) ORDER BY posted_at DESC LIMIT $1`, [limit, before ?? null]);
  return result.rows;
}

export async function upsertDeviceToken(token: string, timezone: string, quietStart: number, quietEnd: number) {
  await pool.query(`INSERT INTO device_tokens (token, timezone, quiet_start, quiet_end) VALUES ($1,$2,$3,$4)
  ON CONFLICT (token) DO UPDATE SET enabled=true, timezone=EXCLUDED.timezone, quiet_start=EXCLUDED.quiet_start, quiet_end=EXCLUDED.quiet_end, updated_at=NOW()`, [token, timezone, quietStart, quietEnd]);
}

export async function enabledTokens(): Promise<Array<{ token: string; timezone: string; quiet_start: number; quiet_end: number }>> {
  return (await pool.query("SELECT token, timezone, quiet_start, quiet_end FROM device_tokens WHERE enabled = true")).rows;
}

