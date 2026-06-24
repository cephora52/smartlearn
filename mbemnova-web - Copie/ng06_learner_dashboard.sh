#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 06/16 · Dashboard Apprenant
# ============================================================
# Contenu :
#   dashboard.component.ts  — vue globale apprenant (S05)
#     · XP total + streak + rang
#     · Cours en cours avec barre progression
#     · Tirage en vedette (S24)
#     · Notifications récentes
#     · Suggestions de cours
#     · Skeleton sur tous les chargements
#     · Empty states illustrés
#
# Règles : Tailwind only · OnPush · Signals · SSR-safe
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "\033[0;31m  ✗\033[0m $1" >&2; exit 1; }
[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet"

mkdir -p src/app/features/learner/dashboard

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 06 · Dashboard Apprenant     ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

sec "Dashboard apprenant (S05)"

cat > src/app/features/learner/dashboard/dashboard.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService }        from '../../../core/services/auth.service';
import { ProgressionService } from '../../../core/services/progression.service';
import { CourseService }      from '../../../core/services/course.service';
import { NotificationService } from '../../../core/services/notification.service';
import { TalentService }      from '../../../core/services/talent.service';
import type {
  ProgressionResponse, CoursResponse,
  NotificationResponse, DrawResponse,
  ProfilTalentResponse,
} from '../../../core/models';
import {
  MOCK_PROGRESSION, MOCK_COURS, MOCK_NOTIFICATIONS,
  MOCK_DRAW, MOCK_PROFIL,
} from '../../../core/services/mock.data';

