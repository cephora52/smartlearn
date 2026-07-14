// course-detail.component.ts
import {
  ChangeDetectionStrategy, Component, inject,
  signal, input, OnInit, computed,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule, DecimalPipe } from '@angular/common';
import { CourseService }   from '../../../core/services/course.service';
import { SessionService }  from '../../../core/services/session.service';
import { AuthService }     from '../../../core/services/auth.service';
import { ToastService }    from '../../../core/services/toast.service';
import type { CoursDetailResponse, AvisCoursResponse, SessionResponse } from '../../../core/models';
import { MOCK_COURS_DETAIL, MOCK_AVIS, MOCK_SESSIONS } from '../../../core/services/mock.data';

interface Debouche {
  titre: string;
  salaireMin: number;
  salaireMax: number;
  demande: 'Forte' | 'Très forte' | 'Croissante';
}

@Component({
  selector: 'app-course-detail',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true,
  imports: [RouterLink, CommonModule, DecimalPipe],
  templateUrl: './course-detail.html',
  styleUrls: ['./course-detail.css'],
})
export class CourseDetailComponent implements OnInit {
  readonly slug = input<string>('');

  readonly #courseSvc   = inject(CourseService);
  readonly #sessionsSvc = inject(SessionService);
  readonly #auth        = inject(AuthService);
  readonly #toast       = inject(ToastService);
  readonly Math         = Math;

  readonly detail   = signal<CoursDetailResponse | null>(null);
  readonly sessions = signal<SessionResponse[]>([]);
  readonly avis     = signal<AvisCoursResponse[]>([]);
  readonly loading  = signal(true);
  readonly isAuth   = this.#auth.isAuthenticated;

  readonly isFormateur = computed(() => {
    const detail = this.detail();
    const user = this.#auth.currentUser();
    return !!detail && !!user && detail.formateurId === user.id;
  });

  readonly prixFormateurPct = () => 30;
  readonly prixAvecFormateur = computed(() =>
    Math.round((this.detail()?.prixFcfa ?? 0) * (1 + this.prixFormateurPct() / 100))
  );


  readonly avantages = [
    'Accès illimité à tout le contenu',
    '1 séance hebdomadaire avec votre mentor attribué',
    'Certificat officiel SmartLearn',
    'Projets concrets pour votre portfolio',
    'Paiement en plusieurs fois disponible',
  ];

  readonly debouches = computed<Debouche[]>(() => {
    const t = (this.detail()?.titre ?? '').toLowerCase();
    if (t.includes('market') || t.includes('communic')) return [
      { titre: 'Community Manager',         salaireMin: 150_000, salaireMax: 300_000,   demande: 'Forte' },
      { titre: 'Digital Marketing Manager', salaireMin: 250_000, salaireMax: 500_000,   demande: 'Très forte' },
      { titre: 'Traffic Manager',           salaireMin: 200_000, salaireMax: 400_000,   demande: 'Croissante' },
      { titre: 'Responsable Marketing',     salaireMin: 350_000, salaireMax: 700_000,   demande: 'Forte' },
    ];
    if (t.includes('data') || t.includes('ia') || t.includes('python')) return [
      { titre: 'Data Analyst',   salaireMin: 300_000, salaireMax: 600_000,   demande: 'Très forte' },
      { titre: 'BI Analyst',     salaireMin: 350_000, salaireMax: 700_000,   demande: 'Forte' },
      { titre: 'Data Scientist', salaireMin: 500_000, salaireMax: 1_000_000, demande: 'Très forte' },
      { titre: 'ML Engineer',    salaireMin: 600_000, salaireMax: 1_200_000, demande: 'Croissante' },
    ];
    if (t.includes('design') || t.includes('ui') || t.includes('ux')) return [
      { titre: 'UI Designer',      salaireMin: 200_000, salaireMax: 450_000, demande: 'Forte' },
      { titre: 'UX Designer',      salaireMin: 250_000, salaireMax: 550_000, demande: 'Très forte' },
      { titre: 'Product Designer', salaireMin: 350_000, salaireMax: 700_000, demande: 'Très forte' },
      { titre: 'Brand Designer',   salaireMin: 300_000, salaireMax: 600_000, demande: 'Croissante' },
    ];
    if (t.includes('réseau') || t.includes('sécur') || t.includes('cyber')) return [
      { titre: 'Admin Réseaux',  salaireMin: 250_000, salaireMax: 500_000,   demande: 'Forte' },
      { titre: 'Analyste Cyber', salaireMin: 400_000, salaireMax: 800_000,   demande: 'Très forte' },
      { titre: 'Ingénieur Sécu', salaireMin: 500_000, salaireMax: 1_000_000, demande: 'Très forte' },
      { titre: 'Consultant IT',  salaireMin: 350_000, salaireMax: 700_000,   demande: 'Croissante' },
    ];
    return [
      { titre: 'Développeur Front-end', salaireMin: 250_000, salaireMax: 500_000,   demande: 'Très forte' },
      { titre: 'Développeur Back-end',  salaireMin: 300_000, salaireMax: 600_000,   demande: 'Très forte' },
      { titre: 'Full Stack Developer',  salaireMin: 400_000, salaireMax: 800_000,   demande: 'Très forte' },
      { titre: 'Lead Technique',        salaireMin: 600_000, salaireMax: 1_200_000, demande: 'Forte' },
    ];
  });

