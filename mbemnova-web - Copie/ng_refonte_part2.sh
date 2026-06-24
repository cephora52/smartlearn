#!/usr/bin/env bash
# ============================================================
# MbemNova · Refonte Part 2 — UX Pro + Performance
# ============================================================
# Contenu :
#   1. Landing         — style Xarala Academy (image ci-dessus)
#   2. Catalog         — cards modernes + skeleton + filtres
#   3. CourseDetail    — page détail pro + avis vérifiés
#   4. Auth pages      — login/register optimisés
#   5. Dashboard       — KPIs réels + skeleton propre
#   6. styles.css      — utilitaires manquants
#   7. tailwind.config — fixes
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
[[ ! -f "angular.json" ]] && echo "Lancez depuis la racine" && exit 1

mkdir -p \
  src/app/features/public/landing \
  src/app/features/public/catalog \
  src/app/features/public/course-detail \
  src/app/features/auth/login \
  src/app/features/auth/register \
  src/app/features/auth/forgot-password \
  src/app/features/auth/reset-password \
  src/app/features/learner/dashboard

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · Refonte Part 2 · UX Pro      ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. LANDING — style Xarala Academy
# ============================================================
sec "1/7 — Landing (style Xarala)"

cat > src/app/features/public/landing/landing.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
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

  <!-- ── HERO (style Xarala — fond sombre + badge + stats) ── -->
  <section class="relative bg-slate-950 overflow-hidden">
    <!-- Motif grille subtil -->
    <div class="absolute inset-0 opacity-[0.04]"
         style="background-image:linear-gradient(white 1px,transparent 1px),linear-gradient(90deg,white 1px,transparent 1px);background-size:60px 60px"></div>
    <!-- Blobs lumineux -->
    <div class="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-600/10 rounded-full blur-[120px] pointer-events-none"></div>
    <div class="absolute bottom-0 left-0 w-[400px] h-[400px] bg-indigo-600/10 rounded-full blur-[100px] pointer-events-none"></div>

    <div class="container relative py-20 md:py-28 lg:py-32">
      <div class="max-w-3xl">

        <!-- Badge social proof (style Xarala) -->
        <div class="inline-flex items-center gap-2 bg-white/5 border border-white/10
                    rounded-full px-4 py-2 text-sm text-slate-300 mb-8 animate-fade-up">
          <div class="flex -space-x-1.5">
            @for (c of ['bg-blue-500','bg-green-500','bg-purple-500','bg-amber-500']; track c) {
              <div [class]="'w-6 h-6 rounded-full border-2 border-slate-950 flex items-center justify-center text-white text-xs font-bold ' + c">
                {{ ['J','D','S','P'][['bg-blue-500','bg-green-500','bg-purple-500','bg-amber-500'].indexOf(c)] }}
              </div>
            }
          </div>
          <span>{{ stats[0].value }} apprenants actifs en Afrique Centrale</span>
        </div>

        <!-- Titre principal -->
        <h1 class="text-4xl sm:text-5xl lg:text-[3.5rem] font-black text-white leading-[1.1] mb-6 animate-fade-up delay-75"
            style="font-family:var(--font);">
          Décrochez un <span class="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 via-blue-300 to-cyan-300">vrai métier tech</span><br>
          en 3 à 6 mois, depuis l'Afrique
        </h1>

        <p class="text-lg text-slate-400 leading-relaxed mb-8 max-w-2xl animate-fade-up delay-100">
          Formations intensives en Développement, Data, IA et Marketing Digital.
          Mentor dédié, projets concrets, stage en entreprise, paiement flexible.
          <strong class="text-slate-200">87% de nos diplômés</strong> trouvent un emploi en 6 mois.
        </p>

        <!-- CTA double -->
        <div class="flex flex-wrap gap-3 mb-12 animate-fade-up delay-150">
          <a routerLink="/auth/inscription"
             class="btn bg-blue-600 hover:bg-blue-500 text-white px-7 py-3.5 text-base
                    font-semibold shadow-xl shadow-blue-900/30 transition-all duration-150">
            Voir les bootcamps
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
          </a>
          <a routerLink="/catalogue"
             class="btn bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10 px-7 py-3.5 text-base">
            Ou explorons les cours gratuits →
          </a>
        </div>

        <!-- Stats clés (style Xarala) -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-6 pt-8 border-t border-white/5 animate-fade-up delay-200">
          @for (s of stats; track s.label) {
            <div>
              <p class="text-2xl sm:text-3xl font-black text-white">{{ s.value }}</p>
              <p class="text-xs text-slate-500 mt-0.5 leading-snug">{{ s.label }}</p>
            </div>
          }
        </div>
      </div>
    </div>

    <!-- Vague de transition -->
    <div class="absolute bottom-0 left-0 right-0 h-16 bg-white"
         style="clip-path:ellipse(55% 100% at 50% 100%)"></div>
  </section>

  <!-- ── DOMAINES (filtre rapide) ──────────────────────── -->
  <section class="bg-white py-10 border-b border-slate-100">
    <div class="container">
      <p class="text-xs font-semibold text-slate-400 uppercase tracking-widest mb-5 text-center">
        Quel domaine voulez-vous cibler ?
      </p>
      <div class="flex flex-wrap justify-center gap-2.5">
        @for (d of domaines; track d.label) {
          <a [routerLink]="['/catalogue']" [queryParams]="{ q: d.label }"
             [class]="'flex items-center gap-2 px-4 py-2 rounded-full text-sm border transition-all duration-150 '
                      + (d.active
                      ? 'bg-blue-600 text-white border-blue-600'
                      : 'bg-white text-slate-600 border-slate-200 hover:border-blue-300 hover:bg-blue-50')">
            <span aria-hidden="true">{{ d.icon }}</span>
            {{ d.label }}
          </a>
        }
      </div>
    </div>
  </section>

  <!-- ── BOOTCAMPS / COURS (cartes style Xarala) ───────── -->
  <section class="section">
    <div class="container">
      <div class="flex items-end justify-between mb-10">
        <div>
          <p class="text-blue-600 font-semibold text-sm uppercase tracking-wide mb-1.5">Nos bootcamps</p>
          <h2 class="h2">De zéro à l'emploi en quelques semaines</h2>
          <p class="text-slate-500 mt-2 max-w-lg">
            Formation intensive + mentor + stage en entreprise garantis.
          </p>
        </div>
        <a routerLink="/catalogue" class="btn-secondary hidden sm:flex shrink-0 ml-6">
          Découvrir tous les bootcamps
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
        </a>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        @for (c of featured(); track c.id; let i = $index) {
          <a [routerLink]="['/cours', c.slug]"
             class="group flex flex-col bg-white rounded-2xl border border-slate-200
                    hover:border-blue-200 hover:shadow-lg transition-all duration-200 overflow-hidden"
             [style]="'animation-delay:' + (i * 60) + 'ms'"
             [attr.aria-label]="'Formation ' + c.titre">

            <!-- Bannière niveau colorée -->
            <div [class]="'h-44 relative overflow-hidden ' + levelGradient(c.niveau)">
              <!-- Pattern décoratif -->
              <div class="absolute inset-0 opacity-10"
                   style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:24px 24px" aria-hidden="true"></div>
              <!-- Badge type -->
              <div class="absolute top-3 left-3">
                <span class="inline-flex items-center gap-1.5 bg-black/30 backdrop-blur-sm text-white text-xs font-semibold px-2.5 py-1 rounded-full">
                  <span aria-hidden="true">{{ levelEmoji(c.niveau) }}</span>
                  Bootcamp {{ levelLabel(c.niveau) }}
                </span>
              </div>
              <!-- Stats en bas bannière -->
              <div class="absolute bottom-3 right-3 flex items-center gap-3">
                @if (c.noteMoyenne) {
                  <div class="flex items-center gap-1 bg-black/30 backdrop-blur-sm rounded-full px-2 py-0.5">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="#fbbf24" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    <span class="text-white text-xs font-bold">{{ c.noteMoyenne }}</span>
                    <span class="text-white/70 text-xs">({{ c.nbAvis }})</span>
                  </div>
                }
                <div class="flex items-center gap-1 bg-black/30 backdrop-blur-sm rounded-full px-2 py-0.5">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                  <span class="text-white text-xs font-bold">{{ c.nbApprenants }}</span>
                </div>
              </div>
            </div>

            <!-- Contenu carte -->
            <div class="flex-1 flex flex-col p-5">
              <h3 class="font-bold text-slate-900 text-base leading-snug mb-2 group-hover:text-blue-700 transition-colors">
                {{ c.titre }}
              </h3>
              <p class="text-sm text-slate-500 leading-relaxed mb-4 flex-1 line-clamp-2">
                {{ c.descriptionCourte }}
              </p>

              <!-- Méta infos -->
              <div class="flex items-center gap-3 text-xs text-slate-400 mb-4">
                <span class="flex items-center gap-1">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  {{ Math.floor(c.dureeTotaleMinutes / 60) }}h de contenu
                </span>
                <span class="flex items-center gap-1">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                  {{ c.nbLecons }} leçons
                </span>
              </div>

              <!-- Prix + barre freemium -->
              <div>
                <div class="flex items-center justify-between text-xs mb-1.5">
                  <span class="text-green-600 font-semibold">
                    {{ (c.seuilPaiement * 100) | number:'1.0-0' }}% gratuit
                  </span>
                  <span class="font-bold text-slate-800">{{ c.prixFcfa | number:'1.0-0' }} FCFA</span>
                </div>
                <div class="h-1.5 bg-slate-100 rounded-full overflow-hidden mb-4">
                  <div class="h-full bg-green-500 rounded-full" [style.width.%]="c.seuilPaiement * 100"></div>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-xs text-green-600 font-medium flex items-center gap-1">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                    Commencer gratuitement
                  </span>
                  <span class="text-blue-600 text-sm font-semibold group-hover:gap-2 flex items-center gap-1 transition-all">
                    Voir
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                  </span>
                </div>
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

  <!-- ── TIRAGE AU SORT ─────────────────────────────────── -->
  <section class="bg-gradient-to-r from-amber-50 to-orange-50 border-y border-amber-100 py-8">
    <div class="container">
      <div class="flex flex-col sm:flex-row items-start sm:items-center gap-5 justify-between">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-2xl bg-amber-100 flex items-center justify-center shrink-0 text-2xl" aria-hidden="true">🎟️</div>
          <div>
            <span class="badge-amber text-xs mb-1.5 inline-flex">Tirage mensuel</span>
            <h3 class="font-bold text-slate-900">Gagnez la formation
              <span class="text-amber-700">{{ draw().formationGagnanteTitre }}</span>
              gratuitement
            </h3>
            <p class="text-sm text-slate-500 mt-0.5">
              {{ draw().prixTicketFcfa | number:'1.0-0' }} FCFA / ticket ·
              {{ draw().nbTicketsVendus }} participants ·
              Tirage le {{ draw().dateDrawFormatee }}
            </p>
          </div>
        </div>
        <a routerLink="/auth/inscription"
           class="btn bg-amber-600 hover:bg-amber-700 text-white px-5 py-2.5 shrink-0 text-sm">
          Acheter un ticket
        </a>
      </div>
    </div>
  </section>

  <!-- ── MÉTHODE PÉDAGOGIQUE ───────────────────────────── -->
  <section class="section bg-slate-50">
    <div class="container">
      <div class="text-center mb-12">
        <p class="text-blue-600 font-semibold text-sm uppercase tracking-wide mb-2">Notre méthode</p>
        <h2 class="h2">Une méthode qui transforme les<br>
          <span class="text-blue-600">débutants en professionnels</span>
        </h2>
        <p class="text-slate-500 mt-3 max-w-xl mx-auto">
          Pas de cours passifs. Pas de théorie sans pratique. Chaque approche est pensée pour l'Afrique, avec les contraintes de l'Afrique.
        </p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        @for (m of methode; track m.title; let i = $index) {
          <div class="bg-white rounded-2xl p-6 border border-slate-200 hover:border-blue-200
                      hover:shadow-md transition-all duration-200 animate-fade-up"
               [style]="'animation-delay:' + (i * 60) + 'ms'">
            <div class="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center text-2xl mb-4" aria-hidden="true">
              {{ m.icon }}
            </div>
            <h3 class="font-bold text-slate-900 mb-2">{{ m.title }}</h3>
            <p class="text-sm text-slate-500 leading-relaxed">{{ m.desc }}</p>
          </div>
        }
      </div>
    </div>
  </section>

  <!-- ── TÉMOIGNAGES / TOP TALENTS ─────────────────────── -->
  <section class="section">
    <div class="container">
      <div class="text-center mb-10">
        <p class="text-blue-600 font-semibold text-sm uppercase tracking-wide mb-2">Communauté</p>
        <h2 class="h2">+{{ stats[0].value }} apprenants ont choisi MbemNova</h2>
      </div>

      <!-- Top 3 leaderboard -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-5 mb-12">
        @for (t of topTalents; track t.userId; let i = $index) {
          <div [class]="'rounded-2xl p-5 border text-center ' + rankBg(i)">
            <div class="text-3xl mb-2" aria-hidden="true">{{ rankEmoji(i) }}</div>
            <div class="w-14 h-14 rounded-full bg-blue-600 flex items-center justify-center
                        text-white text-xl font-black mx-auto mb-3">
              {{ t.prenom.charAt(0) }}
            </div>
            <p class="font-bold text-slate-900 mb-1">{{ t.prenom }}</p>
            <div class="flex justify-center gap-3 text-xs text-slate-500">
              <span class="flex items-center gap-1">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                {{ t.xpTotal | number:'1.0-0' }} XP
              </span>
              <span>🔥 {{ t.streakJours }}j</span>
            </div>
          </div>
        }
      </div>
    </div>
  </section>

  <!-- ── PARTENAIRES / RECRUTEURS ─────────────────────── -->
  <section class="py-10 bg-slate-50 border-y border-slate-100">
    <div class="container text-center">
      <p class="text-sm text-slate-400 mb-6">+50 entreprises recrutent nos diplômés</p>
      <div class="flex flex-wrap justify-center items-center gap-8">
        @for (p of partenaires; track p) {
          <span class="text-slate-400 font-bold text-sm hover:text-slate-600 transition-colors">{{ p }}</span>
        }
      </div>
    </div>
  </section>

  <!-- ── CTA FINAL ─────────────────────────────────────── -->
  <section class="section">
    <div class="container">
      <div class="relative bg-blue-600 rounded-3xl overflow-hidden px-8 py-14 md:px-16 text-center">
        <div class="absolute inset-0 opacity-10"
             style="background-image:radial-gradient(circle at 20% 50%,white 1px,transparent 1px),radial-gradient(circle at 80% 50%,white 1px,transparent 1px);background-size:30px 30px" aria-hidden="true"></div>
        <h2 class="text-3xl md:text-4xl font-black text-white mb-3 relative">
          Prêt à changer de carrière ?
        </h2>
        <p class="text-blue-100 text-lg mb-8 relative max-w-xl mx-auto">
          Rejoignez {{ stats[0].value }} apprenants qui développent leurs compétences tech avec MbemNova.
        </p>
        <div class="flex flex-wrap gap-3 justify-center relative">
          <a routerLink="/auth/inscription"
             class="btn bg-white text-blue-700 hover:bg-blue-50 px-8 py-3.5 text-base font-bold shadow-xl">
            S'inscrire gratuitement
          </a>
          <a href="https://wa.me/237600000000" target="_blank" rel="noopener"
             class="btn bg-white/10 hover:bg-white/20 text-white border border-white/20 px-6 py-3.5 text-base">
            Parler à un conseiller
          </a>
        </div>
      </div>
    </div>
  </section>

</div>
  `,
})
export class LandingComponent implements OnInit {
  readonly #courseSvc = inject(CourseService);
  readonly #talentSvc = inject(TalentService);
  readonly Math = Math;

  readonly cours   = signal<CoursResponse[]>(MOCK_COURS);
  readonly draw    = signal<DrawResponse>(MOCK_DRAW);
  readonly featured = () => this.cours().slice(0, 6);
  readonly topTalents = MOCK_LEADERBOARD.slice(0, 3);

  readonly stats = [
    { value: '247+',  label: 'apprenants actifs en Afrique Centrale' },
    { value: '2 000+',label: 'diplômés depuis 2020' },
    { value: '4.1/5', label: 'note moyenne sur Trustpilot' },
    { value: '87%',   label: 'trouvent un emploi en 6 mois' },
  ];

  readonly domaines = [
    { icon: '💻', label: 'Développement Web',    active: false },
    { icon: '📊', label: 'Data & IA',            active: false },
    { icon: '🎨', label: 'Design Graphique',     active: false },
    { icon: '📱', label: 'Marketing Digital',    active: false },
    { icon: '🔐', label: 'Réseaux & Sécurité',  active: false },
    { icon: '📈', label: 'No-Code & Saas',       active: false },
  ];

  readonly methode = [
    { icon: '👨‍🏫', title: 'Un mentor dédié',          desc: 'Un expert guide votre apprentissage de A à Z. Sessions live, corrections personnalisées.' },
    { icon: '🏢', title: 'Un stage en entreprise',    desc: 'Accédez à notre réseau de partenaires pour un stage de 1 à 3 mois en fin de bootcamp.' },
    { icon: '💳', title: 'Un paiement flexible',      desc: 'Payez en plusieurs fois. Cash, Mobile Money ou virement. Adapté à votre situation.' },
    { icon: '🛠️', title: 'Des projets concrets',      desc: 'Chaque module aboutit à un projet réel que vous ajoutez à votre portfolio.' },
    { icon: '🏆', title: 'Un certificat reconnu',     desc: 'Obtenez un certificat officiel MbemNova vérifiable en ligne par les recruteurs.' },
    { icon: '⚡', title: 'Un format rapide',          desc: '6 à 8 semaines intensives pour être opérationnel. Même avec un emploi à temps partiel.' },
  ];

  readonly partenaires = ['Orange', 'MTN', 'Express Union', 'Digital Africa', 'TechPoint', 'PayDunya', 'Afrikpay'];

  ngOnInit(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.cours.set(r.data.content); },
    });
    this.#talentSvc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); },
    });
  }

  levelGradient(n: string): string {
    return { DEBUTANT: 'bg-gradient-to-br from-emerald-500 to-green-700', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-500 to-indigo-700', AVANCE: 'bg-gradient-to-br from-purple-600 to-violet-700' }[n] ?? 'bg-blue-700';
  }
  levelEmoji(n: string): string    { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  levelLabel(n: string): string    { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
  rankEmoji(i: number): string     { return ['🥇','🥈','🥉'][i] ?? '#'; }
  rankBg(i: number): string        { return ['bg-amber-50 border-amber-200','bg-slate-50 border-slate-200','bg-orange-50 border-orange-200'][i] ?? 'bg-white border-slate-200'; }
}
EOF
ok "Landing"

# ============================================================
# 2. CATALOG — Optimisé + filtres + skeleton propre
# ============================================================
sec "2/7 — Catalog"

cat > src/app/features/public/catalog/catalog.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink, ActivatedRoute } from '@angular/router';
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

  <!-- Header section sombre -->
  <div class="bg-gradient-to-br from-slate-900 to-blue-950 py-14">
    <div class="container">
      <h1 class="h2 text-white mb-3 text-center animate-fade-up">
        Catalogue des formations
      </h1>
      <p class="text-slate-300 text-center max-w-xl mx-auto mb-8 animate-fade-up delay-75">
        {{ total() }} formations disponibles. Commencez gratuitement, payez à votre rythme.
      </p>

      <!-- Barre recherche -->
      <div class="max-w-lg mx-auto animate-fade-up delay-100">
        <div class="relative">
          <svg class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none"
               width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
          </svg>
          <input type="search" [(ngModel)]="search" (ngModelChange)="onSearch()"
                 placeholder="Rechercher une formation…"
                 class="w-full pl-10 pr-4 py-3.5 rounded-xl bg-white/10 border border-white/20
                        text-white placeholder-slate-400 focus:outline-none focus:ring-2
                        focus:ring-blue-400 text-sm backdrop-blur-sm"
                 aria-label="Rechercher une formation">
        </div>
      </div>
    </div>
  </div>

  <!-- Contenu principal -->
  <div class="container py-10">
    <div class="flex flex-col lg:flex-row gap-8">

      <!-- Filtres sidebar -->
      <aside class="lg:w-56 xl:w-64 shrink-0" aria-label="Filtres">
        <div class="card p-5 sticky top-20">
          <h2 class="font-semibold text-slate-900 mb-4">Filtres</h2>

          <!-- Niveau -->
          <div class="mb-5">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">Niveau</p>
            <div class="space-y-2">
              @for (n of niveaux; track n.value) {
                <label class="flex items-center gap-2.5 cursor-pointer group">
                  <input type="radio" name="niveau" [value]="n.value" [(ngModel)]="selectedNiveau" (change)="load()"
                         class="w-4 h-4 text-blue-600 border-slate-300 focus:ring-blue-500">
                  <span class="text-sm text-slate-700 group-hover:text-slate-900 transition-colors flex items-center gap-1.5">
                    <span aria-hidden="true">{{ n.icon }}</span>{{ n.label }}
                  </span>
                </label>
              }
            </div>
          </div>

          <!-- Accès -->
          <div class="mb-5">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">Accès</p>
            <label class="flex items-center gap-2.5 cursor-pointer">
              <input type="checkbox" [(ngModel)]="onlyFree" (change)="load()"
                     class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500">
              <span class="text-sm text-slate-700">Partiellement gratuit</span>
            </label>
          </div>

          @if (hasFilter()) {
            <button (click)="resetFilters()" class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
              ✕ Effacer les filtres
            </button>
          }
        </div>
      </aside>

      <!-- Grille -->
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between mb-6">
          @if (!loading()) {
            <p class="text-sm text-slate-500">
              <strong class="text-slate-900">{{ total() }}</strong>
              formation{{ total() > 1 ? 's' : '' }}
            </p>
          }
        </div>

        <!-- Skeleton -->
        @if (loading()) {
          <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
            @for (_ of [1,2,3,4,5,6]; track $_) {
              <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
                <div class="shimmer h-40 w-full"></div>
                <div class="p-4 space-y-3">
                  <div class="shimmer h-4 rounded w-3/4"></div>
                  <div class="shimmer h-3 rounded w-full"></div>
                  <div class="shimmer h-3 rounded w-2/3"></div>
                  <div class="shimmer h-1.5 rounded-full w-full mt-4"></div>
                </div>
              </div>
            }
          </div>
        }

        <!-- Empty state -->
        @if (!loading() && cours().length === 0) {
          <div class="text-center py-20">
            <div class="text-5xl mb-4" aria-hidden="true">🔍</div>
            <h3 class="font-bold text-slate-900 text-lg mb-2">Aucune formation trouvée</h3>
            <p class="text-slate-500 text-sm mb-5">Essayez d'autres mots-clés ou effacez les filtres.</p>
            <button (click)="resetFilters()" class="btn-secondary btn-sm">Effacer les filtres</button>
          </div>
        }

        <!-- Grille cours -->
        @if (!loading() && cours().length > 0) {
          <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
            @for (c of cours(); track c.id; let i = $index) {
              <a [routerLink]="['/cours', c.slug]"
                 class="group flex flex-col bg-white rounded-2xl border border-slate-200
                        hover:border-blue-200 hover:shadow-lg transition-all duration-200 overflow-hidden animate-fade-up"
                 [style]="'animation-delay:' + (i * 40) + 'ms'"
                 [attr.aria-label]="c.titre">

                <div [class]="'h-36 relative overflow-hidden ' + levelGradient(c.niveau)">
                  <div class="absolute inset-0 opacity-10" style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px" aria-hidden="true"></div>
                  <div class="absolute top-3 left-3">
                    <span class="bg-black/25 backdrop-blur-sm text-white text-xs font-semibold px-2.5 py-1 rounded-full">
                      {{ levelEmoji(c.niveau) }} {{ levelLabel(c.niveau) }}
                    </span>
                  </div>
                  @if (c.noteMoyenne) {
                    <div class="absolute bottom-3 right-3 flex items-center gap-1 bg-black/25 backdrop-blur-sm rounded-full px-2 py-0.5">
                      <svg width="10" height="10" viewBox="0 0 24 24" fill="#fbbf24" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                      <span class="text-white text-xs font-bold">{{ c.noteMoyenne }}</span>
                    </div>
                  }
                </div>

                <div class="flex-1 flex flex-col p-4">
                  <h3 class="font-bold text-slate-900 text-sm leading-snug mb-2 line-clamp-2 group-hover:text-blue-700 transition-colors">
                    {{ c.titre }}
                  </h3>
                  <p class="text-xs text-slate-500 line-clamp-2 mb-3 flex-1 leading-relaxed">{{ c.descriptionCourte }}</p>

                  <div class="flex items-center gap-3 text-xs text-slate-400 mb-3">
                    <span>{{ c.nbLecons }} leçons</span>
                    <span>·</span>
                    <span>{{ Math.floor(c.dureeTotaleMinutes / 60) }}h</span>
                    <span class="ml-auto font-bold text-slate-700">{{ c.prixFcfa | number:'1.0-0' }} FCFA</span>
                  </div>

                  <div class="h-1.5 bg-slate-100 rounded-full overflow-hidden mb-1.5">
                    <div class="h-full bg-green-500 rounded-full" [style.width.%]="c.seuilPaiement * 100"></div>
                  </div>
                  <p class="text-xs text-green-600 font-medium">
                    {{ (c.seuilPaiement * 100) | number:'1.0-0' }}% gratuit
                  </p>
                </div>
              </a>
            }
          </div>

          <!-- Pagination -->
          @if (totalPages() > 1) {
            <div class="flex items-center justify-center gap-3 mt-10">
              <button (click)="prevPage()" [disabled]="page() === 0"
                      class="btn-secondary btn-sm" [class.opacity-40]="page() === 0">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
              </button>
              <span class="text-sm text-slate-600">{{ page() + 1 }} / {{ totalPages() }}</span>
              <button (click)="nextPage()" [disabled]="page() + 1 >= totalPages()"
                      class="btn-secondary btn-sm" [class.opacity-40]="page() + 1 >= totalPages()">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
              </button>
            </div>
          }
        }
      </div>
    </div>
  </div>
</div>
  `,
})
export class CatalogComponent implements OnInit {
  readonly #svc   = inject(CourseService);
  readonly #route = inject(ActivatedRoute);
  readonly Math   = Math;

