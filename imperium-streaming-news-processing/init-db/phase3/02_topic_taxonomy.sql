CREATE TABLE IF NOT EXISTS imperium_topic_taxonomy
(
    topic_id          text PRIMARY KEY,
    parent_topic_id   text REFERENCES imperium_topic_taxonomy (topic_id),
    topic_key         text NOT NULL,
    display_name      text NOT NULL,
    description       text NOT NULL,
    taxonomy_version  text NOT NULL,
    is_active         boolean NOT NULL DEFAULT true,
    review_status     text NOT NULL DEFAULT 'draft',
    -- Rich taxonomy fields from medtop JSON
    embedding_seeds   jsonb NOT NULL DEFAULT '[]'::jsonb,
    signals_strong    jsonb NOT NULL DEFAULT '[]'::jsonb,
    signals_medium    jsonb NOT NULL DEFAULT '[]'::jsonb,
    signals_weak      jsonb NOT NULL DEFAULT '[]'::jsonb,
    dimensions_event  jsonb NOT NULL DEFAULT '[]'::jsonb,
    dimensions_impact jsonb NOT NULL DEFAULT '[]'::jsonb,
    dimensions_actors jsonb NOT NULL DEFAULT '[]'::jsonb,
    reviewed_by       text,
    reviewed_at       timestamp with time zone,
    created_at        timestamp with time zone NOT NULL DEFAULT now(),
    updated_at        timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT imperium_topic_taxonomy_topic_key_version_key
        UNIQUE (topic_key, taxonomy_version),
    CONSTRAINT imperium_topic_taxonomy_review_status_check
        CHECK (review_status IN ('draft', 'approved', 'rejected'))
);

CREATE INDEX IF NOT EXISTS imperium_topic_taxonomy_parent_idx
    ON imperium_topic_taxonomy (parent_topic_id);

CREATE INDEX IF NOT EXISTS imperium_topic_taxonomy_active_version_idx
    ON imperium_topic_taxonomy (taxonomy_version, is_active);

CREATE TABLE IF NOT EXISTS imperium_topic_embeddings
(
    topic_id             text NOT NULL REFERENCES imperium_topic_taxonomy (topic_id),
    taxonomy_version     text NOT NULL,
    embedding_model      text NOT NULL,
    embedding_dimension  integer NOT NULL,
    embedding_input_text text NOT NULL,
    embedding_input_hash text NOT NULL,
    embedding_vector     double precision[] NOT NULL,
    is_active            boolean NOT NULL DEFAULT true,
    created_at           timestamp with time zone NOT NULL DEFAULT now(),
    updated_at           timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (topic_id, taxonomy_version, embedding_model)
);

CREATE INDEX IF NOT EXISTS imperium_topic_embeddings_active_idx
    ON imperium_topic_embeddings (taxonomy_version, embedding_model, is_active);
