alter table public.profiles
add column if not exists locale text not null default 'en-IN';

do $$
begin
  alter table public.profiles
    add constraint profiles_locale_check
    check (locale in ('en-IN', 'hi-IN'));
exception
  when duplicate_object then null;
end $$;

do $$
declare
  duplicate_owner_ids text;
begin
  select string_agg(user_id::text, ', ' order by user_id::text)
  into duplicate_owner_ids
  from (
    select user_id
    from public.profiles
    where user_id is not null
    group by user_id
    having count(*) > 1
  ) duplicate_profiles;

  if duplicate_owner_ids is not null then
    raise exception using
      errcode = '23505',
      message = 'Cannot enforce one child profile per parent while duplicate profiles exist for user_id values: ' || duplicate_owner_ids,
      constraint = 'unique_profiles_user_id';
  end if;
end $$;

create unique index if not exists unique_profiles_user_id
on public.profiles (user_id)
where user_id is not null;

grant select, insert, update on public.profiles to authenticated;
alter table public.profiles enable row level security;

drop policy if exists "Profiles are readable by owner" on public.profiles;
drop policy if exists "Profiles are insertable by owner" on public.profiles;
drop policy if exists "Profiles are updateable by owner" on public.profiles;

create policy "Profiles are readable by owner"
on public.profiles
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

create policy "Profiles are insertable by owner"
on public.profiles
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

create policy "Profiles are updateable by owner"
on public.profiles
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);
