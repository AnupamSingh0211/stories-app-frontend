-- Verifies the CMS hierarchy:
-- homepage stories -> episodes -> pages, with one unique image and audio per page.
-- The transaction is rolled back so the catalog stays unchanged.

begin;

do $$
declare
  krishna_id uuid;
  hanuman_id uuid;
  hanuman_episode_id uuid;
  duplicate_rejected boolean;
begin
  insert into public.cms_stories (
    title,
    thumbnail_url,
    hero_banner_url,
    category,
    sort_order
  )
  values
    (
      'Krishna ki kahani',
      'cms/krishna/cover.webp',
      'cms/krishna/hero.webp',
      'Krishna',
      1
    ),
    (
      'Hanuman ki shakti',
      'cms/hanuman/cover.webp',
      'cms/hanuman/hero.webp',
      'Hanuman',
      2
    );

  select id
  into krishna_id
  from public.cms_stories
  where title = 'Krishna ki kahani';

  select id
  into hanuman_id
  from public.cms_stories
  where title = 'Hanuman ki shakti';

  if krishna_id is null or hanuman_id is null or krishna_id = hanuman_id then
    raise exception 'Homepage stories were not created as separate records.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_stories (
      title,
      thumbnail_url,
      hero_banner_url
    )
    values (
      '  krishna ki kahani  ',
      'cms/krishna/other-cover.webp',
      'cms/krishna/other-hero.webp'
    );
  exception
    when unique_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'Duplicate homepage story titles must be rejected.';
  end if;

  insert into public.cms_episodes (
    story_id,
    title,
    thumbnail_url,
    episode_number
  )
  values
    (
      hanuman_id,
      'Sundarkand',
      'cms/hanuman/episodes/sundarkand.webp',
      1
    ),
    (
      hanuman_id,
      'Lanka Dahan',
      'cms/hanuman/episodes/lanka-dahan.webp',
      2
    ),
    (
      krishna_id,
      'Sundarkand',
      'cms/krishna/episodes/sundarkand.webp',
      1
    );

  select id
  into hanuman_episode_id
  from public.cms_episodes
  where story_id = hanuman_id
    and episode_number = 1;

  if hanuman_episode_id is null then
    raise exception 'Hanuman episode was not created.';
  end if;

  if (
    select count(*)
    from public.cms_episodes
    where story_id = hanuman_id
  ) <> 2 then
    raise exception 'Hanuman ki shakti should have two unique episodes.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_episodes (
      story_id,
      title,
      thumbnail_url,
      episode_number
    )
    values (
      hanuman_id,
      'sundarkand',
      'cms/hanuman/episodes/sundarkand-copy.webp',
      3
    );
  exception
    when unique_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'Duplicate episode titles under one story must be rejected.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_episodes (
      story_id,
      title,
      thumbnail_url,
      episode_number
    )
    values (
      hanuman_id,
      'The Mountain',
      'cms/hanuman/episodes/mountain.webp',
      2
    );
  exception
    when unique_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'Duplicate episode numbers under one story must be rejected.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_episodes (
      story_id,
      title,
      thumbnail_url
    )
    values (
      null,
      'Orphan episode',
      'cms/orphan/episode.webp'
    );
  exception
    when not_null_violation or check_violation or with_check_option_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'An episode without a homepage story must be rejected.';
  end if;

  insert into public.cms_pages (
    episode_id,
    page_number,
    image_url,
    audio_url,
    hindi_text
  )
  values
    (
      hanuman_episode_id,
      1,
      'cms/hanuman/sundarkand/page-001.webp',
      'cms/hanuman/sundarkand/page-001.mp3',
      'Hanuman reaches Lanka.'
    ),
    (
      hanuman_episode_id,
      2,
      'cms/hanuman/sundarkand/page-002.webp',
      'cms/hanuman/sundarkand/page-002.mp3',
      'Hanuman finds Sita.'
    );

  if (
    select count(*)
    from public.cms_pages
    where episode_id = hanuman_episode_id
  ) <> 2 then
    raise exception 'The episode should have two unique pages.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_pages (
      episode_id,
      page_number,
      image_url,
      audio_url
    )
    values (
      hanuman_episode_id,
      1,
      'cms/hanuman/sundarkand/page-003.webp',
      'cms/hanuman/sundarkand/page-003.mp3'
    );
  exception
    when unique_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'Duplicate page numbers under one episode must be rejected.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_pages (
      episode_id,
      page_number,
      image_url,
      audio_url
    )
    values (
      hanuman_episode_id,
      3,
      'cms/hanuman/sundarkand/page-001.webp',
      'cms/hanuman/sundarkand/page-004.mp3'
    );
  exception
    when unique_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'A page image cannot be reused.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_pages (
      episode_id,
      page_number,
      image_url,
      audio_url
    )
    values (
      hanuman_episode_id,
      3,
      'cms/hanuman/sundarkand/page-004.webp',
      '  cms/hanuman/sundarkand/page-001.mp3  '
    );
  exception
    when unique_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'A page audio file cannot be reused.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_pages (
      episode_id,
      page_number,
      image_url,
      audio_url
    )
    values (
      hanuman_episode_id,
      3,
      'cms/hanuman/sundarkand/page-005.webp',
      'cms/hanuman/sundarkand/page-005.webp'
    );
  exception
    when check_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'A page cannot use one file as both its image and its audio.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_pages (
      episode_id,
      page_number,
      image_url,
      audio_url
    )
    values (
      hanuman_episode_id,
      3,
      '   ',
      'cms/hanuman/sundarkand/page-005.mp3'
    );
  exception
    when check_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'A page without an image must be rejected.';
  end if;

  duplicate_rejected := false;
  begin
    insert into public.cms_pages (
      episode_id,
      page_number,
      image_url,
      audio_url
    )
    values (
      null,
      1,
      'cms/orphan/page.webp',
      'cms/orphan/page.mp3'
    );
  exception
    when not_null_violation then
      duplicate_rejected := true;
  end;

  if not duplicate_rejected then
    raise exception 'A page without an episode must be rejected.';
  end if;

  if (
    select count(*)
    from public.cms_story_catalog
    where story_title in ('Krishna ki kahani', 'Hanuman ki shakti')
      and page_id is not null
      and image_url is not null
      and audio_url is not null
  ) <> 2 then
    raise exception 'The CMS catalog should list each page once with its image and audio.';
  end if;
end
$$;

rollback;
