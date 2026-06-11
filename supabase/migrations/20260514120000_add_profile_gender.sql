alter table public.profiles
  add column if not exists gender text;

update public.profiles
set gender = case lower(trim(gender))
  when 'male' then 'boy'
  when 'boy' then 'boy'
  when 'female' then 'girl'
  when 'girl' then 'girl'
  else null
end
where gender is not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_gender_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_gender_check
      check (gender is null or gender in ('boy', 'girl'));
  end if;
end $$;
