import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-learner-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, RouterLinkActive],
  template: `
    <header class="fixed top-0 left-0 right-0 z-50 bg-white border-b border-slate-100">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center gap-3">
        <a routerLink="/app" class="font-black text-lg text-[#312e81]">mbem<span class="text-[#0f172a]">X</span></a>
        <nav class="hidden md:flex items-center gap-1">
          <a routerLink="/app" [routerLinkActiveOptions]="{ exact: true }" routerLinkActive="bg-blue-50 text-blue-700" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Dashboard</a>
          <a routerLink="/app/sessions" routerLinkActive="bg-blue-50 text-blue-700" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Sessions</a>
          <a routerLink="/app/devoirs" routerLinkActive="bg-blue-50 text-blue-700" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Devoirs</a>
          <a routerLink="/" class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Page publique</a>
        </nav>
        <div class="ml-auto flex items-center gap-2">
          <a routerLink="/app/profil" class="hidden sm:inline-flex px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50">Bonjour, {{ prenom() }}</a>
          <button (click)="logout()" class="px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50">Deconnexion</button>
        </div>
      </div>
    </header>
    <div class="h-16"></div>
  `,
})
export class LearnerHeaderComponent {
  readonly #auth = inject(AuthService);
  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Apprenant');
  logout(): void { this.#auth.logout(); }
}
