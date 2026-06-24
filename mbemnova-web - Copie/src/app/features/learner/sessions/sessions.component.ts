import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { SessionService } from '../../../core/services/session.service';
import { ToastService }   from '../../../core/services/toast.service';
import type { SessionResponse, CreneauResponse } from '../../../core/models';
import { MOCK_SESSIONS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-sessions',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
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
          Mes sessions
        </h1>
      </div>
      <p class="text-slate-500 text-sm ml-8">
        Formations avec formateur — présentiel ou en ligne.
      </p>
    </div>
  </div>

  <div class="container py-6 space-y-5">

    <!-- Skeleton -->
    @if (loading()) {
      @for (_ of [1,2]; track $index) {
        <div class="card p-5">
          <div class="flex gap-4 mb-4">
            <div class="shimmer w-12 h-12 rounded-xl shrink-0"></div>
            <div class="flex-1 space-y-2">
              <div class="shimmer h-4 rounded w-2/3"></div>
              <div class="shimmer h-3 rounded w-1/2"></div>
            </div>
          </div>
          <div class="shimmer h-10 rounded-lg w-full"></div>
        </div>
      }
    }

    <!-- Empty state -->
    @if (!loading() && sessions().length === 0) {
      <div class="card p-14 text-center">
        <div class="flex justify-center mb-5">
          <svg width="100" height="100" viewBox="0 0 100 100" fill="none" aria-hidden="true">
            <circle cx="50" cy="50" r="50" fill="#eff6ff"/>
            <rect x="20" y="25" width="60" height="50" rx="8" fill="#bfdbfe"/>
            <rect x="20" y="25" width="60" height="18" rx="8" fill="#2563eb"/>
            <rect x="30" y="20" width="6" height="12" rx="3" fill="#1d4ed8"/>
            <rect x="64" y="20" width="6" height="12" rx="3" fill="#1d4ed8"/>
            <rect x="30" y="52" width="8" height="8" rx="2" fill="#93c5fd"/>
            <rect x="46" y="52" width="8" height="8" rx="2" fill="#93c5fd"/>
            <rect x="62" y="52" width="8" height="8" rx="2" fill="#dbeafe"/>
            <rect x="30" y="65" width="8" height="8" rx="2" fill="#93c5fd"/>
            <rect x="46" y="65" width="8" height="8" rx="2" fill="#dbeafe"/>
          </svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Aucune session disponible</h2>
        <p class="text-sm text-slate-500 mb-6 max-w-xs mx-auto leading-relaxed">
          Inscrivez-vous à un cours pour accéder aux sessions avec formateur.
        </p>
        <a routerLink="/catalogue" class="btn-primary">Voir le catalogue</a>
      </div>
    }

    <!-- Liste sessions -->
    @if (!loading()) {
      @for (s of sessions(); track s.id; let i = $index) {
        <div class="card overflow-hidden animate-fade-up"
             [style]="'animation-delay:' + (i * 60) + 'ms'">

          <!-- En-tête session -->
          <div class="p-5">
            <div class="flex items-start gap-4">
              <!-- Icône modalité -->
              <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0 '
                            + modaliteBg(s.modalite)" aria-hidden="true">
                {{ modaliteEmoji(s.modalite) }}
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-start gap-2 flex-wrap mb-1">
                  <h2 class="font-bold text-slate-900">{{ s.titre }}</h2>
                  <span [class]="modaliteBadge(s.modalite)">
                    {{ modaliteLabel(s.modalite) }}
                  </span>
                  @if (!s.estActive) {
                    <span class="badge-slate">Inactive</span>
                  }
                </div>

                <!-- Dates + lieu -->
                <div class="flex flex-wrap gap-3 text-xs text-slate-500 mb-3">
                  <span class="flex items-center gap-1">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                    Du {{ formatDate(s.dateDebut) }} au {{ formatDate(s.dateFin) }}
                  </span>
                  @if (s.lieu) {
                    <span class="flex items-center gap-1">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                      {{ s.lieu }}
                    </span>
                  }
                  @if (s.lienReunion) {
                    <a [href]="s.lienReunion" target="_blank" rel="noopener"
                       class="flex items-center gap-1 text-blue-600 hover:text-blue-700 transition-colors">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 3h4v18h-4"/><path d="M8 3H4v18h4"/></svg>
                      Lien Meet
                    </a>
                  }
                </div>

                <!-- Places -->
                <div class="flex items-center gap-3">
                  <div class="flex-1 progress h-1.5">
                    <div class="progress-bar"
                         [class]="s.placesRestantes === 0 ? 'bg-red-400' : s.placesRestantes <= 3 ? 'bg-amber-400' : 'bg-green-500'"
                         [style.width.%]="(s.nbInscrits / s.capaciteMax) * 100">
                    </div>
                  </div>
                  <span [class]="'text-xs font-medium shrink-0 '
                                  + (s.placesRestantes === 0 ? 'text-red-600'
                                  : s.placesRestantes <= 3 ? 'text-amber-600'
                                  : 'text-green-600')">
                    @if (s.placesRestantes === 0) { Complet }
                    @else { {{ s.placesRestantes }} place{{ s.placesRestantes > 1 ? 's' : '' }} }
                  </span>
                  <span class="text-xs text-slate-400">{{ s.nbInscrits }}/{{ s.capaciteMax }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Créneaux (S10) -->
          @if (activeSession() === s.id) {
            <div class="border-t border-slate-100 p-5 bg-slate-50 animate-fade-up">
              <h3 class="text-sm font-semibold text-slate-900 mb-3">
                Choisissez votre créneau
              </h3>

              @if (creneauxLoading()) {
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  @for (_ of [1,2,3,4,5,6]; track $index) {
                    <div class="shimmer h-14 rounded-xl"></div>
                  }
                </div>
              }

              @if (!creneauxLoading() && creneaux().length === 0) {
                <p class="text-sm text-slate-500 italic">
                  Aucun créneau disponible pour le moment.
                </p>
              }

              @if (!creneauxLoading() && creneaux().length > 0) {
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 mb-4">
                  @for (c of creneaux(); track c.id) {
                    <button (click)="selectCreneau(c)"
                            [disabled]="c.placesRestantes === 0"
                            class="p-3 rounded-xl border-2 text-left transition-all duration-150"
                            [class]="selectedCreneau()?.id === c.id
                              ? 'border-blue-500 bg-blue-50'
                              : c.placesRestantes === 0
                              ? 'border-slate-200 bg-slate-100 opacity-50 cursor-not-allowed'
                              : 'border-slate-200 bg-white hover:border-blue-300 hover:bg-blue-50'">
                      <p class="text-xs font-semibold text-slate-900">{{ c.jourSemaine }}</p>
                      <p class="text-xs text-slate-500">{{ c.heureDebut }} – {{ c.heureFin }}</p>
                      <p [class]="'text-xs font-medium mt-1 '
                                   + (c.placesRestantes === 0 ? 'text-red-500'
                                   : c.placesRestantes <= 2 ? 'text-amber-500'
                                   : 'text-green-600')">
                        {{ c.placesRestantes === 0 ? 'Complet' : c.placesRestantes + ' place' + (c.placesRestantes > 1 ? 's' : '') }}
                      </p>
                    </button>
                  }
                </div>

                <div class="flex gap-3">
                  <button (click)="confirmInscription(s)"
                          [disabled]="!selectedCreneau() || inscribing()"
                          class="btn-primary flex-1 justify-center"
                          [class.opacity-50]="!selectedCreneau()">
                    @if (inscribing()) {
                      <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                      Inscription…
                    } @else {
                      Confirmer l'inscription
                    }
                  </button>
                  <button (click)="activeSession.set(null)"
                          class="btn-secondary">
                    Annuler
                  </button>
                </div>
              }
            </div>
          }

          <!-- Bouton d'action -->
          @if (activeSession() !== s.id) {
            <div class="border-t border-slate-100 px-5 py-4 flex items-center justify-between bg-white">
              @if (s.placesRestantes > 0 && s.estActive) {
                <button (click)="showCreneaux(s)"
                        class="btn-primary btn-sm">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                  Choisir mes créneaux
                </button>
              } @else if (s.placesRestantes === 0) {
                <span class="text-sm text-slate-500 italic">Session complète</span>
              } @else {
                <span class="text-sm text-slate-500 italic">Session inactive</span>
              }

              <!-- Rappel si inscrit -->
              <span class="text-xs text-slate-400 flex items-center gap-1">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                Rappel J-1 automatique
              </span>
            </div>
          }
        </div>
      }
    }
  </div>
</div>
  `,
})
export class SessionsComponent implements OnInit {
  readonly #sessionSvc = inject(SessionService);
  readonly #toast      = inject(ToastService);

  readonly sessions       = signal<SessionResponse[]>(MOCK_SESSIONS);
  readonly creneaux       = signal<CreneauResponse[]>([]);
  readonly loading        = signal(true);
  readonly creneauxLoading= signal(false);
  readonly inscribing     = signal(false);
  readonly activeSession  = signal<string | null>(null);
  readonly selectedCreneau= signal<CreneauResponse | null>(null);

  ngOnInit(): void {
    this.#sessionSvc.getByCours('c-001').subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) this.sessions.set(r.data.content);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  showCreneaux(s: SessionResponse): void {
    this.activeSession.set(s.id);
    this.selectedCreneau.set(null);
    this.creneauxLoading.set(true);

    this.#sessionSvc.getCreneaux(s.id).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.creneaux.set(r.data);
        } else {
          // Mock créneaux si vides
     this.creneaux.set([
  { id: 'c1', sessionId: s.id, jourSemaine: 'Lundi',    heureDebut: '09:00', heureFin: '11:00', dureeMinutes: 120, capaciteMax: 20, placesRestantes: 5 },
  { id: 'c2', sessionId: s.id, jourSemaine: 'Mercredi', heureDebut: '14:00', heureFin: '16:00', dureeMinutes: 120, capaciteMax: 20, placesRestantes: 3 },
  { id: 'c3', sessionId: s.id, jourSemaine: 'Samedi',   heureDebut: '10:00', heureFin: '12:00', dureeMinutes: 120, capaciteMax: 20, placesRestantes: 0 },
  { id: 'c4', sessionId: s.id, jourSemaine: 'Vendredi', heureDebut: '17:00', heureFin: '19:00', dureeMinutes: 120, capaciteMax: 20, placesRestantes: 7 },
]);
        }
        this.creneauxLoading.set(false);
      },
      error: () => { this.creneauxLoading.set(false); },
    });
  }

  selectCreneau(c: CreneauResponse): void {
    if (c.placesRestantes === 0) return;
    this.selectedCreneau.set(c);
  }

  confirmInscription(s: SessionResponse): void {
    const creneau = this.selectedCreneau();
    if (!creneau) return;
    this.inscribing.set(true);

    this.#sessionSvc.inscrire(s.id, { coursId: s.coursId }).subscribe({
      next: () => {
        this.inscribing.set(false);
        this.activeSession.set(null);
        this.#toast.success(
          'Inscription confirmée !',
          `Créneau : ${creneau.jourSemaine} ${creneau.heureDebut}–${creneau.heureFin}. Un rappel vous sera envoyé J-1.`
        );
        // Mettre à jour les places
        this.sessions.update(list => list.map(sess =>
          sess.id === s.id
            ? { ...sess, nbInscrits: sess.nbInscrits + 1, placesRestantes: sess.placesRestantes - 1 }
            : sess
        ));
      },
      error: () => { this.inscribing.set(false); },
    });
  }

  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
  }

  modaliteLabel(m: string): string {
    return { MEET: 'En ligne', PRESENTIEL: 'Présentiel', HYBRIDE: 'Hybride' }[m] ?? m;
  }
  modaliteEmoji(m: string): string {
    return { MEET: '💻', PRESENTIEL: '📍', HYBRIDE: '🔀' }[m] ?? '📅';
  }
  modaliteBg(m: string): string {
    return { MEET: 'bg-blue-100', PRESENTIEL: 'bg-green-100', HYBRIDE: 'bg-purple-100' }[m] ?? 'bg-slate-100';
  }
  modaliteBadge(m: string): string {
    return { MEET: 'badge-blue', PRESENTIEL: 'badge-green', HYBRIDE: 'badge-purple' }[m] ?? 'badge-slate';
  }
}