  readonly domainSvg = computed<string>(() => {
    const t = (this.detail()?.titre ?? '').toLowerCase();
    if (t.includes('data') || t.includes('python') || t.includes('ia')) return `
      <svg viewBox="0 0 360 280" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="10" y="200" width="28" height="60" rx="4" fill="white"/>
        <rect x="48" y="160" width="28" height="100" rx="4" fill="white" opacity=".85"/>
        <rect x="86" y="115" width="28" height="145" rx="4" fill="white"/>
        <rect x="124" y="75" width="28" height="185" rx="4" fill="white" opacity=".9"/>
        <rect x="162" y="95" width="28" height="165" rx="4" fill="white" opacity=".85"/>
        <rect x="200" y="50" width="28" height="210" rx="4" fill="white"/>
        <rect x="238" y="70" width="28" height="190" rx="4" fill="white" opacity=".8"/>
        <rect x="276" y="30" width="28" height="230" rx="4" fill="white" opacity=".9"/>
        <polyline points="24,190 62,148 100,103 138,63 176,83 214,38 252,58 290,18" stroke="white" stroke-width="2" stroke-dasharray="5 3" fill="none" opacity=".6"/>
        <circle cx="24" cy="190" r="5" fill="white" opacity=".9"/>
        <circle cx="62" cy="148" r="5" fill="white" opacity=".9"/>
        <circle cx="100" cy="103" r="5" fill="white" opacity=".9"/>
        <circle cx="138" cy="63" r="5" fill="white" opacity=".9"/>
        <circle cx="176" cy="83" r="5" fill="white" opacity=".9"/>
        <circle cx="214" cy="38" r="6" fill="white"/>
        <circle cx="252" cy="58" r="5" fill="white" opacity=".9"/>
        <circle cx="290" cy="18" r="5" fill="white" opacity=".9"/>
      </svg>`;
    if (t.includes('design') || t.includes('ui') || t.includes('ux')) return `
      <svg viewBox="0 0 360 280" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="20" y="20" width="200" height="130" rx="14" fill="white" opacity=".1" stroke="white" stroke-width="1.5"/>
        <rect x="36" y="36" width="80" height="10" rx="5" fill="white" opacity=".5"/>
        <rect x="36" y="54" width="168" height="5" rx="2.5" fill="white" opacity=".25"/>
        <rect x="36" y="66" width="130" height="5" rx="2.5" fill="white" opacity=".2"/>
        <rect x="36" y="84" width="90" height="36" rx="8" fill="white" opacity=".3" stroke="white" stroke-width="1" opacity=".4"/>
        <circle cx="290" cy="90" r="64" fill="none" stroke="white" stroke-width="1.5" opacity=".25"/>
        <circle cx="290" cy="90" r="40" fill="white" opacity=".07"/>
        <circle cx="290" cy="90" r="18" fill="white" opacity=".12"/>
        <line x1="290" y1="26" x2="290" y2="50" stroke="white" stroke-width="1.5" opacity=".35"/>
        <line x1="290" y1="130" x2="290" y2="154" stroke="white" stroke-width="1.5" opacity=".35"/>
        <line x1="226" y1="90" x2="250" y2="90" stroke="white" stroke-width="1.5" opacity=".35"/>
        <line x1="330" y1="90" x2="354" y2="90" stroke="white" stroke-width="1.5" opacity=".35"/>
        <rect x="20" y="180" width="320" height="70" rx="12" fill="white" opacity=".07" stroke="white" stroke-width="1"/>
        <rect x="36" y="196" width="100" height="8" rx="4" fill="white" opacity=".3"/>
        <rect x="36" y="212" width="240" height="5" rx="2.5" fill="white" opacity=".15"/>
        <rect x="36" y="224" width="180" height="5" rx="2.5" fill="white" opacity=".12"/>
      </svg>`;
    if (t.includes('market') || t.includes('communic')) return `
      <svg viewBox="0 0 360 280" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="90" cy="120" r="68" fill="none" stroke="white" stroke-width="1.5" opacity=".2" stroke-dasharray="7 5"/>
        <circle cx="90" cy="120" r="44" fill="white" opacity=".07"/>
        <circle cx="90" cy="120" r="22" fill="white" opacity=".15"/>
        <line x1="128" y1="90" x2="200" y2="60" stroke="white" stroke-width="1.5" opacity=".45"/>
        <line x1="145" y1="128" x2="218" y2="140" stroke="white" stroke-width="1.5" opacity=".38"/>
        <line x1="120" y1="165" x2="200" y2="200" stroke="white" stroke-width="1.5" opacity=".38"/>
        <circle cx="210" cy="58" r="20" fill="white" opacity=".15" stroke="white" stroke-width="1"/>
        <circle cx="232" cy="140" r="28" fill="white" opacity=".12" stroke="white" stroke-width="1"/>
        <circle cx="210" cy="202" r="18" fill="white" opacity=".15" stroke="white" stroke-width="1"/>
        <circle cx="302" cy="82" r="14" fill="white" opacity=".1"/>
        <circle cx="318" cy="170" r="10" fill="white" opacity=".08"/>
      </svg>`;
    if (t.includes('réseau') || t.includes('sécur') || t.includes('cyber')) return `
      <svg viewBox="0 0 360 280" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="140" y="100" width="80" height="56" rx="8" fill="none" stroke="white" stroke-width="2" opacity=".4"/>
        <rect x="155" y="115" width="50" height="8" rx="3" fill="white" opacity=".3"/>
        <rect x="155" y="130" width="35" height="6" rx="3" fill="white" opacity=".2"/>
        <path d="M 180 156 L 180 178" stroke="white" stroke-width="2" opacity=".4"/>
        <rect x="150" y="178" width="60" height="24" rx="6" fill="white" opacity=".1" stroke="white" stroke-width="1.5"/>
        <circle cx="52" cy="60" r="22" fill="none" stroke="white" stroke-width="1.5" opacity=".35"/>
        <circle cx="308" cy="60" r="22" fill="none" stroke="white" stroke-width="1.5" opacity=".35"/>
        <circle cx="52" cy="210" r="22" fill="none" stroke="white" stroke-width="1.5" opacity=".35"/>
        <circle cx="308" cy="210" r="22" fill="none" stroke="white" stroke-width="1.5" opacity=".35"/>
        <line x1="74" y1="70" x2="140" y2="115" stroke="white" stroke-width="1" opacity=".25" stroke-dasharray="5 3"/>
        <line x1="286" y1="70" x2="220" y2="115" stroke="white" stroke-width="1" opacity=".25" stroke-dasharray="5 3"/>
        <line x1="74" y1="200" x2="150" y2="185" stroke="white" stroke-width="1" opacity=".25" stroke-dasharray="5 3"/>
        <line x1="286" y1="200" x2="210" y2="185" stroke="white" stroke-width="1" opacity=".25" stroke-dasharray="5 3"/>
        <circle cx="52" cy="60" r="8" fill="white" opacity=".2"/>
        <circle cx="308" cy="60" r="8" fill="white" opacity=".2"/>
        <circle cx="52" cy="210" r="8" fill="white" opacity=".2"/>
        <circle cx="308" cy="210" r="8" fill="white" opacity=".2"/>
      </svg>`;
    return `
      <svg viewBox="0 0 360 280" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="20" y="20" width="320" height="220" rx="16" fill="white" opacity=".05" stroke="white" stroke-width="1.5"/>
        <rect x="20" y="20" width="320" height="36" rx="16" fill="white" opacity=".08"/>
        <rect x="20" y="40" width="320" height="16" rx="0" fill="white" opacity=".04"/>
        <circle cx="44" cy="38" r="6" fill="white" opacity=".4"/>
        <circle cx="64" cy="38" r="6" fill="white" opacity=".28"/>
        <circle cx="84" cy="38" r="6" fill="white" opacity=".18"/>
        <text x="44" y="86" font-family="monospace" font-size="13" fill="white" opacity=".45">&lt;div class="app"&gt;</text>
        <text x="62" y="110" font-family="monospace" font-size="13" fill="white" opacity=".65">  const skills = [];</text>
        <text x="62" y="134" font-family="monospace" font-size="12" fill="white" opacity=".4">  skills.push('SmartLearn');</text>
        <text x="62" y="158" font-family="monospace" font-size="12" fill="white" opacity=".35">  return success;</text>
        <text x="44" y="182" font-family="monospace" font-size="13" fill="white" opacity=".45">&lt;/div&gt;</text>
        <rect x="44" y="200" width="70" height="3" rx="1.5" fill="white" opacity=".12"/>
        <rect x="122" y="200" width="120" height="3" rx="1.5" fill="white" opacity=".2"/>
        <rect x="44" y="212" width="160" height="3" rx="1.5" fill="white" opacity=".1"/>
      </svg>`;
  });

