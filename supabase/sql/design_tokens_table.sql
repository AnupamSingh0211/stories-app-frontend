-- Manual Supabase SQL Editor script for the Boopi design token table.
-- This script is intentionally non-destructive: it creates/updates schema,
-- seeds default active tokens, and does not delete existing CMS data.

create table if not exists public.design_tokens (
  id uuid primary key default gen_random_uuid(),
  token_key text not null,
  theme text not null default 'light',
  token_value text not null,
  token_type text not null default 'color',
  group_name text default 'general',
  description text,
  sort_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.design_tokens
add column if not exists theme text not null default 'light';

do $$
declare
  unique_constraint_name text;
begin
  for unique_constraint_name in
    select constraint_name
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'design_tokens'
      and constraint_type = 'UNIQUE'
      and constraint_name in (
        select tc.constraint_name
        from information_schema.table_constraints tc
        join information_schema.key_column_usage kcu
          on tc.constraint_schema = kcu.constraint_schema
          and tc.constraint_name = kcu.constraint_name
          and tc.table_schema = kcu.table_schema
          and tc.table_name = kcu.table_name
        where tc.table_schema = 'public'
          and tc.table_name = 'design_tokens'
          and tc.constraint_type = 'UNIQUE'
        group by tc.constraint_name
        having array_agg(kcu.column_name::text order by kcu.ordinal_position) = array['token_key']
      )
  loop
    execute format(
      'alter table public.design_tokens drop constraint %I',
      unique_constraint_name
    );
  end loop;
end $$;

drop index if exists public.design_tokens_token_key_key;
drop index if exists public.design_tokens_token_key_idx;

do $$
begin
  alter table public.design_tokens
    add constraint design_tokens_token_type_check
    check (token_type in ('color', 'typography', 'preset')) not valid;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.design_tokens
    add constraint design_tokens_theme_check
    check (theme in ('light', 'dark')) not valid;
exception
  when duplicate_object then null;
end $$;

create unique index if not exists design_tokens_token_key_theme_key
on public.design_tokens (token_key, theme);

create index if not exists design_tokens_group_sort_idx
on public.design_tokens (group_name, sort_order, token_key);

create index if not exists design_tokens_theme_active_sort_idx
on public.design_tokens (theme, is_active, sort_order);

insert into public.design_tokens (
  token_key,
  theme,
  token_value,
  token_type,
  group_name,
  description,
  sort_order,
  is_active
) values
  ('color.primary', 'light', '#6750A4', 'color', 'boopi', 'Main Boopi action color.', 0, true),
  ('color.on-primary', 'light', '#FFFFFF', 'color', 'boopi', 'Content color on primary surfaces.', 1, true),
  ('color.primary-container', 'light', '#EADDFF', 'color', 'boopi', 'Primary container color.', 2, true),
  ('color.on-primary-container', 'light', '#21005D', 'color', 'boopi', 'Content color on primary containers.', 3, true),
  ('color.secondary', 'light', '#625B71', 'color', 'boopi', 'Secondary color.', 4, true),
  ('color.on-secondary', 'light', '#FFFFFF', 'color', 'boopi', 'Content color on secondary surfaces.', 5, true),
  ('color.secondary-container', 'light', '#E8DEF8', 'color', 'boopi', 'Secondary container color.', 6, true),
  ('color.on-secondary-container', 'light', '#1D192B', 'color', 'boopi', 'Content color on secondary containers.', 7, true),
  ('color.surface', 'light', '#FFFBFE', 'color', 'boopi', 'Default surface color.', 8, true),
  ('color.on-surface', 'light', '#1C1B1F', 'color', 'boopi', 'Default content color on surfaces.', 9, true),
  ('color.surface-variant', 'light', '#E7E0EC', 'color', 'boopi', 'Variant surface color.', 10, true),
  ('color.on-surface-variant', 'light', '#49454F', 'color', 'boopi', 'Content color on variant surfaces.', 11, true),
  ('color.outline', 'light', '#79747E', 'color', 'boopi', 'Outline and border color.', 12, true),
  ('color.error', 'light', '#B3261E', 'color', 'boopi', 'Error color.', 13, true),
  ('home.background.top', 'light', '#24325F', 'color', 'home', 'Home background top gradient color.', 14, true),
  ('home.background.middle', 'light', '#324582', 'color', 'home', 'Home background middle gradient color.', 15, true),
  ('home.background.bottom', 'light', '#17234F', 'color', 'home', 'Home background bottom gradient color.', 16, true),
  ('player.background.primary', 'light', '#58AAF0', 'color', 'player', 'Primary player background color.', 17, true),
  ('home.card.text.primary', 'light', '#FFFFFF', 'color', 'home', 'Primary text color on home cards.', 18, true),
  ('color.primary', 'dark', '#D0BCFF', 'color', 'boopi', 'Main Boopi action color for dark theme.', 0, true),
  ('color.on-primary', 'dark', '#381E72', 'color', 'boopi', 'Content color on primary surfaces for dark theme.', 1, true),
  ('color.primary-container', 'dark', '#4F378B', 'color', 'boopi', 'Primary container color for dark theme.', 2, true),
  ('color.on-primary-container', 'dark', '#EADDFF', 'color', 'boopi', 'Content color on primary containers for dark theme.', 3, true),
  ('color.secondary', 'dark', '#CCC2DC', 'color', 'boopi', 'Secondary color for dark theme.', 4, true),
  ('color.on-secondary', 'dark', '#332D41', 'color', 'boopi', 'Content color on secondary surfaces for dark theme.', 5, true),
  ('color.secondary-container', 'dark', '#4A4458', 'color', 'boopi', 'Secondary container color for dark theme.', 6, true),
  ('color.on-secondary-container', 'dark', '#E8DEF8', 'color', 'boopi', 'Content color on secondary containers for dark theme.', 7, true),
  ('color.surface', 'dark', '#141218', 'color', 'boopi', 'Default surface color for dark theme.', 8, true),
  ('color.on-surface', 'dark', '#E6E0E9', 'color', 'boopi', 'Default content color on dark surfaces.', 9, true),
  ('color.surface-variant', 'dark', '#49454F', 'color', 'boopi', 'Variant surface color for dark theme.', 10, true),
  ('color.on-surface-variant', 'dark', '#CAC4D0', 'color', 'boopi', 'Content color on variant dark surfaces.', 11, true),
  ('color.outline', 'dark', '#938F99', 'color', 'boopi', 'Outline and border color for dark theme.', 12, true),
  ('color.error', 'dark', '#F2B8B5', 'color', 'boopi', 'Error color for dark theme.', 13, true),
  ('home.background.top', 'dark', '#24325F', 'color', 'home', 'Home background top gradient color for dark theme.', 14, true),
  ('home.background.middle', 'dark', '#324582', 'color', 'home', 'Home background middle gradient color for dark theme.', 15, true),
  ('home.background.bottom', 'dark', '#17234F', 'color', 'home', 'Home background bottom gradient color for dark theme.', 16, true),
  ('player.background.primary', 'dark', '#58AAF0', 'color', 'player', 'Primary player background color for dark theme.', 17, true),
  ('home.card.text.primary', 'dark', '#FFFFFF', 'color', 'home', 'Primary text color on home cards for dark theme.', 18, true),
  ('typography.display-large', 'light', '{"size":"57","lineHeight":"1.12","letterSpacing":"-0.25","weight":"400"}', 'typography', 'typography', 'Display Large type token for Boopi app screens.', 0, true),
  ('typography.display-medium', 'light', '{"size":"45","lineHeight":"1.16","letterSpacing":"0","weight":"400"}', 'typography', 'typography', 'Display Medium type token for Boopi app screens.', 1, true),
  ('typography.display-small', 'light', '{"size":"36","lineHeight":"1.22","letterSpacing":"0","weight":"400"}', 'typography', 'typography', 'Display Small type token for Boopi app screens.', 2, true),
  ('typography.headline-large', 'light', '{"size":"32","lineHeight":"1.25","letterSpacing":"0","weight":"400"}', 'typography', 'typography', 'Headline Large type token for Boopi app screens.', 3, true),
  ('typography.headline-medium', 'light', '{"size":"28","lineHeight":"1.29","letterSpacing":"0","weight":"400"}', 'typography', 'typography', 'Headline Medium type token for Boopi app screens.', 4, true),
  ('typography.headline-small', 'light', '{"size":"24","lineHeight":"1.33","letterSpacing":"0","weight":"400"}', 'typography', 'typography', 'Headline Small type token for Boopi app screens.', 5, true),
  ('typography.title-large', 'light', '{"size":"22","lineHeight":"1.27","letterSpacing":"0","weight":"500"}', 'typography', 'typography', 'Title Large type token for Boopi app screens.', 6, true),
  ('typography.title-medium', 'light', '{"size":"16","lineHeight":"1.5","letterSpacing":"0.15","weight":"500"}', 'typography', 'typography', 'Title Medium type token for Boopi app screens.', 7, true),
  ('typography.title-small', 'light', '{"size":"14","lineHeight":"1.43","letterSpacing":"0.1","weight":"500"}', 'typography', 'typography', 'Title Small type token for Boopi app screens.', 8, true),
  ('typography.body-large', 'light', '{"size":"16","lineHeight":"1.5","letterSpacing":"0.5","weight":"400"}', 'typography', 'typography', 'Body Large type token for Boopi app screens.', 9, true),
  ('typography.body-medium', 'light', '{"size":"14","lineHeight":"1.43","letterSpacing":"0.25","weight":"400"}', 'typography', 'typography', 'Body Medium type token for Boopi app screens.', 10, true),
  ('typography.body-small', 'light', '{"size":"12","lineHeight":"1.33","letterSpacing":"0.4","weight":"400"}', 'typography', 'typography', 'Body Small type token for Boopi app screens.', 11, true),
  ('typography.label-large', 'light', '{"size":"14","lineHeight":"1.43","letterSpacing":"0.1","weight":"500"}', 'typography', 'typography', 'Label Large type token for Boopi app screens.', 12, true),
  ('typography.label-medium', 'light', '{"size":"12","lineHeight":"1.33","letterSpacing":"0.5","weight":"500"}', 'typography', 'typography', 'Label Medium type token for Boopi app screens.', 13, true),
  ('typography.label-small', 'light', '{"size":"11","lineHeight":"1.45","letterSpacing":"0.5","weight":"500"}', 'typography', 'typography', 'Label Small type token for Boopi app screens.', 14, true),
  ('preset.button.primary-cta', 'light', '{"background":"#4945FF","foreground":"#FFFFFF","track":"#e0e0e0","radius":"12","padding":"14","fillMode":"solid","trackMode":"none","applicability":["Nudge","Guide"]}', 'preset', 'Button', 'Primary CTA button preset.', 0, true),
  ('preset.progress-bar.primary', 'light', '{"background":"#ffffff","foreground":"#4945FF","track":"#E0E0E0","radius":"4","padding":"0","fillMode":"solid","trackMode":"solid","applicability":["Nudge","Guide"]}', 'preset', 'Progress Bar', 'Progress bar preset.', 1, true),
  ('preset.stories.card', 'light', '{"background":"#24325F","foreground":"#FFFFFF","track":"#e0e0e0","radius":"16","padding":"16","fillMode":"solid","trackMode":"none","applicability":["Guide"]}', 'preset', 'Stories', 'Story card preset.', 2, true),
  ('preset.dialog.surface', 'light', '{"background":"#FFFFFF","foreground":"#1D1B2A","track":"#e0e0e0","radius":"20","padding":"20","fillMode":"solid","trackMode":"none","applicability":["Nudge","Guide"]}', 'preset', 'Dialog', 'Dialog surface preset.', 3, true),
  ('preset.tooltip.bubble', 'light', '{"background":"#1D1B2A","foreground":"#FFFFFF","track":"#e0e0e0","radius":"8","padding":"10","fillMode":"solid","trackMode":"none","applicability":["Nudge"]}', 'preset', 'Tooltip', 'Tooltip bubble preset.', 4, true)
on conflict (token_key, theme) do update set
  token_value = excluded.token_value,
  token_type = excluded.token_type,
  group_name = excluded.group_name,
  description = excluded.description,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

grant select on public.design_tokens to anon, authenticated;
alter table public.design_tokens enable row level security;

drop policy if exists "Active design tokens are publicly readable" on public.design_tokens;

create policy "Active design tokens are publicly readable"
on public.design_tokens
for select
to anon, authenticated
using (is_active = true);
