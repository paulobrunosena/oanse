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
-- Data for Name: manual; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.manual (id, name, club) VALUES (1, 'Manual Amor', 1);
INSERT INTO public.manual (id, name, club) VALUES (2, 'Manual Alegria', 1);
INSERT INTO public.manual (id, name, club) VALUES (3, 'Manual Saltador', 2);
INSERT INTO public.manual (id, name, club) VALUES (4, 'Manual Caminhante', 2);
INSERT INTO public.manual (id, name, club) VALUES (5, 'Manual Escalador', 2);
INSERT INTO public.manual (id, name, club) VALUES (6, 'Manual Sabiá', 3);
INSERT INTO public.manual (id, name, club) VALUES (7, 'Manual Águia', 3);
INSERT INTO public.manual (id, name, club) VALUES (8, 'Manual Carneiro', 4);
INSERT INTO public.manual (id, name, club) VALUES (9, 'Manual Leão', 4);
INSERT INTO public.manual (id, name, club) VALUES (10, 'Manual Sprint', 5);


--
-- Name: manual_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.manual_id_seq', 10, true);


--
-- PostgreSQL database dump complete
--

