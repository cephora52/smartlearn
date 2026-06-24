#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 03/16 · App Shell
# ============================================================
# Contenu :
#   src/app/app.ts              → composant racine SSR-safe
#   src/app/app.html            → navbar + toasts + footer
#   src/app/app.routes.ts       → toutes les routes lazy (28 scénarios)
#   src/app/layouts/            → public-layout / app-layout / admin-layout
#   src/app/features/public/not-found/
#
# Règles :
#   ✓ Tailwind uniquement (0 CSS custom)
#   ✓ SSR-safe (isPlatformBrowser pour window)
#   ✓ OnPush partout
#   ✓ Signals pour l'état
#   ✓ SVG inline (pas d'icônes classiques)
#   ✓ Responsive xs (100px) → 2xl
# ============================================================
set -euo pipefail

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "\033[0;31m  ✗\033[0m $1" >&2; exit 1; }

[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet"

mkdir -p \
  src/app/layouts \
  src/app/features/public/not-found \
  src/app/features/public/landing \
  src/app/features/public/catalog \
  src/app/features/public/course-detail \
  src/app/features/public/certificate-verify \
  src/app/features/public/privacy-policy \
  src/app/features/auth/login \
  src/app/features/auth/register \
  src/app/features/auth/forgot-password \
  src/app/features/auth/reset-password \
  src/app/features/learner/dashboard \
  src/app/features/learner/course-player \
  src/app/features/learner/payment \
  src/app/features/learner/sessions \
  src/app/features/learner/assignments \
  src/app/features/learner/community \
  src/app/features/learner/certificate \
  src/app/features/learner/profile \
  src/app/features/learner/referral \
  src/app/features/learner/draw \
  src/app/features/learner/notifications \
  src/app/features/learner/leaderboard \
  src/app/features/instructor/dashboard \
  src/app/features/instructor/course-editor \
  src/app/features/instructor/session-manager \
  src/app/features/instructor/grading \
  src/app/features/admin/dashboard \
  src/app/features/admin/learner-manager \
  src/app/features/admin/payment-manager \
  src/app/features/admin/role-manager \
  src/app/features/admin/draw-manager

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 03 · App Shell               ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. APP.ROUTES.TS — Lazy loading complet (28 scénarios)
# ============================================================
sec "1/5 — app.routes.ts"

cat > src/app/app.routes.ts << 'EOF'
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';
import { guestGuard } from './core/guards/guest.guard';

export const routes: Routes = [

  // ── PAGES PUBLIQUES ───────────────────────────────────────
  // S01 · Landing
  {
    path: '',
    loadComponent: () =>
      import('./features/public/landing/landing.component')
        .then(m => m.LandingComponent),
    title: 'MbemNova — Formation Tech Afrique Centrale',
  },
  // S04 · Catalogue
  {
    path: 'catalogue',
    loadComponent: () =>
      import('./features/public/catalog/catalog.component')
        .then(m => m.CatalogComponent),
    title: 'Catalogue des formations — MbemNova',
  },
  // S04 · Détail cours
  {
    path: 'cours/:slug',
    loadComponent: () =>
      import('./features/public/course-detail/course-detail.component')
        .then(m => m.CourseDetailComponent),
  },
  // Vérification certificat (URL publique)
  {
    path: 'certificat/verifier/:code',
    loadComponent: () =>
      import('./features/public/certificate-verify/certificate-verify.component')
        .then(m => m.CertificateVerifyComponent),
    title: 'Vérification de certificat — MbemNova',
  },
  // S28 · Politique de confidentialité
  {
    path: 'politique-confidentialite',
    loadComponent: () =>
      import('./features/public/privacy-policy/privacy-policy.component')
        .then(m => m.PrivacyPolicyComponent),
    title: 'Politique de confidentialité — MbemNova',
  },

  // ── AUTH (visiteurs non connectés uniquement) ─────────────
  {
    path: 'auth',
    canActivate: [guestGuard],
    children: [
      // S03 · Connexion
      {
        path: 'connexion',
        loadComponent: () =>
          import('./features/auth/login/login.component')
            .then(m => m.LoginComponent),
        title: 'Connexion — MbemNova',
      },
      // S02 · Inscription
      {
        path: 'inscription',
        loadComponent: () =>
          import('./features/auth/register/register.component')
            .then(m => m.RegisterComponent),
        title: 'Inscription gratuite — MbemNova',
      },
      // S27 · Mot de passe oublié
      {
        path: 'mot-de-passe-oublie',
        loadComponent: () =>
          import('./features/auth/forgot-password/forgot-password.component')
            .then(m => m.ForgotPasswordComponent),
        title: 'Mot de passe oublié — MbemNova',
      },
      // S27 · Nouveau mot de passe
      {
        path: 'nouveau-mot-de-passe',
        loadComponent: () =>
          import('./features/auth/reset-password/reset-password.component')
            .then(m => m.ResetPasswordComponent),
        title: 'Nouveau mot de passe — MbemNova',
      },
      { path: '', redirectTo: 'connexion', pathMatch: 'full' },
    ],
  },

  // ── ESPACE APPRENANT (authentifié) ───────────────────────
  {
    path: 'app',
    canActivate: [authGuard],
    children: [
      // Dashboard
      {
        path: '',
        loadComponent: () =>
          import('./features/learner/dashboard/dashboard.component')
            .then(m => m.DashboardComponent),
        title: 'Mon espace — MbemNova',
      },
      // S05 · S06 · Lecteur de cours
      {
        path: 'cours/:slug',
        loadComponent: () =>
          import('./features/learner/course-player/course-player.component')
            .then(m => m.CoursePlayerComponent),
      },
      // S07 · S08 · S16 · S17 · S18 · Paiements
      {
        path: 'paiements',
        loadComponent: () =>
          import('./features/learner/payment/payment.component')
            .then(m => m.PaymentComponent),
        title: 'Mes paiements — MbemNova',
      },
      // S09 · S10 · Sessions
      {
        path: 'sessions',
        loadComponent: () =>
          import('./features/learner/sessions/sessions.component')
            .then(m => m.SessionsComponent),
        title: 'Mes sessions — MbemNova',
      },
      // S11 · Devoirs
      {
        path: 'devoirs',
        loadComponent: () =>
          import('./features/learner/assignments/assignments.component')
            .then(m => m.AssignmentsComponent),
        title: 'Mes devoirs — MbemNova',
      },
      // S12 · Communauté (par cours)
      {
        path: 'communaute/:coursId',
        loadComponent: () =>
          import('./features/learner/community/community.component')
            .then(m => m.CommunityComponent),
        title: 'Communauté — MbemNova',
      },
      // S13 · Certificats
      {
        path: 'certificats',
        loadComponent: () =>
          import('./features/learner/certificate/certificate.component')
            .then(m => m.CertificateComponent),
        title: 'Mes certificats — MbemNova',
      },
      // S14 · Profil talent
      {
        path: 'profil',
        loadComponent: () =>
          import('./features/learner/profile/profile.component')
            .then(m => m.ProfileComponent),
        title: 'Mon profil — MbemNova',
      },
      // S15 · Parrainage
      {
        path: 'parrainage',
        loadComponent: () =>
          import('./features/learner/referral/referral.component')
            .then(m => m.ReferralComponent),
        title: 'Parrainer un ami — MbemNova',
      },
      // S24 · Tirage au sort
      {
        path: 'tirage',
        loadComponent: () =>
          import('./features/learner/draw/draw.component')
            .then(m => m.DrawComponent),
        title: 'Tirage au sort — MbemNova',
      },
      // Notifications
      {
        path: 'notifications',
        loadComponent: () =>
          import('./features/learner/notifications/notifications.component')
            .then(m => m.NotificationsComponent),
        title: 'Notifications — MbemNova',
      },
      // Classement
      {
        path: 'classement',
        loadComponent: () =>
          import('./features/learner/leaderboard/leaderboard.component')
            .then(m => m.LeaderboardComponent),
        title: 'Classement — MbemNova',
      },
    ],
  },

  // ── ESPACE FORMATEUR ──────────────────────────────────────
  {
    path: 'instructor',
    canActivate: [authGuard, roleGuard],
    data: { roles: ['FORMATEUR', 'ADMIN', 'SUPER_ADMIN'] },
    children: [
      // S19 · S20 · Dashboard formateur
      {
        path: '',
        loadComponent: () =>
          import('./features/instructor/dashboard/instructor-dashboard.component')
            .then(m => m.InstructorDashboardComponent),
        title: 'Espace formateur — MbemNova',
      },
      // S19 · Éditeur cours
      {
        path: 'cours/nouveau',
        loadComponent: () =>
          import('./features/instructor/course-editor/course-editor.component')
            .then(m => m.CourseEditorComponent),
        title: 'Créer un cours — MbemNova',
      },
      {
        path: 'cours/:id/editer',
        loadComponent: () =>
          import('./features/instructor/course-editor/course-editor.component')
            .then(m => m.CourseEditorComponent),
      },
      // S20 · Gestion sessions
      {
        path: 'sessions',
        loadComponent: () =>
          import('./features/instructor/session-manager/session-manager.component')
            .then(m => m.SessionManagerComponent),
        title: 'Mes sessions — MbemNova',
      },
      // S23 · Correction devoirs
      {
        path: 'correction',
        loadComponent: () =>
          import('./features/instructor/grading/grading.component')
            .then(m => m.GradingComponent),
        title: 'Correction — MbemNova',
      },
    ],
  },

  // ── BACK-OFFICE ADMIN ────────────────────────────────────
  {
    path: 'admin',
    canActivate: [authGuard, roleGuard],
    data: { roles: ['ADMIN', 'SUPER_ADMIN'] },
    children: [
      // S25 · Dashboard
      {
        path: '',
        loadComponent: () =>
          import('./features/admin/dashboard/admin-dashboard.component')
            .then(m => m.AdminDashboardComponent),
        title: 'Back-office — MbemNova',
      },
      // S21 · Gestion apprenants
      {
        path: 'apprenants',
        loadComponent: () =>
          import('./features/admin/learner-manager/learner-manager.component')
            .then(m => m.LearnerManagerComponent),
        title: 'Gestion apprenants — MbemNova',
      },
      // S08 · S18 · Gestion paiements
      {
        path: 'paiements',
        loadComponent: () =>
          import('./features/admin/payment-manager/payment-manager.component')
            .then(m => m.PaymentManagerComponent),
        title: 'Gestion paiements — MbemNova',
      },
      // S26 · Gestion rôles
      {
        path: 'roles',
        loadComponent: () =>
          import('./features/admin/role-manager/role-manager.component')
            .then(m => m.RoleManagerComponent),
        title: 'Gestion des rôles — MbemNova',
      },
      // S24 · Tirage admin
      {
        path: 'tirage',
        loadComponent: () =>
          import('./features/admin/draw-manager/draw-manager.component')
            .then(m => m.DrawManagerComponent),
        title: 'Tirage au sort — MbemNova',
      },
    ],
  },

  // ── 404 ──────────────────────────────────────────────────
  {
    path: '**',
    loadComponent: () =>
      import('./features/public/not-found/not-found.component')
        .then(m => m.NotFoundComponent),
    title: 'Page introuvable — MbemNova',
  },
];
EOF
ok "app.routes.ts"

# ============================================================
# 2. APP.TS — Composant racine SSR-safe
# ============================================================
sec "2/5 — app.ts"

cat > src/app/app.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  computed, signal, OnInit, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive, Router } from '@angular/router';
import { AuthService }  from './core/services/auth.service';
import { ToastService, Toast } from './core/services/toast.service';
import { ApiService }   from './core/services/api.service';
import { NotificationService } from './core/services/notification.service';

