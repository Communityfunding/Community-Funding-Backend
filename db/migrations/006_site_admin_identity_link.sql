-- Explicitly links existing administrator grants to verified Clerk subjects.
-- No account is promoted by this migration. Provisioning requires owner approval.
DO $$
BEGIN
    IF to_regclass('public.site_admins') IS NOT NULL THEN
        ALTER TABLE public.site_admins ADD COLUMN IF NOT EXISTS clerk_user_id text;
        CREATE UNIQUE INDEX IF NOT EXISTS site_admins_clerk_user_id_unique
            ON public.site_admins (clerk_user_id);
    END IF;
END $$;
