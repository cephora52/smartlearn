import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl } from '@angular/forms';
import { RouterLink, Router, ActivatedRoute } from '@angular/router';
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
      <p class="text-emerald-200 text-sm leading-relaxed mb-8">Rejoignez 247 apprenants qui développent leurs compétences tech avec SmartLearn. Formations certifiantes, paiement en tranches.</p>
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
          <rect width="36" height="36" rx="10" fill="#2563eb"/>
          <path d="M18 9L29 14L18 19L7 14L18 9Z" fill="white"/>
          <path d="M12 17V21C12 23.5 14.7 25 18 25C21.3 25 24 23.5 24 21V17L18 20L12 17Z" fill="white" opacity="0.9"/>
          <path d="M25 14.5V20.5L26.5 21.5" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
          <circle cx="28" cy="8" r="2.5" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">Smart<span class="text-blue-600">Learn</span></span>
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
        <!-- Nom / Prénom en ligne -->
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label for="nom" class="label">Nom <span class="text-red-500">*</span></label>
            <input id="nom" type="text" formControlName="nom" autocomplete="family-name" placeholder="Mbemba"
                   [class]="'input ' + (s && form.get('nom')?.invalid ? 'input-error' : '')">
            @if (s && form.get('nom')?.invalid) { <p class="field-error" role="alert">Nom requis</p> }
          </div>
          <div>
            <label for="prenom" class="label">Prénom <span class="text-red-500">*</span></label>
            <input id="prenom" type="text" formControlName="prenom" autocomplete="given-name" placeholder="Jean-Paul"
                   [class]="'input ' + (s && form.get('prenom')?.invalid ? 'input-error' : '')">
            @if (s && form.get('prenom')?.invalid) { <p class="field-error" role="alert">Prénom requis</p> }
          </div>
        </div>

        <!-- Choix du Rôle -->
        <div>
          <label class="label font-semibold text-slate-600">Vous êtes <span class="text-red-500">*</span></label>
          <div class="grid grid-cols-2 gap-3 mt-1.5">
            <label class="flex items-center gap-2 p-3 rounded-lg border border-slate-200 cursor-pointer bg-white hover:bg-slate-50"
                   [class.border-blue-400]="form.get('role')?.value === 'APPRENANT'"
                   [class.bg-blue-50/10]="form.get('role')?.value === 'APPRENANT'">
              <input type="radio" formControlName="role" value="APPRENANT" class="w-4 h-4 text-blue-600 focus:ring-blue-500">
              <span class="text-sm font-semibold text-slate-700">Apprenant</span>
            </label>
            <label class="flex items-center gap-2 p-3 rounded-lg border border-slate-200 cursor-pointer bg-white hover:bg-slate-50"
                   [class.border-blue-400]="form.get('role')?.value === 'FORMATEUR'"
                   [class.bg-blue-50/10]="form.get('role')?.value === 'FORMATEUR'">
              <input type="radio" formControlName="role" value="FORMATEUR" class="w-4 h-4 text-blue-600 focus:ring-blue-500">
              <span class="text-sm font-semibold text-slate-700">Formateur</span>
            </label>
          </div>
        </div>

        <div>
          <label for="reg-email" class="label">Email <span class="text-red-500">*</span></label>
          <input id="reg-email" type="email" formControlName="email" autocomplete="email" placeholder="vous@example.com"
                 [class]="'input ' + (s && form.get('email')?.invalid ? 'input-error' : '')">
          @if (s && form.get('email')?.invalid) { <p class="field-error" role="alert">Email valide requis</p> }
        </div>

        <div>
          <label for="telephone" class="label">Téléphone <span class="text-red-500">*</span></label>
          <input id="telephone" type="tel" formControlName="telephone" autocomplete="tel" placeholder="+242 06 600 0000"
                 [class]="'input ' + (s && form.get('telephone')?.invalid ? 'input-error' : '')">
          @if (s && form.get('telephone')?.invalid) { <p class="field-error" role="alert">Téléphone requis</p> }
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
            J'accepte la <a routerLink="/politique-confidentialite" target="_blank" class="link font-medium">politique de confidentialité</a> de SmartLearn.
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
  readonly #auth   = inject(AuthService);
  readonly #route  = inject(ActivatedRoute);
  readonly #fb     = inject(FormBuilder);

  readonly loading      = signal(false);
  readonly referralCode = signal('');
  s = false;

  readonly avantages = ['Accès partiel gratuit dès l\'inscription', 'Paiement en tranches adapté', 'Certificat officiel vérifiable', 'Communauté d\'apprenants active'];

  readonly form = this.#fb.nonNullable.group({
    nom:          ['', [Validators.required, Validators.minLength(2)]],
    prenom:       ['', [Validators.required, Validators.minLength(2)]],
    email:        ['', [Validators.required, Validators.email]],
    telephone:    ['', [Validators.required]],
    motDePasse:   ['', [Validators.required, Validators.minLength(8)]],
    confirmation: ['', Validators.required],
    role:         ['APPRENANT', [Validators.required]],
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
    const { nom, prenom, email, telephone, motDePasse, confirmation, role } = this.form.getRawValue();
    const code = this.referralCode();
    this.#auth.register({
      nom,
      prenom,
      email,
      telephone,
      motDePasse,
      confirmationMotDePasse: confirmation,
      role,
      ...(code ? { referralCode: code } : {})
    }).subscribe({
      next: () => { this.loading.set(false); this.#auth.redirectToDashboard(); },
      error: () => { this.loading.set(false); },
    });
  }
}
