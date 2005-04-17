\set ON_ERROR_STOP 1

-- Alphabetical order by table

CREATE INDEX donation_email ON donation (email);
CREATE INDEX donation_moderator ON donation (moderator);
CREATE INDEX donation_payment_date ON donation (payment_date);
CREATE INDEX donation_paypal_trans_id ON donation (paypal_trans_id);

CREATE INDEX "Pending_XID_Index" ON "Pending" ("XID");

-- vi: set ts=4 sw=4 et :