@Component({
  selector: 'app-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrl:    './app.css',
})
export class App implements OnInit {
  readonly auth     = inject(AuthService);
  readonly toastSvc = inject(ToastService);
  readonly api      = inject(ApiService);
  readonly notifSvc = inject(NotificationService);
  readonly router   = inject(Router);
  readonly #plat    = inject(PLATFORM_ID);

  // ── Signals réactifs ──────────────────────────────────
  readonly isAuth    = this.auth.isAuthenticated;
  readonly user      = this.auth.currentUser;
  readonly role      = this.auth.userRole;
  readonly isAdmin   = this.auth.isAdmin;
  readonly loading   = this.api.loading;
  readonly toasts    = this.toastSvc.toasts;
  readonly unread    = this.notifSvc.unreadCount;
  readonly hasUnread = this.notifSvc.hasUnread;

  readonly menuOpen  = signal(false);
  readonly userMenuOpen = signal(false);

  // Navigation contextuelle selon le rôle
  readonly navLinks = computed(() => {
    const r = this.role();
    if (!r) return [];
    const maps: Record<string, { label: string; href: string; icon: string }[]> = {
      APPRENANT: [
        { label: 'Mon espace',   href: '/app',             icon: 'home' },
        { label: 'Classement',   href: '/app/classement',  icon: 'trophy' },
        { label: 'Parrainage',   href: '/app/parrainage',  icon: 'gift' },
        { label: 'Tirage',       href: '/app/tirage',      icon: 'star' },
      ],
      FORMATEUR: [
        { label: 'Dashboard',    href: '/instructor',          icon: 'home' },
        { label: 'Mes cours',    href: '/instructor/cours/nouveau', icon: 'book' },
        { label: 'Sessions',     href: '/instructor/sessions', icon: 'calendar' },
        { label: 'Correction',   href: '/instructor/correction', icon: 'check' },
      ],
      ADMIN: [
        { label: 'Dashboard',    href: '/admin',             icon: 'home' },
        { label: 'Apprenants',   href: '/admin/apprenants',  icon: 'users' },
        { label: 'Paiements',    href: '/admin/paiements',   icon: 'credit' },
        { label: 'Rôles',        href: '/admin/roles',       icon: 'shield' },
        { label: 'Tirage',       href: '/admin/tirage',      icon: 'star' },
      ],
      SUPER_ADMIN: [
        { label: 'Dashboard',    href: '/admin',             icon: 'home' },
        { label: 'Apprenants',   href: '/admin/apprenants',  icon: 'users' },
        { label: 'Paiements',    href: '/admin/paiements',   icon: 'credit' },
        { label: 'Rôles',        href: '/admin/roles',       icon: 'shield' },
        { label: 'Tirage',       href: '/admin/tirage',      icon: 'star' },
      ],
    };
    return maps[r] ?? [];
  });

