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
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.role (id, name, description) VALUES (1, 'Líder de clube', 'Líder responsável por passar as seções dos manuais e evangelizar as crianças sobre sua responsabilidade');
INSERT INTO public.role (id, name, description) VALUES (2, 'Diretor de clube', 'Responsável por líderar os líderes de clube');
INSERT INTO public.role (id, name, description) VALUES (3, 'Secretária geral', 'Responsável por gerir material do oanse');
INSERT INTO public.role (id, name, description) VALUES (4, 'Diretor geral', 'Responsável por gerir o oanse na igreja local');


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_id_seq', 4, true);


--
-- PostgreSQL database dump complete
--

