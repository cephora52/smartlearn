import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../core/services/api.service';

@Component({
  selector: 'app-forgot-password',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex items-center justify-center p-4">
  <div class="w-full max-w-sm animate-fade-up">
    <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
      <svg width="34" height="34" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform duration-200" aria-hidden="true">
        <rect width="36" height="36" rx="10" fill="#2563eb"/>
        <path d="M18 9L29 14L18 19L7 14L18 9Z" fill="white"/>
        <path d="M12 17V21C12 23.5 14.7 25 18 25C21.3 25 24 23.5 24 21V17L18 20L12 17Z" fill="white" opacity="0.9"/>
        <path d="M25 14.5V20.5L26.5 21.5" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
        <circle cx="28" cy="8" r="2.5" fill="#f59e0b" class="animate-dot-pulse"/>
      </svg>
      <span class="font-bold text-xl text-slate-900">Smart<span class="text-blue-600">Learn</span></span>
    </a>

    @if (!sent()) {
      <div class="text-center mb-8">
        <div class="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-4">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.8" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/><circle cx="12" cy="16" r="1.5" fill="#2563eb"/></svg>
        </div>
        <h1 class="text-2xl font-black text-slate-900 mb-2">Mot de passe oublié ?</h1>
        <p class="text-slate-500 text-sm">Entrez votre email pour recevoir un lien de réinitialisation.</p>
      </div>
      <div class="card p-6">
        <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
          <div>
            <label for="fp-email" class="label">Adresse email</label>
            <input id="fp-email" type="email" formControlName="email" autocomplete="email" placeholder="vous@example.com" class="input">
          </div>
          <button type="submit" [disabled]="loading()" class="btn-primary w-full py-3 font-semibold">
            @if (loading()) { Envoi… } @else { Envoyer le lien }
          </button>
        </form>
      </div>
    }

    @if (sent()) {
      <div class="card p-10 text-center animate-scale-in">
        <div class="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-5">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Email envoyé !</h2>
        <p class="text-sm text-slate-500 mb-6 leading-relaxed">Si un compte existe avec cette adresse, vous recevrez un lien dans quelques minutes. Vérifiez vos spams.</p>
        <a routerLink="/auth/connexion" class="btn-secondary w-full justify-center">Retour à la connexion</a>
      </div>
    }

    <p class="text-center text-sm text-slate-500 mt-6">
      <a routerLink="/auth/connexion" class="link flex items-center gap-1 justify-center">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        Retour à la connexion
      </a>
    </p>
  </div>
</div>
  `,
})
export class ForgotPasswordComponent {
  readonly #api = inject(ApiService);
  readonly #fb  = inject(FormBuilder);
  readonly loading = signal(false);
  readonly sent    = signal(false);
  readonly form = this.#fb.nonNullable.group({ email: ['', [Validators.required, Validators.email]] });
  submit(): void {
    if (this.form.invalid) return;
    this.loading.set(true);
    this.#api.post('/auth/reset-password', this.form.getRawValue()).subscribe({
      next:  () => { this.loading.set(false); this.sent.set(true); },
      error: () => { this.loading.set(false); this.sent.set(true); },
    });
  }
}
