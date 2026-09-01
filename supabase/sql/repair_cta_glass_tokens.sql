-- Repair CTA surface tokens that should keep the original Boopi glass style.
-- CMS/App Config colors with alpha use CSS order: #RRGGBBAA.
-- Previous Flutter glass values:
--   Color(0x2EFFFFFF) -> #FFFFFF2E
--   Color(0x66FFFFFF) -> #FFFFFF66

update public.design_tokens
set
  token_value = '#FFFFFF2E',
  updated_at = now()
where token_key in (
  'subscription.cta.background',
  'favorites.empty.cta.background'
)
and theme in ('light', 'dark');

update public.design_tokens
set
  token_value = '#FFFFFF66',
  updated_at = now()
where token_key in (
  'subscription.cta.border',
  'favorites.empty.cta.border'
)
and theme in ('light', 'dark');

insert into public.app_config_versions (
  config_key,
  version,
  description
) values (
  'designSystem',
  1,
  'Version for the CMS-backed design system returned by App Config.'
)
on conflict (config_key) do update set
  version = public.app_config_versions.version + 1,
  updated_at = now();
