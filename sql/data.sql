CREATE SCHEMA IF NOT EXISTS bridges;

--'chain' is chain the txs are on; for mint/burn bridges with 1 destination, can use 'destination chain' to have its flows counted on that chain but inverted
CREATE TABLE IF NOT EXISTS bridges.config (
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid (),
    bridge_name varchar NOT NULL,
    chain varchar NOT NULL,
    destination_chain varchar,  --only non-NULL when there is single destination chain for mint/burn bridge, and the destination chain is not tracked by adapters
    UNIQUE (bridge_name, chain)
);

--chain is the chain tx is on
CREATE TABLE IF NOT EXISTS bridges.transactions (
    id INT GENERATED ALWAYS AS IDENTITY,
    bridge_id uuid NOT NULL,
    tx_hash VARCHAR,
    ts TIMESTAMPTZ NOT NULL,
    tx_block INTEGER,
    tx_from VARCHAR,
    tx_to VARCHAR,
    token VARCHAR NOT NULL,
    amount VARCHAR NOT NULL,
    is_deposit BOOLEAN NOT NULL,
    chain VARCHAR NOT NULL,
    is_usd_volume BOOLEAN,
    txs_counted_as INTEGER,
    origin_chain VARCHAR,
    
    PRIMARY KEY(id),
    UNIQUE (bridge_id, chain, tx_hash, token, tx_from, tx_to),
    CONSTRAINT fk_bridge_id
        FOREIGN KEY(bridge_id)
            REFERENCES bridges.config(id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS transactions_ts ON bridges.transactions (ts);

CREATE TYPE token_total AS (
    token           VARCHAR,
    amount          VARCHAR,
    usd_value       NUMERIC
);

CREATE TYPE address_total AS (
    address         VARCHAR,
    usd_value       NUMERIC,
    txs             INT
);

CREATE TABLE IF NOT EXISTS bridges.hourly_aggregated (
    id INT GENERATED ALWAYS AS IDENTITY,
    bridge_id uuid NOT NULL,
    ts TIMESTAMPTZ NOT NULL,
    total_tokens_deposited token_total [],
    total_tokens_withdrawn token_total [],
    total_deposited_usd NUMERIC,
    total_withdrawn_usd NUMERIC,
    total_deposit_txs INTEGER,
    total_withdrawal_txs INTEGER,
    total_address_deposited address_total [],
    total_address_withdrawn address_total [],
    PRIMARY KEY(id),
    UNIQUE (bridge_id, ts),
    CONSTRAINT fk_bridge_id
        FOREIGN KEY(bridge_id)
            REFERENCES bridges.config(id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS hourly_aggregated_ts ON bridges.hourly_aggregated (ts);

CREATE TABLE IF NOT EXISTS bridges.large_transactions (
    id INT GENERATED ALWAYS AS IDENTITY,
    tx_pk INT UNIQUE NOT NULL,
    usd_value NUMERIC NOT NULL,
    ts TIMESTAMPTZ NOT NULL,
    PRIMARY KEY(id),
    CONSTRAINT fk_tx_pk
        FOREIGN KEY(tx_pk)
            REFERENCES bridges.transactions(id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS large_transactions_ts ON bridges.large_transactions (ts);

CREATE TABLE IF NOT EXISTS bridges.daily_aggregated (
    id INT GENERATED ALWAYS AS IDENTITY,
    bridge_id uuid NOT NULL,
    ts TIMESTAMPTZ NOT NULL,
    total_tokens_deposited token_total [],
    total_tokens_withdrawn token_total [],
    total_deposited_usd NUMERIC,
    total_withdrawn_usd NUMERIC,
    total_deposit_txs INTEGER,
    total_withdrawal_txs INTEGER,
    total_address_deposited address_total [],
    total_address_withdrawn address_total [],
    PRIMARY KEY(id),
    UNIQUE (bridge_id, ts),
    CONSTRAINT fk_bridge_id
        FOREIGN KEY(bridge_id)
            REFERENCES bridges.config(id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS daily_aggregated_ts ON bridges.daily_aggregated (ts);

--'target table' can be one of "transactions", "config", "hourly_aggregated", "daily_aggregated", "large_transactions", "none"
--'keyword' can be one of "critical", "data" (missing), 
CREATE TABLE IF NOT EXISTS bridges.errors (
    id INT GENERATED ALWAYS AS IDENTITY,
    ts TIMESTAMPTZ NOT NULL,
    target_table varchar,
    keyword varchar,
    error varchar,
    UNIQUE (ts, error)
);

CREATE INDEX IF NOT EXISTS errors_ts ON bridges.errors (ts);

CREATE TABLE IF NOT EXISTS bridges.hourly_volume (
    id INT GENERATED ALWAYS AS IDENTITY,
    bridge_id uuid NOT NULL,
    ts TIMESTAMPTZ NOT NULL,
    total_deposited_usd NUMERIC,
    total_withdrawn_usd NUMERIC,
    total_deposit_txs INTEGER,
    total_withdrawal_txs INTEGER,
    chain VARCHAR NOT NULL,
    PRIMARY KEY(id),
    UNIQUE (bridge_id, ts, chain),
    CONSTRAINT fk_bridge_id
        FOREIGN KEY(bridge_id)
            REFERENCES bridges.config(id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS hourly_volume_ts ON bridges.hourly_volume (ts);
CREATE INDEX IF NOT EXISTS hourly_volume_chain ON bridges.hourly_volume (chain);

CREATE INDEX IF NOT EXISTS hourly_volume_bridge_ts_chain ON bridges.hourly_volume (bridge_id, ts, chain);
CREATE INDEX IF NOT EXISTS config_bridge_name_id ON bridges.config (bridge_name, id);

CREATE TABLE IF NOT EXISTS bridges.daily_volume (
    id INT GENERATED ALWAYS AS IDENTITY,
    bridge_id uuid NOT NULL,
    ts TIMESTAMPTZ NOT NULL,
    total_deposited_usd NUMERIC,
    total_withdrawn_usd NUMERIC,
    total_deposit_txs INTEGER,
    total_withdrawal_txs INTEGER,
    chain VARCHAR NOT NULL,
    PRIMARY KEY(id),
    UNIQUE (bridge_id, ts, chain),
    CONSTRAINT fk_bridge_id
        FOREIGN KEY(bridge_id)
            REFERENCES bridges.config(id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS daily_volume_ts ON bridges.daily_volume (ts);
CREATE INDEX IF NOT EXISTS daily_volume_chain ON bridges.daily_volume (chain);
CREATE INDEX IF NOT EXISTS daily_volume_bridge_ts_chain ON bridges.daily_volume (bridge_id, ts, chain);
