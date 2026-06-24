import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { ThemeService } from '../../../core/services/theme.service';

/**
 * ThemeToggleComponent — Bouton toggle thème clair/sombre.
 *
 * Usage :
 *   <app-theme-toggle />                    — icône seule
 *   <app-theme-toggle [showLabel]="true" /> — avec label texte
 */
@Component({
  selector: 'app-theme-toggle',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <button
      (click)="themeSvc.toggle()"
      [attr.aria-label]="themeSvc.isDark() ? 'Passer en mode clair' : 'Passer en mode sombre'"
      [attr.title]="themeSvc.isDark() ? 'Mode clair' : 'Mode sombre'"
      [class]="btnClass()">

      @if (themeSvc.isDark()) {
        <!-- Soleil — mode clair -->
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <circle cx="12" cy="12" r="5"/>
          <line x1="12" y1="1" x2="12" y2="3"/>
          <line x1="12" y1="21" x2="12" y2="23"/>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
          <line x1="1" y1="12" x2="3" y2="12"/>
          <line x1="21" y1="12" x2="23" y2="12"/>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
        </svg>
        @if (showLabel()) { <span class="text-sm font-medium">Mode clair</span> }
      } @else {
        <!-- Lune — mode sombre -->
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        </svg>
        @if (showLabel()) { <span class="text-sm font-medium">Mode sombre</span> }
      }
    </button>
  `,
})
export class ThemeToggleComponent {
  readonly themeSvc  = inject(ThemeService);
  readonly showLabel = input(false);
  readonly variant   = input<'icon' | 'pill'>('icon');

  btnClass(): string {
    if (this.variant() === 'pill') {
      return `flex items-center gap-2 px-3 py-1.5 rounded-xl border text-sm
              transition-all duration-150
              ${this.themeSvc.isDark()
                ? 'bg-slate-800 border-slate-700 text-amber-300 hover:bg-slate-700'
                : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`;
    }
    return `p-2 rounded-lg transition-colors duration-150
            ${this.themeSvc.isDark()
              ? 'text-amber-300 hover:bg-slate-700'
              : 'text-slate-500 hover:bg-slate-100'}`;
  }
}
