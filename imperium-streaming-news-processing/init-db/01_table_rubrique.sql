CREATE TABLE IF NOT EXISTS public.table_rubrique
(
    id integer NOT NULL,
    sedition_id integer NOT NULL,
    rubrique character varying(200) NOT NULL,
    CONSTRAINT table_rubrique_pk PRIMARY KEY (id)
);
