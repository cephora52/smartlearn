import { ChangeDetectionStrategy, Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CourseBuilderDraftService, LessonDraft, ModuleDraft } from './course-builder-draft.service';
import { AdminService } from '../../../core/services/admin.service';
import { ToastService } from '../../../core/services/toast.service';

@Component({
  selector: 'app-course-modules',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, RouterLink, FormsModule],
  styles: [`
    [contenteditable]:empty:before {
      content: attr(placeholder);
      color: #94a3b8;
    }
    .prose ul { list-style-type: disc !important; margin-left: 1.5rem !important; margin-top: 0.5rem !important; margin-bottom: 0.5rem !important; display: block !important; }
    .prose ol { list-style-type: decimal !important; margin-left: 1.5rem !important; margin-top: 0.5rem !important; margin-bottom: 0.5rem !important; display: block !important; }
    .prose li { display: list-item !important; margin-bottom: 0.25rem; }
    .prose h2 { font-size: 1.25rem; font-weight: 700; margin-top: 1rem; margin-bottom: 0.5rem; color: #0f172a; }
    .prose h3 { font-size: 1.1rem; font-weight: 700; margin-top: 0.8rem; margin-bottom: 0.4rem; color: #0f172a; }
    .prose h4 { font-size: 1rem; font-weight: 700; margin-top: 0.6rem; margin-bottom: 0.3rem; color: #0f172a; }
    .prose p { margin-bottom: 0.8rem; color: #334155; }
    .prose a { color: #2563eb; text-decoration: underline; font-weight: 500; }
  `],
  template: `
<div class="min-h-screen bg-[#f8f9fb]">
  <header class="bg-white border-b border-slate-100 sticky top-0 z-50 shadow-sm">
    <div class="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
      <div>
        <h1 class="text-base font-black text-slate-900">Création des leçons</h1>
        <p class="text-xs text-slate-500">Étape 2/2 · Ajoutez et configurez vos leçons</p>
      </div>
      <div class="flex items-center gap-2">
        <a [routerLink]="['/instructor/cours', courseId(), 'editer']" 
           class="px-4 py-2 text-xs rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors font-medium">
          ← Retour Infos (Étape 1)
        </a>
        <button (click)="validerCours()" 
                [disabled]="saving() || lessons().length === 0" 
                class="px-4 py-2 text-xs font-bold rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:bg-slate-200 disabled:text-slate-400 disabled:cursor-not-allowed transition-colors shadow-sm">
          {{ saving() ? 'Enregistrement...' : 'Enregistrer le cours' }}
        </button>
      </div>
    </div>
  </header>

  <main class="max-w-4xl mx-auto px-4 py-8">
    <!-- Liste des Leçons -->
    <div class="space-y-6">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h2 class="text-lg font-bold text-slate-900">Leçons de la formation</h2>
          <p class="text-xs text-slate-500">Configurez le titre, le type de média et le contenu de chaque leçon.</p>
        </div>
        <button (click)="addLesson()" 
                class="px-4 py-2 text-xs font-semibold rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 transition-colors shadow-sm">
          + Ajouter une leçon
        </button>
      </div>

      <!-- Empty State -->
      @if (lessons().length === 0) {
        <div class="bg-white border border-dashed border-slate-300 rounded-2xl p-12 text-center">
          <div class="text-4xl mb-3">📚</div>
          <h3 class="font-bold text-slate-900 text-base mb-1">Aucune leçon pour l'instant</h3>
          <p class="text-slate-500 text-xs mb-6">Commencez par ajouter votre première leçon en cliquant sur le bouton ci-dessous.</p>
          <button (click)="addLesson()" class="btn-primary btn-sm">
            Ajouter ma première leçon
          </button>
        </div>
      }

      <!-- Liste Cartes -->
      @for (l of lessons(); track l.id; let idx = $index) {
        <section class="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-4 relative hover:border-blue-200 transition-all">
          <div class="flex items-center justify-between border-b border-slate-100 pb-3">
            <div class="flex items-center gap-3">
              <span class="w-6 h-6 rounded-full bg-blue-50 text-blue-600 text-xs font-bold flex items-center justify-center">
                {{ idx + 1 }}
              </span>
              <input class="font-bold text-slate-950 border-b border-transparent focus:border-blue-400 focus:outline-none text-sm w-64 md:w-96 px-1"
                     [value]="l.title"
                     (input)="onTitleChange(idx, text($event))"
                     placeholder="Titre de la leçon...">
            </div>
            <button (click)="deleteLesson(idx)" class="text-xs text-red-500 hover:text-red-700 font-medium">
              Supprimer
            </button>
          </div>

          <!-- Configuration Leçon -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="text-xs font-semibold text-slate-600 block mb-1">Durée (minutes)</label>
              <input type="number" min="1" class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                     [value]="l.durationMinutes || 10"
                     (input)="onDurationChange(idx, number($event))">
            </div>
            <div>
              <label class="text-xs font-semibold text-slate-600 block mb-1">XP récompense</label>
              <input type="number" min="5" class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                     [value]="xpRewardValue(l)"
                     (input)="onXpChange(idx, number($event))">
            </div>
            <div>
              <label class="text-xs font-semibold text-slate-600 block mb-1">Type de contenu</label>
              <select [value]="typeContenuValue(l)"
                      (change)="onTypeChanged(idx, typeValue($event))"
                      class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-blue-500">
                <option value="TEXTE">Texte Riche (WYSIWYG)</option>
                <option value="VIDEO">Vidéo</option>
                <option value="PDF">Document PDF</option>
              </select>
            </div>
          </div>

          <!-- Contenu dynamique basé sur le type -->
          <div class="bg-slate-50 p-4 rounded-xl border border-slate-200">
            @if (typeContenuValue(l) === 'TEXTE') {
              <div class="space-y-2">
                <label class="text-xs font-semibold text-slate-700 block">Éditeur de texte riche (WYSIWYG)</label>
                
                <div class="border border-slate-200 rounded-lg bg-white overflow-hidden shadow-sm">
                  <!-- Barre d'outils -->
                  <div class="bg-slate-50 border-b border-slate-200 px-3 py-2 flex flex-wrap gap-1.5 items-center">
                    <!-- Format bloc -->
                    <select (change)="execEditorCommand('formatBlock', selectValue($event))" 
                            class="text-xs border border-slate-200 rounded px-2 py-1 bg-white text-slate-700 focus:outline-none">
                      <option value="<p>">Paragraphe</option>
                      <option value="<h2>">Titre 2</option>
                      <option value="<h3>">Titre 3</option>
                      <option value="<h4>">Titre 4</option>
                    </select>
                    
                    <span class="w-[1px] h-4 bg-slate-200 mx-1"></span>

                    <!-- Styles -->
                    <button type="button" (click)="execEditorCommand('bold')" title="Gras"
                            class="w-6 h-6 rounded hover:bg-slate-200 text-slate-800 text-xs font-black transition-colors flex items-center justify-center">
                      G
                    </button>
                    <button type="button" (click)="execEditorCommand('italic')" title="Italique"
                            class="w-6 h-6 rounded hover:bg-slate-200 text-slate-800 text-xs italic transition-colors flex items-center justify-center font-serif">
                      I
                    </button>
                    <button type="button" (click)="execEditorCommand('underline')" title="Souligné"
                            class="w-6 h-6 rounded hover:bg-slate-200 text-slate-800 text-xs underline transition-colors flex items-center justify-center">
                      S
                    </button>

                    <span class="w-[1px] h-4 bg-slate-200 mx-1"></span>

                    <!-- Listes -->
                    <button type="button" (click)="execEditorCommand('insertUnorderedList')" title="Liste à puces"
                            class="px-1.5 py-0.5 rounded hover:bg-slate-200 text-slate-800 text-xs transition-colors font-medium">
                      • Puces
                    </button>
                    <button type="button" (click)="execEditorCommand('insertOrderedList')" title="Liste ordonnée"
                            class="px-1.5 py-0.5 rounded hover:bg-slate-200 text-slate-800 text-xs transition-colors font-medium">
                      1. Numéro
                    </button>

                    <span class="w-[1px] h-4 bg-slate-200 mx-1"></span>

                    <!-- Alignement -->
                    <button type="button" (click)="execEditorCommand('justifyLeft')" title="Gauche"
                            class="w-6 h-6 rounded hover:bg-slate-200 text-slate-800 text-xs transition-colors flex items-center justify-center">
                      ←
                    </button>
                    <button type="button" (click)="execEditorCommand('justifyCenter')" title="Centrer"
                            class="w-6 h-6 rounded hover:bg-slate-200 text-slate-800 text-xs transition-colors flex items-center justify-center">
                      ↔
                    </button>
                    <button type="button" (click)="execEditorCommand('justifyRight')" title="Droite"
                            class="w-6 h-6 rounded hover:bg-slate-200 text-slate-800 text-xs transition-colors flex items-center justify-center">
                      →
                    </button>

                    <span class="w-[1px] h-4 bg-slate-200 mx-1"></span>

                    <!-- Lien -->
                    <button type="button" (click)="execEditorLink()" title="Lien"
                            class="px-1.5 py-0.5 rounded hover:bg-slate-200 text-blue-700 hover:text-blue-800 text-xs font-bold transition-colors">
                      Lien
                    </button>
                  </div>

                  <!-- Zone éditable -->
                  <div [id]="'editor-' + idx"
                       contenteditable="true"
                       [innerHTML]="getInitialContent(l.id, l.blocks[0]?.content)"
                       (blur)="onEditorBlur(idx, $event)"
                       (input)="onEditorInput(idx, $event)"
                       placeholder="Rédigez le contenu enrichi ici..."
                       class="p-4 min-h-[150px] max-h-[400px] overflow-y-auto text-sm font-sans focus:outline-none bg-white text-slate-800 leading-relaxed prose prose-sm max-w-none">
                  </div>
                </div>
              </div>
            }

            @if (typeContenuValue(l) === 'VIDEO') {
              <div class="space-y-3">
                <label class="text-xs font-semibold text-slate-700 block mb-1">Upload du fichier vidéo (MP4, WebM)</label>
                <input type="file" 
                       accept="video/mp4,video/webm" 
                       (change)="onFileUpload($event, idx)" 
                       class="w-full text-xs text-slate-600">
                @if (l.blocks[0]?.content) {
                  <p class="text-xs text-emerald-600 font-bold">✓ Vidéo active : {{ l.blocks[0]?.content }}</p>
                } @else {
                  <p class="text-xs text-slate-400">Aucune vidéo sélectionnée.</p>
                }
                @if (isLessonUploading(idx)) {
                  <p class="text-xs text-blue-600 font-medium animate-pulse">Chargement de la vidéo sur le serveur en cours...</p>
                }
              </div>
            }

            @if (typeContenuValue(l) === 'PDF') {
              <div class="space-y-3">
                <label class="text-xs font-semibold text-slate-700 block mb-1">Upload du document PDF</label>
                <input type="file" 
                       accept="application/pdf" 
                       (change)="onFileUpload($event, idx)" 
                       class="w-full text-xs text-slate-600">
                @if (l.blocks[0]?.content) {
                  <p class="text-xs text-emerald-600 font-bold">✓ PDF actif : {{ l.blocks[0]?.fileName || l.blocks[0]?.content }}</p>
                } @else {
                  <p class="text-xs text-slate-400">Aucun document PDF sélectionné.</p>
                }
                @if (isLessonUploading(idx)) {
                  <p class="text-xs text-blue-600 font-medium animate-pulse">Chargement du PDF sur le serveur en cours...</p>
                }
              </div>
            }
          </div>
        </section>
      }
    </div>

    <!-- Actions du Bas -->
    <div class="mt-8 flex items-center justify-between border-t border-slate-100 pt-6">
      <button (click)="addLesson()" 
              class="px-4 py-2 text-xs font-bold rounded-lg border border-slate-200 bg-white text-slate-700 hover:bg-slate-50 transition-colors shadow-sm">
        + Ajouter une leçon
      </button>
      <button (click)="validerCours()" 
              [disabled]="saving() || lessons().length === 0" 
              class="px-6 py-2.5 text-xs font-bold rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:bg-slate-200 disabled:text-slate-400 disabled:cursor-not-allowed transition-colors shadow-sm">
        {{ saving() ? 'Enregistrement...' : 'Enregistrer le cours' }}
      </button>
    </div>
  </main>
</div>
  `,
})
export class CourseModulesComponent implements OnInit {
  readonly #route = inject(ActivatedRoute);
  readonly #router = inject(Router);
  readonly #draftSvc = inject(CourseBuilderDraftService);
  readonly #adminSvc = inject(AdminService);
  readonly #toast = inject(ToastService);

