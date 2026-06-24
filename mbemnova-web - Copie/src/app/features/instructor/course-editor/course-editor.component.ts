import {
  ChangeDetectionStrategy, Component, computed, inject,
  input, OnInit, signal,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AdminService } from '../../../core/services/admin.service';
import { ToastService } from '../../../core/services/toast.service';
import type { NiveauCours } from '../../../core/models';

type BlockType = 'TEXT' | 'CODE' | 'IMAGE' | 'VIDEO' | 'QUIZ' | 'FILE' | 'TIP';
interface LessonBlock {
  id: string;
  type: BlockType;
  title: string;
  content: string;
  optionA?: string;
  optionB?: string;
  optionC?: string;
  optionD?: string;
  answer?: string;
}
interface LessonItem {
  id: string;
  title: string;
  duration: number;
  description: string;
  sortOrder: number;
  blocks: LessonBlock[];
}
interface ModuleItem {
  id: string;
  title: string;
  sortOrder: number;
  lessons: LessonItem[];
}

@Component({
  selector: 'app-course-editor',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-[#f8f9fb]">
  <header class="sticky top-0 z-30 bg-white border-b border-slate-100">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
      <div class="flex items-center gap-3 min-w-0">
        <a routerLink="/instructor" class="text-slate-400 hover:text-slate-700">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <div class="min-w-0">
          <h1 class="text-sm sm:text-base font-black text-slate-900 truncate">
            {{ isEditMode() ? 'Editer la formation' : 'Creation d\\'une formation' }}
          </h1>
          <p class="text-[11px] text-slate-400">Formateur · constructeur complet de cours</p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-[11px] font-semibold text-slate-500 bg-slate-100 px-2 py-1 rounded-full">Statut: Brouillon</span>
        <button (click)="saveCourse()" [disabled]="saving()" class="px-3 py-2 rounded-lg bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 disabled:opacity-60">
          {{ saving() ? 'Enregistrement...' : 'Enregistrer' }}
        </button>
      </div>
    </div>
  </header>

  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">
    <section class="bg-white border border-slate-100 rounded-xl p-5">
      <h2 class="text-sm font-bold text-slate-900 mb-4">4.2 Creation d'une formation</h2>
      <form [formGroup]="courseForm" class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="md:col-span-2">
          <label class="text-xs font-semibold text-slate-600">Titre</label>
          <input class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" formControlName="title" placeholder="Titre de la formation">
        </div>
        <div class="md:col-span-2">
          <label class="text-xs font-semibold text-slate-600">Description</label>
          <textarea rows="3" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" formControlName="description" placeholder="Description de la formation"></textarea>
        </div>
        <div>
          <label class="text-xs font-semibold text-slate-600">Niveau</label>
          <select class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" formControlName="level">
            <option value="DEBUTANT">Debutant</option>
            <option value="INTERMEDIAIRE">Intermediaire</option>
            <option value="AVANCE">Avance</option>
          </select>
        </div>
        <div>
          <label class="text-xs font-semibold text-slate-600">Prix (FCFA)</label>
          <input type="number" min="0" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" formControlName="price">
        </div>
      </form>
    </section>

    <section class="bg-white border border-slate-100 rounded-xl p-5">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-sm font-bold text-slate-900">4.3 Gestion des modules</h2>
        <button (click)="addModule()" class="text-xs font-semibold text-blue-600 hover:text-blue-700">+ Ajouter un module</button>
      </div>
      <div class="space-y-3">
        @for (m of modules(); track m.id; let mi = $index) {
          <div class="border border-slate-200 rounded-xl bg-slate-50/50 p-3"
               draggable="true"
               (dragstart)="onModuleDragStart(mi)"
               (dragover)="onDragOver($event)"
               (drop)="onModuleDrop(mi)">
            <div class="flex items-center gap-2">
              <span class="text-xs text-slate-400">::</span>
              <input class="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm" [value]="m.title" (input)="renameModule(mi, asText($event))">
              <button (click)="removeModule(mi)" class="text-xs text-red-600 hover:text-red-700">Supprimer</button>
            </div>

            <div class="mt-3 pl-3 border-l-2 border-slate-200 space-y-2">
              <div class="flex items-center justify-between">
                <p class="text-xs font-semibold text-slate-600">4.4 Lecons</p>
                <button (click)="addLesson(mi)" class="text-xs font-semibold text-blue-600 hover:text-blue-700">+ Ajouter une lecon</button>
              </div>

              @for (l of m.lessons; track l.id; let li = $index) {
                <div class="bg-white border border-slate-200 rounded-lg p-3"
                     draggable="true"
                     (dragstart)="onLessonDragStart(mi, li)"
                     (dragover)="onDragOver($event)"
                     (drop)="onLessonDrop(mi, li)">
                  <div class="grid grid-cols-1 md:grid-cols-12 gap-2">
                    <input class="md:col-span-5 border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="l.title" (input)="renameLesson(mi, li, asText($event))" placeholder="Titre">
                    <input type="number" min="1" class="md:col-span-2 border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="l.duration" (input)="setLessonDuration(mi, li, asNumber($event, 10))" placeholder="Duree">
                    <input class="md:col-span-4 border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="l.description" (input)="setLessonDescription(mi, li, asText($event))" placeholder="Description courte (optionnel)">
                    <div class="md:col-span-1 flex items-center justify-end gap-2">
                      <button (click)="selectLesson(mi, li)" class="text-[11px] font-semibold text-blue-600 hover:text-blue-700">Editer</button>
                      <button (click)="removeLesson(mi, li)" class="text-[11px] text-red-600 hover:text-red-700">X</button>
                    </div>
                  </div>
                </div>
              }
            </div>
          </div>
        }
      </div>
    </section>

    <section class="bg-white border border-slate-100 rounded-xl p-5">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-sm font-bold text-slate-900">4.5 Editeur de lecon avec apercu en temps reel</h2>
        @if (selectedLessonPath()) {
          <span class="text-[11px] text-slate-500">Autosave local: actif</span>
        }
      </div>

      @if (!selectedLessonPath()) {
        <div class="text-sm text-slate-500 border border-dashed border-slate-300 rounded-xl p-6 text-center">
          Selectionnez une lecon dans un module pour ouvrir l'editeur.
        </div>
      } @else {
        <div class="grid grid-cols-1 xl:grid-cols-2 gap-4">
          <div class="border border-slate-200 rounded-xl p-4 space-y-3">
            <div class="flex items-center justify-between">
              <p class="text-xs font-semibold text-slate-600">Blocs de contenu</p>
              <select class="text-xs border border-slate-200 rounded-lg px-2 py-1" (change)="addBlock(($any($event.target)).value); ($any($event.target)).value=''">
                <option value="">+ Ajouter un bloc</option>
                <option value="TEXT">Texte</option>
                <option value="CODE">Code</option>
                <option value="IMAGE">Image</option>
                <option value="VIDEO">Video</option>
                <option value="QUIZ">Quiz</option>
                <option value="FILE">Fichier</option>
                <option value="TIP">TIP</option>
              </select>
            </div>

            @for (b of selectedBlocks(); track b.id; let bi = $index) {
              <div class="border border-slate-200 rounded-lg p-3 bg-slate-50"
                   draggable="true"
                   (dragstart)="onBlockDragStart(bi)"
                   (dragover)="onDragOver($event)"
                   (drop)="onBlockDrop(bi)">
                <div class="flex items-center gap-2 mb-2">
                  <span class="text-[10px] font-bold text-blue-600 bg-blue-50 px-2 py-1 rounded-full">{{ b.type }}</span>
                  <span class="text-[10px] text-slate-400">::</span>
                  <button (click)="removeBlock(bi)" class="ml-auto text-[11px] text-red-600 hover:text-red-700">Supprimer</button>
                </div>
                <input class="w-full border border-slate-200 rounded-lg px-2 py-1.5 text-sm mb-2" [value]="b.title" (input)="setBlockField(bi, 'title', asText($event))" placeholder="Titre du bloc">
                <textarea rows="3" class="w-full border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="b.content" (input)="setBlockField(bi, 'content', asText($event))" placeholder="Contenu"></textarea>
                @if (b.type === 'QUIZ') {
                  <div class="grid grid-cols-2 gap-2 mt-2">
                    <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionA || ''" (input)="setBlockField(bi, 'optionA', asText($event))" placeholder="Option A">
                    <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionB || ''" (input)="setBlockField(bi, 'optionB', asText($event))" placeholder="Option B">
                    <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionC || ''" (input)="setBlockField(bi, 'optionC', asText($event))" placeholder="Option C">
                    <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionD || ''" (input)="setBlockField(bi, 'optionD', asText($event))" placeholder="Option D">
                    <input class="col-span-2 border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.answer || ''" (input)="setBlockField(bi, 'answer', asText($event))" placeholder="Bonne reponse (A/B/C/D)">
                  </div>
                }
              </div>
            }
          </div>

          <div class="border border-slate-200 rounded-xl p-4 bg-white">
            <p class="text-xs font-semibold text-slate-600 mb-3">Apercu apprenant (temps reel)</p>
            <div class="space-y-3">
              @for (b of selectedBlocks(); track b.id) {
                <article class="border border-slate-100 rounded-lg p-3">
                  <h4 class="text-sm font-bold text-slate-900 mb-1">{{ b.title || '(sans titre)' }}</h4>
                  @switch (b.type) {
                    @case ('TEXT') { <p class="text-sm text-slate-700 whitespace-pre-wrap">{{ b.content }}</p> }
                    @case ('CODE') { <pre class="text-xs bg-slate-900 text-sky-200 rounded-lg p-3 overflow-auto">{{ b.content }}</pre> }
                    @case ('IMAGE') { <img [src]="b.content" alt="preview image" class="w-full max-h-56 object-cover rounded-lg bg-slate-100"> }
                    @case ('VIDEO') { <div class="text-sm text-slate-600">Lien video: {{ b.content }}</div> }
                    @case ('FILE') { <a [href]="b.content" target="_blank" class="text-sm text-blue-600 underline">Ouvrir le fichier</a> }
                    @case ('TIP') { <div class="bg-blue-50 border-l-4 border-blue-500 text-blue-800 px-3 py-2 text-sm">{{ b.content }}</div> }
                    @case ('QUIZ') {
                      <div class="text-sm text-slate-700 space-y-1">
                        <p>{{ b.content }}</p>
                        <p>A) {{ b.optionA || '-' }}</p>
                        <p>B) {{ b.optionB || '-' }}</p>
                        <p>C) {{ b.optionC || '-' }}</p>
                        <p>D) {{ b.optionD || '-' }}</p>
                      </div>
                    }
                  }
                </article>
              }
            </div>
          </div>
        </div>
      }
    </section>
  </main>
</div>
  `,
})
export class CourseEditorComponent implements OnInit {
  readonly id = input<string>('');

  readonly #adminSvc = inject(AdminService);
  readonly #toast = inject(ToastService);
  readonly #router = inject(Router);
  readonly #route = inject(ActivatedRoute);
  readonly #fb = inject(FormBuilder);

  readonly saving = signal(false);
  readonly isEditMode = computed(() => !!this.id() || !!this.#route.snapshot.paramMap.get('id'));

  readonly courseForm = this.#fb.nonNullable.group({
    title: ['', [Validators.required, Validators.minLength(5)]],
    description: ['', [Validators.required, Validators.minLength(10)]],
    level: ['DEBUTANT' as NiveauCours, Validators.required],
    price: [25000, [Validators.required, Validators.min(0)]],
  });

  readonly modules = signal<ModuleItem[]>([]);
  readonly selectedLessonPath = signal<{ moduleIndex: number; lessonIndex: number } | null>(null);

  #dragModuleIndex: number | null = null;
  #dragLesson: { moduleIndex: number; lessonIndex: number } | null = null;
  #dragBlockIndex: number | null = null;

  ngOnInit(): void {
    this.addModule();
    this.addLesson(0);
    this.selectLesson(0, 0);
    this.restoreDraft();
  }

  addModule(): void {
    this.modules.update(ms => [
      ...ms,
      { id: this.uid('mod'), title: `Module ${ms.length + 1}`, sortOrder: ms.length + 1, lessons: [] },
    ]);
  }

  removeModule(index: number): void {
    this.modules.update(ms => ms.filter((_, i) => i !== index).map((m, i) => ({ ...m, sortOrder: i + 1 })));
    this.ensureSelectedLesson();
    this.autoSaveDraft();
  }

  renameModule(index: number, title: string): void {
    this.modules.update(ms => ms.map((m, i) => i === index ? { ...m, title } : m));
    this.autoSaveDraft();
  }

  addLesson(moduleIndex: number): void {
    this.modules.update(ms => ms.map((m, i) => {
      if (i !== moduleIndex) return m;
      const next = m.lessons.length + 1;
      const lesson: LessonItem = {
        id: this.uid('lesson'),
        title: `Lecon ${next}`,
        duration: 10,
        description: '',
        sortOrder: next,
        blocks: [],
      };
      return { ...m, lessons: [...m.lessons, lesson] };
    }));
    const li = this.modules()[moduleIndex]?.lessons.length ? this.modules()[moduleIndex].lessons.length - 1 : 0;
    this.selectLesson(moduleIndex, li);
    this.autoSaveDraft();
  }

  removeLesson(moduleIndex: number, lessonIndex: number): void {
    this.modules.update(ms => ms.map((m, i) => {
      if (i !== moduleIndex) return m;
      const lessons = m.lessons.filter((_, li) => li !== lessonIndex).map((l, li) => ({ ...l, sortOrder: li + 1 }));
      return { ...m, lessons };
    }));
    this.ensureSelectedLesson();
    this.autoSaveDraft();
  }

  renameLesson(moduleIndex: number, lessonIndex: number, title: string): void {
    this.modules.update(ms => ms.map((m, i) => i !== moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => li === lessonIndex ? { ...l, title } : l),
    })));
    this.autoSaveDraft();
  }

  setLessonDuration(moduleIndex: number, lessonIndex: number, value: number): void {
    this.modules.update(ms => ms.map((m, i) => i !== moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => li === lessonIndex ? { ...l, duration: Math.max(1, value) } : l),
    })));
    this.autoSaveDraft();
  }

  setLessonDescription(moduleIndex: number, lessonIndex: number, value: string): void {
    this.modules.update(ms => ms.map((m, i) => i !== moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => li === lessonIndex ? { ...l, description: value } : l),
    })));
    this.autoSaveDraft();
  }

  selectLesson(moduleIndex: number, lessonIndex: number): void {
    this.selectedLessonPath.set({ moduleIndex, lessonIndex });
  }

  selectedBlocks(): LessonBlock[] {
    const p = this.selectedLessonPath();
    if (!p) return [];
    return this.modules()[p.moduleIndex]?.lessons[p.lessonIndex]?.blocks ?? [];
  }

  addBlock(type: string): void {
    if (!type) return;
    const p = this.selectedLessonPath();
    if (!p) return;
    const block: LessonBlock = {
      id: this.uid('blk'),
      type: type as BlockType,
      title: '',
      content: '',
      optionA: '',
      optionB: '',
      optionC: '',
      optionD: '',
      answer: '',
    };
    this.modules.update(ms => ms.map((m, mi) => mi !== p.moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => li !== p.lessonIndex ? l : ({ ...l, blocks: [...l.blocks, block] })),
    })));
    this.autoSaveDraft();
  }

  removeBlock(blockIndex: number): void {
    const p = this.selectedLessonPath();
    if (!p) return;
    this.modules.update(ms => ms.map((m, mi) => mi !== p.moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => li !== p.lessonIndex ? l : ({ ...l, blocks: l.blocks.filter((_, bi) => bi !== blockIndex) })),
    })));
    this.autoSaveDraft();
  }

  setBlockField(blockIndex: number, field: keyof LessonBlock, value: string): void {
    const p = this.selectedLessonPath();
    if (!p) return;
    this.modules.update(ms => ms.map((m, mi) => mi !== p.moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => li !== p.lessonIndex ? l : ({
        ...l,
        blocks: l.blocks.map((b, bi) => bi !== blockIndex ? b : ({ ...b, [field]: value })),
      })),
    })));
    this.autoSaveDraft();
  }

  onDragOver(event: DragEvent): void { event.preventDefault(); }
  onModuleDragStart(index: number): void { this.#dragModuleIndex = index; }
  onModuleDrop(targetIndex: number): void {
    const from = this.#dragModuleIndex;
    if (from === null || from === targetIndex) return;
    this.modules.update(ms => {
      const arr = [...ms];
      const [m] = arr.splice(from, 1);
      arr.splice(targetIndex, 0, m);
      return arr.map((x, i) => ({ ...x, sortOrder: i + 1 }));
    });
    this.#dragModuleIndex = null;
    this.autoSaveDraft();
  }

  onLessonDragStart(moduleIndex: number, lessonIndex: number): void {
    this.#dragLesson = { moduleIndex, lessonIndex };
  }
  onLessonDrop(moduleIndex: number, targetLessonIndex: number): void {
    const drag = this.#dragLesson;
    if (!drag || drag.moduleIndex !== moduleIndex || drag.lessonIndex === targetLessonIndex) return;
    this.modules.update(ms => ms.map((m, mi) => {
      if (mi !== moduleIndex) return m;
      const lessons = [...m.lessons];
      const [l] = lessons.splice(drag.lessonIndex, 1);
      lessons.splice(targetLessonIndex, 0, l);
      return { ...m, lessons: lessons.map((x, i) => ({ ...x, sortOrder: i + 1 })) };
    }));
    this.#dragLesson = null;
    this.autoSaveDraft();
  }

  onBlockDragStart(blockIndex: number): void { this.#dragBlockIndex = blockIndex; }
  onBlockDrop(targetBlockIndex: number): void {
    const p = this.selectedLessonPath();
    const from = this.#dragBlockIndex;
    if (!p || from === null || from === targetBlockIndex) return;
    this.modules.update(ms => ms.map((m, mi) => mi !== p.moduleIndex ? m : ({
      ...m,
      lessons: m.lessons.map((l, li) => {
        if (li !== p.lessonIndex) return l;
        const blocks = [...l.blocks];
        const [b] = blocks.splice(from, 1);
        blocks.splice(targetBlockIndex, 0, b);
        return { ...l, blocks };
      }),
    })));
    this.#dragBlockIndex = null;
    this.autoSaveDraft();
  }

  saveCourse(): void {
    if (this.courseForm.invalid) {
      this.#toast.error('Informations du cours invalides', 'Completer titre, description, niveau et prix.');
      return;
    }
    if (this.modules().length === 0) {
      this.#toast.error('Ajoutez au moins un module', '');
      return;
    }
    this.saving.set(true);
    const raw = this.courseForm.getRawValue();
    this.#adminSvc.creerCours({
      titre: raw.title,
      description: raw.description,
      niveau: raw.level,
      prixFcfa: raw.price,
      seuilPaiement: 0.3,
    }).subscribe({
      next: () => {
        this.saving.set(false);
        this.#toast.success('Cours cree en brouillon', 'Modules, lecons et blocs gardes localement.');
        this.autoSaveDraft();
        this.#router.navigate(['/instructor']);
      },
      error: () => this.saving.set(false),
    });
  }

  asText(event: Event): string {
    return ((event.target as HTMLInputElement | HTMLTextAreaElement).value ?? '').trimStart();
  }
  asNumber(event: Event, fallback = 0): number {
    const n = Number((event.target as HTMLInputElement).value);
    return Number.isFinite(n) ? n : fallback;
  }

  private ensureSelectedLesson(): void {
    const p = this.selectedLessonPath();
    const ms = this.modules();
    if (!ms.length) {
      this.selectedLessonPath.set(null);
      return;
    }
    const mi = Math.min(p?.moduleIndex ?? 0, ms.length - 1);
    const lessons = ms[mi].lessons;
    if (!lessons.length) {
      this.selectedLessonPath.set(null);
      return;
    }
    const li = Math.min(p?.lessonIndex ?? 0, lessons.length - 1);
    this.selectedLessonPath.set({ moduleIndex: mi, lessonIndex: li });
  }

  private restoreDraft(): void {
    try {
      if (typeof window === 'undefined') return;
      const raw = localStorage.getItem('mn_instructor_course_draft');
      if (!raw) return;
      const parsed = JSON.parse(raw) as { form: unknown; modules: ModuleItem[] };
      if (parsed?.form) this.courseForm.patchValue(parsed.form as any);
      if (Array.isArray(parsed?.modules) && parsed.modules.length) this.modules.set(parsed.modules);
      this.ensureSelectedLesson();
    } catch {}
  }

  private autoSaveDraft(): void {
    try {
      if (typeof window === 'undefined') return;
      localStorage.setItem('mn_instructor_course_draft', JSON.stringify({
        form: this.courseForm.getRawValue(),
        modules: this.modules(),
      }));
    } catch {}
  }

  private uid(prefix: string): string {
    return `${prefix}-${Math.random().toString(36).slice(2, 9)}`;
  }
}
