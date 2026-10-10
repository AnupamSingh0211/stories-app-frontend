-- CMS content hierarchy:
--
--   homepage story -> episode -> page
--
--   public.story_cards  homepage stories such as "Krishna ki kahani"
--   public.stories      episodes that belong to one homepage story
--   public.story_pages  pages that belong to one episode
--
-- Each page has exactly one image and exactly one audio. A page image cannot
-- be reused by another page, and a page audio file cannot be reused either.
-- Editors should use the cms_stories, cms_episodes, and cms_pages views.

create schema if not exists stories_private;

alter table public.stories
  add column if not exists story_card_id uuid,
  add column if not exists cover_url text,
  add column if not exists duration_seconds integer not null default 0,
  add column if not exists sort_order integer not null default 0,
  add column if not exists episode_number integer;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'stories_story_card_id_fkey'
      and conrelid = 'public.stories'::regclass
  ) then
    alter table public.stories
      add constraint stories_story_card_id_fkey
      foreign key (story_card_id)
      references public.story_cards(id)
      on delete restrict;
  end if;
end
$$;

create table if not exists public.story_pages (
  id uuid primary key default gen_random_uuid(),
  story_id uuid,
  page_number integer,
  hindi_text text not null default '',
  image_url text,
  audio_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.story_pages
  add column if not exists story_id uuid,
  add column if not exists page_number integer,
  add column if not exists hindi_text text not null default '',
  add column if not exists image_url text,
  add column if not exists audio_url text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from public.story_cards
    group by lower(trim(title))
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce unique homepage stories: duplicate story titles exist.';
  end if;

  if exists (
    select 1
    from public.stories
    where nullif(trim(title), '') is null
  ) then
    raise exception
      'Cannot enforce unique episodes: a story episode title is blank.';
  end if;

  if exists (
    select 1
    from public.stories
    where story_card_id is not null
    group by story_card_id, lower(trim(title))
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce unique episodes: duplicate episode titles exist under one story.';
  end if;
end
$$;

with missing_numbers as (
  select
    missing.id,
    (
      select coalesce(max(assigned.episode_number), 0)
      from public.stories as assigned
      where assigned.story_card_id = missing.story_card_id
        and assigned.episode_number is not null
    ) + row_number() over (
      partition by missing.story_card_id
      order by missing.sort_order, missing.created_at, missing.id
    ) as next_number
  from public.stories as missing
  where missing.story_card_id is not null
    and missing.episode_number is null
)
update public.stories as episode
set episode_number = missing_numbers.next_number
from missing_numbers
where episode.id = missing_numbers.id;

do $$
begin
  if exists (
    select 1
    from public.stories
    where story_card_id is not null
      and episode_number is not null
    group by story_card_id, episode_number
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce unique episodes: duplicate episode numbers exist under one story.';
  end if;

  if exists (
    select 1
    from public.stories
    where episode_number is not null
      and episode_number < 1
  ) then
    raise exception
      'Cannot enforce episode numbers: an episode number is less than 1.';
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'stories_episode_number_check'
      and conrelid = 'public.stories'::regclass
  ) then
    alter table public.stories
      add constraint stories_episode_number_check
      check (episode_number is null or episode_number > 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'stories_title_not_blank_check'
      and conrelid = 'public.stories'::regclass
  ) then
    alter table public.stories
      add constraint stories_title_not_blank_check
      check (nullif(trim(title), '') is not null);
  end if;
end
$$;

create unique index if not exists story_cards_unique_title_idx
on public.story_cards (lower(trim(title)));

create unique index if not exists stories_unique_episode_title_idx
on public.stories (story_card_id, lower(trim(title)))
where story_card_id is not null;

create unique index if not exists stories_unique_episode_number_idx
on public.stories (story_card_id, episode_number)
where story_card_id is not null
  and episode_number is not null;

create or replace function stories_private.assign_cms_episode_defaults()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  if new.story_card_id is null
    and (tg_op = 'INSERT' or old.story_card_id is not null) then
    raise exception using
      errcode = '23502',
      message = 'Each episode must belong to one homepage story.',
      constraint = 'stories_story_card_required';
  end if;

  if new.story_card_id is not null and new.episode_number is null then
    select coalesce(max(existing.episode_number), 0) + 1
    into new.episode_number
    from public.stories as existing
    where existing.story_card_id = new.story_card_id;
  end if;

  if new.episode_number is not null and new.episode_number < 1 then
    raise exception using
      errcode = '23514',
      message = 'Episode number must be a positive integer.',
      constraint = 'stories_episode_number_check';
  end if;

  return new;
end;
$$;

revoke all
on function stories_private.assign_cms_episode_defaults()
from public;

drop trigger if exists assign_cms_episode_defaults on public.stories;

create trigger assign_cms_episode_defaults
before insert or update of story_card_id, episode_number
on public.stories
for each row
execute function stories_private.assign_cms_episode_defaults();

do $$
begin
  if exists (
    select 1
    from public.story_pages
    where story_id is null
      or page_number is null
      or page_number < 1
  ) then
    raise exception
      'Cannot enforce unique pages: a page is missing its episode or page number.';
  end if;

  if exists (
    select 1
    from public.story_pages
    group by story_id, page_number
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce unique pages: duplicate page numbers exist under one episode.';
  end if;

  if exists (
    select 1
    from public.story_pages
    where nullif(trim(coalesce(image_url, '')), '') is null
      or nullif(trim(coalesce(audio_url, '')), '') is null
  ) then
    raise exception
      'Cannot enforce unique page media: a page is missing its image or audio.';
  end if;

  if exists (
    select 1
    from public.story_pages
    where trim(image_url) = trim(audio_url)
  ) then
    raise exception
      'Cannot enforce unique page media: a page uses the same path for image and audio.';
  end if;

  if exists (
    select 1
    from public.story_pages
    group by trim(image_url)
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce unique page images: the same image is used by more than one page.';
  end if;

  if exists (
    select 1
    from public.story_pages
    group by trim(audio_url)
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce unique page audio: the same audio is used by more than one page.';
  end if;
end
$$;

update public.story_pages
set
  image_url = trim(image_url),
  audio_url = trim(audio_url)
where image_url is distinct from trim(image_url)
  or audio_url is distinct from trim(audio_url);

alter table public.story_pages
  alter column story_id set not null,
  alter column page_number set not null,
  alter column image_url set not null,
  alter column audio_url set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'story_pages_story_id_fkey'
      and conrelid = 'public.story_pages'::regclass
  ) then
    alter table public.story_pages
      add constraint story_pages_story_id_fkey
      foreign key (story_id)
      references public.stories(id)
      on delete cascade;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'story_pages_page_number_check'
      and conrelid = 'public.story_pages'::regclass
  ) then
    alter table public.story_pages
      add constraint story_pages_page_number_check
      check (page_number > 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'story_pages_image_url_check'
      and conrelid = 'public.story_pages'::regclass
  ) then
    alter table public.story_pages
      add constraint story_pages_image_url_check
      check (nullif(trim(image_url), '') is not null);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'story_pages_audio_url_check'
      and conrelid = 'public.story_pages'::regclass
  ) then
    alter table public.story_pages
      add constraint story_pages_audio_url_check
      check (nullif(trim(audio_url), '') is not null);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'story_pages_image_audio_distinct_check'
      and conrelid = 'public.story_pages'::regclass
  ) then
    alter table public.story_pages
      add constraint story_pages_image_audio_distinct_check
      check (trim(image_url) <> trim(audio_url));
  end if;
end
$$;

create unique index if not exists story_pages_unique_page_number_idx
on public.story_pages (story_id, page_number);

create unique index if not exists story_pages_unique_image_url_idx
on public.story_pages (trim(image_url));

create unique index if not exists story_pages_unique_audio_url_idx
on public.story_pages (trim(audio_url));

create or replace function stories_private.normalize_cms_page_media()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  new.image_url := trim(coalesce(new.image_url, ''));
  new.audio_url := trim(coalesce(new.audio_url, ''));

  return new;
end;
$$;

revoke all
on function stories_private.normalize_cms_page_media()
from public;

drop trigger if exists normalize_cms_page_media on public.story_pages;

create trigger normalize_cms_page_media
before insert or update of image_url, audio_url
on public.story_pages
for each row
execute function stories_private.normalize_cms_page_media();

create or replace view public.cms_stories
with (security_invoker = true) as
select
  id,
  title,
  thumbnail_url,
  hero_banner_url,
  category,
  sort_order,
  created_at,
  updated_at
from public.story_cards;

create or replace view public.cms_episodes
with (security_invoker = true) as
select
  id,
  story_card_id as story_id,
  episode_number,
  title,
  thumbnail_url,
  cover_url,
  duration_seconds,
  sort_order,
  created_at,
  updated_at
from public.stories
where story_card_id is not null
with local check option;

create or replace view public.cms_pages
with (security_invoker = true) as
select
  id,
  story_id as episode_id,
  page_number,
  image_url,
  audio_url,
  hindi_text,
  created_at,
  updated_at
from public.story_pages;

create or replace view public.cms_story_catalog
with (security_invoker = true) as
select
  homepage_story.id as story_id,
  homepage_story.title as story_title,
  homepage_story.sort_order as story_sort_order,
  episode.id as episode_id,
  episode.episode_number,
  episode.title as episode_title,
  page.id as page_id,
  page.page_number,
  page.image_url,
  page.audio_url
from public.story_cards as homepage_story
left join public.stories as episode
  on episode.story_card_id = homepage_story.id
left join public.story_pages as page
  on page.story_id = episode.id;

comment on table public.story_cards is
  'CMS homepage stories. Each title is unique. Example: Krishna ki kahani.';

comment on column public.stories.story_card_id is
  'Homepage story that owns this episode.';

comment on column public.stories.episode_number is
  'Episode order within one homepage story. Unique per story.';

comment on table public.story_pages is
  'CMS pages for one episode. Each page has one image and one audio, and neither asset can be reused.';

comment on view public.cms_stories is
  'Editable CMS view of homepage stories.';

comment on view public.cms_episodes is
  'Editable CMS view of episodes. story_id is the homepage story.';

comment on view public.cms_pages is
  'Editable CMS view of episode pages. episode_id is the episode.';

comment on view public.cms_story_catalog is
  'Read-only CMS outline of stories, episodes, and pages.';

do $$
begin
  if to_regclass('public.episodes') is not null then
    execute $comment$
      comment on table public.episodes is
        'Legacy table. CMS episodes live in public.stories and are edited through cms_episodes. CMS pages live in public.story_pages.'
    $comment$;
  end if;
end
$$;

grant select on public.story_pages to anon, authenticated;

alter table public.story_pages enable row level security;

drop policy if exists "Story pages are publicly readable" on public.story_pages;

create policy "Story pages are publicly readable"
on public.story_pages
for select
to anon, authenticated
using (true);

grant select on
  public.cms_stories,
  public.cms_episodes,
  public.cms_pages,
  public.cms_story_catalog
to anon, authenticated;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function stories_private.assign_cms_episode_defaults()
      to service_role;
    grant execute on function stories_private.normalize_cms_page_media()
      to service_role;
    grant select, insert, update, delete on
      public.cms_stories,
      public.cms_episodes,
      public.cms_pages
    to service_role;
    grant select on public.cms_story_catalog to service_role;
  end if;
end
$$;
