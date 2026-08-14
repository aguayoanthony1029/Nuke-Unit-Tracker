import apn from "apn";
import { config } from "./config.js";
import { enabledTokens } from "./db.js";

const provider = config.apns.keyID && config.apns.teamID && config.apns.keyPath
  ? new apn.Provider({ token: { key: config.apns.keyPath, keyId: config.apns.keyID, teamId: config.apns.teamID }, production: config.apns.production })
  : undefined;

export async function notifyFreePick(content: string, pickID: string) {
  if (!provider) return;
  const devices = await enabledTokens();
  const now = new Date();
  const sendTo = devices.filter(device => !isQuietHour(now, device.timezone, device.quiet_start, device.quiet_end)).map(device => device.token);
  if (!sendTo.length) return;
  const notification = new apn.Notification();
  notification.topic = config.apns.bundleID;
  notification.alert = { title: "New Nuke Free Pick", body: content.slice(0, 160) };
  notification.payload = { freePickID: pickID };
  notification.sound = "default";
  const result = await provider.send(notification, sendTo);
  for (const failed of result.failed) if (failed.status === "410") { /* mark removed tokens disabled on a future cleanup pass */ }
}

export function isQuietHour(now: Date, timezone: string, start: number, end: number): boolean {
  const hour = Number(new Intl.DateTimeFormat("en-US", { timeZone: timezone, hour: "numeric", hourCycle: "h23" }).format(now));
  if (start === end) return false;
  return start < end ? hour >= start && hour < end : hour >= start || hour < end;
}

