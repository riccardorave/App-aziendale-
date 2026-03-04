--
-- PostgreSQL database dump
--

\restrict iH4ERXVAhh5itel4odNmx63huMc0qFEaMpf1rLAyiWKETVr1MHjYfVVJB25oDyO

-- Dumped from database version 16.12
-- Dumped by pg_dump version 16.12

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
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: booking_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.booking_status AS ENUM (
    'confirmed',
    'cancelled',
    'pending'
);


ALTER TYPE public.booking_status OWNER TO postgres;

--
-- Name: resource_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.resource_type AS ENUM (
    'meeting_room',
    'desk',
    'equipment'
);


ALTER TYPE public.resource_type OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'employee',
    'admin'
);


ALTER TYPE public.user_role OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    resource_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    notes text,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    status public.booking_status DEFAULT 'confirmed'::public.booking_status NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.bookings OWNER TO postgres;

--
-- Name: resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resources (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(150) NOT NULL,
    type public.resource_type NOT NULL,
    description text,
    capacity integer,
    location character varying(100),
    amenities jsonb DEFAULT '[]'::jsonb,
    is_active boolean DEFAULT true,
    image_url character varying(255),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.resources OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password character varying(255) NOT NULL,
    role public.user_role DEFAULT 'employee'::public.user_role NOT NULL,
    department character varying(100),
    avatar_color character varying(7) DEFAULT '#4F46E5'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    reset_token character varying(255),
    reset_token_expires timestamp with time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (id, user_id, resource_id, title, notes, start_time, end_time, status, created_at, updated_at) FROM stdin;
cb0977f0-63d1-494a-bb4b-025b808d8275	0f34d649-3ec2-4050-90b9-7d0be866eec7	14b2aa26-a3ef-4653-9df0-4a7363fab939	postazione 1		2026-02-27 15:00:00+01	2026-02-27 16:00:00+01	confirmed	2026-02-27 14:18:23.085778+01	2026-02-27 14:18:23.085778+01
f56b5f93-faa3-4e01-952e-88941b3882f4	0f34d649-3ec2-4050-90b9-7d0be866eec7	14b2aa26-a3ef-4653-9df0-4a7363fab939	postazione 1		2026-02-28 15:00:00+01	2026-02-28 16:00:00+01	confirmed	2026-02-28 14:42:27.105776+01	2026-02-28 14:42:27.105776+01
dc5a49e5-2cac-45c1-9572-9e69065d274b	0f34d649-3ec2-4050-90b9-7d0be866eec7	14b2aa26-a3ef-4653-9df0-4a7363fab939	postazione 1		2026-02-28 18:00:00+01	2026-02-28 19:00:00+01	cancelled	2026-02-28 14:49:51.114038+01	2026-02-28 14:50:22.669595+01
3d989c5e-99e9-4cb4-91e1-39c469bc66b1	0f34d649-3ec2-4050-90b9-7d0be866eec7	14b2aa26-a3ef-4653-9df0-4a7363fab939	postazione 1		2026-02-28 17:00:00+01	2026-02-28 18:00:00+01	cancelled	2026-02-28 14:55:50.202814+01	2026-02-28 14:56:02.847103+01
\.


--
-- Data for Name: resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resources (id, name, type, description, capacity, location, amenities, is_active, image_url, created_at) FROM stdin;
601db045-d6d8-43af-a113-2f8c48b20bcb	Sala Alfa	meeting_room	Sala riunioni principale con vista esterna	10	Piano 1	["Proiettore", "Lavagna", "Videoconferenza", "Clima"]	t	\N	2026-02-25 13:44:49.375325+01
37ae7921-5618-476f-9334-54f68795cace	Sala Beta	meeting_room	Sala piccola per call e meeting rapidi	4	Piano 1	["TV 55 pollici", "Webcam", "Lavagna magnetica"]	t	\N	2026-02-25 13:44:49.375325+01
efc44fab-2b00-41ff-8cc1-addd775ade92	Sala Gamma	meeting_room	Sala executive per presentazioni clienti	16	Piano 2	["Proiettore 4K", "Sistema audio", "Clima"]	t	\N	2026-02-25 13:44:49.375325+01
bda8c329-00f9-44b6-a670-28d81de9b302	Desk A1	desk	Postazione open space zona A	1	Piano 1 - Open Space A	["Monitor 27 pollici", "Dock USB-C", "Locker"]	t	\N	2026-02-25 13:44:49.375325+01
1a8f83b8-ca58-4710-bebc-746a8a63bf0f	Desk A2	desk	Postazione open space zona A	1	Piano 1 - Open Space A	["Monitor 27 pollici", "Dock USB-C", "Locker"]	t	\N	2026-02-25 13:44:49.375325+01
83731048-1416-4e53-b9eb-919df216382d	Desk B1	desk	Postazione open space zona B vicino finestre	1	Piano 1 - Open Space B	["Monitor 34 Ultrawide", "Dock", "Vista esterna"]	t	\N	2026-02-25 13:44:49.375325+01
2e7c4eff-4867-4575-abc4-f2dba5666caa	Proiettore Portatile	equipment	Proiettore Full HD con borsa trasporto	\N	Armadio Attrezzature	["HDMI", "VGA", "USB", "Telecomando"]	t	\N	2026-02-25 13:44:49.375325+01
18d77aec-a4ea-476c-b1c0-051c24633c98	MacBook Pro 16	equipment	Laptop per presentazioni esterne o smart working	\N	Armadio Attrezzature	["M3 Pro", "32GB RAM", "Caricatore incluso"]	t	\N	2026-02-25 13:44:49.375325+01
92706880-1ed1-4586-84c0-1a80ab1ce4dc	Kit Videoconferenza	equipment	Webcam 4K + microfono omnidirezionale + speaker	\N	Armadio Attrezzature	["USB-C", "Compatibile Zoom e Teams", "Custodia"]	t	\N	2026-02-25 13:44:49.375325+01
5e8b69cf-3691-4175-8baa-10cfb79ed925	gaga	meeting_room	proca	3	piano 1	["lavagna"]	t	\N	2026-02-25 20:51:49.337201+01
14b2aa26-a3ef-4653-9df0-4a7363fab939	sala 1	meeting_room	hahah	8	piano 1	["lavagna"]	t	\N	2026-02-27 14:12:16.570037+01
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password, role, department, avatar_color, created_at, updated_at, reset_token, reset_token_expires) FROM stdin;
60225f37-e5a1-4a09-9388-c926327098f1	Marco Rossi	marco.rossi@company.com	$2b$10$2k7phXW3kUOhRM0g0NT3AOSabsE.MypyYGRqyGr0eyUVndM94OEB.	employee	Sviluppo	#059669	2026-02-25 13:44:49.368811+01	2026-02-25 13:44:49.368811+01	\N	\N
488bebdf-470b-40b7-91c1-a0b01a4d64c7	Laura Bianchi	laura.bianchi@company.com	$2b$10$2k7phXW3kUOhRM0g0NT3AOSabsE.MypyYGRqyGr0eyUVndM94OEB.	employee	Marketing	#DC2626	2026-02-25 13:44:49.368811+01	2026-02-25 13:44:49.368811+01	\N	\N
35123e7f-3f50-4ae3-be6a-30d953dd1db6	Giovanni Verdi	giovanni.verdi@company.com	$2b$10$2k7phXW3kUOhRM0g0NT3AOSabsE.MypyYGRqyGr0eyUVndM94OEB.	employee	Commerciale	#D97706	2026-02-25 13:44:49.368811+01	2026-02-25 13:44:49.368811+01	\N	\N
0f34d649-3ec2-4050-90b9-7d0be866eec7	Admin Sistema	riccardor404@gmail.com	$2b$10$3KfhbXr/wFqrCDgjtzE.tO4HcmI0SThDv5JpJWdzBN8HgvyFTeq4O	admin	IT	#7C3AED	2026-02-25 13:44:49.368811+01	2026-02-25 13:44:49.368811+01	d4b8d3a3b0b82f5671fc014bc43038c09cb3ad2ae84347e9cb13ddce19f601ef	2026-02-28 15:31:26.243+01
\.


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: bookings no_overlap; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT no_overlap EXCLUDE USING gist (resource_id WITH =, tstzrange(start_time, end_time, '[)'::text) WITH &&) WHERE ((status = 'confirmed'::public.booking_status));


--
-- Name: resources resources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_bookings_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_date ON public.bookings USING btree (start_time);


--
-- Name: idx_bookings_resource_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_resource_time ON public.bookings USING btree (resource_id, start_time, end_time);


--
-- Name: idx_bookings_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_user ON public.bookings USING btree (user_id);


--
-- Name: idx_resources_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resources_type ON public.resources USING btree (type);


--
-- Name: bookings bookings_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.resources(id) ON DELETE CASCADE;


--
-- Name: bookings bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict iH4ERXVAhh5itel4odNmx63huMc0qFEaMpf1rLAyiWKETVr1MHjYfVVJB25oDyO

