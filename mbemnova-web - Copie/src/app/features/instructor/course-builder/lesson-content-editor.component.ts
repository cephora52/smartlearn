import { ChangeDetectionStrategy, Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { CourseBuilderDraftService, LessonBlock, LessonDraft } from './course-builder-draft.service';
import { AdminService } from '../../../core/services/admin.service';
import { ToastService } from '../../../core/services/toast.service';

@Component({
  selector: 'app-lesson-content-editor',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, RouterLink],
  template: `
<div class="min-h-screen bg-[#f8f9fb]">
  <header class="bg-white border-b border-slate-100">
    <div class="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
      <div>
        <h1 class="text-base font-black text-slate-900">Editeur de contenu lecon</h1>
        <p class="text-xs text-slate-500">{{ courseTitle() }} · {{ moduleTitle() }} · {{ lessonTitle() }}</p>
      </div>
      <div class="flex items-center gap-2">
        <a [routerLink]="['/instructor/cours', courseId(), 'modules']" class="px-3 py-2 text-xs rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50">Retour modules</a>
        <button (click)="validerCours()" [disabled]="saving()" class="px-3 py-2 text-xs font-bold rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-60">
          {{ saving() ? 'Enregistrement...' : 'Valider & Enregistrer le cours' }}
        </button>
      </div>
    </div>
  </header>

  <main class="max-w-7xl mx-auto px-4 py-6 grid grid-cols-1 xl:grid-cols-2 gap-4">
    <section class="bg-white border border-slate-100 rounded-xl p-4">
      <div class="flex items-center justify-between mb-3">
        <p class="text-sm font-bold text-slate-900">Blocs (repliables + drag & drop)</p>
        <select class="text-xs border border-slate-200 rounded-lg px-2 py-1" (change)="addBlock(($any($event.target)).value); ($any($event.target)).value=''">
          <option value="">+ Ajouter bloc</option>
          <option value="TEXT">Texte</option>
          <option value="CODE">Code</option>
          <option value="IMAGE">Image</option>
          <option value="VIDEO">Video</option>
          <option value="QUIZ">Quiz</option>
          <option value="FILE">Fichier</option>
          <option value="TIP">TIP</option>
        </select>
      </div>

      <div class="space-y-3">
        @for (b of blocks(); track b.id; let bi = $index) {
          <article class="border border-slate-200 rounded-lg p-3 bg-slate-50"
                   draggable="true"
                   (dragstart)="onBlockDragStart(bi)"
                   (dragover)="onDragOver($event)"
                   (drop)="onBlockDrop(bi)">
            <div class="flex items-center gap-2 mb-2">
              <button (click)="toggleBlock(b.id)" class="text-[11px] text-slate-500">{{ isBlockOpen(b.id) ? '−' : '+' }}</button>
              <span class="text-[10px] font-bold text-blue-600 bg-blue-50 px-2 py-1 rounded-full">{{ b.type }}</span>
              <span class="text-[10px] text-slate-400">::</span>
              <button (click)="removeBlock(bi)" class="ml-auto text-[11px] text-red-600 hover:text-red-700">Supprimer</button>
            </div>

            @if (isBlockOpen(b.id)) {
              <input class="w-full border border-slate-200 rounded-lg px-2 py-1.5 text-sm mb-2" [value]="b.title" (input)="setField(bi, 'title', text($event))" placeholder="Titre">
              <textarea rows="3" class="w-full border border-slate-200 rounded-lg px-2 py-1.5 text-sm" [value]="b.content" (input)="setField(bi, 'content', text($event))" placeholder="Contenu"></textarea>

              @if (b.type === 'IMAGE' || b.type === 'FILE') {
                <div class="grid grid-cols-1 md:grid-cols-2 gap-2 mt-2">
                  <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.content" (input)="setField(bi, 'content', text($event))" [placeholder]="b.type === 'IMAGE' ? 'URL image' : 'URL fichier'">
                  <input type="file" (change)="onFilePick($event, bi)" class="border border-slate-200 rounded-lg px-2 py-1 text-xs">
                </div>
                @if (b.fileName) { <p class="text-[11px] text-slate-500 mt-1">Upload: {{ b.fileName }}</p> }
              }

              @if (b.type === 'TIP') {
                <div class="mt-2">
                  <label class="text-[11px] text-slate-500">Couleur du TIP</label>
                  <select class="mt-1 border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.tipColor || 'blue'" (change)="setField(bi, 'tipColor', text($event))">
                    <option value="blue">Bleu</option>
                    <option value="green">Vert</option>
                    <option value="amber">Jaune</option>
                    <option value="red">Rouge</option>
                    <option value="slate">Gris</option>
                  </select>
                </div>
              }

              @if (b.type === 'QUIZ') {
                <div class="grid grid-cols-2 gap-2 mt-2">
                  <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionA || ''" (input)="setField(bi, 'optionA', text($event))" placeholder="Option A">
                  <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionB || ''" (input)="setField(bi, 'optionB', text($event))" placeholder="Option B">
                  <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionC || ''" (input)="setField(bi, 'optionC', text($event))" placeholder="Option C">
                  <input class="border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.optionD || ''" (input)="setField(bi, 'optionD', text($event))" placeholder="Option D">
                  <input class="col-span-2 border border-slate-200 rounded-lg px-2 py-1 text-xs" [value]="b.answer || ''" (input)="setField(bi, 'answer', text($event).toUpperCase())" placeholder="Bonne reponse (A/B/C/D)">
                </div>
              }
            }
          </article>
        }
      </div>
    </section>

    <section class="bg-white border border-slate-100 rounded-xl p-4">
      <p class="text-sm font-bold text-slate-900 mb-3">Apercu apprenant en temps reel</p>
      <div class="space-y-3">
        @for (b of blocks(); track b.id) {
          <article class="border border-slate-100 rounded-lg p-3">
            <h4 class="text-sm font-semibold text-slate-900 mb-1">{{ b.title || '(sans titre)' }}</h4>
            @switch (b.type) {
              @case ('TEXT') { <p class="text-sm text-slate-700 whitespace-pre-wrap">{{ b.content }}</p> }
              @case ('CODE') { <pre class="text-xs bg-slate-900 text-sky-200 rounded-lg p-3 overflow-auto">{{ b.content }}</pre> }
              @case ('IMAGE') { <img [src]="b.content || '/hero.png'" alt="image lesson" class="w-full max-h-56 object-cover rounded-lg bg-slate-100"> }
              @case ('VIDEO') { <iframe class="w-full aspect-video rounded-lg bg-slate-100" [src]="safeVideoUrl(b.content)" allowfullscreen></iframe> }
              @case ('FILE') { <a [href]="b.content" target="_blank" class="text-sm text-blue-600 underline">Ouvrir le fichier {{ b.fileName ? '(' + b.fileName + ')' : '' }}</a> }
              @case ('TIP') { <div [ngClass]="tipClass(b.tipColor)" class="px-3 py-2 text-sm border-l-4 rounded-r-lg">{{ b.content }}</div> }
              @case ('QUIZ') {
                <div class="text-sm text-slate-700 space-y-1">
                  <p>{{ b.content }}</p><p>A) {{ b.optionA || '-' }}</p><p>B) {{ b.optionB || '-' }}</p><p>C) {{ b.optionC || '-' }}</p><p>D) {{ b.optionD || '-' }}</p>
                </div>
              }
            }
          </article>
        }
      </div>
    </section>

    <!-- Barre de validation et navigation en bas de page -->
    <div class="col-span-1 xl:col-span-2 bg-white border border-slate-200 rounded-xl p-4 flex flex-col sm:flex-row items-center justify-between gap-4 mt-2">
      <div class="flex items-center gap-2 w-full sm:w-auto">
        <a [routerLink]="['/instructor/cours', courseId(), 'modules']" class="w-full sm:w-auto text-center px-4 py-2.5 text-xs font-semibold rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors">
          ← Retour aux modules
        </a>
        @if (prevLesson()) {
          <a [routerLink]="['/instructor/cours', courseId(), 'lecons', prevLesson()!.id, 'contenu']" class="w-full sm:w-auto text-center px-4 py-2.5 text-xs font-semibold rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors">
            Leçon précédente
          </a>
        }
      </div>

      <div class="flex flex-col sm:flex-row items-center gap-2 w-full sm:w-auto">
        @if (nextLesson()) {
          <a [routerLink]="['/instructor/cours', courseId(), 'lecons', nextLesson()!.id, 'contenu']" class="w-full sm:w-auto text-center px-4 py-2.5 text-xs font-semibold rounded-lg bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors">
            Leçon suivante →
          </a>
        }
        <button (click)="validerCours()" [disabled]="saving()" class="w-full sm:w-auto px-5 py-2.5 text-xs font-bold rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-60 shadow-sm transition-colors">
          {{ saving() ? 'Enregistrement...' : 'Valider & Enregistrer le cours' }}
        </button>
      </div>
    </div>
  </main>
</div>
  `,
})
export class LessonContentEditorComponent implements OnInit {
  readonly #route = inject(ActivatedRoute);
  readonly #router = inject(Router);
  readonly #draftSvc = inject(CourseBuilderDraftService);
  readonly #adminSvc = inject(AdminService);
  readonly #toast = inject(ToastService);

