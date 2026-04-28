-- Admin dashboard collections + security for Supabase
-- Run in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  href text,
  image_url text,
  image_urls text[],
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint news_title_not_blank check (length(trim(title)) > 0),
  constraint news_description_not_blank check (length(trim(description)) > 0),
  constraint news_href_format check (href is null or href ~* '^https?://')
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  day text not null,
  month text not null,
  time_range text not null,
  location_name text,
  href text,
  image_url text,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint events_title_not_blank check (length(trim(title)) > 0),
  constraint events_description_not_blank check (length(trim(description)) > 0),
  constraint events_day_not_blank check (length(trim(day)) > 0),
  constraint events_month_not_blank check (length(trim(month)) > 0),
  constraint events_time_range_not_blank check (length(trim(time_range)) > 0),
  constraint events_location_name_not_blank check (location_name is null or length(trim(location_name)) > 0),
  constraint events_href_format check (href is null or href ~* '^https?://')
);

alter table public.events
  add column if not exists location_name text;

alter table public.events
  drop constraint if exists events_location_name_not_blank;

alter table public.events
  add constraint events_location_name_not_blank
  check (location_name is null or length(trim(location_name)) > 0);
 
create table if not exists public.study_plans (
  id uuid primary key default gen_random_uuid(),
  undergrad_cs_old_curriculum text,
  undergrad_is_old_curriculum text,
  undergrad_ai_old_curriculum text,
  undergrad_cs_new_curriculum text,
  undergrad_is_new_curriculum text,
  undergrad_ai_new_curriculum text,
  master_cs_old_curriculum text,
  master_is_old_curriculum text,
  master_ai_old_curriculum text,
  master_cs_new_curriculum text,
  master_is_new_curriculum text,
  master_ai_new_curriculum text,
  phd_cs_old_curriculum text,
  phd_is_old_curriculum text,
  phd_ai_old_curriculum text,
  phd_cs_new_curriculum text,
  phd_is_new_curriculum text,
  phd_ai_new_curriculum text,
  diploma_big_data jsonb,
  diploma_applied_ai jsonb,
  diploma_business_intelligence jsonb,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint study_plans_diploma_big_data_array check (
    diploma_big_data is null or jsonb_typeof(diploma_big_data) = 'array'
  ),
  constraint study_plans_diploma_applied_ai_array check (
    diploma_applied_ai is null or jsonb_typeof(diploma_applied_ai) = 'array'
  ),
  constraint study_plans_diploma_business_intelligence_array check (
    diploma_business_intelligence is null or jsonb_typeof(diploma_business_intelligence) = 'array'
  )
);

create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  title text,
  category text,
  schedule_type text not null,
  semester text not null,
  year integer not null,
  file_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schedules_title_not_blank check (title is null or length(trim(title)) > 0),
  constraint schedules_category_valid check (category is null or category in ('exams', 'lectures_sections')),
  constraint schedules_type_valid check (schedule_type in ('Quiz 1', 'Quiz 2', 'Final', 'Semester Schedule')),
  constraint schedules_semester_valid check (semester in ('Fall', 'Spring', 'Summer')),
  constraint schedules_year_valid check (year between 2000 and 2100)
);

create table if not exists public.calendars (
  id uuid primary key default gen_random_uuid(),
  program_level text not null,
  year integer not null,
  file_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint calendars_program_level_valid check (
    program_level in ('Undergraduate', 'Postgraduate', 'Professional Diplomas')
  ),
  constraint calendars_year_valid check (year between 2000 and 2100)
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  activity_type text not null,
  href text,
  image_url text,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint activities_title_not_blank check (length(trim(title)) > 0),
  constraint activities_description_not_blank check (length(trim(description)) > 0),
  constraint activities_type_valid check (activity_type in ('sport', 'cultural', 'art', 'student club')),
  constraint activities_href_format check (href is null or href ~* '^https?://')
);

create table if not exists public.photo_gallery (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint photo_gallery_image_url_not_blank check (length(trim(image_url)) > 0)
);

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

create table if not exists public.advisor_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  section text not null default 'academic_advising',
  resource_type text not null,
  resource_url text,
  file_path text,
  duration text,
  thumbnail_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint advisor_resources_title_not_blank check (length(trim(title)) > 0),
  constraint advisor_resources_section_valid check (section in ('academic_advising', 'registration', 'schedules')),
  constraint advisor_resources_type_valid check (resource_type in ('file', 'video', 'link')),
  constraint advisor_resources_url_format check (resource_url is null or resource_url ~* '^https?://'),
  constraint advisor_resources_data_shape check (
    (resource_type = 'file' and file_path is not null and resource_url is null)
    or (resource_type in ('video', 'link') and resource_url is not null and file_path is null)
  )
);

create table if not exists public.student_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text not null default 'Other / Untagged',
  resource_type text not null,
  resource_url text,
  file_path text,
  duration text,
  thumbnail_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_resources_title_not_blank check (length(trim(title)) > 0),
  constraint student_resources_category_valid check (
    category in ('Registration Guide', 'Facilities Resource', 'Other / Untagged')
  ),
  constraint student_resources_type_valid check (resource_type in ('file', 'video', 'link')),
  constraint student_resources_url_format check (resource_url is null or resource_url ~* '^https?://'),
  constraint student_resources_data_shape check (
    (resource_type = 'file' and file_path is not null and resource_url is null)
    or (resource_type in ('video', 'link') and resource_url is not null and file_path is null)
  )
);

