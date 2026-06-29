CREATE TABLE IF NOT EXISTS imperium_articles
(
    article_id text PRIMARY KEY,
    source_news_id integer NOT NULL,
    payload jsonb NOT NULL,
    schema_version integer NOT NULL,
    classification_status text NOT NULL,
    dimension_status text NOT NULL,
    published_at timestamp with time zone,
    crawled_at timestamp with time zone,
    processed_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS imperium_articles_source_news_id_idx
    ON imperium_articles (source_news_id);

-- First-emission upsert contract for issue #14:
--
-- INSERT INTO imperium_articles (
--     article_id, source_news_id, payload, schema_version,
--     classification_status, dimension_status,
--     published_at, crawled_at, processed_at
-- )
-- VALUES (
--     :article_id, :source_news_id, :payload::jsonb, :schema_version,
--     :classification_status, :dimension_status,
--     :published_at, :crawled_at, :processed_at
-- )
-- ON CONFLICT (article_id) DO UPDATE SET
--     source_news_id = EXCLUDED.source_news_id,
--     payload = EXCLUDED.payload,
--     schema_version = EXCLUDED.schema_version,
--     classification_status = EXCLUDED.classification_status,
--     dimension_status = EXCLUDED.dimension_status,
--     published_at = EXCLUDED.published_at,
--     crawled_at = EXCLUDED.crawled_at,
--     processed_at = EXCLUDED.processed_at,
--     updated_at = now();
