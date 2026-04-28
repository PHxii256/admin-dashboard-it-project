create or replace function public.set_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.academic_advising (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  file_path text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint academic_advising_title_not_blank check (length(trim(title)) > 0)
);

drop trigger if exists trg_academic_advising_set_updated_at on public.academic_advising;
create trigger trg_academic_advising_set_updated_at
before update on public.academic_advising
for each row
execute function public.set_updated_at_column();

alter table public.academic_advising enable row level security;

drop policy if exists academic_advising_select_anon on public.academic_advising;
create policy academic_advising_select_anon on public.academic_advising
for select to anon using (true);

drop policy if exists academic_advising_insert_anon on public.academic_advising;
create policy academic_advising_insert_anon on public.academic_advising
for insert to anon with check (true);

drop policy if exists academic_advising_update_anon on public.academic_advising;
create policy academic_advising_update_anon on public.academic_advising
for update to anon using (true) with check (true);

drop policy if exists academic_advising_delete_anon on public.academic_advising;
create policy academic_advising_delete_anon on public.academic_advising
for delete to anon using (true);

drop policy if exists academic_advising_select_authenticated on public.academic_advising;
create policy academic_advising_select_authenticated on public.academic_advising
for select to authenticated using (true);

drop policy if exists academic_advising_insert_authenticated on public.academic_advising;
create policy academic_advising_insert_authenticated on public.academic_advising
for insert to authenticated with check (true);

drop policy if exists academic_advising_update_authenticated on public.academic_advising;
create policy academic_advising_update_authenticated on public.academic_advising
for update to authenticated using (true) with check (true);

drop policy if exists academic_advising_delete_authenticated on public.academic_advising;
create policy academic_advising_delete_authenticated on public.academic_advising
for delete to authenticated using (true);

drop policy if exists storage_academic_advising_files_insert_anon on storage.objects;
create policy storage_academic_advising_files_insert_anon
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
    'text/plain'
  )
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^academic-advising/.+/.+'
);

drop policy if exists storage_academic_advising_files_select_anon on storage.objects;
create policy storage_academic_advising_files_select_anon
on storage.objects
for select to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^academic-advising/.+/.+'
);

drop policy if exists storage_academic_advising_files_delete_anon on storage.objects;
create policy storage_academic_advising_files_delete_anon
on storage.objects
for delete to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^academic-advising/.+/.+'
);

drop policy if exists storage_academic_advising_files_insert_authenticated on storage.objects;
create policy storage_academic_advising_files_insert_authenticated
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
    'text/plain'
  )
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^academic-advising/.+/.+'
);

drop policy if exists storage_academic_advising_files_select_authenticated on storage.objects;
create policy storage_academic_advising_files_select_authenticated
on storage.objects
for select to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^academic-advising/.+/.+'
);

drop policy if exists storage_academic_advising_files_delete_authenticated on storage.objects;
create policy storage_academic_advising_files_delete_authenticated
on storage.objects
for delete to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^academic-advising/.+/.+'
);

notify pgrst, 'reload schema';

-- mostafa mahmiud ahned