  readonly cours      = signal<CoursResponse[]>(MOCK_COURS);
  readonly loading    = signal(true);
  readonly total      = signal(6);
  readonly page       = signal(0);
  readonly totalPages = signal(1);

  search          = '';
  selectedNiveau: NiveauCours | '' = '';
  onlyFree        = false;

  readonly hasFilter = computed(() => !!this.search || !!this.selectedNiveau || this.onlyFree);

  readonly niveaux = [
    { value: '' as NiveauCours | '', label: 'Tous',           icon: '🎯' },
    { value: 'DEBUTANT' as NiveauCours,      label: 'Débutant',     icon: '🌱' },
    { value: 'INTERMEDIAIRE' as NiveauCours, label: 'Intermédiaire',icon: '⚡' },
    { value: 'AVANCE' as NiveauCours,        label: 'Avancé',       icon: '🚀' },
  ];

  ngOnInit(): void {
    this.#route.queryParams.subscribe(p => {
      if (p['niveau']) this.selectedNiveau = p['niveau'] as NiveauCours;
      if (p['q'])      this.search = p['q'];
      this.load();
    });
  }

  load(): void {
    this.loading.set(true);
    const params: Record<string, string | number> = { page: this.page(), size: 9 };
    if (this.search)          params['q']       = this.search;
    if (this.selectedNiveau)  params['niveau']  = this.selectedNiveau;
    if (this.onlyFree)        params['gratuit'] = 'true';
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
  resetFilters(): void { this.search = ''; this.selectedNiveau = ''; this.onlyFree = false; this.page.set(0); this.load(); }

  levelGradient(n: string): string { return { DEBUTANT: 'bg-gradient-to-br from-emerald-500 to-green-700', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-500 to-indigo-700', AVANCE: 'bg-gradient-to-br from-purple-600 to-violet-700' }[n] ?? 'bg-blue-700'; }
  levelEmoji(n: string): string    { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  levelLabel(n: string): string    { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
}
EOF
ok "Catalog"

# ============================================================
# 3. COURSE DETAIL — page pro avec avis vérifiés
# ============================================================
sec "3/7 — CourseDetail (S4 avis + liste attente)"

cat > src/app/features/public/course-detail/course-detail.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, input, OnInit, computed,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CourseService }   from '../../../core/services/course.service';
import { SessionService }  from '../../../core/services/session.service';
import { AuthService }     from '../../../core/services/auth.service';
import { ToastService }    from '../../../core/services/toast.service';
import type { CoursDetailResponse, AvisCoursResponse, SessionResponse } from '../../../core/models';
import { MOCK_COURS_DETAIL, MOCK_AVIS, MOCK_SESSIONS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-course-detail',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-white">

  @if (loading()) {
    <div class="container py-16 space-y-8">
      <div class="shimmer h-72 rounded-2xl"></div>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="lg:col-span-2 space-y-4">
          <div class="shimmer h-8 rounded w-3/4"></div>
          <div class="shimmer h-4 rounded w-full"></div>
          <div class="shimmer h-4 rounded w-2/3"></div>
        </div>
        <div class="shimmer h-80 rounded-xl"></div>
      </div>
    </div>
  }

  @if (!loading() && detail()) {
    <!-- Hero cours -->
    <div [class]="'py-14 relative overflow-hidden ' + heroBg()">
      <div class="absolute inset-0 opacity-10" style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:28px 28px" aria-hidden="true"></div>
      <div class="container relative">
        <nav class="flex items-center gap-2 text-sm text-white/70 mb-6" aria-label="Fil d'Ariane">
          <a routerLink="/" class="hover:text-white transition-colors">Accueil</a>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
          <a routerLink="/catalogue" class="hover:text-white transition-colors">Catalogue</a>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
          <span class="text-white truncate max-w-xs">{{ detail()!.titre }}</span>
        </nav>

        <div class="max-w-3xl">
          <span class="inline-flex items-center gap-1.5 bg-white/20 backdrop-blur-sm text-white text-sm font-semibold px-3 py-1.5 rounded-full mb-4">
            {{ levelEmoji(detail()!.niveau) }} {{ levelLabel(detail()!.niveau) }}
          </span>
          <h1 class="text-3xl md:text-4xl font-black text-white mb-4 leading-tight" style="font-family:var(--font);">
            {{ detail()!.titre }}
          </h1>
          <p class="text-lg text-white/85 leading-relaxed mb-6">{{ detail()!.descriptionCourte }}</p>

          <!-- Stats barre -->
          <div class="flex flex-wrap items-center gap-5 text-sm text-white/80">
            @if (detail()!.noteMoyenne) {
              <span class="flex items-center gap-1.5">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="#fbbf24" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                <strong class="text-white">{{ detail()!.noteMoyenne }}</strong> ({{ detail()!.nbAvis }} avis)
              </span>
            }
            <span class="flex items-center gap-1.5">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
              {{ detail()!.nbApprenants }} apprenants
            </span>
            <span>{{ detail()!.nbLecons }} leçons · {{ Math.floor(detail()!.dureeTotaleMinutes / 60) }}h de contenu</span>
            <span>Langue : {{ detail()!.langue }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Contenu -->
    <div class="container py-12">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-10">

        <!-- Col principale -->
        <div class="lg:col-span-2 space-y-10">

          <!-- Description longue -->
          @if (detail()!.descriptionLongue) {
            <div class="card p-6">
              <h2 class="h3 mb-4">À propos de cette formation</h2>
              <div class="prose prose-sm prose-slate max-w-none"
                   [innerHTML]="detail()!.descriptionLongue"></div>
            </div>
          }

          <!-- Programme -->
          <div class="card p-6">
            <h2 class="h3 mb-2">Programme</h2>
            <p class="text-sm text-slate-400 mb-5">
              {{ detail()!.nbModules }} modules · {{ detail()!.nbLecons }} leçons ·
              {{ Math.floor(detail()!.dureeTotaleMinutes / 60) }}h{{ detail()!.dureeTotaleMinutes % 60 ? detail()!.dureeTotaleMinutes % 60 + 'min' : '' }}
            </p>
            <div class="space-y-2">
              @for (mod of detail()!.modules; track mod.id; let i = $index) {
                <details class="border border-slate-200 rounded-xl overflow-hidden group" [attr.open]="i === 0 ? true : null">
                  <summary class="flex items-center gap-3 px-5 py-4 cursor-pointer hover:bg-slate-50 transition-colors list-none">
                    <div class="w-7 h-7 rounded-lg bg-blue-100 flex items-center justify-center text-xs font-bold text-blue-700 shrink-0">
                      {{ i + 1 }}
                    </div>
                    <span class="font-semibold text-slate-900 flex-1 text-sm">{{ mod.titre }}</span>
                    <span class="text-xs text-slate-400">{{ mod.lecons.length }} leçons</span>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"
                         class="shrink-0 group-open:rotate-180 transition-transform" aria-hidden="true">
                      <polyline points="6 9 12 15 18 9"/>
                    </svg>
                  </summary>
                  <div class="divide-y divide-slate-100 border-t border-slate-100">
                    @for (l of mod.lecons; track l.id) {
                      <div class="flex items-center gap-3 px-5 py-3">
                        <!-- Icône type -->
                        @if (l.typeContenu === 'VIDEO') {
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                        } @else if (l.typeContenu === 'QCM') {
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/></svg>
                        } @else {
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                        }
                        <span class="text-sm text-slate-700 flex-1">{{ l.titre }}</span>
                        <div class="flex items-center gap-2 shrink-0">
                          @if (!l.estVerrouille) {
                            <span class="text-xs text-green-600 font-medium">Gratuit</span>
                          } @else {
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                          }
                          <span class="text-xs text-slate-400">{{ l.dureeMinutes }}min</span>
                        </div>
                      </div>
                    }
                  </div>
                </details>
              }
            </div>
          </div>

          <!-- Sessions disponibles -->
          @if (sessions().length > 0) {
            <div class="card p-6">
              <h2 class="h3 mb-5">Sessions avec formateur</h2>
              <div class="space-y-4">
                @for (s of sessions(); track s.id) {
                  <div class="border border-slate-200 rounded-xl p-4 hover:border-blue-200 transition-colors">
                    <div class="flex items-start justify-between gap-3">
                      <div>
                        <div class="flex items-center gap-2 mb-2 flex-wrap">
                          <span [class]="'badge ' + modaliteBadge(s.modalite)">
                            {{ s.modalite === 'MEET' ? '💻 En ligne' : s.modalite === 'PRESENTIEL' ? '📍 Présentiel' : '🔀 Hybride' }}
                          </span>
                          @if (s.placesRestantes === 0) { <span class="badge-red">Complet</span> }
                          @else if (s.placesRestantes <= 3) { <span class="badge-amber">{{ s.placesRestantes }} places</span> }
                        </div>
                        <p class="font-semibold text-slate-900 text-sm">{{ s.titre }}</p>
                        <p class="text-xs text-slate-500 mt-1">
                          Du {{ formatDate(s.dateDebut) }} au {{ formatDate(s.dateFin) }}
                          @if (s.lieu) { · {{ s.lieu }} }
                        </p>
                      </div>
                      <div class="text-right shrink-0">
                        <p class="text-xs text-slate-400">{{ s.nbInscrits }}/{{ s.capaciteMax }}</p>
                        <!-- Liste d'attente si complet (S4) -->
                        @if (s.placesRestantes === 0 && isAuth()) {
                          <button (click)="rejoindreListeAttente(detail()!.id, s.id)"
                                  class="text-xs text-blue-600 hover:text-blue-700 font-medium mt-1 transition-colors">
                            Liste d'attente
                          </button>
                        }
                      </div>
                    </div>
                  </div>
                }
              </div>
            </div>
          }

          <!-- Avis vérifiés (S4) -->
          @if (avis().length > 0) {
            <div class="card p-6">
              <div class="flex items-center gap-3 mb-5">
                <h2 class="h3">Avis vérifiés</h2>
                @if (detail()!.noteMoyenne) {
                  <div class="flex items-center gap-1.5 ml-auto">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    <span class="text-xl font-black text-slate-900">{{ detail()!.noteMoyenne }}</span>
                    <span class="text-sm text-slate-400">/ 5 ({{ detail()!.nbAvis }} avis)</span>
                  </div>
                }
              </div>
              <div class="space-y-4">
                @for (a of avis().slice(0, 5); track a.id) {
                  <div class="flex gap-3 pb-4 border-b border-slate-100 last:border-0 last:pb-0">
                    <div class="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-sm shrink-0">
                      {{ (a.prenomApprenant ?? '?').charAt(0) }}
                    </div>
                    <div class="flex-1">
                      <div class="flex items-center gap-2 mb-1">
                        <span class="text-sm font-semibold text-slate-900">{{ a.prenomApprenant }}</span>
                        <div class="flex">
                          @for (s of starsArray(a.note); track s) {
                            <svg width="12" height="12" viewBox="0 0 24 24" [attr.fill]="s === 1 ? '#f59e0b' : '#e2e8f0'" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                          }
                        </div>
                        <span class="text-xs text-slate-400 ml-auto">{{ timeAgo(a.createdAt) }}</span>
                      </div>
                      @if (a.commentaire) {
                        <p class="text-sm text-slate-600 leading-relaxed">{{ a.commentaire }}</p>
                      }
                      <span class="inline-flex items-center gap-1 text-xs text-green-600 mt-1">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                        Avis vérifié
                      </span>
                    </div>
                  </div>
                }
              </div>
            </div>
          }
        </div>

        <!-- Carte d'action sticky -->
        <div class="lg:col-span-1">
          <div class="card p-6 sticky top-20">
            <!-- Prix -->
            <div class="mb-4">
              <p class="text-3xl font-black text-slate-900">{{ detail()!.prixFcfa | number:'1.0-0' }} FCFA</p>
              <p class="text-xs text-slate-400 mt-0.5">Paiement en tranches disponible</p>
            </div>

            <!-- Barre freemium -->
            <p class="text-sm text-green-600 font-medium flex items-center gap-1.5 mb-2">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
              {{ (detail()!.seuilPaiement * 100) | number:'1.0-0' }}% du contenu accessible gratuitement
            </p>
            <div class="progress mb-5">
              <div class="progress-bar bg-green-500" [style.width.%]="detail()!.seuilPaiement * 100"></div>
            </div>

            <!-- CTA -->
            @if (isAuth()) {
              <a [routerLink]="['/app/cours', detail()!.slug]"
                 class="btn-primary w-full justify-center py-3 text-base font-semibold mb-3">
                Commencer ce cours
              </a>
            } @else {
              <a routerLink="/auth/inscription" class="btn-primary w-full justify-center py-3 text-base font-semibold mb-3">
                Commencer gratuitement
              </a>
              <a routerLink="/auth/connexion" class="btn-secondary w-full justify-center mb-3">
                Déjà inscrit ? Se connecter
              </a>
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
  readonly #toast       = inject(ToastService);
  readonly Math         = Math;

  readonly detail   = signal<CoursDetailResponse | null>(MOCK_COURS_DETAIL);
  readonly sessions = signal<SessionResponse[]>(MOCK_SESSIONS);
  readonly avis     = signal<AvisCoursResponse[]>(MOCK_AVIS);
  readonly loading  = signal(true);
  readonly isAuth   = this.#auth.isAuthenticated;

  readonly avantages = ['Accès à vie au contenu', 'Certificat officiel MbemNova', 'Paiement en tranches', 'Communauté d\'entraide'];

  ngOnInit(): void {
    const s = this.slug();
    if (!s) return;
    this.loading.set(true);
    this.#courseSvc.getBySlug(s).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.detail.set(r.data);
          this.loading.set(false);
          // Charger avis
          this.#courseSvc.getAvis(r.data.id).subscribe({
            next: av => { if (av.success && av.data) this.avis.set(av.data); },
          });
        }
      },
      error: () => { this.loading.set(false); },
    });
  }

  rejoindreListeAttente(coursId: string, sessionId: string): void {
    this.#courseSvc.rejoindreListeAttente(coursId, sessionId).subscribe({
      next: r => { this.#toast.success(r.message ?? 'Liste d\'attente rejointe'); },
    });
  }

  heroBg(): string { return { DEBUTANT: 'bg-gradient-to-br from-emerald-600 to-green-800', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-600 to-indigo-800', AVANCE: 'bg-gradient-to-br from-purple-600 to-violet-800' }[this.detail()?.niveau ?? ''] ?? 'bg-blue-800'; }
  levelEmoji(n: string): string { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  levelLabel(n: string): string { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
  modaliteBadge(m: string): string { return { MEET: 'badge-blue', PRESENTIEL: 'badge-green', HYBRIDE: 'badge-purple' }[m] ?? 'badge-slate'; }
  starsArray(note: number): number[] { return Array.from({ length: 5 }, (_, i) => i < Math.round(note) ? 1 : 0); }
  timeAgo(iso: string): string {
    const d = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
    return d === 0 ? 'Aujourd\'hui' : d === 1 ? 'Hier' : `il y a ${d} jours`;
  }
  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
  }
}
EOF
ok "CourseDetail"

# ============================================================
# 4. AUTH PAGES — Login + Register optimisés
# ============================================================
sec "4/7 — Auth pages (login + register)"

cat > src/app/features/auth/login/login.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink, Router, ActivatedRoute } from '@angular/router';
import { AuthService }  from '../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex">

  <!-- Panneau gauche -->
  <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900
              items-center justify-center p-12 relative overflow-hidden">
    <div class="absolute inset-0 opacity-[0.04]"
         style="background-image:linear-gradient(white 1px,transparent 1px),linear-gradient(90deg,white 1px,transparent 1px);background-size:40px 40px"></div>
    <div class="relative z-10 text-center max-w-sm">
      <svg width="240" height="200" viewBox="0 0 240 200" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="mx-auto mb-8">
        <rect x="30" y="30" width="180" height="120" rx="12" fill="white" opacity="0.08"/>
        <rect x="42" y="42" width="156" height="96" rx="8" fill="white" opacity="0.06"/>
        <rect x="55" y="56" width="70" height="8" rx="4" fill="white" opacity="0.6"/>
        <rect x="55" y="70" width="100" height="5" rx="2.5" fill="white" opacity="0.3"/>
        <rect x="55" y="82" width="86" height="5" rx="2.5" fill="white" opacity="0.25"/>
        <rect x="55" y="98" width="130" height="5" rx="2.5" fill="#f1f5f9" opacity="0.12"/>
        <rect x="55" y="98" width="90" height="5" rx="2.5" fill="#60a5fa" opacity="0.7"/>
        <rect x="55" y="110" width="130" height="5" rx="2.5" fill="#f1f5f9" opacity="0.12"/>
        <rect x="55" y="110" width="55" height="5" rx="2.5" fill="#34d399" opacity="0.7"/>
        <path d="M110 150 L90 160 H150 L130 150z" fill="white" opacity="0.08"/>
        <rect x="74" y="160" width="92" height="5" rx="2.5" fill="white" opacity="0.08"/>
        <circle cx="192" cy="46" r="16" fill="#f59e0b" opacity="0.85"/>
        <text x="192" y="51" text-anchor="middle" font-size="14" fill="white" font-weight="bold">★</text>
        <circle cx="36" cy="145" r="18" fill="#f59e0b" opacity="0.15"/>
        <circle cx="36" cy="145" r="13" stroke="#f59e0b" stroke-width="2" opacity="0.4"/>
        <text x="36" y="150" text-anchor="middle" font-size="13" fill="#f59e0b">🏆</text>
      </svg>
      <h2 class="text-2xl font-bold text-white mb-3">Continuez votre apprentissage</h2>
      <p class="text-blue-200 text-sm leading-relaxed mb-8">Accédez à vos cours, suivez votre progression et rejoignez la communauté MbemNova.</p>
      <div class="flex justify-center gap-8">
        @for (s of [['247+','apprenants'],['6','formations'],['95%','satisfaction']]; track s[0]) {
          <div class="text-center">
            <p class="text-2xl font-black text-white">{{ s[0] }}</p>
            <p class="text-xs text-blue-300 mt-0.5">{{ s[1] }}</p>
          </div>
        }
      </div>
    </div>
  </div>

  <!-- Formulaire -->
  <div class="flex-1 flex items-center justify-center p-6 sm:p-10">
    <div class="w-full max-w-sm animate-fade-up">
      <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform" aria-hidden="true">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
      </a>
      <h1 class="text-2xl font-black text-slate-900 mb-1">Bon retour !</h1>
      <p class="text-slate-500 text-sm mb-8">Connectez-vous pour continuer votre parcours.</p>

      <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
        <div>
          <label for="email" class="label">Adresse email</label>
          <input id="email" type="email" formControlName="email" autocomplete="email"
                 placeholder="vous@example.com"
                 [class]="'input ' + (s && form.get('email')?.invalid ? 'input-error' : '')">
          @if (s && form.get('email')?.invalid) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Email valide requis
            </p>
          }
        </div>
        <div>
          <div class="flex justify-between items-center mb-1.5">
            <label for="pwd" class="label mb-0">Mot de passe</label>
            <a routerLink="/auth/mot-de-passe-oublie" class="text-xs text-blue-600 hover:text-blue-700 transition-colors">Oublié ?</a>
          </div>
          <div class="relative">
            <input id="pwd" [type]="showPwd() ? 'text' : 'password'" formControlName="motDePasse"
                   autocomplete="current-password" placeholder="••••••••"
                   [class]="'input pr-11 ' + (s && form.get('motDePasse')?.invalid ? 'input-error' : '')">
            <button type="button" (click)="showPwd.set(!showPwd())"
                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
                    [attr.aria-label]="showPwd() ? 'Masquer' : 'Afficher'">
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                @if (!showPwd()) { <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/> }
                @else { <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/> }
              </svg>
            </button>
          </div>
        </div>
        <label class="flex items-center gap-2.5 cursor-pointer select-none">
          <input type="checkbox" formControlName="rememberMe" class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500">
          <span class="text-sm text-slate-600">Se souvenir de moi</span>
        </label>
        <button type="submit" [disabled]="loading()" class="btn-primary w-full py-3 text-base font-semibold mt-1">
          @if (loading()) {
            <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            Connexion…
          } @else { Se connecter }
        </button>
      </form>

      <p class="text-center text-sm text-slate-500 mt-6">
        Pas encore de compte ?
        <a routerLink="/auth/inscription" class="link font-semibold ml-1">Créer un compte gratuit</a>
      </p>
      <p class="text-center text-xs text-slate-400 mt-4">
        En vous connectant, vous acceptez nos
        <a routerLink="/politique-confidentialite" class="underline hover:text-slate-600 transition-colors">conditions d'utilisation</a>
      </p>
    </div>
  </div>
