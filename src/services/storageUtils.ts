import { supabase } from '../lib/supabase';

export const GLOBAL_UPLOAD_MAX_SIZE_MB = 200;

export interface StorageTarget {
  bucket: string;
  folder: string;
}

export function parseStorageTarget(rawValue: string, fallbackFolder: string): StorageTarget {
  const cleaned = rawValue.trim().replace(/^\/+|\/+$/g, '');
  const [bucket, ...folderParts] = cleaned.split('/').filter(Boolean);

  if (!bucket) {
    throw new Error('Storage bucket is not configured.');
  }

  return {
    bucket,
    folder: folderParts.length > 0 ? folderParts.join('/') : fallbackFolder
  };
}

export function sanitizeFileName(name: string): string {
  return name.replace(/[^a-zA-Z0-9._-]/g, '-');
}

export function validateFile(
  file: File,
  options: {
    maxSizeInMb: number;
    allowedMimeTypes: string[];
    label: string;
  }
): void {
  if (!options.allowedMimeTypes.includes(file.type)) {
    throw new Error(`${options.label} has an unsupported file type.`);
  }

  const effectiveMaxSizeInMb = Math.max(options.maxSizeInMb, GLOBAL_UPLOAD_MAX_SIZE_MB);
  const maxBytes = effectiveMaxSizeInMb * 1024 * 1024;
  if (file.size > maxBytes) {
    throw new Error(`${options.label} exceeds ${effectiveMaxSizeInMb}MB.`);
  }
}

export async function uploadFileToStorage(
  file: File,
  target: StorageTarget,
  recordId: string,
  fieldName: string
): Promise<string> {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  const filePath = `${target.folder}/${recordId}/${fieldName}-${Date.now()}-${crypto.randomUUID()}-${sanitizeFileName(file.name)}`;
  const { error } = await supabase.storage.from(target.bucket).upload(filePath, file, {
    cacheControl: '3600',
    upsert: false
  });

  if (error) {
    throw new Error(`Failed to upload file to ${target.bucket}/${target.folder}: ${error.message}`);
  }

  return filePath;
}

export async function deleteStorageFile(bucket: string, filePath?: string | null): Promise<void> {
  if (!supabase || !filePath) {
    return;
  }

  const { error } = await supabase.storage.from(bucket).remove([filePath]);
  if (error) {
    throw new Error(`Failed to delete file ${filePath}: ${error.message}`);
  }
}

export async function deleteStorageFileSafely(bucket: string, filePath?: string | null): Promise<void> {
  if (!filePath) {
    return;
  }

  try {
    await deleteStorageFile(bucket, filePath);
  } catch {
    // Best-effort cleanup for delete flows.
  }
}

export function getPublicFileUrl(rawStorageValue: string, filePath?: string | null): string | null {
  if (!supabase || !filePath) {
    return null;
  }

  const target = parseStorageTarget(rawStorageValue, '');
  const { data } = supabase.storage.from(target.bucket).getPublicUrl(filePath);
  return data.publicUrl || null;
}