  ngOnInit(): void {
    // Écouter les erreurs globales depuis GlobalErrorHandler
    if (isPlatformBrowser(this.#plat)) {
      window.addEventListener('mn:error', (e: Event) => {
        const detail = (e as CustomEvent<{ message: string }>).detail;
        this.toastSvc.error(detail.message);
      });
    }
  }

  logout(): void {
    this.menuOpen.set(false);
    this.userMenuOpen.set(false);
    this.auth.logout();
  }

  closeMenu():    void { this.menuOpen.set(false); }
  toggleMenu():   void { this.menuOpen.update(v => !v); }
  closeUserMenu():void { this.userMenuOpen.set(false); }
  toggleUserMenu():void{ this.userMenuOpen.update(v => !v); }

  // Icône SVG par clé (inline — zéro dépendance)
  icon(key: string): string {
    const icons: Record<string, string> = {
      home:    '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>',
      trophy:  '<polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-1a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2h-2"/><rect x="6" y="18" width="12" height="4" rx="1"/>',
      gift:    '<polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/>',
      star:    '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>',
      book:    '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>',
      calendar:'<rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>',
      check:   '<polyline points="20 6 9 17 4 12"/>',
      users:   '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
      credit:  '<rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>',
      shield:  '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
      bell:    '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>',
      logout:  '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>',
      user:    '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
      menu:    '<line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>',
      close:   '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
    };
    return `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[key] ?? ''}</svg>`;
  }

  // Styles des toasts
  toastBg(type: Toast['type']): string {
    return {
      success: 'bg-green-50 border-green-200',
      error:   'bg-red-50 border-red-200',
      warning: 'bg-amber-50 border-amber-200',
      info:    'bg-blue-50 border-blue-200',
    }[type];
  }
  toastIcon(type: Toast['type']): string {
    return {
      success: '✓', error: '✕', warning: '⚠', info: 'ℹ',
    }[type];
  }
  toastIconBg(type: Toast['type']): string {
    return {
      success: 'bg-green-100 text-green-700',
      error:   'bg-red-100 text-red-700',
      warning: 'bg-amber-100 text-amber-700',
      info:    'bg-blue-100 text-blue-700',
    }[type];
  }
  toastText(type: Toast['type']): string {
    return {
      success: 'text-green-900',
      error:   'text-red-900',
      warning: 'text-amber-900',
      info:    'text-blue-900',
    }[type];
  }
}
EOF
ok "app.ts"

# ============================================================
# 3. APP.HTML — Navbar + Footer + Toasts
# ============================================================
sec "3/5 — app.html"

cat > src/app/app.html << 'HTMLEOF'
<!-- ========================================================
     MbemNova · App Shell
     Navbar adaptive (rôle) + Router outlet + Toasts + Footer
     SSR-safe — Tailwind uniquement
     ======================================================== -->

<!-- Barre de progression loading (top) -->
@if (loading()) {
  <div class="fixed top-0 left-0 right-0 z-[500] h-0.5 overflow-hidden bg-blue-100" role="progressbar" aria-label="Chargement">
    <div class="h-full bg-blue-600" style="animation: loadingBar 1.5s ease-in-out infinite;"></div>
  </div>
}

<!-- ── NAVBAR ─────────────────────────────────────────────── -->
<header class="sticky top-0 z-40 bg-white border-b border-slate-100">
  <nav class="container flex items-center h-16 gap-2" aria-label="Navigation principale">

