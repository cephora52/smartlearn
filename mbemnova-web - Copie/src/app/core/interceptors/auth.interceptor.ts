import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { TokenService } from '../services/token.service';
import { AuthService }  from '../services/auth.service';

// Évite les boucles de refresh concurrent
let isRefreshing = false;

const NO_AUTH = ['/auth/login', '/auth/register', '/auth/refresh',
                 '/auth/reset-password', '/auth/new-password'];

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(TokenService);
  const auth  = inject(AuthService);

  const skip = NO_AUTH.some(p => req.url.includes(p));
  const tk   = token.get();

  // Ajouter le Bearer token si présent
  const authReq = (tk && !skip)
    ? req.clone({ setHeaders: { Authorization: `Bearer ${tk}` } })
    : req;

  return next(authReq).pipe(
    catchError(err => {
      if (err.status === 401 && !skip && !isRefreshing) {
        isRefreshing = true;
        return auth.refreshToken().pipe(
          switchMap(() => {
            isRefreshing = false;
            const newTk  = token.get();
            const retry  = newTk
              ? req.clone({ setHeaders: { Authorization: `Bearer ${newTk}` } })
              : req;
            return next(retry);
          }),
          catchError(e => { isRefreshing = false; return throwError(() => e); }),
        );
      }
      return throwError(() => err);
    }),
  );
};