  readonly courseId = signal('');
  readonly saving = signal(false);

  readonly draft = computed(() => this.#draftSvc.courses()[this.courseId()]);
  readonly lessons = computed(() => this.draft()?.modules[0]?.lessons ?? []);

  editorContents = new Map<string, string>();

  getInitialContent(lessonId: string, currentVal: string | null | undefined): string {
    if (!this.editorContents.has(lessonId)) {
      this.editorContents.set(lessonId, currentVal || '<p><br></p>');
    }
    return this.editorContents.get(lessonId)!;
  }

  ngOnInit(): void {
    const id = this.#route.snapshot.paramMap.get('id');
    if (id) {
      this.courseId.set(id);
      const c = this.#draftSvc.getOrCreate(id);
      if (c.modules.length === 0) {
        const defaultMod: ModuleDraft = {
          id: 'mod-principal',
          title: 'Module Principal',
          sortOrder: 1,
          lessons: []
        };
        this.#draftSvc.patch(id, { modules: [defaultMod] });
      }
    }
  }

  text(event: Event): string { 
    return (event.target as HTMLInputElement | HTMLTextAreaElement).value; 
  }

  number(event: Event): number { 
    return Number((event.target as HTMLInputElement).value) || 0; 
  }

  typeValue(event: Event): 'TEXTE' | 'VIDEO' | 'PDF' {
    return (event.target as HTMLSelectElement).value as 'TEXTE' | 'VIDEO' | 'PDF';
  }

  selectValue(event: Event): string {
    return (event.target as HTMLSelectElement).value;
  }

  typeContenuValue(l: LessonDraft): 'TEXTE' | 'VIDEO' | 'PDF' {
    return (l as any).typeContenu || 'TEXTE';
  }

  xpRewardValue(l: LessonDraft): number {
    return (l as any).xpReward || 25;
  }

  isLessonUploading(idx: number): boolean {
    const l = this.lessons()[idx];
    return !!(l as any)?.isUploading;
  }

  addLesson(): void {
    const c = this.draft();
    if (!c) return;
    const currentLessons = c.modules[0]?.lessons ?? [];
    const newLesson: LessonDraft = {
      id: 'lesson-' + Date.now(),
      title: 'Leçon ' + (currentLessons.length + 1),
      durationMinutes: 10,
      shortDescription: '',
      sortOrder: currentLessons.length + 1,
      blocks: [{ id: 'block-' + Date.now(), type: 'TEXT', content: '<p><br></p>', title: '' }],
    };
    (newLesson as any).typeContenu = 'TEXTE';
    (newLesson as any).xpReward = 25;

    const updatedModules = [{
      ...c.modules[0],
      lessons: [...currentLessons, newLesson]
    }];
    this.#draftSvc.patch(c.id, { modules: updatedModules });
  }

  deleteLesson(index: number): void {
    const c = this.draft();
    if (!c) return;
    const currentLessons = c.modules[0]?.lessons ?? [];
    const updatedLessons = currentLessons.filter((_, i) => i !== index).map((l, i) => ({ ...l, sortOrder: i + 1 }));
    const updatedModules = [{
      ...c.modules[0],
      lessons: updatedLessons
    }];
    this.#draftSvc.patch(c.id, { modules: updatedModules });
  }

  onTitleChange(index: number, val: string): void {
    const c = this.draft();
    if (!c) return;
    const currentLessons = [...(c.modules[0]?.lessons ?? [])];
    const lesson = { ...currentLessons[index] };
    lesson.title = val;
    currentLessons[index] = lesson;
    this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: currentLessons }] });
  }

  onDurationChange(index: number, val: number): void {
    const c = this.draft();
    if (!c) return;
    const currentLessons = [...(c.modules[0]?.lessons ?? [])];
    const lesson = { ...currentLessons[index] };
    lesson.durationMinutes = val;
    currentLessons[index] = lesson;
    this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: currentLessons }] });
  }

  onXpChange(index: number, val: number): void {
    const c = this.draft();
    if (!c) return;
    const currentLessons = [...(c.modules[0]?.lessons ?? [])];
    const lesson = { ...currentLessons[index] };
    (lesson as any).xpReward = val;
    currentLessons[index] = lesson;
    this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: currentLessons }] });
  }

  onTypeChanged(index: number, newType: 'TEXTE' | 'VIDEO' | 'PDF'): void {
    const c = this.draft();
    if (!c) return;
    const currentLessons = [...(c.modules[0]?.lessons ?? [])];
    const lesson = { ...currentLessons[index] };
    (lesson as any).typeContenu = newType;
    
    if (newType === 'TEXTE') {
      lesson.blocks = [{ id: 'block-' + Date.now(), type: 'TEXT', content: '<p><br></p>', title: '' }];
    } else if (newType === 'VIDEO') {
      lesson.blocks = [{ id: 'block-' + Date.now(), type: 'VIDEO', content: '', title: '' }];
    } else if (newType === 'PDF') {
      lesson.blocks = [{ id: 'block-' + Date.now(), type: 'FILE', content: '', fileName: '', title: '' }];
    }
    
    currentLessons[index] = lesson;
    this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: currentLessons }] });
  }

  execEditorCommand(command: string, value: string = ''): void {
    document.execCommand(command, false, value);
  }

  execEditorLink(): void {
    const url = prompt('Entrez l\'URL du lien:');
    if (url) {
      document.execCommand('createLink', false, url);
    }
  }

  onEditorInput(index: number, event: Event): void {
    const html = (event.target as HTMLElement).innerHTML;
    const lessonId = this.lessons()[index]?.id;
    if (lessonId) {
      this.editorContents.set(lessonId, html);
    }
  }

  onEditorBlur(index: number, event: Event): void {
    const html = (event.target as HTMLElement).innerHTML;
    const c = this.draft();
    if (!c) return;
    const lessonId = this.lessons()[index]?.id;
    if (lessonId) {
      this.editorContents.set(lessonId, html);
    }
    const currentLessons = [...(c.modules[0]?.lessons ?? [])];
    const lesson = { ...currentLessons[index] };
    lesson.blocks = [{ id: lesson.blocks[0]?.id || 'block-' + Date.now(), type: 'TEXT', content: html, title: '' }];
    currentLessons[index] = lesson;
    this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: currentLessons }] });
  }

  onFileUpload(event: Event, index: number): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    
    const c = this.draft();
    const remoteId = c?.remoteId;
    if (!remoteId) {
      this.#toast.error('Erreur', 'Veuillez d\'abord enregistrer le brouillon API à l\'étape 1.');
      return;
    }
    
    const currentLessons = [...(c.modules[0]?.lessons ?? [])];
    const lesson = { ...currentLessons[index] };
    (lesson as any).isUploading = true;
    currentLessons[index] = lesson;
    this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: currentLessons }] });
    
    if ((lesson as any).typeContenu === 'PDF') {
      this.#adminSvc.uploadPdf(remoteId, file).subscribe({
        next: r => {
          if (r.success && r.data) {
            const updated = [...(this.draft()?.modules[0]?.lessons ?? [])];
            const l = { ...updated[index] };
            (l as any).isUploading = false;
            l.blocks = [{ id: 'block-' + Date.now(), type: 'FILE', content: r.data.urlPdf, fileName: file.name, title: '' }];
            updated[index] = l;
            this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: updated }] });
            this.#toast.success('Succès', 'Document PDF enregistré.');
          }
        },
        error: () => {
          const updated = [...(this.draft()?.modules[0]?.lessons ?? [])];
          (updated[index] as any).isUploading = false;
          this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: updated }] });
          this.#toast.error('Erreur', 'Échec de l\'upload du PDF.');
        }
      });
    } else if ((lesson as any).typeContenu === 'VIDEO') {
      this.#adminSvc.uploadVideo(remoteId, file).subscribe({
        next: r => {
          if (r.success && r.data) {
            const updated = [...(this.draft()?.modules[0]?.lessons ?? [])];
            const l = { ...updated[index] };
            (l as any).isUploading = false;
            l.blocks = [{ id: 'block-' + Date.now(), type: 'VIDEO', content: r.data.urlVideo, title: '' }];
            updated[index] = l;
            this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: updated }] });
            this.#toast.success('Succès', 'Vidéo enregistrée.');
          }
        },
        error: () => {
          const updated = [...(this.draft()?.modules[0]?.lessons ?? [])];
          (updated[index] as any).isUploading = false;
          this.#draftSvc.patch(c.id, { modules: [{ ...c.modules[0], lessons: updated }] });
          this.#toast.error('Erreur', 'Échec de l\'upload de la vidéo.');
        }
      });
    }
  }

  validerCours(): void {
    const c = this.draft();
    if (!c) {
      this.#toast.error('Erreur', 'Cours introuvable.');
      return;
    }
    
    if (!c.title.trim()) {
      this.#toast.error('Formulaire invalide', 'Le titre du cours est requis.');
      return;
    }
    if (!c.description.trim()) {
      this.#toast.error('Formulaire invalide', 'La description courte est requise.');
      return;
    }
    if (this.lessons().length === 0) {
      this.#toast.error('Formulaire invalide', 'Veuillez ajouter au moins une leçon.');
      return;
    }

    const hasEmptyLessonTitle = this.lessons().some(l => !l.title || !l.title.trim());
    if (hasEmptyLessonTitle) {
      this.#toast.error('Formulaire invalide', 'Toutes les leçons doivent avoir un titre.');
      return;
    }

    const isUploading = this.lessons().some(l => (l as any).isUploading);
    if (isUploading) {
      this.#toast.error('En cours', 'Veuillez attendre la fin du chargement des fichiers.');
      return;
    }

    this.saving.set(true);

    const req = {
      titre: c.title,
      descriptionCourte: c.description,
      descriptionLongue: c.description,
      niveau: c.level || 'DEBUTANT',
      categorieId: c.category || '44444444-4444-4444-4444-444444444444',
      dureeTotaleMinutes: this.lessons().reduce((acc, l) => acc + (l.durationMinutes || 0), 0),
      imageCouverture: c.bannerUrl || '',
      seuilPaiement: c.kind === 'COURS' ? 1.0 : (c.freePercent / 100),
      prixFcfa: c.kind === 'COURS' ? 0 : c.priceFcfa,
      objectifsApprentissage: ['Apprendre ' + c.title],
      prerequis: 'Aucun prérequis',
      publicCible: 'Tout public',
      lecons: this.lessons().map((l, lIdx) => {
        let blocks = l.blocks;
        const typeContenu = (l as any).typeContenu || 'TEXTE';
        if (typeContenu === 'TEXTE') {
          const editorEl = document.getElementById(`editor-${lIdx}`);
          const content = editorEl ? editorEl.innerHTML : (l.blocks[0]?.content || '');
          blocks = [{ id: l.blocks[0]?.id || 'block-' + Date.now(), type: 'TEXT', content, title: '' }];
        }
        return {
          titre: l.title,
          descriptionCourte: '',
          ordre: lIdx + 1,
          dureeMinutes: l.durationMinutes || 10,
          xpValeur: (l as any).xpReward || 25,
          estPreview: l.estPreview ?? false,
          blocs: blocks && blocks.length > 0 ? blocks.map((b, bIdx) => ({
            typeBloc: b.type === 'TEXT' ? 'TEXTE_HTML' : (b.type === 'VIDEO' ? 'VIDEO' : 'PDF_EMBED'),
            ordre: bIdx + 1,
            contenuHtml: b.type === 'TEXT' ? b.content : null,
            urlImage: null,
            altImage: null,
            legendeImage: null,
            urlVideo: b.type === 'VIDEO' ? b.content : null,
            dureeVideoSec: null,
            urlPdf: b.type === 'FILE' ? b.content : null,
            nomPdf: b.type === 'FILE' ? b.fileName : null,
            langageCode: null,
            codeSource: null,
            typeCallout: null,
            texteCallout: null
          })) : [{
            typeBloc: 'TEXTE_HTML',
            ordre: 1,
            contenuHtml: 'Introduction de la leçon'
          }],
          qcm: null
        };
      })
    };

    this.#adminSvc.creerCours(req).subscribe({
      next: (res: any) => {
        if (res && res.success === false) {
          this.saving.set(false);
          this.#toast.error('Erreur', res.message || 'Une erreur est survenue lors de l\'enregistrement.');
          return;
        }
        try {
          this.#draftSvc.remove(c.id);
          this.#toast.success('Succès', 'Cours enregistré avec succès');
        } catch (e) {
          console.error('Draft clear error:', e);
        }
        this.saving.set(true);
        this.#router.navigate(['/instructor']).then(
          () => this.saving.set(false),
          () => this.saving.set(false)
        );
      },
      error: err => {
        this.saving.set(false);
        const errMsg = err.error?.error?.details?.join(', ') || err.error?.message || 'Une erreur est survenue lors de l\'enregistrement.';
        this.#toast.error('Erreur', errMsg);
      }
    });
  }
}
