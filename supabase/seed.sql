-- ============================================================================
-- OANSE - Seed local: clubes, itens de pontuação e config de jogos.
-- Aplicado automaticamente após as migrations por `npx supabase db reset`.
-- ============================================================================

insert into clubes (nome, slug, idade_min, idade_max, cor, ordem) values
  ('Ursinhos', 'ursinhos', 4, 5, '#EF4444', 1),
  ('Faíscas',  'faiscas',  6, 8, '#EAB308', 2),
  ('Flamas',   'flamas',   9, 10, '#22C55E', 3),
  ('Tochas',   'tochas',   11, 12, '#3B82F6', 4);

insert into itens_pontuacao (chave, descricao, pontos) values
  ('presenca',           'Presença no sábado',                10),
  ('uniforme',           'Está com o uniforme',               10),
  ('biblia',             'Trouxe a Bíblia',                   10),
  ('ebd',                'Participou da EBD',                 10),
  ('manual',             'Trouxe o manual',                   10),
  ('conduta',            'Boa conduta no clube',              10),
  ('leitura_biblica',    'Leitura bíblica',                   10),
  ('visitante',          'Por visitante convidado',            5),
  ('secao_sem_ajuda',    'Por seção do manual sem ajuda',     10),
  ('secao_com_ajuda',    'Por seção do manual com ajuda',      5),
  ('jogo_1_lugar',       'Jogos do sábado: 1º lugar',          5),
  ('jogo_2_lugar',       'Jogos do sábado: 2º lugar',          4),
  ('jogo_3_lugar',       'Jogos do sábado: 3º lugar',          3),
  ('jogo_4_lugar',       'Jogos do sábado: 4º lugar',          2)
on conflict (chave) do nothing;

insert into jogos_pontos_config (colocacao, pontos) values
  (1, 100), (2, 70), (3, 50), (4, 40);

-- ============================================================================
-- Catálogo de jogos por clube (alimenta o combo do registro de rodadas)
-- ============================================================================
insert into jogos_catalogo (clube_id, nome) values
  ((select id from clubes where slug = 'ursinhos'), 'trenzinho de mãos dadas'),
  ((select id from clubes where slug = 'ursinhos'), 'de gatinhos (em pé)'),
  ((select id from clubes where slug = 'ursinhos'), 'saquinho de feijão na cabeça'),
  ((select id from clubes where slug = 'faiscas'),  'de gatinhos (de joelhos)'),
  ((select id from clubes where slug = 'faiscas'),  'saquinho de feijão na cabeça'),
  ((select id from clubes where slug = 'faiscas'),  'agilidade zigue-zague'),
  ((select id from clubes where slug = 'faiscas'),  'queimada'),
  ((select id from clubes where slug = 'faiscas'),  'boliche dos faíscas'),
  ((select id from clubes where slug = 'faiscas'),  'revezamento com bexigas'),
  ((select id from clubes where slug = 'flamas'),   'revezamento com saquinho de feijão'),
  ((select id from clubes where slug = 'flamas'),   'corrida de 3 pernas'),
  ((select id from clubes where slug = 'flamas'),   'revezamento sprint'),
  ((select id from clubes where slug = 'flamas'),   'agilidade zigue-zague'),
  ((select id from clubes where slug = 'flamas'),   'sprint'),
  ((select id from clubes where slug = 'flamas'),   'cabo de guerra'),
  ((select id from clubes where slug = 'flamas'),   'derrubando o pino'),
  ((select id from clubes where slug = 'flamas'),   'revezamento maratona'),
  ((select id from clubes where slug = 'flamas'),   'bonanza'),
  ((select id from clubes where slug = 'flamas'),   'maratona'),
  ((select id from clubes where slug = 'flamas'),   'bola no túnel'),
  ((select id from clubes where slug = 'tochas'),   'revezamento com saquinho de feijão'),
  ((select id from clubes where slug = 'tochas'),   'corrida de 3 pernas'),
  ((select id from clubes where slug = 'tochas'),   'revezamento sprint'),
  ((select id from clubes where slug = 'tochas'),   'agilidade zigue-zague'),
  ((select id from clubes where slug = 'tochas'),   'sprint'),
  ((select id from clubes where slug = 'tochas'),   'cabo de guerra'),
  ((select id from clubes where slug = 'tochas'),   'derrubando o pino'),
  ((select id from clubes where slug = 'tochas'),   'revezamento maratona'),
  ((select id from clubes where slug = 'tochas'),   'bonanza'),
  ((select id from clubes where slug = 'tochas'),   'maratona'),
  ((select id from clubes where slug = 'tochas'),   'bola no túnel'),
  ((select id from clubes where slug = 'tochas'),   'revezamento com bola de basquete');

