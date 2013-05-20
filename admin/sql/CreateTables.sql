\set ON_ERROR_STOP 1
BEGIN;

CREATE TABLE "Pending" (
    "SeqId"     SERIAL NOT NULL, -- PK
    "TableName" CHARACTER VARYING NOT NULL,
    "Op"        CHARACTER(1),
    "XID"       INTEGER NOT NULL
);

CREATE TABLE "PendingData" (
    "SeqId" INTEGER NOT NULL, -- PK
    "IsKey" BOOLEAN NOT NULL,
    "Data" CHARACTER VARYING
);

CREATE TABLE donation (
    id               serial NOT NULL, -- PK
    first_name       text NOT NULL,
    last_name        text NOT NULL,
    email            text NOT NULL,
    moderator        text DEFAULT '',
    contact          boolean DEFAULT false,
    anon             boolean DEFAULT false,
    address_street   text DEFAULT '',
    address_city     text DEFAULT '',
    address_state    text DEFAULT '',
    address_postcode text DEFAULT '',
    address_country  text DEFAULT '',
    payment_date     timestamp with time zone DEFAULT now(),
    paypal_trans_id  character varying(32) DEFAULT '',
    amount           numeric(11,2) NOT NULL,
    fee              numeric(11,2) NOT NULL,
    memo             text DEFAULT ''
);

CREATE TABLE donation_historical (
    id           serial NOT NULL, -- PK
    amount       numeric(11,2) NOT NULL,
    payment_date timestamp with time zone NOT NULL
);

CREATE TABLE replication_control (
    id                           integer NOT NULL, -- PK
    current_schema_sequence      integer NOT NULL,
    current_replication_sequence integer,
    last_replication_date        timestamp with time zone
);

COMMIT;
