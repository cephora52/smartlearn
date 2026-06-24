import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { CertificatResponse } from '../../../core/models';
import { MOCK_PROFIL } from '../../../core/services/mock.data';

@Component({
  selector: 'app-certificate',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Mes certificats</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-3xl">

    @if (loading()) {
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
        @for (_ of [1,2]; track $index) {
          <div class="card p-6">
            <div class="shimmer h-32 rounded-xl mb-4"></div>
            <div class="shimmer h-4 rounded w-3/4 mb-2"></div>
            <div class="shimmer h-3 rounded w-1/2"></div>
          </div>
        }
      </div>
    }

    @if (!loading() && certs().length === 0) {
      <div class="card p-14 text-center">
        <div class="flex justify-center mb-5">
          <svg width="100" height="100" viewBox="0 0 100 100" fill="none" aria-hidden="true">
            <circle cx="50" cy="50" r="50" fill="#fffbeb"/>
            <circle cx="50" cy="42" r="22" fill="#fde68a"/>
            <circle cx="50" cy="42" r="16" fill="#fbbf24"/>
            <path d="M42 42l6 6 12-12" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M35 66l-6 14 21-7 21 7-6-14" fill="#f59e0b" opacity="0.7"/>
          </svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Aucun certificat pour l'instant</h2>
        <p class="text-sm text-slate-500 mb-6 max-w-xs mx-auto leading-relaxed">
          Terminez un cours complet pour obtenir votre certificat officiel MbemNova.
        </p>
        <a routerLink="/catalogue" class="btn-primary">Découvrir les formations</a>
      </div>
    }

    @if (!loading() && certs().length > 0) {
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
        @for (cert of certs(); track cert.id; let i = $index) {
          <div class="card overflow-hidden group animate-fade-up"
               [style]="'animation-delay:' + (i * 80) + 'ms'">
            <!-- Bannière certificat -->
            <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-6 text-center relative overflow-hidden">
              <div class="absolute inset-0 opacity-10"
                   style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px" aria-hidden="true"></div>
              <svg width="56" height="56" viewBox="0 0 56 56" fill="none" class="mx-auto mb-2" aria-hidden="true">
                <circle cx="28" cy="28" r="28" fill="rgba(255,255,255,0.2)"/>
                <circle cx="28" cy="22" r="14" fill="white" opacity="0.9"/>
                <path d="M22 22l5 5 9-9" stroke="#d97706" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M18 40l-4 10 14-5 14 5-4-10" fill="white" opacity="0.6"/>
              </svg>
              <p class="text-white font-bold text-xs uppercase tracking-wide">Certificat MbemNova</p>
            </div>

            <!-- Détails -->
            <div class="p-5">
              <h3 class="font-bold text-slate-900 mb-1 leading-snug">
                {{ cert.coursTitre ?? 'Formation MbemNova' }}
              </h3>
              <p class="text-xs text-slate-400 mb-4">
                Obtenu le {{ formatDate(cert.dateEmission) }}
              </p>
              <div class="flex items-center gap-2 p-2.5 bg-slate-50 rounded-lg mb-4">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                <code class="text-xs font-mono text-slate-600 flex-1">{{ cert.codeVerification }}</code>
              </div>
              <div class="flex gap-2">
                <a [href]="cert.lienPdf" target="_blank" rel="noopener" class="btn-primary btn-sm flex-1 justify-center">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                  PDF
                </a>
                <a [routerLink]="['/certificat/verifier', cert.codeVerification]"
                   class="btn-secondary btn-sm flex-1 justify-center">
                  Vérifier
                </a>
                <button (click)="share(cert)"
                        class="btn-ghost btn-sm px-3"
                        aria-label="Partager">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
                </button>
              </div>
            </div>
          </div>
        }
      </div>
    }
  </div>
</div>
  `,
})
export class CertificateComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);

  readonly certs   = signal<CertificatResponse[]>(MOCK_PROFIL.certificats);
  readonly loading = signal(true);

  ngOnInit(): void {
    this.#svc.getMe().subscribe({
      next: r => {
        if (r.success && r.data?.certificats?.length) this.certs.set(r.data.certificats);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  share(cert: CertificatResponse): void {
    const url = `${window.location.origin}/certificat/verifier/${cert.codeVerification}`;
    const text = `🏆 J'ai obtenu ma certification "${cert.coursTitre ?? 'MbemNova'}" ! Vérifiez ici : ${url}`;
    if (navigator.share) {
      navigator.share({ title: 'Mon certificat MbemNova', text, url }).catch(() => {});
    } else {
      navigator.clipboard.writeText(text).then(() =>
        this.#toast.success('Lien copié !', 'Partagez votre certificat sur WhatsApp ou LinkedIn.')
      );
    }
  }

  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
  }
}