-- ============================================================================
-- Usuários de teste (senha: oanse123). O trigger on_auth_user_created cria o
-- profile a partir dos metadados; depois vinculamos o clube onde aplicável.
-- ============================================================================

create or replace function seed_auth_user(
  p_email text, p_senha text, p_nome text, p_telefone text, p_role text, p_clube_slug text default null
) returns uuid
language plpgsql security definer set search_path = auth, public, extensions as $$
declare
  v_uid uuid := gen_random_uuid();
  v_clube uuid;
begin
  insert into auth.users (id, instance_id, aud, role, email, phone, encrypted_password,
                          email_confirmed_at, confirmation_token, recovery_token,
                          email_change, email_change_token_current, email_change_token_new,
                          created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          p_email, null, crypt(p_senha, gen_salt('bf')),
          now(), '', '', '', '', '',
          now(), now(),
          '{"provider":"email","providers":["email"]}'::jsonb,
          jsonb_build_object('nome', p_nome, 'telefone', p_telefone, 'role', p_role));

  insert into auth.identities (id, user_id, provider_id, identity_data, provider,
                               last_sign_in_at, created_at, updated_at)
  values (v_uid, v_uid, v_uid::text,
          jsonb_build_object('sub', v_uid::text, 'email', p_email, 'email_verified', true),
          'email', now(), now(), now());

  if p_clube_slug is not null then
    select id into v_clube from clubes where slug = p_clube_slug;
    update profiles set clube_id = v_clube where id = v_uid;
  end if;

  return v_uid;
end $$;

select seed_auth_user('diretor@oanse.local',  'oanse123', 'Diretor Geral',      '81999990001', 'diretor_geral');
select seed_auth_user('secretaria@oanse.local','oanse123', 'Secretária',        '81999990002', 'secretaria');
select seed_auth_user('diretor.ursinhos@oanse.local', 'oanse123', 'Diretor Ursinhos', '81999990003', 'diretor_clube', 'ursinhos');
select seed_auth_user('diretor.faiscas@oanse.local',  'oanse123', 'Diretor Faíscas',  '81999990006', 'diretor_clube', 'faiscas');
select seed_auth_user('diretor.flamas@oanse.local',   'oanse123', 'Diretor Flamas',   '81999990007', 'diretor_clube', 'flamas');
select seed_auth_user('diretor.tochas@oanse.local',   'oanse123', 'Diretor Tochas',   '81999990008', 'diretor_clube', 'tochas');
select seed_auth_user('lider.jogos@oanse.local', 'oanse123', 'Líder de Jogos',   '81999990005', 'lider_jogos');
select seed_auth_user('tia.ana@oanse.local',    'oanse123', 'Tia Ana',          '81999990004', 'lider', 'ursinhos');
select seed_auth_user('tia.bea@oanse.local',    'oanse123', 'Tia Bea',          '81999990009', 'lider', 'faiscas');
select seed_auth_user('tio.carlos@oanse.local', 'oanse123', 'Tio Carlos',       '81999990010', 'lider', 'flamas');
select seed_auth_user('tia.duda@oanse.local',   'oanse123', 'Tia Duda',         '81999990011', 'lider', 'tochas');

