--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7
-- Dumped by pg_dump version 14.7

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
-- Data for Name: club; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.club (id, name, entry_age, leave_age) VALUES (1, 'Ursinho', 4, 6);
INSERT INTO public.club (id, name, entry_age, leave_age) VALUES (2, 'Faísca', 6, 9);
INSERT INTO public.club (id, name, entry_age, leave_age) VALUES (3, 'Flama', 9, 11);
INSERT INTO public.club (id, name, entry_age, leave_age) VALUES (4, 'Tocha', 11, 13);
INSERT INTO public.club (id, name, entry_age, leave_age) VALUES (5, 'JV', 13, 15);
INSERT INTO public.club (id, name, entry_age, leave_age) VALUES (6, 'VQ7', 15, 19);


--
-- Name: club_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.club_id_seq', 6, true);


--
-- PostgreSQL database dump complete
--

