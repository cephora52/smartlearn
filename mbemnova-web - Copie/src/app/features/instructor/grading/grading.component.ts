import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AssignmentService } from '../../../core/services/assignment.service';
import { ToastService }      from '../../../core/services/toast.service';

interface RenduVue {
  id: string; devoirId: string; apprenantId: string;
  prenomApprenant: string; titrDevoir: string;
  contenu: string; lienFichier: string | null;
  soumisLe: string; note: number | null; commentaire: string | null; corrigeLe: string | null;
}

const MOCK_RENDUS: RenduVue[] = [
  { id: 'r-001', devoirId: 'd-001', apprenantId: 'u-002', prenomApprenant: 'Diane K.', titrDevoir: 'TP1 — Page de profil responsive', contenu: 'Voici ma page HTML responsive avec flexbox et media queries. Lien GitHub : https://github.com/diane/profil-web - J\'ai utilisé CSS Grid pour la mise en page principale et Flexbox pour les composants. Le site est responsive à partir de 320px.', lienFichier: 'https://github.com/diane/profil-web', soumisLe: new Date(Date.now() - 86_400_000).toISOString(), note: null, commentaire: null, corrigeLe: null },
  { id: 'r-002', devoirId: 'd-001', apprenantId: 'u-003', prenomApprenant: 'Patrick N.', titrDevoir: 'TP1 — Page de profil responsive', contenu: 'J\'ai créé ma page avec CSS Grid. Voici le résultat : j\'ai eu du mal avec le responsive mais j\'ai réussi. La page s\'adapte sur mobile. J\'aurais aimé ajouter des animations mais je manque encore de pratique.', lienFichier: null, soumisLe: new Date(Date.now() - 2 * 86_400_000).toISOString(), note: null, commentaire: null, corrigeLe: null },
  { id: 'r-003', devoirId: 'd-001', apprenantId: 'u-004', prenomApprenant: 'Yvonne B.', titrDevoir: 'TP1 — Page de profil responsive', contenu: 'Page disponible sur : https://yvonne-portfolio.netlify.app Design moderne avec animations CSS et dark mode. Code propre et commenté.', lienFichier: 'https://yvonne-portfolio.netlify.app', soumisLe: new Date(Date.now() - 3 * 86_400_000).toISOString(), note: 18, commentaire: 'Excellent travail Yvonne ! Design soigné, responsive parfait et le dark mode est un plus. Continuez ainsi !', corrigeLe: new Date(Date.now() - 86_400_000).toISOString() },
];

