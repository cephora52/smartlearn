import {
  Injectable, inject, signal, computed, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Router } from '@angular/router';
import { Observable, tap, catchError, throwError } from 'rxjs';
import { ApiService }   from './api.service';
import { TokenService } from './token.service';
import { ToastService } from './toast.service';
import type {
  AuthResponse, UserProfile, UserRole,
  InscriptionRequest, ConnexionRequest, ApiResponse,
} from '../models';

const DASHBOARDS: Record<UserRole, string> = {
  APPRENANT:   '/app',
  FORMATEUR:   '/instructor',
  ADMIN:       '/admin',
  SUPER_ADMIN: '/admin',
};

/**
 * AuthService — gestion complète de l'authentification.
 *
 * État via signals Angular :
 *   currentUser     → profil ou null
 *   isAuthenticated → computed
 *   userRole        → computed
 *   isAdmin         → computed
 *
 * Persistance : sessionStorage (pas localStorage — sécurité XSS).
 * Disparaît à la fermeture du navigateur.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  readonly #api    = inject(ApiService);
  readonly #token  = inject(TokenService);
  readonly #router = inject(Router);
  readonly #toast  = inject(ToastService);
  readonly #plat   = inject(PLATFORM_ID);

  readonly currentUser     = signal<UserProfile | null>(this.#restore());
  readonly isAuthenticated = computed(() => this.currentUser() !== null);
  readonly userRole        = computed<UserRole | null>(() => this.currentUser()?.role ?? null);
  readonly isAdmin         = computed(() =>
    this.userRole() === 'ADMIN' || this.userRole() === 'SUPER_ADMIN'
  );
  readonly isSuspended     = computed(() => this.currentUser()?.statut === 'SUSPENDU');

  constructor() {
    if (isPlatformBrowser(this.#plat) && !this.currentUser()) {
      this.#silentRefresh();
    }
  }

  // ── S02 : Inscription ─────────────────────────────────
  register(req: InscriptionRequest): Observable<ApiResponse<AuthResponse>> {
    return this.#api.post<AuthResponse>('/auth/register', req).pipe(
      tap(r => { if (r.success && r.data) this.#onSuccess(r.data); }),
    );
  }

  // ── S03 : Connexion ───────────────────────────────────
  login(req: ConnexionRequest): Observable<ApiResponse<AuthResponse>> {
    return this.#api.post<AuthResponse>('/auth/login', req).pipe(
      tap(r => { if (r.success && r.data) this.#onSuccess(r.data); }),
    );
  }

  // ── Déconnexion ───────────────────────────────────────
  logout(): void {
    this.#api.post('/auth/logout', {}).subscribe({ error: () => {} });
    this.#clear();
    this.#router.navigate(['/auth/connexion']);
  }

  // ── Refresh token (auto depuis intercepteur) ──────────
  refreshToken(): Observable<ApiResponse<{ accessToken: string }>> {
    return this.#api
      .post<{ accessToken: string }>('/auth/refresh', {})
      .pipe(
        tap(r => { if (r.success && r.data) this.#token.set(r.data.accessToken); }),
        catchError(err => {
          this.#clear();
          this.#router.navigate(['/auth/connexion']);
          return throwError(() => err);
        }),
      );
  }

  // ── Redirection post-auth ─────────────────────────────
  redirectToDashboard(): void {
    const r = this.userRole();
    this.#router.navigateByUrl(r ? DASHBOARDS[r] : '/');
  }

  // ── Privé ─────────────────────────────────────────────
  #onSuccess(a: AuthResponse): void {
    this.#token.set(a.accessToken);
    const u: UserProfile = {
      userId: a.userId, prenom: a.prenom, email: a.email,
      role: a.role, photoUrl: null, statut: 'ACTIF',
    };
    this.currentUser.set(u);
    if (isPlatformBrowser(this.#plat)) {
      sessionStorage.setItem('mn_u', JSON.stringify(u));
    }
  }

  #clear(): void {
    this.#token.clear();
    this.currentUser.set(null);
    if (isPlatformBrowser(this.#plat)) sessionStorage.removeItem('mn_u');
  }

  #restore(): UserProfile | null {
    try {
      if (typeof window === 'undefined') return null;
      const s = sessionStorage.getItem('mn_u');
      return s ? (JSON.parse(s) as UserProfile) : null;
    } catch { return null; }
  }

  #silentRefresh(): void {
    this.#api.post<{ accessToken: string }>('/auth/refresh', {}).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.#token.set(r.data.accessToken);
          this.#api.get<UserProfile>('/auth/me').subscribe({
            next: me => {
              if (me.success && me.data) {
                this.currentUser.set(me.data);
                if (isPlatformBrowser(this.#plat)) {
                  sessionStorage.setItem('mn_u', JSON.stringify(me.data));
                }
              }
            },
          });
        }
      },
      error: () => { /* Silence — pas de session active */ },
    });
  }
}
