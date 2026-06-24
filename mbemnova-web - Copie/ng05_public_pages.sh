#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 05/16 · Pages Publiques
# ============================================================
# Contenu :
#   Landing         (S01) — hero, tirage en vedette, catalogue aperçu
#   Catalog         (S04) — filtres, pagination, skeleton
#   CourseDetail    (S04) — détail cours, sessions, CTA
#   CertificateVerify     — vérification publique
#   PrivacyPolicy   (S28) — politique de confidentialité complète
#
# Règles : Tailwind only · OnPush · Signals · SSR-safe
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "\033[0;31m  ✗\033[0m $1" >&2; exit 1; }
[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet"

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 05 · Pages Publiques         ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

mkdir -p \
  src/app/features/public/landing \
  src/app/features/public/catalog \
  src/app/features/public/course-detail \
  src/app/features/public/certificate-verify \
  src/app/features/public/privacy-policy

# ============================================================
# 1. LANDING — S01
# ============================================================
sec "1/5 — Landing (S01)"

cat > src/app/features/public/landing/landing.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CourseService } from '../../../core/services/course.service';
import { TalentService } from '../../../core/services/talent.service';
import type { CoursResponse, DrawResponse } from '../../../core/models';
import { MOCK_COURS, MOCK_DRAW, MOCK_LEADERBOARD } from '../../../core/services/mock.data';

