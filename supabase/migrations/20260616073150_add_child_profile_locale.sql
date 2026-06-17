alter table public.child_profiles
add column if not exists locale text not null default 'en-IN';

do $$
begin
  alter table public.child_profiles
    add constraint child_profiles_locale_check
    check (locale in ('en-IN', 'hi-IN'));
exception
  when duplicate_object then null;
end $$;
