import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl } from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { ApiService }   from '../../../core/services/api.service';
import { ToastService } from '../../../core/services/toast.service';

const pwdMatch = (c: AbstractControl) => {
  const a = c.get('nouveauMotDePasse')?.value, b = c.get('confirmation')?.value;
  return a && b && a !== b ? { mismatch: true } : null;
};

@Component({
  selector: 'app-reset-password',
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

    @if (!tokenValid()) {
      <div class="card p-8 text-center">
        <div class="text-4xl mb-4" aria-hidden="true">⚠️</div>
        <h2 class="font-bold text-slate-900 mb-2">Lien expiré</h2>
        <p class="text-sm text-slate-500 mb-6">Ce lien est invalide ou a expiré (1h). Faites une nouvelle demande.</p>
        <a routerLink="/auth/mot-de-passe-oublie" class="btn-primary w-full justify-center">Nouvelle demande</a>
      </div>
    }

    @if (tokenValid() && !done()) {
      <div class="text-center mb-8">
        <div class="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-4">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.8" aria-hidden="true"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>
        </div>
        <h1 class="text-2xl font-black text-slate-900 mb-2">Nouveau mot de passe</h1>
        <p class="text-slate-500 text-sm">Choisissez un mot de passe sécurisé (8 car. min).</p>
      </div>
      <div class="card p-6">
        <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
          <div>
            <label for="np" class="label">Nouveau mot de passe</label>
            <input id="np" type="password" formControlName="nouveauMotDePasse" autocomplete="new-password" placeholder="8 caractères minimum"
                   [class]="'input ' + (s && form.get('nouveauMotDePasse')?.invalid ? 'input-error' : '')">
            @if (s && form.get('nouveauMotDePasse')?.hasError('minlength')) { <p class="field-error" role="alert">8 caractères minimum</p> }
          </div>
          <div>
            <label for="nc" class="label">Confirmation</label>
            <input id="nc" type="password" formControlName="confirmation" autocomplete="new-password" placeholder="Retapez le mot de passe"
                   [class]="'input ' + (s && form.hasError('mismatch') ? 'input-error' : '')">
            @if (s && form.hasError('mismatch')) { <p class="field-error" role="alert">Les mots de passe ne correspondent pas</p> }
          </div>
          <button type="submit" [disabled]="loading()" class="btn-primary w-full py-3 font-semibold">
            @if (loading()) { Enregistrement… } @else { Enregistrer le mot de passe }
          </button>
        </form>
      </div>
    }

    @if (done()) {
      <div class="card p-10 text-center animate-scale-in">
        <div class="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-5">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Mot de passe mis à jour !</h2>
        <p class="text-sm text-slate-500 mb-6">Toutes vos sessions ont été déconnectées.</p>
        <a routerLink="/auth/connexion" class="btn-primary w-full justify-center">Se connecter</a>
      </div>
    }
  </div>
</div>
  `,
})
export class ResetPasswordComponent implements OnInit {
  readonly #api   = inject(ApiService);
  readonly #toast = inject(ToastService);
  readonly #route = inject(ActivatedRoute);
  readonly #fb    = inject(FormBuilder);
  readonly loading    = signal(false);
  readonly done       = signal(false);
  readonly tokenValid = signal(false);
  s = false; #token = '';
  readonly form = this.#fb.nonNullable.group(
    { nouveauMotDePasse: ['', [Validators.required, Validators.minLength(8)]], confirmation: ['', Validators.required] },
    { validators: pwdMatch }
  );
  ngOnInit(): void { this.#token = this.#route.snapshot.queryParams['token'] ?? ''; this.tokenValid.set(!!this.#token); }
  submit(): void {
    this.s = true;
    if (this.form.invalid || !this.#token) return;
    this.loading.set(true);
    const { nouveauMotDePasse, confirmation } = this.form.getRawValue();
    this.#api.post('/auth/new-password', { token: this.#token, nouveauMotDePasse, confirmation }).subscribe({
      next: () => { this.loading.set(false); this.done.set(true); this.#toast.success('Mot de passe mis à jour !'); },
      error: () => { this.loading.set(false); },
    });
  }
}
