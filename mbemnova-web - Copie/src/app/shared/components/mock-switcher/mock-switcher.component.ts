import {
  ChangeDetectionStrategy, Component, inject,
  signal, PLATFORM_ID, OnInit,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { MOCK_PROFILES, switchProfile } from '../../../core/services/mock.data';
import type { UserRole } from '../../../core/models';

/**
 * MockSwitcherComponent — visible UNIQUEMENT en mode mock (DEV).
 *
 * Permet de switcher entre les 4 profils en 1 clic :
 *   APPRENANT · FORMATEUR · ADMIN · SUPER_ADMIN
 *
 * Placé en bas à gauche de l'écran — ne gêne pas l'UI.
 */
@Component({
  selector: 'app-mock-switcher',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (visible()) {
      <div class="fixed bottom-4 left-4 z-[490] animate-fade-up"
           role="complementary" aria-label="Sélecteur de profil (développement)">

        @if (open()) {
          <!-- Panel profils -->
          <div class="mb-2 bg-slate-900 border border-slate-700 rounded-2xl p-3
                      shadow-2xl min-w-52 animate-slide-right">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2.5 px-1">
              🎭 Changer de profil
            </p>
            <div class="space-y-1">
              @for (p of profiles; track p.role) {
                <button (click)="switchTo(p.role)"
                        [class]="'w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm
                                  transition-colors text-left '
                                  + (currentRole() === p.role
                                  ? 'bg-blue-600 text-white'
                                  : 'text-slate-300 hover:bg-slate-800')">
                  <span class="text-lg shrink-0" aria-hidden="true">{{ p.icon }}</span>
                  <div class="flex-1 min-w-0">
                    <p class="font-semibold truncate">{{ p.label }}</p>
                    <p class="text-xs opacity-70 truncate">{{ p.email }}</p>
                  </div>
                  @if (currentRole() === p.role) {
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" aria-label="Profil actif">
                      <polyline points="20 6 9 17 4 12"/>
                    </svg>
                  }
                </button>
              }
            </div>
            <div class="border-t border-slate-700 mt-2.5 pt-2.5 px-1">
              <p class="text-xs text-slate-500 leading-relaxed">
                Données mock actives.<br>
                Pour l'API réelle : <code class="text-amber-400">useMock: false</code>
              </p>
            </div>
          </div>
        }

        <!-- Bouton toggle -->
        <button (click)="open.set(!open())"
                class="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold
                       shadow-lg border transition-all"
                [class]="open()
                  ? 'bg-slate-700 border-slate-600 text-white'
                  : 'bg-amber-100 border-amber-300 text-amber-800 hover:bg-amber-200'"
                aria-label="Ouvrir le sélecteur de profil">
          <div class="w-2 h-2 rounded-full bg-amber-500 animate-pulse shrink-0" aria-hidden="true"></div>
          <span>{{ currentIcon() }} {{ currentRole() }}</span>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2.5" class="transition-transform"
               [class.rotate-180]="open()" aria-hidden="true">
            <polyline points="6 9 12 15 18 9"/>
          </svg>
        </button>
      </div>
    }
  `,
})
export class MockSwitcherComponent implements OnInit {
  readonly #auth     = inject(AuthService);
  readonly #router   = inject(Router);
  readonly #platform = inject(PLATFORM_ID);

  readonly visible    = signal(false);
  readonly open       = signal(false);
  readonly currentRole = () => this.#auth.currentUser()?.role ?? 'APPRENANT';

  readonly profiles = [
    { role: 'APPRENANT'  as UserRole, label: 'Apprenant',   icon: '🎓', email: 'jeanpaul@gmail.com' },
    { role: 'FORMATEUR'  as UserRole, label: 'Formateur',   icon: '👨‍🏫', email: 'alice@mbemnova.com' },
    { role: 'ADMIN'      as UserRole, label: 'Admin',       icon: '🛡️', email: 'serge@mbemnova.com' },
    { role: 'SUPER_ADMIN'as UserRole, label: 'Super Admin', icon: '👑', email: 'root@mbemnova.com' },
  ];

  currentIcon(): string {
    return this.profiles.find(p => p.role === this.currentRole())?.icon ?? '👤';
  }

  ngOnInit(): void {
    if (!isPlatformBrowser(this.#platform)) return;
    // Visible seulement si useMock est actif
    import('../../../../environments/environment').then(env => {
      this.visible.set(!!env.environment.useMock);
    }).catch(() => {});
  }

  switchTo(role: UserRole): void {
    switchProfile(role);
    const authData = MOCK_PROFILES[role];
    // Forcer la mise à jour du signal currentUser
    (this.#auth as any).currentUser.set({
      id: authData.userId,
      userId: authData.userId,
      nom: authData.nom,
      prenom: authData.prenom,
      email: authData.email,
      role: authData.role,
      photoUrl: null,
      statut: 'ACTIF',
    });
    this.open.set(false);
    // Redirection vers le dashboard du rôle
    const routes: Record<UserRole, string> = {
      APPRENANT: '/apprenant/dashboard',
      FORMATEUR: '/formateur/dashboard',
      ADMIN: '/admin/dashboard',
      SUPER_ADMIN: '/admin/dashboard',
    };
    this.#router.navigateByUrl(routes[role]);
  }
}
