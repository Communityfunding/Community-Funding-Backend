-- Provision the administrative tables without granting anyone a role.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS public.site_admins (
    admin_id serial PRIMARY KEY,
    username text NOT NULL UNIQUE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    hashed_password text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    time_created timestamptz NOT NULL DEFAULT now(),
    last_login timestamptz,
    status varchar(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','approved','rejected')),
    clerk_user_id text UNIQUE
);
ALTER TABLE public.site_admins ADD COLUMN IF NOT EXISTS clerk_user_id text;
CREATE UNIQUE INDEX IF NOT EXISTS site_admins_clerk_user_id_unique
    ON public.site_admins(clerk_user_id);
CREATE TABLE IF NOT EXISTS public.admin_activity_log (
    log_id serial PRIMARY KEY,
    admin_id integer NOT NULL REFERENCES public.site_admins(admin_id),
    action text NOT NULL,
    target_type text,
    target_id text,
    details text,
    time_created timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.campaigns
    ADD COLUMN IF NOT EXISTS reviewed_by integer REFERENCES public.site_admins(admin_id),
    ADD COLUMN IF NOT EXISTS reviewed_at timestamptz,
    ADD COLUMN IF NOT EXISTS rejected_reason text;
COMMIT;