    <!-- Logo MbemNova -->
    <a routerLink="/" class="flex items-center gap-2 shrink-0 group mr-3" aria-label="MbemNova — Accueil">
      <!-- SVG Logo -->
      <div class="relative transition-transform duration-200 group-hover:scale-105">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <!-- Lettre M -->
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5"
                stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <!-- Point or animé -->
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
      </div>
      <span class="font-bold text-lg text-slate-900 hidden xs:inline tracking-tight">
        Mbem<span class="text-blue-600">Nova</span>
      </span>
    </a>

    <!-- Nav desktop — connecté -->
    @if (isAuth()) {
      <div class="hidden md:flex items-center gap-1 flex-1">
        @for (link of navLinks(); track link.href) {
          <a [routerLink]="link.href"
             routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
             [routerLinkActiveOptions]="{ exact: link.href.endsWith('app') || link.href === '/admin' || link.href === '/instructor' }"
             class="flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm text-slate-600
                    hover:bg-slate-50 hover:text-slate-900 transition-colors duration-150">
            {{ link.label }}
          </a>
        }
      </div>
    }

    <!-- Nav desktop — non connecté -->
    @if (!isAuth()) {
      <div class="hidden md:flex items-center gap-1 flex-1">
        <a routerLink="/catalogue"
           routerLinkActive="bg-blue-50 text-blue-700"
           class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50 hover:text-slate-900 transition-colors">
          Catalogue
        </a>
      </div>
    }

    <div class="flex-1 md:flex-none"></div>

    <!-- Actions droite -->
    <div class="flex items-center gap-1.5">

      <!-- Cloche notifications (connecté) -->
      @if (isAuth()) {
        <a routerLink="/app/notifications"
           class="relative p-2 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-900
                  transition-colors duration-150"
           aria-label="Notifications">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
          </svg>
          @if (hasUnread()) {
            <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"
                  aria-label="Nouvelles notifications"></span>
          }
        </a>
      }

      <!-- Menu utilisateur (connecté) -->
      @if (isAuth()) {
        <div class="relative">
          <button (click)="toggleUserMenu()"
                  class="flex items-center gap-2 pl-2 pr-3 py-1.5 rounded-lg
                         hover:bg-slate-100 transition-colors duration-150"
                  [attr.aria-expanded]="userMenuOpen()"
                  aria-haspopup="true">
            <!-- Avatar initiale -->
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center
                        text-white text-xs font-bold shrink-0">
              {{ user()?.prenom?.charAt(0)?.toUpperCase() ?? '?' }}
            </div>
            <span class="hidden sm:block text-sm font-medium text-slate-700 max-w-24 truncate">
              {{ user()?.prenom }}
            </span>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2.5" class="text-slate-400 hidden sm:block" aria-hidden="true">
              <polyline points="6 9 12 15 18 9"/>
            </svg>
          </button>

          <!-- Dropdown menu utilisateur -->
          @if (userMenuOpen()) {
            <div class="absolute right-0 top-full mt-1.5 w-52 bg-white rounded-xl border border-slate-200
                        shadow-lg py-1.5 z-50 animate-slide-down"
                 role="menu">
              <div class="px-3 py-2 border-b border-slate-100 mb-1">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  {{ role() === 'ADMIN' || role() === 'SUPER_ADMIN' ? 'Administrateur' :
                     role() === 'FORMATEUR' ? 'Formateur' : 'Apprenant' }}
                </p>
                <p class="text-sm text-slate-900 font-medium truncate">{{ user()?.email }}</p>
              </div>

              @if (role() === 'APPRENANT') {
                <a routerLink="/app/profil" (click)="closeUserMenu()"
                   class="flex items-center gap-2.5 px-3 py-2 text-sm text-slate-700
                          hover:bg-slate-50 w-full" role="menuitem">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                  Mon profil
                </a>
                <a routerLink="/app/paiements" (click)="closeUserMenu()"
                   class="flex items-center gap-2.5 px-3 py-2 text-sm text-slate-700
                          hover:bg-slate-50 w-full" role="menuitem">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
                  Mes paiements
                </a>
              }

              <div class="border-t border-slate-100 mt-1 pt-1">
                <button (click)="logout()"
                        class="flex items-center gap-2.5 px-3 py-2 text-sm text-red-600
                               hover:bg-red-50 w-full rounded-b-xl transition-colors"
                        role="menuitem">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                  Se déconnecter
                </button>
              </div>
            </div>
          }
        </div>
      }

