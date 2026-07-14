import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';
import { guestGuard } from './core/guards/guest.guard';

export const routes: Routes = [
  { path: 'apprenant/dashboard', redirectTo: 'app', pathMatch: 'full' },
  { path: 'formateur/dashboard', redirectTo: 'instructor', pathMatch: 'full' },
  { path: 'admin/dashboard', redirectTo: 'admin', pathMatch: 'full' },

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
          import('./features/instructor/course-builder/course-setup.component')
            .then(m => m.CourseSetupComponent),
        title: 'Créer un cours — MbemNova',
      },
      {
        path: 'cours/:id/editer',
        loadComponent: () =>
          import('./features/instructor/course-builder/course-setup.component')
            .then(m => m.CourseSetupComponent),
      },
      {
        path: 'cours/:id/modules',
        loadComponent: () =>
          import('./features/instructor/course-builder/course-modules.component')
            .then(m => m.CourseModulesComponent),
      },
      {
        path: 'cours/:id/lecons/:lessonId/contenu',
        loadComponent: () =>
          import('./features/instructor/course-builder/lesson-content-editor.component')
            .then(m => m.LessonContentEditorComponent),
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
        title: 'Correction — SmartLearn',
      },
      // Mes formations formateur
      {
        path: 'formations',
        loadComponent: () =>
          import('./features/instructor/formations/formations.component')
            .then(m => m.FormationsComponent),
        title: 'Mes formations — SmartLearn',
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
