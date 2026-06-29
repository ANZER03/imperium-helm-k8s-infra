CREATE TABLE IF NOT EXISTS imperium_projection_state
(
    article_id text PRIMARY KEY,
    country_id integer,
    root_topic_id integer,
    published_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS imperium_projection_state_country_idx
    ON imperium_projection_state (country_id);

CREATE INDEX IF NOT EXISTS imperium_projection_state_root_topic_idx
    ON imperium_projection_state (root_topic_id);
