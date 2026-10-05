-- Reconcile the legacy creators bootstrap with the current User ORM.
-- Preflight: user_type values must be NULL or integer strings.
-- Tested against the empty Railway demo creators table on 2026-10-05.
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE public.creators
    ADD COLUMN IF NOT EXISTS username varchar(30),
    ADD COLUMN IF NOT EXISTS avatar_url text,
    ADD COLUMN IF NOT EXISTS website varchar(500);
ALTER TABLE public.creators
    ALTER COLUMN user_type TYPE integer USING user_type::integer,
    ALTER COLUMN user_type SET DEFAULT 0;
CREATE UNIQUE INDEX IF NOT EXISTS creators_username_unique
    ON public.creators (username);
COMMIT;
