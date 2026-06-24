import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { ReferralResponse } from '../../../core/models';
import { MOCK_REFERRAL } from '../../../core/services/mock.data';
import { forkJoin } from 'rxjs';

@Component({
  selector: 'app-referral',
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
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Parrainer un ami</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl space-y-6">

    @if (loading()) {
      <div class="card p-8"><div class="shimmer h-40 rounded-xl"></div></div>
    }

    @if (!loading() && referral()) {

      <!-- Hero parrainage -->
      <div class="card bg-gradient-to-br from-purple-600 to-blue-600 p-8 text-white overflow-hidden relative animate-fade-up">
        <div class="absolute inset-0 opacity-10"
             style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:24px 24px" aria-hidden="true"></div>
        <div class="relative">
          <div class="text-4xl mb-3" aria-hidden="true">🤝</div>
          <h2 class="text-xl font-black mb-2">Invitez vos amis, gagnez ensemble</h2>
          <p class="text-purple-100 text-sm leading-relaxed mb-6">
            Quand votre ami termine son premier module,
            vous recevez tous les deux <strong>200 XP</strong> bonus.
          </p>

          <!-- Lien parrainage -->
          <div class="bg-white/15 backdrop-blur-sm rounded-xl p-4 mb-4">
            <p class="text-xs text-purple-200 mb-2 font-medium uppercase tracking-wide">Votre lien unique</p>
            <div class="flex items-center gap-2">
              <code class="text-sm font-mono text-white flex-1 truncate">
                {{ referral()!.lienParrainage }}
              </code>
              <button (click)="copyLink()" class="btn bg-white/20 hover:bg-white/30 text-white border border-white/30 btn-sm shrink-0">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                Copier
              </button>
            </div>
          </div>

          <!-- Partage WhatsApp -->
          <a [href]="whatsappUrl()" target="_blank" rel="noopener"
             class="btn bg-green-500 hover:bg-green-400 text-white w-full justify-center">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="white" aria-hidden="true">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
              <path d="M11.999 2C6.477 2 2 6.477 2 11.999c0 1.873.518 3.623 1.418 5.12L2 22l5.064-1.387A10 10 0 0 0 12 22c5.523 0 10-4.477 10-10S17.523 2 11.999 2z"/>
            </svg>
            Partager sur WhatsApp
          </a>
        </div>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-3 gap-4 animate-fade-up delay-75">
        @for (stat of stats(); track stat.label) {
          <div class="card p-4 text-center">
            <p class="text-2xl font-black text-slate-900">{{ stat.value }}</p>
            <p class="text-xs text-slate-500 mt-0.5">{{ stat.label }}</p>
          </div>
        }
      </div>

      <!-- Filleuls -->
      @if (referral()!.filleuls.length > 0) {
        <div class="card p-5 animate-fade-up delay-100">
          <h3 class="font-semibold text-slate-900 mb-4">Mes filleuls</h3>
          <div class="space-y-3">
            @for (f of referral()!.filleuls; track f.email) {
              <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                <div class="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0"
                     [class]="f.estActif ? 'bg-green-600' : 'bg-slate-400'">
                  {{ f.prenom.charAt(0) }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-slate-900">{{ f.prenom }}</p>
                  <p class="text-xs text-slate-400">{{ f.email }} · Rejoint {{ formatDate(f.rejointLe) }}</p>
                </div>
                <span [class]="f.estActif ? 'badge-green' : 'badge-slate'">
                  {{ f.estActif ? '✓ Actif' : 'En attente' }}
                </span>
              </div>
            }
          </div>
        </div>
      }

      <!-- Comment ça marche -->
      <div class="card p-5 animate-fade-up delay-150">
        <h3 class="font-semibold text-slate-900 mb-4">Comment ça marche ?</h3>
        <div class="space-y-4">
          @for (step of steps; track step.n) {
            <div class="flex gap-3">
              <div class="w-7 h-7 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">{{ step.n }}</div>
              <div>
                <p class="text-sm font-medium text-slate-900">{{ step.title }}</p>
                <p class="text-xs text-slate-500 leading-relaxed">{{ step.desc }}</p>
              </div>
            </div>
          }
        </div>
      </div>
    }
  </div>
</div>
  `,
})
export class ReferralComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);

  readonly referral = signal<ReferralResponse | null>(MOCK_REFERRAL);
  readonly loading  = signal(true);

  readonly steps = [
    { n: 1, title: 'Partagez votre lien', desc: 'Envoyez votre lien unique par WhatsApp, email ou réseaux sociaux.' },
    { n: 2, title: 'Votre ami s\'inscrit', desc: 'Il crée son compte gratuitement en cliquant sur votre lien.' },
    { n: 3, title: 'Il termine un module', desc: 'Dès qu\'il complète son premier module, la récompense se déclenche.' },
    { n: 4, title: 'Vous gagnez tous les deux', desc: 'Vous recevez chacun 200 XP bonus crédités automatiquement.' },
  ];

  readonly stats = () => [
    { value: this.referral()?.nbFilleulsInvites ?? 0,   label: 'invités' },
    { value: this.referral()?.nbFilleulsActifs ?? 0,    label: 'actifs' },
    { value: (this.referral()?.xpGagneParrainage ?? 0) + ' XP', label: 'gagnés' },
  ];

ngOnInit(): void {
  forkJoin({
    lien:     this.#svc.getMonLien(),
    filleuls: this.#svc.getMesFilleuls(),
  }).subscribe({
    next: ({ lien, filleuls }) => {
      if (lien.success && lien.data && filleuls.success && filleuls.data) {
        this.referral.set({
          lienParrainage:    lien.data.lienParrainage,
          codeParrainage:    lien.data.codeParrainage,
          nbFilleulsInvites: filleuls.data.length,
          nbFilleulsActifs:  filleuls.data.filter(f => f.estActif).length,
          xpGagneParrainage: filleuls.data.filter(f => f.estActif).length * 200,
          filleuls:          filleuls.data,
        });
      }
      this.loading.set(false);
    },
    error: () => { this.loading.set(false); },
  });
}

  copyLink(): void {
    const link = this.referral()?.lienParrainage ?? '';
    navigator.clipboard.writeText(link).then(() =>
      this.#toast.success('Lien copié !', 'Collez-le sur WhatsApp pour inviter vos amis.')
    );
  }

  whatsappUrl(): string {
    const link = this.referral()?.lienParrainage ?? '';
    const text = encodeURIComponent(`Je me forme à la tech avec MbemNova 🚀 Commence avec moi et on débloque tous les deux un bonus : ${link}`);
    return `https://wa.me/?text=${text}`;
  }

  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  }
}
