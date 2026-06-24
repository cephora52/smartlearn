import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AssignmentService } from '../../../core/services/assignment.service';
import { ToastService }      from '../../../core/services/toast.service';
import type { DevoirSuiviResponse, RenduResponse } from '../../../core/models';
import { MOCK_DEVOIRS_SUIVI } from '../../../core/services/mock.data';

@Component({
  selector: 'app-assignments',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3 mb-1">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors"
           aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
          Mes devoirs
        </h1>
      </div>
      <p class="text-slate-500 text-sm ml-8">
        Travaux pratiques envoyés par vos formateurs.
      </p>
    </div>
  </div>

  <div class="container py-6 space-y-5">

    <!-- Skeleton -->
    @if (loading()) {
      @for (_ of [1,2]; track $index) {
        <div class="card p-5 space-y-3">
          <div class="flex gap-3">
            <div class="shimmer w-12 h-12 rounded-xl shrink-0"></div>
            <div class="flex-1 space-y-2">
              <div class="shimmer h-4 rounded w-3/4"></div>
              <div class="shimmer h-3 rounded w-1/2"></div>
            </div>
          </div>
          <div class="shimmer h-10 rounded-lg w-full"></div>
        </div>
      }
    }

    <!-- Empty state -->
    @if (!loading() && devoirs().length === 0) {
      <div class="card p-14 text-center">
        <div class="flex justify-center mb-5">
          <svg width="100" height="100" viewBox="0 0 100 100" fill="none" aria-hidden="true">
            <circle cx="50" cy="50" r="50" fill="#f0fdf4"/>
            <rect x="25" y="20" width="50" height="60" rx="8" fill="#bbf7d0"/>
            <rect x="32" y="32" width="36" height="4" rx="2" fill="#16a34a"/>
            <rect x="32" y="42" width="28" height="4" rx="2" fill="#86efac"/>
            <rect x="32" y="52" width="32" height="4" rx="2" fill="#86efac"/>
            <rect x="32" y="62" width="20" height="4" rx="2" fill="#86efac"/>
            <circle cx="72" cy="72" r="18" fill="#2563eb"/>
            <path d="M64 72l6 6 12-12" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Aucun devoir reçu</h2>
        <p class="text-sm text-slate-500 max-w-xs mx-auto leading-relaxed">
          Vos formateurs publieront des devoirs ici au fil de votre formation.
        </p>
      </div>
    }

    <!-- Liste devoirs -->
    @if (!loading()) {
      @for (d of devoirs(); track d.devoir.id; let i = $index) {
        <div class="card overflow-hidden animate-fade-up"
             [style]="'animation-delay:' + (i * 60) + 'ms'">

          <!-- En-tête devoir -->
          <div class="p-5">
            <div class="flex items-start gap-4">

              <!-- Icône état devoir -->
              <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 '
                            + devoirIconBg(d)" aria-hidden="true">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                     [attr.stroke]="devoirIconColor(d)" stroke-width="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                  @if (d.rendu?.note !== null && d.rendu?.note !== undefined) {
                    <polyline points="9 15 11 17 15 13"/>
                  } @else {
                    <line x1="16" y1="13" x2="8" y2="13"/>
                    <line x1="16" y1="17" x2="8" y2="17"/>
                    <polyline points="10 9 9 9 8 9"/>
                  }
                </svg>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-start gap-2 flex-wrap mb-1">
                  <h2 class="font-bold text-slate-900 leading-snug">{{ d.devoir.titre }}</h2>
                  <!-- Badge statut -->
                  @if (d.rendu?.note !== null && d.rendu?.note !== undefined) {
                    <span class="badge-green shrink-0">Corrigé — {{ d.rendu!.note }}/20</span>
                  } @else if (d.rendu) {
                    <span class="badge-blue shrink-0">Soumis</span>
                  } @else if (isOverdue(d)) {
                    <span class="badge-red shrink-0">En retard</span>
                  } @else if (isDueSoon(d)) {
                    <span class="badge-amber shrink-0">
                      Bientôt — {{ daysLeft(d) }}j
                    </span>
                  } @else {
                    <span class="badge-slate shrink-0">À faire</span>
                  }
                </div>

                <!-- Date limite -->
                <div class="flex items-center gap-1.5 text-xs text-slate-400">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  <span [class]="isOverdue(d) && !d.rendu ? 'text-red-500 font-medium' : ''">
                    Remise : {{ formatDate(d.devoir.dateLimite) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Consignes -->
            <div class="mt-4 bg-slate-50 rounded-xl p-4">
              <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Consignes</p>
              <p class="text-sm text-slate-700 leading-relaxed whitespace-pre-line">{{ d.devoir.consignes }}</p>
            
            </div>

            <!-- Résultat correction (S23) -->
            @if (d.rendu?.note !== null && d.rendu?.note !== undefined) {
              <div class="mt-4 border border-green-200 bg-green-50 rounded-xl p-4">
                <div class="flex items-center justify-between mb-3">
                  <p class="text-sm font-bold text-green-900">Correction du formateur</p>
                  <div class="flex items-center gap-2">
                    <!-- Note visuelle -->
                    <div class="flex items-center gap-1">
                      <span class="text-2xl font-black"
                            [class]="noteColor(d.rendu!.note!)">
                        {{ d.rendu!.note }}
                      </span>
                      <span class="text-slate-400 text-sm">/20</span>
                    </div>
                    <!-- Badge appréciation -->
                    <span [class]="noteBadge(d.rendu!.note!)">
                      {{ noteLabel(d.rendu!.note!) }}
                    </span>
                  </div>
                </div>

                <!-- Barre note -->
                <div class="progress mb-3">
                  <div class="progress-bar"
                       [class]="d.rendu!.note! >= 14 ? 'bg-green-500' : d.rendu!.note! >= 10 ? 'bg-amber-400' : 'bg-red-400'"
                       [style.width.%]="(d.rendu!.note! / 20) * 100">
                  </div>
                </div>

                @if (d.rendu!.commentaire) {
                  <p class="text-sm text-green-800 leading-relaxed italic">
                    "{{ d.rendu!.commentaire }}"
                  </p>
                }
                <p class="text-xs text-green-600 mt-2">
                  Corrigé le {{ formatDate(d.rendu!.corrigeLe ?? '') }}
                </p>
              </div>
            }

            <!-- Rendu soumis (en attente correction) -->
            @if (d.rendu && (d.rendu.note === null || d.rendu.note === undefined)) {
              <div class="mt-4 border border-blue-200 bg-blue-50 rounded-xl p-4">
                <div class="flex items-center gap-2 mb-2">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  <p class="text-sm font-semibold text-blue-900">Rendu soumis</p>
                </div>
                <p class="text-xs text-blue-600">
                  Soumis le {{ formatDate(d.rendu.soumisLe) }} — En attente de correction.
                </p>
              </div>
            }
          </div>

          <!-- Footer action -->
          <div class="border-t border-slate-100 px-5 py-3 bg-white flex items-center justify-between">
            @if (!d.rendu && !isOverdue(d)) {
              <button (click)="openSubmit(d)"
                      class="btn-primary btn-sm">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                Soumettre mon rendu
              </button>
            } @else if (!d.rendu && isOverdue(d)) {
              <span class="text-sm text-red-500 font-medium">
                Délai dépassé — contactez votre formateur
              </span>
            } @else if (d.rendu && !d.rendu.note) {
              <span class="text-sm text-slate-500 italic">En attente de correction</span>
            } @else {
              <span class="text-sm text-green-600 font-medium">
                ✓ Corrigé
              </span>
            }
          </div>
        </div>
      }
    }
  </div>

  <!-- ── MODAL SOUMISSION (S11) ──────────────────────────── -->
  @if (showSubmit()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="submit-title">

      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm"
           (click)="closeSubmit()"></div>

      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg
                  animate-scale-in overflow-hidden">

        <!-- En-tête -->
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="17 8 12 3 7 8"/>
                <line x1="12" y1="3" x2="12" y2="15"/>
              </svg>
            </div>
            <div class="flex-1 min-w-0">
              <h2 id="submit-title" class="font-bold text-slate-900 leading-snug truncate">
              @if (activeDevoir()) { {{ activeDevoir()!.devoir.titre }} }
              </h2>
              <p class="text-xs text-slate-500">Soumission de votre rendu</p>
            </div>
            <button (click)="closeSubmit()"
                    class="btn-icon text-slate-400 hover:text-slate-600 shrink-0"
                    aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- Corps -->
        <div class="p-6">
          <form [formGroup]="submitForm" (ngSubmit)="confirmSubmit()" novalidate class="space-y-4">

            <!-- Contenu texte -->
            <div>
              <label for="contenu" class="label">
                Votre rendu
                <span class="text-slate-400 font-normal">(texte, lien GitHub, description…)</span>
              </label>
              <textarea id="contenu" formControlName="contenu"
                        rows="6"
                        placeholder="Décrivez votre travail, collez un lien vers votre code, expliquez vos choix techniques…"
                        [class]="'input resize-none ' + (subSubmitted && submitForm.get('contenu')?.invalid ? 'input-error' : '')">
              </textarea>
              @if (subSubmitted && submitForm.get('contenu')?.hasError('required')) {
                <p class="field-error" role="alert">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  Contenu requis
                </p>
              }
              @if (subSubmitted && submitForm.get('contenu')?.hasError('minlength')) {
                <p class="field-error" role="alert">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  20 caractères minimum
                </p>
              }
            </div>

            <!-- Lien fichier optionnel -->
            <div>
              <label for="lienFichier" class="label">
                Lien vers votre fichier
                <span class="text-slate-400 font-normal">(optionnel — GitHub, Drive, etc.)</span>
              </label>
              <input id="lienFichier" type="url" formControlName="lienFichier"
                     placeholder="https://github.com/votre-repo ou https://drive.google.com/…"
                     class="input">
            </div>

            <!-- Avertissement avant soumission -->
            <div class="bg-amber-50 border border-amber-200 rounded-xl p-3 flex gap-2.5">
              <svg class="shrink-0 mt-0.5" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true">
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              <p class="text-xs text-amber-800 leading-relaxed">
                Une fois soumis, votre rendu ne peut pas être modifié. Relisez bien avant de confirmer.
              </p>
            </div>

            <!-- Boutons -->
            <div class="flex gap-3 pt-1">
              <button type="button" (click)="closeSubmit()"
                      class="btn-secondary flex-1">
                Annuler
              </button>
              <button type="submit" [disabled]="submitting()"
                      class="btn-primary flex-1">
                @if (submitting()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  Envoi…
                } @else {
                  Soumettre le rendu
                }
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  }

</div>
  `,
})
export class AssignmentsComponent implements OnInit {
  readonly #assignSvc = inject(AssignmentService);
  readonly #toast     = inject(ToastService);
  readonly #fb        = inject(FormBuilder);

  readonly devoirs     = signal<DevoirSuiviResponse[]>(MOCK_DEVOIRS_SUIVI);
  readonly loading     = signal(true);
  readonly showSubmit  = signal(false);
  readonly activeDevoir= signal<DevoirSuiviResponse | null>(null);
  readonly submitting  = signal(false);
  subSubmitted         = false;

  readonly submitForm = this.#fb.nonNullable.group({
    contenu:     ['', [Validators.required, Validators.minLength(20)]],
    lienFichier: [''],
  });

  ngOnInit(): void {
    this.#assignSvc.getMes().subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) this.devoirs.set(r.data.content);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  openSubmit(d: DevoirSuiviResponse): void {
    this.activeDevoir.set(d);
    this.submitForm.reset();
    this.subSubmitted = false;
    this.showSubmit.set(true);
  }

  closeSubmit(): void {
    this.showSubmit.set(false);
    this.subSubmitted = false;
  }

confirmSubmit(): void {
  this.subSubmitted = true;
  if (this.submitForm.invalid || !this.activeDevoir()) return;
  this.submitting.set(true);

  const { contenu, lienFichier } = this.submitForm.getRawValue();

  this.#assignSvc.soumettre({
    devoirId:    this.activeDevoir()!.devoir.id,  // ← .devoir.id
    contenu,
    lienFichier: lienFichier || undefined,
  }).subscribe({
    next: () => {
      this.submitting.set(false);
      this.closeSubmit();
      const devoir = this.activeDevoir()!;
      const rendu: RenduResponse = {
        id: 'r-new', devoirId: devoir.devoir.id, apprenantId: '',  // ← .devoir.id
        contenu, lienFichier: lienFichier || null,
        soumisLe: new Date().toISOString(),
        note: null, commentaire: null, corrigeLe: null,
      };
      this.devoirs.update(list => list.map(d =>
        d.devoir.id === devoir.devoir.id ? { ...d, rendu } : d  // ← .devoir.id
      ));
      this.#toast.success('Rendu soumis !', 'Votre formateur recevra une notification.');
    },
    error: () => { this.submitting.set(false); },
  });
}

// Helpers — utiliser d.devoir.dateLimite
isOverdue(d: DevoirSuiviResponse): boolean {
  return new Date(d.devoir.dateLimite) < new Date();
}

isDueSoon(d: DevoirSuiviResponse): boolean {
  const diff = new Date(d.devoir.dateLimite).getTime() - Date.now();
  return diff > 0 && diff < 3 * 86_400_000;
}

daysLeft(d: DevoirSuiviResponse): number {
  return Math.ceil((new Date(d.devoir.dateLimite).getTime() - Date.now()) / 86_400_000);
}

  // ── Helpers ────────────────────────────────────────────
  // isOverdue(d: DevoirSuiviResponse): boolean {
  //   return new Date(d.devoir.dateLimite) < new Date();
  // }

  // isDueSoon(d: DevoirSuiviResponse): boolean {
  //   const diff = new Date(d.devoir.dateLimite).getTime() - Date.now();
  //   return diff > 0 && diff < 3 * 86_400_000;
  // }

  // daysLeft(d: DevoirSuiviResponse): number {
  //   return Math.ceil((new Date(d.devoir.dateLimite).getTime() - Date.now()) / 86_400_000);
  // }

  formatDate(iso: string): string {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('fr-FR', {
      day: 'numeric', month: 'long', year: 'numeric',
    });
  }

  devoirIconBg(d: DevoirSuiviResponse): string {
    if (d.rendu?.note !== null && d.rendu?.note !== undefined) return 'bg-green-100';
    if (d.rendu)           return 'bg-blue-100';
    if (this.isOverdue(d)) return 'bg-red-100';
    if (this.isDueSoon(d)) return 'bg-amber-100';
    return 'bg-slate-100';
  }

  devoirIconColor(d: DevoirSuiviResponse): string {
    if (d.rendu?.note !== null && d.rendu?.note !== undefined) return '#16a34a';
    if (d.rendu)           return '#2563eb';
    if (this.isOverdue(d)) return '#dc2626';
    if (this.isDueSoon(d)) return '#d97706';
    return '#64748b';
  }

  noteColor(note: number): string {
    if (note >= 16) return 'text-green-600';
    if (note >= 12) return 'text-blue-600';
    if (note >= 10) return 'text-amber-600';
    return 'text-red-600';
  }

  noteBadge(note: number): string {
    if (note >= 16) return 'badge-green';
    if (note >= 12) return 'badge-blue';
    if (note >= 10) return 'badge-amber';
    return 'badge-red';
  }

  noteLabel(note: number): string {
    if (note >= 16) return 'Excellent';
    if (note >= 14) return 'Très bien';
    if (note >= 12) return 'Bien';
    if (note >= 10) return 'Passable';
    return 'Insuffisant';
  }
}
