import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-white flex items-center justify-center px-4">
  <div class="text-center max-w-md animate-fade-up">

    <!-- Illustration SVG 404 -->
    <div class="mb-8 flex justify-center">
      <svg width="200" height="160" viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <!-- Fond cercle -->
        <circle cx="100" cy="80" r="70" fill="#eff6ff" opacity="0.8"/>
        <!-- Chiffres 404 -->
        <text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle"
              font-family="DM Sans, system-ui" font-size="52" font-weight="800"
              fill="#1e40af" opacity="0.15">404</text>
        <!-- Personnage perdu -->
        <circle cx="100" cy="68" r="18" fill="#2563eb" opacity="0.9"/>
        <circle cx="93" cy="64" r="3" fill="white"/>
        <circle cx="107" cy="64" r="3" fill="white"/>
        <!-- Bouche -->
        <path d="M93 73 Q100 70 107 73" stroke="white" stroke-width="2" stroke-linecap="round" fill="none"/>
        <!-- Point d'interrogation -->
        <text x="125" y="58" font-size="28" fill="#f59e0b" font-weight="800" font-family="DM Sans">?</text>
        <!-- Corps -->
        <rect x="88" y="88" width="24" height="28" rx="6" fill="#2563eb" opacity="0.8"/>
        <!-- Jambes -->
        <rect x="90" y="114" width="8" height="18" rx="4" fill="#1e40af"/>
        <rect x="102" y="114" width="8" height="18" rx="4" fill="#1e40af"/>
        <!-- Bras levés (perdu) -->
        <path d="M88 96 L72 82" stroke="#2563eb" stroke-width="6" stroke-linecap="round"/>
        <path d="M112 96 L128 82" stroke="#2563eb" stroke-width="6" stroke-linecap="round"/>
        <!-- Étoiles autour -->
        <circle cx="60" cy="45" r="3" fill="#f59e0b"/>
        <circle cx="140" cy="45" r="2" fill="#f59e0b"/>
        <circle cx="55" cy="100" r="2" fill="#93c5fd"/>
        <circle cx="148" cy="95" r="3" fill="#93c5fd"/>
      </svg>
    </div>

    <h1 class="text-6xl font-black text-slate-100 mb-2 leading-none" style="font-family:var(--font);">404</h1>
    <h2 class="text-2xl font-bold text-slate-900 mb-3">Page introuvable</h2>
    <p class="text-slate-500 mb-8 leading-relaxed">
      La page que vous cherchez n'existe pas ou a été déplacée.
      Pas de panique — retournons sur quelque chose de connu !
    </p>

    <div class="flex flex-col xs:flex-row gap-3 justify-center">
      <a routerLink="/" class="btn-primary btn-lg">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        Accueil
      </a>
      <a routerLink="/catalogue" class="btn-secondary btn-lg">Voir le catalogue</a>
    </div>
  </div>
</div>
  `,
})
export class NotFoundComponent {}
