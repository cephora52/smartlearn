import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig).catch((err) => {
  // Erreur bootstrap silencieuse - évite crash navigateur
  if (typeof window !== 'undefined') {
    window.dispatchEvent(
      new CustomEvent('mn:error', {
        detail: { message: 'Échec chargement application.' },
      }),
    );
  }
});
