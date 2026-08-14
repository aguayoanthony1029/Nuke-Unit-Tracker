import { describe, expect, it, vi } from "vitest";
vi.mock("../src/config.js", () => ({ config: { discord: { guildID: "guild", channelID: "channel", trustedRoleID: "role" } } }));
vi.mock("../src/db.js", () => ({ removePick: vi.fn(), upsertPick: vi.fn() }));
vi.mock("../src/notifications.js", () => ({ notifyFreePick: vi.fn() }));
import { shouldMirror } from "../src/discord.js";

describe("shouldMirror", () => {
  const message = (overrides = {}) => ({ author: { bot: false }, guildId: "guild", channelId: "channel", content: "Free play", member: { roles: { cache: { has: (role: string) => role === "role" } } }, ...overrides }) as never;
  it("allows trusted free-picks posts", () => expect(shouldMirror(message())).toBe(true));
  it("rejects non-staff posts", () => expect(shouldMirror(message({ member: { roles: { cache: { has: () => false } } } }))).toBe(false));
  it("rejects bot posts", () => expect(shouldMirror(message({ author: { bot: true } }))).toBe(false));
});
