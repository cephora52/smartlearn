import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl } from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

const pwdMatch = (c: AbstractControl) => {
  const a = c.get('motDePasse')?.value, b = c.get('confirmation')?.value;
  return a && b && a !== b ? { mismatch: true } : null;
};

@Component({
  selector: 'app-register',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex">
  <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-emerald-700 to-teal-900
              items-center justify-center p-12 relative overflow-hidden">
    <div class="absolute inset-0 opacity-[0.04]"
         style="background-image:linear-gradient(white 1px,transparent 1px),linear-gradient(90deg,white 1px,transparent 1px);background-size:40px 40px"></div>
    <div class="relative z-10 text-center max-w-sm">
      <div class="text-6xl mb-6" aria-hidden="true">🚀</div>
      <h2 class="text-2xl font-bold text-white mb-3">Votre parcours commence ici</h2>
      <p class="text-emerald-200 text-sm leading-relaxed mb-8">Rejoignez 247 apprenants qui développent leurs compétences tech avec MbemNova. Formations certifiantes, paiement en tranches.</p>
      <div class="space-y-3 text-left">
        @for (a of avantages; track a) {
          <div class="flex items-center gap-3">
            <div class="w-5 h-5 rounded-full bg-white/20 flex items-center justify-center shrink-0">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
            <p class="text-sm text-emerald-100">{{ a }}</p>
          </div>
        }
      </div>
    </div>
  </div>

  <div class="flex-1 flex items-start justify-center p-6 sm:p-10 overflow-y-auto py-10">
    <div class="w-full max-w-sm animate-fade-up">
      <a routerLink="/" class="inline-flex items-center gap-2.5 mb-8 group">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform" aria-hidden="true">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
      </a>
      <h1 class="text-2xl font-black text-slate-900 mb-1">Créer votre compte</h1>
      <p class="text-slate-500 text-sm mb-8">Gratuit. Aucune carte bancaire requise.</p>

      @if (referralCode()) {
        <div class="flex items-center gap-3 bg-green-50 border border-green-200 rounded-xl px-4 py-3 mb-6">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
          <div>
            <p class="text-sm font-semibold text-green-800">Code parrainage appliqué !</p>
            <p class="text-xs text-green-600">Vous et votre parrain recevrez des bonus XP.</p>
          </div>
        </div>
      }

      <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
        <div>
          <label for="prenom" class="label">Prénom <span class="text-red-500">*</span></label>
          <input id="prenom" type="text" formControlName="prenom" autocomplete="given-name" placeholder="Jean-Paul"
                 [class]="'input ' + (s && form.get('prenom')?.invalid ? 'input-error' : '')">
          @if (s && form.get('prenom')?.invalid) { <p class="field-error" role="alert">Prénom requis (2 car. min)</p> }
        </div>
        <div>
          <label for="reg-email" class="label">Email <span class="text-red-500">*</span></label>
          <input id="reg-email" type="email" formControlName="email" autocomplete="email" placeholder="vous@example.com"
                 [class]="'input ' + (s && form.get('email')?.invalid ? 'input-error' : '')">
          @if (s && form.get('email')?.invalid) { <p class="field-error" role="alert">Email valide requis</p> }
        </div>
        <div>
          <label for="reg-pwd" class="label">Mot de passe <span class="text-red-500">*</span></label>
          <input id="reg-pwd" type="password" formControlName="motDePasse" autocomplete="new-password" placeholder="8 caractères minimum"
                 [class]="'input ' + (s && form.get('motDePasse')?.invalid ? 'input-error' : '')">
          @if (s && form.get('motDePasse')?.hasError('minlength')) { <p class="field-error" role="alert">8 caractères minimum</p> }
        </div>
        <div>
          <label for="reg-conf" class="label">Confirmation <span class="text-red-500">*</span></label>
          <input id="reg-conf" type="password" formControlName="confirmation" autocomplete="new-password" placeholder="Retapez le mot de passe"
                 [class]="'input ' + (s && form.hasError('mismatch') ? 'input-error' : '')">
          @if (s && form.hasError('mismatch')) { <p class="field-error" role="alert">Les mots de passe ne correspondent pas</p> }
        </div>
        <label class="flex items-start gap-2.5 cursor-pointer">
          <input type="checkbox" formControlName="consent" class="w-4 h-4 rounded mt-0.5 text-blue-600 border-slate-300 focus:ring-blue-500 shrink-0">
          <span class="text-sm text-slate-600 leading-relaxed">
            J'accepte la <a routerLink="/politique-confidentialite" target="_blank" class="link font-medium">politique de confidentialité</a> de MbemNova.
          </span>
        </label>
        @if (s && form.get('consent')?.hasError('required')) {
          <p class="field-error -mt-2" role="alert">Vous devez accepter les conditions</p>
        }
        <button type="submit" [disabled]="loading()" class="btn-success w-full py-3 text-base font-semibold mt-1">
          @if (loading()) {
            <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            Création…
          } @else { Créer mon compte gratuit }
        </button>
      </form>
      <p class="text-center text-sm text-slate-500 mt-6">
        Déjà inscrit ? <a routerLink="/auth/connexion" class="link font-semibold ml-1">Se connecter</a>
      </p>
    </div>
  </div>
</div>
  `,
})
export class RegisterComponent implements OnInit {
  readonly #auth  = inject(AuthService);
  readonly #route = inject(ActivatedRoute);
  readonly #fb    = inject(FormBuilder);

  readonly loading     = signal(false);
  readonly referralCode= signal('');
  s = false;

  readonly avantages = ['Accès partiel gratuit dès l\'inscription', 'Paiement en tranches adapté', 'Certificat officiel vérifiable', 'Communauté d\'apprenants active'];

  readonly form = this.#fb.nonNullable.group({
    prenom:       ['', [Validators.required, Validators.minLength(2)]],
    email:        ['', [Validators.required, Validators.email]],
    motDePasse:   ['', [Validators.required, Validators.minLength(8)]],
    confirmation: ['', Validators.required],
    consent:      [false, Validators.requiredTrue],
  }, { validators: pwdMatch });

  ngOnInit(): void {
    const code = this.#route.snapshot.queryParams['ref'] ?? '';
    if (code) this.referralCode.set(code);
  }

  submit(): void {
    this.s = true;
    if (this.form.invalid) return;
    this.loading.set(true);
    const { prenom, email, motDePasse } = this.form.getRawValue();
    const code = this.referralCode();
    this.#auth.register({ prenom, email, motDePasse, ...(code ? { referralCode: code } : {}) }).subscribe({
      next: () => { this.loading.set(false); this.#auth.redirectToDashboard(); },
      error: () => { this.loading.set(false); },
    });
  }
}
