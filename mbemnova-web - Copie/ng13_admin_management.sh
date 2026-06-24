#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 13/16 · Admin Management
# ============================================================
# Contenu :
#   learner-manager.component.ts   (S21)
#     · Tableau apprenants + recherche + filtres
#     · Modal inscription manuelle
#     · Actions : suspendre / réactiver
#
#   payment-manager.component.ts   (S08 · S18)
#     · Tableau paiements + filtres statut
#     · Modal enregistrement paiement cash (S08)
#     · Suspension / réactivation compte (S18)
#
#   role-manager.component.ts      (S26)
#     · Liste utilisateurs + rôles
#     · Modal assignation rôle + mot de passe admin
#
#   draw-manager.component.ts      (S24)
#     · Configuration tirage mensuel
#     · Tirage au sort + annonce gagnant
#
# Règles : Tailwind only · OnPush · Signals · SSR-safe
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "\033[0;31m  ✗\033[0m $1" >&2; exit 1; }
[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet"

mkdir -p \
  src/app/features/admin/learner-manager \
  src/app/features/admin/payment-manager \
  src/app/features/admin/role-manager \
  src/app/features/admin/draw-manager

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 13 · Admin Management       ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. LEARNER MANAGER — S21
# ============================================================
sec "1/4 — learner-manager.component.ts (S21)"

cat > src/app/features/admin/learner-manager/learner-manager.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AdminService }   from '../../../core/services/admin.service';
import { PaymentService } from '../../../core/services/payment.service';
import { ToastService }   from '../../../core/services/toast.service';
import type { ApprenantAdminView, StatutCompte } from '../../../core/models';
import { MOCK_APPRENANTS_ADMIN } from '../../../core/services/mock.data';

