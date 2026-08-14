import "dotenv/config";

const required = (name: string): string => {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
};

export const config = {
  port: Number(process.env.PORT ?? 3000),
  databaseURL: required("DATABASE_URL"),
  discord: {
    token: required("DISCORD_BOT_TOKEN"),
    guildID: required("DISCORD_GUILD_ID"),
    channelID: required("DISCORD_FREE_PICKS_CHANNEL_ID"),
    trustedRoleID: required("DISCORD_TRUSTED_ROLE_ID"),
    channelURL: process.env.DISCORD_CHANNEL_URL
  },
  apns: {
    keyID: process.env.APNS_KEY_ID,
    teamID: process.env.APNS_TEAM_ID,
    keyPath: process.env.APNS_KEY_PATH,
    bundleID: process.env.APNS_BUNDLE_ID ?? "com.nukesportsbets.nukeunittracker",
    production: process.env.APNS_PRODUCTION === "true"
  }
};

