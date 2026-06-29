CREATE TABLE IF NOT EXISTS public.table_pays
(
    id integer NOT NULL,
    pays character varying(200) NOT NULL,
    abr character varying(200) NOT NULL,
    CONSTRAINT table_pays_pk PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.table_langue
(
    id integer NOT NULL,
    langue character varying(200) NOT NULL,
    abr character varying(200) NOT NULL,
    CONSTRAINT table_langue_pk PRIMARY KEY (id)
);

CREATE SEQUENCE IF NOT EXISTS public.tableauthority_id_seq;

CREATE TABLE IF NOT EXISTS public.table_authority
(
    id integer NOT NULL DEFAULT nextval('public.tableauthority_id_seq'::regclass),
    link character varying(1000),
    valide boolean,
    domain character varying(100),
    news boolean NOT NULL DEFAULT false,
    pub boolean NOT NULL DEFAULT false,
    authority character varying(100) NOT NULL,
    actif boolean NOT NULL DEFAULT true,
    pool_rdp_id_old integer NOT NULL DEFAULT 0,
    pool_adconcept_id integer NOT NULL DEFAULT 0,
    remote_id integer NOT NULL DEFAULT 0,
    sedition_id integer NOT NULL DEFAULT 0,
    rss boolean NOT NULL DEFAULT false,
    ao boolean NOT NULL DEFAULT false,
    doc boolean NOT NULL DEFAULT false,
    website_id integer NOT NULL DEFAULT 0,
    priority_level integer NOT NULL DEFAULT 0,
    added_by integer NOT NULL DEFAULT 0,
    added_by_app_id integer NOT NULL DEFAULT 0,
    added_in timestamp without time zone NOT NULL DEFAULT now(),
    title text NOT NULL DEFAULT ''::text,
    pays_id integer NOT NULL DEFAULT 0,
    sedition_webtv_id integer,
    crawl_proxy boolean,
    use_http_parameters boolean,
    micro_service_id integer,
    CONSTRAINT tablesites_pk PRIMARY KEY (id)
);

ALTER SEQUENCE public.tableauthority_id_seq OWNED BY public.table_authority.id;

CREATE TABLE IF NOT EXISTS public.table_sedition
(
    id integer NOT NULL,
    support_id integer NOT NULL,
    definition_se character varying(200) NOT NULL DEFAULT ''::character varying,
    langue_id integer NOT NULL,
    media_id integer NOT NULL,
    pays_id integer NOT NULL,
    sedition character varying(200) DEFAULT ''::character varying,
    periodicite_id integer NOT NULL DEFAULT 0,
    media_type_id integer NOT NULL DEFAULT 0,
    up_kiosque_bench boolean,
    ispropress boolean NOT NULL DEFAULT false,
    CONSTRAINT table_sedition_pk PRIMARY KEY (id)
);