</div>
  `,
})
export class LoginComponent {
  readonly #auth   = inject(AuthService);
  readonly #router = inject(Router);
  readonly #route  = inject(ActivatedRoute);
  readonly #fb     = inject(FormBuilder);

  readonly loading = signal(false);
  readonly showPwd = signal(false);
  s = false;

  readonly form = this.#fb.nonNullable.group({
    email:      ['', [Validators.required, Validators.email]],
    motDePasse: ['', Validators.required],
    rememberMe: [false],
  });

  submit(): void {
    this.s = true;
    if (this.form.invalid) return;
    this.loading.set(true);
    this.#auth.login(this.form.getRawValue()).subscribe({
      next: () => {
        this.loading.set(false);
        const returnUrl = this.#route.snapshot.queryParams['returnUrl'];
        if (returnUrl) this.#router.navigateByUrl(returnUrl);
        else this.#auth.redirectToDashboard();
      },
      error: () => { this.loading.set(false); },
    });
  }
}
EOF
ok "Login"

cat > src/app/features/auth/register/register.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl } from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

const pwdMatch = (c: AbstractControl) => {
  const a = c.get('motDePasse')?.value, b = c.get('confirmation')?.value;
  return a && b && a !== b ? { mismatch: true } : null;
};

@Component({
  selector: 'app-register',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex">
  <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-emerald-700 to-teal-900
              items-center justify-center p-12 relative overflow-hidden">
    <div class="absolute inset-0 opacity-[0.04]"
         style="background-image:linear-gradient(white 1px,transparent 1px),linear-gradient(90deg,white 1px,transparent 1px);background-size:40px 40px"></div>
    <div class="relative z-10 text-center max-w-sm">
      <div class="text-6xl mb-6" aria-hidden="true">🚀</div>
      <h2 class="text-2xl font-bold text-white mb-3">Votre parcours commence ici</h2>
      <p class="text-emerald-200 text-sm leading-relaxed mb-8">Rejoignez 247 apprenants qui développent leurs compétences tech avec MbemNova. Formations certifiantes, paiement en tranches.</p>
      <div class="space-y-3 text-left">
        @for (a of avantages; track a) {
          <div class="flex items-center gap-3">
            <div class="w-5 h-5 rounded-full bg-white/20 flex items-center justify-center shrink-0">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
            <p class="text-sm text-emerald-100">{{ a }}</p>
          </div>
        }
      </div>
    </div>
  </div>

  <div class="flex-1 flex items-start justify-center p-6 sm:p-10 overflow-y-auto py-10">
    <div class="w-full max-w-sm animate-fade-up">
      <a routerLink="/" class="inline-flex items-center gap-2.5 mb-8 group">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform" aria-hidden="true">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
      </a>
      <h1 class="text-2xl font-black text-slate-900 mb-1">Créer votre compte</h1>
      <p class="text-slate-500 text-sm mb-8">Gratuit. Aucune carte bancaire requise.</p>

      @if (referralCode()) {
        <div class="flex items-center gap-3 bg-green-50 border border-green-200 rounded-xl px-4 py-3 mb-6">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
          <div>
            <p class="text-sm font-semibold text-green-800">Code parrainage appliqué !</p>
            <p class="text-xs text-green-600">Vous et votre parrain recevrez des bonus XP.</p>
          </div>
        </div>
      }

      <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
        <div>
          <label for="prenom" class="label">Prénom <span class="text-red-500">*</span></label>
          <input id="prenom" type="text" formControlName="prenom" autocomplete="given-name" placeholder="Jean-Paul"
                 [class]="'input ' + (s && form.get('prenom')?.invalid ? 'input-error' : '')">
          @if (s && form.get('prenom')?.invalid) { <p class="field-error" role="alert">Prénom requis (2 car. min)</p> }
        </div>
        <div>
          <label for="reg-email" class="label">Email <span class="text-red-500">*</span></label>
          <input id="reg-email" type="email" formControlName="email" autocomplete="email" placeholder="vous@example.com"
                 [class]="'input ' + (s && form.get('email')?.invalid ? 'input-error' : '')">
          @if (s && form.get('email')?.invalid) { <p class="field-error" role="alert">Email valide requis</p> }
        </div>
        <div>
          <label for="reg-pwd" class="label">Mot de passe <span class="text-red-500">*</span></label>
          <input id="reg-pwd" type="password" formControlName="motDePasse" autocomplete="new-password" placeholder="8 caractères minimum"
                 [class]="'input ' + (s && form.get('motDePasse')?.invalid ? 'input-error' : '')">
          @if (s && form.get('motDePasse')?.hasError('minlength')) { <p class="field-error" role="alert">8 caractères minimum</p> }
        </div>
        <div>
          <label for="reg-conf" class="label">Confirmation <span class="text-red-500">*</span></label>
          <input id="reg-conf" type="password" formControlName="confirmation" autocomplete="new-password" placeholder="Retapez le mot de passe"
                 [class]="'input ' + (s && form.hasError('mismatch') ? 'input-error' : '')">
          @if (s && form.hasError('mismatch')) { <p class="field-error" role="alert">Les mots de passe ne correspondent pas</p> }
        </div>
        <label class="flex items-start gap-2.5 cursor-pointer">
          <input type="checkbox" formControlName="consent" class="w-4 h-4 rounded mt-0.5 text-blue-600 border-slate-300 focus:ring-blue-500 shrink-0">
          <span class="text-sm text-slate-600 leading-relaxed">
            J'accepte la <a routerLink="/politique-confidentialite" target="_blank" class="link font-medium">politique de confidentialité</a> de MbemNova.
          </span>
        </label>
        @if (s && form.get('consent')?.hasError('required')) {
          <p class="field-error -mt-2" role="alert">Vous devez accepter les conditions</p>
        }
        <button type="submit" [disabled]="loading()" class="btn-success w-full py-3 text-base font-semibold mt-1">
          @if (loading()) {
            <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            Création…
          } @else { Créer mon compte gratuit }
        </button>
      </form>
      <p class="text-center text-sm text-slate-500 mt-6">
        Déjà inscrit ? <a routerLink="/auth/connexion" class="link font-semibold ml-1">Se connecter</a>
      </p>
    </div>
  </div>
</div>
  `,
})
export class RegisterComponent implements OnInit {
  readonly #auth  = inject(AuthService);
  readonly #route = inject(ActivatedRoute);
  readonly #fb    = inject(FormBuilder);

