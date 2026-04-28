create or replace function public.set_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.smart_elearning_videos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  source_type text not null,
  youtube_url text,
  video_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint smart_elearning_videos_title_not_blank check (length(trim(title)) > 0),
  constraint smart_elearning_videos_source_type_valid check (source_type in ('video', 'file', 'link', 'youtube', 'upload')),
  constraint smart_elearning_videos_youtube_format check (youtube_url is null or youtube_url ~* '^https?://'),
  constraint smart_elearning_videos_data_shape check (
    (source_type in ('link', 'youtube') and youtube_url is not null and video_path is null)
    or (source_type in ('video', 'file', 'upload') and video_path is not null and youtube_url is null)
  )
);

alter table if exists public.smart_elearning_videos
drop constraint if exists smart_elearning_videos_source_type_valid;

alter table if exists public.smart_elearning_videos
add constraint smart_elearning_videos_source_type_valid
check (source_type in ('video', 'file', 'link', 'youtube', 'upload'));

alter table if exists public.smart_elearning_videos
drop constraint if exists smart_elearning_videos_youtube_format;

alter table if exists public.smart_elearning_videos
add constraint smart_elearning_videos_youtube_format
check (youtube_url is null or youtube_url ~* '^https?://');

alter table if exists public.smart_elearning_videos
drop constraint if exists smart_elearning_videos_data_shape;

alter table if exists public.smart_elearning_videos
add constraint smart_elearning_videos_data_shape
check (
  (source_type in ('link', 'youtube') and youtube_url is not null and video_path is null)
  or (source_type in ('video', 'file', 'upload') and video_path is not null and youtube_url is null)
);

drop trigger if exists trg_smart_elearning_videos_set_updated_at on public.smart_elearning_videos;
create trigger trg_smart_elearning_videos_set_updated_at
before update on public.smart_elearning_videos
for each row
execute function public.set_updated_at_column();

alter table public.smart_elearning_videos enable row level security;

drop policy if exists smart_elearning_videos_select_anon on public.smart_elearning_videos;
create policy smart_elearning_videos_select_anon on public.smart_elearning_videos
for select to anon using (true);

drop policy if exists smart_elearning_videos_insert_anon on public.smart_elearning_videos;
create policy smart_elearning_videos_insert_anon on public.smart_elearning_videos
for insert to anon with check (true);

drop policy if exists smart_elearning_videos_update_anon on public.smart_elearning_videos;
create policy smart_elearning_videos_update_anon on public.smart_elearning_videos
for update to anon using (true) with check (true);

drop policy if exists smart_elearning_videos_delete_anon on public.smart_elearning_videos;
create policy smart_elearning_videos_delete_anon on public.smart_elearning_videos
for delete to anon using (true);

drop policy if exists smart_elearning_videos_select_authenticated on public.smart_elearning_videos;
create policy smart_elearning_videos_select_authenticated on public.smart_elearning_videos
for select to authenticated using (true);

drop policy if exists smart_elearning_videos_insert_authenticated on public.smart_elearning_videos;
create policy smart_elearning_videos_insert_authenticated on public.smart_elearning_videos
for insert to authenticated with check (true);

drop policy if exists smart_elearning_videos_update_authenticated on public.smart_elearning_videos;
create policy smart_elearning_videos_update_authenticated on public.smart_elearning_videos
for update to authenticated using (true) with check (true);

drop policy if exists smart_elearning_videos_delete_authenticated on public.smart_elearning_videos;
create policy smart_elearning_videos_delete_authenticated on public.smart_elearning_videos
for delete to authenticated using (true);

drop policy if exists storage_smart_elearning_videos_insert_anon on storage.objects;
create policy storage_smart_elearning_videos_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('video/mp4', 'video/webm', 'video/quicktime', 'application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^smart-elearning/.+/.+'
);

drop policy if exists storage_smart_elearning_videos_select_anon on storage.objects;
create policy storage_smart_elearning_videos_select_anon
on storage.objects
for select to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^smart-elearning/.+/.+'
);

drop policy if exists storage_smart_elearning_videos_delete_anon on storage.objects;
create policy storage_smart_elearning_videos_delete_anon
on storage.objects
for delete to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^smart-elearning/.+/.+'
);

drop policy if exists storage_smart_elearning_videos_insert_authenticated on storage.objects;
create policy storage_smart_elearning_videos_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('video/mp4', 'video/webm', 'video/quicktime', 'application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^smart-elearning/.+/.+'
);

drop policy if exists storage_smart_elearning_videos_select_authenticated on storage.objects;
create policy storage_smart_elearning_videos_select_authenticated
on storage.objects
for select to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^smart-elearning/.+/.+'
);

drop policy if exists storage_smart_elearning_videos_delete_authenticated on storage.objects;
create policy storage_smart_elearning_videos_delete_authenticated
on storage.objects
for delete to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^smart-elearning/.+/.+'
);

notify pgrst, 'reload schema';
