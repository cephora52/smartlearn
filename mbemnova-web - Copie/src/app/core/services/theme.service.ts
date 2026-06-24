import {
  Injectable, signal, computed, effect,
  PLATFORM_ID, inject,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export type Theme = 'light' | 'dark';

/**
 * ThemeService — Gestion du thème clair/sombre.
 *
 * • Persistance via localStorage (clé 'mn_theme')
 * • Respecte la préférence système si aucune préférence stockée
 * • SSR-safe : ne touche pas au DOM côté serveur
 * • Apply via classe 'dark' sur <html> (compatible Tailwind dark mode)
 */
@Injectable({ providedIn: 'root' })
export class ThemeService {
  readonly #platform = inject(PLATFORM_ID);

  readonly theme = signal<Theme>(this.#init());

  readonly isDark  = computed(() => this.theme() === 'dark');
  readonly isLight = computed(() => this.theme() === 'light');

  constructor() {
    // Applique le thème dès que le signal change
    effect(() => {
      this.#apply(this.theme());
    });
  }

  toggle(): void {
    this.theme.update(t => t === 'dark' ? 'light' : 'dark');
  }

  setTheme(t: Theme): void {
    this.theme.set(t);
  }

  #init(): Theme {
    if (!isPlatformBrowser(this.#platform)) return 'light';
    const stored = localStorage.getItem('mn_theme') as Theme | null;
    if (stored === 'dark' || stored === 'light') return stored;
    // Respecter la préférence système
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  #apply(t: Theme): void {
    if (!isPlatformBrowser(this.#platform)) return;
    const html = document.documentElement;
    if (t === 'dark') {
      html.classList.add('dark');
    } else {
      html.classList.remove('dark');
    }
    localStorage.setItem('mn_theme', t);
    html.setAttribute('data-theme', t);
  }
}
