create schema if not exists stories_private;

revoke all on schema stories_private from public, anon, authenticated;

alter table public.child_profiles
  alter column parent_id set default auth.uid();

alter table public.child_profiles enable row level security;

drop policy if exists "Parents can view their own children"
on public.child_profiles;
drop policy if exists "Parents can insert their own children"
on public.child_profiles;
drop policy if exists "Parents can update their own children"
on public.child_profiles;
drop policy if exists "Parents can delete their own children"
on public.child_profiles;

create policy "Parents can view their own children"
on public.child_profiles
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = parent_id
);

create policy "Parents can insert their own children"
on public.child_profiles
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = parent_id
);

create policy "Parents can update their own children"
on public.child_profiles
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = parent_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = parent_id
);

create policy "Parents can delete their own children"
on public.child_profiles
for delete
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = parent_id
);

create table if not exists stories_private.child_profile_counts (
  parent_id uuid primary key references auth.users(id) on delete cascade,
  child_count integer not null default 0,
  constraint child_profile_counts_nonnegative check (child_count >= 0)
);

revoke all
on stories_private.child_profile_counts
from public, anon, authenticated;

insert into stories_private.child_profile_counts (parent_id, child_count)
select parent_id, count(*)::integer
from public.child_profiles
group by parent_id
on conflict (parent_id) do update
set child_count = excluded.child_count;

delete from stories_private.child_profile_counts counts
where not exists (
  select 1
  from public.child_profiles children
  where children.parent_id = counts.parent_id
);

create or replace function stories_private.reserve_child_profile_slot()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, stories_private
as $$
declare
  reserved_count integer;
begin
  insert into stories_private.child_profile_counts as counts (
    parent_id,
    child_count
  )
  values (new.parent_id, 1)
  on conflict (parent_id) do update
  set child_count = counts.child_count + 1
  where counts.child_count < 2
  returning child_count into reserved_count;

  if reserved_count is null then
    raise exception using
      errcode = '23514',
      message = 'You can add up to two child profiles. To add another, please update or remove an existing profile.',
      constraint = 'child_profiles_parent_limit';
  end if;

  return new;
end;
$$;

revoke all
on function stories_private.reserve_child_profile_slot()
from public, anon, authenticated;

create or replace function stories_private.release_child_profile_slot()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, stories_private
as $$
begin
  update stories_private.child_profile_counts
  set child_count = greatest(child_count - 1, 0)
  where parent_id = old.parent_id;

  return old;
end;
$$;

revoke all
on function stories_private.release_child_profile_slot()
from public, anon, authenticated;

create or replace function stories_private.prevent_child_profile_reparenting()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $$
begin
  if new.parent_id is distinct from old.parent_id then
    raise exception using
      errcode = '23514',
      message = 'A child profile cannot be moved to another parent.',
      constraint = 'child_profiles_parent_id_immutable';
  end if;

  return new;
end;
$$;

revoke all
on function stories_private.prevent_child_profile_reparenting()
from public, anon, authenticated;

drop trigger if exists reserve_child_profile_slot
on public.child_profiles;

create trigger reserve_child_profile_slot
before insert on public.child_profiles
for each row
execute function stories_private.reserve_child_profile_slot();

drop trigger if exists release_child_profile_slot
on public.child_profiles;

create trigger release_child_profile_slot
after delete on public.child_profiles
for each row
execute function stories_private.release_child_profile_slot();

drop trigger if exists prevent_child_profile_reparenting
on public.child_profiles;

create trigger prevent_child_profile_reparenting
before update of parent_id on public.child_profiles
for each row
execute function stories_private.prevent_child_profile_reparenting();

do $$
declare
  owner_column text;
begin
  if to_regclass('public.profiles') is null then
    return;
  end if;

  revoke insert on public.profiles from anon;
  grant select, insert, update on public.profiles to authenticated;
  alter table public.profiles enable row level security;

  drop policy if exists "Profiles are readable by owner"
  on public.profiles;
  drop policy if exists "Profiles are insertable by owner"
  on public.profiles;
  drop policy if exists "Profiles are updateable by owner"
  on public.profiles;
  drop policy if exists "Profiles are insertable during guest onboarding"
  on public.profiles;
  drop policy if exists "Profiles can be created during onboarding"
  on public.profiles;
  drop policy if exists "profiles"
  on public.profiles;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'user_id'
  ) then
    owner_column := 'user_id';
  elsif exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'id'
  ) then
    owner_column := 'id';
  else
    raise exception
      'public.profiles has no supported ownership column (user_id or id)';
  end if;

  execute format(
    'create policy "Profiles are readable by owner" '
    'on public.profiles for select to authenticated '
    'using ((select auth.uid()) is not null '
    'and (select auth.uid()) = %I)',
    owner_column
  );

  execute format(
    'create policy "Profiles are insertable by owner" '
    'on public.profiles for insert to authenticated '
    'with check ((select auth.uid()) is not null '
    'and (select auth.uid()) = %I)',
    owner_column
  );

  execute format(
    'create policy "Profiles are updateable by owner" '
    'on public.profiles for update to authenticated '
    'using ((select auth.uid()) is not null '
    'and (select auth.uid()) = %I) '
    'with check ((select auth.uid()) is not null '
    'and (select auth.uid()) = %I)',
    owner_column,
    owner_column
  );
end
$$;
