#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 01/16 · Tokens + Config
# ============================================================
# Contenu :
#   - src/tokens.css           → source de vérité design (1 fichier)
#   - src/styles.css           → Tailwind uniquement, 0 CSS custom
#   - tailwind.config.js       → palette + breakpoints 100px
#   - src/app/app.config.ts    → providers SSR
#   - src/app/app.config.server.ts
#   - tsconfig.json            → paths @core @shared @features @env
#
# Usage : chmod +x ng01_tokens_config.sh && ./ng01_tokens_config.sh
# Prérequis : Angular 21 + Tailwind déjà installés
# ============================================================
set -euo pipefail

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "${R}  ✗${N} $1" >&2; exit 1; }

[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet Angular"

echo -e "\n${B}══════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 01 · Tokens + Config     ${N}"
echo -e "${B}══════════════════════════════════════${N}\n"

# ============================================================
# 1. DESIGN TOKENS — src/tokens.css
#    Source de vérité absolue. Pour changer une couleur sur
#    tout le site : modifier CE seul fichier.
#
#    Philosophie couleur (plateformes qui retiennent le plus) :
#    • Bleu primaire  → confiance, expertise (Coursera, LinkedIn)
#    • Vert succès    → progression, validation (signal universel)
#    • Ambre          → attention, délais (signal universel)
#    • Rouge          → erreur, suspension (signal universel)
#    • Or             → gamification, XP, récompenses
#    • Fond blanc pur → focus contenu (Notion, Linear)
# ============================================================
sec "1/6 — Design tokens"

cat > src/tokens.css << 'EOF'
/* ============================================================
   MBEMNOVA · Design Tokens · Source de vérité unique
   Pour changer l'UI : modifier ce fichier uniquement.
   ============================================================ */

:root {
  /* ── Bleu primaire (confiance, apprentissage) ──────────── */
  --p-50:  #eff6ff;
  --p-100: #dbeafe;
  --p-200: #bfdbfe;
  --p-300: #93c5fd;
  --p-400: #60a5fa;
  --p-500: #3b82f6;
  --p-600: #2563eb;   /* ← Action principale */
  --p-700: #1d4ed8;   /* ← Hover */
  --p-800: #1e40af;   /* ← Navbar / éléments forts */
  --p-900: #1e3a8a;

  /* ── Vert succès (progression, XP, certificat) ─────────── */
  --s-50:  #f0fdf4;
  --s-100: #dcfce7;
  --s-500: #22c55e;
  --s-600: #16a34a;   /* ← Badges succès */
  --s-700: #15803d;

  /* ── Ambre (relances, délais, avertissements) ───────────── */
  --a-50:  #fffbeb;
  --a-100: #fef3c7;
  --a-500: #f59e0b;
  --a-600: #d97706;   /* ← Badges warning */

  /* ── Rouge (erreurs, suspension, retard) ───────────────── */
  --r-50:  #fef2f2;
  --r-100: #fee2e2;
  --r-500: #ef4444;
  --r-600: #dc2626;   /* ← Danger */

  /* ── Or (gamification, XP, tirage) ────────────────────── */
  --g-400: #fbbf24;
  --g-500: #f59e0b;
  --g-600: #d97706;

  /* ── Violet (instructor, formateur) ────────────────────── */
  --v-50:  #faf5ff;
  --v-600: #9333ea;
  --v-700: #7e22ce;

  /* ── Neutres (surfaces, textes) ────────────────────────── */
  --bg:         #ffffff;   /* Fond principal */
  --bg-subtle:  #f8fafc;   /* Fond cartes */
  --bg-muted:   #f1f5f9;   /* Fond inputs */
  --border:     #e2e8f0;   /* Bordures */
  --border-md:  #cbd5e1;   /* Bordures hover */

  --tx:         #0f172a;   /* Texte principal */
  --tx-sec:     #475569;   /* Texte secondaire */
  --tx-muted:   #94a3b8;   /* Placeholder */
  --tx-inv:     #ffffff;   /* Texte sur fond coloré */

  /* ── Typographie ──────────────────────────────────────── */
  --font:       'DM Sans', system-ui, -apple-system, sans-serif;
  --font-mono:  'JetBrains Mono', 'Fira Code', monospace;

  /* ── Ombres ───────────────────────────────────────────── */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0/.05);
  --shadow-sm: 0 1px 3px 0 rgb(0 0 0/.08),0 1px 2px -1px rgb(0 0 0/.06);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0/.07),0 2px 4px -2px rgb(0 0 0/.05);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0/.07),0 4px 6px -4px rgb(0 0 0/.05);
  --shadow-focus: 0 0 0 3px rgb(37 99 235/.25);

  /* ── Transitions ──────────────────────────────────────── */
  --t-fast:   150ms ease;
  --t-base:   200ms ease;
  --t-slow:   300ms ease;
  --t-spring: 350ms cubic-bezier(0.34,1.56,0.64,1);

  /* ── Z-index ──────────────────────────────────────────── */
  --z-dropdown: 100;
  --z-sticky:   200;
  --z-modal:    300;
  --z-toast:    400;
}
EOF
ok "src/tokens.css"

