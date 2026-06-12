-- Seed the two playable Krishna stories from their verified Storage paths.
-- Target project: ozdvhjcumeujfxodiawc

update storage.buckets
set public = true
where id = 'story-assets';

drop policy if exists "Story assets are publicly readable" on storage.objects;
create policy "Story assets are publicly readable"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'story-assets');

do $$
declare
  sunheri_images integer;
  sunheri_audio integer;
  khabar_images integer;
  khabar_audio integer;
begin
  select count(*) filter (
    where name ~ '^stories/kanha ki sunheri subah/images/page-[0-9]{3}\.webp$'
  ),
  count(*) filter (
    where name ~ '^stories/kanha ki sunheri subah/audio/page-[0-9]{3}\.mp3$'
  ),
  count(*) filter (
    where name ~ '^stories/kanha ke aane ki khabar/images/page-[0-9]{3}\.webp$'
  ),
  count(*) filter (
    where name ~ '^stories/kanha ke aane ki khabar/audio/page-[0-9]{3}\.mp3$'
  )
  into sunheri_images, sunheri_audio, khabar_images, khabar_audio
  from storage.objects
  where bucket_id = 'story-assets';

  if sunheri_images <> 9 or sunheri_audio <> 9 then
    raise exception
      'Kanha Ki Sunheri Subah requires 9 images and 9 audio files; found % images and % audio files.',
      sunheri_images,
      sunheri_audio;
  end if;

  if khabar_images <> 11 or khabar_audio <> 11 then
    raise exception
      'Kanha Ke Aane Ki Khabar requires 11 images and 11 audio files; found % images and % audio files.',
      khabar_images,
      khabar_audio;
  end if;
end
$$;

insert into public.story_categories (
  id,
  title,
  display_order
)
values (
  '33333333-3333-4333-8333-333333333333'::uuid,
  'Krishna Stories',
  1
)
on conflict (id) do update set
  title = excluded.title,
  display_order = excluded.display_order;

insert into public.story_sections (
  id,
  title,
  section_type,
  emoji,
  display_order
)
values (
  '44444444-4444-4444-8444-444444444444'::uuid,
  'For You',
  'for_you',
  'heart',
  0
)
on conflict (id) do update set
  title = excluded.title,
  section_type = excluded.section_type,
  emoji = excluded.emoji,
  display_order = excluded.display_order;

insert into public.stories (
  id,
  companion_id,
  category_id,
  title,
  description,
  thumbnail_url,
  cover_url,
  total_pages,
  is_featured,
  is_premium
)
values
  (
    '11111111-1111-4111-8111-111111111111'::uuid,
    'krishna',
    '33333333-3333-4333-8333-333333333333'::uuid,
    'Kanha Ki Sunheri Subah',
    'Kanha begins a bright new morning.',
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/story-assets/stories/kanha%20ki%20sunheri%20subah/images/page-001.webp',
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/story-assets/stories/kanha%20ki%20sunheri%20subah/images/page-001.webp',
    9,
    true,
    false
  ),
  (
    '22222222-2222-4222-8222-222222222222'::uuid,
    'krishna',
    '33333333-3333-4333-8333-333333333333'::uuid,
    'Kanha Ke Aane Ki Khabar',
    'The joyful news of Kanha''s arrival spreads.',
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/story-assets/stories/kanha%20ke%20aane%20ki%20khabar/images/page-001.webp',
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/story-assets/stories/kanha%20ke%20aane%20ki%20khabar/images/page-001.webp',
    11,
    false,
    false
  )
on conflict (id) do update set
  companion_id = excluded.companion_id,
  category_id = excluded.category_id,
  title = excluded.title,
  description = excluded.description,
  thumbnail_url = excluded.thumbnail_url,
  cover_url = excluded.cover_url,
  total_pages = excluded.total_pages,
  is_featured = excluded.is_featured,
  is_premium = excluded.is_premium;

delete from public.section_stories
where section_id = '44444444-4444-4444-8444-444444444444'::uuid
  and story_id in (
    '11111111-1111-4111-8111-111111111111'::uuid,
    '22222222-2222-4222-8222-222222222222'::uuid
  );

insert into public.section_stories (
  id,
  section_id,
  story_id,
  sort_order
)
values
  (
    '55555555-5555-4555-8555-555555555551'::uuid,
    '44444444-4444-4444-8444-444444444444'::uuid,
    '11111111-1111-4111-8111-111111111111'::uuid,
    0
  ),
  (
    '55555555-5555-4555-8555-555555555552'::uuid,
    '44444444-4444-4444-8444-444444444444'::uuid,
    '22222222-2222-4222-8222-222222222222'::uuid,
    1
  )
on conflict (id) do update set
  section_id = excluded.section_id,
  story_id = excluded.story_id,
  sort_order = excluded.sort_order;

delete from public.story_pages
where story_id in (
  '11111111-1111-4111-8111-111111111111'::uuid,
  '22222222-2222-4222-8222-222222222222'::uuid
);

insert into public.story_pages (
  id,
  story_id,
  page_number,
  hindi_text,
  image_url,
  audio_url
)
select
  (
    '66666666-6666-4666-8666-'
    || lpad(page_number::text, 12, '0')
  )::uuid,
  '11111111-1111-4111-8111-111111111111'::uuid,
  page_number,
  '',
  'stories/kanha ki sunheri subah/images/page-'
    || lpad(page_number::text, 3, '0')
    || '.webp',
  'stories/kanha ki sunheri subah/audio/page-'
    || lpad(page_number::text, 3, '0')
    || '.mp3'
from generate_series(1, 9) as pages(page_number);

insert into public.story_pages (
  id,
  story_id,
  page_number,
  hindi_text,
  image_url,
  audio_url
)
select
  (
    '77777777-7777-4777-8777-'
    || lpad(page_number::text, 12, '0')
  )::uuid,
  '22222222-2222-4222-8222-222222222222'::uuid,
  page_number,
  '',
  'stories/kanha ke aane ki khabar/images/page-'
    || lpad(page_number::text, 3, '0')
    || '.webp',
  'stories/kanha ke aane ki khabar/audio/page-'
    || lpad(page_number::text, 3, '0')
    || '.mp3'
from generate_series(1, 11) as pages(page_number);

grant select on public.story_categories to anon, authenticated;
grant select on public.story_sections to anon, authenticated;
grant select on public.section_stories to anon, authenticated;
grant select on public.stories to anon, authenticated;
grant select on public.story_pages to anon, authenticated;

alter table public.story_categories enable row level security;
alter table public.story_sections enable row level security;
alter table public.section_stories enable row level security;
alter table public.stories enable row level security;
alter table public.story_pages enable row level security;

drop policy if exists "Story categories are publicly readable"
on public.story_categories;
create policy "Story categories are publicly readable"
on public.story_categories for select to anon, authenticated using (true);

drop policy if exists "Story sections are publicly readable"
on public.story_sections;
create policy "Story sections are publicly readable"
on public.story_sections for select to anon, authenticated using (true);

drop policy if exists "Section stories are publicly readable"
on public.section_stories;
create policy "Section stories are publicly readable"
on public.section_stories for select to anon, authenticated using (true);

drop policy if exists "Stories are publicly readable" on public.stories;
create policy "Stories are publicly readable"
on public.stories for select to anon, authenticated using (true);

drop policy if exists "Story pages are publicly readable"
on public.story_pages;
create policy "Story pages are publicly readable"
on public.story_pages for select to anon, authenticated using (true);
