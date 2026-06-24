#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 04/16 · Pages Authentification
# ============================================================
# Contenu :
#   Login           (S03) — connexion + redirect selon rôle
#   Register        (S02) — inscription + code parrainage URL
#   ForgotPassword  (S27 étape 1) — email reset
#   ResetPassword   (S27 étape 2) — nouveau mot de passe
#
# Règles : Tailwind only · OnPush · Signals · Reactive Forms
#          SSR-safe · Illustrations SVG inline
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "\033[0;31m  ✗\033[0m $1" >&2; exit 1; }
[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet"

mkdir -p \
  src/app/features/auth/login \
  src/app/features/auth/register \
  src/app/features/auth/forgot-password \
  src/app/features/auth/reset-password

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 04 · Auth Pages              ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. LOGIN — S03
# ============================================================
sec "1/4 — Login (S03)"

cat > src/app/features/auth/login/login.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject, signal,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink, Router, ActivatedRoute } from '@angular/router';
import { AuthService }  from '../../../core/services/auth.service';
import { ToastService } from '../../../core/services/toast.service';

@Component({
  selector: 'app-login',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex">

  <!-- Panneau gauche — illustration (masqué xs/sm) -->
  <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-blue-600 to-indigo-800
              items-center justify-center p-12 relative overflow-hidden">
    <!-- Motif grille -->
    <div class="absolute inset-0 opacity-10"
         style="background-image:linear-gradient(rgba(255,255,255,1) 1px,transparent 1px),
                linear-gradient(90deg,rgba(255,255,255,1) 1px,transparent 1px);
                background-size:40px 40px"></div>

    <!-- Illustration SVG -->
    <div class="relative z-10 text-center max-w-sm">
      <svg width="280" height="220" viewBox="0 0 280 220" fill="none"
           xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="mx-auto mb-8">
        <!-- Écran laptop -->
        <rect x="30" y="30" width="220" height="140" rx="12" fill="white" opacity="0.12"/>
        <rect x="40" y="40" width="200" height="120" rx="8" fill="white" opacity="0.08"/>
        <!-- Contenu écran -->
        <rect x="55" y="56" width="80" height="8" rx="4" fill="white" opacity="0.6"/>
        <rect x="55" y="72" width="120" height="6" rx="3" fill="white" opacity="0.4"/>
        <rect x="55" y="85" width="100" height="6" rx="3" fill="white" opacity="0.3"/>
        <!-- Barres de progression -->
        <rect x="55" y="102" width="160" height="6" rx="3" fill="white" opacity="0.15"/>
        <rect x="55" y="102" width="110" height="6" rx="3" fill="#60a5fa" opacity="0.8"/>
        <rect x="55" y="114" width="160" height="6" rx="3" fill="white" opacity="0.15"/>
        <rect x="55" y="114" width="70" height="6" rx="3" fill="#34d399" opacity="0.8"/>
        <rect x="55" y="126" width="160" height="6" rx="3" fill="white" opacity="0.15"/>
        <rect x="55" y="126" width="130" height="6" rx="3" fill="#a78bfa" opacity="0.8"/>
        <!-- Support laptop -->
        <path d="M110 170 L90 185 H190 L170 170z" fill="white" opacity="0.1"/>
        <rect x="75" y="185" width="130" height="6" rx="3" fill="white" opacity="0.1"/>
        <!-- Étoiles XP -->
        <circle cx="230" cy="50" r="12" fill="#f59e0b" opacity="0.9"/>
        <text x="230" y="55" text-anchor="middle" font-size="12" fill="white" font-weight="bold">★</text>
        <circle cx="248" cy="72" r="8" fill="#34d399" opacity="0.7"/>
        <text x="248" y="76" text-anchor="middle" font-size="9" fill="white" font-weight="bold">✓</text>
        <!-- Badge certificat -->
        <circle cx="50" cy="165" r="18" fill="#f59e0b" opacity="0.2"/>
        <circle cx="50" cy="165" r="14" stroke="#f59e0b" stroke-width="2" opacity="0.5"/>
        <text x="50" y="170" text-anchor="middle" font-size="14" fill="#f59e0b">🏆</text>
      </svg>

      <h2 class="text-2xl font-bold text-white mb-3">Continuez votre apprentissage</h2>
      <p class="text-blue-200 text-sm leading-relaxed">
        Accédez à vos cours, suivez votre progression et rejoignez la communauté MbemNova.
      </p>

      <!-- Stats -->
      <div class="flex justify-center gap-8 mt-8">
        @for (s of stats; track s.label) {
          <div class="text-center">
            <p class="text-2xl font-black text-white">{{ s.value }}</p>
            <p class="text-xs text-blue-300 mt-0.5">{{ s.label }}</p>
          </div>
        }
      </div>
    </div>
  </div>

  <!-- Panneau droite — formulaire -->
  <div class="flex-1 flex items-center justify-center p-6 sm:p-10">
    <div class="w-full max-w-sm animate-fade-up">

      <!-- Logo -->
      <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" aria-hidden="true"
             class="group-hover:scale-105 transition-transform">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5"
                stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">
          Mbem<span class="text-blue-600">Nova</span>
        </span>
      </a>

      <h1 class="text-2xl font-black text-slate-900 mb-1" style="font-family:var(--font);">
        Bon retour !
      </h1>
      <p class="text-slate-500 text-sm mb-8">
        Connectez-vous pour continuer votre parcours.
      </p>

      <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">

        <!-- Email -->
        <div>
          <label for="email" class="label">Adresse email</label>
          <input id="email" type="email" formControlName="email"
                 autocomplete="email" placeholder="vous@example.com"
                 [class]="'input ' + (touched('email') && f['email'].invalid ? 'input-error' : '')">
          @if (touched('email') && f['email'].hasError('required')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Email requis
            </p>
          }
          @if (touched('email') && f['email'].hasError('email')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Format email invalide
            </p>
          }
        </div>

        <!-- Mot de passe -->
        <div>
          <div class="flex items-center justify-between mb-1.5">
            <label for="password" class="label mb-0">Mot de passe</label>
            <a routerLink="/auth/mot-de-passe-oublie"
               class="text-xs text-blue-600 hover:text-blue-700 transition-colors">
              Oublié ?
            </a>
          </div>
          <div class="relative">
            <input id="password" [type]="showPwd() ? 'text' : 'password'"
                   formControlName="motDePasse"
                   autocomplete="current-password" placeholder="••••••••"
                   [class]="'input pr-11 ' + (touched('motDePasse') && f['motDePasse'].invalid ? 'input-error' : '')">
            <button type="button" (click)="showPwd.set(!showPwd())"
                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400
                           hover:text-slate-600 transition-colors"
                    [attr.aria-label]="showPwd() ? 'Masquer le mot de passe' : 'Afficher le mot de passe'">
              @if (!showPwd()) {
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                  <circle cx="12" cy="12" r="3"/>
                </svg>
              } @else {
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                  <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                  <line x1="1" y1="1" x2="23" y2="23"/>
                </svg>
              }
            </button>
          </div>
          @if (touched('motDePasse') && f['motDePasse'].hasError('required')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Mot de passe requis
            </p>
          }
        </div>

        <!-- Se souvenir -->
        <label class="flex items-center gap-2.5 cursor-pointer select-none">
          <input type="checkbox" formControlName="rememberMe"
                 class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500">
          <span class="text-sm text-slate-600">Se souvenir de moi</span>
        </label>

        <!-- Bouton connexion -->
        <button type="submit" [disabled]="loading()"
                class="btn-primary w-full py-3 text-base font-semibold mt-2">
          @if (loading()) {
            <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24"
                 fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
            Connexion en cours…
          } @else {
            Se connecter
          }
        </button>
      </form>

      <p class="text-center text-sm text-slate-500 mt-6">
        Pas encore de compte ?
        <a routerLink="/auth/inscription" class="link font-semibold ml-1">
          Créer un compte gratuit
        </a>
      </p>

      <!-- Lien politique (requis sur page auth — S28) -->
      <p class="text-center text-xs text-slate-400 mt-4">
        En vous connectant, vous acceptez nos
        <a routerLink="/politique-confidentialite" class="underline hover:text-slate-600 transition-colors">
          conditions d'utilisation
        </a>
      </p>
    </div>
  </div>
</div>
  `,
})
export class LoginComponent {
  readonly #auth   = inject(AuthService);
  readonly #toast  = inject(ToastService);
  readonly #router = inject(Router);
  readonly #route  = inject(ActivatedRoute);
  readonly #fb     = inject(FormBuilder);

  readonly loading = signal(false);
  readonly showPwd = signal(false);
  submitted        = false;

  readonly form = this.#fb.nonNullable.group({
    email:      ['', [Validators.required, Validators.email]],
    motDePasse: ['', Validators.required],
    rememberMe: [false],
  });

  get f() { return this.form.controls; }

  touched(field: string): boolean {
    return this.submitted || !!this.form.get(field)?.touched;
  }

  readonly stats = [
    { value: '247', label: 'apprenants' },
    { value: '6',   label: 'formations' },
    { value: '95%', label: 'satisfaction' },
  ];

  submit(): void {
    this.submitted = true;
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
EOF
ok "Login"

# ============================================================
# 2. REGISTER — S02
# ============================================================
sec "2/4 — Register (S02)"

cat > src/app/features/auth/register/register.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators, AbstractControl,
} from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { AuthService }  from '../../../core/services/auth.service';

/** Validateur : les deux mots de passe doivent correspondre */
function passwordMatch(c: AbstractControl): Record<string, boolean> | null {
  const pwd  = c.get('motDePasse')?.value;
  const conf = c.get('confirmation')?.value;
  return pwd && conf && pwd !== conf ? { mismatch: true } : null;
}

@Component({
  selector: 'app-register',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex">

  <!-- Panneau gauche illustration -->
  <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-emerald-600 to-teal-800
              items-center justify-center p-12 relative overflow-hidden">
    <div class="absolute inset-0 opacity-10"
         style="background-image:linear-gradient(rgba(255,255,255,1) 1px,transparent 1px),
                linear-gradient(90deg,rgba(255,255,255,1) 1px,transparent 1px);
                background-size:40px 40px"></div>

    <div class="relative z-10 text-center max-w-sm">
      <!-- Illustration SVG parcours -->
      <svg width="280" height="240" viewBox="0 0 280 240" fill="none"
           xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="mx-auto mb-8">
        <!-- Chemin d'apprentissage -->
        <path d="M40 200 Q80 160 120 120 Q160 80 200 60 Q230 45 250 40"
              stroke="white" stroke-width="3" stroke-dasharray="8 6" opacity="0.4"
              stroke-linecap="round"/>
        <!-- Étapes du parcours -->
        <!-- Étape 1 -->
        <circle cx="60" cy="185" r="24" fill="white" opacity="0.15"/>
        <circle cx="60" cy="185" r="18" fill="white" opacity="0.2"/>
        <text x="60" y="191" text-anchor="middle" font-size="18" aria-hidden="true">🌱</text>
        <!-- Étape 2 -->
        <circle cx="130" cy="120" r="24" fill="white" opacity="0.15"/>
        <circle cx="130" cy="120" r="18" fill="white" opacity="0.2"/>
        <text x="130" y="126" text-anchor="middle" font-size="18" aria-hidden="true">⚡</text>
        <!-- Étape 3 -->
        <circle cx="200" cy="70" r="24" fill="white" opacity="0.15"/>
        <circle cx="200" cy="70" r="18" fill="white" opacity="0.2"/>
        <text x="200" y="76" text-anchor="middle" font-size="18" aria-hidden="true">🚀</text>
        <!-- Trophée final -->
        <circle cx="255" cy="40" r="28" fill="#f59e0b" opacity="0.9"/>
        <text x="255" y="47" text-anchor="middle" font-size="22" aria-hidden="true">🏆</text>
        <!-- Labels -->
        <rect x="15" y="210" width="90" height="22" rx="11" fill="white" opacity="0.15"/>
        <text x="60" y="225" text-anchor="middle" font-size="10" fill="white" opacity="0.8">Débutant</text>
        <rect x="88" y="145" width="84" height="22" rx="11" fill="white" opacity="0.15"/>
        <text x="130" y="160" text-anchor="middle" font-size="10" fill="white" opacity="0.8">Intermédiaire</text>
        <rect x="162" y="95" width="76" height="22" rx="11" fill="white" opacity="0.15"/>
        <text x="200" y="110" text-anchor="middle" font-size="10" fill="white" opacity="0.8">Avancé</text>
        <!-- XP floating -->
        <rect x="30" y="50" width="60" height="24" rx="12" fill="white" opacity="0.2"/>
        <text x="60" y="66" text-anchor="middle" font-size="11" fill="white" font-weight="bold">+200 XP</text>
        <!-- Streak -->
        <rect x="185" y="155" width="75" height="24" rx="12" fill="white" opacity="0.2"/>
        <text x="222" y="171" text-anchor="middle" font-size="11" fill="white">🔥 9 jours</text>
      </svg>

      <h2 class="text-2xl font-bold text-white mb-3">Votre parcours commence ici</h2>
      <p class="text-emerald-200 text-sm leading-relaxed">
        Rejoignez 247 apprenants qui développent leurs compétences tech avec MbemNova.
        Formations certifiantes, paiement en tranches.
      </p>

      <!-- Avantages -->
      <div class="mt-8 space-y-3 text-left">
        @for (av of avantages; track av) {
          <div class="flex items-center gap-3">
            <div class="w-5 h-5 rounded-full bg-white/20 flex items-center justify-center shrink-0">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" aria-hidden="true">
                <polyline points="20 6 9 17 4 12"/>
              </svg>
            </div>
            <p class="text-sm text-emerald-100">{{ av }}</p>
          </div>
        }
      </div>
    </div>
  </div>

  <!-- Formulaire -->
  <div class="flex-1 flex items-start justify-center p-6 sm:p-10 overflow-y-auto py-10">
    <div class="w-full max-w-sm animate-fade-up">

      <!-- Logo -->
      <a routerLink="/" class="inline-flex items-center gap-2.5 mb-8 group">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" aria-hidden="true"
             class="group-hover:scale-105 transition-transform">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5"
                stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-xl text-slate-900">
          Mbem<span class="text-blue-600">Nova</span>
        </span>
      </a>

      <h1 class="text-2xl font-black text-slate-900 mb-1" style="font-family:var(--font);">
        Créer votre compte
      </h1>
      <p class="text-slate-500 text-sm mb-8">
        Gratuit. Aucune carte bancaire requise.
      </p>

      <!-- Bannière code parrainage -->
      @if (referralCode()) {
        <div class="flex items-center gap-3 bg-green-50 border border-green-200
                    rounded-xl px-4 py-3 mb-6 animate-fade-up">
          <div class="w-8 h-8 rounded-lg bg-green-100 flex items-center justify-center shrink-0">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.5" aria-hidden="true">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <div>
            <p class="text-sm font-semibold text-green-800">Code parrainage appliqué !</p>
            <p class="text-xs text-green-600">Vous et votre parrain recevrez des bonus.</p>
          </div>
        </div>
      }

      <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">

        <!-- Prénom -->
        <div>
          <label for="prenom" class="label">Prénom</label>
          <input id="prenom" type="text" formControlName="prenom"
                 autocomplete="given-name" placeholder="Jean-Paul"
                 [class]="'input ' + (touched('prenom') && f['prenom'].invalid ? 'input-error' : '')">
          @if (touched('prenom') && f['prenom'].hasError('required')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Prénom requis
            </p>
          }
          @if (touched('prenom') && f['prenom'].hasError('minlength')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              2 caractères minimum
            </p>
          }
        </div>

        <!-- Email -->
        <div>
          <label for="reg-email" class="label">Adresse email</label>
          <input id="reg-email" type="email" formControlName="email"
                 autocomplete="email" placeholder="vous@example.com"
                 [class]="'input ' + (touched('email') && f['email'].invalid ? 'input-error' : '')">
          @if (touched('email') && f['email'].hasError('required')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Email requis
            </p>
          }
          @if (touched('email') && f['email'].hasError('email')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Format email invalide
            </p>
          }
        </div>

        <!-- Mot de passe -->
        <div>
          <label for="reg-pwd" class="label">Mot de passe</label>
          <div class="relative">
            <input id="reg-pwd" [type]="showPwd() ? 'text' : 'password'"
                   formControlName="motDePasse"
                   autocomplete="new-password" placeholder="8 caractères minimum"
                   [class]="'input pr-11 ' + (touched('motDePasse') && f['motDePasse'].invalid ? 'input-error' : '')">
            <button type="button" (click)="showPwd.set(!showPwd())"
                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400
                           hover:text-slate-600 transition-colors"
                    [attr.aria-label]="showPwd() ? 'Masquer' : 'Afficher'">
              @if (!showPwd()) {
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              } @else {
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              }
            </button>
          </div>
          <!-- Indicateur force mot de passe -->
          @if (f['motDePasse'].value) {
            <div class="mt-2">
              <div class="flex gap-1">
                @for (i of [1,2,3,4]; track i) {
                  <div [class]="'h-1 flex-1 rounded-full transition-colors ' + strengthColor(i)"></div>
                }
              </div>
              <p [class]="'text-xs mt-1 ' + strengthTextColor()">
                {{ strengthLabel() }}
              </p>
            </div>
          }
          @if (touched('motDePasse') && f['motDePasse'].hasError('minlength')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              8 caractères minimum
            </p>
          }
        </div>

        <!-- Confirmation -->
        <div>
          <label for="reg-confirm" class="label">Confirmer le mot de passe</label>
          <input id="reg-confirm" type="password" formControlName="confirmation"
                 autocomplete="new-password" placeholder="Retapez votre mot de passe"
                 [class]="'input ' + (touched('confirmation') && form.hasError('mismatch') ? 'input-error' : '')">
          @if (touched('confirmation') && form.hasError('mismatch')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Les mots de passe ne correspondent pas
            </p>
          }
        </div>

        <!-- Consentement politique (S28) -->
        <div>
          <label class="flex items-start gap-2.5 cursor-pointer">
            <input type="checkbox" formControlName="consent"
                   class="w-4 h-4 rounded mt-0.5 text-blue-600 border-slate-300 focus:ring-blue-500 shrink-0">
            <span class="text-sm text-slate-600 leading-relaxed">
              J'accepte la
              <a routerLink="/politique-confidentialite" target="_blank"
                 class="link font-medium">
                politique de confidentialité
              </a>
              et les conditions d'utilisation de MbemNova.
            </span>
          </label>
          @if (submitted && f['consent'].hasError('required')) {
            <p class="field-error mt-1" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Vous devez accepter les conditions pour continuer
            </p>
          }
        </div>

        <!-- Bouton inscription -->
        <button type="submit" [disabled]="loading()"
                class="btn-success w-full py-3 text-base font-semibold mt-1">
          @if (loading()) {
            <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24"
                 fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
            Création du compte…
          } @else {
            Créer mon compte gratuit
          }
        </button>
      </form>

      <p class="text-center text-sm text-slate-500 mt-6">
        Déjà inscrit ?
        <a routerLink="/auth/connexion" class="link font-semibold ml-1">Se connecter</a>
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
  readonly showPwd     = signal(false);
  readonly referralCode = signal('');
  submitted             = false;

  readonly form = this.#fb.nonNullable.group(
    {
      prenom:       ['', [Validators.required, Validators.minLength(2)]],
      email:        ['', [Validators.required, Validators.email]],
      motDePasse:   ['', [Validators.required, Validators.minLength(8)]],
      confirmation: ['', Validators.required],
      consent:      [false, Validators.requiredTrue],
    },
    { validators: passwordMatch },
  );

  get f() { return this.form.controls; }

  readonly avantages = [
    'Accès partiel gratuit dès l\'inscription',
    'Paiement en tranches adapté',
    'Certificat officiel vérifiable',
    'Communauté d\'apprenants active',
  ];

  ngOnInit(): void {
    const code = this.#route.snapshot.queryParams['ref'] ?? '';
    if (code) {
      this.referralCode.set(code);
      this.form.patchValue({ prenom: '' }); // Déclenche la détection
    }
  }

  touched(field: string): boolean {
    return this.submitted || !!this.form.get(field)?.touched;
  }

  // Force du mot de passe
  get pwdStrength(): number {
    const v = this.f['motDePasse'].value;
    if (!v) return 0;
    let score = 0;
    if (v.length >= 8)  score++;
    if (v.length >= 12) score++;
    if (/[A-Z]/.test(v) && /[a-z]/.test(v)) score++;
    if (/[0-9]/.test(v) || /[^A-Za-z0-9]/.test(v)) score++;
    return score;
  }

  strengthColor(i: number): string {
    const s = this.pwdStrength;
    if (s >= i) {
      if (s <= 1) return 'bg-red-400';
      if (s <= 2) return 'bg-amber-400';
      if (s <= 3) return 'bg-blue-400';
      return 'bg-green-500';
    }
    return 'bg-slate-200';
  }

  strengthLabel(): string {
    const labels = ['', 'Faible', 'Moyen', 'Bon', 'Fort'];
    return labels[this.pwdStrength] ?? '';
  }

  strengthTextColor(): string {
    const s = this.pwdStrength;
    if (s <= 1) return 'text-red-500';
    if (s <= 2) return 'text-amber-500';
    if (s <= 3) return 'text-blue-500';
    return 'text-green-600';
  }

  submit(): void {
    this.submitted = true;
    if (this.form.invalid) return;
    this.loading.set(true);

    const { prenom, email, motDePasse } = this.form.getRawValue();
    const code = this.referralCode();

    this.#auth.register({
      prenom, email, motDePasse,
      ...(code ? { referralCode: code } : {}),
    }).subscribe({
      next: () => {
        this.loading.set(false);
        this.#auth.redirectToDashboard();
      },
      error: () => { this.loading.set(false); },
    });
  }
}
EOF
ok "Register"

# ============================================================
# 3. FORGOT PASSWORD — S27 étape 1
# ============================================================
sec "3/4 — ForgotPassword (S27 étape 1)"

cat > src/app/features/auth/forgot-password/forgot-password.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject, signal,
} from '@angular/core';
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

    <!-- Logo -->
    <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" aria-hidden="true"
           class="group-hover:scale-105 transition-transform">
        <circle cx="18" cy="18" r="18" fill="#2563eb"/>
        <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5"
              stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
      </svg>
      <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
    </a>

    @if (!sent()) {
      <!-- Formulaire -->
      <div class="text-center mb-8">
        <!-- Illustration cadenas -->
        <div class="w-20 h-20 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-5">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#2563eb"
               stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            <circle cx="12" cy="16" r="1.5" fill="#2563eb"/>
          </svg>
        </div>
        <h1 class="text-2xl font-black text-slate-900 mb-2" style="font-family:var(--font);">
          Mot de passe oublié ?
        </h1>
        <p class="text-slate-500 text-sm leading-relaxed">
          Entrez votre email. Nous vous enverrons un lien pour réinitialiser votre mot de passe.
        </p>
      </div>

      <div class="card p-6">
        <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">
          <div>
            <label for="fp-email" class="label">Adresse email</label>
            <input id="fp-email" type="email" formControlName="email"
                   autocomplete="email" placeholder="vous@example.com"
                   [class]="'input ' + (submitted && form.get('email')?.invalid ? 'input-error' : '')">
            @if (submitted && form.get('email')?.hasError('required')) {
              <p class="field-error" role="alert">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                Email requis
              </p>
            }
            @if (submitted && form.get('email')?.hasError('email')) {
              <p class="field-error" role="alert">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                Format email invalide
              </p>
            }
          </div>

          <button type="submit" [disabled]="loading()"
                  class="btn-primary w-full py-3 font-semibold">
            @if (loading()) {
              <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24"
                   fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
              </svg>
              Envoi en cours…
            } @else {
              Envoyer le lien
            }
          </button>
        </form>
      </div>
    }

    @if (sent()) {
      <!-- État succès — message neutre anti-énumération -->
      <div class="card p-10 text-center animate-scale-in">
        <div class="w-20 h-20 rounded-full bg-green-100 flex items-center
                    justify-center mx-auto mb-5">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#16a34a"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07
                     19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72
                     12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27
                     a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
          </svg>
        </div>
        <h2 class="text-xl font-bold text-slate-900 mb-2">Email envoyé !</h2>
        <p class="text-sm text-slate-500 leading-relaxed mb-2">
          Si un compte existe avec cette adresse, vous recevrez un lien de
          réinitialisation dans quelques minutes.
        </p>
        <p class="text-xs text-slate-400 mb-8">
          Vérifiez aussi vos spams si vous ne voyez rien.
        </p>
        <a routerLink="/auth/connexion" class="btn-secondary w-full justify-center">
          Retour à la connexion
        </a>
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

  readonly loading  = signal(false);
  readonly sent     = signal(false);
  submitted         = false;

  readonly form = this.#fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
  });

  submit(): void {
    this.submitted = true;
    if (this.form.invalid) return;
    this.loading.set(true);

    this.#api.post('/auth/reset-password', this.form.getRawValue()).subscribe({
      next:  () => { this.loading.set(false); this.sent.set(true); },
      // Message identique qu'il existe ou non — anti-énumération
      error: () => { this.loading.set(false); this.sent.set(true); },
    });
  }
}
EOF
ok "ForgotPassword"

# ============================================================
# 4. RESET PASSWORD — S27 étape 2
# ============================================================
sec "4/4 — ResetPassword (S27 étape 2)"

cat > src/app/features/auth/reset-password/reset-password.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject, signal, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators, AbstractControl,
} from '@angular/forms';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { ApiService }   from '../../../core/services/api.service';
import { ToastService } from '../../../core/services/toast.service';

function passwordMatch(c: AbstractControl): Record<string, boolean> | null {
  const pwd  = c.get('nouveauMotDePasse')?.value;
  const conf = c.get('confirmation')?.value;
  return pwd && conf && pwd !== conf ? { mismatch: true } : null;
}

@Component({
  selector: 'app-reset-password',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex items-center justify-center p-4">
  <div class="w-full max-w-sm animate-fade-up">

    <!-- Logo -->
    <a routerLink="/" class="inline-flex items-center gap-2.5 mb-10 group">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" aria-hidden="true"
           class="group-hover:scale-105 transition-transform">
        <circle cx="18" cy="18" r="18" fill="#2563eb"/>
        <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5"
              stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
      </svg>
      <span class="font-bold text-xl text-slate-900">Mbem<span class="text-blue-600">Nova</span></span>
    </a>

    @if (!tokenValid()) {
      <!-- Token invalide ou expiré -->
      <div class="card p-8 text-center">
        <div class="w-16 h-16 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-4">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/>
            <line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
        </div>
        <h2 class="font-bold text-slate-900 mb-2">Lien expiré ou invalide</h2>
        <p class="text-sm text-slate-500 mb-6">
          Ce lien de réinitialisation a expiré (valide 1 heure) ou est invalide.
          Veuillez faire une nouvelle demande.
        </p>
        <a routerLink="/auth/mot-de-passe-oublie" class="btn-primary w-full justify-center">
          Nouvelle demande
        </a>
      </div>
    }

    @if (tokenValid() && !done()) {
      <!-- Formulaire -->
      <div class="text-center mb-8">
        <div class="w-20 h-20 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-5">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#2563eb"
               stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/>
          </svg>
        </div>
        <h1 class="text-2xl font-black text-slate-900 mb-2" style="font-family:var(--font);">
          Nouveau mot de passe
        </h1>
        <p class="text-slate-500 text-sm">
          Choisissez un mot de passe sécurisé d'au moins 8 caractères.
        </p>
      </div>

      <div class="card p-6">
        <form [formGroup]="form" (ngSubmit)="submit()" novalidate class="space-y-4">

          <!-- Nouveau mot de passe -->
          <div>
            <label for="new-pwd" class="label">Nouveau mot de passe</label>
            <div class="relative">
              <input id="new-pwd" [type]="showPwd() ? 'text' : 'password'"
                     formControlName="nouveauMotDePasse"
                     autocomplete="new-password" placeholder="8 caractères minimum"
                     [class]="'input pr-11 ' + (submitted && form.get('nouveauMotDePasse')?.invalid ? 'input-error' : '')">
              <button type="button" (click)="showPwd.set(!showPwd())"
                      class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400
                             hover:text-slate-600 transition-colors"
                      [attr.aria-label]="showPwd() ? 'Masquer' : 'Afficher'">
                @if (!showPwd()) {
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                } @else {
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                }
              </button>
            </div>
            @if (submitted && form.get('nouveauMotDePasse')?.hasError('minlength')) {
              <p class="field-error" role="alert">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                8 caractères minimum
              </p>
            }
          </div>

          <!-- Confirmation -->
          <div>
            <label for="new-confirm" class="label">Confirmer le mot de passe</label>
            <input id="new-confirm" type="password" formControlName="confirmation"
                   autocomplete="new-password" placeholder="Retapez le mot de passe"
                   [class]="'input ' + (submitted && form.hasError('mismatch') ? 'input-error' : '')">
            @if (submitted && form.hasError('mismatch')) {
              <p class="field-error" role="alert">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                Les mots de passe ne correspondent pas
              </p>
            }
          </div>

          <button type="submit" [disabled]="loading()"
                  class="btn-primary w-full py-3 font-semibold">
            @if (loading()) {
              <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24"
                   fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
              </svg>
              Enregistrement…
            } @else {
              Enregistrer le mot de passe
            }
          </button>
        </form>
      </div>
    }

    @if (done()) {
      <!-- Succès -->
      <div class="card p-10 text-center animate-scale-in">
        <div class="w-20 h-20 rounded-full bg-green-100 flex items-center
                    justify-center mx-auto mb-5">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#16a34a"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        </div>
        <h2 class="text-xl font-bold text-slate-900 mb-2">Mot de passe mis à jour !</h2>
        <p class="text-sm text-slate-500 mb-8">
          Votre mot de passe a été changé avec succès. Toutes vos sessions ont été déconnectées.
        </p>
        <a routerLink="/auth/connexion" class="btn-primary w-full justify-center">
          Se connecter
        </a>
      </div>
    }
  </div>
</div>
  `,
})
export class ResetPasswordComponent implements OnInit {
  readonly #api    = inject(ApiService);
  readonly #toast  = inject(ToastService);
  readonly #route  = inject(ActivatedRoute);
  readonly #router = inject(Router);
  readonly #fb     = inject(FormBuilder);

