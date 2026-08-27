do $$
declare
  owner_id uuid;
  profile_id uuid;
  raised_constraint text;
begin
  select user_id
  into owner_id
  from public.profiles
  where user_id is not null
  group by user_id
  having count(*) = 1
  limit 1;

  if owner_id is null then
    raise exception 'Test requires at least one parent with one profile.';
  end if;

  select id
  into profile_id
  from public.profiles
  where user_id = owner_id
  limit 1;

  begin
    insert into public.profiles (
      user_id,
      child_name,
      age,
      gender,
      locale
    )
    values (
      owner_id,
      'Second Profile Limit Test',
      4,
      'boy',
      'en-IN'
    );

    raise exception 'Expected a second profile to be rejected.';
  exception
    when unique_violation then
      get stacked diagnostics raised_constraint = constraint_name;
      if raised_constraint <> 'unique_profiles_user_id' then
        raise;
      end if;
  end;

  update public.profiles
  set locale = 'hi-IN'
  where id = profile_id;

  update public.profiles
  set locale = 'en-IN'
  where id = profile_id;
end
$$;