      <!-- Boutons non connecté -->
      @if (!isAuth()) {
        <a routerLink="/auth/connexion"
           class="hidden sm:flex btn-ghost text-sm">Connexion</a>
        <a routerLink="/auth/inscription"
           class="btn-primary text-sm">
          Commencer
        </a>
      }

      <!-- Burger mobile -->
      <button (click)="toggleMenu()"
              class="md:hidden p-2 rounded-lg text-slate-600 hover:bg-slate-100 transition-colors"
              [attr.aria-expanded]="menuOpen()"
              aria-label="Menu de navigation">
        @if (!menuOpen()) {
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
          </svg>
        } @else {
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        }
      </button>
    </div>
  </nav>

  <!-- Menu mobile -->
  @if (menuOpen()) {
    <div class="md:hidden border-t border-slate-100 bg-white animate-slide-down" role="navigation" aria-label="Menu mobile">
      <div class="container py-3 space-y-0.5">

        @if (isAuth()) {
          @for (link of navLinks(); track link.href) {
            <a [routerLink]="link.href" (click)="closeMenu()"
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-slate-700
                      hover:bg-slate-50 transition-colors w-full">
              {{ link.label }}
            </a>
          }
          <div class="border-t border-slate-100 pt-2 mt-2 space-y-0.5">
            <a routerLink="/app/profil" (click)="closeMenu()"
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">
              Mon profil
            </a>
            <a routerLink="/app/notifications" (click)="closeMenu()"
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">
              Notifications
              @if (hasUnread()) {
                <span class="ml-auto bg-red-500 text-white text-xs rounded-full px-1.5 py-0.5">
                  {{ unread() }}
                </span>
              }
            </a>
            <button (click)="logout()"
                    class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-red-600
                           hover:bg-red-50 transition-colors w-full text-left">
              Se déconnecter
            </button>
          </div>
        }

        @if (!isAuth()) {
          <a routerLink="/catalogue" (click)="closeMenu()"
             class="flex items-center px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">
            Catalogue
          </a>
          <a routerLink="/auth/connexion" (click)="closeMenu()"
             class="flex items-center px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">
            Connexion
          </a>
          <a routerLink="/auth/inscription" (click)="closeMenu()"
             class="btn-primary w-full mt-2 justify-center">
            Commencer gratuitement
          </a>
        }
      </div>
    </div>
  }
</header>

<!-- ── CONTENU PRINCIPAL ──────────────────────────────────── -->
<main class="min-h-[calc(100vh-64px)]">
  <router-outlet />
</main>

<!-- ── FOOTER (pages publiques uniquement) ────────────────── -->
@if (!isAuth()) {
  <footer class="bg-slate-900 text-slate-400" aria-label="Pied de page">
    <div class="container py-14">
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-10 mb-12">

        <!-- Logo + tagline -->
        <div class="sm:col-span-2 lg:col-span-1">
          <a routerLink="/" class="flex items-center gap-2 mb-4 group w-fit">
            <svg width="32" height="32" viewBox="0 0 36 36" fill="none" aria-hidden="true">
              <circle cx="18" cy="18" r="18" fill="#3b82f6"/>
              <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5"
                    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
              <circle cx="28" cy="10" r="3" fill="#f59e0b"/>
            </svg>
            <span class="font-bold text-lg text-white">Mbem<span class="text-blue-400">Nova</span></span>
          </a>
          <p class="text-sm leading-relaxed mb-4">
            La référence EdTech de l'Afrique Centrale.<br>
            Formations certifiantes, paiement en tranches.
          </p>
          <div class="text-xs space-y-1">
            <p>📍 Douala, Cameroun</p>
            <p>✉️ contact&#64;mbemnova.com</p>
          </div>
        </div>

        <!-- Formations -->
        <div>
          <h3 class="text-white font-semibold text-sm mb-4">Formations</h3>
          <ul class="space-y-2.5 text-sm">
            <li><a routerLink="/catalogue" class="hover:text-white transition-colors">Tout le catalogue</a></li>
            <li><a routerLink="/catalogue" [queryParams]="{ niveau: 'DEBUTANT' }" class="hover:text-white transition-colors">Débutants</a></li>
            <li><a routerLink="/catalogue" [queryParams]="{ niveau: 'INTERMEDIAIRE' }" class="hover:text-white transition-colors">Intermédiaires</a></li>
            <li><a routerLink="/catalogue" [queryParams]="{ niveau: 'AVANCE' }" class="hover:text-white transition-colors">Avancés</a></li>
          </ul>
        </div>

        <!-- Plateforme -->
        <div>
          <h3 class="text-white font-semibold text-sm mb-4">Plateforme</h3>
          <ul class="space-y-2.5 text-sm">
            <li><a routerLink="/auth/inscription" class="hover:text-white transition-colors">Inscription gratuite</a></li>
            <li><a routerLink="/auth/connexion" class="hover:text-white transition-colors">Connexion</a></li>
            <li><a routerLink="/certificat/verifier/demo" class="hover:text-white transition-colors">Vérifier un certificat</a></li>
          </ul>
        </div>

        <!-- Légal -->
        <div>
          <h3 class="text-white font-semibold text-sm mb-4">Légal</h3>
          <ul class="space-y-2.5 text-sm">
            <li>
              <a routerLink="/politique-confidentialite" class="hover:text-white transition-colors">
                Politique de confidentialité
              </a>
            </li>
          </ul>
        </div>
      </div>

      <div class="border-t border-slate-800 pt-6 flex flex-col sm:flex-row items-center
                  justify-between gap-3 text-xs">
        <p>© 2025 MbemNova. Tous droits réservés.</p>
        <p>Fait avec ❤️ pour la tech africaine</p>
      </div>
    </div>
  </footer>
}

<!-- ── TOASTS (fixed bottom-right) ───────────────────────── -->
<div class="fixed bottom-4 right-4 z-[400] flex flex-col gap-2 max-w-xs w-full pointer-events-none"
     role="region" aria-live="polite" aria-label="Notifications">
  @for (t of toasts(); track t.id) {
    <div [class]="'flex items-start gap-3 p-3.5 rounded-xl border shadow-lg pointer-events-auto
                  animate-slide-right ' + toastBg(t.type)"
         role="alert">
      <!-- Icône -->
      <div [class]="'w-6 h-6 rounded-full flex items-center justify-center shrink-0
                    text-xs font-bold ' + toastIconBg(t.type)"
           aria-hidden="true">
        {{ toastIcon(t.type) }}
      </div>
      <!-- Texte -->
      <div class="flex-1 min-w-0">
        <p [class]="'text-sm font-semibold leading-tight ' + toastText(t.type)">{{ t.title }}</p>
        @if (t.message) {
          <p [class]="'text-xs mt-0.5 opacity-80 ' + toastText(t.type)">{{ t.message }}</p>
        }
      </div>
      <!-- Fermer -->
      <button (click)="toastSvc.dismiss(t.id)"
              [attr.aria-label]="'Fermer : ' + t.title"
              class="opacity-50 hover:opacity-100 transition-opacity shrink-0 p-0.5">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2.5" aria-hidden="true">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      </button>
    </div>
  }
</div>

<!-- Backdrop pour fermer les menus au clic extérieur -->
@if (menuOpen() || userMenuOpen()) {
  <div class="fixed inset-0 z-30" (click)="closeMenu(); closeUserMenu()" aria-hidden="true"></div>
}
HTMLEOF
ok "app.html"

# ============================================================
# 4. APP.CSS — barre loading uniquement (keyframe impossible Tailwind)
# ============================================================
cat > src/app/app.css << 'EOF'
/* Barre de progression loading — keyframe impossible en Tailwind */
@keyframes loadingBar {
  0%   { transform: translateX(-100%) scaleX(0.3); }
  40%  { transform: translateX(-10%)  scaleX(0.7); }
  100% { transform: translateX(100%)  scaleX(0.3); }
}
EOF
ok "app.css"

# ============================================================
# 5. LAYOUTS (public / app / admin)
# ============================================================
sec "4/5 — Layouts"

# ── Public Layout ─────────────────────────────────────────
cat > src/app/layouts/public-layout.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

/** Layout pour les pages publiques (navbar + footer dans app.ts) */
@Component({
  selector: 'app-public-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet],
  template: `<router-outlet />`,
})
export class PublicLayoutComponent {}
EOF

# ── App Layout (apprenant + formateur) ───────────────────
cat > src/app/layouts/app-layout.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component, inject, computed } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../core/services/auth.service';

