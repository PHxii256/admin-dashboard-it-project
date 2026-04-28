import {
  supabase,
  supabaseResourcesFilesBucket,
  supabaseSmartELearningTable
} from '../lib/supabase';
import {
  deleteStorageFileSafely,
  parseStorageTarget,
  uploadFileToStorage,
  validateFile
} from './storageUtils';

export const smartELearningSourceTypes = ['video', 'link', 'file'] as const;
export type SmartELearningSourceType = (typeof smartELearningSourceTypes)[number];
export type SmartELearningStoredSourceType = SmartELearningSourceType | 'youtube' | 'upload';

export interface SmartELearningRecord {
  id: string;
  title: string;
  source_type: SmartELearningStoredSourceType;
  youtube_url: string | null;
  video_path: string | null;
  created_at: string;
  updated_at: string;
}

export interface SmartELearningInput {
  title: string;
  sourceType: SmartELearningSourceType;
  sourceUrl: string;
}

const VIDEO_FILE_MIME_TYPES = ['video/mp4', 'video/webm', 'video/quicktime'];
const DOCUMENT_FILE_MIME_TYPES = ['application/pdf'];

function assertInput(input: SmartELearningInput): void {
  if (!input.title.trim()) {
    throw new Error('Title is required.');
  }

  if (!smartELearningSourceTypes.includes(input.sourceType)) {
    throw new Error('Please select a valid source type.');
  }

  if (input.sourceType === 'link' && !/^https?:\/\//i.test(input.sourceUrl.trim())) {
    throw new Error('Please enter a valid source link.');
  }
}

function validateVideoFile(file: File): void {
  validateFile(file, {
    maxSizeInMb: 150,
    allowedMimeTypes: VIDEO_FILE_MIME_TYPES,
    label: 'Smart E-Learning video file'
  });
}

function validateDocumentFile(file: File): void {
  validateFile(file, {
    maxSizeInMb: 150,
    allowedMimeTypes: DOCUMENT_FILE_MIME_TYPES,
    label: 'Smart E-Learning document file'
  });
}

function isMissingTable(error: { code?: string; message?: string }): boolean {
  return error.code === 'PGRST205' || error.code === '42P01' || /smart_elearning_videos/i.test(error.message ?? '');
}

async function uploadSource(file: File, recordId: string): Promise<string> {
  const target = parseStorageTarget(supabaseResourcesFilesBucket, 'smart-elearning');
  return uploadFileToStorage(file, target, recordId, 'source');
}

export async function listSmartELearningVideos(): Promise<SmartELearningRecord[]> {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  const { data, error } = await supabase
    .from(supabaseSmartELearningTable)
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    if (isMissingTable(error)) {
      return [];
    }
    throw new Error(`Failed to load smart e-learning videos: ${error.message}`);
  }

  return (data ?? []) as SmartELearningRecord[];
}

export async function createSmartELearningVideo(input: SmartELearningInput, sourceFile?: File | null): Promise<void> {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  assertInput(input);

  const id = crypto.randomUUID();
  let videoPath: string | null = null;
  let sourceUrl: string | null = null;

  if (input.sourceType === 'video') {
    if (!sourceFile) {
      throw new Error('Please upload a video file.');
    }
    validateVideoFile(sourceFile);
    videoPath = await uploadSource(sourceFile, id);
  } else if (input.sourceType === 'file') {
    if (!sourceFile) {
      throw new Error('Please upload a file.');
    }
    validateDocumentFile(sourceFile);
    videoPath = await uploadSource(sourceFile, id);
  } else {
    sourceUrl = input.sourceUrl.trim();
  }

  const now = new Date().toISOString();
  const { error } = await supabase.from(supabaseSmartELearningTable).insert({
    id,
    title: input.title.trim(),
    source_type: input.sourceType,
    youtube_url: sourceUrl,
    video_path: videoPath,
    created_at: now,
    updated_at: now
  });

  if (error) {
    if (isMissingTable(error)) {
      throw new Error(
        'Smart E-Learning backend is not initialized yet. Run supabase/add_smart_elearning.sql first. If the table already exists but uploads still fail, run supabase/fix_smart_elearning_backend_mismatch.sql.'
      );
    }
    throw new Error(`Failed to create smart e-learning video: ${error.message}`);
  }
}

export async function deleteSmartELearningVideo(record: SmartELearningRecord): Promise<void> {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  if (record.video_path) {
    const target = parseStorageTarget(supabaseResourcesFilesBucket, 'smart-elearning');
    await deleteStorageFileSafely(target.bucket, record.video_path);
  }

  const { error } = await supabase
    .from(supabaseSmartELearningTable)
    .delete()
    .eq('id', record.id);

  if (error) {
    throw new Error(`Failed to delete smart e-learning video: ${error.message}`);
  }
}