create table if not exists public.students (
  student_id text primary key,
  full_name text not null,
  nationality text not null,
  college text,
  major text not null,
  team_code text,
  amit text,
  level text not null,
  class_name text,
  mobile text,
  email text,
  advisor_name text,
  gpa numeric(3,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint students_student_id_not_blank check (length(trim(student_id)) > 0),
  constraint students_full_name_not_blank check (length(trim(full_name)) > 0),
  constraint students_nationality_not_blank check (length(trim(nationality)) > 0),
  constraint students_major_valid check (major in ('cs', 'is', 'ai', 'general')),
  constraint students_level_not_blank check (length(trim(level)) > 0),
  constraint students_gpa_valid check (gpa is null or (gpa >= 0 and gpa <= 4))
);

alter table public.students add column if not exists college text;
alter table public.students add column if not exists team_code text;
alter table public.students add column if not exists amit text;
alter table public.students add column if not exists class_name text;
alter table public.students add column if not exists mobile text;
alter table public.students add column if not exists email text;
alter table public.students add column if not exists advisor_name text;

alter table if exists public.staff add column if not exists display_order integer not null default 0;
alter table if exists public.study_plans add column if not exists master_cs_old_curriculum text;
alter table if exists public.study_plans add column if not exists master_is_old_curriculum text;
alter table if exists public.study_plans add column if not exists master_ai_old_curriculum text;
alter table if exists public.study_plans add column if not exists master_cs_new_curriculum text;
alter table if exists public.study_plans add column if not exists master_is_new_curriculum text;
alter table if exists public.study_plans add column if not exists master_ai_new_curriculum text;
alter table if exists public.study_plans add column if not exists phd_cs_old_curriculum text;
alter table if exists public.study_plans add column if not exists phd_is_old_curriculum text;
alter table if exists public.study_plans add column if not exists phd_ai_old_curriculum text;
alter table if exists public.study_plans add column if not exists phd_cs_new_curriculum text;
alter table if exists public.study_plans add column if not exists phd_is_new_curriculum text;
alter table if exists public.study_plans add column if not exists phd_ai_new_curriculum text;
alter table if exists public.study_plans add column if not exists diploma_big_data jsonb;
alter table if exists public.study_plans add column if not exists diploma_applied_ai jsonb;
alter table if exists public.study_plans add column if not exists diploma_business_intelligence jsonb;

create table if not exists public.student_honor_list_documents (
  key text primary key default 'current',
  file_path text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_honor_list_singleton check (key = 'current'),
  constraint student_honor_list_file_not_blank check (length(trim(file_path)) > 0)
);

alter table if exists public.staff
add column if not exists department text;

alter table if exists public.staff
add column if not exists email text;

update public.staff
set email = lower(trim(email))
where email is not null;

alter table if exists public.staff
drop constraint if exists staff_email_not_blank;

alter table if exists public.staff
add constraint staff_email_not_blank check (email is null or length(trim(email)) > 0);

create unique index if not exists staff_email_unique_idx
on public.staff (lower(email))
where email is not null;

alter table if exists public.news
add column if not exists image_urls text[];

update public.news
set image_urls = array[image_url]
where image_url is not null
  and (image_urls is null or cardinality(image_urls) = 0);

alter table if exists public.advisor_resources
add column if not exists section text;

alter table if exists public.advisor_resources
add column if not exists description text;

alter table if exists public.advisor_resources
add column if not exists duration text;

alter table if exists public.advisor_resources
add column if not exists thumbnail_path text;

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

update public.advisor_resources
set section = 'schedules'
where section = 'scheduler';

alter table public.advisor_resources
alter column section set default 'academic_advising';

alter table public.advisor_resources
alter column section set not null;

alter table public.advisor_resources
drop constraint if exists advisor_resources_section_valid;

alter table public.advisor_resources
add constraint advisor_resources_section_valid
check (section in ('academic_advising', 'registration', 'schedules'));

alter table if exists public.student_resources
add column if not exists description text;

alter table if exists public.student_resources
add column if not exists duration text;

alter table if exists public.student_resources
add column if not exists thumbnail_path text;

alter table public.schedules
add column if not exists file_path text;

alter table public.calendars
add column if not exists file_path text;

alter table public.calendars
add column if not exists program_level text;

update public.calendars
set program_level = 'Undergraduate'
where program_level is null;

alter table public.calendars
alter column program_level set not null;

alter table public.calendars
drop column if exists calendar_type;

alter table public.calendars
drop column if exists semester;

alter table public.calendars
drop constraint if exists calendars_type_valid;

alter table public.calendars
drop constraint if exists calendars_semester_valid;

alter table public.calendars
drop constraint if exists calendars_program_level_valid;

alter table public.calendars
add constraint calendars_program_level_valid check (
  program_level in ('Undergraduate', 'Postgraduate', 'Professional Diplomas')
);

create or replace function public.set_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_news_set_updated_at on public.news;
create trigger trg_news_set_updated_at
before update on public.news
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_events_set_updated_at on public.events;
create trigger trg_events_set_updated_at
before update on public.events
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_study_plans_set_updated_at on public.study_plans;
create trigger trg_study_plans_set_updated_at
before update on public.study_plans
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_schedules_set_updated_at on public.schedules;
create trigger trg_schedules_set_updated_at
before update on public.schedules
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_calendars_set_updated_at on public.calendars;
create trigger trg_calendars_set_updated_at
before update on public.calendars
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_activities_set_updated_at on public.activities;
create trigger trg_activities_set_updated_at
before update on public.activities
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_photo_gallery_set_updated_at on public.photo_gallery;
create trigger trg_photo_gallery_set_updated_at
before update on public.photo_gallery
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_announcements_set_updated_at on public.announcements;
create trigger trg_announcements_set_updated_at
before update on public.announcements
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_advisor_resources_set_updated_at on public.advisor_resources;
create trigger trg_advisor_resources_set_updated_at
before update on public.advisor_resources
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_student_resources_set_updated_at on public.student_resources;
create trigger trg_student_resources_set_updated_at
before update on public.student_resources
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_students_set_updated_at on public.students;
create trigger trg_students_set_updated_at
before update on public.students
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_student_honor_list_set_updated_at on public.student_honor_list_documents;
create trigger trg_student_honor_list_set_updated_at
before update on public.student_honor_list_documents
for each row
execute function public.set_updated_at_column();

alter table public.news enable row level security;
alter table public.events enable row level security;
alter table public.study_plans enable row level security;
alter table public.schedules enable row level security;
alter table public.calendars enable row level security;
alter table public.activities enable row level security;
alter table public.photo_gallery enable row level security;
alter table public.announcements enable row level security;
alter table public.advisor_resources enable row level security;
alter table public.student_resources enable row level security;
alter table public.students enable row level security;
alter table public.student_honor_list_documents enable row level security;

-- Demo/admin dashboard anon policies. Tighten for production.
drop policy if exists news_select_anon on public.news;
create policy news_select_anon on public.news
for select to anon using (true);

drop policy if exists news_insert_anon on public.news;
create policy news_insert_anon on public.news
for insert to anon with check (true);

drop policy if exists news_update_anon on public.news;
create policy news_update_anon on public.news
for update to anon using (true) with check (true);

drop policy if exists news_delete_anon on public.news;
create policy news_delete_anon on public.news
for delete to anon using (true);

drop policy if exists events_select_anon on public.events;
create policy events_select_anon on public.events
for select to anon using (true);

drop policy if exists events_insert_anon on public.events;
create policy events_insert_anon on public.events
for insert to anon with check (true);

drop policy if exists events_update_anon on public.events;
create policy events_update_anon on public.events
for update to anon using (true) with check (true);

drop policy if exists events_delete_anon on public.events;
create policy events_delete_anon on public.events
for delete to anon using (true);

drop policy if exists study_plans_select_anon on public.study_plans;
create policy study_plans_select_anon on public.study_plans
for select to anon using (true);

drop policy if exists study_plans_insert_anon on public.study_plans;
create policy study_plans_insert_anon on public.study_plans
for insert to anon with check (true);

drop policy if exists study_plans_update_anon on public.study_plans;
create policy study_plans_update_anon on public.study_plans
for update to anon using (true) with check (true);

drop policy if exists study_plans_delete_anon on public.study_plans;
create policy study_plans_delete_anon on public.study_plans
for delete to anon using (true);

drop policy if exists schedules_select_anon on public.schedules;
create policy schedules_select_anon on public.schedules
for select to anon using (true);

drop policy if exists schedules_insert_anon on public.schedules;
create policy schedules_insert_anon on public.schedules
for insert to anon with check (true);

drop policy if exists schedules_update_anon on public.schedules;
create policy schedules_update_anon on public.schedules
for update to anon using (true) with check (true);

drop policy if exists schedules_delete_anon on public.schedules;
create policy schedules_delete_anon on public.schedules
for delete to anon using (true);

drop policy if exists calendars_select_anon on public.calendars;
create policy calendars_select_anon on public.calendars
for select to anon using (true);

drop policy if exists calendars_insert_anon on public.calendars;
create policy calendars_insert_anon on public.calendars
for insert to anon with check (true);

drop policy if exists calendars_update_anon on public.calendars;
create policy calendars_update_anon on public.calendars
for update to anon using (true) with check (true);

drop policy if exists calendars_delete_anon on public.calendars;
create policy calendars_delete_anon on public.calendars
for delete to anon using (true);

drop policy if exists activities_select_anon on public.activities;
create policy activities_select_anon on public.activities
for select to anon using (true);

drop policy if exists activities_insert_anon on public.activities;
create policy activities_insert_anon on public.activities
for insert to anon with check (true);

drop policy if exists activities_update_anon on public.activities;
create policy activities_update_anon on public.activities
for update to anon using (true) with check (true);

drop policy if exists activities_delete_anon on public.activities;
create policy activities_delete_anon on public.activities
for delete to anon using (true);

drop policy if exists photo_gallery_select_anon on public.photo_gallery;
create policy photo_gallery_select_anon on public.photo_gallery
for select to anon using (true);

drop policy if exists photo_gallery_insert_anon on public.photo_gallery;
create policy photo_gallery_insert_anon on public.photo_gallery
for insert to anon with check (true);

drop policy if exists photo_gallery_update_anon on public.photo_gallery;
create policy photo_gallery_update_anon on public.photo_gallery
for update to anon using (true) with check (true);

drop policy if exists photo_gallery_delete_anon on public.photo_gallery;
create policy photo_gallery_delete_anon on public.photo_gallery
for delete to anon using (true);

drop policy if exists photo_gallery_select_authenticated on public.photo_gallery;
create policy photo_gallery_select_authenticated on public.photo_gallery
for select to authenticated using (true);

drop policy if exists photo_gallery_insert_authenticated on public.photo_gallery;
create policy photo_gallery_insert_authenticated on public.photo_gallery
for insert to authenticated with check (true);

drop policy if exists photo_gallery_update_authenticated on public.photo_gallery;
create policy photo_gallery_update_authenticated on public.photo_gallery
for update to authenticated using (true) with check (true);

drop policy if exists photo_gallery_delete_authenticated on public.photo_gallery;
create policy photo_gallery_delete_authenticated on public.photo_gallery
for delete to authenticated using (true);

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

drop policy if exists student_resources_select_anon on public.student_resources;
create policy student_resources_select_anon on public.student_resources
for select to anon using (true);

drop policy if exists student_resources_insert_anon on public.student_resources;
create policy student_resources_insert_anon on public.student_resources
for insert to anon with check (true);

drop policy if exists student_resources_update_anon on public.student_resources;
create policy student_resources_update_anon on public.student_resources
for update to anon using (true) with check (true);

drop policy if exists student_resources_delete_anon on public.student_resources;
create policy student_resources_delete_anon on public.student_resources
for delete to anon using (true);

drop policy if exists students_select_anon on public.students;
create policy students_select_anon on public.students
for select to anon using (true);

drop policy if exists students_insert_anon on public.students;
create policy students_insert_anon on public.students
for insert to anon with check (true);

drop policy if exists students_update_anon on public.students;
create policy students_update_anon on public.students
for update to anon using (true) with check (true);

drop policy if exists students_delete_anon on public.students;
create policy students_delete_anon on public.students
for delete to anon using (true);

drop policy if exists students_select_authenticated on public.students;
create policy students_select_authenticated on public.students
for select to authenticated using (true);

drop policy if exists students_insert_authenticated on public.students;
create policy students_insert_authenticated on public.students
for insert to authenticated with check (true);

drop policy if exists students_update_authenticated on public.students;
create policy students_update_authenticated on public.students
for update to authenticated using (true) with check (true);

drop policy if exists student_honor_list_select_anon on public.student_honor_list_documents;
create policy student_honor_list_select_anon on public.student_honor_list_documents
for select to anon using (true);

drop policy if exists student_honor_list_insert_anon on public.student_honor_list_documents;
create policy student_honor_list_insert_anon on public.student_honor_list_documents
for insert to anon with check (true);

drop policy if exists student_honor_list_update_anon on public.student_honor_list_documents;
create policy student_honor_list_update_anon on public.student_honor_list_documents
for update to anon using (true) with check (true);

drop policy if exists student_honor_list_delete_anon on public.student_honor_list_documents;
create policy student_honor_list_delete_anon on public.student_honor_list_documents
for delete to anon using (true);

drop policy if exists student_honor_list_select_authenticated on public.student_honor_list_documents;
create policy student_honor_list_select_authenticated on public.student_honor_list_documents
for select to authenticated using (true);

drop policy if exists student_honor_list_insert_authenticated on public.student_honor_list_documents;
create policy student_honor_list_insert_authenticated on public.student_honor_list_documents
for insert to authenticated with check (true);

drop policy if exists student_honor_list_update_authenticated on public.student_honor_list_documents;
create policy student_honor_list_update_authenticated on public.student_honor_list_documents
for update to authenticated using (true) with check (true);

drop policy if exists student_honor_list_delete_authenticated on public.student_honor_list_documents;
create policy student_honor_list_delete_authenticated on public.student_honor_list_documents
for delete to authenticated using (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'honor-list-files',
  'honor-list-files',
  true,
  20971520,
  array['application/pdf']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists honor_list_files_public_read on storage.objects;
create policy honor_list_files_public_read on storage.objects
for select to public
using (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_anon_insert on storage.objects;
create policy honor_list_files_anon_insert on storage.objects
for insert to anon
with check (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_anon_update on storage.objects;
create policy honor_list_files_anon_update on storage.objects
for update to anon
using (bucket_id = 'honor-list-files')
with check (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_anon_delete on storage.objects;
create policy honor_list_files_anon_delete on storage.objects
for delete to anon
using (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_authenticated_read on storage.objects;
create policy honor_list_files_authenticated_read on storage.objects
for select to authenticated
using (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_authenticated_insert on storage.objects;
create policy honor_list_files_authenticated_insert on storage.objects
for insert to authenticated
with check (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_authenticated_update on storage.objects;
create policy honor_list_files_authenticated_update on storage.objects
for update to authenticated
using (bucket_id = 'honor-list-files')
with check (bucket_id = 'honor-list-files');

drop policy if exists honor_list_files_authenticated_delete on storage.objects;
create policy honor_list_files_authenticated_delete on storage.objects
for delete to authenticated
using (bucket_id = 'honor-list-files');

drop policy if exists students_delete_authenticated on public.students;
create policy students_delete_authenticated on public.students
for delete to authenticated using (true);

-- Storage buckets
insert into storage.buckets (id, name, public)
values
  ('staff-cv', 'staff-cv', true),
  ('staff-images', 'staff-images', true),
  ('news-images', 'news-images', true),
  ('event-images', 'event-images', true),
  ('study-plan-files', 'study-plan-files', true),
  ('schedule-files', 'schedule-files', true),
  ('calendar-files', 'calendar-files', true),
  ('activity-images', 'activity-images', true),
  ('gallery-images', 'gallery-images', true),
  ('resources-files', 'resources-files', true),
  ('facilities-images', 'facilities-images', true),
  ('home-images', 'home-images', true),
  ('home-files', 'home-files', true),
  ('important-links-images', 'important-links-images', true),
  ('admission-files', 'admission-files', true),
  ('international-handbook-files', 'international-handbook-files', true)
on conflict (id) do nothing;

update storage.buckets
set public = true
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
  'advisor-avatars'
);

drop policy if exists storage_project_files_select_anon on storage.objects;
create policy storage_project_files_select_anon
on storage.objects
for select to anon
using (
  bucket_id in (
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
    'advisor-avatars'
  )
);

drop policy if exists storage_project_files_select_authenticated on storage.objects;
create policy storage_project_files_select_authenticated
on storage.objects
for select to authenticated
using (
  bucket_id in (
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
    'advisor-avatars'
  )
);

drop policy if exists storage_facilities_images_insert_authenticated on storage.objects;
create policy storage_facilities_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'facilities-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 8 * 1024 * 1024
  and name ~ '^facilities/.+/.+'
);

drop policy if exists storage_facilities_images_select_authenticated on storage.objects;
create policy storage_facilities_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'facilities-images');

drop policy if exists storage_facilities_images_delete_authenticated on storage.objects;
create policy storage_facilities_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'facilities-images');

drop policy if exists storage_home_images_insert_authenticated on storage.objects;
create policy storage_home_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'home-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 8 * 1024 * 1024
  and name ~ '^home/.+/.+'
);

drop policy if exists storage_home_images_select_authenticated on storage.objects;
create policy storage_home_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'home-images');

drop policy if exists storage_home_images_delete_authenticated on storage.objects;
create policy storage_home_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'home-images');

drop policy if exists storage_home_files_insert_authenticated on storage.objects;
create policy storage_home_files_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'home-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 20 * 1024 * 1024
  and name ~ '^home/.+/.+'
);

