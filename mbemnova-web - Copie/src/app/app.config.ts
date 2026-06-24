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
      console.warn('[MbemNova] Nouvelle version détectée. Rechargement...'); // TODO: Logger service en prod
      setTimeout(() => window.location.reload(), 1000);
      return;
    }
    console.error('[MbemNova]', err?.message ?? error); // TODO: Logger service en prod
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
