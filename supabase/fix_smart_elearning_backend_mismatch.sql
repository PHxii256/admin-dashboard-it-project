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
