create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  category text,
  mood text,
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  thumbnail_path text,
  thumbnail_url text,
  narrator text,
  is_featured boolean not null default false,
  is_popular boolean not null default false,
  like_count integer not null default 0 check (like_count >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint stories_thumbnail_check
    check (
      nullif(trim(coalesce(thumbnail_path, '')), '') is not null
      or nullif(trim(coalesce(thumbnail_url, '')), '') is not null
    )
);

grant select on public.stories to anon, authenticated;

alter table public.stories enable row level security;

drop policy if exists "Stories are readable" on public.stories;

create policy "Stories are readable"
on public.stories
for select
to anon, authenticated
using (true);

