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
