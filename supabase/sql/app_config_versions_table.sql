-- Manual Supabase SQL Editor script for app config versioning.
-- This keeps one version number for the full designSystem config.

create table if not exists public.app_config_versions (
  id uuid primary key default gen_random_uuid(),
  config_key text not null unique,
  version integer not null default 1 check (version >= 1),
  description text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

insert into public.app_config_versions (
  config_key,
  version,
  description
) values (
  'designSystem',
  1,
  'Version for the CMS-backed design system returned by App Config.'
)
on conflict (config_key) do nothing;

grant select on public.app_config_versions to anon, authenticated;
alter table public.app_config_versions enable row level security;

drop policy if exists "Design system config version is publicly readable"
on public.app_config_versions;

create policy "Design system config version is publicly readable"
on public.app_config_versions
for select
to anon, authenticated
using (config_key = 'designSystem');
