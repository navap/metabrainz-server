\set ON_ERROR_STOP 1
BEGIN;

-- A quick crib sheet: when adding a table to the system, quite a few files
-- will need modification.  This isn't a complete list, but should serve as a
-- handy reminder as to most of the files involved:
--   admin/sql/(Create|Drop)Tables.sql
--   admin/sql/(Create|Drop)PrimaryKeys.sql
--   admin/sql/(Create|Drop)Indexes.sql
--   admin/sql/(Create|Drop)FKConstraints.sql
--   admin/SetSequences.pl

-- Add tables in alphabetical order please!

CREATE TABLE donation
(
    id                  SERIAL,
    first_name          VARCHAR(64) NOT NULL,
    last_name           VARCHAR(64) NOT NULL,
    email               VARCHAR(128) NOT NULL,
    moderator           VARCHAR(64) DEFAULT '',
    contact             BOOLEAN DEFAULT 'f',
    anon                BOOLEAN DEFAULT 'f',
    address_street      VARCHAR(255) DEFAULT '',
    address_city        VARCHAR(64) DEFAULT '',
    address_state       VARCHAR(16) DEFAULT '',
    address_postcode    VARCHAR(15) DEFAULT '',
    address_country     VARCHAR(32) DEFAULT '',
    payment_date        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    paypal_trans_id     VARCHAR(32) DEFAULT '',
    amount              DECIMAL(11, 2) NOT NULL,
    fee                 DECIMAL(11, 2) NOT NULL,
    memo                TEXT DEFAULT ''
);

CREATE TABLE donation_historical
(
    id                  SERIAL,
    amount              DECIMAL(11, 2) NOT NULL,
    payment_date        TIMESTAMP WITH TIME ZONE NOT NULL
);


COMMIT;

-- vi: set ts=4 sw=4 et :
