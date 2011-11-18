-- Automatically generated, do not edit.
\unset ON_ERROR_STOP

SELECT setval('donation_id_seq', (SELECT MAX(id) FROM donation));
SELECT setval('donation_historical_id_seq', (SELECT MAX(id) FROM donation_historical));
