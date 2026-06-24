import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit, OnDestroy,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { DrawResponse, TicketResponse } from '../../../core/models';
import { MOCK_DRAW } from '../../../core/services/mock.data';

@Component({
  selector: 'app-draw',
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
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Tirage au sort</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-xl space-y-6">

    @if (!loading() && draw()) {

      <!-- Carte principale tirage -->
      <div class="card overflow-hidden animate-fade-up">
        <div class="bg-gradient-to-br from-amber-400 to-orange-600 p-8 text-center relative overflow-hidden">
          <div class="absolute inset-0 opacity-10"
               style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px" aria-hidden="true"></div>
          <div class="relative">
            <div class="text-5xl mb-3" aria-hidden="true">🎟️</div>
            <h2 class="text-2xl font-black text-white mb-1">Tirage du mois</h2>
            <p class="text-amber-100 text-sm">{{ draw()!.dateDrawFormatee }}</p>
          </div>
        </div>

        <div class="p-6">
          <!-- Formation à gagner -->
          <div class="bg-slate-50 rounded-2xl p-5 mb-6">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Formation à gagner</p>
            <div class="flex items-center gap-4">
              <div class="w-14 h-14 rounded-xl bg-blue-100 flex items-center justify-center text-2xl shrink-0" aria-hidden="true">🏆</div>
              <div>
                <h3 class="font-bold text-slate-900">{{ draw()!.formationGagnanteTitre }}</h3>
                <p class="text-sm text-slate-500">Valeur : <span class="font-bold text-green-600">{{ draw()!.formationGagnantePrix }}</span></p>
              </div>
            </div>
          </div>

          <!-- Stats tirage -->
          <div class="grid grid-cols-2 gap-4 mb-6">
            <div class="bg-slate-50 rounded-xl p-4 text-center">
              <p class="text-2xl font-black text-slate-900">{{ draw()!.nbTicketsVendus }}</p>
              <p class="text-xs text-slate-500">participants</p>
            </div>
            <div class="bg-slate-50 rounded-xl p-4 text-center">
              <p class="text-2xl font-black text-amber-600">{{ draw()!.prixTicketFcfa   }} FCFA</p>
              <!-- <p class="text-2xl font-black text-amber-600">{{ draw()!.prixTicketFcfa | number:'1.0-0' }} FCFA</p> -->
              <!-- <p class="text-2xl font-black text-amber-600">{{ draw()!.prixTicketFcfa | number:'1.0-0' }} FCFA</p> -->
              <p class="text-xs text-slate-500">par ticket</p>
            </div>
          </div>

          <!-- Ticket acheté -->
          @if (monTicket()) {
            <div class="bg-green-50 border border-green-200 rounded-2xl p-5 mb-4 text-center animate-scale-in">
              <p class="text-3xl mb-2" aria-hidden="true">🎟️</p>
              <p class="font-bold text-green-900 mb-1">Ticket acheté !</p>
              <code class="text-xl font-black font-mono text-green-700">{{ monTicket()!.numero }}</code>
              <p class="text-xs text-green-600 mt-1">Votre numéro de participation</p>
            </div>
          }

          <!-- CTA achat -->
          @if (!monTicket() && draw()!.statut === 'OUVERT') {
            <button (click)="acheterTicket()" [disabled]="buying()"
                    class="btn-primary w-full justify-center py-3.5 text-base font-semibold">
              @if (buying()) {
                <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                Achat en cours…
              } @else {
                Acheter un ticket — {{ draw()!.prixTicketFcfa   }} FCFA
                <!-- Acheter un ticket — {{ draw()!.prixTicketFcfa | number:'1.0-0' }} FCFA -->
              }
            </button>
            <p class="text-xs text-slate-400 text-center mt-2">
              Paiement sécurisé · Ticket immédiatement disponible
            </p>
          }

          @if (draw()!.statut === 'CLOTURE') {
            <div class="bg-slate-100 rounded-xl p-4 text-center">
              <p class="text-sm font-medium text-slate-600">Les inscriptions sont clôturées. Le tirage est en cours.</p>
            </div>
          }

          @if (draw()!.statut === 'GAGNANT_SELECTIONNE') {
            <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 text-center">
              <p class="text-2xl mb-1" aria-hidden="true">🎉</p>
              <p class="font-bold text-amber-900">Gagnant : {{ draw()!.gagnantPrenom }}</p>
              <p class="text-xs text-amber-600 mt-1">Le prochain tirage sera annoncé bientôt !</p>
            </div>
          }
        </div>
      </div>

      <!-- Comment ça marche -->
      <div class="card p-5 animate-fade-up delay-75">
        <h3 class="font-semibold text-slate-900 mb-4">Comment ça marche ?</h3>
        <div class="space-y-3">
          @for (s of steps; track s.n) {
            <div class="flex gap-3">
              <div class="w-6 h-6 rounded-full bg-amber-500 text-white text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">{{ s.n }}</div>
              <p class="text-sm text-slate-700 leading-relaxed">{{ s.text }}</p>
            </div>
          }
        </div>
      </div>
    }
  </div>
</div>
  `,
})
export class DrawComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);

  readonly draw     = signal<DrawResponse | null>(MOCK_DRAW);
  readonly monTicket= signal<TicketResponse | null>(null);
  readonly loading  = signal(true);
  readonly buying   = signal(false);

  readonly steps = [
    { n: 1, text: 'Achetez un ticket au prix indiqué par paiement sécurisé.' },
    { n: 2, text: 'Vous recevez un numéro unique de participation.' },
    { n: 3, text: 'Le tirage a lieu le 1er du mois. 1 gagnant principal + 2 consolations.' },
    { n: 4, text: 'Le gagnant reçoit sa formation gratuitement et est annoncé sur la plateforme.' },
  ];

  ngOnInit(): void {
    this.#svc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  acheterTicket(): void {
    const d = this.draw();
    if (!d) return;
    this.buying.set(true);
    this.#svc.acheterTicket(d.id).subscribe({
      next: r => {
        this.buying.set(false);
        if (r.success && r.data) {
          this.monTicket.set(r.data);
          this.draw.update(dr => dr ? { ...dr, nbTicketsVendus: dr.nbTicketsVendus + 1 } : dr);
          this.#toast.success(`Ticket acheté ! N° ${r.data.numero}`, 'Bonne chance pour le tirage !');
        }
      },
      error: () => { this.buying.set(false); },
    });
  }
}