-- Líderes e oansistas de todos os clubes
do $$
declare
  v_turma uuid;
begin
  insert into turmas (clube_id, lider_id, nome)
  values ((select id from clubes where slug = 'ursinhos'), (select id from profiles where nome = 'Tia Ana'), 'Turma 1 - Tia Ana')
  returning id into v_turma;

  insert into oansistas (nome, data_nascimento, clube_id, turma_id, responsavel, contato) values
    ('Miguel Sousa',   '2021-03-15', (select id from clubes where slug = 'ursinhos'), v_turma, 'Carla Sousa',  '81988880101'),
    ('Helena Lima',    '2021-07-02', (select id from clubes where slug = 'ursinhos'), v_turma, 'Rita Lima',    '81988880102'),
    ('Benício Alves',  '2022-01-20', (select id from clubes where slug = 'ursinhos'), v_turma, 'João Alves',   '81988880103'),
    ('Alice Ferreira', '2021-11-08', (select id from clubes where slug = 'ursinhos'), v_turma, 'Marta Pereira','81988880104');

  insert into turmas (clube_id, lider_id, nome)
  values ((select id from clubes where slug = 'faiscas'), (select id from profiles where nome = 'Tia Bea'), 'Turma 1 - Tia Bea')
  returning id into v_turma;

  insert into oansistas (nome, data_nascimento, clube_id, turma_id, responsavel, contato) values
    ('Davi Rocha',   '2019-04-10', (select id from clubes where slug = 'faiscas'), v_turma, 'Ana Rocha',    '81988880201'),
    ('Laura Castro', '2018-09-22', (select id from clubes where slug = 'faiscas'), v_turma, 'Paula Castro', '81988880202'),
    ('Heitor Dias',  '2019-01-05', (select id from clubes where slug = 'faiscas'), v_turma, 'Jorge Dias',   '81988880203');

  insert into turmas (clube_id, lider_id, nome)
  values ((select id from clubes where slug = 'flamas'), (select id from profiles where nome = 'Tio Carlos'), 'Turma 1 - Tio Carlos')
  returning id into v_turma;

  insert into oansistas (nome, data_nascimento, clube_id, turma_id, responsavel, contato) values
    ('Valentina Nunes', '2016-06-14', (select id from clubes where slug = 'flamas'), v_turma, 'Sônia Nunes',  '81988880301'),
    ('Gabriel Pinto',   '2017-02-28', (select id from clubes where slug = 'flamas'), v_turma, 'Rafael Pinto', '81988880302'),
    ('Cecília Ramos',   '2016-11-09', (select id from clubes where slug = 'flamas'), v_turma, 'Lúcia Ramos',  '81988880303'),
    ('Arthur Melo',     '2017-07-17', (select id from clubes where slug = 'flamas'), v_turma, 'Pedro Melo',   '81988880304');

  insert into turmas (clube_id, lider_id, nome)
  values ((select id from clubes where slug = 'tochas'), (select id from profiles where nome = 'Tia Duda'), 'Turma 1 - Tia Duda')
  returning id into v_turma;

  insert into oansistas (nome, data_nascimento, clube_id, turma_id, responsavel, contato) values
    ('Samuel Barros',  '2015-03-30', (select id from clubes where slug = 'tochas'), v_turma, 'Mônica Barros', '81988880401'),
    ('Isabela Farias', '2014-10-12', (select id from clubes where slug = 'tochas'), v_turma, 'Tadeu Farias',  '81988880402'),
    ('Theo Cardoso',   '2015-08-21', (select id from clubes where slug = 'tochas'), v_turma, 'Diana Cardoso', '81988880403'),
    ('Larissa Prado',  '2014-12-04', (select id from clubes where slug = 'tochas'), v_turma, 'Vera Prado',    '81988880404');
end $$;

drop function seed_auth_user(text, text, text, text, text, text);
