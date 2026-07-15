import { ChangeDetectionStrategy, Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { forkJoin } from 'rxjs';
import { PaymentService } from '../../../core/services/payment.service';
import { AdminService } from '../../../core/services/admin.service';
import { CourseService } from '../../../core/services/course.service';
import { ToastService } from '../../../core/services/toast.service';
import type { TraiterMoratoireRequest, PaiementResponse, ApprenantAdminView, CoursResponse } from '../../../core/models';

interface MoratoireItem {
  id: string;
  paiementId: string;
  raison: string;
  nouvelleDateSouhaitee: string;
  nouvelleDateAccordee: string | null;
  statut: 'EN_ATTENTE' | 'APPROUVE' | 'REFUSE';
  createdAt: string;
  apprenantId: string;
  apprenantNom: string;
  apprenantPrenom: string;
  apprenantEmail: string;
  coursId: string;
  coursTitre: string;
  justificationRefus?: string | null;
  dateDecision?: string | null;
}

@Component({
  selector: 'app-payment-mgr',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true,
  imports: [CommonModule, RouterLink, ReactiveFormsModule],
  template: `
<div class="min-h-screen bg-slate-50/50 py-10">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    
    <!-- ── HEADER ── -->
    <div class="mb-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">Suivi des Paiements</h1>
        <p class="text-sm text-slate-500 mt-1">Gérez les règlements des apprenants, suivez les échéances, et traitez les demandes de moratoires.</p>
      </div>
      <a routerLink="/admin" class="btn-secondary self-start md:self-auto flex items-center gap-2">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        Tableau de Bord
      </a>
    </div>

    <!-- ── TABS SELECTOR ── -->
    <div class="flex items-center gap-2 p-1 bg-slate-200/50 rounded-2xl border border-slate-100 mb-8 self-start max-w-fit shadow-xs">
      <button (click)="activeTab.set('VALIDATED')"
              [class]="'px-5 py-2.5 text-xs font-bold rounded-xl transition-all ' + 
                       (activeTab() === 'VALIDATED' ? 'bg-slate-900 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100')">
        ✓ Paiements Validés
      </button>
      <button (click)="activeTab.set('PENDING')"
              [class]="'px-5 py-2.5 text-xs font-bold rounded-xl transition-all ' + 
                       (activeTab() === 'PENDING' ? 'bg-slate-900 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100')">
        ⏳ En Attente
      </button>
      <button (click)="activeTab.set('LATE')"
              [class]="'px-5 py-2.5 text-xs font-bold rounded-xl transition-all ' + 
                       (activeTab() === 'LATE' ? 'bg-slate-900 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100')">
        ⚠️ En Retard
      </button>
      <button (click)="activeTab.set('MORATORIUM')"
              [class]="'px-5 py-2.5 text-xs font-bold rounded-xl transition-all ' + 
                       (activeTab() === 'MORATORIUM' ? 'bg-slate-900 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100')">
        📋 Demandes de Moratoire
      </button>
    </div>

    <!-- ── MAIN CONTENT ── -->
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">
      
      <!-- Loading State -->
      @if (loading()) {
        <div class="p-12 text-center">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent mb-3"></div>
          <p class="text-sm text-slate-500">Chargement des données financières...</p>
        </div>
      } @else {

        <!-- ── TAB: VALIDATED PAYMENTS ── -->
        @if (activeTab() === 'VALIDATED') {
          <div class="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/30">
            <h2 class="text-sm font-bold text-slate-900">Paiements Validés (Réglés)</h2>
            <span class="text-xs text-slate-400 font-bold uppercase tracking-wider">{{ validatedPayments().length }} paiements</span>
          </div>
          @if (validatedPayments().length === 0) {
            <div class="p-16 text-center">
              <p class="text-4xl mb-3">✓</p>
              <h3 class="text-base font-bold text-slate-900">Aucun paiement validé</h3>
              <p class="text-xs text-slate-400 mt-1">Tous les règlements complets apparaîtront ici.</p>
            </div>
          } @else {
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold uppercase text-slate-400 tracking-wider">
                    <th class="px-6 py-4">Apprenant</th>
                    <th class="px-6 py-4">Formation</th>
                    <th class="px-6 py-4">Montant Total</th>
                    <th class="px-6 py-4">Montant Réglé</th>
                    <th class="px-6 py-4">Date de Validation</th>
                    <th class="px-6 py-4">Mode</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 text-sm">
                  @for (p of validatedPayments(); track p.id) {
                    <tr class="hover:bg-slate-50/50 transition-colors">
                      <td class="px-6 py-4 font-bold text-slate-900">{{ getLearnerName(p.apprenantId) }}</td>
                      <td class="px-6 py-4 text-slate-700">{{ getCourseTitle(p.coursId) }}</td>
                      <td class="px-6 py-4 font-semibold text-slate-500">{{ p.montantTotal }}</td>
                      <td class="px-6 py-4 font-bold text-emerald-600">{{ p.montantPaye }}</td>
                      <td class="px-6 py-4 text-slate-500">{{ formatDate(p.dateActivation) }}</td>
                      <td class="px-6 py-4">
                        <span class="badge badge-green">{{ p.mode }}</span>
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          }
        }

        <!-- ── TAB: PENDING PAYMENTS ── -->
        @if (activeTab() === 'PENDING') {
          <div class="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/30">
            <h2 class="text-sm font-bold text-slate-900">Paiements en Attente (Partiels)</h2>
            <span class="text-xs text-slate-400 font-bold uppercase tracking-wider">{{ pendingPayments().length }} paiements</span>
          </div>
          @if (pendingPayments().length === 0) {
            <div class="p-16 text-center">
              <p class="text-4xl mb-3">⏳</p>
              <h3 class="text-base font-bold text-slate-900">Aucun paiement en attente</h3>
              <p class="text-xs text-slate-400 mt-1">Tous les paiements partiels apparaîtront ici.</p>
            </div>
          } @else {
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold uppercase text-slate-400 tracking-wider">
                    <th class="px-6 py-4">Apprenant</th>
                    <th class="px-6 py-4">Formation</th>
                    <th class="px-6 py-4">Montant Total</th>
                    <th class="px-6 py-4">Montant Payé</th>
                    <th class="px-6 py-4">Reste à payer</th>
                    <th class="px-6 py-4">Statut</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 text-sm">
                  @for (p of pendingPayments(); track p.id) {
                    <tr class="hover:bg-slate-50/50 transition-colors">
                      <td class="px-6 py-4 font-bold text-slate-900">{{ getLearnerName(p.apprenantId) }}</td>
                      <td class="px-6 py-4 text-slate-700">{{ getCourseTitle(p.coursId) }}</td>
                      <td class="px-6 py-4 font-semibold text-slate-500">{{ p.montantTotal }}</td>
                      <td class="px-6 py-4 font-bold text-slate-700">{{ p.montantPaye }}</td>
                      <td class="px-6 py-4 font-bold text-amber-600">{{ getResteAPayer(p) }}</td>
                      <td class="px-6 py-4">
                        <span class="badge badge-amber">EN ATTENTE</span>
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          }
        }

        <!-- ── TAB: LATE PAYMENTS ── -->
        @if (activeTab() === 'LATE') {
          <div class="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/30">
            <h2 class="text-sm font-bold text-slate-900">Paiements en Retard (Impayés)</h2>
            <span class="text-xs text-slate-400 font-bold uppercase tracking-wider">{{ latePayments().length }} retards</span>
          </div>
          @if (latePayments().length === 0) {
            <div class="p-16 text-center">
              <p class="text-4xl mb-3">✓</p>
              <h3 class="text-base font-bold text-slate-900">Aucun paiement en retard</h3>
              <p class="text-xs text-slate-400 mt-1">Tous les retards de paiements sont actuellement régularisés.</p>
            </div>
          } @else {
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold uppercase text-slate-400 tracking-wider">
                    <th class="px-6 py-4">Apprenant</th>
                    <th class="px-6 py-4">Formation</th>
                    <th class="px-6 py-4">Montant Total</th>
                    <th class="px-6 py-4">Montant Payé</th>
                    <th class="px-6 py-4">Statut</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 text-sm">
                  @for (p of latePayments(); track p.id) {
                    <tr class="hover:bg-slate-50/50 transition-colors">
                      <td class="px-6 py-4 font-bold text-slate-900">{{ getLearnerName(p.apprenantId) }}</td>
                      <td class="px-6 py-4 text-slate-700">{{ getCourseTitle(p.coursId) }}</td>
                      <td class="px-6 py-4 font-semibold text-slate-500">{{ p.montantTotal }}</td>
                      <td class="px-6 py-4 font-bold text-slate-700">{{ p.montantPaye }}</td>
                      <td class="px-6 py-4">
                        <span class="badge badge-red">EN RETARD</span>
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          }
        }

        <!-- ── TAB: MORATORIUM REQUESTS ── -->
        @if (activeTab() === 'MORATORIUM') {
          <!-- Filters -->
          <div class="px-6 py-5 border-b border-slate-100 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-slate-50/30">
            <div class="flex items-center gap-2 bg-white p-1 rounded-xl border border-slate-200 shadow-xs">
              <button (click)="filterStatus.set('ALL')"
                      [class]="'px-4 py-2 text-xs font-bold rounded-lg transition-all ' + 
                               (filterStatus() === 'ALL' ? 'bg-slate-900 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50')">
                Toutes
              </button>
              <button (click)="filterStatus.set('EN_ATTENTE')"
                      [class]="'px-4 py-2 text-xs font-bold rounded-lg transition-all ' + 
                               (filterStatus() === 'EN_ATTENTE' ? 'bg-amber-500 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50')">
                En Attente
              </button>
              <button (click)="filterStatus.set('APPROUVE')"
                      [class]="'px-4 py-2 text-xs font-bold rounded-lg transition-all ' + 
                               (filterStatus() === 'APPROUVE' ? 'bg-emerald-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50')">
                Approuvées
              </button>
              <button (click)="filterStatus.set('REFUSE')"
                      [class]="'px-4 py-2 text-xs font-bold rounded-lg transition-all ' + 
                               (filterStatus() === 'REFUSE' ? 'bg-rose-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50')">
                Refusées
              </button>
            </div>
            <span class="text-xs text-slate-400 font-bold uppercase tracking-wider">{{ filteredMoratoires().length }} demandes</span>
          </div>

          @if (filteredMoratoires().length === 0) {
            <div class="p-16 text-center">
              <p class="text-4xl mb-3">📋</p>
              <h3 class="text-base font-bold text-slate-900">Aucune demande de moratoire</h3>
              <p class="text-xs text-slate-400 mt-1">Toutes les demandes correspondantes apparaîtront ici.</p>
            </div>
          } @else {
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold uppercase text-slate-400 tracking-wider">
                    <th class="px-6 py-4">Apprenant</th>
                    <th class="px-6 py-4">Formation</th>
                    <th class="px-6 py-4">Raison / Justification</th>
                    <th class="px-6 py-4">Échéance Souhaitée</th>
                    <th class="px-6 py-4">Statut</th>
                    <th class="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 text-sm">
                  @for (m of filteredMoratoires(); track m.id) {
                    <tr class="hover:bg-slate-50/50 transition-colors">
                      <td class="px-6 py-4">
                        <p class="font-bold text-slate-900">{{ m.apprenantPrenom }} {{ m.apprenantNom }}</p>
                        <p class="text-xs text-slate-400">{{ m.apprenantEmail }}</p>
                      </td>
                      <td class="px-6 py-4 text-slate-700 font-medium">{{ m.coursTitre }}</td>
                      <td class="px-6 py-4">
                        <span [class]="'badge text-[10px] font-bold px-2 py-0.5 rounded-full mr-2 ' + getRaisonClass(m.raison)">
                          {{ formatRaison(m.raison) }}
                        </span>
                        <span class="text-slate-500 text-xs leading-relaxed italic">"{{ m.justificationRefus || m.raison }}"</span>
                      </td>
                      <td class="px-6 py-4 text-slate-900 font-semibold">{{ formatDate(m.nouvelleDateSouhaitee) }}</td>
                      <td class="px-6 py-4">
                        <span [class]="'badge inline-flex ' + getStatusClass(m.statut)">
                          {{ formatStatut(m.statut) }}
                        </span>
                      </td>
                      <td class="px-6 py-4 text-right">
                        @if (m.statut === 'EN_ATTENTE') {
                          <div class="flex justify-end gap-2">
                            <button (click)="openAcceptModal(m)"
                                    class="px-2.5 py-1.5 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 text-xs font-bold rounded-lg transition-colors">
                              Approuver
                            </button>
                            <button (click)="openRefuseModal(m)"
                                    class="px-2.5 py-1.5 bg-rose-50 text-rose-700 hover:bg-rose-100 text-xs font-bold rounded-lg transition-colors">
                              Refuser
                            </button>
                          </div>
                        } @else {
                          <span class="text-xs text-slate-400 font-semibold px-2 py-1.5">Traité</span>
                        }
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          }
        }

      }
    </div>
  </div>
</div>

<!-- ── MODAL ACCEPTER MORATOIRE ── -->
@if (activeModal() === 'ACCEPT') {
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
    <div class="bg-white rounded-3xl max-w-md w-full border border-slate-100 shadow-2xl p-6 overflow-hidden animate-fade-up">
      <div class="flex justify-between items-center mb-5">
        <h3 class="text-lg font-black text-slate-800">Accepter la demande</h3>
        <button (click)="closeModal()" class="text-slate-400 hover:text-slate-600 transition-colors">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
      <p class="text-xs text-slate-500 mb-6">
        Approuver cette demande débloquera immédiatement l'accès de l'apprenant <strong class="text-slate-700">{{ selectedMoratoire()?.apprenantPrenom }}</strong> au reste de la formation.
      </p>

      <form [formGroup]="acceptForm" (ngSubmit)="confirmAccept()" class="space-y-4">
        <div>
          <label class="block text-xs font-bold text-slate-500 mb-2 uppercase tracking-wide">Nouvelle date d'échéance accordée</label>
          <input type="date" formControlName="nouvelleDateAccordee"
                 class="w-full px-4 py-3 rounded-xl border border-slate-200 text-sm font-semibold text-slate-800 focus:border-slate-800 outline-none transition-colors">
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <button type="button" (click)="closeModal()" class="btn-secondary px-5 py-2.5 text-xs font-bold">
            Annuler
          </button>
          <button type="submit" [disabled]="acceptForm.invalid || actionLoading()"
                  class="btn-primary px-5 py-2.5 text-xs font-bold">
            {{ actionLoading() ? 'Traitement...' : 'Confirmer' }}
          </button>
        </div>
      </form>
    </div>
  </div>
}

<!-- ── MODAL REFUSER MORATOIRE ── -->
@if (activeModal() === 'REFUSE') {
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
    <div class="bg-white rounded-3xl max-w-md w-full border border-slate-100 shadow-2xl p-6 overflow-hidden animate-fade-up">
      <div class="flex justify-between items-center mb-5">
        <h3 class="text-lg font-black text-slate-800">Refuser la demande</h3>
        <button (click)="closeModal()" class="text-slate-400 hover:text-slate-600 transition-colors">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
      <p class="text-xs text-slate-500 mb-6">
        Refuser la demande de moratoire maintiendra le verrouillage des leçons au-delà du seuil de paiement.
      </p>

      <form [formGroup]="refuseForm" (ngSubmit)="confirmRefuse()" class="space-y-4">
        <div>
          <label class="block text-xs font-bold text-slate-500 mb-2 uppercase tracking-wide">Motif du refus (Justification)</label>
          <textarea formControlName="justificationRefus" rows="4" placeholder="Ex: Veuillez régulariser la première tranche..."
                    class="w-full px-4 py-3 rounded-xl border border-slate-200 text-sm font-semibold text-slate-800 focus:border-slate-800 outline-none transition-colors resize-none"></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <button type="button" (click)="closeModal()" class="btn-secondary px-5 py-2.5 text-xs font-bold">
            Annuler
          </button>
          <button type="submit" [disabled]="refuseForm.invalid || actionLoading()"
                  class="btn-primary px-5 py-2.5 text-xs font-bold bg-rose-600 hover:bg-rose-700">
            {{ actionLoading() ? 'Traitement...' : 'Confirmer' }}
          </button>
        </div>
      </form>
    </div>
  </div>
}
  `,
})
export class PaymentManagerComponent implements OnInit {
  readonly #paymentSvc = inject(PaymentService);
  readonly #adminSvc   = inject(AdminService);
  readonly #courseSvc  = inject(CourseService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly activeTab     = signal<'VALIDATED' | 'PENDING' | 'LATE' | 'MORATORIUM'>('MORATORIUM');
  readonly moratoires    = signal<MoratoireItem[]>([]);
  readonly payments      = signal<PaiementResponse[]>([]);
  readonly loading       = signal(true);
  readonly actionLoading = signal(false);
  readonly filterStatus  = signal<'ALL' | 'EN_ATTENTE' | 'APPROUVE' | 'REFUSE'>('ALL');

  // Lookups maps
  readonly learnerNameMap = signal<Record<string, string>>({});
  readonly courseTitleMap = signal<Record<string, string>>({});

  // Modal State
  readonly activeModal      = signal<'NONE' | 'ACCEPT' | 'REFUSE'>('NONE');
  readonly selectedMoratoire = signal<MoratoireItem | null>(null);

  // Forms
  readonly acceptForm = this.#fb.nonNullable.group({
    nouvelleDateAccordee: ['', Validators.required],
  });

  readonly refuseForm = this.#fb.nonNullable.group({
    justificationRefus: ['', [Validators.required, Validators.minLength(5)]],
  });

  // Filtered Moratoires list
  readonly filteredMoratoires = computed(() => {
    const list = this.moratoires();
    const filter = this.filterStatus();
    if (filter === 'ALL') return list;
    return list.filter(m => m.statut === filter);
  });

  // Payments groupings
  readonly validatedPayments = computed(() => {
    return this.payments().filter(p => p.statut === 'PAYE');
  });

  readonly pendingPayments = computed(() => {
    return this.payments().filter(p => p.statut === 'EN_ATTENTE');
  });

  readonly latePayments = computed(() => {
    return this.payments().filter(p => p.statut === 'EN_RETARD');
  });

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading.set(true);

    forkJoin({
      moratoires: this.#paymentSvc.getMoratoires(),
      payments: this.#paymentSvc.getAll(),
      apprenants: this.#adminSvc.getApprenants(),
      courses: this.#courseSvc.getAll()
    }).subscribe({
      next: ({ moratoires, payments, apprenants, courses }) => {
        // Parse moratoires
        if (moratoires.success && moratoires.data) {
          this.moratoires.set(moratoires.data as MoratoireItem[]);
        }

        // Parse payments
        if (payments.success && payments.data) {
          this.payments.set(payments.data);
        }

        // Parse lookups
        const learnerMap: Record<string, string> = {};
        const learnersList: ApprenantAdminView[] = (apprenants.data as any)?.content || apprenants.data || [];
        learnersList.forEach(app => {
          learnerMap[app.id] = `${app.prenom} ${app.nom || ''}`.trim();
        });
        this.learnerNameMap.set(learnerMap);

        const coursesMap: Record<string, string> = {};
        const coursesList: CoursResponse[] = (courses.data as any)?.content || courses.data || [];
        coursesList.forEach(c => {
          coursesMap[c.id] = c.titre;
        });
        this.courseTitleMap.set(coursesMap);

        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.#toast.error('Erreur lors du chargement des données de paiement');
      }
    });
  }

  getLearnerName(id: string): string {
    return this.learnerNameMap()[id] || `Apprenant (${id.substring(0, 5)})`;
  }

  getCourseTitle(id: string): string {
    return this.courseTitleMap()[id] || `Formation (${id.substring(0, 5)})`;
  }

  getResteAPayer(p: PaiementResponse): string {
    try {
      const total = parseInt(p.montantTotal.replace(/[^0-9]/g, ''));
      const paye = parseInt(p.montantPaye.replace(/[^0-9]/g, ''));
      const diff = total - paye;
      return diff > 0 ? `${diff.toLocaleString('fr-FR')} FCFA` : '0 FCFA';
    } catch {
      return '-';
    }
  }

  loadMoratoires(): void {
    this.#paymentSvc.getMoratoires().subscribe({
      next: r => {
        if (r.success && r.data) {
          this.moratoires.set(r.data as MoratoireItem[]);
        }
      }
    });
  }

  openAcceptModal(m: MoratoireItem): void {
    this.selectedMoratoire.set(m);
    this.acceptForm.reset({
      nouvelleDateAccordee: m.nouvelleDateSouhaitee
    });
    this.activeModal.set('ACCEPT');
  }

  openRefuseModal(m: MoratoireItem): void {
    this.selectedMoratoire.set(m);
    this.refuseForm.reset();
    this.activeModal.set('REFUSE');
  }

  closeModal(): void {
    this.activeModal.set('NONE');
    this.selectedMoratoire.set(null);
  }

  confirmAccept(): void {
    if (this.acceptForm.invalid || this.actionLoading()) return;
    const m = this.selectedMoratoire();
    if (!m) return;

    this.actionLoading.set(true);
    const { nouvelleDateAccordee } = this.acceptForm.getRawValue();

    const req: TraiterMoratoireRequest = {
      decision: 'APPROUVE',
      nouvelleDateAccordee
    };

    this.#paymentSvc.deciderMoratoire(m.id, req).subscribe({
      next: () => {
        this.actionLoading.set(false);
        this.closeModal();
        this.#toast.success('Moratoire accordé', "L'accès au cours a été déverrouillé.");
        this.loadData();
      },
      error: () => { this.actionLoading.set(false); }
    });
  }

  confirmRefuse(): void {
    if (this.refuseForm.invalid || this.actionLoading()) return;
    const m = this.selectedMoratoire();
    if (!m) return;

    this.actionLoading.set(true);
    const { justificationRefus } = this.refuseForm.getRawValue();

    const req: TraiterMoratoireRequest = {
      decision: 'REFUSE',
      justificationRefus
    };

    this.#paymentSvc.deciderMoratoire(m.id, req).subscribe({
      next: () => {
        this.actionLoading.set(false);
        this.closeModal();
        this.#toast.success('Demande refusée', 'Le moratoire a été refusé avec succès.');
        this.loadData();
      },
      error: () => { this.actionLoading.set(false); }
    });
  }

  // Helpers
  formatDate(iso?: string | null): string {
    if (!iso) return '';
    return new Date(iso).toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  }

  formatStatut(s: string): string {
    return {
      'EN_ATTENTE': 'En attente',
      'APPROUVE': 'Approuvé',
      'REFUSE': 'Refusé'
    }[s] || s;
  }

  getStatusClass(s: string): string {
    return {
      'EN_ATTENTE': 'bg-amber-100 text-amber-800 border border-amber-200/50',
      'APPROUVE': 'bg-emerald-100 text-emerald-800 border border-emerald-200/50',
      'REFUSE': 'bg-rose-100 text-rose-800 border border-rose-200/50'
    }[s] || '';
  }

  formatRaison(r: string): string {
    return {
      'DIFFICULTES_FINANCIERES': 'Finances',
      'PROBLEME_SANTE': 'Santé',
      'AUTRE': 'Autre'
    }[r] || 'Délai';
  }

  getRaisonClass(r: string): string {
    return {
      'DIFFICULTES_FINANCIERES': 'bg-purple-100 text-purple-700',
      'PROBLEME_SANTE': 'bg-sky-100 text-sky-700',
      'AUTRE': 'bg-slate-100 text-slate-700'
    }[r] || 'bg-slate-100 text-slate-700';
  }
}
