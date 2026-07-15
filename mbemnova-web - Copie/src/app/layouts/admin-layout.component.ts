import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-admin-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
<div class="flex min-h-[calc(100vh-64px)]">

  <!-- Sidebar admin -->
  <aside class="hidden lg:flex flex-col w-56 xl:w-60 shrink-0 border-r border-[var(--border)] bg-[var(--bg)] transition-colors duration-200 sticky top-16 h-[calc(100vh-64px)]">
    <nav class="flex-1 p-3 space-y-0.5 overflow-y-auto" aria-label="Navigation admin">

      <a routerLink="/admin" [routerLinkActiveOptions]="{ exact: true }"
         routerLinkActive="active-admin-link"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
        Dashboard
      </a>
      <a routerLink="/admin/apprenants"
         routerLinkActive="active-admin-link"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        Apprenants
      </a>
      <a routerLink="/admin/formateurs"
         routerLinkActive="active-admin-link"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        Formateurs
      </a>
      <a routerLink="/admin/formations"
         routerLinkActive="active-admin-link"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
        Formations
      </a>
      <a routerLink="/admin/paiements"
         routerLinkActive="active-admin-link"
         class="admin-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        Paiements
      </a>
    </nav>

    <div class="border-t border-[var(--border)] p-3">
      <p class="text-xs text-slate-500 px-2">Back-office MbemNova</p>
    </div>
  </aside>

  <main class="flex-1 min-w-0 bg-[var(--bg)] transition-colors duration-200">
    <router-outlet />
  </main>
</div>
  `,
  styles: [`
    @reference "tailwindcss";
    .admin-link {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 0.75rem;
      border-radius: 0.5rem;
      font-size: 0.875rem;
      color: var(--tx-sec);
      transition: all var(--t-fast);
      width: 100%;
    }
    .admin-link:hover {
      background-color: var(--bg-muted);
      color: var(--tx);
    }
    .active-admin-link {
      background-color: var(--p-600) !important;
      color: white !important;
      font-weight: 600 !important;
    }
  `],
})
export class AdminLayoutComponent {}
