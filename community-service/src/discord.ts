import { Client, GatewayIntentBits, Message } from "discord.js";
import { config } from "./config.js";
import { removePick, upsertPick } from "./db.js";
import { notifyFreePick } from "./notifications.js";

export function shouldMirror(message: Pick<Message, "author" | "channelId" | "guildId" | "content" | "member">): boolean {
  return !message.author.bot && message.guildId === config.discord.guildID && message.channelId === config.discord.channelID && Boolean(message.content.trim()) && Boolean(message.member?.roles.cache.has(config.discord.trustedRoleID));
}

export function startDiscordBot() {
  const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent] });
  client.on("messageCreate", async message => {
    if (!shouldMirror(message)) return;
    await persist(message, true);
  });
  client.on("messageUpdate", async (_old, updated) => { if (!updated.partial && shouldMirror(updated)) await persist(updated, false); });
  client.on("messageDelete", async message => { if (message.channelId === config.discord.channelID) await removePick(message.id); });
  client.login(config.discord.token);
}

async function persist(message: Message, notify: boolean) {
  const imageURLs = [...message.attachments.values()].filter(attachment => attachment.contentType?.startsWith("image/")).map(attachment => attachment.url);
  await upsertPick({ id: message.id, channelID: message.channelId, authorID: message.author.id, content: message.content, imageURLs, discordURL: config.discord.channelURL });
  if (notify) await notifyFreePick(message.content, message.id);
}

