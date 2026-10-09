-- Current submission code stores one Fernet-encrypted JSON blob per campaign.
-- Adds an empty table only; never stores plaintext account/routing numbers.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS public.bank_details (
 campaign_id integer PRIMARY KEY REFERENCES public.campaigns(campaign_id),
 fermat_key text NOT NULL,
 account_type text NOT NULL CHECK (account_type IN ('individual','business'))
);
COMMIT;
