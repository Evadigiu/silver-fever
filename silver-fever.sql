-- ============================================================
-- SILVER FEVER · Héléana's 30th Birthday
-- Base de données du site (projet Supabase dédié « silver-fever »)
-- ============================================================
-- À lancer dans Supabase > SQL Editor > New query > Run.
-- Le script peut être relancé sans danger : il ne supprime aucune donnée.
-- À lancer UNIQUEMENT dans le projet de la fête, jamais dans celui
-- du Sanctuaire des Brumes.
--
-- Principe de sécurité :
--   * Les invités (rôle « anon ») n'ont accès à AUCUNE table.
--     Ils passent uniquement par 3 fonctions qui vérifient le code
--     d'invitation et ne renvoient jamais de données privées.
--   * L'organisatrice se connecte à admin.html avec un compte Supabase
--     (e-mail + mot de passe). Seules les adresses listées dans
--     sf_admins peuvent lire et modifier les données.
-- ============================================================


-- ---------- 1. Outil : une clé de comparaison pour les noms ----------
-- « Jean-Marc Müller » et « jean marc muller » donnent la même clé,
-- ce qui permet de rapprocher les réponses de la liste des invités.
create or replace function public.sf_cle(p_prenom text, p_nom text)
returns text
language sql
immutable
as $$
  select trim(regexp_replace(
    translate(
      lower(coalesce(p_prenom, '') || ' ' || coalesce(p_nom, '')),
      'àâäáãåçéèêëíìîïñóòôöõøúùûüýÿ-''’.',
      'aaaaaaceeeeiiiinoooooouuuuyy    '
    ),
    '\s+', ' ', 'g'
  ));
$$;
revoke all on function public.sf_cle(text, text) from anon;


-- ---------- 2. Les tables ----------

-- Réglages (une seule ligne)
create table if not exists public.sf_reglages (
  id               smallint primary key default 1 check (id = 1),
  code_invitation  text not null check (char_length(code_invitation) between 4 and 40),
  guest_list_mode  text not null default 'nombre'
                   check (guest_list_mode in ('masque', 'nombre', 'prenoms')),
  modifie_le       timestamptz not null default now()
);

-- Le code d'invitation de départ. CHANGE-LE dans admin.html (onglet Réglages)
-- ou ici avant de lancer le script.
insert into public.sf_reglages (id, code_invitation)
values (1, 'SILVER30')
on conflict (id) do nothing;

-- Les adresses e-mail autorisées à ouvrir admin.html
create table if not exists public.sf_admins (
  email  text primary key check (email = lower(email))
);

