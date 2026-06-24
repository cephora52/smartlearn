import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import type { LeaderboardEntry } from '../../../core/models';
import { MOCK_LEADERBOARD } from '../../../core/services/mock.data';

@Component({
  selector: 'app-leaderboard',
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
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Classement</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl">

    <!-- Podium top 3 -->
    @if (!loading() && entries().length >= 3) {
      <div class="flex items-end justify-center gap-4 mb-10 animate-fade-up">
        <!-- 2ème -->
        <div class="text-center">
          <div class="w-16 h-16 rounded-2xl bg-slate-100 border-2 border-slate-300 flex items-center justify-center text-2xl font-black text-slate-500 mx-auto mb-2">
            {{ entries()[1].prenom.charAt(0) }}
          </div>
          <p class="text-xs font-semibold text-slate-700 truncate max-w-16">{{ entries()[1].prenom }}</p>
          <p class="text-xs text-slate-400">{{ entries()[1].xpTotal   }} XP</p>
          <!-- <p class="text-xs text-slate-400">{{ entries()[1].xpTotal | number:'1.0-0' }} XP</p> -->
          <div class="w-16 h-16 bg-slate-200 rounded-t-xl flex items-end justify-center pb-1 mt-2">
            <span class="text-2xl">🥈</span>
          </div>
        </div>
        <!-- 1er -->
        <div class="text-center -mb-2">
          <div class="w-20 h-20 rounded-2xl bg-amber-100 border-2 border-amber-400 flex items-center justify-center text-3xl font-black text-amber-600 mx-auto mb-2 relative">
            {{ entries()[0].prenom.charAt(0) }}
            <div class="absolute -top-3 left-1/2 -translate-x-1/2 text-xl">👑</div>
          </div>
          <p class="text-sm font-bold text-slate-900 truncate max-w-20">{{ entries()[0].prenom }}</p>
          <p class="text-xs text-amber-600 font-semibold">{{ entries()[0].xpTotal  ' }} XP</p>
          <!-- <p class="text-xs text-amber-600 font-semibold">{{ entries()[0].xpTotal | number:'1.0-0' }} XP</p> -->
          <div class="w-20 h-24 bg-amber-200 rounded-t-xl flex items-end justify-center pb-1 mt-2">
            <span class="text-3xl">🥇</span>
          </div>
        </div>
        <!-- 3ème -->
        <div class="text-center">
          <div class="w-16 h-16 rounded-2xl bg-orange-50 border-2 border-orange-300 flex items-center justify-center text-2xl font-black text-orange-500 mx-auto mb-2">
            {{ entries()[2].prenom.charAt(0) }}
          </div>
          <p class="text-xs font-semibold text-slate-700 truncate max-w-16">{{ entries()[2].prenom }}</p>
          <p class="text-xs text-slate-400">{{ entries()[2].xpTotal   }} XP</p>
          <!-- <p class="text-xs text-slate-400">{{ entries()[2].xpTotal | number:'1.0-0' }} XP</p> -->
          <div class="w-16 h-10 bg-orange-100 rounded-t-xl flex items-end justify-center pb-1 mt-2">
            <span class="text-xl">🥉</span>
          </div>
        </div>
      </div>
    }

    <!-- Liste complète -->
    @if (loading()) {
      <div class="space-y-2">
        @for (_ of [1,2,3,4,5]; track $index) {
          <div class="card p-4 flex items-center gap-3">
            <div class="shimmer w-8 h-8 rounded-lg shrink-0"></div>
            <div class="shimmer w-10 h-10 rounded-full shrink-0"></div>
            <div class="flex-1 space-y-1.5">
              <div class="shimmer h-4 rounded w-1/3"></div>
              <div class="shimmer h-3 rounded w-1/4"></div>
            </div>
            <div class="shimmer h-5 rounded w-16 shrink-0"></div>
          </div>
        }
      </div>
    }

    @if (!loading()) {
      <div class="space-y-2">
        @for (e of entries(); track e.userId; let i = $index) {
          <div [class]="'card p-4 flex items-center gap-3 animate-fade-up '
                        + (e.estMoi ? 'border-blue-200 bg-blue-50' : '')"
               [style]="'animation-delay:' + (i * 30) + 'ms'">
            <!-- Rang -->
            <div [class]="'w-9 h-9 rounded-xl flex items-center justify-center text-sm font-black shrink-0 '
                          + rankBg(i)"
                 [attr.aria-label]="'Rang ' + e.rang">
              {{ rankEmoji(i) }}
            </div>
            <!-- Avatar -->
            <div [class]="'w-10 h-10 rounded-full flex items-center justify-center text-white font-bold shrink-0 '
                          + (e.estMoi ? 'bg-blue-600' : 'bg-slate-500')">
              {{ e.prenom.charAt(0) }}
            </div>
            <!-- Infos -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <p class="text-sm font-semibold text-slate-900 truncate">{{ e.prenom }}</p>
                @if (e.estMoi) { <span class="badge-blue text-xs">Moi</span> }
              </div>
              <p class="text-xs text-slate-400">🔥 {{ e.streakJours }} jours de suite</p>
            </div>
            <!-- XP -->
            <div class="text-right shrink-0">
              <p class="text-sm font-black" [class]="e.estMoi ? 'text-blue-700' : 'text-slate-900'">
                {{ e.xpTotal   }}
                <!-- {{ e.xpTotal | number:'1.0-0' }} -->
              </p>
              <p class="text-xs text-slate-400">XP</p>
            </div>
          </div>
        }
      </div>
    }
  </div>
</div>
  `,
})
export class LeaderboardComponent implements OnInit {
  readonly #svc    = inject(TalentService);
  readonly entries = signal<LeaderboardEntry[]>(MOCK_LEADERBOARD);
  readonly loading = signal(true);

  ngOnInit(): void {
    this.#svc.getLeaderboard().subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.entries.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  rankEmoji(i: number): string { return ['🥇','🥈','🥉'][i] ?? '#' + (i + 1); }
  rankBg(i: number): string {
    return ['bg-amber-100','bg-slate-100','bg-orange-100'][i] ?? 'bg-slate-50';
  }
}
