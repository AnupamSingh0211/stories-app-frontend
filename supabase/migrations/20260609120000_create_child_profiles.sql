create table if not exists public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  child_name text not null,
  age integer not null default 2,
  gender text not null default 'boy',
  companion_id text null references public.companions(id)
    on update cascade
    on delete set null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  constraint child_profiles_age_check check (age > 0),
  constraint child_profiles_gender_check check (gender in ('boy', 'girl'))
);

create index if not exists idx_child_profiles_parent_id
on public.child_profiles (parent_id, created_at desc);

grant select, insert, update, delete
on public.child_profiles
to authenticated;

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
using ((select auth.uid()) = parent_id);

create policy "Parents can insert their own children"
on public.child_profiles
for insert
to authenticated
with check ((select auth.uid()) = parent_id);

create policy "Parents can update their own children"
on public.child_profiles
for update
to authenticated
using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

create policy "Parents can delete their own children"
on public.child_profiles
for delete
to authenticated
using ((select auth.uid()) = parent_id);