-- La liste des personnes invitées (sert à savoir qui n'a pas répondu)
create table if not exists public.sf_invites (
  id       bigint generated always as identity primary key,
  prenom   text not null check (char_length(prenom) between 1 and 60),
  nom      text not null default '' check (char_length(nom) <= 60),
  cle      text generated always as (public.sf_cle(prenom, nom)) stored unique,
  cree_le  timestamptz not null default now()
);

-- Les réponses. Une seule réponse par personne : si quelqu'un répond
-- à nouveau avec les mêmes prénom et nom, sa réponse est mise à jour.
create table if not exists public.sf_reponses (
  id          bigint generated always as identity primary key,
  prenom      text not null check (char_length(prenom) between 1 and 60),
  nom         text not null check (char_length(nom) between 1 and 60),
  cle         text generated always as (public.sf_cle(prenom, nom)) stored unique,
  email       text check (email is null or (char_length(email) <= 120 and email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')),
  venue       boolean not null,
  allergies   text check (allergies is null or char_length(allergies) <= 300),
  mot         text check (mot is null or char_length(mot) <= 600),
  visible     boolean not null default false,
  cree_le     timestamptz not null default now(),
  modifie_le  timestamptz not null default now()
);

-- La playlist proposée par les invités (la table existait peut-être déjà)
create table if not exists public.sf_sons (
  id           bigint generated always as identity primary key,
  titre        text not null check (char_length(titre) between 1 and 120),
  artiste      text check (artiste is null or char_length(artiste) <= 120),
  propose_par  text check (propose_par is null or char_length(propose_par) <= 60),
  cree_le      timestamptz not null default now()
);


-- ---------- 3. Verrouillage ----------

alter table public.sf_reglages enable row level security;
alter table public.sf_admins   enable row level security;
alter table public.sf_invites  enable row level security;
alter table public.sf_reponses enable row level security;
alter table public.sf_sons     enable row level security;

-- Anciennes règles de la première version du site (accès direct à la playlist)
drop policy if exists "invites ajoutent un son" on public.sf_sons;
drop policy if exists "invites lisent la playlist" on public.sf_sons;

-- Les invités n'ont aucun accès direct aux tables
revoke all on public.sf_reglages, public.sf_admins, public.sf_invites,
              public.sf_reponses, public.sf_sons from anon;

-- Est-ce que la personne connectée est une organisatrice ?
create or replace function public.sf_est_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from sf_admins
    where email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.sf_est_admin() from public, anon;
grant execute on function public.sf_est_admin() to authenticated;

grant select, insert, update, delete on public.sf_invites, public.sf_reponses, public.sf_sons to authenticated;
grant select, update on public.sf_reglages to authenticated;
grant select on public.sf_admins to authenticated;

drop policy if exists "admin invites"  on public.sf_invites;
drop policy if exists "admin reponses" on public.sf_reponses;
drop policy if exists "admin sons"     on public.sf_sons;
drop policy if exists "admin reglages" on public.sf_reglages;
drop policy if exists "admin admins"   on public.sf_admins;

create policy "admin invites"  on public.sf_invites  for all    to authenticated using (public.sf_est_admin()) with check (public.sf_est_admin());
create policy "admin reponses" on public.sf_reponses for all    to authenticated using (public.sf_est_admin()) with check (public.sf_est_admin());
create policy "admin sons"     on public.sf_sons     for all    to authenticated using (public.sf_est_admin()) with check (public.sf_est_admin());
create policy "admin reglages" on public.sf_reglages for all    to authenticated using (public.sf_est_admin()) with check (public.sf_est_admin());
create policy "admin admins"   on public.sf_admins   for select to authenticated using (public.sf_est_admin());


-- ---------- 4. Les fonctions utilisées par le site public ----------

-- Vérifie le code d'invitation (comparaison sans tenir compte des majuscules)
create or replace function public.sf_code_ok(p_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from sf_reglages
    where id = 1 and upper(trim(code_invitation)) = upper(trim(coalesce(p_code, '')))
  );
$$;
revoke all on function public.sf_code_ok(text) from public, anon, authenticated;

-- Ce que le site public a le droit de savoir :
--   le mode de la guest list, le nombre de confirmés, les prénoms des
--   personnes qui ont accepté d'apparaître (si le mode le permet),
--   et la playlist proposée. Jamais de nom de famille, d'e-mail,
--   de réponse négative, d'allergie ni de petit mot.
create or replace function public.sf_public(p_code text)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_mode text;
begin
  if not sf_code_ok(p_code) then
    return json_build_object('code_ok', false);
  end if;

  select guest_list_mode into v_mode from sf_reglages where id = 1;

  return json_build_object(
    'code_ok', true,
    'mode', v_mode,
    'confirmes', case when v_mode = 'masque' then null
                      else (select count(*) from sf_reponses where venue) end,
    'prenoms', case when v_mode = 'prenoms' then coalesce((
                  select json_agg(prenom order by cree_le)
                  from sf_reponses where venue and visible
                ), '[]'::json) else '[]'::json end,
    'sons', coalesce((
      select json_agg(json_build_object('titre', titre, 'artiste', artiste, 'par', propose_par) order by cree_le desc)
      from (select * from sf_sons order by cree_le desc limit 300) s
    ), '[]'::json)
  );
end;
$$;
revoke all on function public.sf_public(text) from public;
grant execute on function public.sf_public(text) to anon, authenticated;

-- Enregistre (ou met à jour) une réponse
create or replace function public.sf_repondre(
  p_code text, p_prenom text, p_nom text, p_email text,
  p_venue boolean, p_allergies text, p_mot text, p_visible boolean
)
returns json
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_maj boolean;
begin
  if not sf_code_ok(p_code) then
    raise exception 'code_invalide' using errcode = 'P0001';
  end if;
  if (select count(*) from sf_reponses) >= 300 then
    raise exception 'trop_de_reponses' using errcode = 'P0001';
  end if;

  v_maj := exists (select 1 from sf_reponses where cle = sf_cle(trim(p_prenom), trim(p_nom)));

  insert into sf_reponses (prenom, nom, email, venue, allergies, mot, visible)
  values (
    trim(p_prenom), trim(p_nom),
    nullif(lower(trim(coalesce(p_email, ''))), ''),
    p_venue,
    case when p_venue then nullif(trim(coalesce(p_allergies, '')), '') end,
    nullif(trim(coalesce(p_mot, '')), ''),
    coalesce(p_visible, false) and p_venue
  )
  on conflict (cle) do update set
    prenom = excluded.prenom, nom = excluded.nom, email = excluded.email,
    venue = excluded.venue, allergies = excluded.allergies, mot = excluded.mot,
    visible = excluded.visible, modifie_le = now();

  return json_build_object('ok', true, 'mise_a_jour', v_maj);
end;
$$;
revoke all on function public.sf_repondre(text, text, text, text, boolean, text, text, boolean) from public;
grant execute on function public.sf_repondre(text, text, text, text, boolean, text, text, boolean) to anon, authenticated;

-- Ajoute un son à la playlist
create or replace function public.sf_proposer_son(p_code text, p_titre text, p_artiste text, p_par text)
returns json
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if not sf_code_ok(p_code) then
    raise exception 'code_invalide' using errcode = 'P0001';
  end if;
  if (select count(*) from sf_sons) >= 400 then
    raise exception 'playlist_pleine' using errcode = 'P0001';
  end if;
  insert into sf_sons (titre, artiste, propose_par)
  values (trim(p_titre), nullif(trim(coalesce(p_artiste, '')), ''), nullif(trim(coalesce(p_par, '')), ''));
  return json_build_object('ok', true);
end;
$$;
revoke all on function public.sf_proposer_son(text, text, text, text) from public;
grant execute on function public.sf_proposer_son(text, text, text, text) to anon, authenticated;


-- ============================================================
-- 5. À FAIRE UNE FOIS, APRÈS LE SCRIPT : déclarer l'organisatrice
-- ============================================================
-- a) Supabase > Authentication > Users > Add user > Create new user :
--    son e-mail + un mot de passe solide, cocher « Auto Confirm User ».
-- b) Remplace l'adresse ci-dessous par la même, retire les deux tirets
--    au début de la ligne, puis lance uniquement cette ligne :
--
-- insert into public.sf_admins (email) values (lower('helena@exemple.fr')) on conflict do nothing;
--
-- c) Supabase > Authentication > Sign In / Providers : désactive
--    « Allow new users to sign up ». Ainsi, personne d'autre ne peut se
--    créer de compte. (Même s'il le faisait, il ne verrait rien : seules
--    les adresses de sf_admins ont accès aux données.)


-- ============================================================
-- 6. APRÈS LA FÊTE : conservation des données
-- ============================================================
-- Les réponses n'ont plus d'utilité après la soirée. Conseil : tout
-- effacer au plus tard fin février 2027, avec le bouton « Effacer toutes
-- les données » d'admin.html, ou avec ces lignes :
--
-- delete from public.sf_reponses;
-- delete from public.sf_sons;
-- delete from public.sf_invites;
