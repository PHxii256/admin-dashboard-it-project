update storage.buckets
set file_size_limit = 209715200
where id in (
  'staff-cv',
  'staff-images',
  'news-images',
  'event-images',
  'study-plan-files',
  'schedule-files',
  'calendar-files',
  'activity-images',
  'gallery-images',
  'resources-files',
  'facilities-images',
  'home-images',
  'home-files',
  'important-links-images',
  'admission-files',
  'international-handbook-files',
  'honor-list-files',
  'advisor-avatars'
);
