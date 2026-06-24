import {
  ChangeDetectionStrategy, Component, inject,
  signal, input, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import type { CertificatResponse } from '../../../core/models';

@Component({
  selector: 'app-certificate-verify',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50 flex items-center justify-center p-4 py-16">
  <div class="w-full max-w-lg animate-fade-up">

    @if (loading()) {
      <div class="card p-10 text-center">
        <div class="shimmer w-20 h-20 rounded-full mx-auto mb-6"></div>
        <div class="shimmer h-6 rounded w-2/3 mx-auto mb-3"></div>
        <div class="shimmer h-4 rounded w-1/2 mx-auto"></div>
      </div>
    }

    @if (!loading() && cert()) {
      <div class="card overflow-hidden">
        <!-- En-tête colorée -->
        <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-8 text-center">
          <!-- Illustration certificat -->
          <div class="flex justify-center mb-4">
            <svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
              <circle cx="40" cy="40" r="40" fill="rgba(255,255,255,0.2)"/>
              <circle cx="40" cy="32" r="18" fill="white" opacity="0.9"/>
              <path d="M31 32l6 6 12-12" stroke="#d97706" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M27 56l-5 10 18-6 18 6-5-10" fill="white" opacity="0.7"/>
              <circle cx="40" cy="32" r="14" stroke="white" stroke-width="2" opacity="0.5"/>
            </svg>
          </div>
          <h1 class="text-2xl font-black text-white mb-1">Certificat Valide ✓</h1>
          <p class="text-amber-100 text-sm">Ce certificat est authentique et vérifié par MbemNova</p>
        </div>

        <!-- Détails -->
        <div class="p-8">
          <div class="text-center mb-8">
            <p class="text-xs text-slate-500 uppercase tracking-wide mb-1">Formation certifiée</p>
            <h2 class="text-xl font-bold text-slate-900">{{ cert()!.coursTitre ?? 'Formation MbemNova' }}</h2>
          </div>

          <div class="space-y-4">
            <div class="flex items-center justify-between py-3 border-b border-slate-100">
              <span class="text-sm text-slate-500">Code de vérification</span>
              <code class="text-sm font-mono font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded">
                {{ cert()!.codeVerification }}
              </code>
            </div>
            <div class="flex items-center justify-between py-3 border-b border-slate-100">
              <span class="text-sm text-slate-500">Date d'obtention</span>
              <span class="text-sm font-semibold text-slate-900">
                {{ cert()!.dateEmission   }}
                <!-- {{ cert()!.dateEmission | date:'dd MMMM yyyy':'':'fr' }} -->
              </span>
            </div>
            <div class="flex items-center justify-between py-3">
              <span class="text-sm text-slate-500">Délivré par</span>
              <span class="text-sm font-semibold text-blue-700">MbemNova</span>
            </div>
          </div>

          <div class="flex gap-3 mt-8">
            <a [href]="cert()!.lienPdf" target="_blank" rel="noopener"
               class="btn-primary flex-1 justify-center">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Télécharger PDF
            </a>
            <a routerLink="/catalogue" class="btn-secondary flex-1 justify-center">Voir les formations</a>
          </div>
        </div>
      </div>
    }

    @if (!loading() && !cert()) {
      <div class="card p-10 text-center">
        <div class="w-20 h-20 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-5">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
        </div>
        <h2 class="h3 mb-2">Certificat introuvable</h2>
        <p class="text-slate-500 text-sm mb-6">
          Le code de vérification <code class="font-mono bg-slate-100 px-1.5 py-0.5 rounded text-xs">{{ code() }}</code>
          ne correspond à aucun certificat valide.
        </p>
        <a routerLink="/" class="btn-secondary">Retour à l'accueil</a>
      </div>
    }
  </div>
</div>
  `,
})
export class CertificateVerifyComponent implements OnInit {
  readonly code = input<string>('');
  readonly #svc = inject(TalentService);

  readonly cert    = signal<CertificatResponse | null>(null);
  readonly loading = signal(true);

  ngOnInit(): void {
    const c = this.code();
    if (!c || c === 'demo') {
      // Demo : montrer un exemple
      this.cert.set({
        id: 'demo', coursId: 'c-003', codeVerification: 'MBEM-2025-DEMO',
        lienPdf: '#', dateEmission: new Date().toISOString(), coursTitre: 'Python & Data Science',
      });
      this.loading.set(false);
      return;
    }
    this.#svc.verifierCertificat(c).subscribe({
      next: r => { this.cert.set(r.data); this.loading.set(false); },
      error: () => { this.cert.set(null); this.loading.set(false); },
    });
  }
}