@Component({
  selector: 'app-learner-manager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4 flex-wrap">
        <div class="flex items-center gap-3">
          <a routerLink="/admin" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
          </a>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
            Apprenants
          </h1>
          <span class="badge-blue">{{ total() }}</span>
        </div>
        <button (click)="showInscription.set(true)" class="btn-primary shrink-0">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Inscrire manuellement
        </button>
      </div>
    </div>
  </div>

  <div class="container py-6 space-y-5">

    <!-- Barre recherche + filtres -->
    <div class="flex flex-col sm:flex-row gap-3">
      <div class="relative flex-1">
        <svg class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none"
             width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
        </svg>
        <input type="search" [(ngModel)]="searchTerm" (input)="onSearch()"
               placeholder="Rechercher par nom ou email…"
               class="input pl-9">
      </div>
      <div class="flex gap-2">
        @for (f of filtres; track f.value) {
          <button (click)="filtre.set(f.value)"
                  [class]="'btn-sm rounded-lg px-4 transition-colors '
                           + (filtre() === f.value ? 'bg-blue-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50')">
            {{ f.label }}
          </button>
        }
      </div>
    </div>

    <!-- Tableau apprenants -->
    @if (loading()) {
      <div class="card overflow-hidden">
        @for (_ of [1,2,3,4,5]; track $_) {
          <div class="flex items-center gap-4 p-4 border-b border-slate-100">
            <div class="shimmer w-9 h-9 rounded-full shrink-0"></div>
            <div class="flex-1 space-y-1.5">
              <div class="shimmer h-4 rounded w-1/3"></div>
              <div class="shimmer h-3 rounded w-1/4"></div>
            </div>
            <div class="shimmer h-6 rounded-full w-20 shrink-0"></div>
          </div>
        }
      </div>
    }

    @if (!loading()) {
      @if (apprenantsFiltres().length === 0) {
        <div class="card p-12 text-center">
          <div class="text-4xl mb-3" aria-hidden="true">👤</div>
          <p class="font-semibold text-slate-900 mb-1">Aucun apprenant trouvé</p>
          <p class="text-sm text-slate-500">Essayez d'autres mots-clés.</p>
        </div>
      }

      @if (apprenantsFiltres().length > 0) {
        <div class="card overflow-hidden">
          <!-- En-tête tableau -->
          <div class="hidden sm:grid grid-cols-12 gap-4 px-5 py-3 bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase tracking-wide">
            <div class="col-span-4">Apprenant</div>
            <div class="col-span-2">Statut</div>
            <div class="col-span-2">XP</div>
            <div class="col-span-2">Cours</div>
            <div class="col-span-2 text-right">Actions</div>
          </div>

          @for (a of apprenantsFiltres(); track a.id; let i = $index) {
            <div class="grid grid-cols-1 sm:grid-cols-12 gap-3 sm:gap-4 items-center
                        px-5 py-4 border-b border-slate-100 hover:bg-slate-50
                        transition-colors animate-fade-up"
                 [style]="'animation-delay:' + (i * 30) + 'ms'">

              <!-- Identité -->
              <div class="col-span-4 flex items-center gap-3 min-w-0">
                <div [class]="'w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0 '
                              + (a.statut === 'SUSPENDU' ? 'bg-red-500' : 'bg-blue-600')">
                  {{ a.prenom.charAt(0) }}
                </div>
                <div class="min-w-0">
                  <p class="text-sm font-semibold text-slate-900 truncate">{{ a.prenom }} {{ a.nom }}</p>
                  <p class="text-xs text-slate-400 truncate">{{ a.email }}</p>
                  @if (a.telephone) {
                    <p class="text-xs text-slate-400">{{ a.telephone }}</p>
                  }
                </div>
              </div>

              <!-- Statut -->
              <div class="col-span-2 flex items-center">
                <span [class]="statutBadge(a.statut)">{{ statutLabel(a.statut) }}</span>
              </div>

              <!-- XP -->
              <div class="col-span-2">
                <p class="text-sm font-bold text-slate-900">{{ a.xpTotal | number:'1.0-0' }}</p>
                <p class="text-xs text-slate-400">XP</p>
              </div>

              <!-- Cours -->
              <div class="col-span-2">
                <p class="text-sm text-slate-700">{{ a.nbCoursInscrits }} cours</p>
                <p class="text-xs text-slate-400">Inscrit {{ fmtDate(a.inscritLe) }}</p>
              </div>

              <!-- Actions -->
              <div class="col-span-2 flex items-center gap-2 justify-end">
                @if (a.statut === 'ACTIF') {
                  <button (click)="suspendre(a)"
                          class="btn-danger btn-sm text-xs">
                    Suspendre
                  </button>
                } @else if (a.statut === 'SUSPENDU') {
                  <button (click)="reactiver(a)"
                          class="btn-success btn-sm text-xs">
                    Réactiver
                  </button>
                }
              </div>
            </div>
          }
        </div>
      }
    }
  </div>

  <!-- ── MODAL INSCRIPTION MANUELLE (S21) ─────────────── -->
  @if (showInscription()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="inscr-title">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" (click)="showInscription.set(false)"></div>

      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-md animate-scale-in overflow-hidden">
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
              </div>
              <div>
                <h2 id="inscr-title" class="font-bold text-slate-900">Inscription manuelle</h2>
                <p class="text-xs text-slate-500">S21 — Créer un compte apprenant</p>
              </div>
            </div>
            <button (click)="showInscription.set(false)" class="btn-icon text-slate-400 hover:text-slate-600" aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
        </div>

        <div class="p-6">
          <form [formGroup]="inscrForm" (ngSubmit)="inscrire()" novalidate class="space-y-4">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label for="iPrenom" class="label">Prénom <span class="text-red-500">*</span></label>
                <input id="iPrenom" type="text" formControlName="prenom" placeholder="Jean-Paul"
                       [class]="'input ' + (inscrSub && inscrForm.get('prenom')?.invalid ? 'input-error' : '')">
              </div>
              <div>
                <label for="iNom" class="label">Nom <span class="text-red-500">*</span></label>
                <input id="iNom" type="text" formControlName="nom" placeholder="Mbemba"
                       [class]="'input ' + (inscrSub && inscrForm.get('nom')?.invalid ? 'input-error' : '')">
              </div>
            </div>
            <div>
              <label for="iEmail" class="label">Email <span class="text-red-500">*</span></label>
              <input id="iEmail" type="email" formControlName="email" placeholder="jeanpaul@gmail.com"
                     [class]="'input ' + (inscrSub && inscrForm.get('email')?.invalid ? 'input-error' : '')">
            </div>
            <div>
              <label for="iTel" class="label">Téléphone <span class="text-red-500">*</span></label>
              <input id="iTel" type="tel" formControlName="telephone" placeholder="+237 6XX XX XX XX"
                     [class]="'input ' + (inscrSub && inscrForm.get('telephone')?.invalid ? 'input-error' : '')">
            </div>

            <div class="bg-amber-50 border border-amber-100 rounded-xl p-3 flex gap-2">
              <svg class="shrink-0 mt-0.5" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              <p class="text-xs text-amber-800">
                Un email contenant le mot de passe temporaire sera envoyé automatiquement à l'apprenant.
              </p>
            </div>

            <div class="flex gap-3 pt-1">
              <button type="button" (click)="showInscription.set(false)" class="btn-secondary flex-1">Annuler</button>
              <button type="submit" [disabled]="inscrLoading()" class="btn-primary flex-1">
                @if (inscrLoading()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                }
                Créer le compte
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  }
</div>
  `,
})
export class LearnerManagerComponent implements OnInit {
  readonly #adminSvc   = inject(AdminService);
  readonly #paymentSvc = inject(PaymentService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly apprenants      = signal<ApprenantAdminView[]>(MOCK_APPRENANTS_ADMIN);
  readonly loading         = signal(true);
  readonly showInscription = signal(false);
  readonly inscrLoading    = signal(false);
  readonly filtre          = signal<'tous' | 'actifs' | 'suspendus'>('tous');
  inscrSub                 = false;
  searchTerm               = '';

  readonly total = computed(() => this.apprenants().length);

  readonly filtres = [
    { value: 'tous',      label: 'Tous' },
    { value: 'actifs',    label: 'Actifs' },
    { value: 'suspendus', label: 'Suspendus' },
  ] as const;

  readonly inscrForm = this.#fb.nonNullable.group({
    prenom:    ['', Validators.required],
    nom:       ['', Validators.required],
    email:     ['', [Validators.required, Validators.email]],
    telephone: ['', Validators.required],
  });

  readonly apprenantsFiltres = computed(() => {
    let list = this.apprenants();
    const f  = this.filtre();
    if (f === 'actifs')    list = list.filter(a => a.statut === 'ACTIF');
    if (f === 'suspendus') list = list.filter(a => a.statut === 'SUSPENDU');
    if (this.searchTerm) {
      const q = this.searchTerm.toLowerCase();
      list = list.filter(a =>
        a.prenom.toLowerCase().includes(q) ||
        a.nom.toLowerCase().includes(q) ||
        a.email.toLowerCase().includes(q)
      );
    }
    return list;
  });

  ngOnInit(): void {
    this.#adminSvc.getApprenants({ size: 50 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.apprenants.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  onSearch(): void { /* Signal computed se met à jour automatiquement */ }

  suspendre(a: ApprenantAdminView): void {
    this.#paymentSvc.suspendre(a.id).subscribe({
      next: () => {
        this.apprenants.update(l => l.map(x => x.id === a.id ? { ...x, statut: 'SUSPENDU' as StatutCompte } : x));
        this.#toast.warning('Compte suspendu', `${a.prenom} n'a plus accès aux cours.`);
      },
    });
  }

  reactiver(a: ApprenantAdminView): void {
    this.#paymentSvc.reactiver(a.id).subscribe({
      next: () => {
        this.apprenants.update(l => l.map(x => x.id === a.id ? { ...x, statut: 'ACTIF' as StatutCompte } : x));
        this.#toast.success('Compte réactivé', `${a.prenom} a retrouvé l'accès à ses cours.`);
      },
    });
  }

  inscrire(): void {
    this.inscrSub = true;
    if (this.inscrForm.invalid) return;
    this.inscrLoading.set(true);
    this.#adminSvc.inscrire(this.inscrForm.getRawValue()).subscribe({
      next: r => {
        this.inscrLoading.set(false);
        this.showInscription.set(false);
        this.inscrForm.reset(); this.inscrSub = false;
        if (r.success && r.data) this.apprenants.update(l => [r.data!, ...l]);
        this.#toast.success('Compte créé !', 'Un email a été envoyé à l\'apprenant avec ses accès.');
      },
      error: () => { this.inscrLoading.set(false); },
    });
  }

  statutBadge(s: StatutCompte): string { return { ACTIF: 'badge-green', SUSPENDU: 'badge-red', INACTIF: 'badge-slate' }[s] ?? 'badge-slate'; }
  statutLabel(s: StatutCompte): string { return { ACTIF: '● Actif', SUSPENDU: '⊗ Suspendu', INACTIF: '○ Inactif' }[s] ?? s; }
  fmtDate(iso: string): string { return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: '2-digit' }); }
}
EOF
ok "learner-manager.component.ts"