drop policy if exists storage_home_files_select_authenticated on storage.objects;
create policy storage_home_files_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'home-files');

drop policy if exists storage_home_files_delete_authenticated on storage.objects;
create policy storage_home_files_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'home-files');

drop policy if exists storage_important_links_images_insert_authenticated on storage.objects;
create policy storage_important_links_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'important-links-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 8 * 1024 * 1024
  and name ~ '^important-links/.+/.+'
);

drop policy if exists storage_important_links_images_select_authenticated on storage.objects;
create policy storage_important_links_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'important-links-images');

drop policy if exists storage_important_links_images_delete_authenticated on storage.objects;
create policy storage_important_links_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'important-links-images');

drop policy if exists storage_admission_files_insert_authenticated on storage.objects;
create policy storage_admission_files_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'admission-files'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^admission/.+/.+'
);

drop policy if exists storage_admission_files_select_authenticated on storage.objects;
create policy storage_admission_files_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'admission-files');

drop policy if exists storage_admission_files_delete_authenticated on storage.objects;
create policy storage_admission_files_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'admission-files');

drop policy if exists storage_international_handbook_files_insert_authenticated on storage.objects;
create policy storage_international_handbook_files_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'international-handbook-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 20 * 1024 * 1024
  and name ~ '^international-handbook/.+/.+'
);

