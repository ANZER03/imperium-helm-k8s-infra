DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'imperium_reference_publication') THEN
        CREATE PUBLICATION imperium_reference_publication FOR TABLE public.table_pays, public.table_langue, public.table_rubrique, public.table_sedition;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'imperium_metadata_publication') THEN
        CREATE PUBLICATION imperium_metadata_publication FOR TABLE public.table_authority, public.table_links, public.debezium_signal;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'imperium_news_publication') THEN
        CREATE PUBLICATION imperium_news_publication FOR TABLE public.table_news, public.debezium_signal;
    END IF;
END
$$;
