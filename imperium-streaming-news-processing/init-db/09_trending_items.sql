-- Trending items: historical snapshots of keyword/entity trend scores.
-- Written by the imperium-trending-driver Spark app.

CREATE TABLE IF NOT EXISTS trend_items (
    id BIGSERIAL PRIMARY KEY,

    window_start TIMESTAMPTZ NOT NULL,
    window_end   TIMESTAMPTZ NOT NULL,

    scope_type   TEXT NOT NULL,   -- 'global', 'country', 'topic'
    scope_value  TEXT NOT NULL,   -- 'global', country_name, root_topic_label

    term         TEXT NOT NULL,
    term_type    TEXT NOT NULL,   -- 'title_word', 'title_bigram', 'excerpt_word'

    article_ids  TEXT[] NOT NULL DEFAULT '{}',

    current_count  INT NOT NULL,
    previous_count INT NOT NULL DEFAULT 0,
    velocity       DOUBLE PRECISION NOT NULL DEFAULT 1,
    score          DOUBLE PRECISION NOT NULL,

    created_at     TIMESTAMPTZ DEFAULT now(),

    UNIQUE (
        window_start,
        window_end,
        scope_type,
        scope_value,
        term,
        term_type
    )
);

CREATE INDEX IF NOT EXISTS idx_trend_scope_window
    ON trend_items (scope_type, scope_value, window_end DESC, score DESC);

CREATE INDEX IF NOT EXISTS idx_trend_term
    ON trend_items (term, window_end DESC);

CREATE INDEX IF NOT EXISTS idx_trend_window
    ON trend_items (window_end DESC);