drop policy if exists storage_international_handbook_files_select_authenticated on storage.objects;
create policy storage_international_handbook_files_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'international-handbook-files');

drop policy if exists storage_international_handbook_files_delete_authenticated on storage.objects;
create policy storage_international_handbook_files_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'international-handbook-files');

-- Storage upload policies with server-side mime/size checks.
drop policy if exists storage_news_images_insert_anon on storage.objects;
create policy storage_news_images_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'news-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 5 * 1024 * 1024
  and name ~ '^news/.+/.+'
);

drop policy if exists storage_news_images_select_anon on storage.objects;
create policy storage_news_images_select_anon
on storage.objects
for select to anon
using (bucket_id = 'news-images');

drop policy if exists storage_news_images_delete_anon on storage.objects;
create policy storage_news_images_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'news-images');

drop policy if exists storage_event_images_insert_anon on storage.objects;
create policy storage_event_images_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'event-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 5 * 1024 * 1024
  and name ~ '^events/.+/.+'
);

drop policy if exists storage_event_images_select_anon on storage.objects;
create policy storage_event_images_select_anon
on storage.objects
for select to anon
using (bucket_id = 'event-images');

drop policy if exists storage_event_images_delete_anon on storage.objects;
create policy storage_event_images_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'event-images');

drop policy if exists storage_study_plan_insert_anon on storage.objects;
create policy storage_study_plan_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'study-plan-files'
  and (metadata->>'mimetype') in (
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  )
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^study-plans/.+/.+'
);

drop policy if exists storage_study_plan_select_anon on storage.objects;
create policy storage_study_plan_select_anon
on storage.objects
for select to anon
using (bucket_id = 'study-plan-files');

