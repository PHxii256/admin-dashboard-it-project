import { useEffect, useMemo, useRef, useState } from 'react';
import {
  DownloadIcon,
  FileTextIcon,
  GraduationCapIcon,
  LinkIcon,
  PlayCircleIcon,
  Trash2Icon,
  ImageIcon
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '../components/ui/Card';
import { Input } from '../components/ui/Input';
import { Button } from '../components/ui/Button';
import { ConfirmModal } from '../components/ui/ConfirmModal';
import { Pagination } from '../components/ui/Pagination';
import {
  createAdvisorResource,
  deleteAdvisorResource,
  listAdvisorResources,
  type AdvisorResourceInput,
  type AdvisorResourceRecord
} from '../services/advisorResourcesService';
import { getPublicFileUrl } from '../services/storageUtils';
import { supabaseResourcesFilesBucket } from '../lib/supabase';

const SECTIONS = [
  { id: 'academic_advising', label: 'Academic advising' },
  { id: 'registration', label: 'Registration' },
  { id: 'schedules', label: 'Schedules' }
] as const;

type SectionId = (typeof SECTIONS)[number]['id'];

type SectionDraft = {
  photoFile: File | null;
  pdfFile: File | null;
  videoUrl: string;
  linkUrl: string;
  sourceOfLink: string;
};

function emptyDraft(): SectionDraft {
  return {
    photoFile: null,
    pdfFile: null,
    videoUrl: '',
    linkUrl: '',
    sourceOfLink: ''
  };
}

function initialDrafts(): Record<SectionId, SectionDraft> {
  return {
    academic_advising: emptyDraft(),
    registration: emptyDraft(),
    schedules: emptyDraft()
  };
}

function normalizeHttpUrl(raw: string): string {
  const t = raw.trim();
  if (!t) {
    return '';
  }
  if (/^https?:\/\//i.test(t)) {
    return t;
  }
  return `https://${t}`;
}

export function AdvisorResources() {
  const ITEMS_PER_PAGE = 6;
  const [records, setRecords] = useState<AdvisorResourceRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [submitError, setSubmitError] = useState('');
  const [activeSection, setActiveSection] = useState<SectionId>('academic_advising');
  const [drafts, setDrafts] = useState<Record<SectionId, SectionDraft>>(initialDrafts);
  const [deleteTarget, setDeleteTarget] = useState<AdvisorResourceRecord | null>(null);
  const [currentPage, setCurrentPage] = useState(1);

  const photoInputRef = useRef<HTMLInputElement>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);

  const draft = drafts[activeSection];
  const sectionLabel = SECTIONS.find((s) => s.id === activeSection)?.label ?? activeSection;

  const setDraftField = <K extends keyof SectionDraft>(field: K, value: SectionDraft[K]) => {
    setDrafts((prev) => ({
      ...prev,
      [activeSection]: { ...prev[activeSection], [field]: value }
    }));
  };

  useEffect(() => {
    void loadResources();
  }, []);

  async function loadResources(): Promise<void> {
    try {
      setIsLoading(true);
      setSubmitError('');
      const data = await listAdvisorResources();
      setRecords(data);
      setCurrentPage(1);
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'Failed to load advisor resources.');
    } finally {
      setIsLoading(false);
    }
  }

  const sectionRecords = useMemo(() => {
    return records.filter((r) => r.section === activeSection);
  }, [records, activeSection]);

  const totalPages = Math.max(1, Math.ceil(sectionRecords.length / ITEMS_PER_PAGE));

  const paginatedRecords = useMemo(() => {
    const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
    return sectionRecords.slice(startIndex, startIndex + ITEMS_PER_PAGE);
  }, [currentPage, sectionRecords]);

  useEffect(() => {
    setCurrentPage(1);
  }, [activeSection]);

  async function handleSaveSection(): Promise<void> {
    const d = drafts[activeSection];
    const desc = d.sourceOfLink.trim() || '';

    const hasPdf = Boolean(d.pdfFile);
    const hasPhotoOnly = Boolean(d.photoFile) && !d.videoUrl.trim();
    const hasVideo = Boolean(d.videoUrl.trim());
    const hasLink = Boolean(d.linkUrl.trim());

    if (!hasPdf && !hasPhotoOnly && !hasVideo && !hasLink) {
      setSubmitError('Add at least one of: PDF, photo, video URL, or link URL.');
      return;
    }

    setIsSaving(true);
    setSubmitError('');

    try {
      if (hasPdf && d.pdfFile) {
        const input: AdvisorResourceInput = {
          title: 'PDF',
          description: desc,
          section: activeSection,
          resourceType: 'file',
          resourceUrl: '',
          duration: ''
        };
        await createAdvisorResource(input, d.pdfFile, null);
      }

      if (d.photoFile && !hasVideo) {
        const input: AdvisorResourceInput = {
          title: 'Photo',
          description: desc,
          section: activeSection,
          resourceType: 'file',
          resourceUrl: '',
          duration: ''
        };
        await createAdvisorResource(input, d.photoFile, null);
      }

      if (hasVideo) {
        const url = normalizeHttpUrl(d.videoUrl);
        const input: AdvisorResourceInput = {
          title: 'Video',
          description: desc,
          section: activeSection,
          resourceType: 'video',
          resourceUrl: url,
          duration: ''
        };
        const thumb = d.photoFile ?? null;
        await createAdvisorResource(input, null, thumb);
      }

      if (hasLink) {
        const url = normalizeHttpUrl(d.linkUrl);
        const input: AdvisorResourceInput = {
          title: 'Link',
          description: desc,
          section: activeSection,
          resourceType: 'link',
          resourceUrl: url,
          duration: ''
        };
        await createAdvisorResource(input, null, null);
      }

      setDrafts((prev) => ({ ...prev, [activeSection]: emptyDraft() }));
      if (photoInputRef.current) {
        photoInputRef.current.value = '';
      }
      if (pdfInputRef.current) {
        pdfInputRef.current.value = '';
      }
      await loadResources();
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'Failed to save one or more resources.');
    } finally {
      setIsSaving(false);
    }
  }

  async function confirmDelete(): Promise<void> {
    if (!deleteTarget) {
      return;
    }

    try {
      setSubmitError('');
      await deleteAdvisorResource(deleteTarget);
      setDeleteTarget(null);
      await loadResources();
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'Failed to delete advisor resource.');
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div>
        <h1 className="text-2xl font-bold text-must-text-primary">Advising resources</h1>
        <p className="text-sm text-must-text-secondary mt-1 max-w-2xl">
          Each area has its own form: upload a photo and/or PDF, add a video URL and/or link URL, and note the source of the
          link. Saving creates one entry per filled item for that section.
        </p>
      </div>

      <div className="flex border-b border-must-border overflow-x-auto gap-1">
        {SECTIONS.map((s) => (
          <button
            key={s.id}
            type="button"
            onClick={() => setActiveSection(s.id)}
            className={`px-5 py-3 text-sm font-medium whitespace-nowrap border-b-2 transition-colors ${activeSection === s.id ? 'border-must-green text-must-green' : 'border-transparent text-must-text-secondary hover:text-must-text-primary hover:border-slate-300'}`}
          >
            {s.label}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-5 gap-6">
        <Card className="xl:col-span-2 h-fit">
          <CardHeader className="flex flex-row items-center gap-2">
            <GraduationCapIcon className="w-5 h-5 text-must-green" />
            <h2 className="text-lg font-semibold text-must-text-primary">{sectionLabel}</h2>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-must-text-primary mb-2">Photo (image)</label>
              <input
                ref={photoInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={(e) => setDraftField('photoFile', e.target.files?.[0] ?? null)}
              />
              <Button type="button" variant="outline" size="sm" icon={<ImageIcon className="w-4 h-4" />} onClick={() => photoInputRef.current?.click()}>
                Choose photo
              </Button>
              {draft.photoFile ? <p className="text-xs text-must-text-secondary mt-2 break-all">{draft.photoFile.name}</p> : null}
              {draft.photoFile && draft.videoUrl.trim() ? (
                <p className="text-xs text-must-text-secondary mt-1">Photo will be used as the video thumbnail when a video URL is set.</p>
              ) : null}
            </div>

            <div>
              <label className="block text-sm font-medium text-must-text-primary mb-2">PDF</label>
              <input
                ref={pdfInputRef}
                type="file"
                accept="application/pdf,.pdf"
                className="hidden"
                onChange={(e) => setDraftField('pdfFile', e.target.files?.[0] ?? null)}
              />
              <Button type="button" variant="outline" size="sm" icon={<FileTextIcon className="w-4 h-4" />} onClick={() => pdfInputRef.current?.click()}>
                Choose PDF
              </Button>
              {draft.pdfFile ? <p className="text-xs text-must-text-secondary mt-2 break-all">{draft.pdfFile.name}</p> : null}
            </div>

            <Input
              label="Video URL"
              type="url"
              value={draft.videoUrl}
              onChange={(e) => setDraftField('videoUrl', e.target.value)}
              placeholder="https://..."
              icon={<PlayCircleIcon className="w-4 h-4" />}
            />

            <Input
              label="Link URL"
              type="url"
              value={draft.linkUrl}
              onChange={(e) => setDraftField('linkUrl', e.target.value)}
              placeholder="https://..."
              icon={<LinkIcon className="w-4 h-4" />}
            />

            <div>
              <label className="block text-sm font-medium text-must-text-primary mb-1">Source of link</label>
              <textarea
                value={draft.sourceOfLink}
                onChange={(e) => setDraftField('sourceOfLink', e.target.value)}
                placeholder="e.g. official faculty page, document name, publisher…"
                rows={3}
                className="w-full rounded-lg border border-must-border bg-must-surface text-must-text-primary px-4 py-2 text-sm focus:ring-2 focus:ring-must-green outline-none resize-y"
              />
            </div>

            {submitError ? <p className="text-sm text-red-500">{submitError}</p> : null}

            <div className="flex flex-wrap gap-2 pt-1">
              <Button type="button" disabled={isSaving} onClick={() => void handleSaveSection()}>
                {isSaving ? 'Saving…' : 'Save for this section'}
              </Button>
              <Button
                type="button"
                variant="outline"
                disabled={isSaving}
                onClick={() => {
                  setDraftField('photoFile', null);
                  setDraftField('pdfFile', null);
                  setDraftField('videoUrl', '');
                  setDraftField('linkUrl', '');
                  setDraftField('sourceOfLink', '');
                  if (photoInputRef.current) {
                    photoInputRef.current.value = '';
                  }
                  if (pdfInputRef.current) {
                    pdfInputRef.current.value = '';
                  }
                  setSubmitError('');
                }}
              >
                Clear form
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="xl:col-span-3 space-y-4">
          <h3 className="text-sm font-medium text-must-text-secondary">
            Saved items — {sectionLabel} ({sectionRecords.length})
          </h3>

          {isLoading ? (
            <Card>
              <CardContent className="p-6 text-sm text-must-text-secondary">Loading resources...</CardContent>
            </Card>
          ) : null}

          {!isLoading && sectionRecords.length === 0 ? (
            <Card>
              <CardContent className="p-6 text-sm text-must-text-secondary">No resources for this section yet.</CardContent>
            </Card>
          ) : null}

          {!isLoading && sectionRecords.length > 0 ? (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {paginatedRecords.map((record) => {
                  const fileUrl = getPublicFileUrl(supabaseResourcesFilesBucket, record.file_path);
                  const thumbnailUrl = getPublicFileUrl(supabaseResourcesFilesBucket, record.thumbnail_path);
                  const actionUrl = record.resource_type === 'file' ? fileUrl : record.resource_url;
                  const isFileResource = record.resource_type === 'file';

                  return (
                    <Card key={record.id}>
                      <CardContent className="p-4">
                        <div className="flex items-start gap-3">
                          <div className="p-2 rounded-lg bg-slate-100 dark:bg-slate-800 text-must-text-secondary">
                            {record.resource_type === 'video' ? (
                              <PlayCircleIcon className="w-5 h-5" />
                            ) : record.resource_type === 'link' ? (
                              <LinkIcon className="w-5 h-5" />
                            ) : (
                              <FileTextIcon className="w-5 h-5" />
                            )}
                          </div>

                          <div className="flex-1 min-w-0">
                            <h3 className="font-semibold text-must-text-primary truncate">{record.title}</h3>
                            {record.description ? (
                              <p className="text-xs text-must-text-secondary mt-1 line-clamp-3">
                                <span className="font-medium text-must-text-primary">Source: </span>
                                {record.description}
                              </p>
                            ) : null}
                            <p className="text-xs text-must-text-secondary mt-1 capitalize">{record.resource_type}</p>
                          </div>
                        </div>

                        {record.resource_type === 'video' && thumbnailUrl ? (
                          <img
                            src={thumbnailUrl}
                            alt=""
                            className="mt-3 w-full h-32 object-cover rounded-lg border border-must-border"
                          />
                        ) : null}

                        <div className="mt-4 flex flex-wrap gap-2">
                          <Button
                            type="button"
                            size="sm"
                            variant="secondary"
                            icon={isFileResource ? <DownloadIcon className="w-4 h-4" /> : <LinkIcon className="w-4 h-4" />}
                            disabled={!actionUrl}
                            onClick={() => {
                              if (actionUrl) {
                                window.open(actionUrl, '_blank', 'noopener,noreferrer');
                              }
                            }}
                          >
                            {isFileResource ? 'Open / download' : 'Open link'}
                          </Button>
                          <Button type="button" size="sm" variant="danger" icon={<Trash2Icon className="w-4 h-4" />} onClick={() => setDeleteTarget(record)}>
                            Delete
                          </Button>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
              </div>
              <Pagination
                currentPage={currentPage}
                totalPages={totalPages}
                totalItems={sectionRecords.length}
                itemLabel="resources"
                onPageChange={setCurrentPage}
              />
            </>
          ) : null}
        </div>
      </div>

      <ConfirmModal
        isOpen={Boolean(deleteTarget)}
        title="Delete resource"
        message="This will permanently delete the resource. This action cannot be undone."
        confirmLabel="Delete"
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          void confirmDelete();
        }}
      />
    </div>
  );
}