  readonly loading     = signal(false);
  readonly referralCode= signal('');
  s = false;

  readonly avantages = ['Accès partiel gratuit dès l\'inscription', 'Paiement en tranches adapté', 'Certificat officiel vérifiable', 'Communauté d\'apprenants active'];

  readonly form = this.#fb.nonNullable.group({
    prenom:       ['', [Validators.required, Validators.minLength(2)]],
    email:        ['', [Validators.required, Validators.email]],
    motDePasse:   ['', [Validators.required, Validators.minLength(8)]],
    confirmation: ['', Validators.required],
    consent:      [false, Validators.requiredTrue],
  }, { validators: pwdMatch });

  ngOnInit(): void {
    const code = this.#route.snapshot.queryParams['ref'] ?? '';
    if (code) this.referralCode.set(code);
  }

  submit(): void {
    this.s = true;
    if (this.form.invalid) return;
    this.loading.set(true);
    const { prenom, email, motDePasse } = this.form.getRawValue();
    const code = this.referralCode();
    this.#auth.register({ prenom, email, motDePasse, ...(code ? { referralCode: code } : {}) }).subscribe({
      next: () => { this.loading.set(false); this.#auth.redirectToDashboard(); },
      error: () => { this.loading.set(false); },
    });
  }
}
EOF
ok "Register"

