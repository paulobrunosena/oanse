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
  ('presenca',     'Presença no sábado',           10),
  ('uniforme',     'Está com o uniforme',          10),
  ('biblia',       'Trouxe a Bíblia',              10),
  ('ebd',          'Participou da EBD',            10),
  ('manual',       'Trouxe o manual',              10),
  ('conduta',      'Boa conduta no clube',         10),
  ('secao_manual', 'Por seção do manual concluída', 5);

insert into jogos_pontos_config (colocacao, pontos) values
  (1, 100), (2, 70), (3, 50), (4, 40);

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
select seed_auth_user('tia.ana@oanse.local',  'oanse123', 'Tia Ana',            '81999990004', 'lider', 'ursinhos');

-- Turma da líder Tia Ana + oansistas
do $$
declare
  v_lider uuid;
  v_turma uuid;
begin
  select id into v_lider from profiles where nome = 'Tia Ana';
  insert into turmas (clube_id, lider_id, nome)
  values ((select id from clubes where slug = 'ursinhos'), v_lider, 'Turma 1 - Tia Ana')
  returning id into v_turma;

  insert into oansistas (nome, data_nascimento, clube_id, turma_id, responsavel, contato) values
    ('Miguel Sousa',   '2021-03-15', (select id from clubes where slug = 'ursinhos'), v_turma, 'Carla Sousa',  '81988880101'),
    ('Helena Lima',    '2021-07-02', (select id from clubes where slug = 'ursinhos'), v_turma, 'Rita Lima',    '81988880102'),
    ('Benício Alves',  '2022-01-20', (select id from clubes where slug = 'ursinhos'), v_turma, 'João Alves',   '81988880103'),
    ('Alice Ferreira', '2021-11-08', (select id from clubes where slug = 'ursinhos'), v_turma, 'Marta Pereira','81988880104');
end $$;

drop function seed_auth_user(text, text, text, text, text, text);
