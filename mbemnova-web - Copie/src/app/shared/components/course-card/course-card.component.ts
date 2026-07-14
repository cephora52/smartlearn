import { ChangeDetectionStrategy, Component, Input, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import type { CoursResponse } from '../../../core/models';

@Component({
  selector: 'app-course-card',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './course-card.component.html',
  styleUrl: './course-card.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseCardComponent {
  @Input({ required: true }) course!: CoursResponse;
  @Input() delay = 0;

  readonly useFallback = signal(false);

  onImgError(): void {
    this.useFallback.set(true);
  }

  // ── View helpers ─────────────────────────────────────────────────────────

  /** Gradient stop 1 per level */
  levelColor1(niveau: string): string {
    return {
      DEBUTANT:      '#059669',
      INTERMEDIAIRE: '#4f46e5',
      AVANCE:        '#7c3aed',
    }[niveau] ?? '#4f46e5';
  }

  /** Gradient stop 2 per level */
  levelColor2(niveau: string): string {
    return {
      DEBUTANT:      '#065f46',
      INTERMEDIAIRE: '#1e1b4b',
      AVANCE:        '#4c1d95',
    }[niveau] ?? '#1e1b4b';
  }

  /** Background class for banner container */
  levelBg(niveau: string): string {
    return {
      DEBUTANT:      'bg-emerald-900',
      INTERMEDIAIRE: 'bg-indigo-950',
      AVANCE:        'bg-violet-950',
    }[niveau] ?? 'bg-indigo-950';
  }

  /** Dot color for level badge */
  levelDot(niveau: string): string {
    return {
      DEBUTANT:      'bg-emerald-400',
      INTERMEDIAIRE: 'bg-indigo-400',
      AVANCE:        'bg-violet-400',
    }[niveau] ?? 'bg-indigo-400';
  }

  /** Human-readable level label */
  levelLabel(niveau: string): string {
    return {
      DEBUTANT:      'Débutant',
      INTERMEDIAIRE: 'Intermédiaire',
      AVANCE:        'Avancé',
    }[niveau] ?? niveau;
  }

  formatDuration(minutes: number): string {
    if (!minutes) return '0 min';
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    if (h > 0) {
      return `${h}h${m > 0 ? m + 'm' : ''}`;
    }
    return `${m} min`;
  }
}
