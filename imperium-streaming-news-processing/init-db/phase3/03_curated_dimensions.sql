CREATE TABLE IF NOT EXISTS imperium_dim_links
(
    link_id integer PRIMARY KEY,
    url text,
    source_domain text,
    source_name text,
    country_id integer,
    is_active boolean NOT NULL DEFAULT true,
    payload jsonb NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS imperium_dim_authorities
(
    authority_id integer PRIMARY KEY,
    source_name text,
    source_domain text,
    sedition_id integer,
    is_active boolean NOT NULL DEFAULT true,
    payload jsonb NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS imperium_dim_seditions
(
    sedition_id integer PRIMARY KEY,
    country_id integer,
    is_active boolean NOT NULL DEFAULT true,
    payload jsonb NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS imperium_dim_countries
(
    country_id integer PRIMARY KEY,
    country_name text,
    is_active boolean NOT NULL DEFAULT true,
    payload jsonb NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS imperium_dim_rubrics
(
    rubric_id integer PRIMARY KEY,
    rubric_title text,
    is_active boolean NOT NULL DEFAULT true,
    payload jsonb NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS imperium_dim_languages
(
    language_id integer PRIMARY KEY,
    language_code text,
    is_active boolean NOT NULL DEFAULT true,
    payload jsonb NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);
