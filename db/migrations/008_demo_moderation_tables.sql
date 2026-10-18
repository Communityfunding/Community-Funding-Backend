-- Additive moderation schema used by the existing report routes.
-- Does not migrate/drop the older generic reports table or change any roles.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS public.campaign_reports (
 report_id bigserial PRIMARY KEY,
 reporter_creator_id text REFERENCES creators(creator_id),
 reported_campaign_id integer REFERENCES campaigns(campaign_id),
 reported_campaign_creator_id text,
 reported_campaign_creator_name text, reported_campaign_creator_last_name text,
 reported_campaign_creator_username text, reported_campaign_creator_user_type integer,
 reported_campaign_title_snapshot text, reported_campaign_status_snapshot text,
 reported_campaign_url_snapshot text, reported_campaign_description_html_snapshot text,
 reported_campaign_category_snapshot text, reported_campaign_location_snapshot text,
 reported_campaign_funding_goal_cents_snapshot bigint,
 reported_campaign_duration_days_snapshot integer,
 reported_campaign_amount_raised_cents_snapshot bigint,
 reported_campaign_backers_snapshot integer,
 reported_campaign_time_created_snapshot timestamptz,
 reported_campaign_end_date_snapshot timestamptz, reported_campaign_bio_snapshot text,
 reason text, notes text, status text NOT NULL DEFAULT 'open',
 time_reported timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.comment_reports (
 report_id bigserial PRIMARY KEY,
 reporter_creator_id text REFERENCES creators(creator_id),
 reported_campaign_id integer REFERENCES campaigns(campaign_id),
 reported_comment_id text,
 reported_comment_creator_id text,
 reported_comment_creator_name text, reported_comment_creator_last_name text,
 reported_comment_creator_username text, reported_comment_text_snapshot text,
 reported_comment_time_created timestamptz, reported_comment_updated_at_snapshot timestamptz,
 reason text, notes text, status text NOT NULL DEFAULT 'open',
 time_reported timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.profile_reports (
 report_id bigserial PRIMARY KEY,
 reporter_creator_id text REFERENCES creators(creator_id),
 reported_profile_creator_id text REFERENCES creators(creator_id),
 reported_profile_user_type integer,
 reported_profile_name text, reported_profile_last_name text,
 reported_profile_username text, reported_profile_bio_snapshot text,
 reported_profile_website_snapshot text, reported_profile_avatar_url_snapshot text,
 reported_profile_time_creation_snapshot timestamptz,
 reason text, notes text, status text NOT NULL DEFAULT 'open',
 time_reported timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.misc_reports (
 report_id bigserial PRIMARY KEY, creator_id text REFERENCES creators(creator_id),
 report_description text NOT NULL, report_reason text NOT NULL,
 reported_content_url text, status text NOT NULL DEFAULT 'open',
 time_created timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.blocked_users (
 block_id bigserial PRIMARY KEY,
 creator_id text NOT NULL REFERENCES creators(creator_id),
 reason text, blocked_by integer REFERENCES site_admins(admin_id),
 ban_type text NOT NULL DEFAULT 'full_ban'
   CHECK (ban_type IN ('warning','soft_ban','full_ban')),
 blocked_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS blocked_users_creator_idx ON blocked_users(creator_id);
ALTER TABLE public.creators ADD COLUMN IF NOT EXISTS warning_count integer NOT NULL DEFAULT 0;
COMMIT;
