-- =============================================================================
-- Advising resources — database setup (public.advisor_resources + storage)
-- =============================================================================
-- The full dashboard schema also defines this table in:
--   supabase/admin_dashboard_collections.sql
-- Run this file alone if you only need advisor_resources + resources-files ACLs.
-- Safe to re-run: uses IF NOT EXISTS / DROP POLICY IF EXISTS / ON CONFLICT DO NOTHING.
-- =============================================================================

create or replace function public.set_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

insert into storage.buckets (id, name, public)
values ('resources-files', 'resources-files', true)
on conflict (id) do nothing;

update storage.buckets
set public = true
where id = 'resources-files';

create table if not exists public.advisor_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  resource_type text not null,
  resource_url text,
  file_path text,
  duration text,
  thumbnail_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint advisor_resources_title_not_blank check (length(trim(title)) > 0),
  constraint advisor_resources_type_valid check (resource_type in ('file', 'video', 'link')),
  constraint advisor_resources_url_format check (resource_url is null or resource_url ~* '^https?://'),
  constraint advisor_resources_data_shape check (
    (resource_type = 'file' and file_path is not null and resource_url is null)
    or (resource_type in ('video', 'link') and resource_url is not null and file_path is null)
  )
);

alter table if exists public.advisor_resources
  add column if not exists description text;

alter table if exists public.advisor_resources
  add column if not exists duration text;

alter table if exists public.advisor_resources
  add column if not exists thumbnail_path text;

drop trigger if exists trg_advisor_resources_set_updated_at on public.advisor_resources;
create trigger trg_advisor_resources_set_updated_at
before update on public.advisor_resources
for each row
execute function public.set_updated_at_column();

alter table public.advisor_resources enable row level security;

drop policy if exists advisor_resources_select_anon on public.advisor_resources;
create policy advisor_resources_select_anon on public.advisor_resources
for select to anon using (true);

drop policy if exists advisor_resources_insert_anon on public.advisor_resources;
create policy advisor_resources_insert_anon on public.advisor_resources
for insert to anon with check (true);

drop policy if exists advisor_resources_update_anon on public.advisor_resources;
create policy advisor_resources_update_anon on public.advisor_resources
for update to anon using (true) with check (true);

drop policy if exists advisor_resources_delete_anon on public.advisor_resources;
create policy advisor_resources_delete_anon on public.advisor_resources
for delete to anon using (true);

drop policy if exists advisor_resources_select_authenticated on public.advisor_resources;
create policy advisor_resources_select_authenticated on public.advisor_resources
for select to authenticated using (true);

drop policy if exists advisor_resources_insert_authenticated on public.advisor_resources;
create policy advisor_resources_insert_authenticated on public.advisor_resources
for insert to authenticated with check (true);

drop policy if exists advisor_resources_update_authenticated on public.advisor_resources;
create policy advisor_resources_update_authenticated on public.advisor_resources
for update to authenticated using (true) with check (true);

drop policy if exists advisor_resources_delete_authenticated on public.advisor_resources;
create policy advisor_resources_delete_authenticated on public.advisor_resources
for delete to authenticated using (true);

-- Upload / read / delete objects under resources-files (path prefix resources/… from the app)
drop policy if exists storage_resources_files_insert_anon on storage.objects;
create policy storage_resources_files_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in (
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/zip',
    'text/plain',
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/webm',
    'video/quicktime'
  )
  and coalesce((metadata->>'size')::bigint, 0) <= 100 * 1024 * 1024
  and name ~ '^resources/.+/.+'
);

drop policy if exists storage_resources_files_select_anon on storage.objects;
create policy storage_resources_files_select_anon
on storage.objects
for select to anon
using (bucket_id = 'resources-files');

drop policy if exists storage_resources_files_delete_anon on storage.objects;
create policy storage_resources_files_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'resources-files');

drop policy if exists storage_resources_files_insert_authenticated on storage.objects;
create policy storage_resources_files_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in (
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/zip',
    'text/plain',
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/webm',
    'video/quicktime'
  )
  and coalesce((metadata->>'size')::bigint, 0) <= 100 * 1024 * 1024
  and name ~ '^resources/.+/.+'
);

drop policy if exists storage_resources_files_select_authenticated on storage.objects;
create policy storage_resources_files_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'resources-files');

drop policy if exists storage_resources_files_delete_authenticated on storage.objects;
create policy storage_resources_files_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'resources-files');