cat > src/app/features/auth/forgot-password/forgot-password.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../core/services/api.service';

@Component({
  selector: 'app-forgot-password',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex items-center justify-center p-4">
  <div class="w-full max-w-sm animate-fade-up">
    <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform" aria-hidden="true">
        <circle cx="18" cy="18" r="18" fill="#2563eb"/>
        <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
      </svg>
      <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
    </a>

    @if (!sent()) {
      <div class="text-center mb-8">
        <div class="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-4">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.8" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/><circle cx="12" cy="16" r="1.5" fill="#2563eb"/></svg>
        </div>
        <h1 class="text-2xl font-black text-slate-900 mb-2">Mot de passe oublié ?</h1>
        <p class="text-slate-500 text-sm">Entrez votre email pour recevoir un lien de réinitialisation.</p>
      </div>
      <div class="card p-6">
        <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
          <div>
            <label for="fp-email" class="label">Adresse email</label>
            <input id="fp-email" type="email" formControlName="email" autocomplete="email" placeholder="vous@example.com" class="input">
          </div>
          <button type="submit" [disabled]="loading()" class="btn-primary w-full py-3 font-semibold">
            @if (loading()) { Envoi… } @else { Envoyer le lien }
          </button>
        </form>
      </div>
    }

    @if (sent()) {
      <div class="card p-10 text-center animate-scale-in">
        <div class="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-5">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Email envoyé !</h2>
        <p class="text-sm text-slate-500 mb-6 leading-relaxed">Si un compte existe avec cette adresse, vous recevrez un lien dans quelques minutes. Vérifiez vos spams.</p>
        <a routerLink="/auth/connexion" class="btn-secondary w-full justify-center">Retour à la connexion</a>
      </div>
    }

    <p class="text-center text-sm text-slate-500 mt-6">
      <a routerLink="/auth/connexion" class="link flex items-center gap-1 justify-center">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        Retour à la connexion
      </a>
    </p>
  </div>
</div>
  `,
})
export class ForgotPasswordComponent {
  readonly #api = inject(ApiService);
  readonly #fb  = inject(FormBuilder);
  readonly loading = signal(false);
  readonly sent    = signal(false);
  readonly form = this.#fb.nonNullable.group({ email: ['', [Validators.required, Validators.email]] });
  submit(): void {
    if (this.form.invalid) return;
    this.loading.set(true);
    this.#api.post('/auth/reset-password', this.form.getRawValue()).subscribe({
      next:  () => { this.loading.set(false); this.sent.set(true); },
      error: () => { this.loading.set(false); this.sent.set(true); },
    });
  }
}
EOF
ok "ForgotPassword"

cat > src/app/features/auth/reset-password/reset-password.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl } from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { ApiService }   from '../../../core/services/api.service';
import { ToastService } from '../../../core/services/toast.service';

const pwdMatch = (c: AbstractControl) => {
  const a = c.get('nouveauMotDePasse')?.value, b = c.get('confirmation')?.value;
  return a && b && a !== b ? { mismatch: true } : null;
};

@Component({
  selector: 'app-reset-password',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex items-center justify-center p-4">
  <div class="w-full max-w-sm animate-fade-up">
    <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform" aria-hidden="true">
        <circle cx="18" cy="18" r="18" fill="#2563eb"/>
        <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
      </svg>
      <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
    </a>

    @if (!tokenValid()) {
      <div class="card p-8 text-center">
        <div class="text-4xl mb-4" aria-hidden="true">⚠️</div>
        <h2 class="font-bold text-slate-900 mb-2">Lien expiré</h2>
        <p class="text-sm text-slate-500 mb-6">Ce lien est invalide ou a expiré (1h). Faites une nouvelle demande.</p>
        <a routerLink="/auth/mot-de-passe-oublie" class="btn-primary w-full justify-center">Nouvelle demande</a>
      </div>
    }

    @if (tokenValid() && !done()) {
      <div class="text-center mb-8">
        <div class="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-4">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.8" aria-hidden="true"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>
        </div>
        <h1 class="text-2xl font-black text-slate-900 mb-2">Nouveau mot de passe</h1>
        <p class="text-slate-500 text-sm">Choisissez un mot de passe sécurisé (8 car. min).</p>
      </div>
      <div class="card p-6">
        <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
          <div>
            <label for="np" class="label">Nouveau mot de passe</label>
            <input id="np" type="password" formControlName="nouveauMotDePasse" autocomplete="new-password" placeholder="8 caractères minimum"
                   [class]="'input ' + (s && form.get('nouveauMotDePasse')?.invalid ? 'input-error' : '')">
            @if (s && form.get('nouveauMotDePasse')?.hasError('minlength')) { <p class="field-error" role="alert">8 caractères minimum</p> }
          </div>
          <div>
            <label for="nc" class="label">Confirmation</label>
            <input id="nc" type="password" formControlName="confirmation" autocomplete="new-password" placeholder="Retapez le mot de passe"
                   [class]="'input ' + (s && form.hasError('mismatch') ? 'input-error' : '')">
            @if (s && form.hasError('mismatch')) { <p class="field-error" role="alert">Les mots de passe ne correspondent pas</p> }
          </div>
          <button type="submit" [disabled]="loading()" class="btn-primary w-full py-3 font-semibold">
            @if (loading()) { Enregistrement… } @else { Enregistrer le mot de passe }
          </button>
        </form>
      </div>
    }

    @if (done()) {
      <div class="card p-10 text-center animate-scale-in">
        <div class="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-5">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Mot de passe mis à jour !</h2>
        <p class="text-sm text-slate-500 mb-6">Toutes vos sessions ont été déconnectées.</p>
        <a routerLink="/auth/connexion" class="btn-primary w-full justify-center">Se connecter</a>
      </div>
    }
  </div>
</div>
  `,
})
export class ResetPasswordComponent implements OnInit {
  readonly #api   = inject(ApiService);
  readonly #toast = inject(ToastService);
  readonly #route = inject(ActivatedRoute);
  readonly #fb    = inject(FormBuilder);
  readonly loading    = signal(false);
  readonly done       = signal(false);
  readonly tokenValid = signal(false);
  s = false; #token = '';
  readonly form = this.#fb.nonNullable.group(
    { nouveauMotDePasse: ['', [Validators.required, Validators.minLength(8)]], confirmation: ['', Validators.required] },
    { validators: pwdMatch }
  );
  ngOnInit(): void { this.#token = this.#route.snapshot.queryParams['token'] ?? ''; this.tokenValid.set(!!this.#token); }
  submit(): void {
    this.s = true;
    if (this.form.invalid || !this.#token) return;
    this.loading.set(true);
    const { nouveauMotDePasse, confirmation } = this.form.getRawValue();
    this.#api.post('/auth/new-password', { token: this.#token, nouveauMotDePasse, confirmation }).subscribe({
      next: () => { this.loading.set(false); this.done.set(true); this.#toast.success('Mot de passe mis à jour !'); },
      error: () => { this.loading.set(false); },
    });
  }
}
EOF
ok "ResetPassword"

