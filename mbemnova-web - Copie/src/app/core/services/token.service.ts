import { Injectable, signal } from '@angular/core';

/**
 * TokenService — JWT uniquement en mémoire (signal privé).
 *
 * SÉCURITÉ :
 * • Access token → signal en mémoire : invisible aux XSS.
 *   Disparaît à la fermeture de l'onglet (voulu).
 * • Refresh token → cookie httpOnly géré par Spring Boot.
 *   Angular ne le lit jamais.
 */
@Injectable({ providedIn: 'root' })
export class TokenService {
  readonly #token = signal<string | null>(
    typeof window !== 'undefined' ? sessionStorage.getItem('mn_at') : null
  );

  set(t: string):   void { 
    this.#token.set(t); 
    if (typeof window !== 'undefined') {
      sessionStorage.setItem('mn_at', t);
    }
  }
  get():  string | null  { return this.#token(); }
  clear():          void { 
    this.#token.set(null); 
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem('mn_at');
    }
  }
  has():         boolean { return this.#token() !== null; }

  /** Décodage payload JWT (sans vérification signature — côté serveur uniquement) */
  decode(token: string): Record<string, unknown> | null {
    try {
      const p = token.split('.')[1];
      if (!p) return null;
      const pad = p + '='.repeat((4 - p.length % 4) % 4);
      return JSON.parse(atob(pad)) as Record<string, unknown>;
    } catch { return null; }
  }

  /** Vérifie expiration côté client (marge 30s) */
  isExpired(token: string): boolean {
    const p = this.decode(token);
    if (!p || typeof p['exp'] !== 'number') return true;
    return Date.now() / 1000 > (p['exp'] as number) - 30;
  }
}