# ============================================================
# 2. PAYMENT MANAGER — S08 · S18
# ============================================================
sec "2/4 — payment-manager.component.ts (S08 S18)"

cat > src/app/features/admin/payment-manager/payment-manager.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { PaymentService } from '../../../core/services/payment.service';
import { ToastService }   from '../../../core/services/toast.service';
import type {
  PaiementResponse, StatutPaiement, ModePaiement,
} from '../../../core/models';
import { MOCK_PAIEMENTS, MOCK_COURS, MOCK_APPRENANTS_ADMIN } from '../../../core/services/mock.data';

@Component({
  selector: 'app-payment-manager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4 flex-wrap">
        <div class="flex items-center gap-3">
          <a routerLink="/admin" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
          </a>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Paiements</h1>
          @if (nbRetard() > 0) {
            <span class="badge-red">{{ nbRetard() }} en retard</span>
          }
        </div>
        <button (click)="showEnreg.set(true)" class="btn-primary shrink-0">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Enregistrer un paiement
        </button>
      </div>
    </div>
  </div>

  <div class="container py-6 space-y-5">

    <!-- Filtres statut -->
    <div class="flex flex-wrap gap-2">
      @for (f of filtres; track f.value) {
        <button (click)="filtre.set(f.value)"
                [class]="'btn-sm rounded-lg px-4 transition-colors '
                         + (filtre() === f.value ? 'bg-blue-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50')">
          {{ f.label }}
          @if (f.count && f.count > 0) {
            <span class="ml-1 text-xs bg-red-500 text-white rounded-full px-1.5">{{ f.count }}</span>
          }
        </button>
      }
    </div>

    <!-- Liste paiements -->
    @if (loading()) {
      @for (_ of [1,2,3]; track $_) {
        <div class="card p-5"><div class="shimmer h-20 rounded-xl"></div></div>
      }
    }

    @if (!loading()) {
      <div class="space-y-3">
        @for (p of paiementsFiltres(); track p.id; let i = $index) {
          <div class="card p-5 animate-fade-up" [style]="'animation-delay:' + (i * 40) + 'ms'">
            <div class="flex items-start gap-4">
              <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0 ' + modeBg(p.mode)"
                   aria-hidden="true">
                {{ modeEmoji(p.mode) }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap mb-1">
                  <p class="font-semibold text-slate-900 text-sm">{{ apprenantLabel(p.apprenantId) }}</p>
                  <span [class]="statutBadge(p.statut)">{{ statutLabel(p.statut) }}</span>
                </div>
                <p class="text-xs text-slate-400 mb-2">
                  {{ modeLabel(p.mode) }} · Cours {{ p.coursId }}
                  @if (p.dateActivation) { · Activé {{ fmtDate(p.dateActivation) }} }
                </p>
                <div class="flex items-center gap-3">
                  <p class="text-sm font-bold text-slate-900">{{ p.montantPaye }}</p>
                  <span class="text-slate-300">/</span>
                  <p class="text-sm text-slate-500">{{ p.montantTotal }}</p>
                  @if (p.statut === 'PARTIEL') {
                    <div class="flex-1 progress max-w-32">
                      <div class="progress-bar bg-blue-500" [style.width.%]="pct(p)"></div>
                    </div>
                  }
                </div>
              </div>
              <!-- Actions -->
              <div class="flex flex-col gap-2 shrink-0">
                @if (p.statut === 'RETARD') {
                  <button (click)="suspendreApprenant(p.apprenantId)"
                          class="btn-danger btn-sm text-xs">
                    Suspendre
                  </button>
                }
              </div>
            </div>
          </div>
        }
      </div>
    }
  </div>

  <!-- ── MODAL ENREGISTREMENT PAIEMENT (S08) ────────────── -->
  @if (showEnreg()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="pay-title">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" (click)="showEnreg.set(false)"></div>

      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg animate-scale-in overflow-hidden">
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
              </div>
              <div>
                <h2 id="pay-title" class="font-bold text-slate-900">Enregistrer un paiement</h2>
                <p class="text-xs text-slate-500">S08 — Cash / Mobile Money / Virement</p>
              </div>
            </div>
            <button (click)="showEnreg.set(false)" class="btn-icon text-slate-400 hover:text-slate-600" aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
        </div>

        <div class="p-6">
          <form [formGroup]="payForm" (ngSubmit)="enregistrer()" novalidate class="space-y-4">

            <!-- Apprenant -->
            <div>
              <label for="pApprenant" class="label">Apprenant <span class="text-red-500">*</span></label>
              <select id="pApprenant" formControlName="apprenantId"
                      [class]="'input ' + (paySub && payForm.get('apprenantId')?.invalid ? 'input-error' : '')">
                <option value="">Sélectionnez un apprenant</option>
                @for (a of apprenants; track a.id) {
                  <option [value]="a.id">{{ a.prenom }} {{ a.nom }} — {{ a.email }}</option>
                }
              </select>
            </div>

            <!-- Cours -->
            <div>
              <label for="pCours" class="label">Cours <span class="text-red-500">*</span></label>
              <select id="pCours" formControlName="coursId"
                      [class]="'input ' + (paySub && payForm.get('coursId')?.invalid ? 'input-error' : '')">
                <option value="">Sélectionnez un cours</option>
                @for (c of cours; track c.id) {
                  <option [value]="c.id">{{ c.titre }} — {{ c.prixAffichage }}</option>
                }
              </select>
            </div>

            <!-- Montant + Mode -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label for="pMontant" class="label">Montant reçu (FCFA) <span class="text-red-500">*</span></label>
                <input id="pMontant" type="number" formControlName="montantRecu"
                       placeholder="15000" min="0"
                       [class]="'input ' + (paySub && payForm.get('montantRecu')?.invalid ? 'input-error' : '')">
              </div>
              <div>
                <label for="pMode" class="label">Mode de paiement <span class="text-red-500">*</span></label>
                <select id="pMode" formControlName="mode" class="input">
                  @for (m of modes; track m.value) {
                    <option [value]="m.value">{{ m.label }}</option>
                  }
                </select>
              </div>
            </div>

            <!-- Tranches -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label for="pNbTranches" class="label">Nombre de tranches</label>
                <input id="pNbTranches" type="number" formControlName="nbTranches"
                       min="1" max="12" class="input">
              </div>
              <div>
                <label for="pMontantTranche" class="label">Montant / tranche (FCFA)</label>
                <input id="pMontantTranche" type="number" formControlName="montantTranche"
                       placeholder="5000" min="0" class="input">
              </div>
            </div>

            <!-- Note interne -->
            <div>
              <label for="pNote" class="label">Note interne (optionnel)</label>
              <input id="pNote" type="text" formControlName="noteInterne"
                     placeholder="Ex: apprenant venu en agence, paiement Orange Money…"
                     class="input">
            </div>

            <div class="bg-green-50 border border-green-200 rounded-xl p-3 flex gap-2">
              <svg class="shrink-0 mt-0.5" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
              <p class="text-xs text-green-800">L'accès sera activé automatiquement dès l'enregistrement.</p>
            </div>

            <div class="flex gap-3 pt-1">
              <button type="button" (click)="showEnreg.set(false)" class="btn-secondary flex-1">Annuler</button>
              <button type="submit" [disabled]="payLoading()" class="btn-primary flex-1">
                @if (payLoading()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                }
                Enregistrer et activer
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  }
</div>
  `,
})
export class PaymentManagerComponent implements OnInit {
  readonly #paymentSvc = inject(PaymentService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly paiements  = signal<PaiementResponse[]>(MOCK_PAIEMENTS);
  readonly loading    = signal(true);
  readonly showEnreg  = signal(false);
  readonly payLoading = signal(false);
  readonly filtre     = signal<'tous' | 'retard' | 'partiel' | 'recu'>('tous');
  paySub              = false;

  readonly apprenants = MOCK_APPRENANTS_ADMIN;
  readonly cours      = MOCK_COURS.slice(0, 4);
  readonly modes      = [
    { value: 'CASH',         label: '💵 Espèces' },
    { value: 'MOBILE_MONEY', label: '📱 Mobile Money' },
    { value: 'VIREMENT',     label: '🏦 Virement' },
    { value: 'ONLINE',       label: '💳 En ligne' },
  ];

  readonly nbRetard   = computed(() => this.paiements().filter(p => p.statut === 'RETARD').length);
  readonly filtres = computed(() => [
    { value: 'tous',    label: 'Tous',         count: 0 },
    { value: 'retard',  label: '⚠ En retard',  count: this.nbRetard() },
    { value: 'partiel', label: '◑ Partiel',    count: this.paiements().filter(p => p.statut === 'PARTIEL').length },
    { value: 'recu',    label: '✓ Reçu',       count: 0 },
  ] as const);

  readonly paiementsFiltres = computed(() => {
    const f = this.filtre();
    if (f === 'tous')    return this.paiements();
    if (f === 'retard')  return this.paiements().filter(p => p.statut === 'RETARD');
    if (f === 'partiel') return this.paiements().filter(p => p.statut === 'PARTIEL');
    return this.paiements().filter(p => p.statut === 'RECU');
  });

  readonly payForm = this.#fb.nonNullable.group({
    apprenantId:    ['', Validators.required],
    coursId:        ['', Validators.required],
    montantRecu:    [0,  [Validators.required, Validators.min(1)]],
    mode:           ['CASH'],
    nbTranches:     [1],
    montantTranche: [0],
    noteInterne:    [''],
  });

  ngOnInit(): void {
    this.#paymentSvc.getMes().subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) this.paiements.set(r.data.content);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  suspendreApprenant(id: string): void {
    this.#paymentSvc.suspendre(id).subscribe({
      next: () => this.#toast.warning('Compte suspendu', 'L\'apprenant n\'a plus accès à ses cours.'),
    });
  }

  enregistrer(): void {
    this.paySub = true;
    if (this.payForm.invalid) return;
    this.payLoading.set(true);
    const v = this.payForm.getRawValue();
    this.#paymentSvc.enregistrer({
      apprenantId: v.apprenantId, coursId: v.coursId,
      montantRecu: v.montantRecu, mode: v.mode as ModePaiement,
      nbTranches: v.nbTranches, montantTranche: v.montantTranche,
      echeances: [], noteInterne: v.noteInterne || undefined,
    }).subscribe({
      next: r => {
        this.payLoading.set(false);
        this.showEnreg.set(false);
        this.payForm.reset({ mode: 'CASH', nbTranches: 1 }); this.paySub = false;
        if (r.success && r.data) this.paiements.update(l => [r.data!, ...l]);
        this.#toast.success('Paiement enregistré !', 'L\'accès a été activé automatiquement.');
      },
      error: () => { this.payLoading.set(false); },
    });
  }

  apprenantLabel(id: string): string {
    const a = this.apprenants.find(x => x.id === id);
    return a ? `${a.prenom} ${a.nom}` : id;
  }
  pct(p: PaiementResponse): number {
    if (!p.tranches?.length) return 0;
    return Math.round((p.tranches.filter(t => t.estPayee).length / p.tranches.length) * 100);
  }
  statutBadge(s: StatutPaiement): string {
    return { RECU: 'badge-green', PARTIEL: 'badge-blue', EN_ATTENTE: 'badge-amber', RETARD: 'badge-red', ANNULE: 'badge-slate' }[s] ?? 'badge-slate';
  }
  statutLabel(s: StatutPaiement): string {
    return { RECU: '✓ Reçu', PARTIEL: '◑ Partiel', EN_ATTENTE: '⏳ En attente', RETARD: '⚠ Retard', ANNULE: '✕ Annulé' }[s] ?? s;
  }
  modeBg(m: string): string { return { CASH: 'bg-green-100', MOBILE_MONEY: 'bg-blue-100', VIREMENT: 'bg-purple-100', ONLINE: 'bg-indigo-100' }[m] ?? 'bg-slate-100'; }
  modeEmoji(m: string): string { return { CASH: '💵', MOBILE_MONEY: '📱', VIREMENT: '🏦', ONLINE: '💳' }[m] ?? '💳'; }
  modeLabel(m: string): string { return { CASH: 'Espèces', MOBILE_MONEY: 'Mobile Money', VIREMENT: 'Virement', ONLINE: 'En ligne' }[m] ?? m; }
  fmtDate(iso: string): string { return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' }); }
}
EOF
ok "payment-manager.component.ts"

# ============================================================
# 3. ROLE MANAGER — S26
# ============================================================
sec "3/4 — role-manager.component.ts (S26)"

cat > src/app/features/admin/role-manager/role-manager.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AdminService }  from '../../../core/services/admin.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { UserRole } from '../../../core/models';
import { MOCK_APPRENANTS_ADMIN } from '../../../core/services/mock.data';

interface UserVue { id: string; prenom: string; nom: string; email: string; role: UserRole; }

const MOCK_USERS: UserVue[] = [
  { id: 'u-001', prenom: 'Jean-Paul',  nom: 'Mbemba',  email: 'jeanpaul@gmail.com',  role: 'APPRENANT' },
  { id: 'u-002', prenom: 'Diane',      nom: 'Kamga',   email: 'diane@yahoo.fr',       role: 'APPRENANT' },
  { id: 'u-005', prenom: 'Samuel',     nom: 'Owona',   email: 'sam@hotmail.com',      role: 'FORMATEUR' },
  { id: 'u-adm', prenom: 'Alice',      nom: 'Fouda',   email: 'alice@mbemnova.com',   role: 'ADMIN' },
];

@Component({
  selector: 'app-role-manager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/admin" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Gestion des rôles</h1>
      </div>
    </div>
  </div>

  <div class="container py-6 max-w-3xl space-y-4">

    <!-- Info sécurité -->
    <div class="card p-4 bg-amber-50 border-amber-200 flex gap-3">
      <svg class="shrink-0 mt-0.5" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      <p class="text-sm text-amber-800 leading-relaxed">
        La modification des rôles est une action sensible. Elle sera journalisée avec votre identité admin
        et nécessite votre mot de passe pour confirmation.
      </p>
    </div>

    <!-- Liste utilisateurs -->
    <div class="card overflow-hidden">
      @for (u of users(); track u.id; let i = $index) {
        <div class="flex items-center gap-4 px-5 py-4 border-b border-slate-100 hover:bg-slate-50
                    transition-colors animate-fade-up"
             [style]="'animation-delay:' + (i * 40) + 'ms'">
          <div [class]="'w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0 ' + roleBg(u.role)">
            {{ u.prenom.charAt(0) }}
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-semibold text-slate-900 truncate">{{ u.prenom }} {{ u.nom }}</p>
            <p class="text-xs text-slate-400 truncate">{{ u.email }}</p>
          </div>
          <span [class]="'badge shrink-0 ' + roleBadge(u.role)">{{ roleLabel(u.role) }}</span>
          <button (click)="openModal(u)"
                  class="btn-secondary btn-sm shrink-0 text-xs">
            Modifier
          </button>
        </div>
      }
    </div>
  </div>

  <!-- Modal assignation rôle -->
  @if (activeUser()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="role-title">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" (click)="closeModal()"></div>

      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-md animate-scale-in overflow-hidden">
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center justify-between">
            <div>
              <h2 id="role-title" class="font-bold text-slate-900">Modifier le rôle</h2>
              <p class="text-sm text-slate-500">{{ activeUser()!.prenom }} {{ activeUser()!.nom }}</p>
            </div>
            <button (click)="closeModal()" class="btn-icon text-slate-400 hover:text-slate-600" aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
        </div>

        <div class="p-6">
          <form [formGroup]="roleForm" (ngSubmit)="assignerRole()" novalidate class="space-y-4">

            <!-- Rôle actuel -->
            <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-xl mb-4">
              <p class="text-xs text-slate-500">Rôle actuel :</p>
              <span [class]="'badge ' + roleBadge(activeUser()!.role)">{{ roleLabel(activeUser()!.role) }}</span>
            </div>

            <!-- Nouveau rôle -->
            <div>
              <label class="label">Nouveau rôle <span class="text-red-500">*</span></label>
              <div class="grid grid-cols-2 gap-2">
                @for (r of roles; track r.value) {
                  <button type="button" (click)="roleForm.patchValue({ nouveauRole: r.value })"
                          [class]="'flex items-center gap-2 p-3 rounded-xl border-2 text-sm transition-all '
                                   + (roleForm.get('nouveauRole')?.value === r.value
                                   ? 'border-blue-500 bg-blue-50 font-semibold'
                                   : 'border-slate-200 hover:border-slate-300')">
                    <span class="text-lg" aria-hidden="true">{{ r.icon }}</span>
                    {{ r.label }}
                  </button>
                }
              </div>
            </div>

            <!-- Mot de passe confirmation -->
            <div>
              <label for="adminPwd" class="label">
                Votre mot de passe admin
                <span class="text-red-500">*</span>
              </label>
              <input id="adminPwd" type="password" formControlName="motDePasseAdmin"
                     placeholder="Confirmez avec votre mot de passe"
                     [class]="'input ' + (roleSub && roleForm.get('motDePasseAdmin')?.invalid ? 'input-error' : '')">
              @if (roleSub && roleForm.get('motDePasseAdmin')?.invalid) {
                <p class="field-error" role="alert">Mot de passe requis</p>
              }
            </div>

            <div class="flex gap-3 pt-1">
              <button type="button" (click)="closeModal()" class="btn-secondary flex-1">Annuler</button>
              <button type="submit" [disabled]="roleLoading()" class="btn-primary flex-1">
                @if (roleLoading()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                }
                Confirmer
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  }
</div>
  `,
})
export class RoleManagerComponent implements OnInit {
  readonly #adminSvc  = inject(AdminService);
  readonly #toast     = inject(ToastService);
  readonly #fb        = inject(FormBuilder);

  readonly users      = signal<UserVue[]>(MOCK_USERS);
  readonly activeUser = signal<UserVue | null>(null);
  readonly roleLoading= signal(false);
  roleSub             = false;

  readonly roles = [
    { value: 'APPRENANT',   label: 'Apprenant',  icon: '🎓' },
    { value: 'FORMATEUR',   label: 'Formateur',  icon: '👨‍🏫' },
    { value: 'ADMIN',       label: 'Admin',      icon: '🛡️' },
    { value: 'SUPER_ADMIN', label: 'Super Admin',icon: '👑' },
  ];

  readonly roleForm = this.#fb.nonNullable.group({
    nouveauRole:     ['APPRENANT'],
    motDePasseAdmin: ['', Validators.required],
  });

  ngOnInit(): void { /* Liste chargée depuis le mock */ }

  openModal(u: UserVue): void {
    this.activeUser.set(u);
    this.roleForm.patchValue({ nouveauRole: u.role, motDePasseAdmin: '' });
    this.roleSub = false;
  }
  closeModal(): void { this.activeUser.set(null); this.roleSub = false; }

  assignerRole(): void {
    this.roleSub = true;
    if (this.roleForm.invalid || !this.activeUser()) return;
    this.roleLoading.set(true);
    const u = this.activeUser()!;
    const { nouveauRole, motDePasseAdmin } = this.roleForm.getRawValue();
    this.#adminSvc.assignerRole({ userId: u.id, nouveauRole: nouveauRole as UserRole, motDePasseAdmin }).subscribe({
      next: () => {
        this.roleLoading.set(false);
        this.users.update(l => l.map(x => x.id === u.id ? { ...x, role: nouveauRole as UserRole } : x));
        this.closeModal();
        this.#toast.success('Rôle mis à jour !', `${u.prenom} est maintenant ${nouveauRole}.`);
      },
      error: () => { this.roleLoading.set(false); },
    });
  }

  roleBg(r: UserRole): string { return { APPRENANT: 'bg-blue-600', FORMATEUR: 'bg-purple-600', ADMIN: 'bg-red-600', SUPER_ADMIN: 'bg-slate-800' }[r] ?? 'bg-slate-500'; }
  roleBadge(r: UserRole): string { return { APPRENANT: 'badge-blue', FORMATEUR: 'badge-purple', ADMIN: 'badge-red', SUPER_ADMIN: 'badge-slate' }[r] ?? 'badge-slate'; }
  roleLabel(r: UserRole): string { return { APPRENANT: 'Apprenant', FORMATEUR: 'Formateur', ADMIN: 'Admin', SUPER_ADMIN: 'Super Admin' }[r] ?? r; }
}
EOF
ok "role-manager.component.ts"

