--
-- PostgreSQL database dump
--

\restrict HKXIvMC9aPITuKOFIfZ22Xgn53L2YPgYUe3c0lUvKoIOkqhLKjfGe3TuIHYJgWm

-- Dumped from database version 17.9
-- Dumped by pg_dump version 17.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_activity_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_activity_log (
    log_id integer NOT NULL,
    admin_id integer NOT NULL,
    action text NOT NULL,
    target_type text,
    target_id text,
    details text,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_activity_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_activity_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_activity_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_activity_log_log_id_seq OWNED BY public.admin_activity_log.log_id;


--
-- Name: bank_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bank_details (
    campaign_id bigint NOT NULL,
    fermat_key text NOT NULL,
    account_type text NOT NULL,
    CONSTRAINT bank_details_account_type_check CHECK ((account_type = ANY (ARRAY['individual'::text, 'business'::text])))
);


--
-- Name: blocked_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blocked_users (
    ban_id integer NOT NULL,
    creator_id text NOT NULL,
    reason text,
    blocked_by integer,
    blocked_at timestamp with time zone DEFAULT now() NOT NULL,
    ban_type character varying(20) DEFAULT 'full_ban'::character varying NOT NULL,
    block_id integer GENERATED ALWAYS AS (ban_id) STORED
);


--
-- Name: blocked_users_ban_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blocked_users_ban_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blocked_users_ban_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blocked_users_ban_id_seq OWNED BY public.blocked_users.ban_id;


--
-- Name: campaign_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_photos (
    photo_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    s3_bucket text NOT NULL,
    s3_key text NOT NULL,
    content_type text,
    file_size_bytes bigint,
    width_px integer,
    height_px integer,
    is_primary boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    uploaded_by_creator_id text,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT campaign_photos_file_size_bytes_check CHECK ((file_size_bytes >= 0)),
    CONSTRAINT campaign_photos_height_px_check CHECK ((height_px >= 0)),
    CONSTRAINT campaign_photos_width_px_check CHECK ((width_px >= 0))
);


--
-- Name: campaign_photos_photo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaign_photos_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaign_photos_photo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaign_photos_photo_id_seq OWNED BY public.campaign_photos.photo_id;


--
-- Name: campaign_report_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_report_photos (
    report_photo_id bigint NOT NULL,
    report_id bigint NOT NULL,
    reported_photo_id bigint,
    reported_campaign_id bigint,
    s3_bucket_snapshot text,
    s3_key_snapshot text,
    image_url_snapshot text,
    content_type_snapshot text,
    file_size_bytes_snapshot bigint,
    width_px_snapshot integer,
    height_px_snapshot integer,
    is_primary_snapshot boolean,
    sort_order_snapshot integer,
    uploaded_by_creator_id_snapshot text,
    photo_time_created_snapshot timestamp with time zone,
    time_snapshotted timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaign_report_photos_report_photo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaign_report_photos_report_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaign_report_photos_report_photo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaign_report_photos_report_photo_id_seq OWNED BY public.campaign_report_photos.report_photo_id;


--
-- Name: campaign_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_reports (
    report_id bigint NOT NULL,
    reporter_creator_id text NOT NULL,
    reported_campaign_id bigint,
    reported_campaign_creator_id text,
    reported_campaign_creator_name text,
    reported_campaign_creator_last_name text,
    reported_campaign_creator_username text,
    reported_campaign_creator_user_type smallint,
    reported_campaign_title_snapshot text NOT NULL,
    reported_campaign_status_snapshot text,
    reported_campaign_url_snapshot text,
    reported_campaign_description_html_snapshot text,
    reported_campaign_category_snapshot text,
    reported_campaign_location_snapshot text,
    reported_campaign_funding_goal_cents_snapshot bigint,
    reported_campaign_duration_days_snapshot integer,
    reported_campaign_amount_raised_cents_snapshot bigint,
    reported_campaign_backers_snapshot integer,
    reported_campaign_time_created_snapshot timestamp with time zone,
    reported_campaign_end_date_snapshot timestamp with time zone,
    reported_campaign_bio_snapshot text,
    reason text,
    notes text,
    status text DEFAULT 'open'::text NOT NULL,
    time_reported timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaign_reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaign_reports_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaign_reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaign_reports_report_id_seq OWNED BY public.campaign_reports.report_id;


--
-- Name: campaign_type_map; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_type_map (
    campaign_id bigint NOT NULL,
    type_id bigint NOT NULL
);


--
-- Name: campaign_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_types (
    type_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaign_types_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaign_types_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaign_types_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaign_types_type_id_seq OWNED BY public.campaign_types.type_id;


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    campaign_id bigint NOT NULL,
    creator_id text NOT NULL,
    title character varying(100) NOT NULL,
    status text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    url text,
    description_html text,
    category text,
    location text,
    funding_goal_cents bigint DEFAULT 0,
    duration_days integer,
    amount_raised_cents bigint DEFAULT 0,
    backers integer DEFAULT 0,
    end_date timestamp with time zone,
    bio text,
    description text,
    rejected_reason text,
    reviewed_by integer,
    reviewed_at timestamp with time zone
);


--
-- Name: campaigns_campaign_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaigns_campaign_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_campaign_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaigns_campaign_id_seq OWNED BY public.campaigns.campaign_id;


--
-- Name: collaborators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collaborators (
    collaborator_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    email text NOT NULL,
    status text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT collaborators_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text])))
);