@Component({
  selector: 'app-landing',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="bg-white">

  <!-- ── HERO ────────────────────────────────────────────── -->
  <section class="relative overflow-hidden bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900">
    <!-- Grille déco -->
    <div class="absolute inset-0 opacity-[0.06]"
         style="background-image:linear-gradient(rgba(255,255,255,1) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,1) 1px,transparent 1px);background-size:48px 48px"></div>
    <!-- Blob lumineux -->
    <div class="absolute -top-24 -right-24 w-96 h-96 bg-blue-500/20 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute bottom-0 -left-16 w-72 h-72 bg-indigo-500/10 rounded-full blur-2xl pointer-events-none"></div>

    <div class="container relative py-20 md:py-28 lg:py-32">
      <div class="max-w-3xl">
        <!-- Badge -->
        <div class="inline-flex items-center gap-2 bg-blue-500/15 border border-blue-400/20
                    text-blue-300 rounded-full px-4 py-1.5 text-sm font-medium mb-8 animate-fade-up">
          <span class="w-2 h-2 bg-blue-400 rounded-full animate-pulse" aria-hidden="true"></span>
          La référence EdTech de l'Afrique Centrale
        </div>

        <h1 class="text-4xl sm:text-5xl lg:text-6xl font-black text-white leading-[1.1] mb-6 animate-fade-up delay-75"
            style="font-family:var(--font);">
          Apprenez la tech,<br>
          <span class="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-cyan-300">
            changez votre avenir
          </span>
        </h1>

        <p class="text-lg sm:text-xl text-slate-300 leading-relaxed mb-8 max-w-2xl animate-fade-up delay-100">
          Formations certifiantes en développement web, mobile, data science et design.
          Payez en tranches. Communauté de Douala, Yaoundé et toute l'Afrique Centrale.
        </p>

        <div class="flex flex-wrap gap-3 animate-fade-up delay-150">
          <a routerLink="/auth/inscription"
             class="btn bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white
                    px-7 py-3 text-base font-semibold shadow-xl shadow-blue-900/30
                    transition-all duration-150">
            Commencer gratuitement
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
          </a>
          <a routerLink="/catalogue"
             class="btn bg-white/10 hover:bg-white/20 text-white border border-white/20
                    px-7 py-3 text-base backdrop-blur-sm">
            Voir le catalogue
          </a>
        </div>

        <!-- Stats -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-6 mt-14 pt-10 border-t border-white/10 animate-fade-up delay-200">
          @for (s of stats; track s.label) {
            <div>
              <p class="text-2xl sm:text-3xl font-black text-white">{{ s.value }}</p>
              <p class="text-sm text-slate-400 mt-0.5">{{ s.label }}</p>
            </div>
          }
        </div>
      </div>
    </div>
  </section>

  <!-- ── TIRAGE EN VEDETTE (S24) ──────────────────────────── -->
  <section class="bg-gradient-to-r from-amber-50 to-orange-50 border-y border-amber-100">
    <div class="container py-6">
      <div class="flex flex-col sm:flex-row items-start sm:items-center gap-5 justify-between">
        <div class="flex items-center gap-4">
          <!-- Illustration tirage -->
          <div class="w-14 h-14 shrink-0 rounded-2xl bg-amber-100 flex items-center justify-center">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true">
              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
          </div>
          <div>
            <span class="badge-amber inline-flex mb-1.5">🎟️ Tirage mensuel</span>
            <h2 class="text-base font-bold text-slate-900 leading-snug">
              Gagne la formation
              <span class="text-amber-700">{{ draw().formationGagnanteTitre }}</span>
              gratuitement
            </h2>
            <p class="text-sm text-slate-500 mt-0.5">
              Ticket à {{ draw().prixTicketFcfa | number:'1.0-0' }} FCFA ·
              {{ draw().nbTicketsVendus }} participants ·
              Tirage le {{ draw().dateDrawFormatee }}
            </p>
          </div>
        </div>
        <a routerLink="/auth/inscription"
           class="btn bg-amber-600 hover:bg-amber-700 text-white px-5 py-2.5 shrink-0 text-sm">
          Participer au tirage
        </a>
      </div>
    </div>
  </section>

  <!-- ── CATALOGUE APERÇU (S04) ───────────────────────────── -->
  <section class="section">
    <div class="container">
      <div class="flex items-end justify-between mb-10">
        <div>
          <p class="text-blue-600 font-semibold text-sm mb-1.5 uppercase tracking-wide">Nos formations</p>
          <h2 class="h2">Commencez gratuitement</h2>
          <p class="text-slate-500 mt-2 max-w-lg">
            Accédez aux premiers modules sans payer. Débloquez la suite à votre rythme, en tranches.
          </p>
        </div>
        <a routerLink="/catalogue" class="btn-secondary hidden sm:flex shrink-0 ml-6">
          Tout voir
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
        </a>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        @for (cours of featured(); track cours.id; let i = $index) {
          <a [routerLink]="['/cours', cours.slug]"
             class="card-hover group block overflow-hidden"
             [style]="'animation-delay:' + (i * 60) + 'ms'"
             [attr.aria-label]="'Voir le cours ' + cours.titre">

            <!-- Bannière colorée avec niveau -->
            <div [class]="'h-40 flex items-end p-5 relative overflow-hidden ' + levelGradient(cours.niveau)">
              <!-- Motif déco -->
              <div class="absolute inset-0 opacity-10"
                   style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:24px 24px"></div>
              <!-- Icône niveau -->
              <div class="absolute top-4 right-4 w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm
                          flex items-center justify-center text-xl" aria-hidden="true">
                {{ levelEmoji(cours.niveau) }}
              </div>
              <!-- Badge + titre -->
              <div class="relative">
                <span [class]="'badge mb-2 bg-white/20 text-white border-white/30 backdrop-blur-sm'">
                  {{ levelLabel(cours.niveau) }}
                </span>
                <h3 class="font-bold text-white text-base leading-snug line-clamp-2">
                  {{ cours.titre }}
                </h3>
              </div>
            </div>

            <!-- Corps -->
            <div class="p-4">
              <p class="text-sm text-slate-500 line-clamp-2 mb-4 leading-relaxed">
                {{ cours.description }}
              </p>

              <!-- Métriques -->
              <div class="flex items-center gap-4 text-xs text-slate-400 mb-4">
                <span class="flex items-center gap-1">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/></svg>
                  {{ cours.nbApprenants }}
                </span>
                @if (cours.noteMoyenne) {
                  <span class="flex items-center gap-1">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    {{ cours.noteMoyenne }}
                  </span>
                }
              </div>

              <!-- Barre freemium -->
              <div class="mb-4">
                <div class="flex justify-between text-xs mb-1">
                  <span class="text-green-600 font-medium">
                    {{ (cours.seuilPaiement * 100) | number:'1.0-0' }}% gratuit
                  </span>
                  <span class="text-slate-500 font-medium">{{ cours.prixAffichage }}</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-green-500"
                       [style.width.%]="cours.seuilPaiement * 100"></div>
                </div>
              </div>

              <!-- CTA -->
              <div class="flex items-center justify-between">
                <span class="text-xs text-green-600 font-medium flex items-center gap-1">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  Accès gratuit partiel
                </span>
                <span class="text-sm text-blue-600 font-semibold flex items-center gap-1
                             group-hover:gap-2 transition-all">
                  Voir
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                </span>
              </div>
            </div>
          </a>
        }
      </div>

      <div class="text-center mt-8 sm:hidden">
        <a routerLink="/catalogue" class="btn-secondary w-full">Voir toutes les formations</a>
      </div>
    </div>
  </section>

  <!-- ── COMMENT ÇA MARCHE ────────────────────────────────── -->
  <section class="section bg-slate-50">
    <div class="container">
      <div class="text-center mb-12">
        <p class="text-blue-600 font-semibold text-sm uppercase tracking-wide mb-2">Simple et efficace</p>
        <h2 class="h2">Comment ça marche ?</h2>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        @for (step of steps; track step.n; let i = $index) {
          <div class="text-center animate-fade-up" [style]="'animation-delay:' + (i * 80) + 'ms'">
            <div class="relative inline-flex mb-5">
              <div class="w-16 h-16 rounded-2xl bg-blue-50 flex items-center
                          justify-center text-3xl border border-blue-100">
                {{ step.icon }}
              </div>
              <div class="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-blue-600
                          text-white text-xs font-bold flex items-center justify-center">
                {{ step.n }}
              </div>
            </div>
            <h3 class="h4 mb-2">{{ step.title }}</h3>
            <p class="text-sm text-slate-500 leading-relaxed">{{ step.desc }}</p>
          </div>
        }
      </div>
    </div>
  </section>

  <!-- ── TOP TALENTS (teaser leaderboard) ─────────────────── -->
  <section class="section">
    <div class="container">
      <div class="flex items-end justify-between mb-8">
        <div>
          <p class="text-blue-600 font-semibold text-sm uppercase tracking-wide mb-1.5">Communauté</p>
          <h2 class="h2">Top apprenants ce mois</h2>
        </div>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        @for (t of topTalents; track t.userId; let i = $index) {
          <div class="card p-4 flex items-center gap-4 animate-fade-up"
               [style]="'animation-delay:' + (i * 60) + 'ms'">
            <!-- Rang -->
            <div [class]="'w-10 h-10 rounded-xl flex items-center justify-center text-sm font-black shrink-0 ' + rankClass(i)">
              {{ i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : '#' + t.rang }}
            </div>
            <!-- Avatar -->
            <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center
                        text-white font-bold shrink-0">
              {{ t.prenom.charAt(0) }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-semibold text-slate-900 truncate">{{ t.prenom }}</p>
              <p class="text-xs text-slate-400">{{ t.xpTotal | number:'1.0-0' }} XP · {{ t.streakJours }}j de suite</p>
            </div>
          </div>
        }
      </div>
    </div>
  </section>

  <!-- ── CTA FINAL ────────────────────────────────────────── -->
  <section class="section">
    <div class="container">
      <div class="relative overflow-hidden bg-blue-600 rounded-3xl px-8 py-14 md:px-14 text-center">
        <div class="absolute inset-0 opacity-10"
             style="background-image:radial-gradient(circle at 20% 50%,white 1px,transparent 1px),radial-gradient(circle at 80% 50%,white 1px,transparent 1px);background-size:32px 32px"></div>
        <h2 class="text-3xl md:text-4xl font-black text-white mb-4 relative"
            style="font-family:var(--font);">
          Prêt à changer de trajectoire ?
        </h2>
        <p class="text-blue-100 text-lg mb-8 relative max-w-xl mx-auto leading-relaxed">
          Rejoignez {{ stats[0].value }} apprenants qui développent leurs compétences tech avec MbemNova.
        </p>
        <a routerLink="/auth/inscription"
           class="btn bg-white text-blue-700 hover:bg-blue-50 px-8 py-3.5 text-base font-bold relative shadow-xl">
          S'inscrire gratuitement — c'est gratuit
        </a>
      </div>
    </div>
  </section>

</div>
  `,
})
export class LandingComponent implements OnInit {
  readonly #courseSvc  = inject(CourseService);
  readonly #talentSvc  = inject(TalentService);

  readonly cours   = signal<CoursResponse[]>(MOCK_COURS);
  readonly draw    = signal<DrawResponse>(MOCK_DRAW);
  readonly featured = () => this.cours().slice(0, 6);
  readonly topTalents = MOCK_LEADERBOARD.slice(0, 3);

  readonly stats = [
    { value: '247+',  label: 'apprenants actifs' },
    { value: '6',     label: 'formations' },
    { value: '95%',   label: 'satisfaction' },
    { value: '3',     label: 'villes' },
  ];

  readonly steps = [
    { n: 1, icon: '👤', title: 'Crée ton compte',        desc: 'Inscription gratuite en 2 min. Aucune carte requise.' },
    { n: 2, icon: '📚', title: 'Explore gratuitement',   desc: 'Accède aux premiers modules. Teste avant de payer.' },
    { n: 3, icon: '💳', title: 'Paie en tranches',       desc: 'Débloque la suite. Cash, Mobile Money, virement.' },
    { n: 4, icon: '🏆', title: 'Obtiens ton certificat', desc: 'Certif officiel MbemNova vérifiable en ligne.' },
  ];

  ngOnInit(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.cours.set(r.data.content); },
    });
    this.#talentSvc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); },
    });
  }

  levelGradient(n: string): string {
    return { DEBUTANT: 'bg-gradient-to-br from-emerald-500 to-green-700', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-500 to-indigo-700', AVANCE: 'bg-gradient-to-br from-purple-500 to-violet-700' }[n] ?? 'bg-blue-700';
  }
  levelEmoji(n: string): string  { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  levelLabel(n: string): string  { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
  rankClass(i: number): string   { return ['bg-amber-100 text-amber-700', 'bg-slate-100 text-slate-600', 'bg-orange-100 text-orange-700'][i] ?? 'bg-slate-50 text-slate-500'; }
}
EOF
ok "Landing"

# ============================================================
# 2. CATALOG — S04
# ============================================================
sec "2/5 — Catalog (S04)"

cat > src/app/features/public/catalog/catalog.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit, effect,
} from '@angular/core';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CourseService } from '../../../core/services/course.service';
import type { CoursResponse, NiveauCours } from '../../../core/models';
import { MOCK_COURS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-catalog',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, FormsModule],
  template: `
<div class="min-h-screen bg-white">

  <!-- Header section -->
  <div class="bg-gradient-to-br from-slate-900 to-blue-950 py-14">
    <div class="container text-center">
      <h1 class="h2 text-white mb-3 animate-fade-up">Catalogue des formations</h1>
      <p class="text-slate-300 text-lg max-w-xl mx-auto mb-8 animate-fade-up delay-75">
        {{ total() }} formations disponibles. Commencez gratuitement, payez à votre rythme.
      </p>

      <!-- Barre de recherche -->
      <div class="max-w-lg mx-auto animate-fade-up delay-100">
        <div class="relative">
          <svg class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none"
               width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
          </svg>
          <input type="search" [(ngModel)]="search" (ngModelChange)="onSearch()"
                 placeholder="Rechercher une formation…"
                 class="w-full pl-10 pr-4 py-3 rounded-xl bg-white/10 border border-white/20
                        text-white placeholder-slate-400 focus:outline-none focus:ring-2
                        focus:ring-blue-400 backdrop-blur-sm text-sm"
                 aria-label="Rechercher une formation">
        </div>
      </div>
    </div>
  </div>

  <!-- Filtres + grille -->
  <div class="container py-10">
    <div class="flex flex-col lg:flex-row gap-8">

      <!-- Sidebar filtres -->
      <aside class="lg:w-56 xl:w-64 shrink-0" aria-label="Filtres">
        <div class="card p-5 sticky top-20">
          <h2 class="h4 mb-4">Filtres</h2>

          <!-- Niveau -->
          <div class="mb-5">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">Niveau</p>
            <div class="space-y-1.5">
              @for (n of niveaux; track n.value) {
                <label class="flex items-center gap-2.5 cursor-pointer group">
                  <input type="radio" name="niveau" [value]="n.value"
                         [(ngModel)]="selectedNiveau"
                         (change)="load()"
                         class="w-4 h-4 text-blue-600 border-slate-300 focus:ring-blue-500">
                  <span class="text-sm text-slate-700 group-hover:text-slate-900 transition-colors">
                    {{ n.label }}
                  </span>
                </label>
              }
            </div>
          </div>

          <!-- Prix -->
          <div class="mb-5">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">Accès</p>
            <div class="space-y-1.5">
              <label class="flex items-center gap-2.5 cursor-pointer">
                <input type="checkbox" [(ngModel)]="onlyFree" (change)="load()"
                       class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500">
                <span class="text-sm text-slate-700">Partiellement gratuit</span>
              </label>
            </div>
          </div>

          <!-- Reset -->
          @if (hasFilter()) {
            <button (click)="resetFilters()"
                    class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
              Effacer les filtres
            </button>
          }
        </div>
      </aside>

      <!-- Grille cours -->
      <div class="flex-1 min-w-0">

        <!-- Résultats count -->
        <div class="flex items-center justify-between mb-6">
          <p class="text-sm text-slate-500">
            @if (!loading()) { {{ total() }} résultat{{ total() > 1 ? 's' : '' }} }
          </p>
        </div>

        <!-- Skeletons -->
        @if (loading()) {
          <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
            @for (_ of [1,2,3,4,5,6]; track $_) {
              <div class="card overflow-hidden">
                <div class="shimmer h-40 rounded-t-xl"></div>
                <div class="p-4 space-y-3">
                  <div class="shimmer h-4 rounded w-3/4"></div>
                  <div class="shimmer h-3 rounded w-full"></div>
                  <div class="shimmer h-3 rounded w-2/3"></div>
                  <div class="shimmer h-2 rounded-full w-full mt-4"></div>
                </div>
              </div>
            }
          </div>
        }

        <!-- Cours -->
        @if (!loading()) {
          @if (cours().length === 0) {
            <!-- Empty state -->
            <div class="empty-state">
              <svg width="80" height="80" viewBox="0 0 80 80" fill="none" class="mb-5" aria-hidden="true">
                <circle cx="40" cy="40" r="40" fill="#f1f5f9"/>
                <path d="M24 40h32M40 24v32" stroke="#94a3b8" stroke-width="3" stroke-linecap="round"/>
                <circle cx="40" cy="40" r="20" stroke="#cbd5e1" stroke-width="2.5" stroke-dasharray="4 4"/>
              </svg>
              <h3 class="h3 mb-2">Aucune formation trouvée</h3>
              <p class="text-slate-500 text-sm mb-5">Essayez d'autres mots-clés ou effacez les filtres.</p>
              <button (click)="resetFilters()" class="btn-secondary btn-sm">Effacer les filtres</button>
            </div>
          }

          @if (cours().length > 0) {
            <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
              @for (c of cours(); track c.id; let i = $index) {
                <a [routerLink]="['/cours', c.slug]"
                   class="card-hover group block overflow-hidden animate-fade-up"
                   [style]="'animation-delay:' + (i * 40) + 'ms'"
                   [attr.aria-label]="c.titre">

                  <div [class]="'h-36 flex items-end p-4 relative overflow-hidden ' + gradient(c.niveau)">
                    <div class="absolute inset-0 opacity-10"
                         style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px" aria-hidden="true"></div>
                    <div class="absolute top-3 right-3 w-9 h-9 rounded-lg bg-white/20 flex items-center justify-center text-lg" aria-hidden="true">
                      {{ emoji(c.niveau) }}
                    </div>
                    <div class="relative">
                      <span class="badge bg-white/25 text-white border-white/30 text-xs mb-1.5">
                        {{ niveauLabel(c.niveau) }}
                      </span>
                      <h3 class="text-sm font-bold text-white leading-snug line-clamp-2">{{ c.titre }}</h3>
                    </div>
                  </div>

                  <div class="p-4">
                    <p class="text-xs text-slate-500 line-clamp-2 mb-3 leading-relaxed">{{ c.description }}</p>

                    <div class="flex items-center gap-3 text-xs text-slate-400 mb-3">
                      <span class="flex items-center gap-1">
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                        {{ c.nbApprenants }}
                      </span>
                      @if (c.noteMoyenne) {
                        <span class="flex items-center gap-1">
                          <svg width="11" height="11" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                          {{ c.noteMoyenne }}
                        </span>
                      }
                      <span class="ml-auto font-semibold text-slate-700">{{ c.prixAffichage }}</span>
                    </div>

                    <div class="progress">
                      <div class="progress-bar bg-green-500" [style.width.%]="c.seuilPaiement * 100"></div>
                    </div>
                    <p class="text-xs text-green-600 mt-1 font-medium">
                      {{ (c.seuilPaiement * 100) | number:'1.0-0' }}% gratuit
                    </p>
                  </div>
                </a>
              }
            </div>

            <!-- Pagination -->
            @if (totalPages() > 1) {
              <div class="flex items-center justify-center gap-2 mt-10">
                <button (click)="prevPage()" [disabled]="page() === 0"
                        class="btn-secondary btn-sm" [class.opacity-40]="page() === 0"
                        aria-label="Page précédente">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
                </button>
                <span class="text-sm text-slate-600 px-2">
                  Page {{ page() + 1 }} / {{ totalPages() }}
                </span>
                <button (click)="nextPage()" [disabled]="page() + 1 >= totalPages()"
                        class="btn-secondary btn-sm" [class.opacity-40]="page() + 1 >= totalPages()"
                        aria-label="Page suivante">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
                </button>
              </div>
            }
          }
        }
      </div>
    </div>
  </div>
</div>
  `,
})
export class CatalogComponent implements OnInit {
  readonly #svc    = inject(CourseService);
  readonly #route  = inject(ActivatedRoute);
  readonly #router = inject(Router);

  readonly cours      = signal<CoursResponse[]>(MOCK_COURS);
  readonly loading    = signal(true);
  readonly total      = signal(6);
  readonly page       = signal(0);
  readonly totalPages = signal(1);

  search          = '';
  selectedNiveau: NiveauCours | '' = '';
  onlyFree        = false;

  readonly hasFilter = computed(() => !!this.search || !!this.selectedNiveau || this.onlyFree);

  readonly niveaux: { value: NiveauCours | ''; label: string }[] = [
    { value: '',              label: 'Tous les niveaux' },
    { value: 'DEBUTANT',      label: '🌱 Débutant' },
    { value: 'INTERMEDIAIRE', label: '⚡ Intermédiaire' },
    { value: 'AVANCE',        label: '🚀 Avancé' },
  ];

  ngOnInit(): void {
    this.#route.queryParams.subscribe(p => {
      if (p['niveau']) this.selectedNiveau = p['niveau'] as NiveauCours;
      this.load();
    });
  }

  load(): void {
    this.loading.set(true);
    const params: Record<string, string | number> = { page: this.page(), size: 9 };
    if (this.search)          params['q']        = this.search;
    if (this.selectedNiveau)  params['niveau']   = this.selectedNiveau;
    if (this.onlyFree)        params['gratuit']  = 'true';

    this.#svc.getAll(params).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.cours.set(r.data.content);
          this.total.set(r.data.totalElements);
          this.totalPages.set(r.data.totalPages);
        }
        this.loading.set(false);
      },
      error: () => { this.cours.set(MOCK_COURS); this.loading.set(false); },
    });
  }

  onSearch(): void { this.page.set(0); this.load(); }
  prevPage(): void { if (this.page() > 0) { this.page.update(p => p - 1); this.load(); } }
  nextPage(): void { if (this.page() + 1 < this.totalPages()) { this.page.update(p => p + 1); this.load(); } }

  resetFilters(): void {
    this.search = ''; this.selectedNiveau = ''; this.onlyFree = false;
    this.page.set(0); this.load();
  }

  gradient(n: string): string {
    return { DEBUTANT: 'bg-gradient-to-br from-emerald-500 to-green-700', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-500 to-indigo-700', AVANCE: 'bg-gradient-to-br from-purple-500 to-violet-700' }[n] ?? 'bg-blue-700';
  }
  emoji(n: string): string    { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  niveauLabel(n: string): string { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
}
EOF
ok "Catalog"

# ============================================================
# 3. COURSE DETAIL — S04
# ============================================================
sec "3/5 — CourseDetail (S04)"

cat > src/app/features/public/course-detail/course-detail.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, input, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CourseService }   from '../../../core/services/course.service';
import { SessionService }  from '../../../core/services/session.service';
import { AuthService }     from '../../../core/services/auth.service';
import type { CoursResponse, SessionResponse } from '../../../core/models';
import { MOCK_COURS, MOCK_SESSIONS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-course-detail',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-white">
  @if (loading()) {
    <!-- Skeleton -->
    <div class="container py-12 space-y-8">
      <div class="shimmer h-64 rounded-2xl"></div>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="lg:col-span-2 space-y-4">
          <div class="shimmer h-8 rounded w-3/4"></div>
          <div class="shimmer h-4 rounded w-full"></div>
          <div class="shimmer h-4 rounded w-2/3"></div>
        </div>
        <div class="shimmer h-72 rounded-xl"></div>
      </div>
    </div>
  }

  @if (!loading() && cours()) {
    <!-- Hero cours -->
    <div [class]="'py-14 relative overflow-hidden ' + gradient(cours()!.niveau)">
      <div class="absolute inset-0 opacity-10"
           style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:28px 28px" aria-hidden="true"></div>
      <div class="container relative">
        <nav class="flex items-center gap-2 text-sm text-white/70 mb-6" aria-label="Fil d'Ariane">
          <a routerLink="/" class="hover:text-white transition-colors">Accueil</a>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
          <a routerLink="/catalogue" class="hover:text-white transition-colors">Catalogue</a>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
          <span class="text-white truncate max-w-xs">{{ cours()!.titre }}</span>
        </nav>

        <div class="max-w-3xl">
          <span class="badge bg-white/20 text-white border-white/30 mb-4">
            {{ niveauLabel(cours()!.niveau) }}
          </span>
          <h1 class="text-3xl md:text-4xl font-black text-white mb-4 leading-tight"
              style="font-family:var(--font);">
            {{ cours()!.titre }}
          </h1>
          <p class="text-lg text-white/85 leading-relaxed mb-6">{{ cours()!.description }}</p>

          <div class="flex flex-wrap items-center gap-5 text-sm text-white/75">
            <span class="flex items-center gap-1.5">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
              {{ cours()!.nbApprenants }} apprenants
            </span>
            @if (cours()!.noteMoyenne) {
              <span class="flex items-center gap-1.5">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="#fbbf24" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                {{ cours()!.noteMoyenne }} / 5 ({{ cours()!.nbAvis }} avis)
              </span>
            }
          </div>
        </div>
      </div>
    </div>

    <!-- Contenu principal -->
    <div class="container py-12">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-10">

        <!-- Colonne gauche -->
        <div class="lg:col-span-2 space-y-8">

          <!-- Ce que vous apprendrez -->
          <div class="card p-6">
            <h2 class="h3 mb-5">Ce que vous apprendrez</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              @for (item of learnings; track item) {
                <div class="flex items-start gap-2.5">
                  <div class="w-5 h-5 rounded-full bg-green-100 flex items-center justify-center shrink-0 mt-0.5">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  </div>
                  <p class="text-sm text-slate-700">{{ item }}</p>
                </div>
              }
            </div>
          </div>

          <!-- Sessions disponibles (S09) -->
          @if (sessions().length > 0) {
            <div class="card p-6">
              <h2 class="h3 mb-5">Sessions avec formateur</h2>
              <div class="space-y-4">
                @for (s of sessions(); track s.id) {
                  <div class="border border-slate-200 rounded-xl p-4 hover:border-blue-200 transition-colors">
                    <div class="flex items-start justify-between gap-4">
                      <div>
                        <div class="flex items-center gap-2 mb-2">
                          <span [class]="'badge ' + modaliteBadge(s.modalite)">
                            {{ s.modalite === 'MEET' ? '💻 En ligne' : s.modalite === 'PRESENTIEL' ? '📍 Présentiel' : '🔀 Hybride' }}
                          </span>
                          @if (s.placesRestantes === 0) {
                            <span class="badge-red">Complet</span>
                          } @else if (s.placesRestantes <= 3) {
                            <span class="badge-amber">{{ s.placesRestantes }} places restantes</span>
                          }
                        </div>
                        <h3 class="font-semibold text-slate-900 text-sm">{{ s.titre }}</h3>
                        <p class="text-xs text-slate-500 mt-1">
                          Du {{ s.dateDebut | date:'dd/MM/yyyy':'':'fr' }} au {{ s.dateFin | date:'dd/MM/yyyy':'':'fr' }}
                          @if (s.lieu) { · {{ s.lieu }} }
                        </p>
                      </div>
                      <div class="text-right shrink-0">
                        <p class="text-xs text-slate-400">{{ s.nbInscrits }}/{{ s.capaciteMax }}</p>
                      </div>
                    </div>
                  </div>
                }
              </div>
            </div>
          }
        </div>

        <!-- Carte d'action (sticky) -->
        <div class="lg:col-span-1">
          <div class="card p-6 sticky top-20">
            <!-- Prix + freemium -->
            <div class="mb-5">
              <div class="flex items-baseline gap-2 mb-1">
                <span class="text-3xl font-black text-slate-900">{{ cours()!.prixAffichage }}</span>
              </div>
              <p class="text-sm text-green-600 font-medium flex items-center gap-1.5">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                {{ (cours()!.seuilPaiement * 100) | number:'1.0-0' }}% accessible gratuitement
              </p>

              <div class="progress mt-3">
                <div class="progress-bar bg-green-500" [style.width.%]="cours()!.seuilPaiement * 100"></div>
              </div>
            </div>

            <!-- CTA -->
            @if (isAuth()) {
              <a [routerLink]="['/app/cours', cours()!.slug]" class="btn-primary w-full btn-lg mb-3">
                Commencer ce cours
              </a>
            } @else {
              <a routerLink="/auth/inscription" class="btn-primary w-full btn-lg mb-3">
                Commencer gratuitement
              </a>
              <a routerLink="/auth/connexion" class="btn-secondary w-full mb-3">J'ai déjà un compte</a>
            }

            <!-- Avantages -->
            <ul class="space-y-2.5 mt-4">
              @for (av of avantages; track av) {
                <li class="flex items-center gap-2 text-sm text-slate-600">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  {{ av }}
                </li>
              }
            </ul>
          </div>
        </div>
      </div>
    </div>
  }
</div>
  `,
})
export class CourseDetailComponent implements OnInit {
  readonly slug = input<string>('');

  readonly #courseSvc   = inject(CourseService);
  readonly #sessionsSvc = inject(SessionService);
  readonly #auth        = inject(AuthService);

  readonly cours    = signal<CoursResponse | null>(MOCK_COURS[0]);
  readonly sessions = signal<SessionResponse[]>(MOCK_SESSIONS);
  readonly loading  = signal(true);
  readonly isAuth   = this.#auth.isAuthenticated;

  readonly learnings = [
    'Créer des interfaces web modernes', 'Maîtriser les fondamentaux du développement',
    'Concevoir des bases de données', 'Déployer une application en production',
    'Utiliser Git et les outils modernes', 'Développer des APIs REST',
  ];

  readonly avantages = [
    'Accès à vie au contenu', 'Certificat officiel MbemNova',
    'Paiement en tranches possible', 'Communauté d\'entraide',
  ];

  ngOnInit(): void {
    const s = this.slug();
    if (!s) return;
    this.loading.set(true);
    this.#courseSvc.getBySlug(s).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.cours.set(r.data);
          this.loading.set(false);
          this.#loadSessions(r.data.id);
        }
      },
      error: () => { this.loading.set(false); },
    });
  }

  #loadSessions(coursId: string): void {
    this.#sessionsSvc.getByCours(coursId).subscribe({
      next: r => { if (r.success && r.data) this.sessions.set(r.data.content); },
    });
  }

  gradient(n: string): string {
    return { DEBUTANT: 'bg-gradient-to-br from-emerald-600 to-green-800', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-600 to-indigo-800', AVANCE: 'bg-gradient-to-br from-purple-600 to-violet-800' }[n] ?? 'bg-blue-800';
  }
  niveauLabel(n: string): string { return { DEBUTANT: '🌱 Débutant', INTERMEDIAIRE: '⚡ Intermédiaire', AVANCE: '🚀 Avancé' }[n] ?? n; }
  modaliteBadge(m: string): string { return { MEET: 'badge-blue', PRESENTIEL: 'badge-green', HYBRIDE: 'badge-purple' }[m] ?? 'badge-slate'; }
}
EOF
ok "CourseDetail"

