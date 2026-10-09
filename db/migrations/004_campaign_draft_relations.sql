-- Draft relations from the team's schema at 85d589f6, adapted for an
-- existing demo database: additive only, with generated IDs and FKs.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS public.faqs (
    campaign_id bigint NOT NULL REFERENCES public.campaigns(campaign_id),
    display_order integer NOT NULL,
    question text NOT NULL,
    answer text NOT NULL,
    PRIMARY KEY (campaign_id, display_order)
);
CREATE TABLE IF NOT EXISTS public.rewards (
    reward_id bigserial PRIMARY KEY,
    campaign_id bigint NOT NULL REFERENCES public.campaigns(campaign_id),
    title varchar(100) NOT NULL,
    required_amount_cents bigint NOT NULL CHECK (required_amount_cents > 0),
    description text NOT NULL,
    limit_total integer CHECK (limit_total > 0),
    display_order integer NOT NULL
);
CREATE TABLE IF NOT EXISTS public.collaborators (
    collaborator_id bigserial PRIMARY KEY,
    campaign_id bigint NOT NULL REFERENCES public.campaigns(campaign_id),
    email text NOT NULL,
    status text NOT NULL CHECK (status IN ('pending', 'accepted', 'declined')),
    time_created timestamptz NOT NULL DEFAULT now()
);
COMMIT;