# ============================================================
# 5. ENVIRONMENT TS — Variable bascule clairement documentée
# ============================================================
sec "5/7 — environment.ts (bascule documentée)"

cat > src/environments/environment.ts << 'EOF'
/**
 * MbemNova · Environment Development
 *
 * ╔══════════════════════════════════════════════════════════╗
 * ║  BASCULE MOCK ↔ API RÉELLE                               ║
 * ║                                                          ║
 * ║  useMock: true  → Données de test (aucun serveur requis) ║
 * ║  useMock: false → API Spring Boot (localhost:8080)       ║
 * ║                                                          ║
 * ║  Changer seulement cette variable — rien d'autre.       ║
 * ╚══════════════════════════════════════════════════════════╝
 */
export const environment = {
  production:   false,
  apiUrl:       'http://localhost:8080/api/v1',
  wsUrl:        'ws://localhost:8080/ws',

  // ← CHANGER ICI : true = mock | false = API Spring Boot
  useMock:      true,

  // Auto-fallback : si l'API retourne [] en dev, bascule sur mock
  autoFallback: true,
  version:      '1.0.0-dev',
} as const;
EOF
ok "environment.ts"

cat > src/environments/environment.prod.ts << 'EOF'
export const environment = {
  production:   true,
  apiUrl:       '/api/v1',
  wsUrl:        '/ws',
  useMock:      false,   // ← JAMAIS de mock en production
  autoFallback: false,
  version:      '1.0.0',
} as const;
EOF
ok "environment.prod.ts"

