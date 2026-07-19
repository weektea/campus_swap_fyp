--
-- PostgreSQL database dump
--

\restrict rRkNsfazxdooFF575UfAbXjvygToap0jYzdwdbdEfjH47YWziY8PnsGOVPrdI4B

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: enum_BackupLogs_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_BackupLogs_status" AS ENUM (
    'Success',
    'Failed',
    'In-Progress'
);


ALTER TYPE public."enum_BackupLogs_status" OWNER TO postgres;

--
-- Name: enum_BackupLogs_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_BackupLogs_type" AS ENUM (
    'Auto',
    'Manual'
);


ALTER TYPE public."enum_BackupLogs_type" OWNER TO postgres;

--
-- Name: enum_Disputes_reason; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Disputes_reason" AS ENUM (
    'Not Received',
    'Damaged',
    'Fraud',
    'Rental Damage',
    'Other'
);


ALTER TYPE public."enum_Disputes_reason" OWNER TO postgres;

--
-- Name: enum_Disputes_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Disputes_status" AS ENUM (
    'New',
    'Investigating',
    'Escalated',
    'Resolved'
);


ALTER TYPE public."enum_Disputes_status" OWNER TO postgres;

--
-- Name: enum_Notifications_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Notifications_type" AS ENUM (
    'Transaction',
    'System',
    'Promotion'
);


ALTER TYPE public."enum_Notifications_type" OWNER TO postgres;

--
-- Name: enum_Products_condition; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Products_condition" AS ENUM (
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor'
);


ALTER TYPE public."enum_Products_condition" OWNER TO postgres;

--
-- Name: enum_Products_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Products_status" AS ENUM (
    'Available',
    'Reserved',
    'Sold',
    'Removed',
    'Suspended'
);


ALTER TYPE public."enum_Products_status" OWNER TO postgres;

--
-- Name: enum_Products_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Products_type" AS ENUM (
    'Sale',
    'Rent'
);


ALTER TYPE public."enum_Products_type" OWNER TO postgres;

--
-- Name: enum_Reports_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Reports_status" AS ENUM (
    'Pending',
    'In-Progress',
    'Uphold',
    'Dismissed',
    'Escalated'
);


ALTER TYPE public."enum_Reports_status" OWNER TO postgres;

--
-- Name: enum_Reports_violation_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Reports_violation_type" AS ENUM (
    'Spam',
    'Scam',
    'Fake',
    'Prohibited'
);


ALTER TYPE public."enum_Reports_violation_type" OWNER TO postgres;

--
-- Name: enum_SupportTickets_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_SupportTickets_category" AS ENUM (
    'Account',
    'Bug',
    'Harassment',
    'General'
);


ALTER TYPE public."enum_SupportTickets_category" OWNER TO postgres;

--
-- Name: enum_SupportTickets_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_SupportTickets_status" AS ENUM (
    'Open',
    'In-Progress',
    'Escalated',
    'Resolved'
);


ALTER TYPE public."enum_SupportTickets_status" OWNER TO postgres;

--
-- Name: enum_TicketMessages_reference_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_TicketMessages_reference_type" AS ENUM (
    'Dispute',
    'SupportTicket'
);


ALTER TYPE public."enum_TicketMessages_reference_type" OWNER TO postgres;

--
-- Name: enum_Transactions_rental_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Transactions_rental_type" AS ENUM (
    'Short-term',
    'Long-term',
    'Shared'
);


ALTER TYPE public."enum_Transactions_rental_type" OWNER TO postgres;

--
-- Name: enum_Transactions_review_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Transactions_review_status" AS ENUM (
    'PENDING_REVIEWS',
    'BUYER_REVIEWED',
    'SELLER_REVIEWED',
    'PUBLISHED'
);


ALTER TYPE public."enum_Transactions_review_status" OWNER TO postgres;

--
-- Name: enum_Transactions_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Transactions_status" AS ENUM (
    'Pending',
    'In Progress',
    'Scheduled',
    'To Confirm',
    'Completed',
    'Cancelled',
    'Disputed',
    'On Rent'
);


ALTER TYPE public."enum_Transactions_status" OWNER TO postgres;

--
-- Name: enum_UserInteractions_interaction_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_UserInteractions_interaction_type" AS ENUM (
    'view',
    'save',
    'message',
    'buy'
);


ALTER TYPE public."enum_UserInteractions_interaction_type" OWNER TO postgres;

--
-- Name: enum_Users_privacy_setting; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Users_privacy_setting" AS ENUM (
    'Public',
    'Private',
    'Friends Only'
);


ALTER TYPE public."enum_Users_privacy_setting" OWNER TO postgres;

--
-- Name: enum_Users_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Users_role" AS ENUM (
    'student',
    'admin',
    'moderator'
);


ALTER TYPE public."enum_Users_role" OWNER TO postgres;

--
-- Name: enum_Users_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Users_status" AS ENUM (
    'active',
    'deactivated',
    'suspended'
);


ALTER TYPE public."enum_Users_status" OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: BackupLogs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."BackupLogs" (
    id uuid NOT NULL,
    type public."enum_BackupLogs_type" DEFAULT 'Manual'::public."enum_BackupLogs_type" NOT NULL,
    size character varying(255) DEFAULT '0 MB'::character varying NOT NULL,
    status public."enum_BackupLogs_status" DEFAULT 'Success'::public."enum_BackupLogs_status" NOT NULL,
    file_path character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."BackupLogs" OWNER TO postgres;

--
-- Name: Categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Categories" (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    icon_url character varying(255),
    carbon_conversion_factor double precision DEFAULT '0'::double precision
);


ALTER TABLE public."Categories" OWNER TO postgres;

--
-- Name: Disputes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Disputes" (
    id uuid NOT NULL,
    transaction_id uuid NOT NULL,
    complainant_id uuid NOT NULL,
    reason public."enum_Disputes_reason" NOT NULL,
    description text NOT NULL,
    evidence_urls json DEFAULT '[]'::json,
    status character varying(255) DEFAULT 'New'::character varying,
    handled_by uuid,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Disputes" OWNER TO postgres;

--
-- Name: Follows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Follows" (
    follow_id uuid NOT NULL,
    follower_id uuid NOT NULL,
    following_id uuid NOT NULL,
    followed_at timestamp with time zone NOT NULL
);


ALTER TABLE public."Follows" OWNER TO postgres;

--
-- Name: Messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Messages" (
    id uuid NOT NULL,
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    "createdAt" timestamp with time zone NOT NULL,
    mapped_zone_id uuid
);


ALTER TABLE public."Messages" OWNER TO postgres;

--
-- Name: Notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Notifications" (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    type public."enum_Notifications_type" DEFAULT 'System'::public."enum_Notifications_type",
    is_read boolean DEFAULT false,
    related_id uuid,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Notifications" OWNER TO postgres;

--
-- Name: Products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Products" (
    id uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    price numeric(10,2) NOT NULL,
    category character varying(255),
    condition public."enum_Products_condition" DEFAULT 'Good'::public."enum_Products_condition",
    image_urls json DEFAULT '[]'::json,
    status public."enum_Products_status" DEFAULT 'Available'::public."enum_Products_status",
    price_negotiable boolean DEFAULT true,
    seller_id uuid NOT NULL,
    type public."enum_Products_type" DEFAULT 'Sale'::public."enum_Products_type",
    rental_price_per_day numeric(10,2),
    max_rental_duration integer,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    video_url character varying(255),
    category_id uuid,
    sub_category_id uuid,
    rental_deposit numeric(10,2),
    accepted_payment_methods json DEFAULT '["Cash", "TNG", "Bank Transfer"]'::json
);


ALTER TABLE public."Products" OWNER TO postgres;

--
-- Name: Reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Reports" (
    id uuid NOT NULL,
    reporter_id uuid NOT NULL,
    product_id uuid,
    violation_type character varying(255) NOT NULL,
    description text NOT NULL,
    status public."enum_Reports_status" DEFAULT 'Pending'::public."enum_Reports_status",
    admin_notes text,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    evidence_urls json DEFAULT '[]'::json,
    handled_by uuid,
    reported_user_id uuid
);


ALTER TABLE public."Reports" OWNER TO postgres;

--
-- Name: Reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Reviews" (
    id uuid NOT NULL,
    rating integer NOT NULL,
    comment text,
    transaction_id uuid NOT NULL,
    reviewer_id uuid NOT NULL,
    reviewee_id uuid NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Reviews" OWNER TO postgres;

--
-- Name: SafeMeetupZones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SafeMeetupZones" (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    description character varying(255),
    is_active boolean DEFAULT true,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."SafeMeetupZones" OWNER TO postgres;

--
-- Name: SavedItems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SavedItems" (
    saved_item_id uuid NOT NULL,
    user_id uuid NOT NULL,
    product_id uuid NOT NULL,
    saved_at timestamp with time zone NOT NULL
);


ALTER TABLE public."SavedItems" OWNER TO postgres;

--
-- Name: SubCategories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SubCategories" (
    id uuid NOT NULL,
    category_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    carbon_conversion_factor double precision DEFAULT '0'::double precision
);


ALTER TABLE public."SubCategories" OWNER TO postgres;

--
-- Name: SupportTickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SupportTickets" (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    category public."enum_SupportTickets_category" NOT NULL,
    subject character varying(255) NOT NULL,
    description text NOT NULL,
    status character varying(255) DEFAULT 'Open'::character varying,
    reply_content text,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "lockedByModeratorId" uuid,
    "lockedAt" timestamp with time zone,
    handled_by uuid,
    type character varying(255) DEFAULT 'SUPPORT'::character varying
);


ALTER TABLE public."SupportTickets" OWNER TO postgres;

--
-- Name: TicketMessages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."TicketMessages" (
    id uuid NOT NULL,
    reference_id uuid NOT NULL,
    reference_type public."enum_TicketMessages_reference_type" NOT NULL,
    sender_id uuid NOT NULL,
    content text NOT NULL,
    attachment_url character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."TicketMessages" OWNER TO postgres;

--
-- Name: Transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Transactions" (
    id uuid NOT NULL,
    buyer_id uuid NOT NULL,
    seller_id uuid NOT NULL,
    product_id uuid NOT NULL,
    amount numeric(10,2) NOT NULL,
    status public."enum_Transactions_status" DEFAULT 'Pending'::public."enum_Transactions_status",
    meetup_location character varying(255),
    scheduled_at timestamp with time zone,
    rating_from_buyer integer,
    rating_from_seller integer,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    payment_proof_url character varying(255),
    rental_start_date timestamp with time zone,
    rental_end_date timestamp with time zone,
    buyer_comment text,
    seller_comment text,
    review_status public."enum_Transactions_review_status" DEFAULT 'PENDING_REVIEWS'::public."enum_Transactions_review_status",
    completed_at timestamp with time zone,
    pre_dispute_status character varying(255),
    awarded_carbon_points double precision,
    platform_fee numeric(10,2) DEFAULT 0.00,
    selected_payment_method character varying(255),
    rental_type character varying(50) DEFAULT 'Short-term'::character varying,
    group_size integer DEFAULT 1,
    co_renter_id uuid
);


ALTER TABLE public."Transactions" OWNER TO postgres;