drop policy if exists storage_study_plan_delete_anon on storage.objects;
create policy storage_study_plan_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'study-plan-files');

drop policy if exists storage_schedule_files_insert_anon on storage.objects;
create policy storage_schedule_files_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'schedule-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^schedules/.+/.+'
);

drop policy if exists storage_schedule_files_select_anon on storage.objects;
create policy storage_schedule_files_select_anon
on storage.objects
for select to anon
using (bucket_id = 'schedule-files');

drop policy if exists storage_schedule_files_delete_anon on storage.objects;
create policy storage_schedule_files_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'schedule-files');

drop policy if exists storage_calendar_files_insert_anon on storage.objects;
create policy storage_calendar_files_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'calendar-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^calendars/.+/.+'
);

drop policy if exists storage_calendar_files_select_anon on storage.objects;
create policy storage_calendar_files_select_anon
on storage.objects
for select to anon
using (bucket_id = 'calendar-files');

drop policy if exists storage_calendar_files_delete_anon on storage.objects;
create policy storage_calendar_files_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'calendar-files');

drop policy if exists storage_activity_images_insert_anon on storage.objects;
create policy storage_activity_images_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'activity-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 5 * 1024 * 1024
  and name ~ '^activities/.+/.+'
);

drop policy if exists storage_activity_images_select_anon on storage.objects;
create policy storage_activity_images_select_anon
on storage.objects
for select to anon
using (bucket_id = 'activity-images');

drop policy if exists storage_activity_images_delete_anon on storage.objects;
create policy storage_activity_images_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'activity-images');

drop policy if exists storage_gallery_images_insert_anon on storage.objects;
create policy storage_gallery_images_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'gallery-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 8 * 1024 * 1024
  and name ~ '^gallery/.+/.+'
);

drop policy if exists storage_gallery_images_select_anon on storage.objects;
create policy storage_gallery_images_select_anon
on storage.objects
for select to anon
using (bucket_id = 'gallery-images');

drop policy if exists storage_gallery_images_delete_anon on storage.objects;
create policy storage_gallery_images_delete_anon
on storage.objects
for delete to anon
using (bucket_id = 'gallery-images');

drop policy if exists storage_gallery_images_insert_authenticated on storage.objects;
create policy storage_gallery_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'gallery-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 8 * 1024 * 1024
  and name ~ '^gallery/.+/.+'
);

drop policy if exists storage_gallery_images_select_authenticated on storage.objects;
create policy storage_gallery_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'gallery-images');

drop policy if exists storage_gallery_images_delete_authenticated on storage.objects;
create policy storage_gallery_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'gallery-images');

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

-- Advisor authentication + role management
create table if not exists public.advisor_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  username text,
  full_name text,
  avatar_url text,
  is_super_admin boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint advisor_profiles_email_not_blank check (length(trim(email)) > 0),
  constraint advisor_profiles_username_not_blank check (username is null or length(trim(username)) > 0)
);

alter table if exists public.advisor_profiles
add column if not exists username text;

with base_usernames as (
  select
    ap.id,
    lower(
      coalesce(
        nullif(trim(ap.username), ''),
        split_part(ap.email, '@', 1)
      )
    ) as base_username
  from public.advisor_profiles ap
),
ranked as (
  select
    bu.id,
    bu.base_username,
    row_number() over (partition by bu.base_username order by bu.id) as rn
  from base_usernames bu
)
update public.advisor_profiles ap
set username = case
  when ranked.rn = 1 then ranked.base_username
  else ranked.base_username || '_' || right(ap.id::text, 4)
end
from ranked
where ap.id = ranked.id
  and (ap.username is null or trim(ap.username) = '' or ap.username <> case
    when ranked.rn = 1 then ranked.base_username
    else ranked.base_username || '_' || right(ap.id::text, 4)
  end);

create unique index if not exists advisor_profiles_username_unique_idx
on public.advisor_profiles (lower(username))
where username is not null;

create table if not exists public.advisor_invites (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  invite_token text not null unique,
  is_super_admin boolean not null default false,
  status text not null default 'pending',
  invited_by uuid references auth.users(id) on delete set null,
  accepted_user_id uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint advisor_invites_email_not_blank check (length(trim(email)) > 0),
  constraint advisor_invites_status_valid check (status in ('pending', 'accepted', 'revoked', 'expired'))
);

drop trigger if exists trg_advisor_profiles_set_updated_at on public.advisor_profiles;
create trigger trg_advisor_profiles_set_updated_at
before update on public.advisor_profiles
for each row
execute function public.set_updated_at_column();

drop trigger if exists trg_advisor_invites_set_updated_at on public.advisor_invites;
create trigger trg_advisor_invites_set_updated_at
before update on public.advisor_invites
for each row
execute function public.set_updated_at_column();

create or replace function public.is_super_admin(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.advisor_profiles ap
    where ap.id = p_user_id
      and ap.is_super_admin = true
      and ap.is_active = true
  );
$$;

create or replace function public.create_advisor_invite(p_email text, p_is_super_admin boolean)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  token text;
  normalized_email text;
begin
  if not public.is_super_admin(auth.uid()) then
    raise exception 'Only super admins can create invites';
  end if;

  normalized_email := lower(trim(p_email));
  if normalized_email = '' then
    raise exception 'Email is required';
  end if;

  token := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');

  insert into public.advisor_invites (
    email,
    invite_token,
    is_super_admin,
    status,
    invited_by,
    expires_at,
    created_at,
    updated_at
  )
  values (
    normalized_email,
    token,
    coalesce(p_is_super_admin, false),
    'pending',
    auth.uid(),
    now() + interval '7 days',
    now(),
    now()
  )
  on conflict (email) do update
  set
    invite_token = excluded.invite_token,
    is_super_admin = excluded.is_super_admin,
    status = 'pending',
    invited_by = excluded.invited_by,
    accepted_user_id = null,
    accepted_at = null,
    expires_at = excluded.expires_at,
    updated_at = now();

  return token;
end;
$$;

