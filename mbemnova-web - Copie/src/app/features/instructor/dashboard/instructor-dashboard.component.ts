import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit, OnDestroy, PLATFORM_ID,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { CourseService }     from '../../../core/services/course.service';
import { AdminService }      from '../../../core/services/admin.service';
import { SessionService }    from '../../../core/services/session.service';
import { AuthService }       from '../../../core/services/auth.service';
import type { CoursResponse, SessionResponse } from '../../../core/models';
import { MOCK_COURS, MOCK_SESSIONS } from '../../../core/services/mock.data';

const MOCK_RENDUS_ATTENTE = [
  {
    id: 'r-001', devoirId: 'd-001', apprenantId: 'u-002',
    contenu: 'Voici ma page HTML responsive avec flexbox et media queries. Lien GitHub : https://github.com/diane/profil-web',
    lienFichier: 'https://github.com/diane/profil-web',
    soumisLe: new Date(Date.now() - 86_400_000).toISOString(),
    note: null, commentaire: null, corrigeLe: null,
    prenomApprenant: 'Diane K.', titrDevoir: 'TP1 — Page de profil responsive',
  },
  {
    id: 'r-002', devoirId: 'd-001', apprenantId: 'u-003',
    contenu: 'J\'ai créé ma page avec CSS Grid. J\'ai eu du mal avec le responsive mais j\'ai réussi.',
    lienFichier: null,
    soumisLe: new Date(Date.now() - 2 * 86_400_000).toISOString(),
    note: null, commentaire: null, corrigeLe: null,
    prenomApprenant: 'Patrick N.', titrDevoir: 'TP1 — Page de profil responsive',
  },
  {
    id: 'r-003', devoirId: 'd-001', apprenantId: 'u-004',
    contenu: 'Page disponible sur : https://yvonne-portfolio.netlify.app Design moderne avec animations CSS.',
    lienFichier: 'https://yvonne-portfolio.netlify.app',
    soumisLe: new Date(Date.now() - 3 * 86_400_000).toISOString(),
    note: 18, commentaire: 'Excellent travail ! Design très soigné.', corrigeLe: new Date(Date.now() - 86_400_000).toISOString(),
    prenomApprenant: 'Yvonne B.', titrDevoir: 'TP1 — Page de profil responsive',
  },
];

// Données progression mensuelle (6 derniers mois)
const PROGRESSION_DATA = [
  { mois: 'Déc', apprenants: 98,  revenus: 340000 },
  { mois: 'Jan', apprenants: 110, revenus: 390000 },
  { mois: 'Fév', apprenants: 119, revenus: 415000 },
  { mois: 'Mar', apprenants: 128, revenus: 460000 },
  { mois: 'Avr', apprenants: 135, revenus: 495000 },
  { mois: 'Mai', apprenants: 142, revenus: 530000 },
];

@Component({
  selector: 'app-instructor-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, CommonModule],
  templateUrl: './instructor-dashboard.html',
  styleUrl: './instructor-dashboard.css',
})
export class InstructorDashboardComponent implements OnInit, OnDestroy {
  readonly #auth       = inject(AuthService);
  readonly #courseSvc  = inject(CourseService);
  readonly #adminSvc   = inject(AdminService);
  readonly #sessionSvc = inject(SessionService);
  readonly #platformId = inject(PLATFORM_ID);

  // ── State ──
  readonly cours    = signal<CoursResponse[]>([]);
  readonly sessions = signal<SessionResponse[]>([]);
  readonly isLoading = signal(true);

  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Formateur');
  readonly rendusAttente = MOCK_RENDUS_ATTENTE.filter(r => r.note === null);
  readonly rendusTotal   = MOCK_RENDUS_ATTENTE.length;
  readonly progressionData = PROGRESSION_DATA;

  // KPIs
  readonly kpis = [
    { label: 'Cours publiés',     value: '3',    delta: '+1 ce mois',  positive: true,  icon: 'book'   },
    { label: 'Apprenants actifs', value: '142',  delta: '+7 ce mois',  positive: true,  icon: 'users'  },
    { label: 'À corriger',        value: '2',    delta: '1 urgent',    positive: false, icon: 'check'  },
    { label: 'Note moyenne',      value: '4.7',  delta: 'sur 5.0',     positive: true,  icon: 'star'   },
  ];

  // Chart max pour les barres relatives
  readonly chartMax = Math.max(...PROGRESSION_DATA.map(d => d.apprenants));

  private loadTimer: ReturnType<typeof setTimeout> | null = null;

  ngOnInit(): void {
    // Simule skeleton → données réelles
    if (isPlatformBrowser(this.#platformId)) {
      this.loadTimer = setTimeout(() => this.isLoading.set(false), 600);
    } else {
      this.isLoading.set(false);
    }

    this.#adminSvc.getMesCours().subscribe({
      next: r => { if (r.success && r.data) this.cours.set(r.data); },
    });
    this.#sessionSvc.getByCours('c-001').subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.sessions.set(r.data.content); },
    });
  }

  ngOnDestroy(): void {
    if (this.loadTimer) clearTimeout(this.loadTimer);
  }

  // ── Helpers ──
  levelBg(n: string): string {
    return { DEBUTANT: 'bg-emerald-50 text-emerald-700', INTERMEDIAIRE: 'bg-blue-50 text-blue-700', AVANCE: 'bg-violet-50 text-violet-700' }[n] ?? 'bg-slate-50 text-slate-700';
  }
  levelDot(n: string): string {
    return { DEBUTANT: 'bg-emerald-500', INTERMEDIAIRE: 'bg-blue-500', AVANCE: 'bg-violet-500' }[n] ?? 'bg-slate-400';
  }
  levelLabel(n: string): string {
    return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n;
  }
  modaliteLabel(m: string): string {
    return { MEET: 'En ligne', PRESENTIEL: 'Présentiel', HYBRIDE: 'Hybride' }[m] ?? m;
  }
  modaliteDot(m: string): string {
    return { MEET: 'bg-blue-500', PRESENTIEL: 'bg-emerald-500', HYBRIDE: 'bg-violet-500' }[m] ?? 'bg-slate-400';
  }
  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  }
  barHeight(val: number): number {
    return Math.round((val / this.chartMax) * 100);
  }
  relativeTime(iso: string): string {
    const diff = Date.now() - new Date(iso).getTime();
    const h = Math.floor(diff / 3_600_000);
    if (h < 24) return `il y a ${h}h`;
    return `il y a ${Math.floor(h / 24)}j`;
  }
  initials(prenom: string): string {
    return prenom.charAt(0).toUpperCase();
  }
}