\set ON_ERROR_STOP 1

-- Alphabetical order by table

ALTER TABLE donation ADD CONSTRAINT donation_pkey PRIMARY KEY (id);
ALTER TABLE "Pending" ADD CONSTRAINT "Pending_pkey" PRIMARY KEY ("SeqId");
ALTER TABLE "PendingData" ADD CONSTRAINT "PendingData_pkey" PRIMARY KEY ("SeqId", "IsKey");
ALTER TABLE replication_control ADD CONSTRAINT replication_control_pkey PRIMARY KEY (id);

-- vi: set ts=4 sw=4 et :
