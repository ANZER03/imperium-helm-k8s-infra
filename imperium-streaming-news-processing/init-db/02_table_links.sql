CREATE SEQUENCE IF NOT EXISTS public.tablelinks_id_seq;

CREATE TABLE IF NOT EXISTS public.table_links
(
    id integer NOT NULL DEFAULT nextval('public.tablelinks_id_seq'::regclass),
    link text NOT NULL,
    lastchecked timestamp without time zone NOT NULL DEFAULT now(),
    added_in timestamp without time zone NOT NULL DEFAULT now(),
    news boolean NOT NULL DEFAULT false,
    pub boolean NOT NULL DEFAULT false,
    rss boolean NOT NULL DEFAULT false,
    authority_id integer NOT NULL,
    actif boolean NOT NULL DEFAULT true,
    title text NOT NULL,
    dateformat text,
    added_by integer NOT NULL DEFAULT 0,
    remote_id integer NOT NULL DEFAULT 0,
    langue_id integer NOT NULL DEFAULT 0,
    theme_id integer NOT NULL DEFAULT 0,
    ao boolean NOT NULL DEFAULT false,
    doc boolean NOT NULL DEFAULT false,
    rubrique_id integer NOT NULL DEFAULT 0,
    rubric_path text NOT NULL DEFAULT ''::text,
    rubric_paterne character varying(200) NOT NULL DEFAULT ''::character varying,
    rss_api boolean NOT NULL DEFAULT false,
    pays_id integer NOT NULL DEFAULT 0,
    added_by_app_id integer NOT NULL DEFAULT 0,
    micro_service_id integer,
    standby_until timestamp without time zone,
    CONSTRAINT tablelinks_pk PRIMARY KEY (id)
);

ALTER SEQUENCE public.tablelinks_id_seq OWNED BY public.table_links.id;