@Component({
  selector: 'app-app-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
<div class="flex min-h-[calc(100vh-64px)]">

  <!-- Sidebar desktop -->
  <aside class="hidden lg:flex flex-col w-56 xl:w-60 shrink-0 border-r border-slate-100 bg-white sticky top-16 h-[calc(100vh-64px)]">
    <nav class="flex-1 p-3 space-y-0.5 overflow-y-auto" aria-label="Navigation apprenant">

      @if (isApprenant()) {
        <a routerLink="/app" [routerLinkActiveOptions]="{ exact: true }"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          Tableau de bord
        </a>
        <a routerLink="/app/sessions"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Mes sessions
        </a>
        <a routerLink="/app/devoirs"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          Mes devoirs
        </a>
        <a routerLink="/app/certificats"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>
          Certificats
        </a>
        <a routerLink="/app/classement"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-1a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2h-2"/><rect x="6" y="18" width="12" height="4" rx="1"/></svg>
          Classement
        </a>
        <a routerLink="/app/paiements"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
          Paiements
        </a>
        <a routerLink="/app/parrainage"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>
          Parrainage
        </a>
        <a routerLink="/app/tirage"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          Tirage au sort
        </a>
      }

      @if (isFormateur()) {
        <a routerLink="/instructor" [routerLinkActiveOptions]="{ exact: true }"
           routerLinkActive="bg-purple-50 text-purple-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
          Dashboard
        </a>
        <a routerLink="/instructor/sessions"
           routerLinkActive="bg-purple-50 text-purple-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Sessions
        </a>
        <a routerLink="/instructor/correction"
           routerLinkActive="bg-purple-50 text-purple-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
          Correction
        </a>
      }
    </nav>

    <!-- Profil sidebar -->
    <div class="border-t border-slate-100 p-3">
      <a routerLink="/app/profil"
         class="flex items-center gap-2.5 p-2 rounded-lg hover:bg-slate-50 transition-colors">
        <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center
                    text-white text-xs font-bold shrink-0">
          {{ initial() }}
        </div>
        <div class="min-w-0">
          <p class="text-sm font-medium text-slate-900 truncate">{{ prenom() }}</p>
          <p class="text-xs text-slate-400 truncate">Mon profil</p>
        </div>
      </a>
    </div>
  </aside>

  <!-- Contenu -->
  <main class="flex-1 min-w-0">
    <router-outlet />
  </main>
</div>
  `,
  styles: [`
    .sidebar-link {
      @apply flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm text-slate-600
             hover:bg-slate-50 hover:text-slate-900 transition-colors duration-150 w-full;
    }
  `],
})
export class AppLayoutComponent {
  readonly #auth   = inject(AuthService);
  readonly isApprenant = computed(() => this.#auth.userRole() === 'APPRENANT');
  readonly isFormateur = computed(() => this.#auth.userRole() === 'FORMATEUR');
  readonly prenom      = computed(() => this.#auth.currentUser()?.prenom ?? '');
  readonly initial     = computed(() => this.prenom().charAt(0).toUpperCase());
}
EOF

# ── Admin Layout ──────────────────────────────────────────
cat > src/app/layouts/admin-layout.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-admin-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
<div class="flex min-h-[calc(100vh-64px)]">

  <!-- Sidebar admin -->
  <aside class="hidden lg:flex flex-col w-56 xl:w-60 shrink-0 border-r border-slate-100 bg-slate-900 sticky top-16 h-[calc(100vh-64px)]">
    <nav class="flex-1 p-3 space-y-0.5 overflow-y-auto" aria-label="Navigation admin">

      <a routerLink="/admin" [routerLinkActiveOptions]="{ exact: true }"
         routerLinkActive="bg-blue-600 text-white"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
        Dashboard
      </a>
      <a routerLink="/admin/apprenants"
         routerLinkActive="bg-blue-600 text-white"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        Apprenants
      </a>
      <a routerLink="/admin/paiements"
         routerLinkActive="bg-blue-600 text-white"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        Paiements
      </a>
      <a routerLink="/admin/roles"
         routerLinkActive="bg-blue-600 text-white"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        Rôles
      </a>
      <a routerLink="/admin/tirage"
         routerLinkActive="bg-blue-600 text-white"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
        Tirage au sort
      </a>
    </nav>

    <div class="border-t border-slate-800 p-3">
      <p class="text-xs text-slate-500 px-2">Back-office MbemNova</p>
    </div>
  </aside>

  <main class="flex-1 min-w-0 bg-slate-50">
    <router-outlet />
  </main>
</div>
  `,
  styles: [`
    .admin-link {
      @apply flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm text-slate-400
             hover:bg-slate-800 hover:text-white transition-colors duration-150 w-full;
    }
  `],
})
export class AdminLayoutComponent {}
EOF
ok "Layouts : public · app · admin"

