-- Add the missing saved-campaign relation without altering existing records.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS public.saved_campaigns (
 creator_id text NOT NULL REFERENCES public.creators(creator_id) ON DELETE CASCADE,
 campaign_id integer NOT NULL REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE,
 engagement_type integer NOT NULL DEFAULT 1,
 time_created timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(creator_id, campaign_id)
);
COMMIT;
