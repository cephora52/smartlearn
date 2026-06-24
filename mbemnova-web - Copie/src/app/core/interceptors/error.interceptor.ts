import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { ToastService } from '../services/toast.service';

/** Messages par code HTTP (conformes aux réponses Spring Boot ErrorResponse) */
const HTTP_MESSAGES: Record<number, string> = {
  400: 'Données invalides. Vérifiez votre saisie.',
  403: 'Vous n\'avez pas les droits pour cette action.',
  404: 'Ressource introuvable.',
  409: 'Conflit : cette ressource existe déjà.',
  422: 'Données non traitables.',
  429: 'Trop de requêtes. Réessayez dans quelques secondes.',
  500: 'Erreur serveur. Notre équipe a été informée.',
  502: 'Serveur temporairement indisponible.',
  503: 'Service momentanément indisponible.',
};

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const toast = inject(ToastService);

  return next(req).pipe(
    catchError(err => {
      // 401 géré par auth.interceptor (refresh + redirect)
      if (err.status === 401) return throwError(() => err);

      const status: number = err.status ?? 0;
      // Préférer le message de l'API (ErrorResponse.message) si disponible
      const msg = err.error?.message || HTTP_MESSAGES[status] || 'Une erreur est survenue.';

      // Erreurs réseau (status 0 = timeout, connexion refusée)
      if (status === 0) {
        toast.error('Connexion impossible', 'Vérifiez votre connexion internet et réessayez.');
      } else {
        toast.error(msg);
      }

      return throwError(() => err);
    }),
  );
};
