alter table public.saved_stories enable row level security;

grant select, insert, delete on public.saved_stories to authenticated;

drop policy if exists "Saved stories are readable by owner"
on public.saved_stories;
drop policy if exists "Saved stories are insertable by owner"
on public.saved_stories;
drop policy if exists "Saved stories are deletable by owner"
on public.saved_stories;

create policy "Saved stories are readable by owner"
on public.saved_stories
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Saved stories are insertable by owner"
on public.saved_stories
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Saved stories are deletable by owner"
on public.saved_stories
for delete
to authenticated
using ((select auth.uid()) = user_id);
