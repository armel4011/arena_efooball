-- Stream comments : chat publique pour les spectateurs d'un live Agora.
--
-- Distinct de `chat_messages` (qui est le DM entre les 2 joueurs d'un
-- match). Un seul fil de discussion par match — n'importe quel
-- utilisateur authentifié peut lire et ecrire tant qu'un stream public
-- est actif sur ce match (RLS check sur `streams.is_public + is_active`).
--
-- Pas de moderation auto pour V1 — on observera le trafic avant de
-- decider du throttle/blocklist. Pas d'UPDATE/DELETE : le chat est
-- un log immuable (le seul moyen d'effacer = drop via super-admin).

create table if not exists public.stream_comments (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null
    references public.matches on delete cascade,
  author_id uuid references public.profiles on delete set null,
  content text not null check (length(content) between 1 and 500),
  created_at timestamptz not null default now()
);

-- Index (match_id, created_at desc) : couvre le scroll antichron typique
-- ("derniers 100 messages du match X") et le tail-f realtime.
create index if not exists stream_comments_match_created_idx
  on public.stream_comments (match_id, created_at desc);

-- RLS
alter table public.stream_comments enable row level security;

-- READ : chat publique — tout user authentifie peut lire.
create policy stream_comments_read_authenticated
  on public.stream_comments
  for select
  to authenticated
  using (true);

-- INSERT : tout user authentifie peut ecrire en tant que lui-meme,
-- a condition que le match cible ait un stream public actif (= un
-- live en cours, broadcasted via Agora).
create policy stream_comments_insert_authenticated
  on public.stream_comments
  for insert
  to authenticated
  with check (
    author_id = auth.uid()
    and exists (
      select 1 from public.streams s
      where s.match_id = stream_comments.match_id
        and s.is_public = true
        and s.is_active = true
    )
  );

-- UPDATE/DELETE : aucune policy = aucune permission (chat log immuable).

-- Publication realtime : permet aux clients de subscribe au flux des
-- nouveaux messages via Supabase realtime.
alter publication supabase_realtime add table public.stream_comments;

-- Grants minimal (RLS gate les vraies permissions).
grant select, insert on public.stream_comments to authenticated;
