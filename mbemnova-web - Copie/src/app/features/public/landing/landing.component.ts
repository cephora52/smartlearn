import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { CourseService } from '../../../core/services/course.service';
import { TalentService } from '../../../core/services/talent.service';
import type { CoursResponse, DrawResponse } from '../../../core/models';
import { MOCK_COURS, MOCK_DRAW, MOCK_LEADERBOARD } from '../../../core/services/mock.data';
import { Hero } from "./components/hero/hero";
import { Foramtions } from "./components/foramtions/foramtions";
import { Blockticket } from "./components/blockticket/blockticket";
import { Profil } from './components/profil/profil';
import { AppelAction } from "./components/appel-action/appel-action";
 

@Component({
  selector: 'app-landing',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Hero, Foramtions, Blockticket, Profil, AppelAction],
  templateUrl: './landing.html',
})
export class LandingComponent implements OnInit {
  readonly #courseSvc = inject(CourseService);
  readonly #talentSvc = inject(TalentService);
  readonly Math = Math;

  readonly cours   = signal<CoursResponse[]>(MOCK_COURS);
  readonly draw    = signal<DrawResponse>(MOCK_DRAW);
  readonly featured = () => this.cours().slice(0, 6);
  readonly topTalents = MOCK_LEADERBOARD.slice(0, 3);

  readonly stats = [
    { value: '247+',  label: 'apprenants actifs en Afrique Centrale' },
    { value: '2 000+',label: 'diplômés depuis 2020' },
    { value: '4.1/5', label: 'note moyenne sur Trustpilot' },
    { value: '87%',   label: 'trouvent un emploi en 6 mois' },
  ];

  readonly domaines = [
    { icon: '💻', label: 'Développement Web',    active: false },
    { icon: '📊', label: 'Data & IA',            active: false },
    { icon: '🎨', label: 'Design Graphique',     active: false },
    { icon: '📱', label: 'Marketing Digital',    active: false },
    { icon: '🔐', label: 'Réseaux & Sécurité',  active: false },
    { icon: '📈', label: 'No-Code & Saas',       active: false },
  ];

  readonly methode = [
    { icon: '👨‍🏫', title: 'Un mentor dédié',          desc: 'Un expert guide votre apprentissage de A à Z. Sessions live, corrections personnalisées.' },
    { icon: '🏢', title: 'Un stage en entreprise',    desc: 'Accédez à notre réseau de partenaires pour un stage de 1 à 3 mois en fin de bootcamp.' },
    { icon: '💳', title: 'Un paiement flexible',      desc: 'Payez en plusieurs fois. Cash, Mobile Money ou virement. Adapté à votre situation.' },
    { icon: '🛠️', title: 'Des projets concrets',      desc: 'Chaque module aboutit à un projet réel que vous ajoutez à votre portfolio.' },
    { icon: '🏆', title: 'Un certificat reconnu',     desc: 'Obtenez un certificat officiel MbemNova vérifiable en ligne par les recruteurs.' },
    { icon: '⚡', title: 'Un format rapide',          desc: '6 à 8 semaines intensives pour être opérationnel. Même avec un emploi à temps partiel.' },
  ];

  readonly partenaires = ['Orange', 'MTN', 'Express Union', 'Digital Africa', 'TechPoint', 'PayDunya', 'Afrikpay'];

  ngOnInit(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.cours.set(r.data.content); },
    });
    this.#talentSvc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); },
    });
  }

  levelGradient(n: string): string {
    return { DEBUTANT: 'bg-gradient-to-br from-emerald-500 to-green-700', INTERMEDIAIRE: 'bg-gradient-to-br from-blue-500 to-indigo-700', AVANCE: 'bg-gradient-to-br from-purple-600 to-violet-700' }[n] ?? 'bg-blue-700';
  }
  levelEmoji(n: string): string    { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  levelLabel(n: string): string    { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
  rankEmoji(i: number): string     { return ['🥇','🥈','🥉'][i] ?? '#'; }
  rankBg(i: number): string        { return ['bg-amber-50 border-amber-200','bg-slate-50 border-slate-200','bg-orange-50 border-orange-200'][i] ?? 'bg-white border-slate-200'; }
}