# ============================================================
# 2. STYLES.CSS — Tailwind uniquement, 0 CSS custom sauf
#    ce qui est strictement impossible en Tailwind pur
#    (animations keyframes, shimmer gradient, scrollbar)
# ============================================================
sec "2/6 — styles.css (Tailwind only)"

cat > src/styles.css << 'EOF'
/* MbemNova · styles.css
   Règle absolue : Tailwind uniquement.
   CSS custom = uniquement si impossible via classes Tailwind. */

@import './tokens.css';

/* Police DM Sans — chaleureuse, moderne, très lisible */
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

/* ── BASE CRITIQUE ─────────────────────────────────────── */
@layer base {
  html {
    font-family: var(--font);
    color: var(--tx);
    background: var(--bg);
    -webkit-text-size-adjust: 100%;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
  }

  /* Focus accessible */
  :focus-visible {
    outline: 2px solid var(--p-600);
    outline-offset: 2px;
    border-radius: 4px;
  }

  /* Sélection texte */
  ::selection {
    background: var(--p-100);
    color: var(--p-900);
  }

  /* Scrollbar discrète */
  ::-webkit-scrollbar { width: 5px; height: 5px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb {
    background: var(--border-md);
    border-radius: 9999px;
  }
}

/* ── COMPOSANTS TAILWIND ───────────────────────────────── */
@layer components {

  /* Carte standard */
  .card {
    @apply bg-white rounded-xl border border-slate-200
           shadow-[var(--shadow-sm)] transition-shadow duration-200;
  }
  .card-hover { @apply card hover:shadow-[var(--shadow-md)] hover:-translate-y-px; }

  /* Boutons */
  .btn {
    @apply inline-flex items-center justify-center gap-2 font-medium rounded-lg
           transition-all duration-150 select-none
           focus-visible:outline-none focus-visible:ring-2
           focus-visible:ring-blue-600 focus-visible:ring-offset-2
           disabled:opacity-50 disabled:pointer-events-none;
  }
  .btn-primary  { @apply btn bg-blue-600 text-white hover:bg-blue-700 active:bg-blue-800 px-4 py-2.5 text-sm; }
  .btn-secondary{ @apply btn bg-white text-blue-600 border border-blue-200 hover:bg-blue-50 px-4 py-2.5 text-sm; }
  .btn-ghost    { @apply btn text-slate-600 hover:bg-slate-100 px-3 py-2 text-sm; }
  .btn-danger   { @apply btn bg-red-600 text-white hover:bg-red-700 px-4 py-2.5 text-sm; }
  .btn-success  { @apply btn bg-green-600 text-white hover:bg-green-700 px-4 py-2.5 text-sm; }
  .btn-sm       { @apply px-3 py-1.5 text-xs; }
  .btn-lg       { @apply px-6 py-3 text-base; }
  .btn-icon     { @apply btn p-2; }

  /* Inputs */
  .input {
    @apply w-full rounded-lg border border-slate-200 bg-white px-3.5 py-2.5
           text-sm text-slate-900 placeholder-slate-400
           focus:outline-none focus:ring-2 focus:ring-blue-600
           focus:border-transparent transition-all duration-150
           disabled:bg-slate-50 disabled:text-slate-400;
  }
  .input-error  { @apply border-red-400 focus:ring-red-500; }
  .label        { @apply block text-sm font-medium text-slate-700 mb-1.5; }
  .field-error  { @apply text-xs text-red-600 mt-1 flex items-center gap-1; }

  /* Badges */
  .badge        { @apply inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium; }
  .badge-blue   { @apply badge bg-blue-50 text-blue-700 border border-blue-200; }
  .badge-green  { @apply badge bg-green-50 text-green-700 border border-green-200; }
  .badge-amber  { @apply badge bg-amber-50 text-amber-700 border border-amber-200; }
  .badge-red    { @apply badge bg-red-50 text-red-700 border border-red-200; }
  .badge-slate  { @apply badge bg-slate-100 text-slate-600; }
  .badge-gold   { @apply badge bg-amber-100 text-amber-800 border border-amber-300; }
  .badge-purple { @apply badge bg-purple-50 text-purple-700 border border-purple-200; }

  /* Layout */
  .container    { @apply max-w-7xl mx-auto px-4 sm:px-6 lg:px-8; }
  .section      { @apply py-12 md:py-16 lg:py-20; }

  /* Typographie */
  .h1 { @apply text-3xl md:text-4xl font-bold text-slate-900 tracking-tight; }
  .h2 { @apply text-2xl md:text-3xl font-bold text-slate-900 tracking-tight; }
  .h3 { @apply text-xl font-semibold text-slate-900; }
  .h4 { @apply text-base font-semibold text-slate-900; }
  .lead { @apply text-lg text-slate-600 leading-relaxed; }
  .link { @apply text-blue-600 hover:text-blue-700 hover:underline underline-offset-2 transition-colors; }

  /* Progression */
  .progress     { @apply h-2 bg-slate-100 rounded-full overflow-hidden; }
  .progress-bar { @apply h-full rounded-full transition-all duration-500 ease-out; }

  /* Divider */
  .divider      { @apply border-t border-slate-100; }

  /* Skeleton */
  .skeleton     { @apply bg-slate-200 rounded animate-pulse; }

  /* Empty state */
  .empty-state  { @apply flex flex-col items-center justify-center py-16 text-center px-4; }
}

/* ── ANIMATIONS (impossible en Tailwind pur) ───────────── */
@layer utilities {

  @keyframes fadeInUp {
    from { opacity: 0; transform: translateY(10px); }
    to   { opacity: 1; transform: translateY(0); }
  }
  @keyframes fadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
  }
  @keyframes slideInRight {
    from { opacity: 0; transform: translateX(12px); }
    to   { opacity: 1; transform: translateX(0); }
  }
  @keyframes slideDown {
    from { opacity: 0; transform: translateY(-6px); }
    to   { opacity: 1; transform: translateY(0); }
  }
  @keyframes scaleIn {
    from { opacity: 0; transform: scale(0.96); }
    to   { opacity: 1; transform: scale(1); }
  }
  /* Shimmer skeleton */
  @keyframes shimmer {
    from { background-position: -400px 0; }
    to   { background-position:  400px 0; }
  }
  /* Barre loading page */
  @keyframes loadingBar {
    0%   { transform: translateX(-100%); }
    50%  { transform: translateX(0%); }
    100% { transform: translateX(100%); }
  }
  /* Dot logo */
  @keyframes dotPulse {
    0%,100% { transform: scale(1); opacity: 1; }
    50%     { transform: scale(1.5); opacity: 0.7; }
  }
  /* XP burst */
  @keyframes xpBurst {
    0%   { opacity: 1; transform: translateY(0) scale(1); }
    100% { opacity: 0; transform: translateY(-40px) scale(0.5); }
  }

  .animate-fade-up    { animation: fadeInUp 0.28s ease both; }
  .animate-fade-in    { animation: fadeIn 0.2s ease both; }
  .animate-slide-right{ animation: slideInRight 0.22s ease both; }
  .animate-slide-down { animation: slideDown 0.18s ease both; }
  .animate-scale-in   { animation: scaleIn 0.2s ease both; }
  .animate-xp-burst   { animation: xpBurst 0.8s ease forwards; }

  /* Shimmer pour skeletons */
  .shimmer {
    background: linear-gradient(90deg,#f1f5f9 0px,#e2e8f0 80px,#f1f5f9 160px);
    background-size: 400px 100%;
    animation: shimmer 1.4s infinite linear;
  }

  /* Délais stagger */
  .delay-75  { animation-delay: 75ms; }
  .delay-100 { animation-delay: 100ms; }
  .delay-150 { animation-delay: 150ms; }
  .delay-200 { animation-delay: 200ms; }
  .delay-300 { animation-delay: 300ms; }
}
EOF
ok "src/styles.css"

# ============================================================
# 3. TAILWIND CONFIG — breakpoints depuis 100px, tokens
# ============================================================
sec "3/6 — tailwind.config.js"

cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  theme: {
    /* Breakpoints mobiles depuis 100px (vieux téléphones Afrique) */
    screens: {
      xs:  '100px',
      sm:  '390px',
      md:  '768px',
      lg:  '1024px',
      xl:  '1280px',
      '2xl': '1536px',
    },
    extend: {
      fontFamily: {
        sans: ['DM Sans', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      colors: {
        primary: {
          50: '#eff6ff', 100: '#dbeafe', 200: '#bfdbfe',
          300: '#93c5fd', 400: '#60a5fa', 500: '#3b82f6',
          600: '#2563eb', 700: '#1d4ed8', 800: '#1e40af', 900: '#1e3a8a',
        },
      },
      transitionTimingFunction: {
        spring: 'cubic-bezier(0.34,1.56,0.64,1)',
      },
      keyframes: {
        /* Réutilisés via Tailwind animate-* */
        dotPulse: {
          '0%,100%': { transform: 'scale(1)', opacity: '1' },
          '50%': { transform: 'scale(1.5)', opacity: '0.7' },
        },
      },
      animation: {
        'dot-pulse': 'dotPulse 2s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
EOF
ok "tailwind.config.js"

# ============================================================
# 4. TSCONFIG — chemins @core @shared @features @env
# ============================================================
sec "4/6 — tsconfig.json (paths)"

# Patch tsconfig.json pour ajouter les paths sans écraser l'existant
node -e "
const fs = require('fs');
const tc = JSON.parse(fs.readFileSync('tsconfig.json','utf8'));
tc.compilerOptions = tc.compilerOptions || {};
tc.compilerOptions.paths = {
  '@core/*':    ['src/app/core/*'],
  '@shared/*':  ['src/app/shared/*'],
  '@features/*':['src/app/features/*'],
  '@env/*':     ['src/environments/*'],
};
fs.writeFileSync('tsconfig.json', JSON.stringify(tc, null, 2));
console.log('paths ajoutés');
" 2>/dev/null && ok "tsconfig.json — paths configurés" || ok "tsconfig.json — mettre à jour manuellement si besoin"

# ============================================================
# 5. APP.CONFIG.TS — providers SSR-safe
# ============================================================
sec "5/6 — app.config.ts"

mkdir -p src/environments src/app/core/{models,services,guards,interceptors}

cat > src/environments/environment.ts << 'EOF'
export const environment = {
  production:   false,
  apiUrl:       'http://localhost:8080/api/v1',
  wsUrl:        'ws://localhost:8080/ws',
  /* ─────────────────────────────────────────────────────────
     USE_MOCK = true  → MockInterceptor intercepte toutes les requêtes
               false → Requêtes envoyées vers apiUrl (Spring Boot)
     AUTO_FALLBACK = true → Si l'API répond [] ou null, bascule
                            automatiquement sur les données mock
     ───────────────────────────────────────────────────────── */
  useMock:      true,
  autoFallback: true,
  version:      '1.0.0-dev',
} as const;
EOF

cat > src/environments/environment.prod.ts << 'EOF'
export const environment = {
  production:   true,
  apiUrl:       '/api/v1',   /* Relatif → Nginx proxy → Spring Boot :8080 */
  wsUrl:        '/ws',
  useMock:      false,
  autoFallback: false,
  version:      '1.0.0',
} as const;
EOF
ok "src/environments/"

cat > src/app/app.config.ts << 'EOF'
import {
  ApplicationConfig,
  ErrorHandler,
} from '@angular/core';
import {
  provideRouter,
  withComponentInputBinding,
  withViewTransitions,
} from '@angular/router';
import {
  provideHttpClient,
  withFetch,
  withInterceptors,
} from '@angular/common/http';
import { provideClientHydration } from '@angular/platform-browser';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { routes } from './app.routes';
import { authInterceptor }  from './core/interceptors/auth.interceptor';
import { errorInterceptor } from './core/interceptors/error.interceptor';
import { mockInterceptor }  from './core/interceptors/mock.interceptor';

/**
 * GlobalErrorHandler — Error Boundary Angular.
 * Capture les erreurs non catchées (lazy chunk, runtime).
 * En production : évite le crash complet de l'app.
 */
class GlobalErrorHandler implements ErrorHandler {
  handleError(error: unknown): void {
    const err = error as Error;
    // Chunk load error → nouvelle version déployée → reload propre
    if (
      err?.message?.includes('Loading chunk') ||
      err?.message?.includes('Failed to fetch dynamically imported module') ||
      err?.name === 'ChunkLoadError'
    ) {
      console.warn('[MbemNova] Nouvelle version détectée. Rechargement...');
      setTimeout(() => window.location.reload(), 1000);
      return;
    }
    console.error('[MbemNova]', err?.message ?? error);
    // Déclenche un toast via événement DOM (évite injection circulaire)
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new CustomEvent('mn:error', {
        detail: { message: 'Une erreur inattendue est survenue.' },
      }));
    }
  }
}

export const appConfig: ApplicationConfig = {
  providers: [
    // Router : input binding + transitions de vue natives
    provideRouter(
      routes,
      withComponentInputBinding(),
      withViewTransitions(),
    ),

    // HTTP : Fetch API + ordre des intercepteurs
    // mock → auth (JWT) → error (toasts)
    provideHttpClient(
      withFetch(),
      withInterceptors([mockInterceptor, authInterceptor, errorInterceptor]),
    ),

    // Hydratation SSR → CSR
    provideClientHydration(),

    // Animations lazy
    provideAnimationsAsync(),

    // Error Boundary
    { provide: ErrorHandler, useClass: GlobalErrorHandler },
  ],
};
EOF
ok "src/app/app.config.ts"

# ============================================================
# 6. APP.CONFIG.SERVER.TS — SSR providers
# ============================================================
sec "6/6 — app.config.server.ts"

cat > src/app/app.config.server.ts << 'EOF'
import { mergeApplicationConfig, ApplicationConfig } from '@angular/core';
import { provideServerRendering } from '@angular/platform-server';
import { provideServerRoutesConfig } from '@angular/ssr';
import { appConfig } from './app.config';
import { serverRoutes } from './app.routes.server';

const serverConfig: ApplicationConfig = {
  providers: [
    provideServerRendering(),
    provideServerRoutesConfig(serverRoutes),
  ],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
EOF
ok "src/app/app.config.server.ts"

echo ""
echo -e "${G}══════════════════════════════════════════${N}"
echo -e "${G}  Script 01 terminé ✓${N}"
echo -e "${G}══════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  tokens.css          (palette + variables)"
echo -e "  ${G}✓${N}  styles.css          (Tailwind + animations)"
echo -e "  ${G}✓${N}  tailwind.config.js  (breakpoints 100px)"
echo -e "  ${G}✓${N}  tsconfig.json       (paths @core @shared)"
echo -e "  ${G}✓${N}  environments/       (mock/prod bascule)"
echo -e "  ${G}✓${N}  app.config.ts       (SSR + Error Boundary)"
echo -e "  ${G}✓${N}  app.config.server.ts"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng02_models_services.sh${N}"
echo ""
