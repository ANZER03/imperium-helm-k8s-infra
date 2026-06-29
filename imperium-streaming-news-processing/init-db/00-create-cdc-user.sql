-- Create replication user for CDC
CREATE ROLE debezium WITH REPLICATION LOGIN PASSWORD 'debezium-secret';
-- Grant membership of db owner to cdc user so it can manage replication publications
GRANT imperium TO debezium;
-- Grant permissions on schema/tables
GRANT USAGE ON SCHEMA public TO debezium;
GRANT ALL PRIVILEGES ON SCHEMA public TO debezium;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium;
