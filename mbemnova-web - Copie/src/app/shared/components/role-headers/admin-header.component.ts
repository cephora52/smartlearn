import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-admin-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, RouterLinkActive],
  template: `
    <header class="fixed top-0 left-0 right-0 z-50 bg-white border-b border-slate-100">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center gap-3">
        <a routerLink="/admin" class="font-black text-lg text-[#312e81]">mbem<span class="text-[#0f172a]">X</span></a>
        <nav class="hidden md:flex items-center gap-1">
          <a routerLink="/admin" [routerLinkActiveOptions]="{ exact: true }" routerLinkActive="bg-blue-50 text-blue-700" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Dashboard</a>
          <a routerLink="/admin/apprenants" routerLinkActive="bg-blue-50 text-blue-700" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Apprenants</a>
          <a routerLink="/admin/paiements" routerLinkActive="bg-blue-50 text-blue-700" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Paiements</a>
          <a routerLink="/" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Page publique</a>
        </nav>
        <div class="ml-auto flex items-center gap-2">
          <span class="hidden sm:inline-flex px-3 py-2 rounded-lg text-sm text-slate-600">Admin: {{ prenom() }}</span>
          <button (click)="logout()" class="px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50">Deconnexion</button>
        </div>
      </div>
    </header>
    <div class="h-16"></div>
  `,
})
export class AdminHeaderComponent {
  readonly #auth = inject(AuthService);
  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Admin');
  logout(): void { this.#auth.logout(); }
}