  readonly loading    = signal(false);
  readonly done       = signal(false);
  readonly tokenValid = signal(false);
  readonly showPwd    = signal(false);
  submitted           = false;
  #token              = '';

  readonly form = this.#fb.nonNullable.group(
    {
      nouveauMotDePasse: ['', [Validators.required, Validators.minLength(8)]],
      confirmation:      ['', Validators.required],
    },
    { validators: passwordMatch },
  );

  ngOnInit(): void {
    this.#token = this.#route.snapshot.queryParams['token'] ?? '';
    this.tokenValid.set(!!this.#token);
  }

  submit(): void {
    this.submitted = true;
    if (this.form.invalid || !this.#token) return;
    this.loading.set(true);

    const { nouveauMotDePasse, confirmation } = this.form.getRawValue();

    this.#api.post('/auth/new-password', {
      token: this.#token,
      nouveauMotDePasse,
      confirmation,
    }).subscribe({
      next: () => {
        this.loading.set(false);
        this.done.set(true);
        this.#toast.success('Mot de passe mis à jour !');
      },
      error: () => { this.loading.set(false); },
    });
  }
}
EOF
ok "ResetPassword"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 04 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  Login           (S03 · illustration SVG · redirect par rôle)"
echo -e "  ${G}✓${N}  Register        (S02 · parrainage URL · force mot de passe)"
echo -e "  ${G}✓${N}  ForgotPassword  (S27-1 · anti-énumération · état succès)"
echo -e "  ${G}✓${N}  ResetPassword   (S27-2 · token validé · sessions révoquées)"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng05_public_pages.sh${N}"
echo ""
