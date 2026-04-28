create or replace function public.set_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.honor_list_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  file_path text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint honor_list_resources_title_not_blank check (length(trim(title)) > 0)
);

drop trigger if exists trg_honor_list_resources_set_updated_at on public.honor_list_resources;
create trigger trg_honor_list_resources_set_updated_at
before update on public.honor_list_resources
for each row
execute function public.set_updated_at_column();

alter table public.honor_list_resources enable row level security;

drop policy if exists honor_list_resources_select_anon on public.honor_list_resources;
create policy honor_list_resources_select_anon on public.honor_list_resources
for select to anon using (true);

drop policy if exists honor_list_resources_insert_anon on public.honor_list_resources;
create policy honor_list_resources_insert_anon on public.honor_list_resources
for insert to anon with check (true);

drop policy if exists honor_list_resources_update_anon on public.honor_list_resources;
create policy honor_list_resources_update_anon on public.honor_list_resources
for update to anon using (true) with check (true);

drop policy if exists honor_list_resources_delete_anon on public.honor_list_resources;
create policy honor_list_resources_delete_anon on public.honor_list_resources
for delete to anon using (true);

drop policy if exists honor_list_resources_select_authenticated on public.honor_list_resources;
create policy honor_list_resources_select_authenticated on public.honor_list_resources
for select to authenticated using (true);

drop policy if exists honor_list_resources_insert_authenticated on public.honor_list_resources;
create policy honor_list_resources_insert_authenticated on public.honor_list_resources
for insert to authenticated with check (true);

drop policy if exists honor_list_resources_update_authenticated on public.honor_list_resources;
create policy honor_list_resources_update_authenticated on public.honor_list_resources
for update to authenticated using (true) with check (true);

drop policy if exists honor_list_resources_delete_authenticated on public.honor_list_resources;
create policy honor_list_resources_delete_authenticated on public.honor_list_resources
for delete to authenticated using (true);

drop policy if exists storage_honor_list_resources_insert_anon on storage.objects;
create policy storage_honor_list_resources_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^honor-list-resources/.+/.+'
);

drop policy if exists storage_honor_list_resources_select_anon on storage.objects;
create policy storage_honor_list_resources_select_anon
on storage.objects
for select to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^honor-list-resources/.+/.+'
);

drop policy if exists storage_honor_list_resources_delete_anon on storage.objects;
create policy storage_honor_list_resources_delete_anon
on storage.objects
for delete to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^honor-list-resources/.+/.+'
);

drop policy if exists storage_honor_list_resources_insert_authenticated on storage.objects;
create policy storage_honor_list_resources_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^honor-list-resources/.+/.+'
);

drop policy if exists storage_honor_list_resources_select_authenticated on storage.objects;
create policy storage_honor_list_resources_select_authenticated
on storage.objects
for select to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^honor-list-resources/.+/.+'
);

drop policy if exists storage_honor_list_resources_delete_authenticated on storage.objects;
create policy storage_honor_list_resources_delete_authenticated
on storage.objects
for delete to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^honor-list-resources/.+/.+'
);

notify pgrst, 'reload schema';
