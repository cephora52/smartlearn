import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ThemeService } from '../../../core/services/theme.service';
import { ThemeToggleComponent } from '../theme-toggle/theme-toggle.component';

@Component({
  selector: 'app-instructor-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, RouterLinkActive, ThemeToggleComponent],
  template: `
    <header class="fixed top-0 left-0 right-0 z-50 bg-[var(--bg-subtle)] border-b border-[var(--border)] transition-colors duration-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center gap-3">
        <a routerLink="/instructor" class="font-black text-lg text-blue-600">Smart<span class="text-[var(--tx)]">Learn</span></a>
        <nav class="hidden md:flex items-center gap-1">
          <a routerLink="/instructor" [routerLinkActiveOptions]="{ exact: true }" routerLinkActive="bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 font-semibold" class="px-3 py-2 rounded-lg text-sm text-[var(--tx-sec)] hover:bg-[var(--bg-muted)] hover:text-[var(--tx)] transition-colors duration-150">Dashboard</a>
          <a routerLink="/instructor/correction" routerLinkActive="bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 font-semibold" class="px-3 py-2 rounded-lg text-sm text-[var(--tx-sec)] hover:bg-[var(--bg-muted)] hover:text-[var(--tx)] transition-colors duration-150">Correction</a>
          <a routerLink="/instructor/formations" routerLinkActive="bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 font-semibold" class="px-3 py-2 rounded-lg text-sm text-[var(--tx-sec)] hover:bg-[var(--bg-muted)] hover:text-[var(--tx)] transition-colors duration-150">Formations</a>
        </nav>
        <div class="ml-auto flex items-center gap-2">
          <app-theme-toggle />
          <span class="hidden sm:inline-flex px-3 py-2 rounded-lg text-sm text-[var(--tx-sec)]">Formateur: {{ prenom() }}</span>
          <button (click)="logout()" class="px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors duration-150">Deconnexion</button>
        </div>
      </div>
    </header>
    <div class="h-16"></div>
  `,
})
export class InstructorHeaderComponent {
  readonly #auth = inject(AuthService);
  readonly themeSvc = inject(ThemeService);
  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Formateur');
  logout(): void { this.#auth.logout(); }
}
