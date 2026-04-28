alter table if exists public.registration_videos
drop constraint if exists registration_videos_source_type_valid;

alter table if exists public.registration_videos
add constraint registration_videos_source_type_valid
check (source_type in ('video', 'file', 'link', 'youtube', 'upload'));

alter table if exists public.registration_videos
drop constraint if exists registration_videos_youtube_format;

alter table if exists public.registration_videos
add constraint registration_videos_youtube_format
check (youtube_url is null or youtube_url ~* '^https?://');

alter table if exists public.registration_videos
drop constraint if exists registration_videos_data_shape;

alter table if exists public.registration_videos
add constraint registration_videos_data_shape
check (
  (source_type in ('link', 'youtube') and youtube_url is not null and video_path is null)
  or (source_type in ('video', 'file', 'upload') and video_path is not null and youtube_url is null)
);

update storage.buckets
set public = true,
    file_size_limit = 209715200
where id = 'resources-files';

drop policy if exists storage_registration_videos_insert_anon on storage.objects;
create policy storage_registration_videos_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('video/mp4', 'video/webm', 'video/quicktime', 'application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^registration-videos/.+/.+'
);

drop policy if exists storage_registration_videos_insert_authenticated on storage.objects;
create policy storage_registration_videos_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('video/mp4', 'video/webm', 'video/quicktime', 'application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^registration-videos/.+/.+'
);
