import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/**
 * Vérifie que l'utilisateur a un des rôles requis.
 * Usage dans les routes : data: { roles: ['ADMIN', 'SUPER_ADMIN'] }
 */
export const roleGuard: CanActivateFn = (route) => {
  const auth   = inject(AuthService);
  const router = inject(Router);

  const required: string[] = route.data['roles'] ?? [];
  const role = auth.userRole();

  if (role && required.includes(role)) return true;

  // Redirige vers le dashboard selon le rôle courant
  auth.redirectToDashboard();
  return false;
};
