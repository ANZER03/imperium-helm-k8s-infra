CREATE TABLE IF NOT EXISTS public.sink_ref_pays
(
    id integer PRIMARY KEY,
    pays character varying(200),
    abr character varying(200)
);

CREATE TABLE IF NOT EXISTS public.sink_ref_langue
(
    id integer PRIMARY KEY,
    langue character varying(200),
    abr character varying(200)
);

CREATE TABLE IF NOT EXISTS public.sink_ref_rubrique
(
    id integer PRIMARY KEY,
    sedition_id integer,
    rubrique character varying(200)
);

CREATE TABLE IF NOT EXISTS public.sink_ref_sedition
(
    id integer PRIMARY KEY,
    support_id integer,
    langue_id integer,
    media_id integer,
    pays_id integer,
    sedition character varying(200)
);

CREATE TABLE IF NOT EXISTS public.sink_meta_authority
(
    id integer PRIMARY KEY,
    authority character varying(100),
    domain character varying(100),
    link character varying(1000),
    news boolean,
    pub boolean,
    rss boolean,
    actif boolean,
    pays_id integer,
    added_in timestamp without time zone
);

CREATE TABLE IF NOT EXISTS public.sink_meta_links
(
    id integer PRIMARY KEY,
    link text,
    authority_id integer,
    title text,
    langue_id integer,
    theme_id integer,
    rubrique_id integer,
    pays_id integer,
    news boolean,
    rss boolean,
    actif boolean,
    lastchecked timestamp without time zone
);

CREATE TABLE IF NOT EXISTS public.sink_news
(
    id integer PRIMARY KEY,
    added_in timestamp without time zone,
    link_id integer,
    authority_id integer,
    rubrique_id integer,
    langue_id integer,
    more_title text,
    more_url text,
    pubdate timestamp without time zone,
    crawl_date timestamp without time zone,
    valide boolean,
    indexed boolean
);
