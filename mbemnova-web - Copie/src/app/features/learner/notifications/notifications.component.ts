import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { NotificationService } from '../../../core/services/notification.service';
import { ToastService }        from '../../../core/services/toast.service';
import type { NotificationResponse } from '../../../core/models';
import { MOCK_NOTIFICATIONS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-notifications',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
          </a>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Notifications</h1>
          @if (unreadCount() > 0) {
            <span class="badge-red">{{ unreadCount() }}</span>
          }
        </div>
        @if (unreadCount() > 0) {
          <button (click)="markAllRead()" [disabled]="marking()"
                  class="btn-ghost btn-sm text-slate-500">
            @if (marking()) {
              <svg class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            }
            Tout marquer lu
          </button>
        }
      </div>
    </div>
  </div>

  <div class="container py-6 max-w-2xl">

    @if (loading()) {
      <div class="space-y-2">
        @for (_ of [1,2,3]; track $index) {
          <div class="card p-4 flex gap-3">
            <div class="shimmer w-10 h-10 rounded-xl shrink-0"></div>
            <div class="flex-1 space-y-2">
              <div class="shimmer h-4 rounded w-2/3"></div>
              <div class="shimmer h-3 rounded w-full"></div>
              <div class="shimmer h-3 rounded w-1/4"></div>
            </div>
          </div>
        }
      </div>
    }

    @if (!loading() && notifications().length === 0) {
      <div class="card p-14 text-center">
        <div class="text-5xl mb-3" aria-hidden="true">🔔</div>
        <p class="font-semibold text-slate-900 mb-1">Tout est à jour !</p>
        <p class="text-sm text-slate-500">Vous n'avez aucune notification pour le moment.</p>
      </div>
    }

    @if (!loading() && notifications().length > 0) {
      <div class="space-y-2">
        @for (n of notifications(); track n.id; let i = $index) {
          <a [routerLink]="n.lienAction ?? '/app'"
             class="card flex items-start gap-4 p-4 hover:shadow-md transition-shadow animate-fade-up group"
             [class.bg-blue-50]="!n.estLue"
             [class.border-blue-100]="!n.estLue"
             [style]="'animation-delay:' + (i * 40) + 'ms'">

            <!-- Icône type -->
            <div [class]="'w-10 h-10 rounded-xl flex items-center justify-center text-xl shrink-0 '
                          + iconBg(n.type)"
                 aria-hidden="true">
              {{ notifEmoji(n.type) }}
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex items-start gap-2 mb-0.5">
                <p class="text-sm font-semibold text-slate-900 leading-snug flex-1">{{ n.titre }}</p>
                @if (!n.estLue) {
                  <div class="w-2 h-2 bg-blue-500 rounded-full shrink-0 mt-1.5" aria-label="Non lue"></div>
                }
              </div>
              <p class="text-xs text-slate-500 leading-relaxed mb-1.5">{{ n.contenu }}</p>
              <p class="text-xs text-slate-400">{{ timeAgo(n.createdAt) }}</p>
            </div>

            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8"
                 stroke-width="2" class="shrink-0 mt-1 opacity-0 group-hover:opacity-100 transition-opacity" aria-hidden="true">
              <path d="M9 18l6-6-6-6"/>
            </svg>
          </a>
        }
      </div>
    }
  </div>
</div>
  `,
})
export class NotificationsComponent implements OnInit {
  readonly #svc   = inject(NotificationService);
  readonly #toast = inject(ToastService);

  readonly notifications = signal<NotificationResponse[]>(MOCK_NOTIFICATIONS);
  readonly loading       = signal(true);
  readonly marking       = signal(false);
  readonly unreadCount   = computed(() => this.notifications().filter(n => !n.estLue).length);

  ngOnInit(): void {
    this.#svc.getAll().subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.notifications.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  markAllRead(): void {
    this.marking.set(true);
    this.#svc.markAllRead().subscribe({
      next: () => {
        this.marking.set(false);
        this.notifications.update(list => list.map(n => ({ ...n, estLue: true })));
        this.#svc.unreadCount.set(0);
        this.#toast.success('Toutes les notifications sont marquées comme lues.');
      },
      error: () => { this.marking.set(false); },
    });
  }

  notifEmoji(type: string): string {
    const m: Record<string, string> = {
      PAIEMENT_ECHEANCE:'💳', PAIEMENT_RETARD:'⚠️', PAIEMENT_RECU:'✅',
      COURS_DEBLOQUE:'🔓', DEVOIR_PUBLIE:'📝', DEVOIR_CORRIGE:'✏️',
      REPONSE_COMMUNAUTE:'💬', PARRAINAGE_ACTIF:'🤝', TIRAGE_RESULTAT:'🎯',
      CERTIFICAT_GENERE:'🏆', COMPTE_SUSPENDU:'🚫', SYSTEME:'ℹ️',
    };
    return m[type] ?? 'ℹ️';
  }

  iconBg(type: string): string {
    if (type.includes('PAIEMENT'))       return 'bg-amber-100';
    if (type.includes('DEVOIR'))         return 'bg-blue-100';
    if (type === 'CERTIFICAT_GENERE')    return 'bg-green-100';
    if (type === 'COMPTE_SUSPENDU')      return 'bg-red-100';
    if (type === 'PARRAINAGE_ACTIF')     return 'bg-purple-100';
    if (type === 'TIRAGE_RESULTAT')      return 'bg-amber-100';
    return 'bg-slate-100';
  }

  timeAgo(iso: string): string {
    const diff = Date.now() - new Date(iso).getTime();
    const m = Math.floor(diff / 60_000);
    const h = Math.floor(diff / 3_600_000);
    const d = Math.floor(diff / 86_400_000);
    if (d >= 1) return `il y a ${d} jour${d > 1 ? 's' : ''}`;
    if (h >= 1) return `il y a ${h}h`;
    return `il y a ${m} min`;
  }
}
