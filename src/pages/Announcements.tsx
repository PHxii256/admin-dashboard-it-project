import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { ImagePlusIcon, FileTextIcon, MegaphoneIcon, RotateCcwIcon, XIcon } from 'lucide-react';
import {
  createAnnouncement,
  listAnnouncements,
  type AnnouncementInput,
  type AnnouncementViewModel
} from '../services/announcementsService';

const DEFAULT_ANNOUNCEMENT_PHOTO = '/must-announcement-default.png';

interface AttachedPreview {
  id: string;
  file: File;
  url: string;
}

function todayInputValue(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function Announcements() {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState(todayInputValue);
  const [mainPhotoFile, setMainPhotoFile] = useState<File | null>(null);
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [attached, setAttached] = useState<AttachedPreview[]>([]);
  const [published, setPublished] = useState<AnnouncementViewModel[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'ok' | 'err'; text: string } | null>(null);

  const mainPhotoPreviewUrl = useMemo(() => {
    if (!mainPhotoFile) {
      return null;
    }
    return URL.createObjectURL(mainPhotoFile);
  }, [mainPhotoFile]);

  useEffect(() => {
    return () => {
      if (mainPhotoPreviewUrl) {
        URL.revokeObjectURL(mainPhotoPreviewUrl);
      }
    };
  }, [mainPhotoPreviewUrl]);

  const mainPhotoInputRef = useRef<HTMLInputElement>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);
  const galleryInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    void loadAnnouncements();
  }, []);

  async function loadAnnouncements(): Promise<void> {
    try {
      setIsLoading(true);
      const data = await listAnnouncements();
      setPublished(data);
    } catch (error) {
      setFeedback({
        type: 'err',
        text: error instanceof Error ? error.message : 'Failed to load announcements.'
      });
    } finally {
      setIsLoading(false);
    }
  }

  const addAttachments = useCallback((fileList: FileList | null) => {
    if (!fileList?.length) {
      return;
    }
    const next: AttachedPreview[] = [];
    for (const file of Array.from(fileList)) {
      if (!file.type.startsWith('image/')) {
        continue;
      }
      next.push({ id: `${file.name}-${file.size}-${Math.random()}`, file, url: URL.createObjectURL(file) });
    }
    if (next.length) {
      setAttached((prev) => [...prev, ...next]);
    }
  }, []);

  const removeAttachment = useCallback((id: string) => {
    setAttached((prev) => {
      const item = prev.find((a) => a.id === id);
      if (item) {
        URL.revokeObjectURL(item.url);
      }
      return prev.filter((a) => a.id !== id);
    });
  }, []);

  const resetMainPhotoToDefault = () => {
    setMainPhotoFile(null);
  };

  const resetForm = () => {
    setTitle('');
    setDescription('');
    setDate(todayInputValue());
    setMainPhotoFile(null);
    setPdfFile(null);
    setAttached((prev) => {
      prev.forEach((a) => URL.revokeObjectURL(a.url));
      return [];
    });
  };

  const handlePublish = async () => {
    setFeedback(null);
    if (!title.trim()) {
      setFeedback({ type: 'err', text: 'Please enter a title.' });
      return;
    }
    if (!description.trim()) {
      setFeedback({ type: 'err', text: 'Please enter a description.' });
      return;
    }
    if (!date) {
      setFeedback({ type: 'err', text: 'Please choose a date.' });
      return;
    }

    setIsSubmitting(true);
    try {
      const input: AnnouncementInput = {
        title: title.trim(),
        description: description.trim(),
        announcementDate: date
      };

      await createAnnouncement(input, {
        mainPhotoFile,
        pdfFile,
        attachmentFiles: attached.map((item) => item.file)
      });

      resetForm();
      await loadAnnouncements();
      setFeedback({ type: 'ok', text: 'Announcement saved successfully.' });
    } catch (error) {
      setFeedback({
        type: 'err',
        text: error instanceof Error ? error.message : 'Failed to save announcement.'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const mainPhotoSrc = mainPhotoPreviewUrl ?? DEFAULT_ANNOUNCEMENT_PHOTO;

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <h1 className="text-2xl font-bold text-must-text-primary">Announcements</h1>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <Card className="xl:col-span-2 h-fit">
          <CardHeader>
            <h2 className="text-lg font-semibold text-must-text-primary flex items-center gap-2">
              <MegaphoneIcon className="w-5 h-5 text-must-green" />
              New announcement
            </h2>
          </CardHeader>
          <CardContent className="space-y-5">
            {feedback && (
              <p
                className={`text-sm rounded-lg px-3 py-2 ${feedback.type === 'ok' ? 'bg-green-50 text-green-800 dark:bg-green-900/30 dark:text-green-200' : 'bg-red-50 text-red-700 dark:bg-red-900/25 dark:text-red-200'}`}
              >
                {feedback.text}
              </p>
            )}

            <Input label="Title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Announcement title" required />

            <div>
              <label className="block text-sm font-medium text-must-text-primary mb-1">
                Description<span className="ml-1 text-red-500">*</span>
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full rounded-lg border border-must-border bg-must-surface text-must-text-primary px-4 py-2 focus:ring-2 focus:ring-must-green outline-none min-h-[140px] resize-y"
                placeholder="Full announcement text…"
                required
              />
            </div>

            <Input label="Date" type="date" value={date} onChange={(e) => setDate(e.target.value)} required />

            <div className="space-y-2">
              <span className="block text-sm font-medium text-must-text-primary">Photo</span>
              <p className="text-xs text-must-text-secondary">Defaults to the MUST logo. Upload to replace.</p>
              <div className="flex flex-col sm:flex-row gap-4 items-start">
                <div className="relative w-36 h-36 rounded-xl border border-must-border bg-white overflow-hidden shrink-0">
                  <img src={mainPhotoSrc} alt="Announcement" className="w-full h-full object-contain p-2" />
                </div>
                <div className="flex flex-wrap gap-2">
                  <input
                    ref={mainPhotoInputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={(e) => {
                      const f = e.target.files?.[0];
                      setMainPhotoFile(f ?? null);
                      e.target.value = '';
                    }}
                  />
                  <Button type="button" variant="outline" size="sm" onClick={() => mainPhotoInputRef.current?.click()}>
                    Change photo
                  </Button>
                  {mainPhotoFile && (
                    <Button type="button" variant="ghost" size="sm" icon={<RotateCcwIcon className="w-4 h-4" />} onClick={resetMainPhotoToDefault}>
                      Use default logo
                    </Button>
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <span className="block text-sm font-medium text-must-text-primary">
                PDF <span className="text-must-text-secondary font-normal">(optional)</span>
              </span>
              <div className="flex flex-wrap items-center gap-2">
                <input
                  ref={pdfInputRef}
                  type="file"
                  accept="application/pdf"
                  className="hidden"
                  onChange={(e) => {
                    setPdfFile(e.target.files?.[0] ?? null);
                    e.target.value = '';
                  }}
                />
                <Button type="button" variant="outline" size="sm" icon={<FileTextIcon className="w-4 h-4" />} onClick={() => pdfInputRef.current?.click()}>
                  Attach PDF
                </Button>
                {pdfFile && (
                  <>
                    <span className="text-sm text-must-text-secondary truncate max-w-[200px]">{pdfFile.name}</span>
                    <Button type="button" variant="ghost" size="sm" onClick={() => setPdfFile(null)}>
                      Remove
                    </Button>
                  </>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <span className="block text-sm font-medium text-must-text-primary">Photos with announcement</span>
              <p className="text-xs text-must-text-secondary">Add one or more images (gallery).</p>
              <input ref={galleryInputRef} type="file" accept="image/*" multiple className="hidden" onChange={(e) => addAttachments(e.target.files)} />
              <Button type="button" variant="outline" size="sm" icon={<ImagePlusIcon className="w-4 h-4" />} onClick={() => galleryInputRef.current?.click()}>
                Add photos
              </Button>
              {attached.length > 0 && (
                <div className="flex flex-wrap gap-3 pt-2">
                  {attached.map((a) => (
                    <div key={a.id} className="relative w-24 h-24 rounded-lg border border-must-border overflow-hidden group">
                      <img src={a.url} alt="" className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => removeAttachment(a.id)}
                        className="absolute top-1 right-1 p-1 rounded-full bg-black/60 text-white opacity-0 group-hover:opacity-100 transition-opacity"
                        aria-label="Remove photo"
                      >
                        <XIcon className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex flex-wrap gap-2 pt-2">
              <Button type="button" onClick={() => void handlePublish()} disabled={isSubmitting}>
                {isSubmitting ? 'Publishing…' : 'Publish announcement'}
              </Button>
              <Button type="button" variant="outline" onClick={resetForm} disabled={isSubmitting}>
                Clear form
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card className="h-fit">
          <CardHeader>
            <h2 className="text-lg font-semibold text-must-text-primary">Preview</h2>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="rounded-lg border border-must-border overflow-hidden bg-white">
              <img src={mainPhotoSrc} alt="" className="w-full aspect-video object-contain p-4" />
            </div>
            <p className="font-medium text-must-text-primary">{title || 'Title'}</p>
            <p className="text-must-text-secondary whitespace-pre-wrap">{description || 'Description will appear here.'}</p>
            <p className="text-xs text-must-text-secondary">{date || '—'}</p>
            {pdfFile && (
              <p className="text-xs flex items-center gap-1 text-must-text-secondary">
                <FileTextIcon className="w-3.5 h-3.5" />
                {pdfFile.name}
              </p>
            )}
            {attached.length > 0 && (
              <div className="grid grid-cols-3 gap-1 pt-2">
                {attached.map((a) => (
                  <img key={a.id} src={a.url} alt="" className="w-full h-16 object-cover rounded border border-must-border" />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {isLoading ? (
        <Card>
          <CardContent className="p-6 text-sm text-must-text-secondary">Loading announcements...</CardContent>
        </Card>
      ) : null}

      {!isLoading && published.length > 0 ? (
        <div className="space-y-3">
          <h2 className="text-lg font-semibold text-must-text-primary">Published announcements</h2>
          <div className="grid gap-4 md:grid-cols-2">
            {published.map((p) => (
              <Card key={p.id}>
                <CardContent className="p-4 flex gap-3">
                  <img
                    src={p.mainImageUrl ?? DEFAULT_ANNOUNCEMENT_PHOTO}
                    alt=""
                    className="w-20 h-20 object-contain rounded-lg border border-must-border bg-white shrink-0"
                  />
                  <div className="min-w-0">
                    <h3 className="font-semibold text-must-text-primary truncate">{p.title}</h3>
                    <p className="text-xs text-must-text-secondary mt-1">{p.announcement_date}</p>
                    <p className="text-sm text-must-text-secondary line-clamp-2 mt-1">{p.description}</p>
                    {p.pdfUrl && <p className="text-xs text-must-text-secondary mt-1">PDF attached</p>}
                    {p.attachmentImageUrls.length > 0 && (
                      <div className="flex gap-1 mt-2 overflow-x-auto">
                        {p.attachmentImageUrls.map((src, i) => (
                          <img key={i} src={src} alt="" className="w-10 h-10 object-cover rounded border border-must-border shrink-0" />
                        ))}
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}
