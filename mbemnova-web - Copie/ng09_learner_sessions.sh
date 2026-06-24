#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 09/16 · Sessions + Devoirs Apprenant
# ============================================================
# Contenu :
#   sessions.component.ts   (S09 · S10)
#     · Liste sessions avec formateur
#     · Inscription session + confirmation
#     · Sélecteur créneaux horaires (S10)
#     · Rappel J-1 affiché
#
#   assignments.component.ts (S11 · S23)
#     · Liste devoirs reçus + badges deadline
#     · Formulaire soumission rendu
#     · Affichage note + commentaire formateur
#     · Modal soumission
#
# Règles : Tailwind only · OnPush · Signals · SSR-safe
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "\033[0;31m  ✗\033[0m $1" >&2; exit 1; }
[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet"

mkdir -p src/app/features/learner/sessions
mkdir -p src/app/features/learner/assignments

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 09 · Sessions + Devoirs      ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. SESSIONS — S09 · S10
# ============================================================
sec "1/2 — sessions.component.ts (S09 S10)"

cat > src/app/features/learner/sessions/sessions.component.ts << 'EOF'
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
      @for (_ of [1,2]; track $_) {
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
                  @for (_ of [1,2,3,4,5,6]; track $_) {
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
            { id: 'c1', sessionId: s.id, jourSemaine: 'Lundi',    heureDebut: '09:00', heureFin: '11:00', placesRestantes: 5 },
            { id: 'c2', sessionId: s.id, jourSemaine: 'Mercredi', heureDebut: '14:00', heureFin: '16:00', placesRestantes: 3 },
            { id: 'c3', sessionId: s.id, jourSemaine: 'Samedi',   heureDebut: '10:00', heureFin: '12:00', placesRestantes: 0 },
            { id: 'c4', sessionId: s.id, jourSemaine: 'Vendredi', heureDebut: '17:00', heureFin: '19:00', placesRestantes: 7 },
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
EOF
ok "sessions.component.ts"

# ============================================================
# 2. ASSIGNMENTS — S11 · S23
# ============================================================
sec "2/2 — assignments.component.ts (S11 S23)"

cat > src/app/features/learner/assignments/assignments.component.ts << 'EOF'
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
import type { DevoirResponse, RenduResponse } from '../../../core/models';
import { MOCK_DEVOIRS } from '../../../core/services/mock.data';

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
      @for (_ of [1,2]; track $_) {
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
      @for (d of devoirs(); track d.id; let i = $index) {
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
                  <h2 class="font-bold text-slate-900 leading-snug">{{ d.titre }}</h2>
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
                    Remise : {{ formatDate(d.dateRemise) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Consignes -->
            <div class="mt-4 bg-slate-50 rounded-xl p-4">
              <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Consignes</p>
              <p class="text-sm text-slate-700 leading-relaxed whitespace-pre-line">{{ d.consignes }}</p>
              @if (d.lienRessources) {
                <a [href]="d.lienRessources" target="_blank" rel="noopener"
                   class="inline-flex items-center gap-1.5 mt-3 text-xs text-blue-600
                          hover:text-blue-700 font-medium transition-colors">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
                  Ressources supplémentaires
                </a>
              }
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
                {{ activeDevoir()?.titre }}
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

  readonly devoirs     = signal<DevoirResponse[]>(MOCK_DEVOIRS);
  readonly loading     = signal(true);
  readonly showSubmit  = signal(false);
  readonly activeDevoir= signal<DevoirResponse | null>(null);
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

  openSubmit(d: DevoirResponse): void {
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
      devoirId:    this.activeDevoir()!.id,
      contenu,
      lienFichier: lienFichier || undefined,
    }).subscribe({
      next: () => {
        this.submitting.set(false);
        this.closeSubmit();
        // Marquer comme soumis localement
        const devoir = this.activeDevoir()!;
        const rendu: RenduResponse = {
          id: 'r-new', devoirId: devoir.id, apprenantId: '',
          contenu, lienFichier: lienFichier || null,
          soumisLe: new Date().toISOString(),
          note: null, commentaire: null, corrigeLe: null,
        };
        this.devoirs.update(list => list.map(d =>
          d.id === devoir.id ? { ...d, rendu } : d
        ));
        this.#toast.success(
          'Rendu soumis !',
          'Votre formateur recevra une notification et corrigera votre travail.'
        );
      },
      error: () => { this.submitting.set(false); },
    });
  }

  // ── Helpers ────────────────────────────────────────────
  isOverdue(d: DevoirResponse): boolean {
    return new Date(d.dateRemise) < new Date();
  }

  isDueSoon(d: DevoirResponse): boolean {
    const diff = new Date(d.dateRemise).getTime() - Date.now();
    return diff > 0 && diff < 3 * 86_400_000;
  }

  daysLeft(d: DevoirResponse): number {
    return Math.ceil((new Date(d.dateRemise).getTime() - Date.now()) / 86_400_000);
  }

  formatDate(iso: string): string {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('fr-FR', {
      day: 'numeric', month: 'long', year: 'numeric',
    });
  }

  devoirIconBg(d: DevoirResponse): string {
    if (d.rendu?.note !== null && d.rendu?.note !== undefined) return 'bg-green-100';
    if (d.rendu)           return 'bg-blue-100';
    if (this.isOverdue(d)) return 'bg-red-100';
    if (this.isDueSoon(d)) return 'bg-amber-100';
    return 'bg-slate-100';
  }

  devoirIconColor(d: DevoirResponse): string {
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
EOF
ok "assignments.component.ts"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 09 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  sessions.component.ts"
echo -e "       · Liste sessions : modalité, dates, places, lieu/Meet"
echo -e "       · Barre places restantes colorée"
echo -e "       · Sélecteur créneaux (S10) : grid interactif"
echo -e "       · Confirmation inscription + mise à jour locale"
echo -e "       · Rappel J-1 affiché · Empty state illustré"
echo ""
echo -e "  ${G}✓${N}  assignments.component.ts"
echo -e "       · Liste devoirs + badges : soumis / retard / bientôt / à faire"
echo -e "       · Consignes + lien ressources"
echo -e "       · Note formateur (S23) : barre + appréciation + commentaire"
echo -e "       · Modal soumission (S11) : textarea + lien fichier"
echo -e "       · Validation reactive form + avertissement avant envoi"
echo -e "       · Skeleton + empty state illustré"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng10_learner_social.sh${N}"
echo ""
