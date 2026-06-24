import { inject } from '@angular/core';
import { CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

/** Empêche les utilisateurs connectés d'accéder aux pages auth. */
export const guestGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  if (!auth.isAuthenticated()) return true;
  auth.redirectToDashboard();
  return false;
};
