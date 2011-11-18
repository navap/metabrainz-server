-- Automatically generated, do not edit.
\set ON_ERROR_STOP 1

ALTER TABLE donation ADD CONSTRAINT donation_pkey PRIMARY KEY (id);
ALTER TABLE donation_historical ADD CONSTRAINT donation_historical_pkey PRIMARY KEY (id);
ALTER TABLE replication_control ADD CONSTRAINT replication_control_pkey PRIMARY KEY (id);
