import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { AdminService } from '../../../core/services/admin.service';
import type { StatistiquesResponse, ApprenantAdminView } from '../../../core/models';
import { MOCK_STATS } from '../../../core/services/mock.data';
import { AuthService } from '../../../core/services/auth.service';

// Données graphiques revenus (mock 6 derniers mois)
const REVENUS_MOIS = [
  { mois: 'Nov', valeur: 420000 },
  { mois: 'Déc', valeur: 580000 },
  { mois: 'Jan', valeur: 490000 },
  { mois: 'Fév', valeur: 720000 },
  { mois: 'Mar', valeur: 650000 },
  { mois: 'Avr', valeur: 890000 },
];

// Activité récente mock
const ACTIVITE = [
  { type: 'inscription',  texte: 'Serge Mvondo a rejoint la formation Dev Web',           heure: 'il y a 12 min', color: 'bg-green-100 text-green-700' },
  { type: 'paiement',     texte: 'Diane Kamga — tranche 2/3 reçue (10 000 FCFA)',         heure: 'il y a 1h',    color: 'bg-blue-100 text-blue-700' },
  { type: 'suspension',   texte: 'Rodrigue Ekambi — compte suspendu (retard 45j)',         heure: 'il y a 2h',    color: 'bg-red-100 text-red-700' },
  { type: 'moratoire',    texte: 'Jean-Paul Mbemba — demande de délai reçue',              heure: 'il y a 3h',    color: 'bg-amber-100 text-amber-700' },
  { type: 'certificat',   texte: 'Yvonne Beyala a obtenu son certificat Python',           heure: 'hier',         color: 'bg-purple-100 text-purple-700' },
  { type: 'inscription',  texte: 'Patrick Nganou a rejoint la formation React/Node.js',   heure: 'hier',         color: 'bg-green-100 text-green-700' },
];