# ============================================================
# 4. CERTIFICATE VERIFY
# ============================================================
sec "4/5 — CertificateVerify"

cat > src/app/features/public/certificate-verify/certificate-verify.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, input, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import type { CertificatResponse } from '../../../core/models';

@Component({
  selector: 'app-certificate-verify',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex items-center justify-center p-4 py-16">
  <div class="w-full max-w-lg animate-fade-up">

    @if (loading()) {
      <div class="card p-10 text-center">
        <div class="shimmer w-20 h-20 rounded-full mx-auto mb-6"></div>
        <div class="shimmer h-6 rounded w-2/3 mx-auto mb-3"></div>
        <div class="shimmer h-4 rounded w-1/2 mx-auto"></div>
      </div>
    }

    @if (!loading() && cert()) {
      <div class="card overflow-hidden">
        <!-- En-tête colorée -->
        <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-8 text-center">
          <!-- Illustration certificat -->
          <div class="flex justify-center mb-4">
            <svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
              <circle cx="40" cy="40" r="40" fill="rgba(255,255,255,0.2)"/>
              <circle cx="40" cy="32" r="18" fill="white" opacity="0.9"/>
              <path d="M31 32l6 6 12-12" stroke="#d97706" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M27 56l-5 10 18-6 18 6-5-10" fill="white" opacity="0.7"/>
              <circle cx="40" cy="32" r="14" stroke="white" stroke-width="2" opacity="0.5"/>
            </svg>
          </div>
          <h1 class="text-2xl font-black text-white mb-1">Certificat Valide ✓</h1>
          <p class="text-amber-100 text-sm">Ce certificat est authentique et vérifié par MbemNova</p>
        </div>

        <!-- Détails -->
        <div class="p-8">
          <div class="text-center mb-8">
            <p class="text-xs text-slate-500 uppercase tracking-wide mb-1">Formation certifiée</p>
            <h2 class="text-xl font-bold text-slate-900">{{ cert()!.coursTitre ?? 'Formation MbemNova' }}</h2>
          </div>

          <div class="space-y-4">
            <div class="flex items-center justify-between py-3 border-b border-slate-100">
              <span class="text-sm text-slate-500">Code de vérification</span>
              <code class="text-sm font-mono font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded">
                {{ cert()!.codeVerification }}
              </code>
            </div>
            <div class="flex items-center justify-between py-3 border-b border-slate-100">
              <span class="text-sm text-slate-500">Date d'obtention</span>
              <span class="text-sm font-semibold text-slate-900">
                {{ cert()!.dateEmission | date:'dd MMMM yyyy':'':'fr' }}
              </span>
            </div>
            <div class="flex items-center justify-between py-3">
              <span class="text-sm text-slate-500">Délivré par</span>
              <span class="text-sm font-semibold text-blue-700">MbemNova</span>
            </div>
          </div>

          <div class="flex gap-3 mt-8">
            <a [href]="cert()!.lienPdf" target="_blank" rel="noopener"
               class="btn-primary flex-1 justify-center">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Télécharger PDF
            </a>
            <a routerLink="/catalogue" class="btn-secondary flex-1 justify-center">Voir les formations</a>
          </div>
        </div>
      </div>
    }

    @if (!loading() && !cert()) {
      <div class="card p-10 text-center">
        <div class="w-20 h-20 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-5">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
        </div>
        <h2 class="h3 mb-2">Certificat introuvable</h2>
        <p class="text-slate-500 text-sm mb-6">
          Le code de vérification <code class="font-mono bg-slate-100 px-1.5 py-0.5 rounded text-xs">{{ code() }}</code>
          ne correspond à aucun certificat valide.
        </p>
        <a routerLink="/" class="btn-secondary">Retour à l'accueil</a>
      </div>
    }
  </div>
</div>
  `,
})
export class CertificateVerifyComponent implements OnInit {
  readonly code = input<string>('');
  readonly #svc = inject(TalentService);

  readonly cert    = signal<CertificatResponse | null>(null);
  readonly loading = signal(true);

  ngOnInit(): void {
    const c = this.code();
    if (!c || c === 'demo') {
      // Demo : montrer un exemple
      this.cert.set({
        id: 'demo', coursId: 'c-003', codeVerification: 'MBEM-2025-DEMO',
        lienPdf: '#', dateEmission: new Date().toISOString(), coursTitre: 'Python & Data Science',
      });
      this.loading.set(false);
      return;
    }
    this.#svc.verifierCertificat(c).subscribe({
      next: r => { this.cert.set(r.data); this.loading.set(false); },
      error: () => { this.cert.set(null); this.loading.set(false); },
    });
  }
}
EOF
ok "CertificateVerify"

# ============================================================
# 5. PRIVACY POLICY — S28
# ============================================================
sec "5/5 — PrivacyPolicy (S28)"

cat > src/app/features/public/privacy-policy/privacy-policy.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-privacy-policy',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-white">
  <!-- Header -->
  <div class="bg-slate-900 py-14">
    <div class="container max-w-4xl">
      <nav class="flex items-center gap-2 text-sm text-slate-400 mb-6" aria-label="Fil d'Ariane">
        <a routerLink="/" class="hover:text-white transition-colors">Accueil</a>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
        <span class="text-white">Politique de confidentialité</span>
      </nav>
      <h1 class="text-3xl font-black text-white mb-2">Politique de confidentialité</h1>
      <p class="text-slate-400">Dernière mise à jour : janvier 2025</p>
    </div>
  </div>

  <!-- Contenu -->
  <div class="container max-w-4xl py-14">
    <div class="prose prose-slate max-w-none">

      <!-- Intro -->
      <div class="card p-6 mb-8 bg-blue-50 border-blue-200">
        <p class="text-sm text-blue-900 leading-relaxed">
          <strong>MbemNova</strong> s'engage à protéger la vie privée de ses utilisateurs.
          Cette politique décrit comment nous collectons, utilisons et protégeons vos données
          personnelles conformément aux lois en vigueur en Afrique Centrale.
        </p>
      </div>

      <!-- Données collectées -->
      <section class="mb-10">
        <h2 class="h2 mb-5">1. Données collectées</h2>
        <div class="overflow-x-auto">
          <table class="w-full border-collapse">
            <thead>
              <tr class="bg-slate-900 text-white">
                <th class="px-4 py-3 text-left text-sm font-semibold rounded-tl-lg">Donnée</th>
                <th class="px-4 py-3 text-left text-sm font-semibold">Moment de collecte</th>
                <th class="px-4 py-3 text-left text-sm font-semibold">Finalité</th>
                <th class="px-4 py-3 text-left text-sm font-semibold rounded-tr-lg">Conservation</th>
              </tr>
            </thead>
            <tbody>
              @for (row of dataTable; track row.data; let i = $index) {
                <tr [class]="i % 2 === 0 ? 'bg-white' : 'bg-slate-50'">
                  <td class="px-4 py-3 text-sm font-medium text-slate-900 border-b border-slate-100">{{ row.data }}</td>
                  <td class="px-4 py-3 text-sm text-slate-600 border-b border-slate-100">{{ row.when }}</td>
                  <td class="px-4 py-3 text-sm text-slate-600 border-b border-slate-100">{{ row.why }}</td>
                  <td class="px-4 py-3 text-sm text-slate-600 border-b border-slate-100">{{ row.duration }}</td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </section>

      <!-- Droits -->
      <section class="mb-10">
        <h2 class="h2 mb-5">2. Vos droits</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          @for (right of rights; track right.title) {
            <div class="card p-5">
              <div class="flex items-center gap-3 mb-2">
                <span class="text-2xl" aria-hidden="true">{{ right.icon }}</span>
                <h3 class="font-semibold text-slate-900 text-sm">{{ right.title }}</h3>
              </div>
              <p class="text-sm text-slate-500 leading-relaxed">{{ right.desc }}</p>
            </div>
          }
        </div>
      </section>

      <!-- Sécurité -->
      <section class="mb-10">
        <h2 class="h2 mb-5">3. Sécurité des données</h2>
        <div class="space-y-3">
          @for (item of security; track item) {
            <div class="flex items-start gap-3">
              <div class="w-5 h-5 rounded-full bg-green-100 flex items-center justify-center shrink-0 mt-0.5">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
              </div>
              <p class="text-sm text-slate-700">{{ item }}</p>
            </div>
          }
        </div>
      </section>

      <!-- Cookies -->
      <section class="mb-10">
        <h2 class="h2 mb-5">4. Cookies</h2>
        <div class="space-y-3">
          @for (cookie of cookies; track cookie.name) {
            <div class="border border-slate-200 rounded-xl p-4">
              <div class="flex items-center justify-between mb-1">
                <h3 class="font-semibold text-sm text-slate-900">{{ cookie.name }}</h3>
                <span [class]="cookie.required ? 'badge-green' : 'badge-amber'">
                  {{ cookie.required ? 'Obligatoire' : 'Optionnel' }}
                </span>
              </div>
              <p class="text-xs text-slate-500">{{ cookie.desc }}</p>
            </div>
          }
        </div>
      </section>

      <!-- Contact -->
      <section class="card p-6 bg-slate-50 border-slate-200">
        <h2 class="h3 mb-3">5. Contact</h2>
        <p class="text-sm text-slate-600 mb-2">
          Pour toute question relative à vos données personnelles :
        </p>
        <p class="text-sm">
          📧 <a href="mailto:privacy@mbemnova.com" class="link font-medium">privacy&#64;mbemnova.com</a>
        </p>
        <p class="text-sm text-slate-500 mt-2">Délai de réponse garanti : 30 jours ouvrables.</p>
      </section>
    </div>

    <div class="mt-10 text-center">
      <a routerLink="/auth/inscription" class="btn-primary btn-lg">
        Je comprends et je m'inscris
      </a>
    </div>
  </div>
</div>
  `,
})
export class PrivacyPolicyComponent {
  readonly dataTable = [
    { data: 'Prénom, Nom',         when: 'Inscription',          why: 'Personnalisation, certificats',    duration: 'Durée compte + 2 ans' },
    { data: 'Email',               when: 'Inscription',          why: 'Authentification, notifications', duration: 'Durée du compte' },
    { data: 'Téléphone',           when: 'Progressif',           why: 'WhatsApp, relances paiement',     duration: 'Durée du compte' },
    { data: 'Mot de passe (haché)',when: 'Inscription',          why: 'Authentification',                duration: 'Durée du compte' },
    { data: 'Adresse IP',          when: 'Chaque connexion',     why: 'Sécurité, prévention fraude',     duration: '90 jours' },
    { data: 'Progression cours',   when: 'Pendant apprentissage',why: 'Service principal',               duration: 'Durée du compte' },
    { data: 'Données de paiement', when: 'Lors du paiement',     why: 'Facturation, comptabilité',       duration: '10 ans (obligation légale)' },
    { data: 'CV uploadé',          when: 'Si l\'apprenant le fait',why: 'Profil talent, recrutement',    duration: 'Jusqu\'à suppression' },
    { data: 'Messages communauté', when: 'Pendant utilisation',  why: 'Service communauté',              duration: 'Durée du compte' },
  ];

