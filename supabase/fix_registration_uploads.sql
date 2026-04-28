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
  and (metadata->>'mimetype') in ('video/mp4', 'video/webm', 'video/quicktime')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^registration-videos/.+/.+'
);

drop policy if exists storage_registration_videos_select_anon on storage.objects;
create policy storage_registration_videos_select_anon
on storage.objects
for select to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^registration-videos/.+/.+'
);

drop policy if exists storage_registration_videos_delete_anon on storage.objects;
create policy storage_registration_videos_delete_anon
on storage.objects
for delete to anon
using (
  bucket_id = 'resources-files'
  and name ~ '^registration-videos/.+/.+'
);

drop policy if exists storage_registration_videos_insert_authenticated on storage.objects;
create policy storage_registration_videos_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('video/mp4', 'video/webm', 'video/quicktime')
  and coalesce((metadata->>'size')::bigint, 0) <= 200 * 1024 * 1024
  and name ~ '^registration-videos/.+/.+'
);

drop policy if exists storage_registration_videos_select_authenticated on storage.objects;
create policy storage_registration_videos_select_authenticated
on storage.objects
for select to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^registration-videos/.+/.+'
);

drop policy if exists storage_registration_videos_delete_authenticated on storage.objects;
create policy storage_registration_videos_delete_authenticated
on storage.objects
for delete to authenticated
using (
  bucket_id = 'resources-files'
  and name ~ '^registration-videos/.+/.+'
);
