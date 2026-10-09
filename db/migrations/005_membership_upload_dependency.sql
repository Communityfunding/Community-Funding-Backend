-- The upload authorization query joins organization_members even for
-- individually owned campaigns. Shape from team schema 85d589f6.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS public.organization_members (
    member_id text NOT NULL REFERENCES public.creators(creator_id),
    organization_id text NOT NULL REFERENCES public.creators(creator_id),
    role varchar(32) NOT NULL DEFAULT 'viewer',
    added_by varchar(255) REFERENCES public.creators(creator_id),
    added_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (member_id, organization_id),
    CHECK (member_id <> organization_id),
    CHECK (role IN ('owner', 'admin', 'finance', 'campaign_editor', 'viewer'))
);
COMMIT;
