drop policy if exists "App assets are readable" on storage.objects;

create policy "App assets are readable"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'app-assets');
