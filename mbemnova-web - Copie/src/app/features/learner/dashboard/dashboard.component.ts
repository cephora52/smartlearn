import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule, DecimalPipe } from '@angular/common';
import { AuthService }         from '../../../core/services/auth.service';
import { ProgressionService }  from '../../../core/services/progression.service';
import { CourseService }       from '../../../core/services/course.service';
import { NotificationService } from '../../../core/services/notification.service';
import { TalentService }       from '../../../core/services/talent.service';
import type { ProgressionResponse, CoursResponse, NotificationResponse, DrawResponse, ProfilTalentResponse } from '../../../core/models';
import { MOCK_PROGRESSION, MOCK_COURS, MOCK_NOTIFICATIONS, MOCK_DRAW, MOCK_PROFIL } from '../../../core/services/mock.data';

@Component({
  selector: 'app-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, CommonModule, DecimalPipe],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
})
export class DashboardComponent implements OnInit {
  readonly #auth        = inject(AuthService);
  readonly #progressSvc = inject(ProgressionService);
  readonly #courseSvc   = inject(CourseService);
  readonly #notifSvc    = inject(NotificationService);
  readonly #talentSvc   = inject(TalentService);

  // ── Signaux de données ──────────────────────────────────────────────────
  readonly profil        = signal<ProfilTalentResponse | null>(null);
  readonly progressions  = signal<ProgressionResponse[]>([]);
  readonly tousLesCours  = signal<CoursResponse[]>([]);
  readonly notifications = signal<NotificationResponse[]>([]);
  readonly draw          = signal<DrawResponse | null>(null);

  // XP des 7 derniers jours (sera alimenté depuis le service si dispo,
  // sinon calculé depuis les progressions comme fallback)
  readonly xpParJour = signal<number[]>([0, 0, 0, 0, 0, 0, 0]);

  // ── Signaux de chargement ───────────────────────────────────────────────
  readonly profilLoading      = signal(true);
  readonly progressionLoading = signal(true);
  readonly notifLoading       = signal(true);

