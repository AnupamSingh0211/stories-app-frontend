do $$
declare
  parent_with_one uuid;
  parent_with_two uuid;
  child_to_delete uuid;
  raised_constraint text;
begin
  select parent_id
  into parent_with_one
  from public.child_profiles
  group by parent_id
  having count(*) = 1
  limit 1;

  select parent_id
  into parent_with_two
  from public.child_profiles
  group by parent_id
  having count(*) = 2
  limit 1;

  if parent_with_one is null or parent_with_two is null then
    raise exception
      'Test requires one parent with one child and one parent with two children.';
  end if;

  begin
    insert into public.child_profiles (
      parent_id,
      child_name,
      age,
      gender
    )
    values (
      parent_with_two,
      'Rollback Limit Test',
      2,
      'boy'
    );

    raise exception 'Expected a third child to be rejected.';
  exception
    when check_violation then
      get stacked diagnostics raised_constraint = constraint_name;
      if raised_constraint <> 'child_profiles_parent_limit' then
        raise;
      end if;
  end;

  insert into public.child_profiles (
    parent_id,
    child_name,
    age,
    gender
  )
  values (
    parent_with_one,
    'Rollback Second Child Test',
    2,
    'girl'
  );

  begin
    insert into public.child_profiles (
      parent_id,
      child_name,
      age,
      gender
    )
    values (
      parent_with_one,
      'Rollback Third Child Test',
      2,
      'boy'
    );

    raise exception 'Expected the next child to be rejected.';
  exception
    when check_violation then
      get stacked diagnostics raised_constraint = constraint_name;
      if raised_constraint <> 'child_profiles_parent_limit' then
        raise;
      end if;
  end;

  select id
  into child_to_delete
  from public.child_profiles
  where parent_id = parent_with_two
  limit 1;

  delete from public.child_profiles
  where id = child_to_delete;

  insert into public.child_profiles (
    parent_id,
    child_name,
    age,
    gender
  )
  values (
    parent_with_two,
    'Rollback Replacement Test',
    2,
    'girl'
  );

  begin
    insert into public.child_profiles (
      parent_id,
      child_name,
      age,
      gender
    )
    values (
      parent_with_two,
      'Rollback Replacement Limit Test',
      2,
      'boy'
    );

    raise exception 'Expected the replacement limit to be enforced.';
  exception
    when check_violation then
      get stacked diagnostics raised_constraint = constraint_name;
      if raised_constraint <> 'child_profiles_parent_limit' then
        raise;
      end if;
  end;
end
$$;