create or replace function public.get_advisor_invite_by_token(p_token text)
returns table (
  email text,
  is_super_admin boolean,
  expires_at timestamptz,
  status text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    ai.email,
    ai.is_super_admin,
    ai.expires_at,
    ai.status
  from public.advisor_invites ai
  where ai.invite_token = p_token
    and ai.status = 'pending'
    and ai.expires_at > now();
$$;

create or replace function public.handle_new_advisor_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  invite_record public.advisor_invites%rowtype;
  display_name text;
  login_name text;
  should_activate boolean := false;
  should_be_super_admin boolean := false;
begin
  select * into invite_record
  from public.advisor_invites ai
  where ai.email = lower(new.email)
    and ai.status = 'pending'
    and ai.expires_at > now()
  order by ai.created_at desc
  limit 1;

  if found then
    should_activate := true;
    should_be_super_admin := invite_record.is_super_admin;

    update public.advisor_invites
    set
      status = 'accepted',
      accepted_user_id = new.id,
      accepted_at = now(),
      updated_at = now()
    where id = invite_record.id;
  end if;

  if lower(new.email) = 'sudo@must.edu.eg' then
    should_activate := true;
    should_be_super_admin := true;
  end if;

  display_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    split_part(new.email, '@', 1)
  );

  login_name := lower(
    coalesce(
      nullif(new.raw_user_meta_data ->> 'username', ''),
      split_part(new.email, '@', 1)
    )
  );

  insert into public.advisor_profiles (
    id,
    email,
    username,
    full_name,
    avatar_url,
    is_super_admin,
    is_active,
    created_at,
    updated_at
  )
  values (
    new.id,
    lower(new.email),
    login_name,
    display_name,
    nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
    should_be_super_admin,
    should_activate,
    now(),
    now()
  )
  on conflict (id) do update
  set
    email = excluded.email,
    username = coalesce(advisor_profiles.username, excluded.username),
    full_name = coalesce(excluded.full_name, advisor_profiles.full_name),
    is_super_admin = advisor_profiles.is_super_admin or excluded.is_super_admin,
    is_active = advisor_profiles.is_active or excluded.is_active,
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists trg_handle_new_advisor_user on auth.users;
create trigger trg_handle_new_advisor_user
after insert on auth.users
for each row
execute function public.handle_new_advisor_user();

create or replace function public.revoke_advisor_access(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_super_admin(auth.uid()) then
    raise exception 'Only super admins can revoke access';
  end if;

  if exists (
    select 1 from public.advisor_profiles ap
    where ap.id = p_user_id
      and ap.is_super_admin = true
  ) then
    raise exception 'Super admins cannot revoke other super admins';
  end if;

  update public.advisor_profiles
  set
    is_active = false,
    updated_at = now()
  where id = p_user_id;
end;
$$;

create or replace function public.delete_advisor_account(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_super_admin(auth.uid()) then
    raise exception 'Only super admins can delete advisors';
  end if;

  if exists (
    select 1 from public.advisor_profiles ap
    where ap.id = p_user_id
      and ap.is_super_admin = true
  ) then
    raise exception 'Super admins cannot delete other super admins';
  end if;

  delete from auth.users where id = p_user_id;
end;
$$;

grant execute on function public.create_advisor_invite(text, boolean) to authenticated;
grant execute on function public.get_advisor_invite_by_token(text) to anon, authenticated;
grant execute on function public.revoke_advisor_access(uuid) to authenticated;
grant execute on function public.delete_advisor_account(uuid) to authenticated;
grant execute on function public.is_super_admin(uuid) to authenticated;

alter table public.advisor_profiles enable row level security;
alter table public.advisor_invites enable row level security;

drop policy if exists advisor_profiles_select_anon on public.advisor_profiles;
create policy advisor_profiles_select_anon on public.advisor_profiles
for select to anon
using (true);

drop policy if exists advisor_profiles_select_self on public.advisor_profiles;
create policy advisor_profiles_select_self on public.advisor_profiles
for select to authenticated
using (id = auth.uid());

drop policy if exists advisor_profiles_select_super_admin on public.advisor_profiles;
create policy advisor_profiles_select_super_admin on public.advisor_profiles
for select to authenticated
using (public.is_super_admin(auth.uid()));

drop policy if exists advisor_profiles_update_self on public.advisor_profiles;
create policy advisor_profiles_update_self on public.advisor_profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists advisor_profiles_update_super_admin on public.advisor_profiles;
create policy advisor_profiles_update_super_admin on public.advisor_profiles
for update to authenticated
using (
  public.is_super_admin(auth.uid())
  and (is_super_admin = false or id = auth.uid())
)
with check (
  public.is_super_admin(auth.uid())
  and (is_super_admin = false or id = auth.uid())
);

drop policy if exists advisor_profiles_delete_super_admin on public.advisor_profiles;
create policy advisor_profiles_delete_super_admin on public.advisor_profiles
for delete to authenticated
using (
  public.is_super_admin(auth.uid())
  and is_super_admin = false
);

drop policy if exists advisor_invites_select_super_admin on public.advisor_invites;
create policy advisor_invites_select_super_admin on public.advisor_invites
for select to authenticated
using (public.is_super_admin(auth.uid()));

drop policy if exists advisor_invites_insert_super_admin on public.advisor_invites;
create policy advisor_invites_insert_super_admin on public.advisor_invites
for insert to authenticated
with check (public.is_super_admin(auth.uid()));

drop policy if exists advisor_invites_update_super_admin on public.advisor_invites;
create policy advisor_invites_update_super_admin on public.advisor_invites
for update to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

drop policy if exists advisor_invites_delete_super_admin on public.advisor_invites;
create policy advisor_invites_delete_super_admin on public.advisor_invites
for delete to authenticated
using (public.is_super_admin(auth.uid()));

insert into storage.buckets (id, name, public)
values ('advisor-avatars', 'advisor-avatars', true)
on conflict (id) do nothing;

drop policy if exists storage_advisor_avatars_insert_auth on storage.objects;
create policy storage_advisor_avatars_insert_auth
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'advisor-avatars'
  and (
    name like (auth.uid()::text || '/%')
    or public.is_super_admin(auth.uid())
  )
);

drop policy if exists storage_advisor_avatars_update_auth on storage.objects;
create policy storage_advisor_avatars_update_auth
on storage.objects
for update to authenticated
using (
  bucket_id = 'advisor-avatars'
  and (
    name like (auth.uid()::text || '/%')
    or public.is_super_admin(auth.uid())
  )
)
with check (
  bucket_id = 'advisor-avatars'
  and (
    name like (auth.uid()::text || '/%')
    or public.is_super_admin(auth.uid())
  )
);

drop policy if exists storage_advisor_avatars_delete_auth on storage.objects;
create policy storage_advisor_avatars_delete_auth
on storage.objects
for delete to authenticated
using (
  bucket_id = 'advisor-avatars'
  and (
    name like (auth.uid()::text || '/%')
    or public.is_super_admin(auth.uid())
  )
);

drop policy if exists storage_advisor_avatars_select_anon on storage.objects;
create policy storage_advisor_avatars_select_anon
on storage.objects
for select to anon
using (bucket_id = 'advisor-avatars');

-- Advisor <-> Student messaging
create table if not exists public.advisor_student_conversations (
  id uuid primary key default gen_random_uuid(),
  advisor_id uuid not null references auth.users(id) on delete cascade,
  student_id text references public.students(student_id) on delete set null,
  student_email text not null,
  student_full_name text,
  status text not null default 'open',
  last_message_text text,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint advisor_student_conversations_student_email_not_blank check (length(trim(student_email)) > 0),
  constraint advisor_student_conversations_status_valid check (status in ('open', 'closed')),
  constraint advisor_student_conversations_unique_advisor_student unique (advisor_id, student_email)
);

create table if not exists public.conversation_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.advisor_student_conversations(id) on delete cascade,
  sender_role text not null,
  sender_id uuid,
  message_text text not null,
  created_at timestamptz not null default now(),
  constraint conversation_messages_sender_role_valid check (sender_role in ('advisor', 'student', 'system')),
  constraint conversation_messages_text_not_blank check (length(trim(message_text)) > 0)
);

