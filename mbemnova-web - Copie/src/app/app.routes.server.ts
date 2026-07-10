import { RenderMode, ServerRoute } from '@angular/ssr';

/**
 * Configuration SSR des routes.
 * • Client : rendu côté client uniquement (pages protégées, états dynamiques)
 * • Server : rendu côté serveur (SEO — pages publiques)
 * • Prerender : pré-rendu au build
 */
export const serverRoutes: ServerRoute[] = [
  // Pages publiques — rendu serveur pour le SEO
  { path: '',                           renderMode: RenderMode.Prerender },
  { path: 'catalogue',                  renderMode: RenderMode.Server },
  { path: 'cours/:slug',                renderMode: RenderMode.Server },
  { path: 'politique-confidentialite',  renderMode: RenderMode.Prerender },
  { path: 'certificat/verifier/:code',   renderMode: RenderMode.Server },

  // Pages d'authentification
  { path: 'auth',                       renderMode: RenderMode.Client },
  { path: 'auth/connexion',             renderMode: RenderMode.Client },
  { path: 'auth/inscription',           renderMode: RenderMode.Client },
  { path: 'auth/mot-de-passe-oublie',   renderMode: RenderMode.Client },
  { path: 'auth/nouveau-mot-de-passe',  renderMode: RenderMode.Client },

  // Redirections d'espace
  { path: 'apprenant/dashboard',        renderMode: RenderMode.Client },
  { path: 'formateur/dashboard',        renderMode: RenderMode.Client },
  { path: 'admin/dashboard',            renderMode: RenderMode.Client },

  // Espaces connectés — côté client uniquement (désactive le pré-rendu statique)
  { path: 'app',                        renderMode: RenderMode.Client },
  { path: 'app/cours/:slug',            renderMode: RenderMode.Client },
  { path: 'app/paiements',              renderMode: RenderMode.Client },
  { path: 'app/sessions',               renderMode: RenderMode.Client },
  { path: 'app/devoirs',                renderMode: RenderMode.Client },
  { path: 'app/communaute/:coursId',    renderMode: RenderMode.Client },
  { path: 'app/certificats',            renderMode: RenderMode.Client },
  { path: 'app/profil',                 renderMode: RenderMode.Client },
  { path: 'app/parrainage',             renderMode: RenderMode.Client },
  { path: 'app/tirage',                 renderMode: RenderMode.Client },
  { path: 'app/notifications',          renderMode: RenderMode.Client },
  { path: 'app/classement',             renderMode: RenderMode.Client },

  // Espace formateur
  { path: 'instructor',                 renderMode: RenderMode.Client },
  { path: 'instructor/cours/nouveau',   renderMode: RenderMode.Client },
  { path: 'instructor/cours/:id/editer', renderMode: RenderMode.Client },
  { path: 'instructor/cours/:id/modules', renderMode: RenderMode.Client },
  { path: 'instructor/cours/:id/lecons/:lessonId/contenu', renderMode: RenderMode.Client },
  { path: 'instructor/sessions',        renderMode: RenderMode.Client },
  { path: 'instructor/correction',      renderMode: RenderMode.Client },

  // Espace admin
  { path: 'admin',                      renderMode: RenderMode.Client },
  { path: 'admin/apprenants',           renderMode: RenderMode.Client },
  { path: 'admin/paiements',            renderMode: RenderMode.Client },
  { path: 'admin/roles',                renderMode: RenderMode.Client },
  { path: 'admin/tirage',               renderMode: RenderMode.Client },

  // Fallback
  { path: '**',                         renderMode: RenderMode.Client },
];
