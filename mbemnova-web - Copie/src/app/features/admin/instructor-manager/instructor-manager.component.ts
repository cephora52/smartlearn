import { ChangeDetectionStrategy, Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { AdminService } from '../../../core/services/admin.service';
import { PaymentService } from '../../../core/services/payment.service';
import { ToastService } from '../../../core/services/toast.service';
import type { ApprenantAdminView, AssignerRoleRequest } from '../../../core/models';

@Component({
  selector: 'app-instructor-mgr',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
<div class="min-h-screen bg-slate-50/50 py-10">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

    <!-- ── HEADER ── -->
    <div class="mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">Gestion des Formateurs</h1>
        <p class="text-sm text-slate-500 mt-1">Gérez les comptes des formateurs de la plateforme, attribuez des rôles ou gérez leurs droits d'accès.</p>
      </div>
      <div class="flex gap-3">
        <button (click)="showRoleModal.set(true)"
                class="btn-primary self-start sm:self-auto flex items-center gap-2">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 5v14M5 12h14"/></svg>
          Promouvoir un Utilisateur
        </button>
      </div>
    </div>

    <!-- ── TABLE CARD ── -->
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">
      
      <!-- Filters and Search -->
      <div class="px-6 py-5 border-b border-slate-100 flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4 bg-slate-50/30">
        <div class="relative flex-1 max-w-md">
          <input type="text"
                 (input)="searchQuery.set(searchInput.value)"
                 #searchInput
                 placeholder="Rechercher par nom, prénom ou email..."
                 class="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl text-sm focus:outline-none focus:border-blue-500 transition-colors" />
          <svg class="absolute left-3.5 top-3 text-slate-400" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-xs text-slate-400 font-bold uppercase tracking-wider">
            Total : {{ filteredFormateurs().length }} formateurs
          </span>
        </div>
      </div>

      <!-- Loading State -->
      @if (loading()) {
        <div class="p-12 text-center">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent mb-3"></div>
          <p class="text-sm text-slate-500">Chargement des formateurs...</p>
        </div>
      } @else {
        <!-- Empty State -->
        @if (filteredFormateurs().length === 0) {
          <div class="p-16 text-center">
            <p class="text-4xl mb-3">👨‍🏫</p>
            <h3 class="text-lg font-bold text-slate-900 mb-1">Aucun formateur trouvé</h3>
            <p class="text-sm text-slate-500">Modifiez vos critères de recherche ou promouvez un utilisateur au rang de formateur.</p>
          </div>
        } @else {
          <!-- Table -->
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold uppercase text-slate-400 tracking-wider">
                  <th class="px-6 py-4">Formateur</th>
                  <th class="px-6 py-4">Email / Téléphone</th>
                  <th class="px-6 py-4">Date de Promotion</th>
                  <th class="px-6 py-4">Statut</th>
                  <th class="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 text-sm">
                @for (fmt of filteredFormateurs(); track fmt.id) {
                  <tr class="hover:bg-slate-50/50 transition-colors">
                    <!-- Formateur -->
                    <td class="px-6 py-4">
                      <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center font-bold text-purple-700">
                          {{ initials(fmt) }}
                        </div>
                        <div>
                          <p class="font-bold text-slate-900">{{ fmt.prenom }} {{ fmt.nom }}</p>
                          <p class="text-xs text-slate-400">ID: {{ fmt.id }}</p>
                        </div>
                      </div>
                    </td>

                    <!-- Email / Tel -->
                    <td class="px-6 py-4">
                      <p class="text-slate-700 font-medium">{{ fmt.email }}</p>
                      <p class="text-xs text-slate-400 mt-0.5">{{ fmt.telephone || 'Aucun téléphone' }}</p>
                    </td>

                    <!-- Date -->
                    <td class="px-6 py-4 text-slate-500">
                      {{ formatDate(fmt.inscritLe) }}
                    </td>

                    <!-- Status -->
                    <td class="px-6 py-4">
                      <span [class]="'badge inline-flex ' + (fmt.statut === 'ACTIF' ? 'badge-green' : 'badge-red')">
                        {{ fmt.statut }}
                      </span>
                    </td>

                    <!-- Actions -->
                    <td class="px-6 py-4 text-right">
                      <div class="flex justify-end gap-2">
                        <button (click)="demoteUser(fmt)"
                                class="px-3 py-1.5 rounded-lg border border-amber-200 text-amber-600 text-xs font-bold hover:bg-amber-50 transition-colors"
                                title="Changer le rôle de formateur à apprenant">
                          Retirer rôle Formateur
                        </button>
                        @if (fmt.statut === 'ACTIF') {
                          <button (click)="suspendUser(fmt)"
                                  class="px-3 py-1.5 rounded-lg border border-red-200 text-red-600 text-xs font-bold hover:bg-red-50 transition-colors">
                            Suspendre
                          </button>
                        } @else {
                          <button (click)="reactivateUser(fmt)"
                                  class="px-3 py-1.5 rounded-lg border border-green-200 text-green-600 text-xs font-bold hover:bg-green-50 transition-colors">
                            Réactiver
                          </button>
                        }
                      </div>
                    </td>
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
      }
    </div>
  </div>
</div>

<!-- ── PROMOTE ROLE MODAL ── -->
@if (showRoleModal()) {
  <div class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
    <div class="bg-white rounded-3xl max-w-md w-full shadow-2xl border border-slate-100 overflow-hidden animate-fade-up">
      <!-- Modal Header -->
      <div class="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
        <h3 class="text-lg font-black text-slate-900">Promouvoir un Formateur</h3>
        <button (click)="showRoleModal.set(false)" class="text-slate-400 hover:text-slate-600">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>

      <!-- Modal Body Form -->
      <form [formGroup]="roleForm" (ngSubmit)="submitPromotion()" class="p-6 space-y-4">
        <div>
          <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">ID Utilisateur</label>
          <input type="text" formControlName="utilisateurId"
                 placeholder="Ex: u-001 ou UUID"
                 class="w-full px-4 py-3 border border-slate-200 rounded-xl text-sm focus:outline-none focus:border-blue-500 transition-colors" />
        </div>

        <div>
          <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">Rôle cible</label>
          <select formControlName="nouveauRole"
                  class="w-full px-4 py-3 border border-slate-200 rounded-xl text-sm focus:outline-none focus:border-blue-500 bg-white transition-colors">
            <option value="FORMATEUR">Formateur</option>
            <option value="ADMIN">Administrateur</option>
          </select>
        </div>

        <div class="pt-4 flex gap-3">
          <button type="button" (click)="showRoleModal.set(false)"
                  class="btn-secondary flex-1 py-3 justify-center">
            Annuler
          </button>
          <button type="submit" [disabled]="roleForm.invalid || promoting()"
                  class="btn-primary flex-1 py-3 justify-center">
            @if (promoting()) { Promotion... } @else { Promouvoir }
          </button>
        </div>
      </form>
    </div>
  </div>
}
  `,
})
export class InstructorManagerComponent implements OnInit {
  readonly #adminSvc   = inject(AdminService);
  readonly #paymentSvc = inject(PaymentService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly listFormateurs = signal<ApprenantAdminView[]>([]);
  readonly loading        = signal(true);
  readonly searchQuery    = signal('');

  // Role promotion
  readonly showRoleModal = signal(false);
  readonly promoting     = signal(false);
  readonly roleForm = this.#fb.nonNullable.group({
    utilisateurId: ['', [Validators.required, Validators.minLength(2)]],
    nouveauRole: ['FORMATEUR', Validators.required],
  });

  readonly filteredFormateurs = computed(() => {
    const q = this.searchQuery().toLowerCase().trim();
    const all = this.listFormateurs();
    if (!q) return all;
    return all.filter(fmt =>
      fmt.prenom.toLowerCase().includes(q) ||
      (fmt.nom || '').toLowerCase().includes(q) ||
      fmt.email.toLowerCase().includes(q)
    );
  });

  ngOnInit(): void {
    this.loadFormateurs();
  }

  loadFormateurs(): void {
    this.loading.set(true);
    this.#adminSvc.getFormateurs().subscribe({
      next: res => {
        if (res.success && res.data) {
          this.listFormateurs.set((res.data as any).content || res.data || []);
        }
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.#toast.error('Impossible de charger la liste des formateurs');
      }
    });
  }

  demoteUser(fmt: ApprenantAdminView): void {
    if (confirm(`Voulez-vous vraiment retirer le rôle Formateur de ${fmt.prenom} ? Il redeviendra un simple apprenant.`)) {
      this.#adminSvc.assignerRole({ utilisateurId: fmt.id, nouveauRole: 'APPRENANT' }).subscribe({
        next: res => {
          if (res.success) {
            this.#toast.success('Rôle mis à jour avec succès');
            this.loadFormateurs();
          }
        },
        error: () => {
          this.#toast.error('Impossible de modifier le rôle');
        }
      });
    }
  }

  suspendUser(fmt: ApprenantAdminView): void {
    if (confirm(`Êtes-vous sûr de vouloir suspendre le compte du formateur ${fmt.prenom} ?`)) {
      this.#paymentSvc.suspendre(fmt.id).subscribe({
        next: res => {
          if (res.success) {
            this.#toast.success('Le compte a été suspendu');
            this.loadFormateurs();
          }
        },
        error: () => {
          this.#toast.error('Erreur lors de la suspension');
        }
      });
    }
  }

  reactivateUser(fmt: ApprenantAdminView): void {
    this.#paymentSvc.reactiver(fmt.id).subscribe({
      next: res => {
        if (res.success) {
          this.#toast.success('Le compte a été réactivé');
          this.loadFormateurs();
        }
      },
      error: () => {
        this.#toast.error('Erreur lors de la réactivation');
      }
    });
  }

  submitPromotion(): void {
    if (this.roleForm.invalid) return;
    this.promoting.set(true);
    const formVal = this.roleForm.getRawValue();
    this.#adminSvc.assignerRole(formVal as AssignerRoleRequest).subscribe({
      next: res => {
        if (res.success) {
          this.#toast.success('Utilisateur promu avec succès');
          this.showRoleModal.set(false);
          this.roleForm.reset({ utilisateurId: '', nouveauRole: 'FORMATEUR' });
          this.loadFormateurs();
        }
        this.promoting.set(false);
      },
      error: () => {
        this.promoting.set(false);
        this.#toast.error('Erreur lors de la promotion. Vérifiez l\'identifiant utilisateur.');
      }
    });
  }

  initials(app: ApprenantAdminView): string {
    const f = app.prenom?.charAt(0) || '';
    const l = app.nom?.charAt(0) || '';
    return (f + l).toUpperCase() || '?';
  }

  formatDate(isoStr?: string): string {
    if (!isoStr) return '-';
    return new Date(isoStr).toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  }
}
