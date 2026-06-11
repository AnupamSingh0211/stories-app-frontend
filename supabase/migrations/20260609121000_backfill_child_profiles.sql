do $$
begin
  if (
    select count(*) = 8
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name in (
        'id',
        'user_id',
        'child_name',
        'age',
        'gender',
        'companion_id',
        'avatar_url',
        'created_at'
      )
  ) then
    execute $backfill$
      insert into public.child_profiles (
        id,
        parent_id,
        child_name,
        age,
        gender,
        companion_id,
        avatar_url,
        created_at
      )
      select
        profiles.id,
        profiles.user_id,
        profiles.child_name,
        coalesce(profiles.age, 2),
        coalesce(nullif(profiles.gender::text, ''), 'boy'),
        profiles.companion_id,
        profiles.avatar_url,
        coalesce(profiles.created_at, now())
      from public.profiles
      where profiles.user_id is not null
      on conflict (id) do nothing
    $backfill$;
  end if;
end
$$;
