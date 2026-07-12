import { Injectable, signal } from '@angular/core';

export type CourseKind = 'COURS' | 'FORMATION';
export type BlockType = 'TEXT' | 'CODE' | 'IMAGE' | 'VIDEO' | 'QUIZ' | 'FILE' | 'TIP';

export interface LessonBlock {
  id: string;
  type: BlockType;
  title?: string;
  content: string;
  tipColor?: 'blue' | 'green' | 'amber' | 'red' | 'slate';
  fileName?: string;
  optionA?: string;
  optionB?: string;
  optionC?: string;
  optionD?: string;
  answer?: string;
  language?: string;
}

export interface LessonDraft {
  id: string;
  title: string;
  durationMinutes: number;
  shortDescription: string;
  sortOrder: number;
  blocks: LessonBlock[];
  estPreview?: boolean;
  typeContenu?: 'TEXTE' | 'VIDEO' | 'PDF';
  xpReward?: number;
}

export interface ModuleDraft {
  id: string;
  title: string;
  sortOrder: number;
  lessons: LessonDraft[];
  description?: string;
  estGratuit?: boolean;
}

export interface CourseDraft {
  id: string;
  remoteId?: string;
  kind: CourseKind;
  title: string;
  description: string;
  level: 'DEBUTANT' | 'INTERMEDIAIRE' | 'AVANCE';
  priceFcfa: number;
  freePercent: number;
  bannerUrl: string;
  bannerFileName: string;
  status: 'BROUILLON';
  modules: ModuleDraft[];
  updatedAt: string;
  about?: string;
  whatYouLearn?: string;
  category?: string;
  prerequis?: string;
  publicCible?: string;
}

@Injectable({ providedIn: 'root' })
export class CourseBuilderDraftService {
  readonly courses = signal<Record<string, CourseDraft>>(this.#restore());

  getOrCreate(id?: string): CourseDraft {
    const cid = id || this.#uid('draft-course');
    const existing = this.courses()[cid];
    if (existing) return existing;
    const draft: CourseDraft = {
      id: cid,
      kind: 'FORMATION',
      title: '',
      description: '',
      level: 'DEBUTANT',
      priceFcfa: 25000,
      freePercent: 30,
      bannerUrl: '',
      bannerFileName: '',
      status: 'BROUILLON',
      modules: [],
      updatedAt: new Date().toISOString(),
    };
    this.#set(draft);
    return draft;
  }

  get(id: string): CourseDraft | null {
    return this.courses()[id] ?? null;
  }

  save(course: CourseDraft): void {
    this.#set({ ...course, updatedAt: new Date().toISOString() });
  }

  patch(id: string, patch: Partial<CourseDraft>): CourseDraft {
    const base = this.getOrCreate(id);
    const next = { ...base, ...patch, updatedAt: new Date().toISOString() };
    this.#set(next);
    return next;
  }

  remove(id: string): void {
    this.courses.update(c => {
      const next = { ...c };
      delete next[id];
      return next;
    });
    this.#persist();
  }

  toApiPayload(id: string): Record<string, unknown> | null {
    const c = this.get(id);
    if (!c) return null;
    return {
      id: c.remoteId ?? null,
      kind: c.kind,
      title: c.title,
      description: c.description,
      level: c.level,
      priceFcfa: c.priceFcfa,
      freePercent: c.kind === 'COURS' ? 100 : c.freePercent,
      bannerUrl: c.bannerUrl,
      modules: c.modules.map(m => ({
        id: m.id,
        title: m.title,
        sortOrder: m.sortOrder,
        lessons: m.lessons.map(l => ({
          id: l.id,
          title: l.title,
          durationMinutes: l.durationMinutes,
          shortDescription: l.shortDescription,
          sortOrder: l.sortOrder,
          blocks: l.blocks,
        })),
      })),
    };
  }

  #set(course: CourseDraft): void {
    this.courses.update(c => ({ ...c, [course.id]: course }));
    this.#persist();
  }

  #persist(): void {
    try {
      if (typeof window === 'undefined') return;
      localStorage.setItem('mn_course_builder_drafts', JSON.stringify(this.courses()));
    } catch {}
  }

  #restore(): Record<string, CourseDraft> {
    try {
      if (typeof window === 'undefined') return {};
      const raw = localStorage.getItem('mn_course_builder_drafts');
      return raw ? (JSON.parse(raw) as Record<string, CourseDraft>) : {};
    } catch {
      return {};
    }
  }

  #uid(prefix: string): string {
    return `${prefix}-${Math.random().toString(36).slice(2, 10)}`;
  }
}