@Component({
  selector: 'app-admin-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête admin -->
  <div class="bg-slate-900 text-white">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-slate-400 text-sm mb-0.5">Back-office MbemNova</p>
          <h1 class="text-2xl font-black" style="font-family:var(--font);">
            Bonjour, {{ prenom() }} 👋
          </h1>
        </div>
        <div class="flex items-center gap-2">
          <span class="flex items-center gap-1.5 text-xs text-green-400">
            <span class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
            Système opérationnel
          </span>
        </div>
      </div>
    </div>
  </div>

  <div class="container py-8 space-y-8">

    <!-- ── KPIs ──────────────────────────────────────────── -->
    <section aria-label="Indicateurs clés">
      @if (statsLoading()) {
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          @for (_ of [1,2,3,4]; track $index) {
            <div class="card p-5">
              <div class="shimmer h-8 rounded w-1/2 mb-2"></div>
              <div class="shimmer h-4 rounded w-3/4 mb-3"></div>
              <div class="shimmer h-1.5 rounded-full w-full"></div>
            </div>
          }
        </div>
      }

      @if (!statsLoading() && stats()) {
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">

          <!-- Apprenants actifs -->
          <div class="card p-5 animate-fade-up">
            <div class="flex items-center justify-between mb-3">
              <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center" aria-hidden="true">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                  <circle cx="9" cy="7" r="4"/>
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
              </div>
              <span class="badge-green text-xs">Apprenants</span>
            </div>
            <p class="text-3xl font-black text-slate-900">{{ stats()!.apprenantsActifs ?? 0 }}</p>
            <p class="text-sm text-slate-500 mb-3">Apprenants actifs</p>
            <div class="progress">
              <div class="progress-bar bg-blue-500"
                   [style.width.%]="stats()!.totalApprenants ? (stats()!.apprenantsActifs / stats()!.totalApprenants) * 100 : 0">
              </div>
            </div>
            <p class="text-xs text-slate-400 mt-1">
              {{ stats()!.totalApprenants ?? 0 }} inscrits au total
            </p>
          </div>

          <!-- Formateurs actifs -->
          <div class="card p-5 animate-fade-up delay-75">
            <div class="flex items-center justify-between mb-3">
              <div class="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center" aria-hidden="true">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                  <circle cx="9" cy="7" r="4"/>
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
              </div>
              <span class="badge-purple text-xs">Formateurs</span>
            </div>
            <p class="text-3xl font-black text-slate-900">{{ stats()!.formateursActifs ?? 0 }}</p>
            <p class="text-sm text-slate-500 mb-3">Formateurs actifs</p>
            <div class="progress">
              <div class="progress-bar bg-purple-500" style="width: 100%"></div>
            </div>
            <p class="text-xs text-slate-400 mt-1">
              {{ stats()!.formateursActifs ?? 0 }} formateurs au total
            </p>
          </div>

          <!-- Nombre total de formations -->
          <div class="card p-5 animate-fade-up delay-100">
            <div class="flex items-center justify-between mb-3">
              <div class="w-10 h-10 rounded-xl bg-indigo-100 flex items-center justify-center" aria-hidden="true">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" stroke-width="2">
                  <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
                  <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
                </svg>
              </div>
              <span class="badge-indigo text-xs">Catalogue</span>
            </div>
            <p class="text-3xl font-black text-slate-900">{{ stats()!.totalFormations ?? 0 }}</p>
            <p class="text-sm text-slate-500 mb-3">Nombre total de formations</p>
            <div class="progress">
              <div class="progress-bar bg-indigo-500" style="width: 100%"></div>
            </div>
            <p class="text-xs text-slate-400 mt-1">
              {{ stats()!.totalFormations ?? 0 }} formations au total
            </p>
          </div>

          <!-- Paiements en attente -->
          <div class="card p-5 animate-fade-up delay-150">
            <div class="flex items-center justify-between mb-3">
              <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center" aria-hidden="true">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2">
                  <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/>
                  <line x1="1" y1="10" x2="23" y2="10"/>
                </svg>
              </div>
              <span class="badge-amber text-xs">À valider</span>
            </div>
            <p class="text-3xl font-black text-slate-900">{{ stats()!.paiementsEnAttente ?? 0 }}</p>
            <p class="text-sm text-slate-500 mb-3">Paiements en attente</p>
            <div class="progress">
              <div class="progress-bar bg-amber-500" style="width: 100%"></div>
            </div>
            <p class="text-xs text-slate-400 mt-1">
              {{ stats()!.paiementsEnAttente ?? 0 }} transactions à confirmer
            </p>
          </div>

        </div>
      }
    </section>

    <!-- ── ALERTES URGENTES ───────────────────────────────── -->
    @if (alertes.length > 0) {
      <section aria-label="Alertes urgentes">
        <h2 class="h3 mb-4 flex items-center gap-2">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" aria-hidden="true">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
            <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
          </svg>
          Alertes
        </h2>
        <div class="space-y-3">
          @for (a of alertes; track a.label; let i = $index) {
            <a [routerLink]="a.href"
               class="card flex items-center gap-4 p-4 hover:shadow-md transition-shadow animate-fade-up group"
               [class]="a.urgent ? 'border-red-200 bg-red-50' : 'border-amber-200 bg-amber-50'"
               [style]="'animation-delay:' + (i * 40) + 'ms'">
              <div [class]="'w-10 h-10 rounded-xl flex items-center justify-center text-xl shrink-0 '
                            + (a.urgent ? 'bg-red-100' : 'bg-amber-100')" aria-hidden="true">
                {{ a.icon }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold"
                   [class]="a.urgent ? 'text-red-900' : 'text-amber-900'">
                  {{ a.label }}
                </p>
                <p class="text-xs mt-0.5"
                   [class]="a.urgent ? 'text-red-600' : 'text-amber-600'">
                  {{ a.desc }}
                </p>
              </div>
              <div class="flex items-center gap-2 shrink-0">
                <span [class]="'text-xl font-black ' + (a.urgent ? 'text-red-700' : 'text-amber-700')">
                  {{ a.count }}
                </span>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8"
                     stroke-width="2" class="opacity-0 group-hover:opacity-100 transition-opacity" aria-hidden="true">
                  <path d="M9 18l6-6-6-6"/>
                </svg>
              </div>
            </a>
          }
        </div>
      </section>
    }

    <!-- ── GRILLE PRINCIPALE ─────────────────────────────── -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Graphique revenus -->
      <div class="lg:col-span-2 card p-6 animate-fade-up">
        <div class="flex items-center justify-between mb-6">
          <h2 class="h3">Revenus (6 derniers mois)</h2>
          <span class="badge-green">+18% vs mois précédent</span>
        </div>

        <!-- Graphique barres SVG (0 dépendance) -->
        <div class="relative">
          <svg viewBox="0 0 520 200" xmlns="http://www.w3.org/2000/svg"
               class="w-full" aria-label="Graphique des revenus des 6 derniers mois"
               role="img">

            <!-- Lignes de grille horizontales -->
            @for (line of gridLines; track line.y) {
              <line [attr.x1]="50" [attr.y1]="line.y" x2="500" [attr.y2]="line.y"
                    stroke="#e2e8f0" stroke-width="1" stroke-dasharray="4 4"/>
              <text [attr.x]="44" [attr.y]="line.y + 4" text-anchor="end"
                    font-size="10" fill="#94a3b8" font-family="DM Sans, system-ui">
                {{ line.label }}
              </text>
            }

            <!-- Barres -->
            @for (bar of barData; track bar.mois; let i = $index) {
              <g>
                <!-- Barre principale -->
                <rect [attr.x]="60 + i * 75" [attr.y]="bar.y"
                      width="44" [attr.height]="bar.height"
                      rx="6" ry="6"
                      [attr.fill]="i === barData.length - 1 ? '#2563eb' : '#93c5fd'"
                      class="transition-all duration-300">
                </rect>
                <!-- Étiquette mois -->
                <text [attr.x]="82 + i * 75" y="195"
                      text-anchor="middle" font-size="11" fill="#64748b" font-family="DM Sans, system-ui">
                  {{ bar.mois }}
                </text>
                <!-- Valeur au survol simulé (dernier mois) -->
                @if (i === barData.length - 1) {
                  <text [attr.x]="82 + i * 75" [attr.y]="bar.y - 6"
                        text-anchor="middle" font-size="9" fill="#2563eb" font-weight="700"
                        font-family="DM Sans, system-ui">
                    890K
                  </text>
                }
              </g>
            }

            <!-- Ligne de tendance -->
            <polyline [attr.points]="trendLine" fill="none"
                      stroke="#2563eb" stroke-width="2" stroke-dasharray="5 3" opacity="0.5"/>

          </svg>
        </div>
      </div>

      <!-- Activité récente -->
      <div class="card p-5 animate-fade-up delay-75">
        <h2 class="h3 mb-4">Activité récente</h2>
        <div class="space-y-3">
          @for (a of activite; track a.texte; let i = $index) {
            <div class="flex items-start gap-3 animate-fade-up"
                 [style]="'animation-delay:' + (i * 40) + 'ms'">
              <div [class]="'w-8 h-8 rounded-lg flex items-center justify-center text-sm shrink-0 ' + a.color"
                   aria-hidden="true">
                {{ actEmoji(a.type) }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-xs text-slate-700 leading-snug">{{ a.texte }}</p>
                <p class="text-xs text-slate-400 mt-0.5">{{ a.heure }}</p>
              </div>
            </div>
          }
        </div>
      </div>
    </div>

    <!-- ── ACTIONS RAPIDES ───────────────────────────────── -->
    <section aria-label="Actions rapides">
      <h2 class="h3 mb-4">Actions rapides</h2>
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
        @for (action of actions; track action.label; let i = $index) {
          <a [routerLink]="action.href"
             class="card p-4 flex flex-col items-center gap-2 text-center
                    hover:shadow-md hover:-translate-y-0.5 transition-all duration-150 animate-fade-up"
             [style]="'animation-delay:' + (i * 40) + 'ms'">
            <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-2xl ' + action.bg"
                 aria-hidden="true">
              {{ action.icon }}
            </div>
            <p class="text-xs font-medium text-slate-700 leading-snug">{{ action.label }}</p>
          </a>
        }
      </div>
    </section>

    <!-- ── DERNIÈRES INSCRIPTIONS ────────────────────────── -->
    <section aria-label="Dernières inscriptions">
      <div class="flex items-center justify-between mb-4">
        <h2 class="h3">Dernières inscriptions</h2>
        <a routerLink="/admin/apprenants"
           class="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors">
          Voir tous les apprenants
        </a>
      </div>
      <div class="card overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full" aria-label="Tableau des dernières inscriptions">
            <thead>
              <tr class="bg-slate-50 border-b border-slate-200">
                <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Apprenant</th>
                <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Email</th>
                <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Statut</th>
                <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden md:table-cell">XP</th>
                <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden lg:table-cell">Inscrit le</th>
                <th class="px-5 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              @for (a of apprenants(); track a.id; let i = $index) {
                <tr class="hover:bg-slate-50 transition-colors">
                  <td class="px-5 py-3.5">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0"
                           [class]="a.statut === 'SUSPENDU' ? 'bg-red-400' : 'bg-blue-600'">
                        {{ a.prenom.charAt(0) }}
                      </div>
                      <div>
                        <p class="text-sm font-medium text-slate-900">{{ a.prenom }} {{ a.nom }}</p>
                        <p class="text-xs text-slate-400">{{ a.nbCoursInscrits ?? 0 }} cours</p>
                      </div>
                    </div>
                  </td>
                  <td class="px-5 py-3.5 text-sm text-slate-500 hidden sm:table-cell">{{ a.email }}</td>
                  <td class="px-5 py-3.5">
                    <span [class]="a.statut === 'ACTIF' ? 'badge-green' : a.statut === 'SUSPENDU' ? 'badge-red' : 'badge-slate'">
                      {{ a.statut }}
                    </span>
                  </td>
                  <td class="px-5 py-3.5 text-sm text-slate-500 hidden md:table-cell">
                    {{ a.xpTotal   }} XP
                    <!-- {{ a.xpTotal | number:'1.0-0' }} XP -->
                  </td>
                  <td class="px-5 py-3.5 text-xs text-slate-400 hidden lg:table-cell">
                    {{ formatDate(a.inscritLe) }}
                  </td>
                  <td class="px-5 py-3.5 text-right">
                    <a routerLink="/admin/apprenants"
                       class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
                      Voir
                    </a>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>
    </section>

  </div>
</div>
  `,
  styles: [`
    :host { display: block; }
    .bg-slate-50 {
      background-color: var(--bg) !important;
      transition: background-color 0.2s ease;
    }
    .bg-slate-900 {
      background-color: var(--bg-subtle) !important;
      border-bottom: 1px solid var(--border);
      transition: background-color 0.2s ease, border-color 0.2s ease;
      color: var(--tx) !important;
    }
    .bg-slate-900 .text-slate-400 {
      color: var(--tx-sec) !important;
    }
    .card {
      background-color: var(--bg-subtle) !important;
      border-color: var(--border) !important;
      color: var(--tx) !important;
    }
    .text-slate-900 {
      color: var(--tx) !important;
    }
    .text-slate-700 {
      color: var(--tx) !important;
    }
    .text-slate-800 {
      color: var(--tx) !important;
    }
    .text-slate-500 {
      color: var(--tx-sec) !important;
    }
    .text-slate-400 {
      color: var(--tx-muted) !important;
    }
    .bg-blue-100 {
      background-color: var(--bg-muted) !important;
    }
    .bg-purple-100 {
      background-color: var(--bg-muted) !important;
    }
    .bg-indigo-100 {
      background-color: var(--bg-muted) !important;
    }
    .bg-amber-100 {
      background-color: var(--bg-muted) !important;
    }
    .bg-red-50 {
      background-color: rgba(239, 68, 68, 0.08) !important;
    }
    .border-red-200 {
      border-color: rgba(239, 68, 68, 0.2) !important;
    }
    .bg-amber-50 {
      background-color: rgba(245, 158, 11, 0.08) !important;
    }
    .border-amber-200 {
      border-color: rgba(245, 158, 11, 0.2) !important;
    }
    /* SVG graph grid lines */
    line[stroke="#e2e8f0"] {
      stroke: var(--border) !important;
    }
    /* SVG graph text labels */
    text[fill="#94a3b8"] {
      fill: var(--tx-sec) !important;
    }
    .border-slate-50, .border-slate-100 {
      border-color: var(--border) !important;
    }
    .hover\:bg-slate-50:hover {
      background-color: var(--bg-muted) !important;
    }
    /* Shimmer effect for skeleton loader */
    .shimmer {
      background: linear-gradient(90deg, var(--bg-muted) 25%, var(--border) 50%, var(--bg-muted) 75%) !important;
      background-size: 200% 100% !important;
    }
  `],
})
export class AdminDashboardComponent implements OnInit {
  readonly #adminSvc = inject(AdminService);
  readonly #auth     = inject(AuthService);

  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Admin');
  readonly stats  = signal<StatistiquesResponse | null>(null);
  readonly statsLoading = signal(true);
  readonly apprenants   = signal<ApprenantAdminView[]>([]);

  // ── Alertes ───────────────────────────────────────────
  readonly alertes = [
    { icon: '🚨', label: '5 paiements en retard', desc: 'Comptes à risque de suspension — action requise sous 48h', count: 5, href: '/admin/paiements', urgent: true },
    { icon: '⏳', label: '12 paiements en attente', desc: 'Versements reçus à confirmer et activer', count: 12, href: '/admin/paiements', urgent: false },
    { icon: '📋', label: '3 demandes de moratoire', desc: 'Demandes de délai soumises par des apprenants', count: 3, href: '/admin/paiements', urgent: false },
  ];

  // ── Graphique barres ──────────────────────────────────
  readonly maxVal = Math.max(...REVENUS_MOIS.map(d => d.valeur));

  readonly barData = REVENUS_MOIS.map((d, i) => ({
    mois:   d.mois,
    height: Math.round((d.valeur / this.maxVal) * 140),
    y:      Math.round(160 - (d.valeur / this.maxVal) * 140),
  }));

  readonly gridLines = [
    { y: 20,  label: '900K' },
    { y: 57,  label: '600K' },
    { y: 110, label: '300K' },
    { y: 160, label: '0' },
  ];

  readonly trendLine = this.barData
    .map((b, i) => `${82 + i * 75},${b.y + b.height / 2}`)
    .join(' ');

  // ── Activité récente ──────────────────────────────────
  readonly activite = ACTIVITE;

  // ── Actions rapides ───────────────────────────────────
  readonly actions = [
    { icon: '👤', label: 'Inscrire manuellement', href: '/admin/apprenants', bg: 'bg-blue-100' },
    { icon: '💳', label: 'Enregistrer paiement',  href: '/admin/paiements',  bg: 'bg-green-100' },
    { icon: '🚫', label: 'Suspendre compte',       href: '/admin/apprenants', bg: 'bg-red-100'  },
    { icon: '🎯', label: 'Configurer tirage',      href: '/admin/tirage',     bg: 'bg-amber-100' },
    { icon: '🛡️', label: 'Gérer les rôles',        href: '/admin/roles',      bg: 'bg-purple-100' },
  ];

  ngOnInit(): void {
    // 1. Charger les statistiques globales
    this.#adminSvc.getStats().subscribe({
      next: r => { if (r.success && r.data) this.stats.set(r.data); this.statsLoading.set(false); },
      error: () => { this.statsLoading.set(false); },
    });

    // 2. Charger les dernières inscriptions apprenants
    this.#adminSvc.getApprenants({ size: 5 }).subscribe({
      next: r => {
        if (r.success && r.data) {
          const list = r.data.content || r.data;
          if (Array.isArray(list)) {
            this.apprenants.set(list.slice(0, 5));
          }
        }
      }
    });
  }

  actEmoji(type: string): string {
    return { inscription: '👤', paiement: '💳', suspension: '🚫', moratoire: '⏳', certificat: '🏆' }[type] ?? 'ℹ️';
  }

  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
  }
}
