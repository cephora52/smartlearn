import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { PaymentService } from '../../../core/services/payment.service';
import { AuthService }    from '../../../core/services/auth.service';
import { ToastService }   from '../../../core/services/toast.service';
import type {
  PaiementResponse, TrancheResponse,
  StatutPaiement, DemanderMoratoireRequest ,
} from '../../../core/models';
import { MOCK_PAIEMENTS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-payment',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- ── EN-TÊTE ────────────────────────────────────────── -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3 mb-1">
        <a routerLink="/app"
           class="text-slate-400 hover:text-slate-600 transition-colors"
           aria-label="Retour au tableau de bord">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
          Mes paiements
        </h1>
      </div>
      <p class="text-slate-500 text-sm ml-8">
        Gérez vos tranches et suivez votre historique de paiement.
      </p>
    </div>
  </div>

  <!-- ── COMPTE SUSPENDU (S18) ──────────────────────────── -->
  @if (isSuspended()) {
    <div class="container py-6">
      <div class="card border-red-200 bg-red-50 p-6 animate-fade-up">
        <div class="flex items-start gap-4">
          <!-- Illustration suspension -->
          <div class="w-14 h-14 rounded-2xl bg-red-100 flex items-center justify-center shrink-0">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" aria-hidden="true">
              <circle cx="12" cy="12" r="10"/>
              <path d="M4.93 4.93l14.14 14.14"/>
            </svg>
          </div>
          <div class="flex-1">
            <h2 class="font-bold text-red-900 mb-1">Accès temporairement suspendu</h2>
            <p class="text-sm text-red-700 leading-relaxed mb-4">
              Votre accès aux cours a été suspendu en raison d'un retard de paiement.
              Votre progression est intégralement sauvegardée — vous reprendrez exactement
              là où vous vous êtes arrêté dès la régularisation.
            </p>
            <div class="flex flex-wrap gap-3">
              <a href="https://wa.me/237600000000?text=Bonjour MbemNova, je souhaite régulariser mon paiement"
                 target="_blank" rel="noopener"
                 class="btn bg-green-600 hover:bg-green-700 text-white btn-sm">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="white" aria-hidden="true">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
                  <path d="M11.999 2C6.477 2 2 6.477 2 11.999c0 1.873.518 3.623 1.418 5.12L2 22l5.064-1.387A10 10 0 0 0 12 22c5.523 0 10-4.477 10-10S17.523 2 11.999 2z"/>
                </svg>
                Contacter MbemNova
              </a>
              <button (click)="openMoratoire(null)"
                      class="btn-secondary btn-sm">
                Demander un délai
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  }

  <!-- ── CONTENU PRINCIPAL ─────────────────────────────── -->
  <div class="container py-6 space-y-6">

    <!-- Skeleton -->
    @if (loading()) {
      <div class="space-y-4">
        @for (_ of [1,2]; track $index) {
          <div class="card p-6">
            <div class="flex gap-4 mb-4">
              <div class="shimmer w-12 h-12 rounded-xl shrink-0"></div>
              <div class="flex-1 space-y-2">
                <div class="shimmer h-4 rounded w-3/4"></div>
                <div class="shimmer h-3 rounded w-1/2"></div>
              </div>
              <div class="shimmer h-6 rounded-full w-20"></div>
            </div>
            <div class="shimmer h-2 rounded-full w-full"></div>
          </div>
        }
      </div>
    }

    <!-- Empty state -->
    @if (!loading() && paiements().length === 0) {
      <div class="card p-14 text-center">
        <div class="flex justify-center mb-5">
          <svg width="100" height="100" viewBox="0 0 100 100" fill="none" aria-hidden="true">
            <circle cx="50" cy="50" r="50" fill="#f0fdf4"/>
            <rect x="20" y="30" width="60" height="40" rx="8" fill="#bbf7d0"/>
            <rect x="20" y="30" width="60" height="16" rx="8" fill="#16a34a"/>
            <rect x="28" y="54" width="20" height="4" rx="2" fill="#86efac"/>
            <rect x="28" y="62" width="14" height="4" rx="2" fill="#86efac"/>
            <circle cx="72" cy="72" r="16" fill="#2563eb"/>
            <path d="M64 72l6 6 12-12" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Aucun paiement enregistré</h2>
        <p class="text-sm text-slate-500 mb-6 max-w-xs mx-auto leading-relaxed">
          Commencez un cours gratuit et débloquez la suite quand vous êtes prêt.
        </p>
        <a routerLink="/catalogue" class="btn-primary">Voir le catalogue</a>
      </div>
    }

    <!-- Liste des paiements -->
    @if (!loading() && paiements().length > 0) {
      @for (p of paiements(); track p.id; let i = $index) {
        <div class="card overflow-hidden animate-fade-up"
             [style]="'animation-delay:' + (i * 60) + 'ms'">

          <!-- En-tête paiement -->
          <div class="p-5 border-b border-slate-100">
            <div class="flex items-start gap-4">
              <!-- Icône mode paiement -->
              <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 '
                            + modeBg(p.mode)" aria-hidden="true">
                {{ modeEmoji(p.mode) }}
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap mb-1">
                  <h2 class="font-bold text-slate-900 text-base">
                    Formation — {{ p.coursId }}
                  </h2>
                  <span [class]="statutBadge(p.statut)">
                    {{ statutLabel(p.statut) }}
                  </span>
                </div>
                <div class="flex flex-wrap items-center gap-3 text-xs text-slate-400">
                  <span>Mode : {{ modeLabel(p.mode) }}</span>
                  @if (p.dateActivation) {
                    <span>Activé le {{ p.dateActivation   }}</span>
                    <!-- <span>Activé le {{ p.dateActivation | date:'dd/MM/yyyy':'':'fr' }}</span> -->
                  }
                </div>
              </div>

              <!-- Montants -->
              <div class="text-right shrink-0">
                <p class="font-black text-slate-900 text-base">{{ p.montantPaye }}</p>
                <p class="text-xs text-slate-400">/ {{ p.montantTotal }}</p>
              </div>
            </div>

            <!-- Barre progression paiement -->
            @if (p.statut === 'PARTIEL') {
              <div class="mt-4">
                <div class="flex justify-between text-xs text-slate-400 mb-1.5">
                  <span>Payé : {{ p.montantPaye }}</span>
                  <span>Total : {{ p.montantTotal }}</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-blue-500"
                       [style.width.%]="paiementPercent(p)"></div>
                </div>
              </div>
            }
          </div>

          <!-- Tranches -->
          @if (p.tranches && p.tranches.length > 0) {
            <div class="p-5">
              <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">
                Échéancier de paiement
              </h3>
              <div class="space-y-2.5">
                @for (t of p.tranches; track t.id; let ti = $index) {
                  <div class="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">

                    <!-- Icône statut tranche -->
                    <div [class]="'w-8 h-8 rounded-lg flex items-center justify-center shrink-0 '
                                  + (t.estPayee ? 'bg-green-100' : isOverdue(t) ? 'bg-red-100' : 'bg-amber-100')"
                         [attr.aria-label]="t.estPayee ? 'Payée' : isOverdue(t) ? 'En retard' : 'À venir'">
                      @if (t.estPayee) {
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                      } @else if (isOverdue(t)) {
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                      } @else {
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                      }
                    </div>

                    <!-- Infos tranche -->
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2">
                        <p class="text-sm font-semibold text-slate-900">
                          Tranche {{ ti + 1 }} — {{ t.montant }}
                        </p>
                        @if (!t.estPayee && isOverdue(t)) {
                          <span class="badge-red text-xs">En retard</span>
                        } @else if (!t.estPayee && isDueSoon(t)) {
                          <span class="badge-amber text-xs">Bientôt</span>
                        }
                      </div>
                      <p class="text-xs text-slate-400">
                        @if (t.estPayee && t.datePaiement) {
                          Payée le {{ t.datePaiement }}
                          <!-- Payée le {{ t.datePaiement | date:'dd/MM/yyyy':'':'fr' }} -->
                        } @else {
                          Échéance : {{ t.echeance   }}
                        }
                      </p>
                    </div>

                    <!-- Badge statut -->
                    @if (t.estPayee) {
                      <span class="badge-green shrink-0">✓ Payée</span>
                    } @else if (isOverdue(t)) {
                      <span class="badge-red shrink-0">Retard</span>
                    } @else {
                      <span class="badge-slate shrink-0">À venir</span>
                    }
                  </div>
                }
              </div>

              <!-- Actions tranche non payée -->
              @if (hasUnpaidTranche(p)) {
                <div class="flex flex-wrap gap-2 mt-4 pt-4 border-t border-slate-100">
                  <button (click)="openMoratoire(p)"
                          class="btn-secondary btn-sm">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                      <circle cx="12" cy="12" r="10"/>
                      <polyline points="12 6 12 12 16 14"/>
                    </svg>
                    Demander un délai
                  </button>
                  <a href="https://wa.me/237600000000"
                     target="_blank" rel="noopener"
                     class="btn-ghost btn-sm text-green-700">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="#16a34a" aria-hidden="true">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
                      <path d="M11.999 2C6.477 2 2 6.477 2 11.999c0 1.873.518 3.623 1.418 5.12L2 22l5.064-1.387A10 10 0 0 0 12 22c5.523 0 10-4.477 10-10S17.523 2 11.999 2z"/>
                    </svg>
                    Contacter MbemNova
                  </a>
                </div>
              }
            </div>
          }
        </div>
      }
    }

    <!-- Bloc informatif paiement cash -->
    <div class="card p-5 bg-blue-50 border-blue-200 animate-fade-up">
      <div class="flex items-start gap-3">
        <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center shrink-0">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
        </div>
        <div>
          <h3 class="font-semibold text-blue-900 text-sm mb-1">
            Comment payer ?
          </h3>
          <p class="text-sm text-blue-700 leading-relaxed">
            Payez en cash, Mobile Money ou virement directement chez MbemNova.
            Notre équipe activera votre accès dans les 30 minutes.
          </p>
          <a href="https://wa.me/237600000000?text=Bonjour, je souhaite payer ma formation"
             target="_blank" rel="noopener"
             class="btn-primary btn-sm mt-3 inline-flex">
            Organiser mon paiement
          </a>
        </div>
      </div>
    </div>

  </div>

  <!-- ── MODAL MORATOIRE (S17) ──────────────────────────── -->
  @if (showMoratoire()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="moratoire-title">

      <!-- Backdrop -->
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm"
           (click)="closeMoratoire()"></div>

      <!-- Modal -->
      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-md
                  animate-scale-in overflow-hidden">

        <!-- En-tête modal -->
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12 6 12 12 16 14"/>
              </svg>
            </div>
            <div>
              <h2 id="moratoire-title" class="font-bold text-slate-900">Demande de délai</h2>
              <p class="text-xs text-slate-500">Moratoire de paiement — S17</p>
            </div>
            <button (click)="closeMoratoire()"
                    class="btn-icon ml-auto text-slate-400 hover:text-slate-600"
                    aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- Corps modal -->
        <div class="p-6">
          <p class="text-sm text-slate-600 leading-relaxed mb-5">
            Notre équipe examinera votre demande et vous répondra sous 24h.
            Votre accès aux cours reste actif pendant l'examen de votre demande.
          </p>

          <form [formGroup]="moratoireForm" (ngSubmit)="submitMoratoire()" novalidate class="space-y-4">

            <!-- Raison -->
            <div>
              <label for="raison" class="label">Raison du délai</label>
              <select id="raison" formControlName="raison" class="input">
                <option value="">Sélectionnez une raison</option>
                <option value="DIFFICULTES_FINANCIERES">Difficultés financières temporaires</option>
                <option value="PROBLEME_SANTE">Problème de santé</option>
                <option value="AUTRE">Autre raison</option>
              </select>
              @if (morSubmitted && moratoireForm.get('raison')?.hasError('required')) {
                <p class="field-error" role="alert">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  Raison requise
                </p>
              }
            </div>

            <!-- Explication libre -->
            <div>
              <label for="explication" class="label">
                Expliquez votre situation
                <span class="text-slate-400 font-normal">(optionnel)</span>
              </label>
              <textarea id="explication" formControlName="explication"
                        rows="3"
                        placeholder="Décrivez brièvement votre situation pour aider notre équipe à traiter votre demande…"
                        class="input resize-none"></textarea>
            </div>

            <!-- Nouvelle date souhaitée -->
            <div>
              <label for="nouvelleDate" class="label">
                Nouvelle date souhaitée
              </label>
              <input id="nouvelleDate" type="date"
                     formControlName="nouvelleDateSouhaitee"
                     [min]="minDate"
                     class="input">
              @if (morSubmitted && moratoireForm.get('nouvelleDateSouhaitee')?.hasError('required')) {
                <p class="field-error" role="alert">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  Date requise
                </p>
              }
            </div>

            <!-- Boutons -->
            <div class="flex gap-3 pt-2">
              <button type="button" (click)="closeMoratoire()"
                      class="btn-secondary flex-1">
                Annuler
              </button>
              <button type="submit" [disabled]="morLoading()"
                      class="btn-primary flex-1">
                @if (morLoading()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  Envoi…
                } @else {
                  Envoyer la demande
                }
              </button>
            </div>
          </form>
        </div>

        <!-- Info bas de modal -->
        <div class="px-6 pb-6">
          <p class="text-xs text-slate-400 text-center">
            Les relances automatiques sont suspendues dès réception de votre demande.
          </p>
        </div>
      </div>
    </div>
  }

</div>
  `,
})
export class PaymentComponent implements OnInit {
  readonly #paymentSvc = inject(PaymentService);
  readonly #authSvc    = inject(AuthService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly paiements    = signal<PaiementResponse[]>(MOCK_PAIEMENTS);
  readonly loading      = signal(true);
  readonly isSuspended  = computed(() => this.#authSvc.isSuspended());

  // ── Moratoire modal ────────────────────────────────────
  readonly showMoratoire  = signal(false);
  readonly morLoading     = signal(false);
  readonly activePaiementId = signal<string | null>(null);
  morSubmitted              = false;

  readonly minDate = new Date(Date.now() + 86_400_000)
    .toISOString().split('T')[0];  // Demain minimum

  readonly moratoireForm = this.#fb.nonNullable.group({
    raison:                ['', Validators.required],
    explication:           [''],
    nouvelleDateSouhaitee: ['', Validators.required],
  });

  ngOnInit(): void {
    this.#load();
  }

  #load(): void {
    this.loading.set(true);
    this.#paymentSvc.getMes().subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) {
          this.paiements.set(r.data.content);
        }
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  // ── Moratoire ──────────────────────────────────────────
  openMoratoire(p: PaiementResponse | null): void {
    this.activePaiementId.set(p?.id ?? this.paiements()[0]?.id ?? null);
    this.moratoireForm.reset();
    this.morSubmitted = false;
    this.showMoratoire.set(true);
  }

  closeMoratoire(): void {
    this.showMoratoire.set(false);
    this.morSubmitted = false;
  }

  submitMoratoire(): void {
    this.morSubmitted = true;
    if (this.moratoireForm.invalid) return;

    const id = this.activePaiementId();
    if (!id) return;

    this.morLoading.set(true);
    const { raison, explication, nouvelleDateSouhaitee } = this.moratoireForm.getRawValue();

    const req: DemanderMoratoireRequest  = {
      paiementId:            id,
      raison:                raison as DemanderMoratoireRequest['raison'],
      explication:           explication ?? '',
      nouvelleDateSouhaitee: nouvelleDateSouhaitee,
    };

    this.#paymentSvc.demanderMoratoire(req).subscribe({
      next: () => {
        this.morLoading.set(false);
        this.closeMoratoire();
        this.#toast.success(
          'Demande envoyée',
          'Notre équipe vous répondra sous 24h. Les relances sont suspendues.'
        );
      },
      error: () => { this.morLoading.set(false); },
    });
  }

  // ── Helpers visuels ────────────────────────────────────
  statutBadge(s: StatutPaiement): string {
    const m: Record<StatutPaiement, string> = {
      RECU:      'badge-green',
      PARTIEL:   'badge-blue',
      EN_ATTENTE:'badge-amber',
      RETARD:    'badge-red',
      ANNULE:    'badge-slate',
    };
    return m[s] ?? 'badge-slate';
  }

  statutLabel(s: StatutPaiement): string {
    const m: Record<StatutPaiement, string> = {
      RECU:      '✓ Payé',
      PARTIEL:   '◑ Partiel',
      EN_ATTENTE:'⏳ En attente',
      RETARD:    '⚠ Retard',
      ANNULE:    '✕ Annulé',
    };
    return m[s] ?? s;
  }

  modeLabel(m: string): string {
    return { CASH: 'Espèces', MOBILE_MONEY: 'Mobile Money', VIREMENT: 'Virement', ONLINE: 'En ligne' }[m] ?? m;
  }

  modeEmoji(m: string): string {
    return { CASH: '💵', MOBILE_MONEY: '📱', VIREMENT: '🏦', ONLINE: '💳' }[m] ?? '💳';
  }

  modeBg(m: string): string {
    return { CASH: 'bg-green-100', MOBILE_MONEY: 'bg-blue-100', VIREMENT: 'bg-purple-100', ONLINE: 'bg-indigo-100' }[m] ?? 'bg-slate-100';
  }

  paiementPercent(p: PaiementResponse): number {
    // Calcul approximatif basé sur les tranches payées
    if (!p.tranches?.length) return 0;
    const payees  = p.tranches.filter(t => t.estPayee).length;
    const total   = p.tranches.length;
    return Math.round((payees / total) * 100);
  }

  isOverdue(t: TrancheResponse): boolean {
    return !t.estPayee && new Date(t.echeance) < new Date();
  }

  isDueSoon(t: TrancheResponse): boolean {
    if (t.estPayee) return false;
    const diff = new Date(t.echeance).getTime() - Date.now();
    return diff > 0 && diff < 7 * 86_400_000;  // Dans les 7 prochains jours
  }

  hasUnpaidTranche(p: PaiementResponse): boolean {
    return !!p.tranches?.some(t => !t.estPayee);
  }
}
