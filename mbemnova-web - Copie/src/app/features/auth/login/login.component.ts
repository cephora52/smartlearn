import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink, Router, ActivatedRoute } from '@angular/router';
import { AuthService }  from '../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex">

  <!-- Panneau gauche -->
  <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900
              items-center justify-center p-12 relative overflow-hidden">
    <div class="absolute inset-0 opacity-[0.04]"
         style="background-image:linear-gradient(white 1px,transparent 1px),linear-gradient(90deg,white 1px,transparent 1px);background-size:40px 40px"></div>
    <div class="relative z-10 text-center max-w-sm">
      <svg width="240" height="200" viewBox="0 0 240 200" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="mx-auto mb-8">
        <rect x="30" y="30" width="180" height="120" rx="12" fill="white" opacity="0.08"/>
        <rect x="42" y="42" width="156" height="96" rx="8" fill="white" opacity="0.06"/>
        <rect x="55" y="56" width="70" height="8" rx="4" fill="white" opacity="0.6"/>
        <rect x="55" y="70" width="100" height="5" rx="2.5" fill="white" opacity="0.3"/>
        <rect x="55" y="82" width="86" height="5" rx="2.5" fill="white" opacity="0.25"/>
        <rect x="55" y="98" width="130" height="5" rx="2.5" fill="#f1f5f9" opacity="0.12"/>
        <rect x="55" y="98" width="90" height="5" rx="2.5" fill="#60a5fa" opacity="0.7"/>
        <rect x="55" y="110" width="130" height="5" rx="2.5" fill="#f1f5f9" opacity="0.12"/>
        <rect x="55" y="110" width="55" height="5" rx="2.5" fill="#34d399" opacity="0.7"/>
        <path d="M110 150 L90 160 H150 L130 150z" fill="white" opacity="0.08"/>
        <rect x="74" y="160" width="92" height="5" rx="2.5" fill="white" opacity="0.08"/>
        <circle cx="192" cy="46" r="16" fill="#f59e0b" opacity="0.85"/>
        <text x="192" y="51" text-anchor="middle" font-size="14" fill="white" font-weight="bold">★</text>
        <circle cx="36" cy="145" r="18" fill="#f59e0b" opacity="0.15"/>
        <circle cx="36" cy="145" r="13" stroke="#f59e0b" stroke-width="2" opacity="0.4"/>
        <text x="36" y="150" text-anchor="middle" font-size="13" fill="#f59e0b">🏆</text>
      </svg>
      <h2 class="text-2xl font-bold text-white mb-3">Continuez votre apprentissage</h2>
      <p class="text-blue-200 text-sm leading-relaxed mb-8">Accédez à vos cours, suivez votre progression et rejoignez la communauté SmartLearn.</p>
      <div class="flex justify-center gap-8">
        @for (s of [['247+','apprenants'],['6','formations'],['95%','satisfaction']]; track s[0]) {
          <div class="text-center">
            <p class="text-2xl font-black text-white">{{ s[0] }}</p>
            <p class="text-xs text-blue-300 mt-0.5">{{ s[1] }}</p>
          </div>
        }
      </div>
    </div>
  </div>

  <!-- Formulaire -->
  <div class="flex-1 flex items-center justify-center p-6 sm:p-10">
    <div class="w-full max-w-sm animate-fade-up">
      <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform" aria-hidden="true">
          <rect width="36" height="36" rx="10" fill="#2563eb"/>
          <path d="M18 9L29 14L18 19L7 14L18 9Z" fill="white"/>
          <path d="M12 17V21C12 23.5 14.7 25 18 25C21.3 25 24 23.5 24 21V17L18 20L12 17Z" fill="white" opacity="0.9"/>
          <path d="M25 14.5V20.5L26.5 21.5" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
          <circle cx="28" cy="8" r="2.5" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">Smart<span class="text-blue-600">Learn</span></span>
      </a>
      <h1 class="text-2xl font-black text-slate-900 mb-1">Bon retour !</h1>
      <p class="text-slate-500 text-sm mb-8">Connectez-vous pour continuer votre parcours.</p>

      <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
        <div>
          <label for="email" class="label">Adresse email</label>
          <input id="email" type="email" formControlName="email" autocomplete="email"
                 placeholder="vous@example.com"
                 [class]="'input ' + (s && form.get('email')?.invalid ? 'input-error' : '')">
          @if (s && form.get('email')?.invalid) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Email valide requis
            </p>
          }
        </div>
        <div>
          <div class="flex justify-between items-center mb-1.5">
            <label for="pwd" class="label mb-0">Mot de passe</label>
            <a routerLink="/auth/mot-de-passe-oublie" class="text-xs text-blue-600 hover:text-blue-700 transition-colors">Oublié ?</a>
          </div>
          <div class="relative">
            <input id="pwd" [type]="showPwd() ? 'text' : 'password'" formControlName="motDePasse"
                   autocomplete="current-password" placeholder="••••••••"
                   [class]="'input pr-11 ' + (s && form.get('motDePasse')?.invalid ? 'input-error' : '')">
            <button type="button" (click)="showPwd.set(!showPwd())"
                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
                    [attr.aria-label]="showPwd() ? 'Masquer' : 'Afficher'">
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                @if (!showPwd()) { <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/> }
                @else { <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/> }
              </svg>
            </button>
          </div>
        </div>
        <label class="flex items-center gap-2.5 cursor-pointer select-none">
          <input type="checkbox" formControlName="rememberMe" class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500">
          <span class="text-sm text-slate-600">Se souvenir de moi</span>
        </label>
        <button type="submit" [disabled]="loading()" class="btn-primary w-full py-3 text-base font-semibold mt-1">
          @if (loading()) {
            <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            Connexion…
          } @else { Se connecter }
        </button>
      </form>

      <p class="text-center text-sm text-slate-500 mt-6">
        Pas encore de compte ?
        <a routerLink="/auth/inscription" class="link font-semibold ml-1">Créer un compte gratuit</a>
      </p>
      <p class="text-center text-xs text-slate-400 mt-4">
        En vous connectant, vous acceptez nos
        <a routerLink="/politique-confidentialite" class="underline hover:text-slate-600 transition-colors">conditions d'utilisation</a>
      </p>
    </div>
  </div>
</div>
  `,
})
export class LoginComponent {
  readonly #auth   = inject(AuthService);
  readonly #router = inject(Router);
  readonly #route  = inject(ActivatedRoute);
  readonly #fb     = inject(FormBuilder);

  readonly loading = signal(false);
  readonly showPwd = signal(false);
  s = false;

  readonly form = this.#fb.nonNullable.group({
    email:      ['', [Validators.required, Validators.email]],
    motDePasse: ['', Validators.required],
    rememberMe: [false],
  });

  submit(): void {
    this.s = true;
    if (this.form.invalid) return;
    this.loading.set(true);
    this.#auth.login(this.form.getRawValue()).subscribe({
      next: () => {
        this.loading.set(false);
        const returnUrl = this.#route.snapshot.queryParams['returnUrl'];
        if (returnUrl) this.#router.navigateByUrl(returnUrl);
        else this.#auth.redirectToDashboard();
      },
      error: () => { this.loading.set(false); },
    });
  }
}
