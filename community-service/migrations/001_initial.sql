CREATE TABLE IF NOT EXISTS free_picks (
    discord_message_id TEXT PRIMARY KEY,
    channel_id TEXT NOT NULL,
    author_id TEXT NOT NULL,
    content TEXT NOT NULL,
    image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
    discord_url TEXT,
    posted_at TIMESTAMPTZ NOT NULL,
    edited_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS free_picks_visible_idx ON free_picks (posted_at DESC) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS device_tokens (
    token TEXT PRIMARY KEY,
    enabled BOOLEAN NOT NULL DEFAULT true,
    timezone TEXT NOT NULL,
    quiet_start SMALLINT NOT NULL CHECK (quiet_start BETWEEN 0 AND 23),
    quiet_end SMALLINT NOT NULL CHECK (quiet_end BETWEEN 0 AND 23),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

