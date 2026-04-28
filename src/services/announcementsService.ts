import {
  supabase,
  supabaseAnnouncementsTable,
  supabaseResourcesFilesBucket
} from '../lib/supabase';
import {
  deleteStorageFileSafely,
  getPublicFileUrl,
  parseStorageTarget,
  uploadFileToStorage,
  validateFile
} from './storageUtils';

const ANNOUNCEMENT_IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const ANNOUNCEMENT_PDF_MIME_TYPES = ['application/pdf'];

export interface AnnouncementRecord {
  id: string;
  title: string;
  description: string;
  announcement_date: string;
  main_image_path: string | null;
  attachment_image_paths: string[] | null;
  pdf_path: string | null;
  created_at: string;
  updated_at: string;
}

export interface AnnouncementInput {
  title: string;
  description: string;
  announcementDate: string;
}

export interface AnnouncementViewModel extends AnnouncementRecord {
  mainImageUrl: string | null;
  attachmentImageUrls: string[];
  pdfUrl: string | null;
}

function isMissingAnnouncementsTable(error: { code?: string; message?: string }): boolean {
  return error.code === 'PGRST205' || error.code === '42P01' || /announcements/i.test(error.message ?? '');
}

function validateAnnouncementImage(file: File, label: string): void {
  validateFile(file, {
    maxSizeInMb: 8,
    allowedMimeTypes: ANNOUNCEMENT_IMAGE_MIME_TYPES,
    label
  });
}

function validateAnnouncementPdf(file: File): void {
  validateFile(file, {
    maxSizeInMb: 25,
    allowedMimeTypes: ANNOUNCEMENT_PDF_MIME_TYPES,
    label: 'Announcement PDF'
  });
}

function assertInput(input: AnnouncementInput): void {
  if (!input.title.trim()) {
    throw new Error('Title is required.');
  }

  if (!input.description.trim()) {
    throw new Error('Description is required.');
  }

  if (!input.announcementDate) {
    throw new Error('Announcement date is required.');
  }
}

function toViewModel(record: AnnouncementRecord): AnnouncementViewModel {
  return {
    ...record,
    mainImageUrl: getPublicFileUrl(supabaseResourcesFilesBucket, record.main_image_path),
    attachmentImageUrls: (record.attachment_image_paths ?? [])
      .map((path) => getPublicFileUrl(supabaseResourcesFilesBucket, path))
      .filter((value): value is string => Boolean(value)),
    pdfUrl: getPublicFileUrl(supabaseResourcesFilesBucket, record.pdf_path)
  };
}

export async function listAnnouncements(): Promise<AnnouncementViewModel[]> {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  const { data, error } = await supabase
    .from(supabaseAnnouncementsTable)
    .select('*')
    .order('announcement_date', { ascending: false })
    .order('created_at', { ascending: false });

  if (error) {
    if (isMissingAnnouncementsTable(error)) {
      return [];
    }

    throw new Error(`Failed to load announcements: ${error.message}`);
  }

  return ((data ?? []) as AnnouncementRecord[]).map(toViewModel);
}

export async function createAnnouncement(
  input: AnnouncementInput,
  options: {
    mainPhotoFile?: File | null;
    pdfFile?: File | null;
    attachmentFiles?: File[];
  }
): Promise<void> {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  assertInput(input);

  const id = crypto.randomUUID();
  const target = parseStorageTarget(supabaseResourcesFilesBucket, 'announcements');

  let mainImagePath: string | null = null;
  let pdfPath: string | null = null;
  const attachmentImagePaths: string[] = [];

  if (options.mainPhotoFile) {
    validateAnnouncementImage(options.mainPhotoFile, 'Announcement photo');
    mainImagePath = await uploadFileToStorage(options.mainPhotoFile, target, id, 'main-image');
  }

  if (options.pdfFile) {
    validateAnnouncementPdf(options.pdfFile);
    pdfPath = await uploadFileToStorage(options.pdfFile, target, id, 'pdf');
  }

  for (const [index, file] of (options.attachmentFiles ?? []).entries()) {
    validateAnnouncementImage(file, `Announcement gallery image ${index + 1}`);
    const filePath = await uploadFileToStorage(file, target, id, `attachment-${index + 1}`);
    attachmentImagePaths.push(filePath);
  }

  const { error } = await supabase.from(supabaseAnnouncementsTable).insert({
    id,
    title: input.title.trim(),
    description: input.description.trim(),
    announcement_date: input.announcementDate,
    main_image_path: mainImagePath,
    attachment_image_paths: attachmentImagePaths,
    pdf_path: pdfPath
  });

  if (error) {
    await Promise.all([
      deleteStorageFileSafely(target.bucket, mainImagePath),
      deleteStorageFileSafely(target.bucket, pdfPath),
      ...attachmentImagePaths.map((path) => deleteStorageFileSafely(target.bucket, path))
    ]);

    if (isMissingAnnouncementsTable(error)) {
      throw new Error('Announcements backend is not initialized yet. Run the SQL setup script first.');
    }

    throw new Error(`Failed to create announcement: ${error.message}`);
  }
}