  // ── Computed de base ────────────────────────────────────────────────────
  readonly prenom     = computed(() => this.#auth.currentUser()?.prenom ?? 'Apprenant');
  readonly nbFilleuls = computed(() => (this.profil() as any)?.filleuls?.length ?? (this.profil() as any)?.nbFilleuls ?? 0);

  readonly xpPct = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    const niveaux = [500, 1000, 2000, 5000, 10000];
    const prochain = niveaux.find(n => n > xp) ?? 10000;
    const prev     = niveaux[niveaux.indexOf(prochain) - 1] ?? 0;
    return Math.min(100, ((xp - prev) / (prochain - prev)) * 100);
  });

  readonly ptsManquants = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    const niveaux = [500, 1000, 2000, 5000, 10000];
    const prochain = niveaux.find(n => n > xp) ?? 10000;
    return (prochain - xp).toLocaleString('fr-FR');
  });

  readonly niveauLabel = computed(() => {
    const xp = this.profil()?.xpTotal ?? 0;
    if (xp < 500)   return { num: 1, label: 'Débutant',    color: 'text-slate-400' };
    if (xp < 1000)  return { num: 2, label: 'Explorateur', color: 'text-emerald-400' };
    if (xp < 2000)  return { num: 3, label: 'Initié',      color: 'text-blue-400' };
    if (xp < 5000)  return { num: 4, label: 'Confirmé',    color: 'text-indigo-400' };
    if (xp < 10000) return { num: 5, label: 'Expert',      color: 'text-violet-400' };
    return { num: 6, label: 'Maître', color: 'text-amber-400' };
  });

  readonly suggestions = computed(() => {
    const ids = this.progressions().map(p => p.coursId);
    return this.tousLesCours().filter(c => !ids.includes(c.id)).slice(0, 4);
  });

  readonly mesFormationsAffichees = computed(() => {
    const all = this.progressions();
    const sorted = [...all].sort((a, b) => {
      const t1 = a.dateDebut ? new Date(a.dateDebut).getTime() : 0;
      const t2 = b.dateDebut ? new Date(b.dateDebut).getTime() : 0;
      return t2 - t1;
    });
    return sorted.slice(0, 3);
  });

  readonly hasPaiementEnAttente = computed(() =>
    this.progressions().some(p => p.seuilAtteint && !p.estPaye)
  );

  readonly unreadCount = computed(() =>
    this.notifications().filter(n => !n.estLue).length
  );

  // ── Computed sparkline XP ───────────────────────────────────────────────

  /** Total XP gagné sur les 7 derniers jours */
  readonly weeklyXP = computed(() =>
    this.xpParJour().reduce((a, b) => a + b, 0)
  );

  /** Labels des 7 derniers jours : ['Lun', 'Mar', …, 'Auj.'] */
  readonly dayLabels = computed(() => {
    const jours = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return Array.from({ length: 7 }, (_, i) => {
      if (i === 6) return 'Auj.';
      const d = new Date();
      d.setDate(d.getDate() - (6 - i));
      return jours[d.getDay()];
    });
  });

  /** Points (x, y) normalisés dans le viewBox 400×72 */
  readonly sparkPoints = computed(() => {
    const vals = this.xpParJour();
    const max  = Math.max(...vals, 1);
    const W = 400, H = 64, padY = 6;
    return vals.map((v, i) => ({
      x: Math.round((i / (vals.length - 1)) * W),
      y: Math.round(H - padY - ((v / max) * (H - padY * 2))),
    }));
  });

  /** Chemin SVG de la ligne du sparkline */
  readonly sparkLinePath = computed(() =>
    this.sparkPoints()
      .map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x},${p.y}`)
      .join(' ')
  );

  /** Chemin SVG de l'aire remplie sous la ligne */
  readonly sparkAreaPath = computed(() => {
    const pts  = this.sparkPoints();
    const line = pts.map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x},${p.y}`).join(' ');
    return `${line} L${pts[pts.length - 1].x},72 L0,72 Z`;
  });

  // ── Quick links (avec path SVG et couleur pour le template mobile) ──────
  readonly quickLinks = computed(() => {
    const pList = this.progressions();
    const defaultCoursId = pList.length > 0 ? pList[0].coursId : null;
    const links = [
      {
        route: '/catalogue',
        label: 'Catalogue',
        color: 'text-indigo-400',
        path: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253',
      },
      {
        route: '/app/classement',
        label: 'Classement',
        color: 'text-amber-400',
        path: 'M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z',
      },
      {
        route: '/app/certificats',
        label: 'Certificats',
        color: 'text-emerald-400',
        path: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
      },
      {
        route: '/app/paiements',
        label: 'Paiements',
        color: 'text-blue-400',
        path: 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z',
      },
      {
        route: '/app/parrainage',
        label: 'Parrainage',
        color: 'text-violet-400',
        path: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z',
      },
    ];
    if (defaultCoursId) {
      links.push({
        route: `/app/communaute/${defaultCoursId}`,
        label: 'Communauté',
        color: 'text-rose-400',
        path: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z',
      });
    }
    return links;
  });

  // ── Lifecycle ───────────────────────────────────────────────────────────
  ngOnInit(): void {
    this.#loadProfil();
    this.#loadProgressions();
    this.#loadCours();
    this.#loadNotifications();
    this.#loadDraw();
  }

  // ── Chargement des données ──────────────────────────────────────────────
  #loadProfil(): void {
    this.#talentSvc.getMe().subscribe({
      next: r => {
        if (r.success && r.data) {
          this.profil.set(r.data);
          // Si le back renvoie l'historique XP 7 jours, on le charge ici
          const hist = (r.data as any)?.xpParJour;
          if (Array.isArray(hist) && hist.length === 7) this.xpParJour.set(hist);
        }
        this.profilLoading.set(false);
      },
      error: () => { this.profilLoading.set(false); },
    });
  }

  #loadProgressions(): void {
    this.#progressSvc.getAll().subscribe({
      next: r => {
        if (r.success && r.data) {
          const list = (r.data as any).content || r.data;
          if (Array.isArray(list)) this.progressions.set(list);
        }
        this.progressionLoading.set(false);
      },
      error: () => { this.progressionLoading.set(false); },
    });
  }

  #loadCours(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.tousLesCours.set(r.data.content); },
    });
  }

  #loadNotifications(): void {
    this.#notifSvc.getAll().subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) this.notifications.set(r.data.content);
        this.notifLoading.set(false);
      },
      error: () => { this.notifLoading.set(false); },
    });
  }

  #loadDraw(): void {
    this.#talentSvc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); },
    });
  }

  // ── Helpers visuels ─────────────────────────────────────────────────────
  coursIconBg(i: number): string {
    return ['bg-indigo-500/15', 'bg-emerald-500/15', 'bg-violet-500/15',
            'bg-amber-500/15',  'bg-blue-500/15',    'bg-rose-500/15'][i % 6];
  }

  coursIconColor(i: number): string {
    return ['text-indigo-400', 'text-emerald-400', 'text-violet-400',
            'text-amber-400',  'text-blue-400',    'text-rose-400'][i % 6];
  }

  coursIcon(i: number): string {
    return ['💻', '⚡', '🎨', '📊', '📱', '🚀', '🌱', '🔧', '📚', '🎯'][i % 10];
  }

  notifBg(type: string): string {
    if (type.includes('PAIEMENT'))      return 'bg-amber-500/15 text-amber-400';
    if (type.includes('DEVOIR'))        return 'bg-blue-500/15 text-blue-400';
    if (type === 'CERTIFICAT_GENERE')   return 'bg-emerald-500/15 text-emerald-400';
    return 'bg-slate-700/60 text-slate-400';
  }

  notifEmoji(type: string): string {
    const m: Record<string, string> = {
      PAIEMENT_ECHEANCE:   '💳',
      PAIEMENT_RETARD:     '⚠️',
      PAIEMENT_RECU:       '✅',
      COURS_DEBLOQUE:      '🔓',
      DEVOIR_PUBLIE:       '📝',
      DEVOIR_CORRIGE:      '✏️',
      REPONSE_COMMUNAUTE:  '💬',
      PARRAINAGE_ACTIF:    '🤝',
      TIRAGE_RESULTAT:     '🎯',
      CERTIFICAT_GENERE:   '🏆',
      COMPTE_SUSPENDU:     '🚫',
      SYSTEME:             'ℹ️',
    };
    return m[type] ?? 'ℹ️';
  }

  getCoursTitle(id: string): string {
    return this.tousLesCours().find(c => c.id === id)?.titre ?? 'Formation SmartLearn';
  }

  getCoursSlug(id: string): string {
    return this.tousLesCours().find(c => c.id === id)?.slug ?? id;
  }

  getCoursType(id: string): 'bootcamp' | 'cours' {
    const c = this.tousLesCours().find(c => c.id === id);
    return (c as any)?.type === 'BOOTCAMP' ? 'bootcamp' : 'cours';
  }

  timeAgo(iso: string): string {
    const ms = Date.now() - new Date(iso).getTime();
    const d  = Math.floor(ms / 86_400_000);
    const h  = Math.floor(ms / 3_600_000);
    const m  = Math.floor(ms / 60_000);
    return d >= 1 ? `il y a ${d}j` : h >= 1 ? `il y a ${h}h` : `il y a ${m}min`;
  }
}