import { RenderMode, ServerRoute } from '@angular/ssr';

/**
 * Configuration SSR des routes.
 * • CLIENT : rendu côté client uniquement (pages protégées, états dynamiques)
 * • SERVER : rendu côté serveur (SEO — pages publiques)
 * • PRERENDER : pré-rendu au build
 */
export const serverRoutes: ServerRoute[] = [
  // Pages publiques — rendu serveur pour le SEO
  { path: '',               renderMode: RenderMode.Prerender },
  { path: 'catalogue',      renderMode: RenderMode.Server },
  { path: 'cours/:slug',    renderMode: RenderMode.Server },
  { path: 'politique-confidentialite', renderMode: RenderMode.Prerender },
  { path: 'certificat/verifier/:code', renderMode: RenderMode.Server },

  // Pages auth — côté client uniquement
  { path: 'auth/**',        renderMode: RenderMode.Client },

  // Espaces connectés — côté client uniquement
  { path: 'app/**',         renderMode: RenderMode.Client },
  { path: 'instructor/**',  renderMode: RenderMode.Client },
  { path: 'admin/**',       renderMode: RenderMode.Client },

  // Fallback
  { path: '**',             renderMode: RenderMode.Client },
];
