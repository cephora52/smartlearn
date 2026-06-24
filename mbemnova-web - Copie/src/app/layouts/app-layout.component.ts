import { ChangeDetectionStrategy, Component, inject, computed } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../core/services/auth.service';

@Component({
  selector: 'app-app-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
<div class="flex min-h-[calc(100vh-64px)]">

  <!-- Sidebar desktop -->
  <aside class="hidden lg:flex flex-col w-56 xl:w-60 shrink-0 border-r border-slate-100 bg-white sticky top-16 h-[calc(100vh-64px)]">
    <nav class="flex-1 p-3 space-y-0.5 overflow-y-auto" aria-label="Navigation apprenant">

      @if (isApprenant()) {
        <a routerLink="/app" [routerLinkActiveOptions]="{ exact: true }"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          Tableau de bord
        </a>
        <a routerLink="/app/sessions"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Mes sessions
        </a>
        <a routerLink="/app/devoirs"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          Mes devoirs
        </a>
        <a routerLink="/app/certificats"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>
          Certificats
        </a>
        <a routerLink="/app/classement"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-1a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2h-2"/><rect x="6" y="18" width="12" height="4" rx="1"/></svg>
          Classement
        </a>
        <a routerLink="/app/paiements"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
          Paiements
        </a>
        <a routerLink="/app/parrainage"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>
          Parrainage
        </a>
        <a routerLink="/app/tirage"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          Tirage au sort
        </a>
      }

      @if (isFormateur()) {
        <a routerLink="/instructor" [routerLinkActiveOptions]="{ exact: true }"
           routerLinkActive="bg-purple-50 text-purple-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
          Dashboard
        </a>
        <a routerLink="/instructor/sessions"
           routerLinkActive="bg-purple-50 text-purple-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Sessions
        </a>
        <a routerLink="/instructor/correction"
           routerLinkActive="bg-purple-50 text-purple-700 font-semibold"
           class="sidebar-link">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
          Correction
        </a>
      }
    </nav>

    <!-- Profil sidebar -->
    <div class="border-t border-slate-100 p-3">
      <a routerLink="/app/profil"
         class="flex items-center gap-2 p-2 rounded-lg hover:bg-slate-50 transition-colors">
        <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center
                    text-white text-xs font-bold shrink-0">
          {{ initial() }}
        </div>
        <div class="min-w-0">
          <p class="text-sm font-medium text-slate-900 truncate">{{ prenom() }}</p>
          <p class="text-xs text-slate-400 truncate">Mon profil</p>
        </div>
      </a>
    </div>
  </aside>

  <!-- Contenu -->
  <main class="flex-1 min-w-0">
    <router-outlet />
  </main>
</div>
  `,
  styles: [`
    @reference "tailwindcss";
    .sidebar-link {
      @apply flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-slate-600
             hover:bg-slate-50 hover:text-slate-900 transition-colors duration-150 w-full;
    }
  `],
})
export class AppLayoutComponent {
  readonly #auth   = inject(AuthService);
  readonly isApprenant = computed(() => this.#auth.userRole() === 'APPRENANT');
  readonly isFormateur = computed(() => this.#auth.userRole() === 'FORMATEUR');
  readonly prenom      = computed(() => this.#auth.currentUser()?.prenom ?? '');
  readonly initial     = computed(() => this.prenom().charAt(0).toUpperCase());
}