--
-- Name: collaborators_collaborator_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collaborators_collaborator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collaborators_collaborator_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collaborators_collaborator_id_seq OWNED BY public.collaborators.collaborator_id;


--
-- Name: comment_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment_likes (
    comment_id bigint NOT NULL,
    creator_id text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: comment_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment_reports (
    report_id bigint NOT NULL,
    reporter_creator_id text NOT NULL,
    reported_comment_id bigint,
    reported_campaign_id bigint,
    reported_comment_creator_id text,
    reported_comment_creator_name text,
    reported_comment_creator_last_name text,
    reported_comment_creator_username text,
    reported_comment_text_snapshot text NOT NULL,
    reported_comment_time_created timestamp with time zone,
    reported_comment_updated_at_snapshot timestamp with time zone,
    reason text,
    notes text,
    status text DEFAULT 'open'::text NOT NULL,
    time_reported timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: comment_reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comment_reports_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comment_reports_report_id_seq OWNED BY public.comment_reports.report_id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    comment_id bigint NOT NULL,
    comment_text text NOT NULL,
    creator_id text NOT NULL,
    campaign_id bigint NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    parent_comment_id integer,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    reply_to_comment_id integer,
    is_deleted boolean DEFAULT false,
    deleted_at timestamp with time zone,
    deleted_by_admin_id integer,
    is_hidden boolean DEFAULT false,
    CONSTRAINT comments_comment_text_check CHECK ((length(TRIM(BOTH FROM comment_text)) > 0))
);


--
-- Name: comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comment_id_seq OWNED BY public.comments.comment_id;


--
-- Name: creator_follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.creator_follows (
    follower_creator_id text NOT NULL,
    followed_creator_id text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT creator_follows_check CHECK ((follower_creator_id <> followed_creator_id))
);


--
-- Name: creator_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.creator_interests (
    creator_id text NOT NULL,
    interest_id bigint NOT NULL
);


--
-- Name: creators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.creators (
    creator_id text NOT NULL,
    user_type smallint NOT NULL,
    name text NOT NULL,
    last_name text,
    email text,
    bio text,
    time_creation timestamp with time zone DEFAULT now() NOT NULL,
    phone_number text,
    address text,
    state text,
    time_zone text,
    hashed_password text,
    website text,
    avatar_url text,
    username text,
    pinned_campaign_id bigint,
    is_admin boolean DEFAULT false,
    warning_count integer DEFAULT 0,
    stripe_customer_id text,
    stripe_connect_account_id text,
    stripe_connect_onboarded boolean DEFAULT false,
    CONSTRAINT creators_user_type_check CHECK ((user_type = ANY (ARRAY[0, 1]))),
    CONSTRAINT creators_username_not_same_as_other_creator_id_chk CHECK ((btrim(username) <> ''::text))
);


--
-- Name: deleted_campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deleted_campaigns (
    deletion_id integer NOT NULL,
    campaign_id bigint NOT NULL,
    title text,
    creator_id text,
    reason text,
    deleted_by integer,
    deleted_at timestamp with time zone DEFAULT now() NOT NULL,
    original_status text
);


--
-- Name: deleted_campaigns_deletion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deleted_campaigns_deletion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deleted_campaigns_deletion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deleted_campaigns_deletion_id_seq OWNED BY public.deleted_campaigns.deletion_id;


--
-- Name: donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.donations (
    donation_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    donor_creator_id text NOT NULL,
    amount numeric(12,2) NOT NULL,
    status text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    donor_name text,
    donor_email text,
    is_anonymous boolean DEFAULT false,
    message text,
    platform_fee numeric,
    net_amount numeric,
    currency text DEFAULT 'usd'::text,
    stripe_payment_intent_id text,
    stripe_checkout_session_id text,
    stripe_charge_id text,
    CONSTRAINT donations_amount_check CHECK ((amount > (0)::numeric))
);


--
-- Name: donations_donation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.donations_donation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donations_donation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.donations_donation_id_seq OWNED BY public.donations.donation_id;


--
-- Name: faqs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faqs (
    campaign_id bigint NOT NULL,
    display_order integer NOT NULL,
    question text NOT NULL,
    answer text NOT NULL
);


--
-- Name: fees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fees (
    fee_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    donation_id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fees_amount_check CHECK ((amount >= (0)::numeric))
);


--
-- Name: fees_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fees_fee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fees_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fees_fee_id_seq OWNED BY public.fees.fee_id;


--
-- Name: interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interests (
    interest_id bigint NOT NULL,
    name text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: interests_interest_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interests_interest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interests_interest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interests_interest_id_seq OWNED BY public.interests.interest_id;


--
-- Name: misc_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.misc_reports (
    report_id bigint NOT NULL,
    creator_id text NOT NULL,
    report_description text NOT NULL,
    report_reason text NOT NULL,
    reported_content_url text,
    status text DEFAULT 'open'::text NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: misc_reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.misc_reports_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: misc_reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.misc_reports_report_id_seq OWNED BY public.misc_reports.report_id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    notification_id bigint NOT NULL,
    recipient_creator_id text NOT NULL,
    actor_creator_id text,
    type text NOT NULL,
    source_type text NOT NULL,
    source_key text NOT NULL,
    title text NOT NULL,
    body text,
    link_url text,
    campaign_id bigint,
    comment_id bigint,
    collaborator_id bigint,
    is_read boolean DEFAULT false NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_notification_id_seq OWNED BY public.notifications.notification_id;


--
-- Name: organization_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_members (
    member_id text NOT NULL,
    organization_id text NOT NULL,
    role character varying(32) DEFAULT 'viewer'::character varying NOT NULL,
    added_by character varying(255),
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_no_self_membership CHECK ((member_id <> organization_id)),
    CONSTRAINT organization_members_role_check CHECK (((role)::text = ANY ((ARRAY['owner'::character varying, 'admin'::character varying, 'finance'::character varying, 'campaign_editor'::character varying, 'viewer'::character varying])::text[])))
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    payment_id bigint NOT NULL,
    donation_id bigint,
    processor text DEFAULT 'stripe'::text NOT NULL,
    status text NOT NULL,
    time_captured timestamp with time zone,
    time_settled timestamp with time zone,
    time_created timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_payment_id_seq OWNED BY public.payments.payment_id;


--
-- Name: payouts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payouts (
    payout_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    payee_creator_id text NOT NULL,
    amount numeric(12,2) NOT NULL,
    time_initiated timestamp with time zone,
    time_paid timestamp with time zone,
    CONSTRAINT payouts_amount_check CHECK ((amount > (0)::numeric))
);


--
-- Name: payouts_payout_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payouts_payout_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payouts_payout_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payouts_payout_id_seq OWNED BY public.payouts.payout_id;


--
-- Name: profile_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_reports (
    report_id bigint NOT NULL,
    reporter_creator_id text NOT NULL,
    reported_profile_creator_id text,
    reported_profile_user_type smallint,
    reported_profile_name text,
    reported_profile_last_name text,
    reported_profile_username text,
    reported_profile_bio_snapshot text,
    reported_profile_website_snapshot text,
    reported_profile_avatar_url_snapshot text,
    reported_profile_time_creation_snapshot timestamp with time zone,
    reason text,
    notes text,
    status text DEFAULT 'open'::text NOT NULL,
    time_reported timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: profile_reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_reports_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_reports_report_id_seq OWNED BY public.profile_reports.report_id;


--
-- Name: refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refunds (
    refund_id bigint NOT NULL,
    donation_id bigint NOT NULL,
    payment_id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    status text NOT NULL,
    time_initiated timestamp with time zone DEFAULT now() NOT NULL,
    time_paid timestamp with time zone,
    CONSTRAINT refunds_amount_check CHECK ((amount > (0)::numeric))
);


--
-- Name: refunds_refund_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refunds_refund_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refunds_refund_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refunds_refund_id_seq OWNED BY public.refunds.refund_id;


--
-- Name: rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rewards (
    reward_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    title character varying(100) NOT NULL,
    required_amount_cents bigint NOT NULL,
    description text NOT NULL,
    limit_total integer,
    display_order integer NOT NULL,
    CONSTRAINT rewards_limit_total_check CHECK ((limit_total > 0)),
    CONSTRAINT rewards_required_amount_cents_check CHECK ((required_amount_cents > 0))
);


--
-- Name: rewards_reward_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rewards_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rewards_reward_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rewards_reward_id_seq OWNED BY public.rewards.reward_id;


--
-- Name: saved_campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_campaigns (
    creator_id text NOT NULL,
    campaign_id bigint NOT NULL,
    engagement_type smallint NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT saved_campaigns_engagement_type_check CHECK ((engagement_type = ANY (ARRAY[0, 1])))
);


--
-- Name: site_admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_admins (
    admin_id integer NOT NULL,
    username text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    hashed_password text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    last_login timestamp with time zone,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    invite_token character varying(64),
    invite_token_expires timestamp with time zone,
    created_by integer,
    CONSTRAINT site_admins_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[])))
);


--
-- Name: site_admins_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.site_admins_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_admins_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.site_admins_admin_id_seq OWNED BY public.site_admins.admin_id;


--
-- Name: admin_activity_log log_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_activity_log ALTER COLUMN log_id SET DEFAULT nextval('public.admin_activity_log_log_id_seq'::regclass);


--
-- Name: blocked_users ban_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_users ALTER COLUMN ban_id SET DEFAULT nextval('public.blocked_users_ban_id_seq'::regclass);


--
-- Name: campaign_photos photo_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_photos ALTER COLUMN photo_id SET DEFAULT nextval('public.campaign_photos_photo_id_seq'::regclass);


--
-- Name: campaign_report_photos report_photo_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_report_photos ALTER COLUMN report_photo_id SET DEFAULT nextval('public.campaign_report_photos_report_photo_id_seq'::regclass);


--
-- Name: campaign_reports report_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_reports ALTER COLUMN report_id SET DEFAULT nextval('public.campaign_reports_report_id_seq'::regclass);


--
-- Name: campaign_types type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_types ALTER COLUMN type_id SET DEFAULT nextval('public.campaign_types_type_id_seq'::regclass);


--
-- Name: campaigns campaign_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN campaign_id SET DEFAULT nextval('public.campaigns_campaign_id_seq'::regclass);


--
-- Name: collaborators collaborator_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators ALTER COLUMN collaborator_id SET DEFAULT nextval('public.collaborators_collaborator_id_seq'::regclass);


--
-- Name: comment_reports report_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reports ALTER COLUMN report_id SET DEFAULT nextval('public.comment_reports_report_id_seq'::regclass);


--
-- Name: comments comment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN comment_id SET DEFAULT nextval('public.comments_comment_id_seq'::regclass);


--
-- Name: deleted_campaigns deletion_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_campaigns ALTER COLUMN deletion_id SET DEFAULT nextval('public.deleted_campaigns_deletion_id_seq'::regclass);


--
-- Name: donations donation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations ALTER COLUMN donation_id SET DEFAULT nextval('public.donations_donation_id_seq'::regclass);


--
-- Name: fees fee_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fees ALTER COLUMN fee_id SET DEFAULT nextval('public.fees_fee_id_seq'::regclass);


--
-- Name: interests interest_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests ALTER COLUMN interest_id SET DEFAULT nextval('public.interests_interest_id_seq'::regclass);


--
-- Name: misc_reports report_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_reports ALTER COLUMN report_id SET DEFAULT nextval('public.misc_reports_report_id_seq'::regclass);


--
-- Name: notifications notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN notification_id SET DEFAULT nextval('public.notifications_notification_id_seq'::regclass);


--
-- Name: payments payment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN payment_id SET DEFAULT nextval('public.payments_payment_id_seq'::regclass);


--
-- Name: payouts payout_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts ALTER COLUMN payout_id SET DEFAULT nextval('public.payouts_payout_id_seq'::regclass);


--
-- Name: profile_reports report_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_reports ALTER COLUMN report_id SET DEFAULT nextval('public.profile_reports_report_id_seq'::regclass);


--
-- Name: refunds refund_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds ALTER COLUMN refund_id SET DEFAULT nextval('public.refunds_refund_id_seq'::regclass);


--
-- Name: rewards reward_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards ALTER COLUMN reward_id SET DEFAULT nextval('public.rewards_reward_id_seq'::regclass);


--
-- Name: site_admins admin_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_admins ALTER COLUMN admin_id SET DEFAULT nextval('public.site_admins_admin_id_seq'::regclass);


--
-- Name: admin_activity_log admin_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_pkey PRIMARY KEY (log_id);


--
-- Name: bank_details bank_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_details
    ADD CONSTRAINT bank_details_pkey PRIMARY KEY (campaign_id);


--
-- Name: blocked_users blocked_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_users
    ADD CONSTRAINT blocked_users_pkey PRIMARY KEY (ban_id);


--
-- Name: campaign_photos campaign_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_photos
    ADD CONSTRAINT campaign_photos_pkey PRIMARY KEY (photo_id);


--
-- Name: campaign_report_photos campaign_report_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_report_photos
    ADD CONSTRAINT campaign_report_photos_pkey PRIMARY KEY (report_photo_id);


--
-- Name: campaign_reports campaign_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_reports
    ADD CONSTRAINT campaign_reports_pkey PRIMARY KEY (report_id);


--
-- Name: campaign_type_map campaign_type_map_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_type_map
    ADD CONSTRAINT campaign_type_map_pkey PRIMARY KEY (campaign_id, type_id);


--
-- Name: campaign_types campaign_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_types
    ADD CONSTRAINT campaign_types_name_key UNIQUE (name);


--
-- Name: campaign_types campaign_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_types
    ADD CONSTRAINT campaign_types_pkey PRIMARY KEY (type_id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (campaign_id);


--
-- Name: campaigns campaigns_url_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_url_key UNIQUE (url);


--
-- Name: collaborators collaborators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators
    ADD CONSTRAINT collaborators_pkey PRIMARY KEY (collaborator_id);


--
-- Name: comment_likes comment_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_likes
    ADD CONSTRAINT comment_likes_pkey PRIMARY KEY (comment_id, creator_id);


--
-- Name: comment_reports comment_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reports
    ADD CONSTRAINT comment_reports_pkey PRIMARY KEY (report_id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (comment_id);


--
-- Name: creator_follows creator_follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creator_follows
    ADD CONSTRAINT creator_follows_pkey PRIMARY KEY (follower_creator_id, followed_creator_id);


--
-- Name: creator_interests creator_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creator_interests
    ADD CONSTRAINT creator_interests_pkey PRIMARY KEY (creator_id, interest_id);


--
-- Name: creators creators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creators
    ADD CONSTRAINT creators_pkey PRIMARY KEY (creator_id);


--
-- Name: deleted_campaigns deleted_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_campaigns
    ADD CONSTRAINT deleted_campaigns_pkey PRIMARY KEY (deletion_id);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (donation_id);


--
-- Name: faqs faqs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faqs
    ADD CONSTRAINT faqs_pkey PRIMARY KEY (campaign_id, display_order);


--
-- Name: fees fees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fees_pkey PRIMARY KEY (fee_id);


--
-- Name: interests interests_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests
    ADD CONSTRAINT interests_name_key UNIQUE (name);


--
-- Name: interests interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests
    ADD CONSTRAINT interests_pkey PRIMARY KEY (interest_id);


--
-- Name: misc_reports misc_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_reports
    ADD CONSTRAINT misc_reports_pkey PRIMARY KEY (report_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: organization_members organization_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_pkey PRIMARY KEY (member_id, organization_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- Name: payouts payouts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts
    ADD CONSTRAINT payouts_pkey PRIMARY KEY (payout_id);


--
-- Name: profile_reports profile_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_reports
    ADD CONSTRAINT profile_reports_pkey PRIMARY KEY (report_id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (refund_id);


--
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (reward_id);


--
-- Name: saved_campaigns saved_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_campaigns
    ADD CONSTRAINT saved_campaigns_pkey PRIMARY KEY (creator_id, campaign_id, engagement_type);


--
-- Name: site_admins site_admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_admins
    ADD CONSTRAINT site_admins_pkey PRIMARY KEY (admin_id);


--
-- Name: site_admins site_admins_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_admins
    ADD CONSTRAINT site_admins_username_key UNIQUE (username);


--
-- Name: organization_members unique_org_member; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT unique_org_member UNIQUE (organization_id, member_id);


--
-- Name: creators_email_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX creators_email_unique ON public.creators USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: creators_username_unique_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX creators_username_unique_idx ON public.creators USING btree (lower(username));


--
-- Name: idx_admin_activity_log_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_activity_log_admin ON public.admin_activity_log USING btree (admin_id);


--
-- Name: idx_admin_activity_log_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_activity_log_time ON public.admin_activity_log USING btree (time_created DESC);


--
-- Name: idx_blocked_users_creator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blocked_users_creator ON public.blocked_users USING btree (creator_id);


--
-- Name: idx_campaign_photos_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_photos_campaign ON public.campaign_photos USING btree (campaign_id);


--
-- Name: idx_campaign_photos_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_photos_primary ON public.campaign_photos USING btree (campaign_id, is_primary);


--
-- Name: idx_campaign_report_photos_reported_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_report_photos_reported_campaign_id ON public.campaign_report_photos USING btree (reported_campaign_id);


--
-- Name: idx_campaign_reports_status_time_reported; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_reports_status_time_reported ON public.campaign_reports USING btree (status, time_reported DESC);


--
-- Name: idx_campaign_type_map_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_type_map_type ON public.campaign_type_map USING btree (type_id);


--
-- Name: idx_campaigns_creator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_creator ON public.campaigns USING btree (creator_id);


--
-- Name: idx_campaigns_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_creator_id ON public.campaigns USING btree (creator_id);


--
-- Name: idx_campaigns_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_status ON public.campaigns USING btree (status);


--
-- Name: idx_collaborators_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collaborators_campaign ON public.collaborators USING btree (campaign_id);


--
-- Name: idx_collaborators_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collaborators_email ON public.collaborators USING btree (email);


--
-- Name: idx_comment_likes_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comment_likes_comment_id ON public.comment_likes USING btree (comment_id);


--
-- Name: idx_comment_reports_reported_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comment_reports_reported_comment_id ON public.comment_reports USING btree (reported_comment_id);


--
-- Name: idx_comment_reports_status_time_reported; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comment_reports_status_time_reported ON public.comment_reports USING btree (status, time_reported DESC);


--
-- Name: idx_comments_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_campaign ON public.comments USING btree (campaign_id);


--
-- Name: idx_comments_campaign_parent_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_campaign_parent_created ON public.comments USING btree (campaign_id, parent_comment_id, time_created DESC);


--
-- Name: idx_comments_creator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_creator ON public.comments USING btree (creator_id);


--
-- Name: idx_comments_is_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_is_deleted ON public.comments USING btree (is_deleted) WHERE (is_deleted = false);


--
-- Name: idx_comments_is_hidden; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_is_hidden ON public.comments USING btree (is_hidden) WHERE (is_hidden = false);


--
-- Name: idx_comments_parent_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_parent_comment_id ON public.comments USING btree (parent_comment_id);


--
-- Name: idx_comments_reply_to_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_reply_to_comment_id ON public.comments USING btree (reply_to_comment_id);


--
-- Name: idx_comments_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_time ON public.comments USING btree (campaign_id, time_created DESC);


--
-- Name: idx_creator_interests_interest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_creator_interests_interest ON public.creator_interests USING btree (interest_id);


--
-- Name: idx_donations_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_campaign ON public.donations USING btree (campaign_id);


--
-- Name: idx_donations_donor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_donor ON public.donations USING btree (donor_creator_id);


--
-- Name: idx_donations_donor_creator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_donor_creator ON public.donations USING btree (donor_creator_id);


--
-- Name: idx_donations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_status ON public.donations USING btree (status);


--
-- Name: idx_donations_stripe_charge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_stripe_charge ON public.donations USING btree (stripe_charge_id) WHERE (stripe_charge_id IS NOT NULL);


--
-- Name: idx_donations_stripe_checkout; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_stripe_checkout ON public.donations USING btree (stripe_checkout_session_id) WHERE (stripe_checkout_session_id IS NOT NULL);


--
-- Name: idx_donations_stripe_pi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_stripe_pi ON public.donations USING btree (stripe_payment_intent_id) WHERE (stripe_payment_intent_id IS NOT NULL);


--
-- Name: idx_faqs_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_faqs_campaign ON public.faqs USING btree (campaign_id);


--
-- Name: idx_fees_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fees_campaign ON public.fees USING btree (campaign_id);


--
-- Name: idx_fees_donation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fees_donation ON public.fees USING btree (donation_id);


--
-- Name: idx_notifications_recipient_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_recipient_unread ON public.notifications USING btree (recipient_creator_id, is_deleted, is_read, time_created DESC);


--
-- Name: idx_org_members_member; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_org_members_member ON public.organization_members USING btree (member_id);


--
-- Name: idx_org_members_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_org_members_org ON public.organization_members USING btree (organization_id);


--
-- Name: idx_payments_donation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_donation ON public.payments USING btree (donation_id);


--
-- Name: idx_payments_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_status ON public.payments USING btree (status);


--
-- Name: idx_payouts_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_campaign ON public.payouts USING btree (campaign_id);


--
-- Name: idx_payouts_payee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_payee ON public.payouts USING btree (payee_creator_id);


--
-- Name: idx_profile_reports_status_time_reported; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profile_reports_status_time_reported ON public.profile_reports USING btree (status, time_reported DESC);


--
-- Name: idx_refunds_donation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refunds_donation ON public.refunds USING btree (donation_id);


--
-- Name: idx_refunds_payment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refunds_payment ON public.refunds USING btree (payment_id);


--
-- Name: idx_refunds_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refunds_status ON public.refunds USING btree (status);


--
-- Name: idx_rewards_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rewards_campaign ON public.rewards USING btree (campaign_id);


--
-- Name: idx_saved_campaigns_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_saved_campaigns_campaign ON public.saved_campaigns USING btree (campaign_id);


--
-- Name: site_admins_invite_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_admins_invite_token_idx ON public.site_admins USING btree (invite_token) WHERE (invite_token IS NOT NULL);


--
-- Name: uq_campaign_photos_s3_object; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_campaign_photos_s3_object ON public.campaign_photos USING btree (s3_bucket, s3_key);


--
-- Name: uq_notifications_recipient_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_notifications_recipient_source ON public.notifications USING btree (recipient_creator_id, source_type, source_key);


--
-- Name: ux_blocked_users_active_ban; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_blocked_users_active_ban ON public.blocked_users USING btree (creator_id) WHERE ((ban_type)::text = ANY ((ARRAY['soft_ban'::character varying, 'full_ban'::character varying])::text[]));


--
-- Name: admin_activity_log admin_activity_log_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.site_admins(admin_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: blocked_users blocked_users_blocked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_users
    ADD CONSTRAINT blocked_users_blocked_by_fkey FOREIGN KEY (blocked_by) REFERENCES public.site_admins(admin_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: blocked_users blocked_users_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_users
    ADD CONSTRAINT blocked_users_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: campaign_report_photos campaign_report_photos_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_report_photos
    ADD CONSTRAINT campaign_report_photos_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.campaign_reports(report_id) ON DELETE CASCADE;


--
-- Name: campaign_reports campaign_reports_reported_campaign_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_reports
    ADD CONSTRAINT campaign_reports_reported_campaign_creator_id_fkey FOREIGN KEY (reported_campaign_creator_id) REFERENCES public.creators(creator_id) ON DELETE SET NULL;


--
-- Name: campaign_reports campaign_reports_reported_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_reports
    ADD CONSTRAINT campaign_reports_reported_campaign_id_fkey FOREIGN KEY (reported_campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE SET NULL;


--
-- Name: campaign_reports campaign_reports_reporter_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_reports
    ADD CONSTRAINT campaign_reports_reporter_creator_id_fkey FOREIGN KEY (reporter_creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: comment_likes comment_likes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_likes
    ADD CONSTRAINT comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(comment_id) ON DELETE CASCADE;


--
-- Name: comment_likes comment_likes_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_likes
    ADD CONSTRAINT comment_likes_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: comment_reports comment_reports_reported_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reports
    ADD CONSTRAINT comment_reports_reported_campaign_id_fkey FOREIGN KEY (reported_campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE SET NULL;


--
-- Name: comment_reports comment_reports_reported_comment_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reports
    ADD CONSTRAINT comment_reports_reported_comment_creator_id_fkey FOREIGN KEY (reported_comment_creator_id) REFERENCES public.creators(creator_id) ON DELETE SET NULL;


--
-- Name: comment_reports comment_reports_reported_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reports
    ADD CONSTRAINT comment_reports_reported_comment_id_fkey FOREIGN KEY (reported_comment_id) REFERENCES public.comments(comment_id) ON DELETE SET NULL;


--
-- Name: comment_reports comment_reports_reporter_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reports
    ADD CONSTRAINT comment_reports_reporter_creator_id_fkey FOREIGN KEY (reporter_creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: comments comments_parent_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_parent_comment_id_fkey FOREIGN KEY (parent_comment_id) REFERENCES public.comments(comment_id) ON DELETE CASCADE;


--
-- Name: comments comments_reply_to_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_reply_to_comment_id_fkey FOREIGN KEY (reply_to_comment_id) REFERENCES public.comments(comment_id) ON DELETE SET NULL;


--
-- Name: creator_follows creator_follows_followed_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creator_follows
    ADD CONSTRAINT creator_follows_followed_creator_id_fkey FOREIGN KEY (followed_creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: creator_follows creator_follows_follower_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creator_follows
    ADD CONSTRAINT creator_follows_follower_creator_id_fkey FOREIGN KEY (follower_creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: deleted_campaigns deleted_campaigns_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_campaigns
    ADD CONSTRAINT deleted_campaigns_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.site_admins(admin_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: bank_details fk_bank_details_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_details
    ADD CONSTRAINT fk_bank_details_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: campaign_photos fk_campaign_photos_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_photos
    ADD CONSTRAINT fk_campaign_photos_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: campaign_photos fk_campaign_photos_uploader; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_photos
    ADD CONSTRAINT fk_campaign_photos_uploader FOREIGN KEY (uploaded_by_creator_id) REFERENCES public.creators(creator_id) ON DELETE SET NULL;


--
-- Name: campaign_type_map fk_campaign_type_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_type_map
    ADD CONSTRAINT fk_campaign_type_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: campaign_type_map fk_campaign_type_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_type_map
    ADD CONSTRAINT fk_campaign_type_type FOREIGN KEY (type_id) REFERENCES public.campaign_types(type_id) ON DELETE CASCADE;


--
-- Name: campaigns fk_campaigns_creator; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_campaigns_creator FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE RESTRICT;


--
-- Name: collaborators fk_collaborators_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators
    ADD CONSTRAINT fk_collaborators_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: comments fk_comments_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comments_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: comments fk_comments_creator; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comments_creator FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: creator_interests fk_creator_interests_creator; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creator_interests
    ADD CONSTRAINT fk_creator_interests_creator FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: creator_interests fk_creator_interests_interest; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creator_interests
    ADD CONSTRAINT fk_creator_interests_interest FOREIGN KEY (interest_id) REFERENCES public.interests(interest_id) ON DELETE CASCADE;


--
-- Name: donations fk_donations_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT fk_donations_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: donations fk_donations_donor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT fk_donations_donor FOREIGN KEY (donor_creator_id) REFERENCES public.creators(creator_id) ON DELETE RESTRICT;


--
-- Name: faqs fk_faqs_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faqs
    ADD CONSTRAINT fk_faqs_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: fees fk_fees_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fk_fees_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: fees fk_fees_donation; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fk_fees_donation FOREIGN KEY (donation_id) REFERENCES public.donations(donation_id) ON DELETE CASCADE;


--
-- Name: organization_members fk_org_members_member; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT fk_org_members_member FOREIGN KEY (member_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: organization_members fk_org_members_org; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT fk_org_members_org FOREIGN KEY (organization_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: payments fk_payments_donation; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payments_donation FOREIGN KEY (donation_id) REFERENCES public.donations(donation_id) ON DELETE SET NULL;


--
-- Name: payouts fk_payouts_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts
    ADD CONSTRAINT fk_payouts_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: payouts fk_payouts_payee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts
    ADD CONSTRAINT fk_payouts_payee FOREIGN KEY (payee_creator_id) REFERENCES public.creators(creator_id) ON DELETE RESTRICT;


--
-- Name: refunds fk_refunds_donation; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_refunds_donation FOREIGN KEY (donation_id) REFERENCES public.donations(donation_id) ON DELETE CASCADE;


--
-- Name: refunds fk_refunds_payment; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_refunds_payment FOREIGN KEY (payment_id) REFERENCES public.payments(payment_id) ON DELETE RESTRICT;


--
-- Name: rewards fk_rewards_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT fk_rewards_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: saved_campaigns fk_saved_campaign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_campaigns
    ADD CONSTRAINT fk_saved_campaign FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: saved_campaigns fk_saved_creator; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_campaigns
    ADD CONSTRAINT fk_saved_creator FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: misc_reports misc_reports_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_reports
    ADD CONSTRAINT misc_reports_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: notifications notifications_actor_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_actor_creator_id_fkey FOREIGN KEY (actor_creator_id) REFERENCES public.creators(creator_id) ON DELETE SET NULL;


--
-- Name: notifications notifications_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: notifications notifications_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(comment_id) ON DELETE CASCADE;


--
-- Name: notifications notifications_recipient_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_creator_id_fkey FOREIGN KEY (recipient_creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- Name: organization_members organization_members_added_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_added_by_fkey FOREIGN KEY (added_by) REFERENCES public.creators(creator_id);


--
-- Name: profile_reports profile_reports_reported_profile_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_reports
    ADD CONSTRAINT profile_reports_reported_profile_creator_id_fkey FOREIGN KEY (reported_profile_creator_id) REFERENCES public.creators(creator_id) ON DELETE SET NULL;


--
-- Name: profile_reports profile_reports_reporter_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_reports
    ADD CONSTRAINT profile_reports_reporter_creator_id_fkey FOREIGN KEY (reporter_creator_id) REFERENCES public.creators(creator_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict HKXIvMC9aPITuKOFIfZ22Xgn53L2YPgYUe3c0lUvKoIOkqhLKjfGe3TuIHYJgWm

