CREATE TABLE IF NOT EXISTS public.debezium_signal
(
    id VARCHAR(50) PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    data VARCHAR(2048) NULL
);