--
-- Name: UserInteractions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UserInteractions" (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    product_id uuid NOT NULL,
    interaction_type public."enum_UserInteractions_interaction_type" NOT NULL,
    weight integer DEFAULT 1,
    "createdAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."UserInteractions" OWNER TO postgres;

--
-- Name: Users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Users" (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    university_id character varying(255),
    profile_image_url character varying(255),
    reputation_score double precision DEFAULT '5'::double precision,
    is_verified boolean DEFAULT false,
    role public."enum_Users_role" DEFAULT 'student'::public."enum_Users_role",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    phone_number character varying(255),
    is_active boolean DEFAULT true,
    deactivated_until timestamp with time zone,
    deactivation_reason character varying(255),
    bio character varying(150),
    privacy_setting public."enum_Users_privacy_setting" DEFAULT 'Public'::public."enum_Users_privacy_setting",
    total_carbon_saved double precision DEFAULT '0'::double precision,
    items_reused integer DEFAULT 0,
    carbon_saved_buyer double precision DEFAULT '0'::double precision,
    carbon_saved_seller double precision DEFAULT '0'::double precision,
    total_reviews integer DEFAULT 0,
    faculty character varying(255),
    year_of_study integer,
    username character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    show_full_name boolean DEFAULT false NOT NULL,
    show_phone_number boolean DEFAULT false NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying,
    accumulated_balance_due numeric(10,2) DEFAULT 0.00,
    is_email_verified boolean DEFAULT false NOT NULL,
    otp character varying(255),
    otp_expiry timestamp with time zone
);


ALTER TABLE public."Users" OWNER TO postgres;

