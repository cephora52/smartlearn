import { ChangeDetectorRef, Component, computed, inject, signal } from '@angular/core';
import { MOCK_LEADERBOARD } from '../../../../../core/services/mock.data';
import { RouterModule } from '@angular/router';
import { CommonModule, DecimalPipe } from '@angular/common';


// ── Augmented talent type (add fields to your real model as needed) ──────────
export interface TalentEntry {
  userId: string;
  prenom: string;
  nom?: string;
  photoUrl?: string;
  specialite?: string;
  xpTotal: number;
  streakJours: number;
  coursTermines?: number;
}

@Component({
  selector: 'app-profil',
  imports: [CommonModule, RouterModule, DecimalPipe],
  templateUrl: './profil.html',
  styleUrl: './profil.css',
})
export class Profil {

    readonly stats = [
    { value: '247+',  label: 'apprenants actifs en Afrique Centrale' },
    { value: '2 000+',label: 'diplômés depuis 2020' },
    { value: '4.1/5', label: 'note moyenne sur Trustpilot' },
    { value: '87%',   label: 'trouvent un emploi en 6 mois' },
  ];

readonly #cdr = inject(ChangeDetectorRef);

readonly talents = signal<TalentEntry[]>([]);

readonly topTalents = computed(() => this.talents().slice(0, 3));
readonly remainingTalents = computed(() => this.talents().slice(3, 10));

ngOnInit(): void {
  this.talents.set(MOCK_LEADERBOARD as TalentEntry[]);
}
  // ── Podium card styling ──────────────────────────────────────────────────
 
  /** Card background + border per rank */
  podiumCardClass(i: number): string {
    return [
      // 1st — gold
      'bg-gradient-to-b from-amber-950/40 to-[#1e293b] border-amber-500/25 hover:border-amber-500/50',
      // 2nd — silver
      'bg-gradient-to-b from-slate-700/30 to-[#1e293b] border-slate-500/20 hover:border-slate-400/40',
      // 3rd — bronze
      'bg-gradient-to-b from-orange-950/30 to-[#1e293b] border-orange-700/20 hover:border-orange-600/40',
    ][i] ?? 'bg-[#1e293b] border-white/10';
  }
 
  /** Desktop order: 2nd | 1st | 3rd */
  podiumOrder(i: number): number {
    return [1, 0, 2][i] ?? i;
  }
 
  /** Accent bar color at top of card */
  rankAccentBar(i: number): string {
    return [
      'bg-gradient-to-r from-amber-600 via-amber-400 to-amber-600',
      'bg-gradient-to-r from-slate-500 via-slate-300 to-slate-500',
      'bg-gradient-to-r from-orange-700 via-orange-500 to-orange-700',
    ][i] ?? 'bg-indigo-600';
  }
 
  /** Rank badge (the #1 #2 #3 circle) */
  rankBadgeClass(i: number): string {
    return [
      'bg-amber-400/15 text-amber-400 ring-1 ring-amber-500/30',
      'bg-slate-400/15 text-slate-300 ring-1 ring-slate-400/30',
      'bg-orange-500/15 text-orange-400 ring-1 ring-orange-500/30',
    ][i] ?? 'bg-white/10 text-white';
  }
 
  /** XP score color per rank */
  rankScoreColor(i: number): string {
    return ['text-amber-400', 'text-slate-300', 'text-orange-400'][i] ?? 'text-white';
  }
 
  /** Avatar background for fallback initials */
  avatarBg(i: number): string {
    return [
      'bg-gradient-to-br from-amber-600 to-amber-800',
      'bg-gradient-to-br from-slate-500 to-slate-700',
      'bg-gradient-to-br from-orange-600 to-orange-800',
    ][i] ?? 'bg-indigo-700';
  }
 
  /** Extra height block at bottom to create visual podium levels (desktop) */
  podiumBase(i: number): string {
    return ['h-3', 'h-0', 'h-1.5'][i] ?? 'h-0';
  }
}