create extension if not exists pgcrypto;

create or replace function public.set_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  announcement_date date not null,
  main_image_path text,
  attachment_image_paths text[] not null default '{}',
  pdf_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint announcements_title_not_blank check (length(trim(title)) > 0),
  constraint announcements_description_not_blank check (length(trim(description)) > 0)
);

drop trigger if exists trg_announcements_set_updated_at on public.announcements;
create trigger trg_announcements_set_updated_at
before update on public.announcements
for each row
execute function public.set_updated_at_column();

alter table public.announcements enable row level security;

drop policy if exists announcements_select_anon on public.announcements;
create policy announcements_select_anon on public.announcements
for select to anon using (true);

drop policy if exists announcements_insert_anon on public.announcements;
create policy announcements_insert_anon on public.announcements
for insert to anon with check (true);

drop policy if exists announcements_update_anon on public.announcements;
create policy announcements_update_anon on public.announcements
for update to anon using (true) with check (true);

drop policy if exists announcements_delete_anon on public.announcements;
create policy announcements_delete_anon on public.announcements
for delete to anon using (true);

drop policy if exists announcements_select_authenticated on public.announcements;
create policy announcements_select_authenticated on public.announcements
for select to authenticated using (true);

drop policy if exists announcements_insert_authenticated on public.announcements;
create policy announcements_insert_authenticated on public.announcements
for insert to authenticated with check (true);

drop policy if exists announcements_update_authenticated on public.announcements;
create policy announcements_update_authenticated on public.announcements
for update to authenticated using (true) with check (true);

drop policy if exists announcements_delete_authenticated on public.announcements;
create policy announcements_delete_authenticated on public.announcements
for delete to authenticated using (true);

alter table if exists public.advisor_resources
add column if not exists section text;

update public.advisor_resources
set section = case
  when title ~* '^\[academic_advising\]' then 'academic_advising'
  when title ~* '^\[registration\]' then 'registration'
  when title ~* '^\[(scheduler|schedules)\]' then 'schedules'
  when section is not null then section
  else 'academic_advising'
end
where section is null;

update public.advisor_resources
set title = regexp_replace(title, '^\[(academic_advising|registration|scheduler|schedules)\]\s*', '', 'i')
where title ~* '^\[(academic_advising|registration|scheduler|schedules)\]';

alter table public.advisor_resources
alter column section set default 'academic_advising';

update public.advisor_resources
set section = 'schedules'
where section = 'scheduler';

alter table public.advisor_resources
alter column section set not null;

alter table public.advisor_resources
drop constraint if exists advisor_resources_section_valid;

alter table public.advisor_resources
add constraint advisor_resources_section_valid
check (section in ('academic_advising', 'registration', 'schedules'));

drop policy if exists storage_announcements_insert_anon on storage.objects;
create policy storage_announcements_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('application/pdf', 'image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^announcements/.+/.+'
);

drop policy if exists storage_announcements_select_anon on storage.objects;
create policy storage_announcements_select_anon
on storage.objects
for select to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^announcements/.+/.+'
);

drop policy if exists storage_announcements_delete_anon on storage.objects;
create policy storage_announcements_delete_anon
on storage.objects
for delete to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^announcements/.+/.+'
);

drop policy if exists storage_announcements_insert_authenticated on storage.objects;
create policy storage_announcements_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('application/pdf', 'image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^announcements/.+/.+'
);

drop policy if exists storage_announcements_select_authenticated on storage.objects;
create policy storage_announcements_select_authenticated
on storage.objects
for select to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^announcements/.+/.+'
);

drop policy if exists storage_announcements_delete_authenticated on storage.objects;
create policy storage_announcements_delete_authenticated
on storage.objects
for delete to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^announcements/.+/.+'
);