--
-- Name: logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logs (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    action character varying(255) DEFAULT 'ACCOUNT_REACTIVATED'::character varying NOT NULL,
    "createdAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.logs OWNER TO postgres;

--
-- Data for Name: BackupLogs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."BackupLogs" (id, type, size, status, file_path, "createdAt", "updatedAt") FROM stdin;
8fb8cd0c-00ed-42d6-b2ec-867b85efc12d	Auto	2.4 GB	Success	\N	2026-05-22 14:02:45.884+00	2026-05-23 14:02:45.886+00
7babddc4-adae-4480-b0b3-dabd6fca9e76	Manual	2.1 GB	Success	\N	2026-07-05 17:03:37.07+00	2026-07-05 17:03:37.07+00
fb57fd2a-ebea-4553-997e-bcdfd37bedcd	Manual	0.26 MB	Success	C:\\Users\\ASUS\\StudioProjects\\campus_swap\\backend\\backups\\backup_2026-07-19_14-31-35.sql	2026-07-19 06:31:38.273+00	2026-07-19 06:31:38.273+00
\.


--
-- Data for Name: Categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Categories" (id, name, icon_url, carbon_conversion_factor) FROM stdin;
9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	Electronics & Gadgets	computer-icon	55.5
0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Furniture & Appliances	chair-icon	30
0e35eace-db96-4449-9669-9d9bf70ae66d	Fashion & Accessories	shirt-icon	8.2
9c960496-5dc8-47ed-b78a-f447da7a8b95	Books & Study Materials	book-icon	3.5
ef936a5b-6f1f-4ce7-96e3-0c45d009b21f	Sports	sports-icon	15
2346555a-a6ff-46b2-9087-74288d2d0528	Stationery	edit-icon	2
ff69deab-59f2-4b5b-a8c2-86f1fc705859	Others	box-icon	10
9de22501-fd60-4511-a63b-a16089142c43	Vehicle	box-icon	100
e76e466b-2e30-4cd9-b768-5bcaa9a18e6b	PreBackup_Cat_9589	test-icon	1.5
\.


--
-- Data for Name: Disputes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Disputes" (id, transaction_id, complainant_id, reason, description, evidence_urls, status, handled_by, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: Follows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Follows" (follow_id, follower_id, following_id, followed_at) FROM stdin;
e392d244-18b1-48e2-ac23-ca2ade4e1b03	977a85fd-6b6c-4658-a69d-fa709f58f9a9	848dcc84-5672-4053-8266-42f20e1d61a7	2026-07-19 06:20:38.637+00
\.


--
-- Data for Name: Messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Messages" (id, sender_id, receiver_id, content, is_read, "createdAt", mapped_zone_id) FROM stdin;
\.


--
-- Data for Name: Notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Notifications" (id, user_id, title, message, type, is_read, related_id, "createdAt", "updatedAt") FROM stdin;
39c875fe-3a11-441d-b186-b8aaaf1368fb	977a85fd-6b6c-4658-a69d-fa709f58f9a9	Test Notif	Hello	System	f	\N	2026-07-19 06:20:38.668+00	2026-07-19 06:20:38.668+00
\.


--
-- Data for Name: Products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Products" (id, title, description, price, category, condition, image_urls, status, price_negotiable, seller_id, type, rental_price_per_day, max_rental_duration, "createdAt", "updatedAt", video_url, category_id, sub_category_id, rental_deposit, accepted_payment_methods) FROM stdin;
8752bb48-3093-47ff-be9f-9d41ba7fd57f	Item of student 5890	Item desc	15.00	Books	Good	[]	Available	t	977a85fd-6b6c-4658-a69d-fa709f58f9a9	Sale	\N	\N	2026-07-19 06:20:38.607+00	2026-07-19 06:21:00.516+00	\N	ff69deab-59f2-4b5b-a8c2-86f1fc705859	2c889163-2444-4d0a-a98c-023375faafaa	\N	["Cash","TNG","Bank Transfer"]
\.


--
-- Data for Name: Reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Reports" (id, reporter_id, product_id, violation_type, description, status, admin_notes, "createdAt", "updatedAt", evidence_urls, handled_by, reported_user_id) FROM stdin;
\.


--
-- Data for Name: Reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Reviews" (id, rating, comment, transaction_id, reviewer_id, reviewee_id, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: SafeMeetupZones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SafeMeetupZones" (id, name, latitude, longitude, description, is_active, "createdAt", "updatedAt") FROM stdin;
fb367732-26f1-4784-a4b4-3f287a4947d8	Main Gate Guard House	5.45359	100.284445	Under CCTV surveillance 24/7. Highly recommended for evening meetups.	t	2026-06-24 14:23:57.32+00	2026-06-24 14:23:57.32+00
de87c4fb-d9d0-4ab4-9fdf-b580ef3aedf1	Library Foyer	5.45158	100.285059	Quiet and bright area, lots of student traffic.	t	2026-06-24 14:24:57.16+00	2026-06-24 14:24:57.16+00
f6930f16-a58b-4de4-b719-f19da6e9c97d	Student Centre / Cafeteria	5.453121	100.284898	Open public space, great for social meetups and testing items.	t	2026-06-24 14:25:31.501+00	2026-06-24 14:25:31.501+00
421fa1ff-490c-41f8-89f4-952a6fd4c616	Block A Hall Entrance	5.452931	100.285494	Sheltered pickup/drop-off point.	t	2026-06-24 14:26:08.36+00	2026-06-24 14:26:08.36+00
48f064ee-a247-4a28-b30a-d3e30d87718a	Club House	5.451849	100.286049	Near parking, easy to hand over heavy item	t	2026-06-26 04:56:56.809+00	2026-06-26 04:56:56.809+00
8881b997-308c-4874-82c4-d30ad0e7ace0	Only One Canteen 	5.452592	100.286336	Suitable for bring small items	t	2026-06-24 14:19:51.048+00	2026-06-29 12:49:02.149+00
\.


--
-- Data for Name: SavedItems; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SavedItems" (saved_item_id, user_id, product_id, saved_at) FROM stdin;
\.


--
-- Data for Name: SubCategories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SubCategories" (id, category_id, name, carbon_conversion_factor) FROM stdin;
6d6e9099-c93a-41ef-a2d2-64c868935df0	9de22501-fd60-4511-a63b-a16089142c43	Car	500
35b574fd-d112-4368-a9c7-70ff9ce02508	9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	Audio	15
712adc51-f746-4952-afad-702f6a970d7c	9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	Laptops	250
b685787c-2206-450c-aa8a-f97c11d8370e	9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	PC Accessories	10
3a665249-6607-4c0f-8f2c-86b5de433cb7	9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	Smartphones	65
5a02034e-86db-4334-985a-585f44d558c1	9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	Tablets	110
b98aa996-a6d6-44f1-b4f1-263cca35c513	9c6f2a21-51bb-4f0b-9ede-3f27bff4801f	Others	50
b8b87508-5ee9-4263-b5cb-78ef98678e52	0e35eace-db96-4449-9669-9d9bf70ae66d	Bags & Luggage	20
87274739-d4c0-4563-b1ba-5619ea1781c7	0e35eace-db96-4449-9669-9d9bf70ae66d	Clothing	15
5302d45f-6c79-4c83-a394-d34710a59751	0e35eace-db96-4449-9669-9d9bf70ae66d	Fashion Accessories	5
c9cd9567-de62-499e-b384-2b0433d94105	0e35eace-db96-4449-9669-9d9bf70ae66d	Shoes	15
735bc5e9-d427-4998-8803-cc656aa798bc	0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Appliances	80
63ce6ed0-08fa-4d54-9161-60ed2f597857	0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Chairs	35
36d4cd06-873b-4f50-90e7-874df7f9d49a	0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Sofas	150
77938579-eea2-41ca-ad27-12f1ca2705ff	0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Storage	50
27b03a0e-8564-4296-8f3c-bb9ebb6d90de	0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Tables & Desks	60
0a052d02-c1f8-4669-8795-d48438530a6e	0d5d31e4-11fd-4f59-b7e3-a7b7b8660164	Others	40
37ed7b43-2935-4311-9f68-0035f245d2ac	9c960496-5dc8-47ed-b78a-f447da7a8b95	Books	2.5
788be6a7-1b2a-469e-9557-08695823519f	9c960496-5dc8-47ed-b78a-f447da7a8b95	Calculators	8
b6022bde-c6fe-4147-84e1-a28e770cc613	9c960496-5dc8-47ed-b78a-f447da7a8b95	Notes & Past Papers	1.5
e76c1233-4459-4e57-aace-705cb52acabc	9c960496-5dc8-47ed-b78a-f447da7a8b95	Others	2
89ff2295-7745-4f5a-bfb5-8b9b21659818	ef936a5b-6f1f-4ce7-96e3-0c45d009b21f	Apparel	10
37080362-62d8-411c-815a-ec90c1806c91	ef936a5b-6f1f-4ce7-96e3-0c45d009b21f	Bicycles	120
40639801-7798-4188-a59a-a4d734fe73c7	ef936a5b-6f1f-4ce7-96e3-0c45d009b21f	Equipment	20
8db2d0ce-dd35-4600-a77c-146d93e04c78	ef936a5b-6f1f-4ce7-96e3-0c45d009b21f	Others	15
95ff13d4-348b-4052-9ced-2d8b296293f6	2346555a-a6ff-46b2-9087-74288d2d0528	Art Supplies	3
7d5c9b32-55f2-4065-938e-63d631c49cfa	2346555a-a6ff-46b2-9087-74288d2d0528	Paper	5
7bf32a9c-3f76-4ec3-91d3-b9444bfe21d6	2346555a-a6ff-46b2-9087-74288d2d0528	Writing	0.5
bbb8c0de-a231-40c0-b153-d46a8c0315e5	2346555a-a6ff-46b2-9087-74288d2d0528	Others	2
2c889163-2444-4d0a-a98c-023375faafaa	ff69deab-59f2-4b5b-a8c2-86f1fc705859	Cosmetics & Beauty	2
e6a14b9a-75c2-4f1b-9316-b880633ee684	ff69deab-59f2-4b5b-a8c2-86f1fc705859	Drinkware	5
fcea54d1-8ac8-49bb-83ef-a318f2a76bae	ff69deab-59f2-4b5b-a8c2-86f1fc705859	Miscellaneous	5
\.


--
-- Data for Name: SupportTickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SupportTickets" (id, user_id, category, subject, description, status, reply_content, "createdAt", "updatedAt", "lockedByModeratorId", "lockedAt", handled_by, type) FROM stdin;
\.


--
-- Data for Name: TicketMessages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."TicketMessages" (id, reference_id, reference_type, sender_id, content, attachment_url, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: Transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Transactions" (id, buyer_id, seller_id, product_id, amount, status, meetup_location, scheduled_at, rating_from_buyer, rating_from_seller, "createdAt", "updatedAt", payment_proof_url, rental_start_date, rental_end_date, buyer_comment, seller_comment, review_status, completed_at, pre_dispute_status, awarded_carbon_points, platform_fee, selected_payment_method, rental_type, group_size, co_renter_id) FROM stdin;
\.


--
-- Data for Name: UserInteractions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."UserInteractions" (id, user_id, product_id, interaction_type, weight, "createdAt") FROM stdin;
\.


--
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Users" (id, email, password_hash, university_id, profile_image_url, reputation_score, is_verified, role, "createdAt", "updatedAt", phone_number, is_active, deactivated_until, deactivation_reason, bio, privacy_setting, total_carbon_saved, items_reused, carbon_saved_buyer, carbon_saved_seller, total_reviews, faculty, year_of_study, username, full_name, show_full_name, show_phone_number, status, accumulated_balance_due, is_email_verified, otp, otp_expiry) FROM stdin;
3b558464-0f96-4990-bdb9-f8250d981f43	admin@campus.edu.my	$2b$10$kJiDsF0IVOJBSNW7XyorRufiOsJ05v4d3qBdG5fp.b6tZNdSaPvCe	ADMIN-001	\N	5	t	admin	2026-07-08 13:50:42.486+00	2026-07-08 13:50:42.486+00	000-0000000	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	super_admin	Super Admin	f	f	active	0.00	f	\N	\N
af713c68-327d-4f90-8d7f-ab11ba1ad930	test_student_01@student.um.edu.my	$2b$10$HlkLSZUnPyMAjbkdmKapGe/K0kxLhyanXyICqzknjKYv8/tSaCwTC	24PMR12345	\N	5	t	student	2026-07-08 13:50:42.486+00	2026-07-08 13:50:42.486+00	+6012-3456789	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	test_student_one	Test Student One	f	f	active	0.00	f	\N	\N
7b5d4ec2-1935-491a-b343-4d34387b057c	stu1@tarc.edu.my	$2b$10$93rTMc08R3cwyIw57o6C0uC3gu.522P4jyKAHa7H0BPEgIykY9sTi	24PMR00001	\N	5	t	student	2026-07-13 11:59:45.443+00	2026-07-13 11:59:45.443+00	+6011-00000001	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	test_register1	Jogn Chin	f	f	active	0.00	f	870289	2026-07-13 12:09:45.438+00
1ca32b6f-4eb8-4b30-b1f9-9c89a25b6d27	studentA@test.edu.my	mockhash	\N	\N	5	f	student	2026-07-17 16:53:59.369+00	2026-07-17 16:53:59.369+00	\N	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	student_a	Student A	f	f	active	0.00	f	\N	\N
12dc0f55-6131-443e-a873-6089f452fb51	studentB@test.edu.my	mockhash	\N	\N	5	f	student	2026-07-17 16:53:59.466+00	2026-07-17 16:53:59.466+00	\N	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	student_b	Student B	f	f	active	0.00	f	\N	\N
848dcc84-5672-4053-8266-42f20e1d61a7	test_admin_5890@campus.edu.my	hash	ADM5890	\N	5	f	admin	2026-07-19 06:20:38.468+00	2026-07-19 06:20:38.468+00	\N	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	test_admin_5890	Test Admin	f	f	active	0.00	t	\N	\N
977a85fd-6b6c-4658-a69d-fa709f58f9a9	test_student_5890@student.um.edu.my	hash	STU5890	\N	5	f	student	2026-07-19 06:20:38.577+00	2026-07-19 06:20:38.577+00	\N	t	\N	\N	\N	Public	0	0	0	0	0	\N	\N	test_student_5890	Test Student	f	f	active	0.00	t	\N	\N
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.logs (id, user_id, action, "createdAt") FROM stdin;
e6b8237d-1989-4f3a-8a37-d80a2ab6c9fd	977a85fd-6b6c-4658-a69d-fa709f58f9a9	LOGIN	2026-07-19 06:20:38.654+00
\.


--
-- Name: BackupLogs BackupLogs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BackupLogs"
    ADD CONSTRAINT "BackupLogs_pkey" PRIMARY KEY (id);


--
-- Name: Categories Categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key" UNIQUE (name);


--
-- Name: Categories Categories_name_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key1" UNIQUE (name);


--
-- Name: Categories Categories_name_key10; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key10" UNIQUE (name);


--
-- Name: Categories Categories_name_key100; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key100" UNIQUE (name);


--
-- Name: Categories Categories_name_key101; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key101" UNIQUE (name);


--
-- Name: Categories Categories_name_key102; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key102" UNIQUE (name);


--
-- Name: Categories Categories_name_key103; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key103" UNIQUE (name);


--
-- Name: Categories Categories_name_key104; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key104" UNIQUE (name);


--
-- Name: Categories Categories_name_key105; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key105" UNIQUE (name);


--
-- Name: Categories Categories_name_key106; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key106" UNIQUE (name);


--
-- Name: Categories Categories_name_key107; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key107" UNIQUE (name);


--
-- Name: Categories Categories_name_key108; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key108" UNIQUE (name);


--
-- Name: Categories Categories_name_key109; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key109" UNIQUE (name);


--
-- Name: Categories Categories_name_key11; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key11" UNIQUE (name);


--
-- Name: Categories Categories_name_key110; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key110" UNIQUE (name);


--
-- Name: Categories Categories_name_key111; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key111" UNIQUE (name);


--
-- Name: Categories Categories_name_key112; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key112" UNIQUE (name);


--
-- Name: Categories Categories_name_key113; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key113" UNIQUE (name);


--
-- Name: Categories Categories_name_key114; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key114" UNIQUE (name);


--
-- Name: Categories Categories_name_key115; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key115" UNIQUE (name);


--
-- Name: Categories Categories_name_key116; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key116" UNIQUE (name);


--
-- Name: Categories Categories_name_key117; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key117" UNIQUE (name);


--
-- Name: Categories Categories_name_key118; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key118" UNIQUE (name);


--
-- Name: Categories Categories_name_key119; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key119" UNIQUE (name);


--
-- Name: Categories Categories_name_key12; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key12" UNIQUE (name);


--
-- Name: Categories Categories_name_key120; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key120" UNIQUE (name);


--
-- Name: Categories Categories_name_key121; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key121" UNIQUE (name);


--
-- Name: Categories Categories_name_key122; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key122" UNIQUE (name);


--
-- Name: Categories Categories_name_key123; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key123" UNIQUE (name);


--
-- Name: Categories Categories_name_key124; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key124" UNIQUE (name);


--
-- Name: Categories Categories_name_key125; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key125" UNIQUE (name);


--
-- Name: Categories Categories_name_key126; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key126" UNIQUE (name);


--
-- Name: Categories Categories_name_key127; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key127" UNIQUE (name);


--
-- Name: Categories Categories_name_key128; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key128" UNIQUE (name);


--
-- Name: Categories Categories_name_key129; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key129" UNIQUE (name);


--
-- Name: Categories Categories_name_key13; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key13" UNIQUE (name);


--
-- Name: Categories Categories_name_key130; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key130" UNIQUE (name);


--
-- Name: Categories Categories_name_key131; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key131" UNIQUE (name);


--
-- Name: Categories Categories_name_key132; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key132" UNIQUE (name);


--
-- Name: Categories Categories_name_key133; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key133" UNIQUE (name);


--
-- Name: Categories Categories_name_key134; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key134" UNIQUE (name);


--
-- Name: Categories Categories_name_key135; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key135" UNIQUE (name);


--
-- Name: Categories Categories_name_key136; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key136" UNIQUE (name);


--
-- Name: Categories Categories_name_key137; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key137" UNIQUE (name);


--
-- Name: Categories Categories_name_key138; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key138" UNIQUE (name);


--
-- Name: Categories Categories_name_key139; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key139" UNIQUE (name);


--
-- Name: Categories Categories_name_key14; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key14" UNIQUE (name);


--
-- Name: Categories Categories_name_key140; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key140" UNIQUE (name);


--
-- Name: Categories Categories_name_key141; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key141" UNIQUE (name);


--
-- Name: Categories Categories_name_key142; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key142" UNIQUE (name);


--
-- Name: Categories Categories_name_key143; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key143" UNIQUE (name);


--
-- Name: Categories Categories_name_key144; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key144" UNIQUE (name);


--
-- Name: Categories Categories_name_key145; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key145" UNIQUE (name);


--
-- Name: Categories Categories_name_key146; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key146" UNIQUE (name);


--
-- Name: Categories Categories_name_key147; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key147" UNIQUE (name);


--
-- Name: Categories Categories_name_key148; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key148" UNIQUE (name);


--
-- Name: Categories Categories_name_key149; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key149" UNIQUE (name);


--
-- Name: Categories Categories_name_key15; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key15" UNIQUE (name);


--
-- Name: Categories Categories_name_key150; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key150" UNIQUE (name);


--
-- Name: Categories Categories_name_key151; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key151" UNIQUE (name);


--
-- Name: Categories Categories_name_key152; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key152" UNIQUE (name);


--
-- Name: Categories Categories_name_key153; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key153" UNIQUE (name);


--
-- Name: Categories Categories_name_key154; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key154" UNIQUE (name);


--
-- Name: Categories Categories_name_key155; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key155" UNIQUE (name);


--
-- Name: Categories Categories_name_key156; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key156" UNIQUE (name);


--
-- Name: Categories Categories_name_key157; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key157" UNIQUE (name);


--
-- Name: Categories Categories_name_key158; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key158" UNIQUE (name);


--
-- Name: Categories Categories_name_key159; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key159" UNIQUE (name);


--
-- Name: Categories Categories_name_key16; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key16" UNIQUE (name);


--
-- Name: Categories Categories_name_key160; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key160" UNIQUE (name);


--
-- Name: Categories Categories_name_key161; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key161" UNIQUE (name);


--
-- Name: Categories Categories_name_key162; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key162" UNIQUE (name);


--
-- Name: Categories Categories_name_key163; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key163" UNIQUE (name);


--
-- Name: Categories Categories_name_key164; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key164" UNIQUE (name);


--
-- Name: Categories Categories_name_key165; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key165" UNIQUE (name);


--
-- Name: Categories Categories_name_key166; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key166" UNIQUE (name);


--
-- Name: Categories Categories_name_key167; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key167" UNIQUE (name);


--
-- Name: Categories Categories_name_key168; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key168" UNIQUE (name);


--
-- Name: Categories Categories_name_key169; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key169" UNIQUE (name);


--
-- Name: Categories Categories_name_key17; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key17" UNIQUE (name);


--
-- Name: Categories Categories_name_key170; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key170" UNIQUE (name);


--
-- Name: Categories Categories_name_key171; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key171" UNIQUE (name);


--
-- Name: Categories Categories_name_key172; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key172" UNIQUE (name);


--
-- Name: Categories Categories_name_key173; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key173" UNIQUE (name);


--
-- Name: Categories Categories_name_key174; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key174" UNIQUE (name);


--
-- Name: Categories Categories_name_key175; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key175" UNIQUE (name);


--
-- Name: Categories Categories_name_key176; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key176" UNIQUE (name);


--
-- Name: Categories Categories_name_key177; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key177" UNIQUE (name);


--
-- Name: Categories Categories_name_key178; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key178" UNIQUE (name);


--
-- Name: Categories Categories_name_key179; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key179" UNIQUE (name);


--
-- Name: Categories Categories_name_key18; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key18" UNIQUE (name);


--
-- Name: Categories Categories_name_key180; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key180" UNIQUE (name);


--
-- Name: Categories Categories_name_key181; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key181" UNIQUE (name);


--
-- Name: Categories Categories_name_key182; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key182" UNIQUE (name);


--
-- Name: Categories Categories_name_key183; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key183" UNIQUE (name);


--
-- Name: Categories Categories_name_key184; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key184" UNIQUE (name);


--
-- Name: Categories Categories_name_key185; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key185" UNIQUE (name);


--
-- Name: Categories Categories_name_key186; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key186" UNIQUE (name);


--
-- Name: Categories Categories_name_key187; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key187" UNIQUE (name);


--
-- Name: Categories Categories_name_key188; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key188" UNIQUE (name);


--
-- Name: Categories Categories_name_key189; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key189" UNIQUE (name);


--
-- Name: Categories Categories_name_key19; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key19" UNIQUE (name);


--
-- Name: Categories Categories_name_key190; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key190" UNIQUE (name);


--
-- Name: Categories Categories_name_key191; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key191" UNIQUE (name);


--
-- Name: Categories Categories_name_key192; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key192" UNIQUE (name);


--
-- Name: Categories Categories_name_key193; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key193" UNIQUE (name);


--
-- Name: Categories Categories_name_key194; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key194" UNIQUE (name);


--
-- Name: Categories Categories_name_key195; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key195" UNIQUE (name);


--
-- Name: Categories Categories_name_key196; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key196" UNIQUE (name);


--
-- Name: Categories Categories_name_key197; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key197" UNIQUE (name);


--
-- Name: Categories Categories_name_key198; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key198" UNIQUE (name);


--
-- Name: Categories Categories_name_key199; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key199" UNIQUE (name);


--
-- Name: Categories Categories_name_key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key2" UNIQUE (name);


--
-- Name: Categories Categories_name_key20; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key20" UNIQUE (name);


--
-- Name: Categories Categories_name_key200; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key200" UNIQUE (name);


--
-- Name: Categories Categories_name_key201; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key201" UNIQUE (name);


--
-- Name: Categories Categories_name_key202; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key202" UNIQUE (name);


--
-- Name: Categories Categories_name_key203; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key203" UNIQUE (name);


--
-- Name: Categories Categories_name_key204; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key204" UNIQUE (name);


--
-- Name: Categories Categories_name_key205; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key205" UNIQUE (name);


--
-- Name: Categories Categories_name_key206; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key206" UNIQUE (name);


--
-- Name: Categories Categories_name_key207; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key207" UNIQUE (name);


--
-- Name: Categories Categories_name_key208; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key208" UNIQUE (name);


--
-- Name: Categories Categories_name_key209; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key209" UNIQUE (name);


--
-- Name: Categories Categories_name_key21; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key21" UNIQUE (name);


--
-- Name: Categories Categories_name_key210; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key210" UNIQUE (name);


--
-- Name: Categories Categories_name_key211; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key211" UNIQUE (name);


--
-- Name: Categories Categories_name_key212; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key212" UNIQUE (name);


--
-- Name: Categories Categories_name_key213; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key213" UNIQUE (name);


--
-- Name: Categories Categories_name_key214; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key214" UNIQUE (name);


--
-- Name: Categories Categories_name_key215; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key215" UNIQUE (name);


--
-- Name: Categories Categories_name_key216; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key216" UNIQUE (name);


--
-- Name: Categories Categories_name_key217; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key217" UNIQUE (name);


--
-- Name: Categories Categories_name_key218; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key218" UNIQUE (name);


--
-- Name: Categories Categories_name_key219; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key219" UNIQUE (name);


--
-- Name: Categories Categories_name_key22; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key22" UNIQUE (name);


--
-- Name: Categories Categories_name_key220; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key220" UNIQUE (name);


--
-- Name: Categories Categories_name_key221; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key221" UNIQUE (name);


--
-- Name: Categories Categories_name_key222; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key222" UNIQUE (name);


--
-- Name: Categories Categories_name_key223; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key223" UNIQUE (name);


--
-- Name: Categories Categories_name_key224; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key224" UNIQUE (name);


--
-- Name: Categories Categories_name_key225; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key225" UNIQUE (name);


--
-- Name: Categories Categories_name_key226; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key226" UNIQUE (name);


--
-- Name: Categories Categories_name_key227; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key227" UNIQUE (name);


--
-- Name: Categories Categories_name_key228; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key228" UNIQUE (name);


--
-- Name: Categories Categories_name_key229; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key229" UNIQUE (name);


--
-- Name: Categories Categories_name_key23; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key23" UNIQUE (name);


--
-- Name: Categories Categories_name_key230; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key230" UNIQUE (name);


--
-- Name: Categories Categories_name_key231; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key231" UNIQUE (name);


--
-- Name: Categories Categories_name_key232; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key232" UNIQUE (name);


--
-- Name: Categories Categories_name_key233; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key233" UNIQUE (name);


--
-- Name: Categories Categories_name_key234; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key234" UNIQUE (name);


--
-- Name: Categories Categories_name_key235; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key235" UNIQUE (name);


--
-- Name: Categories Categories_name_key236; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key236" UNIQUE (name);


--
-- Name: Categories Categories_name_key237; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key237" UNIQUE (name);


--
-- Name: Categories Categories_name_key238; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key238" UNIQUE (name);


--
-- Name: Categories Categories_name_key239; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key239" UNIQUE (name);


--
-- Name: Categories Categories_name_key24; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key24" UNIQUE (name);


--
-- Name: Categories Categories_name_key240; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key240" UNIQUE (name);


--
-- Name: Categories Categories_name_key241; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key241" UNIQUE (name);


--
-- Name: Categories Categories_name_key242; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key242" UNIQUE (name);


--
-- Name: Categories Categories_name_key243; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key243" UNIQUE (name);


--
-- Name: Categories Categories_name_key244; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key244" UNIQUE (name);


--
-- Name: Categories Categories_name_key245; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key245" UNIQUE (name);


--
-- Name: Categories Categories_name_key246; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key246" UNIQUE (name);


--
-- Name: Categories Categories_name_key247; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key247" UNIQUE (name);


--
-- Name: Categories Categories_name_key248; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key248" UNIQUE (name);


--
-- Name: Categories Categories_name_key249; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key249" UNIQUE (name);


--
-- Name: Categories Categories_name_key25; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key25" UNIQUE (name);


--
-- Name: Categories Categories_name_key250; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key250" UNIQUE (name);


--
-- Name: Categories Categories_name_key251; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key251" UNIQUE (name);


--
-- Name: Categories Categories_name_key252; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key252" UNIQUE (name);


--
-- Name: Categories Categories_name_key253; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key253" UNIQUE (name);


--
-- Name: Categories Categories_name_key254; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key254" UNIQUE (name);


--
-- Name: Categories Categories_name_key255; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key255" UNIQUE (name);


--
-- Name: Categories Categories_name_key256; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key256" UNIQUE (name);


--
-- Name: Categories Categories_name_key26; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key26" UNIQUE (name);


--
-- Name: Categories Categories_name_key27; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key27" UNIQUE (name);


--
-- Name: Categories Categories_name_key28; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key28" UNIQUE (name);


--
-- Name: Categories Categories_name_key29; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key29" UNIQUE (name);


--
-- Name: Categories Categories_name_key3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key3" UNIQUE (name);


--
-- Name: Categories Categories_name_key30; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key30" UNIQUE (name);


--
-- Name: Categories Categories_name_key31; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key31" UNIQUE (name);


--
-- Name: Categories Categories_name_key32; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key32" UNIQUE (name);


--
-- Name: Categories Categories_name_key33; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key33" UNIQUE (name);


--
-- Name: Categories Categories_name_key34; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key34" UNIQUE (name);


--
-- Name: Categories Categories_name_key35; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key35" UNIQUE (name);


--
-- Name: Categories Categories_name_key36; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key36" UNIQUE (name);


--
-- Name: Categories Categories_name_key37; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key37" UNIQUE (name);


--
-- Name: Categories Categories_name_key38; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key38" UNIQUE (name);


--
-- Name: Categories Categories_name_key39; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key39" UNIQUE (name);


--
-- Name: Categories Categories_name_key4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key4" UNIQUE (name);


--
-- Name: Categories Categories_name_key40; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key40" UNIQUE (name);


--
-- Name: Categories Categories_name_key41; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key41" UNIQUE (name);


--
-- Name: Categories Categories_name_key42; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key42" UNIQUE (name);


--
-- Name: Categories Categories_name_key43; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key43" UNIQUE (name);


--
-- Name: Categories Categories_name_key44; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key44" UNIQUE (name);


--
-- Name: Categories Categories_name_key45; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key45" UNIQUE (name);


--
-- Name: Categories Categories_name_key46; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key46" UNIQUE (name);


--
-- Name: Categories Categories_name_key47; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key47" UNIQUE (name);


--
-- Name: Categories Categories_name_key48; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key48" UNIQUE (name);


--
-- Name: Categories Categories_name_key49; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key49" UNIQUE (name);


--
-- Name: Categories Categories_name_key5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key5" UNIQUE (name);


--
-- Name: Categories Categories_name_key50; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key50" UNIQUE (name);


--
-- Name: Categories Categories_name_key51; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key51" UNIQUE (name);


--
-- Name: Categories Categories_name_key52; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key52" UNIQUE (name);


--
-- Name: Categories Categories_name_key53; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key53" UNIQUE (name);


--
-- Name: Categories Categories_name_key54; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key54" UNIQUE (name);


--
-- Name: Categories Categories_name_key55; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key55" UNIQUE (name);


--
-- Name: Categories Categories_name_key56; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key56" UNIQUE (name);


--
-- Name: Categories Categories_name_key57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key57" UNIQUE (name);


--
-- Name: Categories Categories_name_key58; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key58" UNIQUE (name);


--
-- Name: Categories Categories_name_key59; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key59" UNIQUE (name);


--
-- Name: Categories Categories_name_key6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key6" UNIQUE (name);


--
-- Name: Categories Categories_name_key60; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key60" UNIQUE (name);


--
-- Name: Categories Categories_name_key61; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key61" UNIQUE (name);


--
-- Name: Categories Categories_name_key62; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key62" UNIQUE (name);


--
-- Name: Categories Categories_name_key63; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key63" UNIQUE (name);


--
-- Name: Categories Categories_name_key64; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key64" UNIQUE (name);


--
-- Name: Categories Categories_name_key65; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key65" UNIQUE (name);


--
-- Name: Categories Categories_name_key66; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key66" UNIQUE (name);


--
-- Name: Categories Categories_name_key67; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key67" UNIQUE (name);


--
-- Name: Categories Categories_name_key68; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key68" UNIQUE (name);


--
-- Name: Categories Categories_name_key69; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key69" UNIQUE (name);


--
-- Name: Categories Categories_name_key7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key7" UNIQUE (name);


--
-- Name: Categories Categories_name_key70; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key70" UNIQUE (name);


--
-- Name: Categories Categories_name_key71; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key71" UNIQUE (name);


--
-- Name: Categories Categories_name_key72; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key72" UNIQUE (name);


--
-- Name: Categories Categories_name_key73; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key73" UNIQUE (name);


--
-- Name: Categories Categories_name_key74; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key74" UNIQUE (name);


--
-- Name: Categories Categories_name_key75; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key75" UNIQUE (name);


--
-- Name: Categories Categories_name_key76; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key76" UNIQUE (name);


--
-- Name: Categories Categories_name_key77; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key77" UNIQUE (name);


--
-- Name: Categories Categories_name_key78; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key78" UNIQUE (name);


--
-- Name: Categories Categories_name_key79; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key79" UNIQUE (name);


--
-- Name: Categories Categories_name_key8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key8" UNIQUE (name);


--
-- Name: Categories Categories_name_key80; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key80" UNIQUE (name);


--
-- Name: Categories Categories_name_key81; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key81" UNIQUE (name);


--
-- Name: Categories Categories_name_key82; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key82" UNIQUE (name);


--
-- Name: Categories Categories_name_key83; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key83" UNIQUE (name);


--
-- Name: Categories Categories_name_key84; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key84" UNIQUE (name);


--
-- Name: Categories Categories_name_key85; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key85" UNIQUE (name);


--
-- Name: Categories Categories_name_key86; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key86" UNIQUE (name);


--
-- Name: Categories Categories_name_key87; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key87" UNIQUE (name);


--
-- Name: Categories Categories_name_key88; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key88" UNIQUE (name);


--
-- Name: Categories Categories_name_key89; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key89" UNIQUE (name);


--
-- Name: Categories Categories_name_key9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key9" UNIQUE (name);


--
-- Name: Categories Categories_name_key90; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key90" UNIQUE (name);


--
-- Name: Categories Categories_name_key91; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key91" UNIQUE (name);


--
-- Name: Categories Categories_name_key92; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key92" UNIQUE (name);


--
-- Name: Categories Categories_name_key93; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key93" UNIQUE (name);


--
-- Name: Categories Categories_name_key94; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key94" UNIQUE (name);


--
-- Name: Categories Categories_name_key95; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key95" UNIQUE (name);


--
-- Name: Categories Categories_name_key96; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key96" UNIQUE (name);


--
-- Name: Categories Categories_name_key97; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key97" UNIQUE (name);


--
-- Name: Categories Categories_name_key98; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key98" UNIQUE (name);


--
-- Name: Categories Categories_name_key99; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_name_key99" UNIQUE (name);


--
-- Name: Categories Categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_pkey" PRIMARY KEY (id);


--
-- Name: Disputes Disputes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Disputes"
    ADD CONSTRAINT "Disputes_pkey" PRIMARY KEY (id);


--
-- Name: Follows Follows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Follows"
    ADD CONSTRAINT "Follows_pkey" PRIMARY KEY (follow_id);


--
-- Name: Messages Messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT "Messages_pkey" PRIMARY KEY (id);


--
-- Name: Notifications Notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "Notifications_pkey" PRIMARY KEY (id);


--
-- Name: Products Products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_pkey" PRIMARY KEY (id);


--
-- Name: Reports Reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT "Reports_pkey" PRIMARY KEY (id);


--
-- Name: Reviews Reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews"
    ADD CONSTRAINT "Reviews_pkey" PRIMARY KEY (id);


--
-- Name: SafeMeetupZones SafeMeetupZones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SafeMeetupZones"
    ADD CONSTRAINT "SafeMeetupZones_pkey" PRIMARY KEY (id);


--
-- Name: SavedItems SavedItems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SavedItems"
    ADD CONSTRAINT "SavedItems_pkey" PRIMARY KEY (saved_item_id);


--
-- Name: SubCategories SubCategories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SubCategories"
    ADD CONSTRAINT "SubCategories_pkey" PRIMARY KEY (id);


--
-- Name: SupportTickets SupportTickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SupportTickets"
    ADD CONSTRAINT "SupportTickets_pkey" PRIMARY KEY (id);


--
-- Name: TicketMessages TicketMessages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TicketMessages"
    ADD CONSTRAINT "TicketMessages_pkey" PRIMARY KEY (id);


--
-- Name: Transactions Transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_pkey" PRIMARY KEY (id);


--
-- Name: UserInteractions UserInteractions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserInteractions"
    ADD CONSTRAINT "UserInteractions_pkey" PRIMARY KEY (id);


--
-- Name: Users Users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key" UNIQUE (email);


--
-- Name: Users Users_email_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key1" UNIQUE (email);


--
-- Name: Users Users_email_key10; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key10" UNIQUE (email);


--
-- Name: Users Users_email_key100; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key100" UNIQUE (email);


--
-- Name: Users Users_email_key101; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key101" UNIQUE (email);


--
-- Name: Users Users_email_key102; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key102" UNIQUE (email);


--
-- Name: Users Users_email_key103; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key103" UNIQUE (email);


--
-- Name: Users Users_email_key104; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key104" UNIQUE (email);


--
-- Name: Users Users_email_key105; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key105" UNIQUE (email);


--
-- Name: Users Users_email_key106; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key106" UNIQUE (email);


--
-- Name: Users Users_email_key107; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key107" UNIQUE (email);


--
-- Name: Users Users_email_key108; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key108" UNIQUE (email);


--
-- Name: Users Users_email_key109; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key109" UNIQUE (email);


--
-- Name: Users Users_email_key11; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key11" UNIQUE (email);


--
-- Name: Users Users_email_key110; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key110" UNIQUE (email);


--
-- Name: Users Users_email_key111; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key111" UNIQUE (email);


--
-- Name: Users Users_email_key112; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key112" UNIQUE (email);


--
-- Name: Users Users_email_key113; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key113" UNIQUE (email);


--
-- Name: Users Users_email_key114; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key114" UNIQUE (email);


--
-- Name: Users Users_email_key115; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key115" UNIQUE (email);


--
-- Name: Users Users_email_key116; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key116" UNIQUE (email);


--
-- Name: Users Users_email_key117; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key117" UNIQUE (email);


--
-- Name: Users Users_email_key118; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key118" UNIQUE (email);


--
-- Name: Users Users_email_key119; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key119" UNIQUE (email);


--
-- Name: Users Users_email_key12; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key12" UNIQUE (email);


--
-- Name: Users Users_email_key120; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key120" UNIQUE (email);


--
-- Name: Users Users_email_key121; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key121" UNIQUE (email);


--
-- Name: Users Users_email_key122; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key122" UNIQUE (email);


--
-- Name: Users Users_email_key123; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key123" UNIQUE (email);


--
-- Name: Users Users_email_key124; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key124" UNIQUE (email);


--
-- Name: Users Users_email_key125; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key125" UNIQUE (email);


--
-- Name: Users Users_email_key126; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key126" UNIQUE (email);


--
-- Name: Users Users_email_key127; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key127" UNIQUE (email);


--
-- Name: Users Users_email_key128; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key128" UNIQUE (email);


--
-- Name: Users Users_email_key129; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key129" UNIQUE (email);


--
-- Name: Users Users_email_key13; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key13" UNIQUE (email);


--
-- Name: Users Users_email_key130; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key130" UNIQUE (email);


--
-- Name: Users Users_email_key131; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key131" UNIQUE (email);


--
-- Name: Users Users_email_key132; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key132" UNIQUE (email);


--
-- Name: Users Users_email_key133; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key133" UNIQUE (email);


--
-- Name: Users Users_email_key134; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key134" UNIQUE (email);


--
-- Name: Users Users_email_key135; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key135" UNIQUE (email);


--
-- Name: Users Users_email_key136; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key136" UNIQUE (email);


--
-- Name: Users Users_email_key137; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key137" UNIQUE (email);


--
-- Name: Users Users_email_key138; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key138" UNIQUE (email);


--
-- Name: Users Users_email_key139; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key139" UNIQUE (email);


--
-- Name: Users Users_email_key14; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key14" UNIQUE (email);


--
-- Name: Users Users_email_key140; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key140" UNIQUE (email);


--
-- Name: Users Users_email_key141; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key141" UNIQUE (email);


--
-- Name: Users Users_email_key142; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key142" UNIQUE (email);


--
-- Name: Users Users_email_key143; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key143" UNIQUE (email);


--
-- Name: Users Users_email_key144; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key144" UNIQUE (email);


--
-- Name: Users Users_email_key145; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key145" UNIQUE (email);


--
-- Name: Users Users_email_key146; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key146" UNIQUE (email);


--
-- Name: Users Users_email_key147; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key147" UNIQUE (email);


--
-- Name: Users Users_email_key148; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key148" UNIQUE (email);


--
-- Name: Users Users_email_key149; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key149" UNIQUE (email);


--
-- Name: Users Users_email_key15; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key15" UNIQUE (email);


--
-- Name: Users Users_email_key150; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key150" UNIQUE (email);


--
-- Name: Users Users_email_key151; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key151" UNIQUE (email);


--
-- Name: Users Users_email_key152; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key152" UNIQUE (email);


--
-- Name: Users Users_email_key153; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key153" UNIQUE (email);


--
-- Name: Users Users_email_key154; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key154" UNIQUE (email);


--
-- Name: Users Users_email_key155; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key155" UNIQUE (email);


--
-- Name: Users Users_email_key156; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key156" UNIQUE (email);


--
-- Name: Users Users_email_key157; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key157" UNIQUE (email);


--
-- Name: Users Users_email_key158; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key158" UNIQUE (email);


--
-- Name: Users Users_email_key159; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key159" UNIQUE (email);


--
-- Name: Users Users_email_key16; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key16" UNIQUE (email);


--
-- Name: Users Users_email_key160; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key160" UNIQUE (email);


--
-- Name: Users Users_email_key161; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key161" UNIQUE (email);


--
-- Name: Users Users_email_key162; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key162" UNIQUE (email);


--
-- Name: Users Users_email_key163; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key163" UNIQUE (email);


--
-- Name: Users Users_email_key164; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key164" UNIQUE (email);


--
-- Name: Users Users_email_key165; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key165" UNIQUE (email);


--
-- Name: Users Users_email_key166; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key166" UNIQUE (email);


--
-- Name: Users Users_email_key167; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key167" UNIQUE (email);


--
-- Name: Users Users_email_key168; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key168" UNIQUE (email);


--
-- Name: Users Users_email_key169; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key169" UNIQUE (email);


--
-- Name: Users Users_email_key17; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key17" UNIQUE (email);


--
-- Name: Users Users_email_key170; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key170" UNIQUE (email);


--
-- Name: Users Users_email_key171; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key171" UNIQUE (email);


--
-- Name: Users Users_email_key172; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key172" UNIQUE (email);


--
-- Name: Users Users_email_key173; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key173" UNIQUE (email);


--
-- Name: Users Users_email_key174; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key174" UNIQUE (email);


--
-- Name: Users Users_email_key175; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key175" UNIQUE (email);


--
-- Name: Users Users_email_key176; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key176" UNIQUE (email);


--
-- Name: Users Users_email_key177; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key177" UNIQUE (email);


--
-- Name: Users Users_email_key178; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key178" UNIQUE (email);


--
-- Name: Users Users_email_key179; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key179" UNIQUE (email);


--
-- Name: Users Users_email_key18; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key18" UNIQUE (email);


--
-- Name: Users Users_email_key180; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key180" UNIQUE (email);


--
-- Name: Users Users_email_key181; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key181" UNIQUE (email);


--
-- Name: Users Users_email_key182; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key182" UNIQUE (email);


--
-- Name: Users Users_email_key183; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key183" UNIQUE (email);


--
-- Name: Users Users_email_key184; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key184" UNIQUE (email);


--
-- Name: Users Users_email_key185; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key185" UNIQUE (email);


--
-- Name: Users Users_email_key186; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key186" UNIQUE (email);


--
-- Name: Users Users_email_key187; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key187" UNIQUE (email);


--
-- Name: Users Users_email_key188; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key188" UNIQUE (email);


--
-- Name: Users Users_email_key189; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key189" UNIQUE (email);


--
-- Name: Users Users_email_key19; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key19" UNIQUE (email);


--
-- Name: Users Users_email_key190; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key190" UNIQUE (email);


--
-- Name: Users Users_email_key191; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key191" UNIQUE (email);


--
-- Name: Users Users_email_key192; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key192" UNIQUE (email);


--
-- Name: Users Users_email_key193; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key193" UNIQUE (email);


--
-- Name: Users Users_email_key194; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key194" UNIQUE (email);


--
-- Name: Users Users_email_key195; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key195" UNIQUE (email);


--
-- Name: Users Users_email_key196; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key196" UNIQUE (email);


--
-- Name: Users Users_email_key197; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key197" UNIQUE (email);


--
-- Name: Users Users_email_key198; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key198" UNIQUE (email);


--
-- Name: Users Users_email_key199; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key199" UNIQUE (email);


--
-- Name: Users Users_email_key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key2" UNIQUE (email);


--
-- Name: Users Users_email_key20; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key20" UNIQUE (email);


--
-- Name: Users Users_email_key200; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key200" UNIQUE (email);


--
-- Name: Users Users_email_key201; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key201" UNIQUE (email);


--
-- Name: Users Users_email_key202; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key202" UNIQUE (email);


--
-- Name: Users Users_email_key203; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key203" UNIQUE (email);


--
-- Name: Users Users_email_key204; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key204" UNIQUE (email);


--
-- Name: Users Users_email_key205; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key205" UNIQUE (email);


--
-- Name: Users Users_email_key206; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key206" UNIQUE (email);


--
-- Name: Users Users_email_key207; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key207" UNIQUE (email);


--
-- Name: Users Users_email_key208; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key208" UNIQUE (email);


--
-- Name: Users Users_email_key209; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key209" UNIQUE (email);


--
-- Name: Users Users_email_key21; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key21" UNIQUE (email);


--
-- Name: Users Users_email_key210; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key210" UNIQUE (email);


--
-- Name: Users Users_email_key211; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key211" UNIQUE (email);


--
-- Name: Users Users_email_key212; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key212" UNIQUE (email);


--
-- Name: Users Users_email_key213; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key213" UNIQUE (email);


--
-- Name: Users Users_email_key214; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key214" UNIQUE (email);


--
-- Name: Users Users_email_key215; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key215" UNIQUE (email);


--
-- Name: Users Users_email_key216; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key216" UNIQUE (email);


--
-- Name: Users Users_email_key217; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key217" UNIQUE (email);


--
-- Name: Users Users_email_key218; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key218" UNIQUE (email);


--
-- Name: Users Users_email_key219; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key219" UNIQUE (email);


--
-- Name: Users Users_email_key22; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key22" UNIQUE (email);


--
-- Name: Users Users_email_key220; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key220" UNIQUE (email);


--
-- Name: Users Users_email_key221; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key221" UNIQUE (email);


--
-- Name: Users Users_email_key222; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key222" UNIQUE (email);


--
-- Name: Users Users_email_key223; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key223" UNIQUE (email);


--
-- Name: Users Users_email_key224; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key224" UNIQUE (email);


--
-- Name: Users Users_email_key225; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key225" UNIQUE (email);


--
-- Name: Users Users_email_key226; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key226" UNIQUE (email);


--
-- Name: Users Users_email_key227; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key227" UNIQUE (email);


--
-- Name: Users Users_email_key228; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key228" UNIQUE (email);


--
-- Name: Users Users_email_key229; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key229" UNIQUE (email);


--
-- Name: Users Users_email_key23; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key23" UNIQUE (email);


--
-- Name: Users Users_email_key230; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key230" UNIQUE (email);


--
-- Name: Users Users_email_key231; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key231" UNIQUE (email);


--
-- Name: Users Users_email_key232; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key232" UNIQUE (email);


--
-- Name: Users Users_email_key233; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key233" UNIQUE (email);


--
-- Name: Users Users_email_key234; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key234" UNIQUE (email);


--
-- Name: Users Users_email_key235; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key235" UNIQUE (email);


--
-- Name: Users Users_email_key236; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key236" UNIQUE (email);


--
-- Name: Users Users_email_key237; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key237" UNIQUE (email);


--
-- Name: Users Users_email_key238; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key238" UNIQUE (email);


--
-- Name: Users Users_email_key239; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key239" UNIQUE (email);


--
-- Name: Users Users_email_key24; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key24" UNIQUE (email);


--
-- Name: Users Users_email_key240; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key240" UNIQUE (email);


--
-- Name: Users Users_email_key241; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key241" UNIQUE (email);


--
-- Name: Users Users_email_key242; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key242" UNIQUE (email);


--
-- Name: Users Users_email_key243; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key243" UNIQUE (email);


--
-- Name: Users Users_email_key244; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key244" UNIQUE (email);


--
-- Name: Users Users_email_key245; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key245" UNIQUE (email);


--
-- Name: Users Users_email_key246; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key246" UNIQUE (email);


--
-- Name: Users Users_email_key247; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key247" UNIQUE (email);


--
-- Name: Users Users_email_key248; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key248" UNIQUE (email);


--
-- Name: Users Users_email_key249; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key249" UNIQUE (email);


--
-- Name: Users Users_email_key25; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key25" UNIQUE (email);


--
-- Name: Users Users_email_key250; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key250" UNIQUE (email);


--
-- Name: Users Users_email_key251; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key251" UNIQUE (email);


--
-- Name: Users Users_email_key252; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key252" UNIQUE (email);


--
-- Name: Users Users_email_key253; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key253" UNIQUE (email);


--
-- Name: Users Users_email_key254; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key254" UNIQUE (email);


--
-- Name: Users Users_email_key255; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key255" UNIQUE (email);


--
-- Name: Users Users_email_key256; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key256" UNIQUE (email);


--
-- Name: Users Users_email_key257; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key257" UNIQUE (email);


--
-- Name: Users Users_email_key258; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key258" UNIQUE (email);


--
-- Name: Users Users_email_key259; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key259" UNIQUE (email);


--
-- Name: Users Users_email_key26; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key26" UNIQUE (email);


--
-- Name: Users Users_email_key260; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key260" UNIQUE (email);


--
-- Name: Users Users_email_key261; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key261" UNIQUE (email);


--
-- Name: Users Users_email_key262; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key262" UNIQUE (email);


--
-- Name: Users Users_email_key263; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key263" UNIQUE (email);


--
-- Name: Users Users_email_key264; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key264" UNIQUE (email);


--
-- Name: Users Users_email_key265; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key265" UNIQUE (email);


--
-- Name: Users Users_email_key266; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key266" UNIQUE (email);


--
-- Name: Users Users_email_key267; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key267" UNIQUE (email);


--
-- Name: Users Users_email_key268; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key268" UNIQUE (email);


--
-- Name: Users Users_email_key269; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key269" UNIQUE (email);


--
-- Name: Users Users_email_key27; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key27" UNIQUE (email);


--
-- Name: Users Users_email_key270; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key270" UNIQUE (email);


--
-- Name: Users Users_email_key271; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key271" UNIQUE (email);


--
-- Name: Users Users_email_key272; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key272" UNIQUE (email);


--
-- Name: Users Users_email_key273; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key273" UNIQUE (email);


--
-- Name: Users Users_email_key274; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key274" UNIQUE (email);


--
-- Name: Users Users_email_key275; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key275" UNIQUE (email);


--
-- Name: Users Users_email_key276; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key276" UNIQUE (email);


--
-- Name: Users Users_email_key277; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key277" UNIQUE (email);


--
-- Name: Users Users_email_key278; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key278" UNIQUE (email);


--
-- Name: Users Users_email_key279; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key279" UNIQUE (email);


--
-- Name: Users Users_email_key28; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key28" UNIQUE (email);


--
-- Name: Users Users_email_key280; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key280" UNIQUE (email);


--
-- Name: Users Users_email_key281; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key281" UNIQUE (email);


--
-- Name: Users Users_email_key282; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key282" UNIQUE (email);


--
-- Name: Users Users_email_key283; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key283" UNIQUE (email);


--
-- Name: Users Users_email_key284; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key284" UNIQUE (email);


--
-- Name: Users Users_email_key285; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key285" UNIQUE (email);


--
-- Name: Users Users_email_key286; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key286" UNIQUE (email);


--
-- Name: Users Users_email_key287; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key287" UNIQUE (email);


--
-- Name: Users Users_email_key288; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key288" UNIQUE (email);


--
-- Name: Users Users_email_key289; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key289" UNIQUE (email);


--
-- Name: Users Users_email_key29; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key29" UNIQUE (email);


--
-- Name: Users Users_email_key290; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key290" UNIQUE (email);


--
-- Name: Users Users_email_key291; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key291" UNIQUE (email);


--
-- Name: Users Users_email_key292; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key292" UNIQUE (email);


--
-- Name: Users Users_email_key293; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key293" UNIQUE (email);


--
-- Name: Users Users_email_key294; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key294" UNIQUE (email);


--
-- Name: Users Users_email_key295; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key295" UNIQUE (email);


--
-- Name: Users Users_email_key296; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key296" UNIQUE (email);


--
-- Name: Users Users_email_key297; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key297" UNIQUE (email);


--
-- Name: Users Users_email_key298; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key298" UNIQUE (email);


--
-- Name: Users Users_email_key299; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key299" UNIQUE (email);


--
-- Name: Users Users_email_key3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key3" UNIQUE (email);


--
-- Name: Users Users_email_key30; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key30" UNIQUE (email);


--
-- Name: Users Users_email_key300; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key300" UNIQUE (email);


--
-- Name: Users Users_email_key301; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key301" UNIQUE (email);


--
-- Name: Users Users_email_key302; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key302" UNIQUE (email);


--
-- Name: Users Users_email_key303; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key303" UNIQUE (email);


--
-- Name: Users Users_email_key304; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key304" UNIQUE (email);


--
-- Name: Users Users_email_key305; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key305" UNIQUE (email);


--
-- Name: Users Users_email_key306; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key306" UNIQUE (email);


--
-- Name: Users Users_email_key307; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key307" UNIQUE (email);


--
-- Name: Users Users_email_key308; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key308" UNIQUE (email);


--
-- Name: Users Users_email_key309; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key309" UNIQUE (email);


--
-- Name: Users Users_email_key31; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key31" UNIQUE (email);


--
-- Name: Users Users_email_key310; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key310" UNIQUE (email);


--
-- Name: Users Users_email_key311; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key311" UNIQUE (email);


--
-- Name: Users Users_email_key312; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key312" UNIQUE (email);


--
-- Name: Users Users_email_key313; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key313" UNIQUE (email);


--
-- Name: Users Users_email_key314; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key314" UNIQUE (email);


--
-- Name: Users Users_email_key315; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key315" UNIQUE (email);


--
-- Name: Users Users_email_key316; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key316" UNIQUE (email);


--
-- Name: Users Users_email_key317; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key317" UNIQUE (email);


--
-- Name: Users Users_email_key32; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key32" UNIQUE (email);


--
-- Name: Users Users_email_key33; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key33" UNIQUE (email);


--
-- Name: Users Users_email_key34; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key34" UNIQUE (email);


--
-- Name: Users Users_email_key35; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key35" UNIQUE (email);


--
-- Name: Users Users_email_key36; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key36" UNIQUE (email);


--
-- Name: Users Users_email_key37; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key37" UNIQUE (email);


--
-- Name: Users Users_email_key38; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key38" UNIQUE (email);


--
-- Name: Users Users_email_key39; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key39" UNIQUE (email);


--
-- Name: Users Users_email_key4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key4" UNIQUE (email);


--
-- Name: Users Users_email_key40; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key40" UNIQUE (email);


--
-- Name: Users Users_email_key41; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key41" UNIQUE (email);


--
-- Name: Users Users_email_key42; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key42" UNIQUE (email);


--
-- Name: Users Users_email_key43; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key43" UNIQUE (email);


--
-- Name: Users Users_email_key44; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key44" UNIQUE (email);


--
-- Name: Users Users_email_key45; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key45" UNIQUE (email);


--
-- Name: Users Users_email_key46; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key46" UNIQUE (email);


--
-- Name: Users Users_email_key47; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key47" UNIQUE (email);


--
-- Name: Users Users_email_key48; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key48" UNIQUE (email);


--
-- Name: Users Users_email_key49; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key49" UNIQUE (email);


--
-- Name: Users Users_email_key5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key5" UNIQUE (email);


--
-- Name: Users Users_email_key50; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key50" UNIQUE (email);


--
-- Name: Users Users_email_key51; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key51" UNIQUE (email);


--
-- Name: Users Users_email_key52; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key52" UNIQUE (email);


--
-- Name: Users Users_email_key53; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key53" UNIQUE (email);


--
-- Name: Users Users_email_key54; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key54" UNIQUE (email);


--
-- Name: Users Users_email_key55; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key55" UNIQUE (email);


--
-- Name: Users Users_email_key56; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key56" UNIQUE (email);


--
-- Name: Users Users_email_key57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key57" UNIQUE (email);


--
-- Name: Users Users_email_key58; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key58" UNIQUE (email);


--
-- Name: Users Users_email_key59; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key59" UNIQUE (email);


--
-- Name: Users Users_email_key6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key6" UNIQUE (email);


--
-- Name: Users Users_email_key60; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key60" UNIQUE (email);


--
-- Name: Users Users_email_key61; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key61" UNIQUE (email);


--
-- Name: Users Users_email_key62; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key62" UNIQUE (email);


--
-- Name: Users Users_email_key63; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key63" UNIQUE (email);


--
-- Name: Users Users_email_key64; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key64" UNIQUE (email);


--
-- Name: Users Users_email_key65; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key65" UNIQUE (email);


--
-- Name: Users Users_email_key66; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key66" UNIQUE (email);


--
-- Name: Users Users_email_key67; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key67" UNIQUE (email);


--
-- Name: Users Users_email_key68; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key68" UNIQUE (email);


--
-- Name: Users Users_email_key69; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key69" UNIQUE (email);


--
-- Name: Users Users_email_key7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key7" UNIQUE (email);


--
-- Name: Users Users_email_key70; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key70" UNIQUE (email);


--
-- Name: Users Users_email_key71; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key71" UNIQUE (email);


--
-- Name: Users Users_email_key72; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key72" UNIQUE (email);


--
-- Name: Users Users_email_key73; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key73" UNIQUE (email);


--
-- Name: Users Users_email_key74; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key74" UNIQUE (email);


--
-- Name: Users Users_email_key75; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key75" UNIQUE (email);


--
-- Name: Users Users_email_key76; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key76" UNIQUE (email);


--
-- Name: Users Users_email_key77; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key77" UNIQUE (email);


--
-- Name: Users Users_email_key78; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key78" UNIQUE (email);


--
-- Name: Users Users_email_key79; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key79" UNIQUE (email);


--
-- Name: Users Users_email_key8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key8" UNIQUE (email);


--
-- Name: Users Users_email_key80; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key80" UNIQUE (email);


--
-- Name: Users Users_email_key81; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key81" UNIQUE (email);


--
-- Name: Users Users_email_key82; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key82" UNIQUE (email);


--
-- Name: Users Users_email_key83; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key83" UNIQUE (email);


--
-- Name: Users Users_email_key84; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key84" UNIQUE (email);


--
-- Name: Users Users_email_key85; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key85" UNIQUE (email);


--
-- Name: Users Users_email_key86; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key86" UNIQUE (email);


--
-- Name: Users Users_email_key87; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key87" UNIQUE (email);


--
-- Name: Users Users_email_key88; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key88" UNIQUE (email);


--
-- Name: Users Users_email_key89; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key89" UNIQUE (email);


--
-- Name: Users Users_email_key9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key9" UNIQUE (email);


--
-- Name: Users Users_email_key90; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key90" UNIQUE (email);


--
-- Name: Users Users_email_key91; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key91" UNIQUE (email);


--
-- Name: Users Users_email_key92; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key92" UNIQUE (email);


--
-- Name: Users Users_email_key93; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key93" UNIQUE (email);


--
-- Name: Users Users_email_key94; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key94" UNIQUE (email);


--
-- Name: Users Users_email_key95; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key95" UNIQUE (email);


--
-- Name: Users Users_email_key96; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key96" UNIQUE (email);


--
-- Name: Users Users_email_key97; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key97" UNIQUE (email);


--
-- Name: Users Users_email_key98; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key98" UNIQUE (email);


--
-- Name: Users Users_email_key99; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key99" UNIQUE (email);


--
-- Name: Users Users_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key1" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key10; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key10" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key100; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key100" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key101; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key101" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key102; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key102" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key103; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key103" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key104; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key104" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key105; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key105" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key106; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key106" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key107; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key107" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key108; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key108" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key109; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key109" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key11; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key11" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key110; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key110" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key111; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key111" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key112; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key112" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key113; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key113" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key114; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key114" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key115; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key115" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key116; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key116" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key117; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key117" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key118; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key118" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key119; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key119" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key12; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key12" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key120; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key120" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key121; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key121" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key122; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key122" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key123; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key123" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key124; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key124" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key125; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key125" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key126; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key126" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key127; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key127" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key128; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key128" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key129; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key129" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key13; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key13" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key130; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key130" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key131; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key131" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key132; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key132" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key133; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key133" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key134; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key134" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key135; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key135" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key136; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key136" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key137; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key137" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key138; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key138" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key139; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key139" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key14; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key14" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key140; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key140" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key141; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key141" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key142; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key142" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key143; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key143" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key144; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key144" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key145; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key145" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key146; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key146" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key147; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key147" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key148; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key148" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key149; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key149" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key15; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key15" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key150; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key150" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key151; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key151" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key152; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key152" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key153; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key153" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key154; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key154" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key155; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key155" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key156; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key156" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key157; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key157" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key158; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key158" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key159; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key159" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key16; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key16" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key160; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key160" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key161; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key161" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key162; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key162" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key163; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key163" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key164; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key164" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key165; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key165" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key166; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key166" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key167; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key167" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key168; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key168" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key169; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key169" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key17; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key17" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key170; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key170" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key171; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key171" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key172; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key172" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key173; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key173" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key174; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key174" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key175; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key175" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key176; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key176" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key177; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key177" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key178; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key178" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key179; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key179" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key18; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key18" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key180; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key180" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key181; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key181" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key182; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key182" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key183; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key183" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key184; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key184" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key185; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key185" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key186; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key186" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key187; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key187" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key188; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key188" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key189; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key189" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key19; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key19" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key190; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key190" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key191; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key191" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key192; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key192" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key193; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key193" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key194; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key194" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key195; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key195" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key196; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key196" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key197; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key197" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key198; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key198" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key199; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key199" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key2" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key20; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key20" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key200; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key200" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key201; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key201" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key202; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key202" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key203; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key203" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key204; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key204" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key205; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key205" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key206; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key206" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key207; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key207" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key208; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key208" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key209; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key209" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key21; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key21" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key210; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key210" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key211; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key211" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key212; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key212" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key213; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key213" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key214; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key214" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key215; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key215" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key216; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key216" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key217; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key217" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key218; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key218" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key219; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key219" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key22; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key22" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key220; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key220" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key221; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key221" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key222; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key222" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key223; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key223" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key224; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key224" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key225; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key225" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key226; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key226" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key227; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key227" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key228; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key228" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key229; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key229" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key23; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key23" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key230; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key230" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key231; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key231" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key232; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key232" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key233; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key233" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key234; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key234" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key235; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key235" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key236; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key236" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key237; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key237" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key238; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key238" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key239; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key239" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key24; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key24" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key240; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key240" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key241; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key241" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key242; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key242" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key243; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key243" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key244; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key244" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key245; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key245" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key246; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key246" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key247; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key247" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key248; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key248" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key249; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key249" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key25; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key25" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key250; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key250" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key251; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key251" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key252; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key252" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key253; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key253" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key254; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key254" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key255; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key255" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key256; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key256" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key257; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key257" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key258; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key258" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key259; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key259" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key26; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key26" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key260; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key260" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key261; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key261" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key262; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key262" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key263; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key263" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key264; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key264" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key265; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key265" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key266; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key266" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key267; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key267" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key268; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key268" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key269; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key269" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key27; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key27" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key270; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key270" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key271; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key271" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key272; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key272" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key273; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key273" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key274; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key274" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key275; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key275" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key276; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key276" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key277; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key277" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key278; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key278" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key279; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key279" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key28; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key28" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key280; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key280" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key281; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key281" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key282; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key282" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key283; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key283" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key284; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key284" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key285; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key285" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key286; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key286" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key287; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key287" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key288; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key288" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key289; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key289" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key29; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key29" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key290; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key290" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key291; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key291" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key292; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key292" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key293; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key293" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key294; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key294" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key295; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key295" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key296; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key296" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key297; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key297" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key298; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key298" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key299; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key299" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key3" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key30; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key30" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key300; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key300" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key301; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key301" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key31; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key31" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key32; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key32" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key33; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key33" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key34; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key34" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key35; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key35" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key36; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key36" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key37; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key37" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key38; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key38" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key39; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key39" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key4" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key40; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key40" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key41; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key41" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key42; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key42" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key43; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key43" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key44; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key44" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key45; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key45" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key46; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key46" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key47; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key47" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key48; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key48" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key49; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key49" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key5" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key50; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key50" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key51; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key51" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key52; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key52" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key53; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key53" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key54; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key54" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key55; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key55" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key56; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key56" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key57" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key58; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key58" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key59; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key59" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key6" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key60; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key60" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key61; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key61" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key62; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key62" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key63; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key63" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key64; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key64" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key65; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key65" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key66; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key66" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key67; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key67" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key68; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key68" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key69; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key69" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key7" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key70; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key70" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key71; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key71" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key72; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key72" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key73; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key73" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key74; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key74" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key75; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key75" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key76; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key76" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key77; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key77" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key78; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key78" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key79; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key79" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key8" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key80; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key80" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key81; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key81" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key82; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key82" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key83; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key83" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key84; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key84" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key85; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key85" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key86; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key86" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key87; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key87" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key88; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key88" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key89; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key89" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key9" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key90; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key90" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key91; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key91" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key92; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key92" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key93; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key93" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key94; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key94" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key95; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key95" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key96; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key96" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key97; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key97" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key98; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key98" UNIQUE (phone_number);


--
-- Name: Users Users_phone_number_key99; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_phone_number_key99" UNIQUE (phone_number);


--
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY (id);


--
-- Name: Users Users_university_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key1" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key10; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key10" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key100; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key100" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key101; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key101" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key102; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key102" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key103; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key103" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key104; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key104" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key105; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key105" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key106; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key106" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key107; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key107" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key108; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key108" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key109; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key109" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key11; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key11" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key110; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key110" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key111; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key111" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key112; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key112" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key113; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key113" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key114; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key114" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key115; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key115" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key116; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key116" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key117; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key117" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key118; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key118" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key119; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key119" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key12; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key12" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key120; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key120" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key121; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key121" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key122; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key122" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key123; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key123" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key124; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key124" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key125; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key125" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key126; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key126" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key127; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key127" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key128; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key128" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key129; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key129" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key13; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key13" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key130; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key130" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key131; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key131" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key132; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key132" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key133; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key133" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key134; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key134" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key135; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key135" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key136; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key136" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key137; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key137" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key138; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key138" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key139; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key139" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key14; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key14" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key140; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key140" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key141; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key141" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key142; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key142" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key143; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key143" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key144; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key144" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key145; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key145" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key146; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key146" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key147; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key147" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key148; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key148" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key149; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key149" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key15; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key15" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key150; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key150" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key151; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key151" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key152; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key152" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key153; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key153" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key154; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key154" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key155; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key155" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key156; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key156" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key157; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key157" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key158; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key158" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key159; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key159" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key16; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key16" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key160; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key160" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key161; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key161" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key162; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key162" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key163; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key163" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key164; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key164" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key165; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key165" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key166; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key166" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key167; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key167" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key168; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key168" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key169; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key169" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key17; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key17" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key170; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key170" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key171; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key171" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key172; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key172" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key173; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key173" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key174; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key174" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key175; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key175" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key176; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key176" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key177; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key177" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key178; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key178" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key179; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key179" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key18; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key18" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key180; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key180" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key181; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key181" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key182; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key182" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key183; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key183" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key184; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key184" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key185; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key185" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key186; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key186" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key187; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key187" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key188; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key188" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key189; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key189" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key19; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key19" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key190; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key190" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key191; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key191" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key192; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key192" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key193; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key193" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key194; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key194" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key195; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key195" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key196; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key196" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key197; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key197" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key198; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key198" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key199; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key199" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key2" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key20; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key20" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key200; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key200" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key201; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key201" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key202; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key202" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key203; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key203" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key204; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key204" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key205; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key205" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key206; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key206" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key207; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key207" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key208; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key208" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key209; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key209" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key21; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key21" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key210; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key210" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key211; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key211" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key212; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key212" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key213; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key213" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key214; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key214" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key215; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key215" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key216; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key216" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key217; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key217" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key218; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key218" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key219; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key219" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key22; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key22" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key220; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key220" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key221; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key221" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key222; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key222" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key223; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key223" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key224; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key224" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key225; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key225" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key226; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key226" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key227; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key227" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key228; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key228" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key229; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key229" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key23; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key23" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key230; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key230" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key231; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key231" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key232; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key232" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key233; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key233" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key234; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key234" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key235; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key235" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key236; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key236" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key237; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key237" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key238; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key238" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key239; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key239" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key24; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key24" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key240; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key240" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key241; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key241" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key242; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key242" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key243; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key243" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key244; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key244" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key245; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key245" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key246; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key246" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key247; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key247" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key248; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key248" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key249; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key249" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key25; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key25" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key250; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key250" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key251; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key251" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key252; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key252" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key253; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key253" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key254; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key254" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key255; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key255" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key256; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key256" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key257; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key257" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key258; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key258" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key259; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key259" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key26; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key26" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key260; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key260" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key261; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key261" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key262; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key262" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key263; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key263" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key264; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key264" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key265; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key265" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key266; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key266" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key267; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key267" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key268; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key268" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key269; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key269" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key27; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key27" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key270; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key270" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key271; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key271" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key272; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key272" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key273; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key273" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key274; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key274" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key275; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key275" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key276; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key276" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key277; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key277" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key278; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key278" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key279; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key279" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key28; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key28" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key280; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key280" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key281; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key281" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key282; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key282" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key283; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key283" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key284; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key284" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key285; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key285" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key286; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key286" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key287; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key287" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key288; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key288" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key289; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key289" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key29; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key29" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key290; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key290" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key291; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key291" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key292; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key292" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key293; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key293" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key294; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key294" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key295; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key295" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key296; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key296" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key297; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key297" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key298; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key298" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key299; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key299" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key3" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key30; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key30" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key300; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key300" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key301; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key301" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key302; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key302" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key303; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key303" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key31; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key31" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key32; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key32" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key33; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key33" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key34; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key34" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key35; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key35" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key36; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key36" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key37; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key37" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key38; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key38" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key39; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key39" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key4" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key40; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key40" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key41; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key41" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key42; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key42" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key43; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key43" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key44; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key44" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key45; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key45" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key46; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key46" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key47; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key47" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key48; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key48" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key49; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key49" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key5" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key50; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key50" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key51; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key51" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key52; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key52" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key53; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key53" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key54; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key54" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key55; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key55" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key56; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key56" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key57" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key58; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key58" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key59; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key59" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key6" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key60; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key60" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key61; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key61" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key62; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key62" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key63; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key63" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key64; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key64" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key65; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key65" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key66; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key66" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key67; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key67" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key68; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key68" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key69; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key69" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key7" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key70; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key70" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key71; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key71" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key72; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key72" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key73; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key73" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key74; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key74" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key75; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key75" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key76; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key76" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key77; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key77" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key78; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key78" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key79; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key79" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key8" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key80; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key80" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key81; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key81" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key82; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key82" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key83; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key83" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key84; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key84" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key85; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key85" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key86; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key86" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key87; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key87" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key88; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key88" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key89; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key89" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key9" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key90; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key90" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key91; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key91" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key92; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key92" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key93; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key93" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key94; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key94" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key95; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key95" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key96; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key96" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key97; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key97" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key98; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key98" UNIQUE (university_id);


--
-- Name: Users Users_university_id_key99; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_university_id_key99" UNIQUE (university_id);


--
-- Name: Users Users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_username_key" UNIQUE (username);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: Disputes Disputes_complainant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Disputes"
    ADD CONSTRAINT "Disputes_complainant_id_fkey" FOREIGN KEY (complainant_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Disputes Disputes_handled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Disputes"
    ADD CONSTRAINT "Disputes_handled_by_fkey" FOREIGN KEY (handled_by) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Disputes Disputes_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Disputes"
    ADD CONSTRAINT "Disputes_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES public."Transactions"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Follows Follows_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Follows"
    ADD CONSTRAINT "Follows_follower_id_fkey" FOREIGN KEY (follower_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Follows Follows_following_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Follows"
    ADD CONSTRAINT "Follows_following_id_fkey" FOREIGN KEY (following_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Messages Messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT "Messages_receiver_id_fkey" FOREIGN KEY (receiver_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Messages Messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT "Messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Notifications Notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "Notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Products Products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public."Categories"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Products Products_seller_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Products Products_sub_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_sub_category_id_fkey" FOREIGN KEY (sub_category_id) REFERENCES public."SubCategories"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Reports Reports_handled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT "Reports_handled_by_fkey" FOREIGN KEY (handled_by) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Reports Reports_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT "Reports_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public."Products"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Reports Reports_reported_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT "Reports_reported_user_id_fkey" FOREIGN KEY (reported_user_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Reports Reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT "Reports_reporter_id_fkey" FOREIGN KEY (reporter_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Reviews Reviews_reviewee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews"
    ADD CONSTRAINT "Reviews_reviewee_id_fkey" FOREIGN KEY (reviewee_id) REFERENCES public."Users"(id) ON UPDATE CASCADE;


--
-- Name: Reviews Reviews_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews"
    ADD CONSTRAINT "Reviews_reviewer_id_fkey" FOREIGN KEY (reviewer_id) REFERENCES public."Users"(id) ON UPDATE CASCADE;


--
-- Name: Reviews Reviews_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews"
    ADD CONSTRAINT "Reviews_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES public."Transactions"(id) ON UPDATE CASCADE;


--
-- Name: SavedItems SavedItems_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SavedItems"
    ADD CONSTRAINT "SavedItems_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public."Products"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SavedItems SavedItems_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SavedItems"
    ADD CONSTRAINT "SavedItems_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SubCategories SubCategories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SubCategories"
    ADD CONSTRAINT "SubCategories_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public."Categories"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SupportTickets SupportTickets_handled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SupportTickets"
    ADD CONSTRAINT "SupportTickets_handled_by_fkey" FOREIGN KEY (handled_by) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: SupportTickets SupportTickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SupportTickets"
    ADD CONSTRAINT "SupportTickets_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TicketMessages TicketMessages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TicketMessages"
    ADD CONSTRAINT "TicketMessages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Transactions Transactions_buyer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_buyer_id_fkey" FOREIGN KEY (buyer_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Transactions Transactions_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public."Products"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Transactions Transactions_seller_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: logs logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."Users"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict rRkNsfazxdooFF575UfAbXjvygToap0jYzdwdbdEfjH47YWziY8PnsGOVPrdI4B