  readonly rights = [
    { icon: '👁️',  title: 'Droit d\'accès',      desc: 'Demandez la liste complète de vos données via les paramètres. Réponse sous 30 jours.' },
    { icon: '✏️',  title: 'Droit de rectification', desc: 'Modifiez vos données directement depuis votre profil (prénom, email, téléphone).' },
    { icon: '🗑️', title: 'Droit à l\'effacement', desc: 'Supprimez votre compte. Les données non légalement obligatoires sont effacées sous 30 jours.' },
    { icon: '🚫',  title: 'Droit d\'opposition',  desc: 'Désactivez les emails marketing et notifications non critiques dans vos paramètres.' },
    { icon: '📦',  title: 'Portabilité',          desc: 'Exportez toutes vos données (progression, certificats) en JSON ou PDF depuis votre profil.' },
    { icon: '⏸️',  title: 'Droit de limitation',  desc: 'Limitez le traitement de vos données en nous contactant à privacy@mbemnova.com.' },
  ];

  readonly security = [
    'Connexions HTTPS uniquement — chiffrement TLS 1.3',
    'Mots de passe hachés avec BCrypt (coût 12) — jamais stockés en clair',
    'Tokens JWT stockés en mémoire côté client — pas dans localStorage',
    'Rate limiting : 100 requêtes/minute par IP',
    'Sauvegardes automatiques chiffrées — rétention 30 jours',
    'Authentification 2FA recommandée pour les comptes admin',
    'Logs d\'audit pour toutes les actions sensibles (paiement, changement rôle)',
    'Protection OWASP Top 10 — XSS, CSRF, injection SQL',
  ];

  readonly cookies = [
    { name: 'Session JWT (refresh)',  required: true,  desc: 'Maintient votre connexion sécurisée. HttpOnly — non accessible au JavaScript.' },
    { name: 'Préférences interface',  required: false, desc: 'Mémorise vos préférences d\'affichage (thème, langue). Désactivable.' },
    { name: 'Analytics anonymisés',  required: false, desc: 'Mesure d\'audience anonymisée pour améliorer la plateforme. Désactivable.' },
  ];
}
EOF
ok "PrivacyPolicy"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 05 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  Landing          (hero · tirage · catalogue · étapes · leaderboard · CTA)"
echo -e "  ${G}✓${N}  Catalog          (filtres · skeleton · pagination · empty state)"
echo -e "  ${G}✓${N}  CourseDetail     (S04 · sessions disponibles · carte d'action sticky)"
echo -e "  ${G}✓${N}  CertificateVerify (vérification publique · illustration SVG)"
echo -e "  ${G}✓${N}  PrivacyPolicy    (S28 · tableau données · droits RGPD · sécurité)"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng06_auth_pages.sh${N}"
echo ""