# ============================================================
# 6. DASHBOARD — KPIs réels + layout sidebar
# ============================================================
sec "6/7 — Dashboard apprenant (KPIs + sidebar)"

cat > src/app/features/learner/dashboard/dashboard.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService }         from '../../../core/services/auth.service';
import { ProgressionService }  from '../../../core/services/progression.service';
import { CourseService }       from '../../../core/services/course.service';
import { NotificationService } from '../../../core/services/notification.service';
import { TalentService }       from '../../../core/services/talent.service';
import type { ProgressionResponse, CoursResponse, NotificationResponse, DrawResponse, ProfilTalentResponse } from '../../../core/models';
import { MOCK_PROGRESSION, MOCK_COURS, MOCK_NOTIFICATIONS, MOCK_DRAW, MOCK_PROFIL } from '../../../core/services/mock.data';

@Component({
  selector: 'app-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête bienvenue -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4 flex-wrap">
        <div>
          <p class="text-sm text-slate-500 mb-0.5">Bon retour,</p>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
            {{ prenom() }} 👋
          </h1>
        </div>
        <!-- Streak -->
        @if (!profilLoading()) {
          <div class="flex items-center gap-2.5 bg-orange-50 border border-orange-200 rounded-xl px-4 py-2.5">
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

    <!-- KPIs -->
    <section aria-label="Mes statistiques">
      @if (profilLoading()) {
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          @for (_ of [1,2,3,4]; track $_) { <div class="card p-5"><div class="shimmer h-16 rounded-lg"></div></div> }
        </div>
      }
      @if (!profilLoading()) {
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- XP -->
          <div class="card p-5 animate-fade-up">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="#d97706" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">{{ profil()?.xpTotal | number:'1.0-0' }}</p>
                <p class="text-xs text-slate-500">XP total</p>
              </div>
            </div>
            <div class="progress"><div class="progress-bar bg-amber-400" [style.width.%]="xpPct()"></div></div>
            <p class="text-xs text-slate-400 mt-1">{{ ptsManquants() }} XP prochain niveau</p>
          </div>

          <!-- Rang -->
          <div class="card p-5 animate-fade-up delay-75">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-1a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2h-2"/><rect x="6" y="18" width="12" height="4" rx="1"/></svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">#{{ profil()?.rang ?? '—' }}</p>
                <p class="text-xs text-slate-500">Classement global</p>
              </div>
            </div>
            <a routerLink="/app/classement" class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">Voir le classement →</a>
          </div>

          <!-- Certificats -->
          <div class="card p-5 animate-fade-up delay-100">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">{{ profil()?.certificats?.length ?? 0 }}</p>
                <p class="text-xs text-slate-500">Certificat{{ (profil()?.certificats?.length ?? 0) > 1 ? 's' : '' }}</p>
              </div>
            </div>
            <a routerLink="/app/certificats" class="text-xs text-green-600 hover:text-green-700 font-medium transition-colors">Mes certificats →</a>
          </div>

          <!-- Parrainage -->
          <div class="card p-5 animate-fade-up delay-150">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" aria-hidden="true"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>
              </div>
              <div>
                <p class="text-2xl font-black text-slate-900">{{ nbFilleuls() }}</p>
                <p class="text-xs text-slate-500">Filleuls actifs</p>
              </div>
            </div>
            <a routerLink="/app/parrainage" class="text-xs text-purple-600 hover:text-purple-700 font-medium transition-colors">Parrainer →</a>
          </div>
        </div>
      }
    </section>

    <!-- Grille principale -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Col gauche — Cours en cours -->
      <div class="lg:col-span-2 space-y-5">
        <div class="flex items-center justify-between">
          <h2 class="h3">Mes cours</h2>
          <a routerLink="/catalogue" class="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors">+ Ajouter</a>
        </div>

        @if (progressionLoading()) {
          @for (_ of [1,2]; track $_) {
            <div class="card p-5">
              <div class="flex gap-4 mb-3">
                <div class="shimmer w-14 h-14 rounded-xl shrink-0"></div>
                <div class="flex-1 space-y-2 pt-1"><div class="shimmer h-4 rounded w-3/4"></div><div class="shimmer h-3 rounded w-1/2"></div></div>
              </div>
              <div class="shimmer h-2 rounded-full w-full"></div>
            </div>
          }
        }

        @if (!progressionLoading()) {
          @if (progressions().length === 0) {
            <div class="card p-12 text-center">
              <div class="text-5xl mb-4" aria-hidden="true">📚</div>
              <h3 class="font-semibold text-slate-900 mb-2">Aucun cours commencé</h3>
              <p class="text-sm text-slate-500 mb-5">Explorez notre catalogue et commencez gratuitement.</p>
              <a routerLink="/catalogue" class="btn-primary">Découvrir les formations</a>
            </div>
          }

          <div class="space-y-4">
            @for (p of progressions(); track p.coursId; let i = $index) {
              <div class="card p-5 hover:shadow-md transition-shadow animate-fade-up" [style]="'animation-delay:' + (i * 60) + 'ms'">
                <div class="flex gap-4">
                  <div [class]="'w-14 h-14 rounded-xl flex items-center justify-center text-2xl shrink-0 ' + coursIconBg(i)" aria-hidden="true">{{ coursIcon(i) }}</div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start justify-between gap-2 mb-1">
                      <h3 class="font-semibold text-slate-900 text-sm leading-snug truncate">{{ getCoursTitle(p.coursId) }}</h3>
                      @if (p.estPaye) { <span class="badge-green shrink-0 text-xs">Accès complet</span> }
                      @else if (p.seuilAtteint) { <span class="badge-amber shrink-0 text-xs">Paiement requis</span> }
                    </div>
                    <div class="flex items-center gap-3 text-xs text-slate-400 mb-2.5">
                      <span class="flex items-center gap-1">
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                        {{ p.xpGagne }} XP
                      </span>
                      <span>{{ p.pourcentage }}% complété</span>
                    </div>
                    <div class="progress mb-3">
                      <div [class]="'progress-bar ' + (p.estTermine ? 'bg-green-500' : 'bg-blue-600')" [style.width.%]="p.pourcentage"></div>
                    </div>
                    <div class="flex items-center gap-2">
                      @if (!p.seuilAtteint || p.estPaye) {
                        <a [routerLink]="['/app/cours', getCoursSlug(p.coursId)]" class="btn-primary btn-sm">
                          {{ p.pourcentage === 0 ? 'Commencer' : 'Continuer' }}
                        </a>
                      } @else {
                        <a routerLink="/app/paiements" class="btn bg-amber-600 hover:bg-amber-700 text-white btn-sm">Débloquer</a>
                      }
                    </div>
                  </div>
                </div>
              </div>
            }
          </div>

          <!-- Suggestions -->
          @if (suggestions().length > 0) {
            <h2 class="h3 mt-6">Continuer votre parcours</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              @for (c of suggestions(); track c.id; let i = $index) {
                <a [routerLink]="['/cours', c.slug]"
                   class="card-hover flex gap-3 p-4 group animate-fade-up"
                   [style]="'animation-delay:' + (i * 60) + 'ms'">
                  <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-xl shrink-0 ' + coursIconBg(i+10)" aria-hidden="true">{{ coursIcon(i+10) }}</div>
                  <div class="flex-1 min-w-0">
                    <h3 class="text-sm font-semibold text-slate-900 line-clamp-1 mb-0.5">{{ c.titre }}</h3>
                    <div class="flex items-center gap-2 text-xs text-slate-400">
                      <span>{{ c.prixFcfa | number:'1.0-0' }} FCFA</span>
                      <span>·</span>
                      <span class="text-green-600 font-medium">{{ (c.seuilPaiement * 100) | number:'1.0-0' }}% gratuit</span>
                    </div>
                  </div>
                </a>
              }
            </div>
          }
        }
      </div>

      <!-- Col droite -->
      <div class="space-y-5">

        <!-- Tirage -->
        <div class="card overflow-hidden animate-fade-up">
          <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-5">
            <div class="flex items-center gap-2 mb-2">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="white" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
              <span class="text-white font-bold text-sm">Tirage mensuel</span>
            </div>
            <p class="text-white text-xs leading-relaxed">Gagne la formation <strong>{{ draw().formationGagnanteTitre }}</strong> ({{ draw().formationGagnantePrix }}) gratuitement !</p>
          </div>
          <div class="p-4">
            <div class="flex justify-between text-xs text-slate-500 mb-3">
              <span>{{ draw().nbTicketsVendus }} participants</span>
              <span>Tirage le {{ draw().dateDrawFormatee }}</span>
            </div>
            <div class="flex justify-between items-center mb-4">
              <div>
                <p class="text-lg font-black text-slate-900">{{ draw().prixTicketFcfa | number:'1.0-0' }} FCFA</p>
                <p class="text-xs text-slate-400">par ticket</p>
              </div>
              <span class="badge-amber">🎟️ Ouvert</span>
            </div>
            <a routerLink="/app/tirage" class="btn-primary w-full justify-center btn-sm">Acheter un ticket</a>
          </div>
        </div>

        <!-- Notifications -->
        <div class="card p-5 animate-fade-up delay-75">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-semibold text-slate-900 text-sm">Notifications</h2>
            <a routerLink="/app/notifications" class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">Toutes</a>
          </div>
          @if (notifLoading()) {
            @for (_ of [1,2,3]; track $_) {
              <div class="flex gap-3 mb-3">
                <div class="shimmer w-8 h-8 rounded-lg shrink-0"></div>
                <div class="flex-1 space-y-1.5"><div class="shimmer h-3 rounded w-3/4"></div><div class="shimmer h-3 rounded w-1/2"></div></div>
              </div>
            }
          }
          @if (!notifLoading()) {
            <div class="space-y-3">
              @for (n of notifications().slice(0, 4); track n.id) {
                <a [routerLink]="n.lienAction ?? '/app/notifications'" class="flex items-start gap-3 group">
                  <div [class]="'w-8 h-8 rounded-lg flex items-center justify-center shrink-0 text-sm ' + notifBg(n.type)" aria-hidden="true">{{ notifEmoji(n.type) }}</div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start gap-1">
                      <p class="text-xs font-medium text-slate-900 line-clamp-2 flex-1 leading-snug group-hover:text-blue-600 transition-colors">{{ n.titre }}</p>
                      @if (!n.estLue) { <div class="w-1.5 h-1.5 bg-blue-500 rounded-full shrink-0 mt-1" aria-label="Non lue"></div> }
                    </div>
                    <p class="text-xs text-slate-400 mt-0.5">{{ timeAgo(n.createdAt) }}</p>
                  </div>
                </a>
              }
            </div>
          }
        </div>

        <!-- Alerte paiement -->
        @if (hasPaiementEnAttente()) {
          <div class="card border-amber-200 bg-amber-50 p-4 animate-fade-up delay-100">
            <div class="flex items-center gap-2 mb-2">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              <h3 class="text-sm font-semibold text-amber-800">Prochaine échéance</h3>
            </div>
            <p class="text-xs text-amber-700 mb-3">Vous avez une tranche de paiement à venir.</p>
            <a routerLink="/app/paiements" class="btn bg-amber-600 hover:bg-amber-700 text-white w-full justify-center btn-sm">Voir mes paiements</a>
          </div>
        }

        <!-- CTA parrainage -->
        <div class="card bg-gradient-to-br from-purple-50 to-blue-50 border-purple-200 p-5 animate-fade-up delay-150">
          <div class="flex items-center gap-2 mb-2">
            <span class="text-xl" aria-hidden="true">🤝</span>
            <h3 class="text-sm font-semibold text-slate-900">Invitez un ami</h3>
          </div>
          <p class="text-xs text-slate-500 mb-3 leading-relaxed">Parrainez un ami et gagnez tous les deux <strong>200 XP</strong> quand il termine son premier module.</p>
          <a routerLink="/app/parrainage" class="btn-secondary w-full justify-center btn-sm border-purple-200 text-purple-700 hover:bg-purple-50">Mon lien de parrainage</a>
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

  readonly profil        = signal<ProfilTalentResponse | null>(MOCK_PROFIL);
  readonly progressions  = signal<ProgressionResponse[]>([MOCK_PROGRESSION]);
  readonly tousLesCours  = signal<CoursResponse[]>(MOCK_COURS);
  readonly notifications = signal<NotificationResponse[]>(MOCK_NOTIFICATIONS);
  readonly draw          = signal(MOCK_DRAW);

  readonly profilLoading      = signal(true);
  readonly progressionLoading = signal(true);
  readonly notifLoading       = signal(true);

  readonly prenom     = computed(() => this.#auth.currentUser()?.prenom ?? 'Apprenant');
  readonly nbFilleuls = computed(() => Math.floor((this.profil()?.xpTotal ?? 0) / 200));

  readonly xpPct = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    const niveaux = [500,1000,2000,5000,10000];
    const prochain = niveaux.find(n => n > xp) ?? 10000;
    const prev     = niveaux[niveaux.indexOf(prochain) - 1] ?? 0;
    return Math.min(100, ((xp - prev) / (prochain - prev)) * 100);
  });
  readonly ptsManquants = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    const niveaux = [500,1000,2000,5000,10000];
    const prochain = niveaux.find(n => n > xp) ?? 10000;
    return (prochain - xp).toLocaleString('fr-FR');
  });
  readonly suggestions = computed(() => {
    const ids = this.progressions().map(p => p.coursId);
    return this.tousLesCours().filter(c => !ids.includes(c.id)).slice(0, 4);
  });
  readonly hasPaiementEnAttente = computed(() => this.progressions().some(p => p.seuilAtteint && !p.estPaye));

  getCoursTitle(id: string): string  { return this.tousLesCours().find(c => c.id === id)?.titre ?? 'Formation MbemNova'; }
  getCoursSlug(id: string): string   { return this.tousLesCours().find(c => c.id === id)?.slug ?? id; }

  ngOnInit(): void {
    this.#loadProfil();
    this.#loadProgressions();
    this.#loadCours();
    this.#loadNotifications();
    this.#loadDraw();
  }

  #loadProfil(): void {
    this.#talentSvc.getMe().subscribe({
      next: r => { if (r.success && r.data) this.profil.set(r.data); this.profilLoading.set(false); },
      error: () => { this.profilLoading.set(false); },
    });
  }
  #loadProgressions(): void {
    this.#progressSvc.getAll().subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.progressions.set(r.data.content); this.progressionLoading.set(false); },
      error: () => { this.progressionLoading.set(false); },
    });
  }
  #loadCours(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.tousLesCours.set(r.data.content); },
    });
  }
  #loadNotifications(): void {
    this.#notifSvc.getAll().subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.notifications.set(r.data.content); this.notifLoading.set(false); },
      error: () => { this.notifLoading.set(false); },
    });
  }
  #loadDraw(): void {
    this.#talentSvc.getTirage().subscribe({ next: r => { if (r.success && r.data) this.draw.set(r.data); } });
  }

  coursIconBg(i: number): string { return ['bg-blue-100','bg-emerald-100','bg-purple-100','bg-amber-100','bg-red-100','bg-cyan-100'][i % 6]; }
  coursIcon(i: number): string   { return ['💻','⚡','🎨','📊','📱','🚀','🌱','🔧','📚','🎯'][i % 10]; }
  notifBg(type: string): string  { if(type.includes('PAIEMENT')) return 'bg-amber-100'; if(type.includes('DEVOIR')) return 'bg-blue-100'; if(type==='CERTIFICAT_GENERE') return 'bg-green-100'; return 'bg-slate-100'; }
  notifEmoji(type: string): string { const m: Record<string,string>={PAIEMENT_ECHEANCE:'💳',PAIEMENT_RETARD:'⚠️',PAIEMENT_RECU:'✅',COURS_DEBLOQUE:'🔓',DEVOIR_PUBLIE:'📝',DEVOIR_CORRIGE:'✏️',REPONSE_COMMUNAUTE:'💬',PARRAINAGE_ACTIF:'🤝',TIRAGE_RESULTAT:'🎯',CERTIFICAT_GENERE:'🏆',COMPTE_SUSPENDU:'🚫',SYSTEME:'ℹ️'}; return m[type]??'ℹ️'; }
  timeAgo(iso: string): string   { const d=Math.floor((Date.now()-new Date(iso).getTime())/86_400_000),h=Math.floor((Date.now()-new Date(iso).getTime())/3_600_000),m=Math.floor((Date.now()-new Date(iso).getTime())/60_000); return d>=1?`il y a ${d}j`:h>=1?`il y a ${h}h`:`il y a ${m}min`; }
}
EOF
ok "Dashboard"