@Component({
  selector: 'app-grading',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/instructor" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Correction des devoirs</h1>
        <span class="badge-amber">{{ enAttente() }} à corriger</span>
      </div>
    </div>
  </div>

  <div class="container py-6 max-w-3xl space-y-5">

    <!-- Filtre -->
    <div class="flex gap-2">
      @for (f of filtres; track f.value) {
        <button (click)="filtre.set(f.value)"
                [class]="'btn-sm rounded-lg px-4 py-2 text-sm font-medium transition-colors '
                         + (filtre() === f.value ? 'bg-blue-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50')">
          {{ f.label }}
          @if (f.value === 'attente') { <span class="ml-1 bg-amber-500 text-white text-xs rounded-full px-1.5">{{ enAttente() }}</span> }
        </button>
      }
    </div>

    @for (r of rendusAffiches(); track r.id; let i = $index) {
      <div class="card overflow-hidden animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">

        <!-- En-tête rendu -->
        <div class="p-5 border-b border-slate-100">
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold shrink-0">
              {{ r.prenomApprenant.charAt(0) }}
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap mb-0.5">
                <p class="font-semibold text-slate-900">{{ r.prenomApprenant }}</p>
                @if (r.note !== null) {
                  <span [class]="noteBadge(r.note)">{{ r.note }}/20 — {{ noteLabel(r.note) }}</span>
                } @else {
                  <span class="badge-amber">En attente de correction</span>
                }
              </div>
              <p class="text-xs text-slate-400">
                {{ r.titrDevoir }} · Soumis {{ timeAgo(r.soumisLe) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Contenu rendu -->
        <div class="p-5">
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Rendu de l'apprenant</p>
          <div class="bg-slate-50 rounded-xl p-4 mb-4">
            <p class="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">{{ r.contenu }}</p>
            @if (r.lienFichier) {
              <a [href]="r.lienFichier" target="_blank" rel="noopener"
                 class="inline-flex items-center gap-1.5 mt-3 text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                Voir le fichier / projet
              </a>
            }
          </div>

          <!-- Correction existante -->
          @if (r.note !== null) {
            <div class="bg-green-50 border border-green-200 rounded-xl p-4">
              <div class="flex items-center justify-between mb-2">
                <p class="text-sm font-bold text-green-900">Votre correction</p>
                <span [class]="noteBadge(r.note)">{{ r.note }}/20</span>
              </div>
              <div class="progress mb-2">
                <div class="progress-bar"
                     [class]="r.note >= 14 ? 'bg-green-500' : r.note >= 10 ? 'bg-amber-400' : 'bg-red-400'"
                     [style.width.%]="(r.note / 20) * 100"></div>
              </div>
              @if (r.commentaire) {
                <p class="text-sm text-green-800 italic">"{{ r.commentaire }}"</p>
              }
            </div>
          }

          <!-- Formulaire correction -->
          @if (r.note === null) {
            <div class="border border-slate-200 rounded-xl p-4">
              <p class="text-sm font-semibold text-slate-900 mb-4">Corriger ce rendu</p>

              @if (activeGrade() === r.id) {
                <form [formGroup]="gradeForm" (ngSubmit)="submitGrade(r)" novalidate class="space-y-4">

                  <!-- Note -->
                  <div>
                    <label class="label">
                      Note /20
                      <span class="ml-2 text-lg font-black"
                            [class]="noteColor(gradeForm.get('note')?.value ?? 0)">
                        {{ gradeForm.get('note')?.value ?? 0 }}/20
                      </span>
                    </label>
                    <input type="range" formControlName="note"
                           min="0" max="20" step="0.5"
                           class="w-full accent-blue-600">
                    <div class="flex justify-between text-xs text-slate-400 mt-1">
                      <span>0</span>
                      <span [class]="noteColor(gradeForm.get('note')?.value ?? 0)">
                        {{ noteLabel(gradeForm.get('note')?.value ?? 0) }}
                      </span>
                      <span>20</span>
                    </div>
                  </div>

                  <!-- Commentaire -->
                  <div>
                    <label for="commentaire-{{r.id}}" class="label">Commentaire pour l'apprenant</label>
                    <textarea [id]="'commentaire-' + r.id" formControlName="commentaire"
                              rows="3"
                              placeholder="Points forts, axes d'amélioration, encouragements…"
                              [class]="'input resize-none ' + (gradeSubmitted && gradeForm.get('commentaire')?.invalid ? 'input-error' : '')">
                    </textarea>
                    @if (gradeSubmitted && gradeForm.get('commentaire')?.hasError('required')) {
                      <p class="field-error" role="alert">Commentaire requis — aidez l'apprenant à progresser.</p>
                    }
                  </div>

                  <div class="flex gap-3">
                    <button type="button" (click)="activeGrade.set(null)" class="btn-secondary flex-1">Annuler</button>
                    <button type="submit" [disabled]="grading()" class="btn-primary flex-1">
                      @if (grading()) {
                        <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                      }
                      Valider la correction
                    </button>
                  </div>
                </form>
              } @else {
                <button (click)="startGrade(r.id)"
                        class="btn-primary w-full justify-center">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                  Commencer la correction
                </button>
              }
            </div>
          }
        </div>
      </div>
    }
  </div>
</div>
  `,
})
export class GradingComponent {
  readonly #assignSvc = inject(AssignmentService);
  readonly #toast     = inject(ToastService);
  readonly #fb        = inject(FormBuilder);

  readonly rendus     = signal<RenduVue[]>(MOCK_RENDUS);
  readonly filtre     = signal<'tous' | 'attente' | 'corriges'>('attente');
  readonly activeGrade= signal<string | null>(null);
  readonly grading    = signal(false);
  gradeSubmitted      = false;

  readonly enAttente    = computed(() => this.rendus().filter(r => r.note === null).length);
  readonly rendusAffiches = computed(() => {
    const f = this.filtre();
    if (f === 'attente')  return this.rendus().filter(r => r.note === null);
    if (f === 'corriges') return this.rendus().filter(r => r.note !== null);
    return this.rendus();
  });

  readonly filtres = [
    { value: 'attente',  label: 'À corriger' },
    { value: 'corriges', label: 'Corrigés' },
    { value: 'tous',     label: 'Tous' },
  ] as const;

  readonly gradeForm = this.#fb.nonNullable.group({
    note:        [12],
    commentaire: ['', Validators.required],
  });

  startGrade(id: string): void {
    this.activeGrade.set(id);
    this.gradeForm.reset({ note: 12, commentaire: '' });
    this.gradeSubmitted = false;
  }

  submitGrade(r: RenduVue): void {
    this.gradeSubmitted = true;
    if (this.gradeForm.invalid) return;
    this.grading.set(true);

    const { note, commentaire } = this.gradeForm.getRawValue();

    this.#assignSvc.corriger(r.id, {
      renduId: r.id, note, commentaire,
    }).subscribe({
      next: () => {
        this.grading.set(false);
        this.activeGrade.set(null);
        this.rendus.update(list => list.map(rv =>
          rv.id === r.id ? { ...rv, note, commentaire, corrigeLe: new Date().toISOString() } : rv
        ));
        this.#toast.success(
          `Correction enregistrée — ${note}/20`,
          `${r.prenomApprenant} sera notifié(e) par notification.`
        );
      },
      error: () => { this.grading.set(false); },
    });
  }

  noteBadge(note: number): string {
    if (note >= 16) return 'badge-green'; if (note >= 12) return 'badge-blue';
    if (note >= 10) return 'badge-amber'; return 'badge-red';
  }
  noteLabel(note: number): string {
    if (note >= 16) return 'Excellent'; if (note >= 14) return 'Très bien';
    if (note >= 12) return 'Bien'; if (note >= 10) return 'Passable'; return 'Insuffisant';
  }
  noteColor(note: number): string {
    if (note >= 14) return 'text-green-600'; if (note >= 10) return 'text-amber-600'; return 'text-red-600';
  }
  timeAgo(iso: string): string {
    const d = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
    const h = Math.floor((Date.now() - new Date(iso).getTime()) / 3_600_000);
    if (d >= 1) return `il y a ${d}j`; if (h >= 1) return `il y a ${h}h`; return "récemment";
  }
}