# ============================================================
# 5. PAGE 404 + PLACEHOLDERS pour routes non encore codées
# ============================================================
sec "5/5 — Page 404 + placeholders"

cat > src/app/features/public/not-found/not-found.component.ts << 'EOF'
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-white flex items-center justify-center px-4">
  <div class="text-center max-w-md animate-fade-up">

    <!-- Illustration SVG 404 -->
    <div class="mb-8 flex justify-center">
      <svg width="200" height="160" viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <!-- Fond cercle -->
        <circle cx="100" cy="80" r="70" fill="#eff6ff" opacity="0.8"/>
        <!-- Chiffres 404 -->
        <text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle"
              font-family="DM Sans, system-ui" font-size="52" font-weight="800"
              fill="#1e40af" opacity="0.15">404</text>
        <!-- Personnage perdu -->
        <circle cx="100" cy="68" r="18" fill="#2563eb" opacity="0.9"/>
        <circle cx="93" cy="64" r="3" fill="white"/>
        <circle cx="107" cy="64" r="3" fill="white"/>
        <!-- Bouche -->
        <path d="M93 73 Q100 70 107 73" stroke="white" stroke-width="2" stroke-linecap="round" fill="none"/>
        <!-- Point d'interrogation -->
        <text x="125" y="58" font-size="28" fill="#f59e0b" font-weight="800" font-family="DM Sans">?</text>
        <!-- Corps -->
        <rect x="88" y="88" width="24" height="28" rx="6" fill="#2563eb" opacity="0.8"/>
        <!-- Jambes -->
        <rect x="90" y="114" width="8" height="18" rx="4" fill="#1e40af"/>
        <rect x="102" y="114" width="8" height="18" rx="4" fill="#1e40af"/>
        <!-- Bras levés (perdu) -->
        <path d="M88 96 L72 82" stroke="#2563eb" stroke-width="6" stroke-linecap="round"/>
        <path d="M112 96 L128 82" stroke="#2563eb" stroke-width="6" stroke-linecap="round"/>
        <!-- Étoiles autour -->
        <circle cx="60" cy="45" r="3" fill="#f59e0b"/>
        <circle cx="140" cy="45" r="2" fill="#f59e0b"/>
        <circle cx="55" cy="100" r="2" fill="#93c5fd"/>
        <circle cx="148" cy="95" r="3" fill="#93c5fd"/>
      </svg>
    </div>

    <h1 class="text-6xl font-black text-slate-100 mb-2 leading-none" style="font-family:var(--font);">404</h1>
    <h2 class="text-2xl font-bold text-slate-900 mb-3">Page introuvable</h2>
    <p class="text-slate-500 mb-8 leading-relaxed">
      La page que vous cherchez n'existe pas ou a été déplacée.
      Pas de panique — retournons sur quelque chose de connu !
    </p>

    <div class="flex flex-col xs:flex-row gap-3 justify-center">
      <a routerLink="/" class="btn-primary btn-lg">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        Accueil
      </a>
      <a routerLink="/catalogue" class="btn-secondary btn-lg">Voir le catalogue</a>
    </div>
  </div>