# ============================================================
# 7. STYLES.CSS — utilitaires manquants
# ============================================================
sec "7/7 — Patch styles.css (utilitaires manquants)"

# Ajouter les classes qui peuvent manquer dans Tailwind
cat >> src/styles.css << 'EOF'

/* ── Correctifs utilitaires (ne pas dupliquer si déjà présents) ─── */
@layer utilities {
  /* Pipe number format (Angular ne peut pas utiliser | number dans Tailwind) */
  .number-fr { font-variant-numeric: tabular-nums; }

  /* Line clamp natif */
  .line-clamp-1 { overflow: hidden; display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 1; }
  .line-clamp-2 { overflow: hidden; display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
  .line-clamp-3 { overflow: hidden; display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 3; }

  /* Dot pulse pour logo */
  .animate-dot-pulse { animation: dotPulse 2s ease-in-out infinite; }

  /* Aspect ratio vidéo */
  .aspect-video { aspect-ratio: 16 / 9; }
}
EOF
ok "styles.css patch"

echo ""
echo -e "${G}══════════════════════════════════════════════════════${N}"
echo -e "${G}  Refonte Part 2 terminée ✓                           ${N}"
echo -e "${G}══════════════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  Landing          — style Xarala (hero + domaines + bootcamps + méthode)"
echo -e "  ${G}✓${N}  Catalog           — filtres + skeleton + pagination"
echo -e "  ${G}✓${N}  CourseDetail      — programme collapsible + avis vérifiés (S4) + liste attente"
echo -e "  ${G}✓${N}  Login / Register  — panels illustrés + validation complète"
echo -e "  ${G}✓${N}  ForgotPwd / Reset — états anti-énumération + token validé"
echo -e "  ${G}✓${N}  Dashboard         — KPIs réels + suggestions + skeleton partout"
echo -e "  ${G}✓${N}  environment.ts    — documentation bascule mock ↔ API"
echo ""
echo -e "  ${G}✓${N}  À lancer en ordre :"
echo -e "    1. ./ng01_tokens_config.sh"
echo -e "    2. ./ng02_models_services.sh"
echo -e "    3. ./ng03_app_shell.sh"
echo -e "    4. ./ng_refonte_complete.sh      ← models + mock + services + course-player HTB"
echo -e "    5. ./ng_refonte_part2.sh         ← landing + catalog + auth + dashboard"
echo -e "    6. npm install && npm start"
echo ""
echo -e "  ${B}Tester les 4 profils :${N}"
echo -e "    Badge 🎭 en bas à gauche → clic → choisir APPRENANT / FORMATEUR / ADMIN / SUPER_ADMIN"
echo ""
echo -e "  ${B}Basculer vers l'API réelle :${N}"
echo -e "    src/environments/environment.ts → useMock: false"
echo -e "    (aucun autre fichier à modifier)"
echo ""
