BEGIN;
SET LOCAL lock_timeout='5s';
CREATE TABLE IF NOT EXISTS public.donation_receipt_emails (
 donation_id varchar(50) PRIMARY KEY REFERENCES public.donations(id),
 provider_id text,
 sent_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now()
);
COMMIT;