</div>
  `,
})
export class NotFoundComponent {}
EOF
ok "not-found.component.ts"

# Placeholders pour toutes les features (seront remplacés dans les scripts 04–16)
make_placeholder() {
  local file="$1" sel="$2" title="$3" emoji="$4"
  [[ -f "$file" ]] && return  # Ne pas écraser si déjà créé
  mkdir -p "$(dirname "$file")"
  local name
  name=$(basename "$file" .ts | sed -E 's/[-.]([a-z])/\U\1/g; s/^([a-z])/\U\1/')
  cat > "$file" << PLEOF
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

/** Placeholder — sera remplacé dans le script correspondant */
@Component({
  selector: '${sel}',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: \`
<div class="container py-16 text-center">
  <div class="text-5xl mb-4">${emoji}</div>
  <h1 class="h2 mb-2">${title}</h1>
  <p class="text-slate-500 mb-6">Cette page est en cours de développement.</p>
  <a routerLink="/" class="btn-secondary">Retour à l'accueil</a>
</div>\`
})
export class ${name} {}
PLEOF
}

# Auth
make_placeholder "src/app/features/auth/login/login.component.ts"                     "app-login"           "Connexion"              "🔐"
make_placeholder "src/app/features/auth/register/register.component.ts"               "app-register"        "Inscription"            "✨"
make_placeholder "src/app/features/auth/forgot-password/forgot-password.component.ts" "app-forgot"          "Mot de passe oublié"    "🔑"
make_placeholder "src/app/features/auth/reset-password/reset-password.component.ts"   "app-reset"           "Nouveau mot de passe"   "🔒"

# Public
make_placeholder "src/app/features/public/landing/landing.component.ts"                       "app-landing"         "Accueil"             "🏠"
make_placeholder "src/app/features/public/catalog/catalog.component.ts"                        "app-catalog"         "Catalogue"           "📚"
make_placeholder "src/app/features/public/course-detail/course-detail.component.ts"            "app-course-detail"   "Détail cours"        "📖"
make_placeholder "src/app/features/public/certificate-verify/certificate-verify.component.ts"  "app-cert-verify"     "Vérifier certificat" "🏆"
make_placeholder "src/app/features/public/privacy-policy/privacy-policy.component.ts"          "app-privacy"         "Confidentialité"     "🔒"

# Learner
make_placeholder "src/app/features/learner/dashboard/dashboard.component.ts"             "app-dashboard"       "Mon espace"          "🏠"
make_placeholder "src/app/features/learner/course-player/course-player.component.ts"     "app-course-player"   "Lecteur cours"       "▶️"
make_placeholder "src/app/features/learner/payment/payment.component.ts"                 "app-payment"         "Paiements"           "💳"
make_placeholder "src/app/features/learner/sessions/sessions.component.ts"               "app-sessions"        "Sessions"            "📅"
make_placeholder "src/app/features/learner/assignments/assignments.component.ts"         "app-assignments"     "Devoirs"             "📝"
make_placeholder "src/app/features/learner/community/community.component.ts"             "app-community"       "Communauté"          "💬"
make_placeholder "src/app/features/learner/certificate/certificate.component.ts"         "app-certificate"     "Certificats"         "🏆"
make_placeholder "src/app/features/learner/profile/profile.component.ts"                 "app-profile"         "Mon profil"          "👤"
make_placeholder "src/app/features/learner/referral/referral.component.ts"               "app-referral"        "Parrainage"          "🤝"
make_placeholder "src/app/features/learner/draw/draw.component.ts"                       "app-draw"            "Tirage au sort"      "🎟️"
make_placeholder "src/app/features/learner/notifications/notifications.component.ts"     "app-notifications"   "Notifications"       "🔔"
make_placeholder "src/app/features/learner/leaderboard/leaderboard.component.ts"         "app-leaderboard"     "Classement"          "🏅"

# Instructor
make_placeholder "src/app/features/instructor/dashboard/instructor-dashboard.component.ts"       "app-instructor"      "Formateur"           "🎓"
make_placeholder "src/app/features/instructor/course-editor/course-editor.component.ts"          "app-course-editor"   "Éditeur cours"       "✏️"
make_placeholder "src/app/features/instructor/session-manager/session-manager.component.ts"      "app-session-mgr"     "Sessions"            "📅"
make_placeholder "src/app/features/instructor/grading/grading.component.ts"                      "app-grading"         "Correction"          "✅"

# Admin
make_placeholder "src/app/features/admin/dashboard/admin-dashboard.component.ts"             "app-admin"           "Back-office"         "⚙️"
make_placeholder "src/app/features/admin/learner-manager/learner-manager.component.ts"       "app-learner-mgr"     "Apprenants"          "👥"
make_placeholder "src/app/features/admin/payment-manager/payment-manager.component.ts"       "app-payment-mgr"     "Paiements"           "💰"
make_placeholder "src/app/features/admin/role-manager/role-manager.component.ts"             "app-role-mgr"        "Rôles"               "🛡️"
make_placeholder "src/app/features/admin/draw-manager/draw-manager.component.ts"             "app-draw-mgr"        "Tirage"              "🎯"

ok "Placeholders créés (seront remplacés scripts 04–16)"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 03 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  app.routes.ts         (28 scénarios couverts)"
echo -e "  ${G}✓${N}  app.ts                (signals + nav adaptative)"
echo -e "  ${G}✓${N}  app.html              (navbar + footer + toasts)"
echo -e "  ${G}✓${N}  layouts/              (public · app · admin)"
echo -e "  ${G}✓${N}  not-found.component   (404 illustré)"
echo -e "  ${G}✓${N}  Placeholders          (33 composants)"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng04_auth_pages.sh${N}"
echo ""