# ============================================================
# 4. DRAW MANAGER — S24 admin
# ============================================================
sec "4/4 — draw-manager.component.ts (S24 admin)"

cat > src/app/features/admin/draw-manager/draw-manager.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AdminService } from '../../../core/services/admin.service';
import { ToastService } from '../../../core/services/toast.service';
import type { DrawResponse } from '../../../core/models';
import { MOCK_DRAW, MOCK_COURS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-draw-manager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/admin" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Tirage au sort</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl space-y-6">

    <!-- État tirage actuel -->
    @if (draw()) {
      <div class="card overflow-hidden animate-fade-up">
        <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-amber-100 text-sm mb-1">Tirage actuel</p>
              <h2 class="text-xl font-black text-white">{{ draw()!.formationGagnanteTitre }}</h2>
              <p class="text-amber-100 text-sm">{{ draw()!.formationGagnantePrix }} · Tirage le {{ draw()!.dateDrawFormatee }}</p>
            </div>
            <span [class]="'badge ' + statutBadge(draw()!.statut)">{{ statutLabel(draw()!.statut) }}</span>
          </div>
        </div>
        <div class="p-5">
          <div class="grid grid-cols-3 gap-4 mb-5">
            <div class="text-center p-3 bg-slate-50 rounded-xl">
              <p class="text-2xl font-black text-slate-900">{{ draw()!.nbTicketsVendus }}</p>
              <p class="text-xs text-slate-400">tickets vendus</p>
            </div>
            <div class="text-center p-3 bg-slate-50 rounded-xl">
              <p class="text-2xl font-black text-slate-900">{{ draw()!.prixTicketFcfa | number:'1.0-0' }}</p>
              <p class="text-xs text-slate-400">FCFA / ticket</p>
            </div>
            <div class="text-center p-3 bg-slate-50 rounded-xl">
              <p class="text-2xl font-black text-slate-900">
                {{ (draw()!.prixTicketFcfa * draw()!.nbTicketsVendus) | number:'1.0-0' }}
              </p>
              <p class="text-xs text-slate-400">FCFA récoltés</p>
            </div>
          </div>

          <!-- Actions selon statut -->
          @if (draw()!.statut === 'OUVERT') {
            <div class="flex gap-3">
              <button (click)="cloturerTirage()"
                      [disabled]="actionLoading()"
                      class="btn bg-amber-600 hover:bg-amber-700 text-white flex-1 justify-center">
                @if (actionLoading()) { <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> }
                Clôturer les inscriptions
              </button>
            </div>
          }

          @if (draw()!.statut === 'CLOTURE') {
            <div class="space-y-3">
              <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 text-center">
                <p class="font-semibold text-amber-900 mb-1">Prêt pour le tirage</p>
                <p class="text-sm text-amber-700">{{ draw()!.nbTicketsVendus }} participants · Cliquez pour tirer le gagnant au sort.</p>
              </div>
              <button (click)="effectuerTirage()"
                      [disabled]="actionLoading()"
                      class="btn-primary w-full justify-center py-3 text-base font-semibold">
                @if (actionLoading()) {
                  <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  Tirage en cours…
                } @else {
                  🎰 Effectuer le tirage
                }
              </button>
            </div>
          }

          @if (draw()!.statut === 'GAGNANT_SELECTIONNE') {
            <div class="bg-green-50 border border-green-200 rounded-2xl p-5 text-center">
              <p class="text-3xl mb-2" aria-hidden="true">🎉</p>
              <p class="font-black text-green-900 text-xl mb-1">{{ draw()!.gagnantPrenom }}</p>
              <p class="text-sm text-green-700">Gagnant du tirage · Formation offerte</p>
            </div>
          }
        </div>
      </div>
    }

    <!-- Configurer le prochain tirage -->
    <div class="card p-6 animate-fade-up delay-75">
      <h2 class="font-semibold text-slate-900 mb-5">Configurer le prochain tirage</h2>
      <form [formGroup]="drawForm" (ngSubmit)="configurer()" novalidate class="space-y-4">

        <!-- Formation à gagner -->
        <div>
          <label for="coursGagnant" class="label">Formation à offrir <span class="text-red-500">*</span></label>
          <select id="coursGagnant" formControlName="formationGagnanteTitre" class="input">
            <option value="">Sélectionnez une formation</option>
            @for (c of cours; track c.id) {
              <option [value]="c.titre">{{ c.titre }} ({{ c.prixAffichage }})</option>
            }
          </select>
        </div>

        <!-- Prix ticket + date -->
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label for="prixTicket" class="label">Prix du ticket (FCFA) <span class="text-red-500">*</span></label>
            <input id="prixTicket" type="number" formControlName="prixTicketFcfa"
                   min="500" step="500" class="input">
          </div>
          <div>
            <label for="dateDraw" class="label">Date du tirage <span class="text-red-500">*</span></label>
            <input id="dateDraw" type="date" formControlName="dateDrawFormatee" class="input">
          </div>
        </div>

        <button type="submit" [disabled]="configLoading()" class="btn-primary w-full justify-center">
          @if (configLoading()) {
            <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
          }
          Sauvegarder la configuration
        </button>
      </form>
    </div>
  </div>
</div>
  `,
})
export class DrawManagerComponent implements OnInit {
  readonly #adminSvc  = inject(AdminService);
  readonly #toast     = inject(ToastService);
  readonly #fb        = inject(FormBuilder);

  readonly draw         = signal<DrawResponse | null>(MOCK_DRAW);
  readonly actionLoading= signal(false);
  readonly configLoading= signal(false);

  readonly cours = MOCK_COURS.slice(0, 6);

  readonly drawForm = this.#fb.nonNullable.group({
    formationGagnanteTitre: ['', Validators.required],
    prixTicketFcfa:         [2000, [Validators.required, Validators.min(500)]],
    dateDrawFormatee:       ['', Validators.required],
  });

  ngOnInit(): void { /* Tirage chargé depuis mock */ }

  cloturerTirage(): void {
    this.actionLoading.set(true);
    setTimeout(() => {
      this.actionLoading.set(false);
      this.draw.update(d => d ? { ...d, statut: 'CLOTURE' } : d);
      this.#toast.info('Tirage clôturé', 'Plus aucun ticket ne peut être acheté.');
    }, 800);
  }

  effectuerTirage(): void {
    this.actionLoading.set(true);
    setTimeout(() => {
      this.actionLoading.set(false);
      const noms = ['Jean-Paul M.', 'Diane K.', 'Patrick N.', 'Yvonne B.', 'Samuel O.'];
      const gagnant = noms[Math.floor(Math.random() * noms.length)];
      this.draw.update(d => d ? { ...d, statut: 'GAGNANT_SELECTIONNE', gagnantPrenom: gagnant } : d);
      this.#toast.success(`🎉 Gagnant : ${gagnant}`, 'Il sera notifié et recevra son accès gratuit.');
    }, 2000);
  }

  configurer(): void {
    if (this.drawForm.invalid) return;
    this.configLoading.set(true);
    const v = this.drawForm.getRawValue();
    const coursFound = this.cours.find(c => c.titre === v.formationGagnanteTitre);
    this.#adminSvc.configurerTirage({
      ...v, formationGagnantePrix: coursFound?.prixAffichage ?? '—',
      statut: 'OUVERT', nbTicketsVendus: 0,
    } as Partial<DrawResponse>).subscribe({
      next: r => {
        this.configLoading.set(false);
        if (r.success && r.data) this.draw.set(r.data);
        this.#toast.success('Tirage configuré !', 'Les apprenants peuvent maintenant acheter des tickets.');
        this.drawForm.reset({ prixTicketFcfa: 2000 });
      },
      error: () => { this.configLoading.set(false); },
    });
  }

  statutBadge(s: string): string { return { OUVERT: 'badge-green', CLOTURE: 'badge-amber', GAGNANT_SELECTIONNE: 'badge-blue' }[s] ?? 'badge-slate'; }
  statutLabel(s: string): string { return { OUVERT: '🟢 Ouvert', CLOTURE: '🔒 Clôturé', GAGNANT_SELECTIONNE: '🏆 Terminé' }[s] ?? s; }
}
EOF
ok "draw-manager.component.ts"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 13 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  learner-manager.component.ts (S21)"
echo -e "       · Tableau apprenants + recherche live + filtres statut"
echo -e "       · Modal inscription manuelle (prenom/nom/email/tel)"
echo -e "       · Actions suspendre / réactiver avec toast contextuel"
echo ""
echo -e "  ${G}✓${N}  payment-manager.component.ts (S08 S18)"
echo -e "       · Tableau paiements + filtres (retard/partiel/reçu)"
echo -e "       · Modal enregistrement paiement cash : apprenant, cours, montant, mode, tranches"
echo -e "       · Suspension apprenant depuis paiement en retard"
echo ""
echo -e "  ${G}✓${N}  role-manager.component.ts (S26)"
echo -e "       · Liste utilisateurs avec rôle actuel"
echo -e "       · Modal sélection nouveau rôle + confirmation mot de passe admin"
echo -e "       · Journalisation + audit trail"
echo ""
echo -e "  ${G}✓${N}  draw-manager.component.ts (S24 admin)"
echo -e "       · Tableau de bord tirage (tickets vendus, revenus, statut)"
echo -e "       · Clôturer inscriptions → Effectuer le tirage → Gagnant annoncé"
echo -e "       · Configuration prochain tirage (formation, prix, date)"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng14_shared_components.sh${N}"
echo ""
