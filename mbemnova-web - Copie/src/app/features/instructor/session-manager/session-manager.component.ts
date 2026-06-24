import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { SessionService } from '../../../core/services/session.service';
import { ToastService }   from '../../../core/services/toast.service';
import type { SessionResponse, Modalite } from '../../../core/models';
import { MOCK_SESSIONS, MOCK_COURS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-session-manager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <a routerLink="/instructor" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
          </a>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Gestion des sessions</h1>
        </div>
        <button (click)="showCreate.set(true)" class="btn-primary shrink-0">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Nouvelle session
        </button>
      </div>
    </div>
  </div>

  <div class="container py-6 space-y-4">

    @if (loading()) {
      @for (_ of [1,2]; track $index) {
        <div class="card p-5">
          <div class="shimmer h-16 rounded-xl mb-3"></div>
          <div class="shimmer h-8 rounded-lg w-1/3"></div>
        </div>
      }
    }

    @if (!loading() && sessions().length === 0) {
      <div class="card p-12 text-center">
        <div class="text-4xl mb-3" aria-hidden="true">📅</div>
        <p class="font-semibold text-slate-900 mb-1">Aucune session créée</p>
        <p class="text-sm text-slate-500 mb-5">Planifiez votre première session avec des apprenants.</p>
        <button (click)="showCreate.set(true)" class="btn-primary">Créer une session</button>
      </div>
    }

    @for (s of sessions(); track s.id; let i = $index) {
      <div class="card p-5 animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">
        <div class="flex items-start gap-4">
          <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0 '
                        + modaliteBg(s.modalite)" aria-hidden="true">
            {{ modaliteEmoji(s.modalite) }}
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap mb-1">
              <h2 class="font-bold text-slate-900">{{ s.titre }}</h2>
              <span [class]="modaliteBadge(s.modalite)">{{ s.modalite }}</span>
              @if (!s.estActive) { <span class="badge-slate">Inactive</span> }
            </div>
            <div class="flex flex-wrap gap-3 text-xs text-slate-400 mb-3">
              <span>Du {{ formatDate(s.dateDebut) }} au {{ formatDate(s.dateFin) }}</span>
              <span>{{ s.nbInscrits }}/{{ s.capaciteMax }} inscrits</span>
              @if (s.lieu) { <span>📍 {{ s.lieu }}</span> }
              @if (s.lienReunion) {
                <a [href]="s.lienReunion" target="_blank" rel="noopener"
                   class="text-blue-600 hover:text-blue-700 transition-colors">
                  Lien Meet
                </a>
              }
            </div>
            <!-- Barre places -->
            <div class="flex items-center gap-2 mb-3">
              <div class="flex-1 progress h-1.5">
                <div class="progress-bar"
                     [class]="s.placesRestantes === 0 ? 'bg-red-400' : 'bg-blue-500'"
                     [style.width.%]="(s.nbInscrits / s.capaciteMax) * 100"></div>
              </div>
              <span class="text-xs font-medium"
                    [class]="s.placesRestantes === 0 ? 'text-red-600' : 'text-slate-500'">
                {{ s.placesRestantes === 0 ? 'Complet' : s.placesRestantes + ' places libres' }}
              </span>
            </div>
            <div class="flex gap-2">
              <a routerLink="/instructor/correction" class="btn-secondary btn-sm">
                Voir les rendus
              </a>
            </div>
          </div>
        </div>
      </div>
    }
  </div>

  <!-- Modal création session -->
  @if (showCreate()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="session-title">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" (click)="showCreate.set(false)"></div>

      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg animate-scale-in overflow-hidden">
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center justify-between">
            <h2 id="session-title" class="font-bold text-slate-900">Nouvelle session</h2>
            <button (click)="showCreate.set(false)" class="btn-icon text-slate-400 hover:text-slate-600" aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
        </div>

        <div class="p-6">
          <form [formGroup]="sessionForm" (ngSubmit)="createSession()" novalidate class="space-y-4">

            <!-- Cours associé -->
            <div>
              <label for="coursId" class="label">Cours associé <span class="text-red-500">*</span></label>
              <select id="coursId" formControlName="coursId" class="input">
                <option value="">Sélectionnez un cours</option>
                @for (c of cours; track c.id) {
                  <option [value]="c.id">{{ c.titre }}</option>
                }
              </select>
            </div>

            <!-- Titre -->
            <div>
              <label for="sTitre" class="label">Titre de la session <span class="text-red-500">*</span></label>
              <input id="sTitre" type="text" formControlName="titre"
                     placeholder="Ex : Dev Web — Session Juillet 2025"
                     class="input">
            </div>

            <!-- Modalité -->
            <div>
              <label class="label">Modalité <span class="text-red-500">*</span></label>
              <div class="grid grid-cols-3 gap-2">
                @for (m of modalites; track m.value) {
                  <button type="button" (click)="sessionForm.patchValue({ modalite: m.value })"
                          [class]="'flex flex-col items-center gap-1 p-3 rounded-xl border-2 transition-all text-sm '
                                   + (sessionForm.get('modalite')?.value === m.value
                                   ? 'border-blue-500 bg-blue-50 text-blue-700 font-semibold'
                                   : 'border-slate-200 hover:border-blue-300')">
                    <span class="text-xl" aria-hidden="true">{{ m.icon }}</span>
                    {{ m.label }}
                  </button>
                }
              </div>
            </div>

            <!-- Dates -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label for="dateDebut" class="label">Date de début <span class="text-red-500">*</span></label>
                <input id="dateDebut" type="date" formControlName="dateDebut" class="input">
              </div>
              <div>
                <label for="dateFin" class="label">Date de fin <span class="text-red-500">*</span></label>
                <input id="dateFin" type="date" formControlName="dateFin" class="input">
              </div>
            </div>

            <!-- Capacité -->
            <div>
              <label for="capacite" class="label">Capacité maximum</label>
              <input id="capacite" type="number" formControlName="capaciteMax"
                     min="1" max="100" class="input">
            </div>

            <!-- Lieu ou lien Meet -->
            @if (sessionForm.get('modalite')?.value === 'PRESENTIEL' || sessionForm.get('modalite')?.value === 'HYBRIDE') {
              <div>
                <label for="lieu" class="label">Lieu</label>
                <input id="lieu" type="text" formControlName="lieu"
                       placeholder="Centre MbemNova, Akwa — Douala" class="input">
              </div>
            }
            @if (sessionForm.get('modalite')?.value === 'MEET' || sessionForm.get('modalite')?.value === 'HYBRIDE') {
              <div>
                <label for="lienMeet" class="label">Lien Google Meet</label>
                <input id="lienMeet" type="url" formControlName="lienReunion"
                       placeholder="https://meet.google.com/..." class="input">
              </div>
            }

            <div class="flex gap-3 pt-2">
              <button type="button" (click)="showCreate.set(false)" class="btn-secondary flex-1">Annuler</button>
              <button type="submit" [disabled]="creating()" class="btn-primary flex-1">
                @if (creating()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                }
                Créer la session
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
export class SessionManagerComponent implements OnInit {
  readonly #sessionSvc = inject(SessionService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly sessions   = signal<SessionResponse[]>(MOCK_SESSIONS);
  readonly loading    = signal(true);
  readonly showCreate = signal(false);
  readonly creating   = signal(false);

  readonly cours = MOCK_COURS.slice(0, 4);

  readonly modalites = [
    { value: 'MEET',       label: 'En ligne', icon: '💻' },
    { value: 'PRESENTIEL', label: 'Présentiel', icon: '📍' },
    { value: 'HYBRIDE',    label: 'Hybride', icon: '🔀' },
  ];

  readonly sessionForm = this.#fb.nonNullable.group({
    coursId:      ['', Validators.required],
    titre:        ['', Validators.required],
    modalite:     ['MEET', Validators.required],
    dateDebut:    ['', Validators.required],
    dateFin:      ['', Validators.required],
    capaciteMax:  [20],
    lieu:         [''],
    lienReunion:  [''],
  });

  ngOnInit(): void {
    this.#sessionSvc.getByCours('c-001').subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.sessions.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  createSession(): void {
    if (this.sessionForm.invalid) return;
    this.creating.set(true);
    // Simulation création (inscrire un apprenant fictif)
    setTimeout(() => {
      this.creating.set(false);
      this.showCreate.set(false);
      this.#toast.success('Session créée !', 'Les apprenants peuvent maintenant s\'inscrire.');
      this.sessionForm.reset({ modalite: 'MEET', capaciteMax: 20 });
    }, 800);
  }

  modaliteBg(m: string): string { return { MEET: 'bg-blue-100', PRESENTIEL: 'bg-green-100', HYBRIDE: 'bg-purple-100' }[m] ?? 'bg-slate-100'; }
  modaliteEmoji(m: string): string { return { MEET: '💻', PRESENTIEL: '📍', HYBRIDE: '🔀' }[m] ?? '📅'; }
  modaliteBadge(m: string): string { return { MEET: 'badge-blue', PRESENTIEL: 'badge-green', HYBRIDE: 'badge-purple' }[m] ?? 'badge-slate'; }
  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
  }
}
