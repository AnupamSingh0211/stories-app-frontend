alter table public.saved_stories
  add column if not exists user_id uuid;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'saved_stories'
      and column_name = 'profile_id'
  ) then
    execute $backfill$
      update public.saved_stories saved
      set user_id = profiles.user_id
      from public.profiles profiles
      where profiles.id = saved.profile_id
        and saved.user_id is null
    $backfill$;
  end if;
end
$$;

do $$
begin
  if exists (
    select 1
    from public.saved_stories
    where user_id is null
  ) then
    raise exception
      'Cannot migrate saved_stories: one or more rows have no owning auth user.';
  end if;
end
$$;

alter table public.saved_stories
  drop constraint if exists fk_saved_story_profile,
  drop constraint if exists unique_saved_story,
  drop constraint if exists saved_stories_user_id_fkey,
  drop constraint if exists saved_stories_user_story_key,
  alter column user_id set not null,
  add constraint saved_stories_user_id_fkey
    foreign key (user_id)
    references auth.users(id)
    on delete cascade,
  add constraint saved_stories_user_story_key
    unique (user_id, story_id);

alter table public.saved_stories
  drop column if exists profile_id;

alter table public.saved_stories enable row level security;

grant select, insert, delete on public.saved_stories to authenticated;

drop policy if exists "Saved stories are readable by owner"
on public.saved_stories;
drop policy if exists "Saved stories are insertable by owner"
on public.saved_stories;
drop policy if exists "Saved stories are deletable by owner"
on public.saved_stories;

create policy "Saved stories are readable by owner"
on public.saved_stories
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Saved stories are insertable by owner"
on public.saved_stories
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Saved stories are deletable by owner"
on public.saved_stories
for delete
to authenticated
using ((select auth.uid()) = user_id);