create index if not exists idx_advisor_student_conversations_advisor_id
  on public.advisor_student_conversations (advisor_id, updated_at desc);

create index if not exists idx_conversation_messages_conversation_id
  on public.conversation_messages (conversation_id, created_at asc);

drop trigger if exists trg_advisor_student_conversations_set_updated_at on public.advisor_student_conversations;
create trigger trg_advisor_student_conversations_set_updated_at
before update on public.advisor_student_conversations
for each row
execute function public.set_updated_at_column();

alter table public.advisor_student_conversations enable row level security;
alter table public.conversation_messages enable row level security;

drop policy if exists advisor_student_conversations_select_owner on public.advisor_student_conversations;
create policy advisor_student_conversations_select_owner on public.advisor_student_conversations
for select to authenticated
using (advisor_id = auth.uid());

drop policy if exists advisor_student_conversations_select_anon on public.advisor_student_conversations;
create policy advisor_student_conversations_select_anon on public.advisor_student_conversations
for select to anon
using (true);

drop policy if exists advisor_student_conversations_insert_owner on public.advisor_student_conversations;
create policy advisor_student_conversations_insert_owner on public.advisor_student_conversations
for insert to authenticated
with check (advisor_id = auth.uid());

drop policy if exists advisor_student_conversations_update_owner on public.advisor_student_conversations;
create policy advisor_student_conversations_update_owner on public.advisor_student_conversations
for update to authenticated
using (advisor_id = auth.uid())
with check (advisor_id = auth.uid());

drop policy if exists advisor_student_conversations_delete_owner on public.advisor_student_conversations;
create policy advisor_student_conversations_delete_owner on public.advisor_student_conversations
for delete to authenticated
using (advisor_id = auth.uid());

drop policy if exists conversation_messages_select_owner on public.conversation_messages;
create policy conversation_messages_select_owner on public.conversation_messages
for select to authenticated
using (
  exists (
    select 1
    from public.advisor_student_conversations c
    where c.id = conversation_messages.conversation_id
      and c.advisor_id = auth.uid()
  )
);

drop policy if exists conversation_messages_select_anon on public.conversation_messages;
create policy conversation_messages_select_anon on public.conversation_messages
for select to anon
using (true);

drop policy if exists conversation_messages_insert_owner on public.conversation_messages;
create policy conversation_messages_insert_owner on public.conversation_messages
for insert to authenticated
with check (
  sender_role = 'advisor'
  and sender_id = auth.uid()
  and exists (
    select 1
    from public.advisor_student_conversations c
    where c.id = conversation_messages.conversation_id
      and c.advisor_id = auth.uid()
      and c.status = 'open'
  )
);

-- Dashboard authenticated access policies
-- These allow logged-in advisors to manage dashboard content without RLS upload/read failures.

drop policy if exists news_select_authenticated on public.news;
create policy news_select_authenticated on public.news
for select to authenticated using (true);

drop policy if exists news_insert_authenticated on public.news;
create policy news_insert_authenticated on public.news
for insert to authenticated with check (true);

drop policy if exists news_update_authenticated on public.news;
create policy news_update_authenticated on public.news
for update to authenticated using (true) with check (true);

drop policy if exists news_delete_authenticated on public.news;
create policy news_delete_authenticated on public.news
for delete to authenticated using (true);

drop policy if exists events_select_authenticated on public.events;
create policy events_select_authenticated on public.events
for select to authenticated using (true);

drop policy if exists events_insert_authenticated on public.events;
create policy events_insert_authenticated on public.events
for insert to authenticated with check (true);

drop policy if exists events_update_authenticated on public.events;
create policy events_update_authenticated on public.events
for update to authenticated using (true) with check (true);

drop policy if exists events_delete_authenticated on public.events;
create policy events_delete_authenticated on public.events
for delete to authenticated using (true);

drop policy if exists study_plans_select_authenticated on public.study_plans;
create policy study_plans_select_authenticated on public.study_plans
for select to authenticated using (true);

drop policy if exists study_plans_insert_authenticated on public.study_plans;
create policy study_plans_insert_authenticated on public.study_plans
for insert to authenticated with check (true);

drop policy if exists study_plans_update_authenticated on public.study_plans;
create policy study_plans_update_authenticated on public.study_plans
for update to authenticated using (true) with check (true);

drop policy if exists study_plans_delete_authenticated on public.study_plans;
create policy study_plans_delete_authenticated on public.study_plans
for delete to authenticated using (true);

drop policy if exists schedules_select_authenticated on public.schedules;
create policy schedules_select_authenticated on public.schedules
for select to authenticated using (true);

drop policy if exists schedules_insert_authenticated on public.schedules;
create policy schedules_insert_authenticated on public.schedules
for insert to authenticated with check (true);

drop policy if exists schedules_update_authenticated on public.schedules;
create policy schedules_update_authenticated on public.schedules
for update to authenticated using (true) with check (true);

drop policy if exists schedules_delete_authenticated on public.schedules;
create policy schedules_delete_authenticated on public.schedules
for delete to authenticated using (true);

drop policy if exists calendars_select_authenticated on public.calendars;
create policy calendars_select_authenticated on public.calendars
for select to authenticated using (true);

drop policy if exists calendars_insert_authenticated on public.calendars;
create policy calendars_insert_authenticated on public.calendars
for insert to authenticated with check (true);

drop policy if exists calendars_update_authenticated on public.calendars;
create policy calendars_update_authenticated on public.calendars
for update to authenticated using (true) with check (true);

drop policy if exists calendars_delete_authenticated on public.calendars;
create policy calendars_delete_authenticated on public.calendars
for delete to authenticated using (true);