@Component({
  selector: 'app-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- ── EN-TÊTE BIENVENUE ─────────────────────────────── -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm text-slate-500 mb-0.5">Bon retour,</p>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
            {{ prenom() }} 👋
          </h1>
        </div>
        <!-- Streak badge -->
        @if (!profilLoading()) {
          <div class="flex items-center gap-2 bg-orange-50 border border-orange-200
                      rounded-xl px-4 py-2.5">
            <span class="text-2xl" aria-hidden="true">🔥</span>
            <div>
              <p class="text-sm font-black text-orange-700">{{ profil()?.streakJours ?? 0 }} jours</p>
              <p class="text-xs text-orange-500">Série en cours</p>
            </div>
          </div>
        }
      </div>
    </div>
  </div>

  <div class="container py-8 space-y-8">

    <!-- ── MÉTRIQUES GLOBALES ───────────────────────────── -->
    <section aria-label="Mes statistiques">
      @if (profilLoading()) {
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          @for (_ of [1,2,3,4]; track $_) {
            <div class="card p-5">
              <div class="shimmer h-8 rounded w-1/2 mb-2"></div>
              <div class="shimmer h-4 rounded w-3/4"></div>
            </div>
          }
        </div>
      }

      @if (!profilLoading()) {
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">

          <!-- XP total -->
          <div class="card p-5 animate-fade-up">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="#d97706" aria-hidden="true">
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">
                  {{ (profil()?.xpTotal ?? 0) | number:'1.0-0' }}
                </p>
                <p class="text-xs text-slate-500">XP gagnés</p>
              </div>
            </div>
            <div class="progress">
              <div class="progress-bar bg-amber-400" [style.width.%]="xpProgress()"></div>
            </div>
            <p class="text-xs text-slate-400 mt-1">
              {{ pointsManquants() }} XP pour le prochain niveau
            </p>
          </div>

          <!-- Rang -->
          <div class="card p-5 animate-fade-up delay-75">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true">
                  <polyline points="6 9 6 2 18 2 18 9"/>
                  <path d="M6 18H4a2 2 0 0 1-2-2v-1a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2h-2"/>
                  <rect x="6" y="18" width="12" height="4" rx="1"/>
                </svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">#{{ profil()?.rang ?? '—' }}</p>
                <p class="text-xs text-slate-500">Classement global</p>
              </div>
            </div>
            <a routerLink="/app/classement"
               class="text-xs text-blue-600 hover:text-blue-700 mt-3 inline-flex items-center gap-1 font-medium transition-colors">
              Voir le classement
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </a>
          </div>

          <!-- Certificats -->
          <div class="card p-5 animate-fade-up delay-100">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true">
                  <circle cx="12" cy="8" r="6"/>
                  <path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/>
                </svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">
                  {{ profil()?.certificats?.length ?? 0 }}
                </p>
                <p class="text-xs text-slate-500">Certificat{{ (profil()?.certificats?.length ?? 0) > 1 ? 's' : '' }}</p>
              </div>
            </div>
            <a routerLink="/app/certificats"
               class="text-xs text-green-600 hover:text-green-700 mt-3 inline-flex items-center gap-1 font-medium transition-colors">
              Mes certificats
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </a>
          </div>

          <!-- Parrainage -->
          <div class="card p-5 animate-fade-up delay-150">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" aria-hidden="true">
                  <polyline points="20 12 20 22 4 22 4 12"/>
                  <rect x="2" y="7" width="20" height="5"/>
                  <path d="M12 22V7"/>
                  <path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/>
                  <path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/>
                </svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">
                  {{ profil()?.xpTotal ? Math.floor((profil()!.xpTotal) / 200) : 0 }}
                </p>
                <p class="text-xs text-slate-500">Filleuls actifs</p>
              </div>
            </div>
            <a routerLink="/app/parrainage"
               class="text-xs text-purple-600 hover:text-purple-700 mt-3 inline-flex items-center gap-1 font-medium transition-colors">
              Parrainer un ami
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </a>
          </div>

        </div>
      }
    </section>

    <!-- ── GRILLE PRINCIPALE ─────────────────────────────── -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Colonne gauche — Cours en cours + Suggestions -->
      <div class="lg:col-span-2 space-y-6">

        <!-- COURS EN COURS (S05) -->
        <section aria-label="Mes cours en cours">
          <div class="flex items-center justify-between mb-4">
            <h2 class="h3">Mes cours</h2>
            <a routerLink="/catalogue" class="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors">
              + Ajouter un cours
            </a>
          </div>

          @if (progressionLoading()) {
            <div class="space-y-4">
              @for (_ of [1,2]; track $_) {
                <div class="card p-5">
                  <div class="flex gap-4">
                    <div class="shimmer w-16 h-16 rounded-xl shrink-0"></div>
                    <div class="flex-1 space-y-2">
                      <div class="shimmer h-4 rounded w-3/4"></div>
                      <div class="shimmer h-3 rounded w-1/2"></div>
                      <div class="shimmer h-2 rounded-full w-full mt-3"></div>
                    </div>
                  </div>
                </div>
              }
            </div>
          }

          @if (!progressionLoading()) {
            @if (progressions().length === 0) {
              <!-- Empty state cours -->
              <div class="card p-10 text-center">
                <div class="flex justify-center mb-4">
                  <svg width="80" height="80" viewBox="0 0 80 80" fill="none" aria-hidden="true">
                    <circle cx="40" cy="40" r="40" fill="#eff6ff"/>
                    <rect x="20" y="24" width="40" height="30" rx="4" fill="#bfdbfe"/>
                    <rect x="25" y="30" width="30" height="3" rx="1.5" fill="#3b82f6"/>
                    <rect x="25" y="36" width="22" height="3" rx="1.5" fill="#93c5fd"/>
                    <rect x="25" y="42" width="26" height="3" rx="1.5" fill="#93c5fd"/>
                    <circle cx="54" cy="56" r="12" fill="#2563eb"/>
                    <path d="M48 56l4 4 8-8" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                </div>
                <h3 class="font-semibold text-slate-900 mb-2">Aucun cours commencé</h3>
                <p class="text-sm text-slate-500 mb-5 max-w-xs mx-auto">
                  Explorez notre catalogue et commencez votre premier cours gratuitement.
                </p>
                <a routerLink="/catalogue" class="btn-primary">
                  Découvrir les formations
                </a>
              </div>
            }

            @if (progressions().length > 0) {
              <div class="space-y-4">
                @for (prog of progressions(); track prog.coursId; let i = $index) {
                  <div class="card p-5 group hover:shadow-md transition-shadow animate-fade-up"
                       [style]="'animation-delay:' + (i * 60) + 'ms'">
                    <div class="flex gap-4">
                      <!-- Icône cours -->
                      <div [class]="'w-14 h-14 rounded-xl flex items-center justify-center text-2xl shrink-0 ' + coursIconBg(i)"
                           aria-hidden="true">
                        {{ coursIcon(i) }}
                      </div>

                      <div class="flex-1 min-w-0">
                        <!-- Titre + statut -->
                        <div class="flex items-start justify-between gap-2 mb-1">
                          <h3 class="font-semibold text-slate-900 text-sm leading-snug line-clamp-1">
                            {{ getCoursTitle(prog.coursId) }}
                          </h3>
                          @if (prog.estPaye) {
                            <span class="badge-green shrink-0">Accès complet</span>
                          } @else if (prog.seuilAtteint) {
                            <span class="badge-amber shrink-0">Paiement requis</span>
                          }
                        </div>

                        <!-- XP + pourcentage -->
                        <div class="flex items-center gap-3 text-xs text-slate-400 mb-2.5">
                          <span class="flex items-center gap-1">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true">
                              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                            </svg>
                            {{ prog.xpGagne }} XP
                          </span>
                          <span>{{ prog.pourcentage }}% complété</span>
                          @if (prog.estTermine) {
                            <span class="text-green-600 font-medium flex items-center gap-0.5">
                              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                              Terminé !
                            </span>
                          }
                        </div>

                        <!-- Barre de progression -->
                        <div class="progress mb-3">
                          <div [class]="'progress-bar ' + (prog.estTermine ? 'bg-green-500' : 'bg-blue-600')"
                               [style.width.%]="prog.pourcentage">
                          </div>
                        </div>

                        <!-- Bouton continuer -->
                        <div class="flex items-center gap-2">
                          @if (!prog.seuilAtteint || prog.estPaye) {
                            <a [routerLink]="['/app/cours', getCoursSlug(prog.coursId)]"
                               class="btn-primary btn-sm">
                              {{ prog.pourcentage === 0 ? 'Commencer' : 'Continuer' }}
                              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                            </a>
                          }
                          @if (prog.seuilAtteint && !prog.estPaye) {
                            <a routerLink="/app/paiements"
                               class="btn bg-amber-600 hover:bg-amber-700 text-white btn-sm">
                              Débloquer la suite
                            </a>
                          }
                          <a [routerLink]="['/app/communaute', prog.coursId]"
                             class="btn-ghost btn-sm text-slate-500">
                            Communauté
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                }
              </div>
            }
          }
        </section>

        <!-- SUGGESTIONS DE COURS -->
        @if (!progressionLoading() && coursDisponibles().length > 0) {
          <section aria-label="Formations suggérées">
            <h2 class="h3 mb-4">Continuez votre parcours</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              @for (cours of coursDisponibles(); track cours.id; let i = $index) {
                <a [routerLink]="['/cours', cours.slug]"
                   class="card-hover group flex gap-3 p-4 animate-fade-up"
                   [style]="'animation-delay:' + (i * 60) + 'ms'">
                  <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-xl shrink-0 ' + coursIconBg(i + 10)"
                       aria-hidden="true">
                    {{ coursIcon(i + 10) }}
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3 class="text-sm font-semibold text-slate-900 line-clamp-1 mb-0.5">
                      {{ cours.titre }}
                    </h3>
                    <div class="flex items-center gap-2 text-xs text-slate-400">
                      <span>{{ cours.prixAffichage }}</span>
                      <span>·</span>
                      <span class="text-green-600 font-medium">
                        {{ (cours.seuilPaiement * 100) | number:'1.0-0' }}% gratuit
                      </span>
                    </div>
                  </div>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8"
                       stroke-width="2" class="shrink-0 mt-1 group-hover:text-blue-500 transition-colors" aria-hidden="true">
                    <path d="M9 18l6-6-6-6"/>
                  </svg>
                </a>
              }
            </div>
          </section>
        }
      </div>

      <!-- Colonne droite — Tirage + Notifs + Paiements -->
      <div class="space-y-5">

        <!-- TIRAGE AU SORT (S24) -->
        <div class="card overflow-hidden animate-fade-up">
          <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-5">
            <div class="flex items-center gap-2 mb-3">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="white" aria-hidden="true">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
              </svg>
              <span class="text-white font-bold text-sm">Tirage mensuel</span>
            </div>
            <p class="text-white text-xs leading-relaxed">
              Gagne la formation
              <strong>{{ draw().formationGagnanteTitre }}</strong>
              ({{ draw().formationGagnantePrix }}) gratuitement !
            </p>
          </div>
          <div class="p-4">
            <div class="flex items-center justify-between text-xs text-slate-500 mb-3">
              <span>{{ draw().nbTicketsVendus }} participants</span>
              <span>Tirage le {{ draw().dateDrawFormatee }}</span>
            </div>
            <div class="flex items-center justify-between mb-4">
              <div>
                <p class="text-lg font-black text-slate-900">{{ draw().prixTicketFcfa | number:'1.0-0' }} FCFA</p>
                <p class="text-xs text-slate-400">par ticket</p>
              </div>
              <span class="badge-amber">🎟️ {{ draw().statut === 'OUVERT' ? 'Ouvert' : 'Fermé' }}</span>
            </div>
            <a routerLink="/app/tirage" class="btn-primary w-full justify-center btn-sm">
              Acheter un ticket
            </a>
          </div>
        </div>

        <!-- NOTIFICATIONS RÉCENTES -->
        <section class="card p-5 animate-fade-up delay-75" aria-label="Notifications récentes">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-semibold text-slate-900 text-sm">Notifications</h2>
            <a routerLink="/app/notifications"
               class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
              Toutes
            </a>
          </div>

          @if (notifLoading()) {
            <div class="space-y-3">
              @for (_ of [1,2,3]; track $_) {
                <div class="flex gap-3">
                  <div class="shimmer w-8 h-8 rounded-lg shrink-0"></div>
                  <div class="flex-1 space-y-1.5">
                    <div class="shimmer h-3 rounded w-3/4"></div>
                    <div class="shimmer h-3 rounded w-1/2"></div>
                  </div>
                </div>
              }
            </div>
          }

          @if (!notifLoading()) {
            @if (notifications().length === 0) {
              <div class="text-center py-6">
                <div class="text-3xl mb-2" aria-hidden="true">🔔</div>
                <p class="text-xs text-slate-400">Aucune notification</p>
              </div>
            }

            <div class="space-y-3">
              @for (n of notifications().slice(0, 4); track n.id) {
                <a [routerLink]="n.lienAction ?? '/app/notifications'"
                   class="flex items-start gap-3 group">
                  <!-- Icône type notif -->
                  <div [class]="'w-8 h-8 rounded-lg flex items-center justify-center shrink-0 text-sm '
                                + notifIconBg(n.type)"
                       aria-hidden="true">
                    {{ notifEmoji(n.type) }}
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start gap-1">
                      <p class="text-xs font-medium text-slate-900 line-clamp-2 flex-1 leading-snug
                                 group-hover:text-blue-600 transition-colors">
                        {{ n.titre }}
                      </p>
                      @if (!n.estLue) {
                        <div class="w-1.5 h-1.5 bg-blue-500 rounded-full shrink-0 mt-1" aria-label="Non lu"></div>
                      }
                    </div>
                    <p class="text-xs text-slate-400 mt-0.5">
                      {{ timeAgo(n.createdAt) }}
                    </p>
                  </div>
                </a>
              }
            </div>
          }
        </section>

        <!-- PAIEMENTS EN ATTENTE -->
        @if (hasPaiementEnAttente()) {
          <div class="card border-amber-200 bg-amber-50 p-5 animate-fade-up delay-100">
            <div class="flex items-center gap-2 mb-3">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true">
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              <h3 class="text-sm font-semibold text-amber-800">Prochaine échéance</h3>
            </div>
            <p class="text-xs text-amber-700 mb-3 leading-relaxed">
              Vous avez une tranche de paiement à venir. Vérifiez votre échéancier.
            </p>
            <a routerLink="/app/paiements"
               class="btn bg-amber-600 hover:bg-amber-700 text-white w-full justify-center btn-sm">
              Voir mes paiements
            </a>
          </div>
        }

        <!-- PARRAINAGE CTA -->
        <div class="card bg-gradient-to-br from-purple-50 to-blue-50
                    border-purple-200 p-5 animate-fade-up delay-150">
          <div class="flex items-center gap-2 mb-2">
            <span class="text-xl" aria-hidden="true">🤝</span>
            <h3 class="text-sm font-semibold text-slate-900">Invitez un ami</h3>
          </div>
          <p class="text-xs text-slate-500 mb-3 leading-relaxed">
            Parrainez un ami et gagnez tous les deux <strong>200 XP</strong> bonus quand il complète son premier module.
          </p>
          <a routerLink="/app/parrainage"
             class="btn-secondary w-full justify-center btn-sm border-purple-200 text-purple-700 hover:bg-purple-50">
            Mon lien de parrainage
          </a>
        </div>

      </div>
    </div>

  </div>
</div>
  `,
})
export class DashboardComponent implements OnInit {
  readonly #auth        = inject(AuthService);
  readonly #progressSvc = inject(ProgressionService);
  readonly #courseSvc   = inject(CourseService);
  readonly #notifSvc    = inject(NotificationService);
  readonly #talentSvc   = inject(TalentService);

  readonly Math = Math;

  // ── Signals ────────────────────────────────────────────
  readonly profil         = signal<ProfilTalentResponse | null>(MOCK_PROFIL);
  readonly progressions   = signal<ProgressionResponse[]>([MOCK_PROGRESSION]);
  readonly tousLesCours   = signal<CoursResponse[]>(MOCK_COURS);
  readonly notifications  = signal<NotificationResponse[]>(MOCK_NOTIFICATIONS);
  readonly draw           = signal(MOCK_DRAW);

  readonly profilLoading      = signal(true);
  readonly progressionLoading = signal(true);
  readonly notifLoading       = signal(true);

  // ── Computed ───────────────────────────────────────────
  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Apprenant');

  readonly xpProgress = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    const niveaux = [500, 1000, 2000, 5000, 10000];
    const prochain = niveaux.find(n => n > xp) ?? 10000;
    const precedent = niveaux[niveaux.indexOf(prochain) - 1] ?? 0;
    return Math.min(100, ((xp - precedent) / (prochain - precedent)) * 100);
  });

  readonly pointsManquants = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    const niveaux = [500, 1000, 2000, 5000, 10000];
    const prochain = niveaux.find(n => n > xp) ?? 10000;
    return (prochain - xp).toLocaleString('fr-FR');
  });

  // Cours non encore commencés (pour les suggestions)
  readonly coursDisponibles = computed(() => {
    const coursIds = this.progressions().map(p => p.coursId);
    return this.tousLesCours()
      .filter(c => !coursIds.includes(c.id))
      .slice(0, 4);
  });

  readonly hasPaiementEnAttente = computed(() =>
    this.progressions().some(p => p.seuilAtteint && !p.estPaye)
  );

  // ── Helpers cours ──────────────────────────────────────
  getCoursTitle(coursId: string): string {
    return this.tousLesCours().find(c => c.id === coursId)?.titre ?? 'Formation MbemNova';
  }
  getCoursSlug(coursId: string): string {
    return this.tousLesCours().find(c => c.id === coursId)?.slug ?? coursId;
  }

  // ── Init ───────────────────────────────────────────────
  ngOnInit(): void {
    this.#loadProfil();
    this.#loadProgressions();
    this.#loadCours();
    this.#loadNotifications();
    this.#loadDraw();
  }

  #loadProfil(): void {
    this.profilLoading.set(true);
    this.#talentSvc.getMe().subscribe({
      next: r => { if (r.success && r.data) this.profil.set(r.data); this.profilLoading.set(false); },
      error: () => { this.profilLoading.set(false); },
    });
  }

  #loadProgressions(): void {
    this.progressionLoading.set(true);
    this.#progressSvc.getAll().subscribe({
      next: r => {
        if (r.success && r.data) this.progressions.set(r.data.content);
        this.progressionLoading.set(false);
      },
      error: () => { this.progressionLoading.set(false); },
    });
  }

  #loadCours(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data) this.tousLesCours.set(r.data.content); },
    });
  }

  #loadNotifications(): void {
    this.notifLoading.set(true);
    this.#notifSvc.getAll().subscribe({
      next: r => {
        if (r.success && r.data) this.notifications.set(r.data.content);
        this.notifLoading.set(false);
      },
      error: () => { this.notifLoading.set(false); },
    });
  }

  #loadDraw(): void {
    this.#talentSvc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); },
    });
  }

  // ── Utilitaires visuels ────────────────────────────────
  coursIconBg(i: number): string {
    const bgs = [
      'bg-blue-100', 'bg-emerald-100', 'bg-purple-100',
      'bg-amber-100', 'bg-red-100', 'bg-cyan-100',
    ];
    return bgs[i % bgs.length];
  }

  coursIcon(i: number): string {
    const icons = ['💻', '⚡', '🎨', '📊', '📱', '🚀', '🌱', '🔧', '📚', '🎯'];
    return icons[i % icons.length];
  }

  notifEmoji(type: string): string {
    const map: Record<string, string> = {
      PAIEMENT_ECHEANCE: '💳', PAIEMENT_RETARD:  '⚠️',  PAIEMENT_RECU:    '✅',
      COURS_DEBLOQUE:   '🔓', DEVOIR_PUBLIE:    '📝',  DEVOIR_CORRIGE:   '✏️',
      REPONSE_COMMUNAUTE:'💬', PARRAINAGE_ACTIF: '🤝',  TIRAGE_RESULTAT:  '🎯',
      CERTIFICAT_GENERE: '🏆', COMPTE_SUSPENDU:  '🚫',  SYSTEME:          'ℹ️',
    };
    return map[type] ?? 'ℹ️';
  }

  notifIconBg(type: string): string {
    if (type.includes('PAIEMENT')) return 'bg-amber-100';
    if (type.includes('DEVOIR'))   return 'bg-blue-100';
    if (type === 'CERTIFICAT_GENERE') return 'bg-green-100';
    if (type === 'COMPTE_SUSPENDU')   return 'bg-red-100';
    if (type === 'PARRAINAGE_ACTIF')  return 'bg-purple-100';
    return 'bg-slate-100';
  }

  timeAgo(iso: string): string {
    const diff = Date.now() - new Date(iso).getTime();
    const mins  = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days  = Math.floor(diff / 86400000);
    if (mins < 60)  return `il y a ${mins} min`;
    if (hours < 24) return `il y a ${hours}h`;
    if (days < 7)   return `il y a ${days}j`;
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  }
}
EOF

ok "dashboard.component.ts"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 06 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  dashboard.component.ts"
echo -e "       · KPIs : XP · rang · certificats · parrainage"
echo -e "       · Cours en cours avec barres de progression"
echo -e "       · Empty states illustrés SVG"
echo -e "       · Skeleton sur tous les chargements"
echo -e "       · Tirage mensuel en vedette (S24)"
echo -e "       · Notifications récentes avec time-ago"
echo -e "       · Alerte paiement en attente (S07)"
echo -e "       · CTA parrainage (S15)"
echo -e "       · Suggestions de cours"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng07_course_player.sh${N}"
echo ""
