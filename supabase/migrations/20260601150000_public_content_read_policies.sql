grant select on public.companions to anon, authenticated;
grant select on public.story_categories to anon, authenticated;
grant select on public.story_sections to anon, authenticated;
grant select on public.section_stories to anon, authenticated;
grant select on public.stories to anon, authenticated;
grant select on public.story_pages to anon, authenticated;
grant insert on public.profiles to anon, authenticated;
grant select on public.profiles to authenticated;
grant select on storage.buckets to anon, authenticated;
grant select on storage.objects to anon, authenticated;

alter table public.companions enable row level security;
alter table public.story_categories enable row level security;
alter table public.story_sections enable row level security;
alter table public.section_stories enable row level security;
alter table public.stories enable row level security;
alter table public.story_pages enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "App assets are readable" on storage.objects;
create policy "App assets are readable"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'app-assets');

drop policy if exists "App assets bucket is readable" on storage.buckets;
create policy "App assets bucket is readable"
on storage.buckets
for select
to anon, authenticated
using (id = 'app-assets');

insert into public.companions (
  id,
  display_name,
  short_description,
  long_description,
  image_path
) values
  (
    'krishna',
    'Baby Krishna',
    'Playful and loving, Krishna guides you through stories of joy and wonder.',
    'A playful and divine presence that brings warmth and peace to your child''s bedtime stories.',
    'companions/comp_krishna.webp'
  ),
  (
    'hanuman',
    'Baby Hanuman',
    'Strong yet gentle, Hanuman provides a sense of protection and courage.',
    'A brave and loyal companion who fills every bedtime tale with courage, kindness, and a comforting sense of protection.',
    'companions/comp_hanuman.webp'
  ),
  (
    'shiva',
    'Baby Shiva',
    'Meditative and calm, Shiva helps clear the mind for a restful sleep.',
    'A calm, moonlit guide who brings stillness, balance, and peaceful wonder to quiet nighttime adventures.',
    'companions/comp_shiva.webp'
  ),
  (
    'ganesha',
    'Baby Ganesha',
    'The remover of obstacles, Ganesha brings a comforting and sweet presence.',
    'A wise and gentle friend who helps every story feel safe, joyful, and full of soft beginnings.',
    'companions/comp_ganesha.webp'
  ),
  (
    'bheem',
    'Baby Bheem',
    'Reliable and brave, Bheem offers steady and grounded story experience.',
    'A strong and cheerful companion who brings confidence, loyalty, and a grounded sense of adventure to bedtime.',
    'companions/comp_bheem.webp'
  ),
  (
    'arjun',
    'Baby Arjun',
    'Focused and visionary, Arjun leads you through tales of purpose and light.',
    'A focused and thoughtful friend who brings purpose, wonder, and gentle courage to every dream-bound story.',
    'companions/comp_arjun.webp'
  )
on conflict (id) do update set
  display_name = excluded.display_name,
  short_description = excluded.short_description,
  long_description = excluded.long_description,
  image_path = excluded.image_path;

drop policy if exists "Companions are publicly readable" on public.companions;
create policy "Companions are publicly readable"
on public.companions
for select
to anon, authenticated
using (true);

drop policy if exists "Story categories are publicly readable" on public.story_categories;
create policy "Story categories are publicly readable"
on public.story_categories
for select
to anon, authenticated
using (true);

drop policy if exists "Story sections are publicly readable" on public.story_sections;
create policy "Story sections are publicly readable"
on public.story_sections
for select
to anon, authenticated
using (true);

drop policy if exists "Section stories are publicly readable" on public.section_stories;
create policy "Section stories are publicly readable"
on public.section_stories
for select
to anon, authenticated
using (true);

drop policy if exists "Stories are publicly readable" on public.stories;
create policy "Stories are publicly readable"
on public.stories
for select
to anon, authenticated
using (true);

drop policy if exists "Story pages are publicly readable" on public.story_pages;
create policy "Story pages are publicly readable"
on public.story_pages
for select
to anon, authenticated
using (true);

drop policy if exists "Profiles can be created during onboarding" on public.profiles;
create policy "Profiles can be created during onboarding"
on public.profiles
for insert
to anon, authenticated
with check (true);
