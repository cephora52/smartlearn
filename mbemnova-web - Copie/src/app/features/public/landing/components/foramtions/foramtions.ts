import { ChangeDetectorRef, Component, computed, inject, OnInit, signal } from '@angular/core';
import { CourseService } from '../../../../../core/services/course.service';
import { CoursResponse, DrawResponse } from '../../../../../core/models';
import { MOCK_COURS, MOCK_DRAW, MOCK_LEADERBOARD } from '../../../../../core/services/mock.data';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';

// ── Local types ──────────────────────────────────────────────────────────────
 
interface DomainFilter {
  label: string;
}
 
interface TrustItem {
  icon: string;
  title: string;
  desc: string;
}
 

@Component({
  selector: 'app-foramtions',
  imports: [RouterLink,CommonModule],
  templateUrl: './foramtions.html',
  styleUrl: './foramtions.css',
})
export class Foramtions implements OnInit {

// ── DI ──
  readonly #courseSvc = inject(CourseService);
  readonly #cdr = inject(ChangeDetectorRef);
 
  // ── Math utility exposed to template ──
  readonly Math = Math;
 
  // ── State ──
  readonly isLoading   = signal(true);
  readonly cours       = signal<CoursResponse[]>([]);
  readonly activeDomaine = signal<string | null>(null);
 
  /** 6 skeleton placeholders while loading */
  readonly skeletons = Array.from({ length: 6 });
 
  // ── Computed filtered list ──
  readonly filteredCours = computed(() => {
    const all = this.cours();
    const domain = this.activeDomaine();
    const list = domain
      ? all.filter(c =>
          c.categorieNom?.toLowerCase().includes(domain.toLowerCase()) ||
          c.domaine?.toLowerCase().includes(domain.toLowerCase()) ||
          c.titre?.toLowerCase().includes(domain.toLowerCase())
        )
      : all;
    return list.slice(0, 6);
  });
 
  // ── Static data ──────────────────────────────────────────────────────────
 
  readonly domaines: DomainFilter[] = [
    { label: 'Bureautique & Productivité' },
    { label: 'Data et IA' },
    { label: 'Design Graphique et UI/UX' },
    { label: 'Développement Web et Mobile' },
    { label: 'Marketing et Communication' },
    { label: 'Réseaux Système et Sécurité' },
  ];
 
  readonly trustItems: TrustItem[] = [
    {
      icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z',
      title: 'Certification reconnue',
      desc: 'Vérifiable en ligne par les recruteurs partout en Afrique.',
    },
    {
      icon: 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z',
      title: 'Paiement en 3× sans frais',
      desc: 'Mobile Money, virement ou cash. Adapté à votre situation.',
    },
    {
      icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
      title: 'Mentor dédié',
      desc: 'Un expert vous suit de A à Z avec des sessions live personnalisées.',
    },
    {
      icon: 'M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z',
      title: 'Stage en entreprise',
      desc: 'Réseau de partenaires pour un stage de 1 à 3 mois garanti.',
    },
  ];
 
  // ── Lifecycle ────────────────────────────────────────────────────────────
 
  ngOnInit(): void {
    this.isLoading.set(true);
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => {
        if (r.success && r.data?.content) {
          this.cours.set(r.data.content);
        }
        this.isLoading.set(false);
        this.#cdr.markForCheck();
      },
      error: () => {
        this.isLoading.set(false);
        this.#cdr.markForCheck();
      }
    });
  }
 
  // ── Actions ──────────────────────────────────────────────────────────────
 
  setDomaine(label: string | null): void {
    this.activeDomaine.set(label);
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
}
 