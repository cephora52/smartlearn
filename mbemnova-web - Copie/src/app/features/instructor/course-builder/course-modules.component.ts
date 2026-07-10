import { ChangeDetectionStrategy, Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { CourseBuilderDraftService, LessonDraft, ModuleDraft } from './course-builder-draft.service';

@Component({
  selector: 'app-course-modules',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, RouterLink],
  template: `
<div class="min-h-screen bg-[#f8f9fb]">
  <header class="bg-white border-b border-slate-100">
    <div class="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
      <div>
        <h1 class="text-base font-black text-slate-900">Modules et lecons</h1>
        <p class="text-xs text-slate-500">Etape 2/3 · structure + apercu global</p>
      </div>
      <div class="flex items-center gap-2">
        <a [routerLink]="['/instructor/cours', courseId(), 'editer']" class="px-3 py-2 text-xs rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50">Infos (Etape 1)</a>
        <button (click)="addModule()" class="px-3 py-2 text-xs rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200">+ Module</button>
        @if (firstLessonId()) {
          <a [routerLink]="['/instructor/cours', courseId(), 'lecons', firstLessonId(), 'contenu']" class="px-3 py-2 text-xs rounded-lg bg-blue-600 text-white hover:bg-blue-700 font-bold">Continuer (Etape 3)</a>
        } @else {
          <button disabled class="px-3 py-2 text-xs rounded-lg bg-slate-100 text-slate-400 cursor-not-allowed border border-slate-200" title="Ajoutez au moins une leçon pour continuer">Continuer (Etape 3)</button>
        }
      </div>
    </div>
  </header>

  <main class="max-w-6xl mx-auto px-4 py-6 grid grid-cols-1 xl:grid-cols-2 gap-4">
    <section class="bg-white border border-slate-100 rounded-xl p-5">
      <div class="mb-4">
        <p class="text-sm font-bold text-slate-900">{{ courseTitle() || 'Sans titre' }}</p>
        <p class="text-xs text-slate-500">Tu peux plier/deplier module et lecon pour eviter surcharge.</p>
      </div>

      <div class="space-y-3">
        @for (m of modules(); track m.id; let mi = $index) {
          <section class="border border-slate-200 rounded-xl p-3 bg-slate-50/50"
                   draggable="true"
                   (dragstart)="onModuleDragStart(mi)"
                   (dragover)="onDragOver($event)"
                   (drop)="onModuleDrop(mi)">
            <div class="flex items-center gap-2">
              <button (click)="toggleModule(m.id)" class="text-xs text-slate-500">{{ isModuleOpen(m.id) ? '−' : '+' }}</button>
              <span class="text-xs text-slate-400">::</span>
              <input class="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm" [value]="m.title" (input)="renameModule(mi, text($event))">
              <button (click)="removeModule(mi)" class="text-xs text-red-600 hover:text-red-700">Supprimer</button>
            </div>

            @if (isModuleOpen(m.id)) {
              <div class="mt-3 pl-3 border-l-2 border-slate-200 space-y-2">
                <div class="flex items-center justify-between">
                  <p class="text-xs font-semibold text-slate-600">Lecons</p>
                  <button (click)="addLesson(mi)" class="text-xs font-semibold text-blue-600 hover:text-blue-700">+ Lecon</button>
                </div>
                @for (l of m.lessons; track l.id; let li = $index) {
                  <article class="bg-white border border-slate-200 rounded-lg p-3"
                           draggable="true"
                           (dragstart)="onLessonDragStart(mi, li)"
                           (dragover)="onDragOver($event)"
                           (drop)="onLessonDrop(mi, li)">
                    <div class="grid grid-cols-1 md:grid-cols-12 gap-2">
                      <button (click)="toggleLesson(l.id)" class="md:col-span-1 text-xs text-slate-500">{{ isLessonOpen(l.id) ? '−' : '+' }}</button>
                      <input class="md:col-span-4 border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="l.title" (input)="renameLesson(mi, li, text($event))">
                      <input type="number" min="1" class="md:col-span-2 border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="l.durationMinutes" (input)="setDuration(mi, li, number($event))">
                      <input class="md:col-span-3 border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="l.shortDescription" (input)="setDesc(mi, li, text($event))">
                      <div class="md:col-span-2 flex items-center justify-end gap-2">
                        <a [routerLink]="['/instructor/cours', courseId(), 'lecons', l.id, 'contenu']" class="text-[11px] font-semibold text-blue-600 hover:text-blue-700">Contenu</a>
                        <button (click)="removeLesson(mi, li)" class="text-[11px] text-red-600 hover:text-red-700">X</button>
                      </div>
                    </div>
                    @if (isLessonOpen(l.id)) {
                      <p class="text-xs text-slate-500 mt-2">{{ l.shortDescription || 'Pas de description' }}</p>
                    }
                  </article>
                }
              </div>
            }
          </section>
        }
      </div>

      <!-- Etape 3 CTA -->
      <div class="mt-6 flex items-center justify-between bg-blue-50 border border-blue-100 rounded-xl p-4">
        <div>
          <h4 class="text-xs font-bold text-slate-900">Structure prete ?</h4>
          <p class="text-[11px] text-slate-600">Passez a la redaction du contenu de vos lecons.</p>
        </div>
        @if (firstLessonId()) {
          <a [routerLink]="['/instructor/cours', courseId(), 'lecons', firstLessonId(), 'contenu']" class="px-3 py-2 text-xs font-bold rounded-lg bg-blue-600 text-white hover:bg-blue-700 shadow-sm">
            Passer a l'etape 3 : Remplir le contenu
          </a>
        } @else {
          <span class="text-[10px] text-amber-600 font-semibold bg-amber-50 px-2 py-1.5 rounded-lg border border-amber-200">
            Ajoutez au moins une lecon pour commencer a rediger
          </span>
        }
      </div>
    </section>

    <section class="bg-white border border-slate-100 rounded-xl p-5">
      <p class="text-sm font-bold text-slate-900 mb-3">Apercu global (presentation finale)</p>
      <div class="space-y-3">
        @for (m of modules(); track m.id) {
          <article class="border border-slate-200 rounded-xl p-3">
            <h3 class="font-semibold text-slate-900">{{ m.title }}</h3>
            <ul class="mt-2 space-y-1">
              @for (l of m.lessons; track l.id) {
                <li class="text-sm text-slate-700 flex items-center justify-between">
                  <span>{{ l.title }}</span>
                  <span class="text-xs text-slate-500">{{ l.durationMinutes }} min · {{ l.blocks.length }} blocs</span>
                </li>
              }
            </ul>
          </article>
        }
      </div>
    </section>
  </main>
</div>
  `,
})
export class CourseModulesComponent implements OnInit {
  readonly #route = inject(ActivatedRoute);
  readonly #router = inject(Router);
  readonly #draftSvc = inject(CourseBuilderDraftService);
  readonly courseId = signal('');
  readonly course = computed(() => this.#draftSvc.get(this.courseId()));
  readonly modules = computed(() => this.course()?.modules ?? []);
  readonly firstLessonId = computed(() => {
    const mods = this.modules();
    for (const m of mods) {
      if (m.lessons && m.lessons.length > 0) {
        return m.lessons[0].id;
      }
    }
    return null;
  });
  readonly courseTitle = computed(() => this.course()?.title ?? '');
  readonly openModules = signal<Record<string, boolean>>({});
  readonly openLessons = signal<Record<string, boolean>>({});
  #dragModule: number | null = null;
  #dragLesson: { mi: number; li: number } | null = null;

  ngOnInit(): void {
    const id = this.#route.snapshot.paramMap.get('id');
    if (!id) return void this.#router.navigate(['/instructor/cours/nouveau']);
    this.courseId.set(id);
    if (!this.course()) this.#draftSvc.getOrCreate(id);
  }

  toggleModule(id: string): void { this.openModules.update(v => ({ ...v, [id]: !v[id] })); }
  isModuleOpen(id: string): boolean { return this.openModules()[id] ?? true; }
  toggleLesson(id: string): void { this.openLessons.update(v => ({ ...v, [id]: !v[id] })); }
  isLessonOpen(id: string): boolean { return this.openLessons()[id] ?? false; }

  addModule(): void {
    const c = this.course(); if (!c) return;
    const next: ModuleDraft = { id: this.uid('mod'), title: `Module ${c.modules.length + 1}`, sortOrder: c.modules.length + 1, lessons: [] };
    this.#draftSvc.patch(c.id, { modules: [...c.modules, next] });
  }
  removeModule(mi: number): void {
    const c = this.course(); if (!c) return;
    this.#draftSvc.patch(c.id, { modules: c.modules.filter((_, i) => i !== mi).map((m, i) => ({ ...m, sortOrder: i + 1 })) });
  }
  renameModule(mi: number, title: string): void {
    const c = this.course(); if (!c) return;
    this.#draftSvc.patch(c.id, { modules: c.modules.map((m, i) => i === mi ? { ...m, title } : m) });
  }
  addLesson(mi: number): void {
    const c = this.course(); if (!c) return;
    const modules = c.modules.map((m, i) => i !== mi ? m : ({
      ...m,
      lessons: [...m.lessons, { id: this.uid('lesson'), title: `Lecon ${m.lessons.length + 1}`, durationMinutes: 10, shortDescription: '', sortOrder: m.lessons.length + 1, blocks: [] }],
    }));
    this.#draftSvc.patch(c.id, { modules });
  }
  removeLesson(mi: number, li: number): void { this.#patchLessonList(mi, lessons => lessons.filter((_, i) => i !== li)); }
  renameLesson(mi: number, li: number, title: string): void { this.#patchLesson(mi, li, l => ({ ...l, title })); }
  setDuration(mi: number, li: number, v: number): void { this.#patchLesson(mi, li, l => ({ ...l, durationMinutes: Math.max(1, v || 1) })); }
  setDesc(mi: number, li: number, shortDescription: string): void { this.#patchLesson(mi, li, l => ({ ...l, shortDescription })); }

  onDragOver(event: DragEvent): void { event.preventDefault(); }
  onModuleDragStart(mi: number): void { this.#dragModule = mi; }
  onModuleDrop(target: number): void {
    const from = this.#dragModule; const c = this.course();
    if (!c || from === null || from === target) return;
    const modules = [...c.modules]; const [x] = modules.splice(from, 1); modules.splice(target, 0, x);
    this.#draftSvc.patch(c.id, { modules: modules.map((m, i) => ({ ...m, sortOrder: i + 1 })) }); this.#dragModule = null;
  }
  onLessonDragStart(mi: number, li: number): void { this.#dragLesson = { mi, li }; }
  onLessonDrop(mi: number, target: number): void {
    const drag = this.#dragLesson; const c = this.course();
    if (!c || !drag || drag.mi !== mi || drag.li === target) return;
    const modules = c.modules.map((m, i) => {
      if (i !== mi) return m;
      const lessons = [...m.lessons]; const [x] = lessons.splice(drag.li, 1); lessons.splice(target, 0, x);
      return { ...m, lessons: lessons.map((l, j) => ({ ...l, sortOrder: j + 1 })) };
    });
    this.#draftSvc.patch(c.id, { modules }); this.#dragLesson = null;
  }

  text(event: Event): string { return (event.target as HTMLInputElement).value; }
  number(event: Event): number { return Number((event.target as HTMLInputElement).value); }

  #patchLesson(mi: number, li: number, patch: (lesson: LessonDraft) => LessonDraft): void {
    const c = this.course(); if (!c) return;
    this.#draftSvc.patch(c.id, {
      modules: c.modules.map((m, i) => i !== mi ? m : ({ ...m, lessons: m.lessons.map((l, j) => j !== li ? l : patch(l)) })),
    });
  }
  #patchLessonList(mi: number, patch: (lessons: LessonDraft[]) => LessonDraft[]): void {
    const c = this.course(); if (!c) return;
    this.#draftSvc.patch(c.id, {
      modules: c.modules.map((m, i) => i !== mi ? m : ({ ...m, lessons: patch(m.lessons).map((l, j) => ({ ...l, sortOrder: j + 1 })) })),
    });
  }
  uid(prefix: string): string { return `${prefix}-${Math.random().toString(36).slice(2, 9)}`; }
}

