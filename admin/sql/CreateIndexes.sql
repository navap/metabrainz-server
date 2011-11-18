\set ON_ERROR_STOP 1
BEGIN;

CREATE INDEX "Pending_XID_Index" ON "Pending" USING btree ("XID");
CREATE INDEX donation_email ON donation USING btree (email);
CREATE INDEX donation_moderator ON donation USING btree (moderator);
CREATE INDEX donation_payment_date ON donation USING btree (payment_date);
CREATE INDEX donation_paypal_trans_id ON donation USING btree (paypal_trans_id);

COMMIT;