  readonly courseId = signal('');
  readonly lessonId = signal('');
  readonly saving = signal(false);
  readonly openBlocks = signal<Record<string, boolean>>({});
  readonly course = computed(() => this.#draftSvc.get(this.courseId()));
  readonly courseTitle = computed(() => this.course()?.title ?? 'Formation');
  readonly moduleIndex = computed(() => {
    const c = this.course(); const lid = this.lessonId();
    if (!c) return -1;
    return c.modules.findIndex(m => m.lessons.some(l => l.id === lid));
  });
  readonly lessonIndex = computed(() => {
    const c = this.course(); const mi = this.moduleIndex();
    if (!c || mi < 0) return -1;
    return c.modules[mi].lessons.findIndex(l => l.id === this.lessonId());
  });
  readonly moduleTitle = computed(() => {
    const c = this.course(); const mi = this.moduleIndex();
    return c && mi >= 0 ? c.modules[mi].title : 'Module';
  });
  readonly lessonTitle = computed(() => this.lesson()?.title ?? 'Lecon');
  readonly blocks = computed(() => this.lesson()?.blocks ?? []);

  readonly allLessons = computed(() => {
    const c = this.course();
    if (!c) return [];
    return c.modules.flatMap(m => m.lessons);
  });

  readonly lessonIndexInCourse = computed(() => {
    const lid = this.lessonId();
    return this.allLessons().findIndex(l => l.id === lid);
  });

  readonly prevLesson = computed(() => {
    const idx = this.lessonIndexInCourse();
    return idx > 0 ? this.allLessons()[idx - 1] : null;
  });

  readonly nextLesson = computed(() => {
    const idx = this.lessonIndexInCourse();
    const list = this.allLessons();
    return idx >= 0 && idx < list.length - 1 ? list[idx + 1] : null;
  });

  #dragBlockIndex: number | null = null;

  ngOnInit(): void {
    const cid = this.#route.snapshot.paramMap.get('id');
    const lid = this.#route.snapshot.paramMap.get('lessonId');
    if (!cid || !lid) return void this.#router.navigate(['/instructor']);
    this.courseId.set(cid); this.lessonId.set(lid);
    if (!this.course()) this.#draftSvc.getOrCreate(cid);
  }

  lesson(): LessonDraft | null {
    const c = this.course(); const mi = this.moduleIndex(); const li = this.lessonIndex();
    if (!c || mi < 0 || li < 0) return null;
    return c.modules[mi].lessons[li];
  }

  toggleBlock(id: string): void { this.openBlocks.update(v => ({ ...v, [id]: !v[id] })); }
  isBlockOpen(id: string): boolean { return this.openBlocks()[id] ?? true; }

  addBlock(type: string): void {
    if (!type) return;
    this.#patchLesson(l => ({ ...l, blocks: [...l.blocks, { id: this.uid('blk'), type: type as any, title: '', content: '', tipColor: 'blue', fileName: '' }] }));
  }
  removeBlock(index: number): void { this.#patchLesson(l => ({ ...l, blocks: l.blocks.filter((_, i) => i !== index) })); }
  setField(index: number, key: keyof LessonBlock, value: any): void {
    this.#patchLesson(l => ({ ...l, blocks: l.blocks.map((b, i) => i === index ? { ...b, [key]: value } : b) }));
  }
  onFilePick(event: Event, index: number): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    this.setField(index, 'fileName', file.name);
    this.setField(index, 'content', `/uploads/${file.name}`);
  }

  onDragOver(event: DragEvent): void { event.preventDefault(); }
  onBlockDragStart(index: number): void { this.#dragBlockIndex = index; }
  onBlockDrop(target: number): void {
    const from = this.#dragBlockIndex;
    if (from === null || from === target) return;
    this.#patchLesson(l => {
      const blocks = [...l.blocks];
      const [item] = blocks.splice(from, 1);
      blocks.splice(target, 0, item);
      return { ...l, blocks };
    });
    this.#dragBlockIndex = null;
  }

