-- Add the parent content level used by the home screen.
--
-- Target hierarchy:
-- story_cards -> stories -> episodes
--
-- Existing stories are not backfilled in this migration. The story_card_id link
-- remains nullable until the current production rows are assigned to cards.

create table if not exists public.story_cards (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  thumbnail_url text not null,
  hero_banner_url text not null,
  category text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint story_cards_title_check
    check (nullif(trim(title), '') is not null),
  constraint story_cards_thumbnail_url_check
    check (nullif(trim(thumbnail_url), '') is not null),
  constraint story_cards_hero_banner_url_check
    check (nullif(trim(hero_banner_url), '') is not null)
);

alter table public.stories
  add column if not exists story_card_id uuid references public.story_cards(id)
    on delete restrict,
  add column if not exists cover_url text,
  add column if not exists duration_seconds integer not null default 0,
  add column if not exists sort_order integer not null default 0;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'stories_duration_seconds_check'
      and conrelid = 'public.stories'::regclass
  ) then
    alter table public.stories
      add constraint stories_duration_seconds_check
      check (duration_seconds >= 0);
  end if;
end
$$;

create index if not exists story_cards_sort_order_idx
on public.story_cards (sort_order, created_at);

create index if not exists stories_story_card_sort_order_idx
on public.stories (story_card_id, sort_order, created_at);

do $$
begin
  if to_regclass('public.episodes') is not null then
    execute '
      create index if not exists episodes_story_episode_number_idx
      on public.episodes (story_id, episode_number)
    ';

    if not exists (
      select 1
      from pg_constraint
      where conname = 'episodes_story_id_fkey'
        and conrelid = 'public.episodes'::regclass
    ) then
      execute '
        alter table public.episodes
          add constraint episodes_story_id_fkey
          foreign key (story_id)
          references public.stories(id)
          on delete cascade
          not valid
      ';
    end if;
  end if;
end
$$;

grant select on public.story_cards to anon, authenticated;
grant select on public.stories to anon, authenticated;

alter table public.story_cards enable row level security;
alter table public.stories enable row level security;

drop policy if exists "Story cards are publicly readable"
on public.story_cards;
create policy "Story cards are publicly readable"
on public.story_cards
for select
to anon, authenticated
using (true);

drop policy if exists "Stories are publicly readable" on public.stories;
create policy "Stories are publicly readable"
on public.stories
for select
to anon, authenticated
using (true);