drop policy if exists activities_select_authenticated on public.activities;
create policy activities_select_authenticated on public.activities
for select to authenticated using (true);

drop policy if exists activities_insert_authenticated on public.activities;
create policy activities_insert_authenticated on public.activities
for insert to authenticated with check (true);

drop policy if exists activities_update_authenticated on public.activities;
create policy activities_update_authenticated on public.activities
for update to authenticated using (true) with check (true);

drop policy if exists activities_delete_authenticated on public.activities;
create policy activities_delete_authenticated on public.activities
for delete to authenticated using (true);

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

drop policy if exists student_resources_select_authenticated on public.student_resources;
create policy student_resources_select_authenticated on public.student_resources
for select to authenticated using (true);

drop policy if exists student_resources_insert_authenticated on public.student_resources;
create policy student_resources_insert_authenticated on public.student_resources
for insert to authenticated with check (true);

drop policy if exists student_resources_update_authenticated on public.student_resources;
create policy student_resources_update_authenticated on public.student_resources
for update to authenticated using (true) with check (true);

drop policy if exists student_resources_delete_authenticated on public.student_resources;
create policy student_resources_delete_authenticated on public.student_resources
for delete to authenticated using (true);

drop policy if exists photo_gallery_select_authenticated on public.photo_gallery;
create policy photo_gallery_select_authenticated on public.photo_gallery
for select to authenticated using (true);

drop policy if exists photo_gallery_insert_authenticated on public.photo_gallery;
create policy photo_gallery_insert_authenticated on public.photo_gallery
for insert to authenticated with check (true);

drop policy if exists photo_gallery_update_authenticated on public.photo_gallery;
create policy photo_gallery_update_authenticated on public.photo_gallery
for update to authenticated using (true) with check (true);

drop policy if exists photo_gallery_delete_authenticated on public.photo_gallery;
create policy photo_gallery_delete_authenticated on public.photo_gallery
for delete to authenticated using (true);

drop policy if exists students_select_authenticated on public.students;
create policy students_select_authenticated on public.students
for select to authenticated using (true);

drop policy if exists students_insert_authenticated on public.students;
create policy students_insert_authenticated on public.students
for insert to authenticated with check (true);

drop policy if exists students_update_authenticated on public.students;
create policy students_update_authenticated on public.students
for update to authenticated using (true) with check (true);

drop policy if exists students_delete_authenticated on public.students;
create policy students_delete_authenticated on public.students
for delete to authenticated using (true);

drop policy if exists storage_news_images_insert_authenticated on storage.objects;
create policy storage_news_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'news-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 5 * 1024 * 1024
  and name ~ '^news/.+/.+'
);

drop policy if exists storage_news_images_select_authenticated on storage.objects;
create policy storage_news_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'news-images');

drop policy if exists storage_news_images_delete_authenticated on storage.objects;
create policy storage_news_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'news-images');

drop policy if exists storage_event_images_insert_authenticated on storage.objects;
create policy storage_event_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'event-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 5 * 1024 * 1024
  and name ~ '^events/.+/.+'
);

drop policy if exists storage_event_images_select_authenticated on storage.objects;
create policy storage_event_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'event-images');

drop policy if exists storage_event_images_delete_authenticated on storage.objects;
create policy storage_event_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'event-images');

drop policy if exists storage_study_plan_insert_authenticated on storage.objects;
create policy storage_study_plan_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'study-plan-files'
  and (metadata->>'mimetype') in (
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  )
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^study-plans/.+/.+'
);

drop policy if exists storage_study_plan_select_authenticated on storage.objects;
create policy storage_study_plan_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'study-plan-files');

drop policy if exists storage_study_plan_delete_authenticated on storage.objects;
create policy storage_study_plan_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'study-plan-files');

drop policy if exists storage_schedule_files_insert_authenticated on storage.objects;
create policy storage_schedule_files_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'schedule-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^schedules/.+/.+'
);

drop policy if exists storage_schedule_files_select_authenticated on storage.objects;
create policy storage_schedule_files_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'schedule-files');

drop policy if exists storage_schedule_files_delete_authenticated on storage.objects;
create policy storage_schedule_files_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'schedule-files');

drop policy if exists storage_calendar_files_insert_authenticated on storage.objects;
create policy storage_calendar_files_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'calendar-files'
  and (metadata->>'mimetype') in ('application/pdf')
  and coalesce((metadata->>'size')::bigint, 0) <= 10 * 1024 * 1024
  and name ~ '^calendars/.+/.+'
);

drop policy if exists storage_calendar_files_select_authenticated on storage.objects;
create policy storage_calendar_files_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'calendar-files');

drop policy if exists storage_calendar_files_delete_authenticated on storage.objects;
create policy storage_calendar_files_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'calendar-files');

drop policy if exists storage_activity_images_insert_authenticated on storage.objects;
create policy storage_activity_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'activity-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 5 * 1024 * 1024
  and name ~ '^activities/.+/.+'
);

drop policy if exists storage_activity_images_select_authenticated on storage.objects;
create policy storage_activity_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'activity-images');

drop policy if exists storage_activity_images_delete_authenticated on storage.objects;
create policy storage_activity_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'activity-images');

drop policy if exists storage_gallery_images_insert_authenticated on storage.objects;
create policy storage_gallery_images_insert_authenticated
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'gallery-images'
  and (metadata->>'mimetype') in ('image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 8 * 1024 * 1024
  and name ~ '^gallery/.+/.+'
);

drop policy if exists storage_gallery_images_select_authenticated on storage.objects;
create policy storage_gallery_images_select_authenticated
on storage.objects
for select to authenticated
using (bucket_id = 'gallery-images');

drop policy if exists storage_gallery_images_delete_authenticated on storage.objects;
create policy storage_gallery_images_delete_authenticated
on storage.objects
for delete to authenticated
using (bucket_id = 'gallery-images');

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

drop policy if exists storage_announcements_insert_anon on storage.objects;
create policy storage_announcements_insert_anon
on storage.objects
for insert to anon
with check (
  bucket_id = 'resources-files'
  and (metadata->>'mimetype') in ('application/pdf', 'image/jpeg', 'image/png', 'image/webp')
  and coalesce((metadata->>'size')::bigint, 0) <= 25 * 1024 * 1024
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
  and coalesce((metadata->>'size')::bigint, 0) <= 25 * 1024 * 1024
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

create table if not exists public.academic_advising (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  file_path text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
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
  and coalesce((metadata->>'size')::bigint, 0) <= 25 * 1024 * 1024
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
  and coalesce((metadata->>'size')::bigint, 0) <= 25 * 1024 * 1024
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