  text(event: Event): string { return (event.target as HTMLInputElement | HTMLTextAreaElement).value; }

  safeVideoUrl(url: string): string {
    if (!url) return '';
    if (url.includes('youtube.com/watch?v=')) return url.replace('watch?v=', 'embed/');
    if (url.includes('youtu.be/')) return `https://www.youtube.com/embed/${url.split('youtu.be/')[1]}`;
    return url;
  }

  tipClass(color: string | undefined): string {
    const map: Record<string, string> = {
      blue: 'bg-blue-50 border-blue-500 text-blue-800',
      green: 'bg-emerald-50 border-emerald-500 text-emerald-800',
      amber: 'bg-amber-50 border-amber-500 text-amber-800',
      red: 'bg-red-50 border-red-500 text-red-800',
      slate: 'bg-slate-100 border-slate-500 text-slate-800',
    };
    return map[color || 'blue'] || map['blue'];
  }

  #patchLesson(update: (lesson: LessonDraft) => LessonDraft): void {
    const c = this.course(); const mi = this.moduleIndex(); const li = this.lessonIndex();
    if (!c || mi < 0 || li < 0) return;
    const modules = c.modules.map((m, mIdx) => mIdx !== mi ? m : ({ ...m, lessons: m.lessons.map((l, lIdx) => lIdx !== li ? l : update(l)) }));
    this.#draftSvc.patch(c.id, { modules });
  }

  uid(prefix: string): string { return `${prefix}-${Math.random().toString(36).slice(2, 9)}`; }

  validerCours(): void {
    const c = this.course();
    if (!c) {
      this.#toast.error('Erreur', 'Cours introuvable.');
      return;
    }
    
    if (!c.title.trim() || c.title.length < 5) {
      this.#toast.error('Formulaire invalide', 'Le titre du cours doit faire au moins 5 caractères.');
      return;
    }
    if (!c.description.trim() || c.description.length < 10) {
      this.#toast.error('Formulaire invalide', 'La description courte doit faire au moins 10 caractères.');
      return;
    }
    if (c.modules.length === 0) {
      this.#toast.error('Formulaire invalide', 'Le cours doit contenir au moins un module.');
      return;
    }
    const hasLessons = c.modules.some(m => m.lessons && m.lessons.length > 0);
    if (!hasLessons) {
      this.#toast.error('Formulaire invalide', 'Le cours doit contenir au moins une leçon.');
      return;
    }

    this.saving.set(true);

    const req = {
      titre: c.title,
      descriptionCourte: c.description,
      descriptionLongue: c.about || c.description,
      niveau: c.level || 'DEBUTANT',
      categorieId: c.category || null,
      dureeTotaleMinutes: c.modules.reduce((acc, m) => acc + m.lessons.reduce((accL, l) => accL + (l.durationMinutes || 0), 0), 0),
      imageCouverture: c.bannerUrl || '',
      seuilPaiement: c.kind === 'COURS' ? 1.0 : (c.freePercent / 100),
      prixFcfa: c.kind === 'COURS' ? 0 : c.priceFcfa,
      objectifsApprentissage: c.whatYouLearn ? c.whatYouLearn.split('\n').filter((l: string) => l.trim()) : ['Apprendre ' + c.title],
      prerequis: c.prerequis || 'Aucun prérequis',
      publicCible: c.publicCible || 'Tout public',
      modules: c.modules.map((m, mIdx) => ({
        titre: m.title,
        description: m.description || '',
        ordre: mIdx + 1,
        xpBonus: 100,
        estGratuit: m.estGratuit ?? false,
        lecons: m.lessons.map((l, lIdx) => ({
          titre: l.title,
          descriptionCourte: l.shortDescription || '',
          ordre: lIdx + 1,
          dureeMinutes: l.durationMinutes || 10,
          xpValeur: 25,
          estPreview: l.estPreview ?? false,
          blocs: l.blocks && l.blocks.length > 0 ? l.blocks.map((b, bIdx) => ({
            typeBloc: this.#mapTypeBloc(b.type),
            ordre: bIdx + 1,
            contenuHtml: b.type === 'TEXT' ? b.content : null,
            urlImage: b.type === 'IMAGE' ? b.content : null,
            altImage: b.type === 'IMAGE' ? b.title : null,
            legendeImage: null,
            urlVideo: b.type === 'VIDEO' ? b.content : null,
            dureeVideoSec: null,
            urlPdf: b.type === 'FILE' ? b.content : null,
            nomPdf: b.type === 'FILE' ? b.fileName : null,
            langageCode: b.type === 'CODE' ? (b.language || 'javascript') : null,
            codeSource: b.type === 'CODE' ? b.content : null,
            typeCallout: b.type === 'TIP' ? (b.tipColor || 'INFO').toUpperCase() : null,
            texteCallout: b.type === 'TIP' ? b.content : null
          })) : [{
            typeBloc: 'TEXTE_HTML',
            ordre: 1,
            contenuHtml: 'Introduction de la leçon'
          }],
          qcm: null
        }))
      }))
    };

    this.#adminSvc.creerCours(req).subscribe({
      next: r => {
        this.saving.set(true);
        this.#toast.success('Félicitations !', 'Le cours complet a été enregistré avec succès en base de données.');
        setTimeout(() => {
          this.saving.set(false);
          this.#router.navigate(['/instructor']);
        }, 1500);
      },
      error: err => {
        this.saving.set(false);
        this.#toast.error('Erreur', 'Une erreur est survenue lors de la sauvegarde sur le serveur.');
      }
    });
  }

  #mapTypeBloc(type: string): string {
    switch (type) {
      case 'TEXT': return 'TEXTE_HTML';
      case 'CODE': return 'CODE';
      case 'IMAGE': return 'IMAGE';
      case 'VIDEO': return 'VIDEO';
      case 'FILE': return 'PDF_EMBED';
      case 'TIP': return 'CALLOUT';
      default: return 'TEXTE_HTML';
    }
  }
}
