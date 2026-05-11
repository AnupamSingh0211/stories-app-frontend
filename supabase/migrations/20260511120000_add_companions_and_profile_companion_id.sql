create table if not exists public.companions (
  id text primary key,
  display_name text not null,
  short_description text not null,
  long_description text not null,
  image_path text not null,
  created_at timestamptz not null default now()
);

insert into public.companions (
  id,
  display_name,
  short_description,
  long_description,
  image_path
) values
  (
    'krishna',
    'Baby Krishna',
    'Playful and loving, Krishna guides you through stories of joy and wonder.',
    'A playful and divine presence that brings warmth and peace to your child''s bedtime stories.',
    'companions/comp_krishna.webp'
  ),
  (
    'hanuman',
    'Baby Hanuman',
    'Strong yet gentle, Hanuman brings courage, devotion, and protection.',
    'A brave and loyal companion who fills every bedtime tale with courage, kindness, and a comforting sense of protection.',
    'companions/comp_hanuman.webp'
  ),
  (
    'shiva',
    'Baby Shiva',
    'Meditative and calm, Shiva helps clear the mind for a restful sleep.',
    'A calm, moonlit guide who brings stillness, balance, and peaceful wonder to quiet nighttime adventures.',
    'companions/comp_shiva.webp'
  ),
  (
    'ganesha',
    'Baby Ganesha',
    'The remover of obstacles, Ganesha brings comfort, wisdom, and sweetness.',
    'A wise and gentle friend who helps every story feel safe, joyful, and full of soft beginnings.',
    'companions/comp_ganesha.webp'
  ),
  (
    'bheem',
    'Baby Bheem',
    'Reliable and brave, Bheem offers a steady and grounded story experience.',
    'A strong and cheerful companion who brings confidence, loyalty, and a grounded sense of adventure to bedtime.',
    'companions/comp_bheem.webp'
  ),
  (
    'arjun',
    'Baby Arjun',
    'Focused and visionary, Arjun leads you through tales of purpose and light.',
    'A focused and thoughtful friend who brings purpose, wonder, and gentle courage to every dream-bound story.',
    'companions/comp_arjun.webp'
  )
on conflict (id) do update set
  display_name = excluded.display_name,
  short_description = excluded.short_description,
  long_description = excluded.long_description,
  image_path = excluded.image_path;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'character'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'companion_id'
  ) then
    alter table public.profiles rename column character to companion_id;
  end if;
end $$;

alter table public.profiles
  alter column companion_id drop default,
  alter column companion_id drop not null;

update public.profiles
set companion_id = case lower(trim(companion_id))
  when 'krishna' then 'krishna'
  when 'baby krishna' then 'krishna'
  when 'hanuman' then 'hanuman'
  when 'baby hanuman' then 'hanuman'
  when 'shiva' then 'shiva'
  when 'baby shiva' then 'shiva'
  when 'ganesha' then 'ganesha'
  when 'baby ganesha' then 'ganesha'
  when 'bheem' then 'bheem'
  when 'baby bheem' then 'bheem'
  when 'arjun' then 'arjun'
  when 'baby arjun' then 'arjun'
  else null
end;

alter table public.profiles
  drop constraint if exists profiles_companion_id_fkey,
  add constraint profiles_companion_id_fkey
    foreign key (companion_id)
    references public.companions(id)
    on update cascade
    on delete set null;

grant select on public.companions to anon, authenticated;
grant insert on public.profiles to anon;
grant select, insert, update on public.profiles to authenticated;

alter table public.companions enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "Companions are readable during onboarding"
on public.companions;
drop policy if exists "Profiles are readable by owner" on public.profiles;
drop policy if exists "Profiles are insertable by owner" on public.profiles;
drop policy if exists "Profiles are updateable by owner" on public.profiles;
drop policy if exists "Profiles are insertable during guest onboarding"
on public.profiles;
drop policy if exists "profiles" on public.profiles;

create policy "Companions are readable during onboarding"
on public.companions
for select
to anon, authenticated
using (true);

create policy "Profiles are readable by owner"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

create policy "Profiles are insertable by owner"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Profiles are insertable during guest onboarding"
on public.profiles
for insert
to anon
with check (true);

create policy "Profiles are updateable by owner"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);
