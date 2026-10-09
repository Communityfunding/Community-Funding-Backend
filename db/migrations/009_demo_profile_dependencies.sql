-- Add only missing profile/notification dependencies; retain all existing data.
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE public.creators ADD COLUMN IF NOT EXISTS pinned_campaign_id integer
 REFERENCES public.campaigns(campaign_id) ON DELETE SET NULL;
CREATE TABLE IF NOT EXISTS public.interests (
 interest_id serial PRIMARY KEY, name text NOT NULL UNIQUE
);
INSERT INTO public.interests(name) VALUES
 ('Art'),('Comics'),('Crafts'),('Dance'),('Design'),('Entertainment'),('Fashion'),
 ('Film & Video'),('Food'),('Games'),('Journalism'),('Music'),('Photography'),
 ('Publishing'),('Technology'),('Theater') ON CONFLICT(name) DO NOTHING;
CREATE TABLE IF NOT EXISTS public.creator_interests (
 creator_id text NOT NULL REFERENCES public.creators(creator_id) ON DELETE CASCADE,
 interest_id integer NOT NULL REFERENCES public.interests(interest_id) ON DELETE CASCADE,
 PRIMARY KEY(creator_id,interest_id)
);
CREATE TABLE IF NOT EXISTS public.creator_follows (
 follower_creator_id text NOT NULL REFERENCES public.creators(creator_id) ON DELETE CASCADE,
 followed_creator_id text NOT NULL REFERENCES public.creators(creator_id) ON DELETE CASCADE,
 time_created timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(follower_creator_id,followed_creator_id),
 CHECK(follower_creator_id <> followed_creator_id)
);
CREATE INDEX IF NOT EXISTS creator_follows_target_idx ON public.creator_follows(followed_creator_id);
CREATE TABLE IF NOT EXISTS public.notifications (
 notification_id bigserial PRIMARY KEY,
 recipient_creator_id text NOT NULL REFERENCES public.creators(creator_id),
 actor_creator_id text REFERENCES public.creators(creator_id),
 type text NOT NULL, source_type text NOT NULL, source_key text NOT NULL,
 title text NOT NULL, body text, link_url text,
 campaign_id integer REFERENCES public.campaigns(campaign_id) ON DELETE SET NULL,
 comment_id text REFERENCES public.comments(id) ON DELETE SET NULL,
 collaborator_id bigint REFERENCES public.collaborators(collaborator_id) ON DELETE SET NULL,
 is_read boolean NOT NULL DEFAULT false, is_deleted boolean NOT NULL DEFAULT false,
 time_created timestamptz NOT NULL DEFAULT now(),
 UNIQUE(recipient_creator_id,source_type,source_key)
);
COMMIT;