  ngOnInit(): void {
    const s = this.slug();
    if (!s) { this.loading.set(false); return; }
    this.#courseSvc.getBySlug(s).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.detail.set(r.data);
          this.#courseSvc.getAvis(r.data.id).subscribe({
            next: av => { if (av.success && av.data) this.avis.set(av.data); },
          });
        }
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  rejoindreListeAttente(coursId: string, sessionId: string): void {
    this.#courseSvc.rejoindreListeAttente(coursId, sessionId).subscribe({
      next: r => { this.#toast.success(r.message ?? "Liste d'attente rejointe"); },
    });
  }

heroBg(): string {
  const colors: Record<string, string> = {
    DEBUTANT: 'bg-gradient-to-br from-emerald-600 via-emerald-700 to-teal-900',
    INTERMEDIAIRE: 'bg-gradient-to-br from-indigo-600 via-indigo-700 to-[#1e1b4b]',
    AVANCE: 'bg-gradient-to-br from-violet-600 via-violet-800 to-purple-950',
  };

  return (
    colors[this.detail()?.niveau ?? ''] ??
    'bg-gradient-to-br from-indigo-700 to-[#1e1b4b]'
  );
}
levelDotColor(): string {
  const colors: Record<string, string> = {
    DEBUTANT: 'bg-emerald-300',
    INTERMEDIAIRE: 'bg-indigo-300',
    AVANCE: 'bg-violet-300',
  };

  return colors[this.detail()?.niveau ?? ''] ?? 'bg-indigo-300';
}
  levelLabel(n: string): string {
    return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n;
  }
  demandBar(d: string): string {
    return { 'Très forte': 'bg-gradient-to-r from-emerald-400 to-emerald-500', 'Forte': 'bg-gradient-to-r from-indigo-400 to-indigo-500', 'Croissante': 'bg-gradient-to-r from-amber-400 to-amber-500' }[d] ?? 'bg-slate-200';
  }
  demandColor(d: string): string {
    return { 'Très forte': 'text-emerald-600', 'Forte': 'text-indigo-600', 'Croissante': 'text-amber-600' }[d] ?? 'text-slate-500';
  }
  modaliteStyle(m: string): string {
    return { MEET: 'bg-blue-50 text-blue-700 border-blue-200', PRESENTIEL: 'bg-emerald-50 text-emerald-700 border-emerald-200', HYBRIDE: 'bg-violet-50 text-violet-700 border-violet-200' }[m] ?? 'bg-slate-50 text-slate-600 border-slate-200';
  }
  modaliteLabel(m: string): string {
    return { MEET: 'En ligne', PRESENTIEL: 'Présentiel', HYBRIDE: 'Hybride' }[m] ?? m;
  }
  starsArray(note: number): number[] {
    return Array.from({ length: 5 }, (_, i) => i < Math.round(note) ? 1 : 0);
  }
  timeAgo(iso: string): string {
    const d = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
    return d === 0 ? "Aujourd'hui" : d === 1 ? 'Hier' : `il y a ${d} jours`;
  }
  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
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