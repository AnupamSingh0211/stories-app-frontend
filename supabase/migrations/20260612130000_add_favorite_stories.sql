create table if not exists public.favorite_stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  story_id uuid not null references public.stories(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint favorite_stories_user_story_key unique (user_id, story_id)
);

grant select, insert, delete on public.favorite_stories to authenticated;

alter table public.favorite_stories enable row level security;

drop policy if exists "Favorite stories are readable by owner"
on public.favorite_stories;
create policy "Favorite stories are readable by owner"
on public.favorite_stories
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Favorite stories are insertable by owner"
on public.favorite_stories;
create policy "Favorite stories are insertable by owner"
on public.favorite_stories
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Favorite stories are deletable by owner"
on public.favorite_stories;
create policy "Favorite stories are deletable by owner"
on public.favorite_stories
for delete
to authenticated
using (user_id = auth.uid());
