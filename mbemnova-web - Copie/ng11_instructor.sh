#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 11/16 · Espace Formateur
# ============================================================
# Contenu :
#   instructor-dashboard.component.ts  (S19 · S20 · S22 · S23)
#     · Vue globale formateur (stats cours, sessions, rendus)
#   course-editor.component.ts         (S19)
#     · Création / édition cours (titre, niveau, prix, seuil)
#   session-manager.component.ts       (S20)
#     · Création sessions + créneaux
#   grading.component.ts               (S22 · S23)
#     · Liste rendus à corriger + formulaire note/commentaire
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
  src/app/features/instructor/dashboard \
  src/app/features/instructor/course-editor \
  src/app/features/instructor/session-manager \
  src/app/features/instructor/grading

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 11 · Espace Formateur        ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. INSTRUCTOR DASHBOARD — S19 S20 S22 S23
# ============================================================
sec "1/4 — instructor-dashboard.component.ts"

cat > src/app/features/instructor/dashboard/instructor-dashboard.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { CourseService }     from '../../../core/services/course.service';
import { SessionService }    from '../../../core/services/session.service';
import { AssignmentService } from '../../../core/services/assignment.service';
import { AuthService }       from '../../../core/services/auth.service';
import type { CoursResponse, SessionResponse, RenduResponse } from '../../../core/models';
import { MOCK_COURS, MOCK_SESSIONS } from '../../../core/services/mock.data';

// Mock rendus en attente pour le formateur
const MOCK_RENDUS_ATTENTE = [
  { id: 'r-001', devoirId: 'd-001', apprenantId: 'u-002', contenu: 'Voici ma page HTML responsive avec flexbox et media queries. Lien GitHub : https://github.com/diane/profil-web', lienFichier: 'https://github.com/diane/profil-web', soumisLe: new Date(Date.now() - 86_400_000).toISOString(), note: null, commentaire: null, corrigeLe: null, prenomApprenant: 'Diane K.', titrDevoir: 'TP1 — Page de profil responsive' },
  { id: 'r-002', devoirId: 'd-001', apprenantId: 'u-003', contenu: 'J\'ai créé ma page avec CSS Grid. Voici le résultat : index.html joint. J\'ai eu du mal avec le responsive mais j\'ai réussi.', lienFichier: null, soumisLe: new Date(Date.now() - 2 * 86_400_000).toISOString(), note: null, commentaire: null, corrigeLe: null, prenomApprenant: 'Patrick N.', titrDevoir: 'TP1 — Page de profil responsive' },
  { id: 'r-003', devoirId: 'd-001', apprenantId: 'u-004', contenu: 'Page disponible sur : https://yvonne-portfolio.netlify.app Design moderne avec animations CSS.', lienFichier: 'https://yvonne-portfolio.netlify.app', soumisLe: new Date(Date.now() - 3 * 86_400_000).toISOString(), note: 18, commentaire: 'Excellent travail ! Design très soigné, responsive parfait.', corrigeLe: new Date(Date.now() - 86_400_000).toISOString(), prenomApprenant: 'Yvonne B.', titrDevoir: 'TP1 — Page de profil responsive' },
];

@Component({
  selector: 'app-instructor-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm text-slate-500 mb-0.5">Espace formateur</p>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
            Bonjour, {{ prenom() }} 👋
          </h1>
        </div>
        <a routerLink="/instructor/cours/nouveau"
           class="btn-primary shrink-0">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Créer un cours
        </a>
      </div>
    </div>
  </div>

  <div class="container py-8 space-y-8">

    <!-- KPIs -->
    <section aria-label="Statistiques formateur">
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        @for (kpi of kpis; track kpi.label; let i = $index) {
          <div class="card p-5 animate-fade-up" [style]="'animation-delay:' + (i * 60) + 'ms'">
            <div class="flex items-center gap-3 mb-1">
              <div [class]="'w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ' + kpi.bg"
                   aria-hidden="true">
                <span class="text-xl">{{ kpi.icon }}</span>
              </div>
              <p class="text-2xl font-black text-slate-900">{{ kpi.value }}</p>
            </div>
            <p class="text-xs text-slate-500">{{ kpi.label }}</p>
          </div>
        }
      </div>
    </section>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Mes cours -->
      <div class="lg:col-span-2 space-y-5">
        <div class="flex items-center justify-between">
          <h2 class="h3">Mes cours</h2>
          <a routerLink="/instructor/cours/nouveau" class="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors">
            + Nouveau cours
          </a>
        </div>

        @if (cours().length === 0) {
          <div class="card p-10 text-center">
            <div class="text-4xl mb-3" aria-hidden="true">📚</div>
            <p class="font-semibold text-slate-900 mb-1">Aucun cours créé</p>
            <p class="text-sm text-slate-500 mb-5">Créez votre premier cours et commencez à former des apprenants.</p>
            <a routerLink="/instructor/cours/nouveau" class="btn-primary">Créer mon premier cours</a>
          </div>
        }

        <div class="space-y-4">
          @for (c of cours(); track c.id; let i = $index) {
            <div class="card p-5 animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">
              <div class="flex items-start gap-4">
                <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0 ' + levelBg(c.niveau)"
                     aria-hidden="true">
                  {{ levelEmoji(c.niveau) }}
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 flex-wrap mb-1">
                    <h3 class="font-semibold text-slate-900 leading-snug">{{ c.titre }}</h3>
                    <span [class]="c.estActif ? 'badge-green' : 'badge-slate'">
                      {{ c.estActif ? 'Publié' : 'Brouillon' }}
                    </span>
                  </div>
                  <div class="flex flex-wrap gap-3 text-xs text-slate-400 mb-3">
                    <span>{{ levelLabel(c.niveau) }}</span>
                    <span>{{ c.prixAffichage }}</span>
                    <span class="flex items-center gap-1">
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                      {{ c.nbApprenants }} apprenants
                    </span>
                    @if (c.noteMoyenne) {
                      <span class="flex items-center gap-1">
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                        {{ c.noteMoyenne }}
                      </span>
                    }
                  </div>
                  <div class="flex gap-2">
                    <a [routerLink]="['/instructor/cours', c.id, 'editer']"
                       class="btn-secondary btn-sm">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                      Modifier
                    </a>
                    <a routerLink="/instructor/sessions" class="btn-ghost btn-sm text-slate-500">Sessions</a>
                    <a [routerLink]="['/app/communaute', c.id]" class="btn-ghost btn-sm text-slate-500">
                      Communauté
                    </a>
                  </div>
                </div>
              </div>
            </div>
          }
        </div>

        <!-- Sessions -->
        <div class="flex items-center justify-between mt-6">
          <h2 class="h3">Sessions actives</h2>
          <a routerLink="/instructor/sessions" class="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors">
            Gérer les sessions
          </a>
        </div>
        <div class="space-y-3">
          @for (s of sessions(); track s.id; let i = $index) {
            <div class="card p-4 flex items-center gap-4 animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">
              <div [class]="'w-10 h-10 rounded-xl flex items-center justify-center shrink-0 '
                            + modaliteBg(s.modalite)" aria-hidden="true">
                {{ modaliteEmoji(s.modalite) }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-900 truncate">{{ s.titre }}</p>
                <p class="text-xs text-slate-400">{{ s.nbInscrits }}/{{ s.capaciteMax }} inscrits · {{ formatDate(s.dateDebut) }}</p>
              </div>
              <span [class]="'badge shrink-0 ' + (s.placesRestantes === 0 ? 'badge-red' : 'badge-green')">
                {{ s.placesRestantes === 0 ? 'Complet' : s.placesRestantes + ' places' }}
              </span>
            </div>
          }
        </div>
      </div>

      <!-- Colonne droite — Rendus à corriger -->
      <div class="space-y-5">
        <div class="flex items-center justify-between">
          <h2 class="h3">À corriger</h2>
          <a routerLink="/instructor/correction" class="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors">
            Tout voir
          </a>
        </div>

        @for (r of rendusAttente; track r.id; let i = $index) {
          <div class="card p-4 animate-fade-up" [style]="'animation-delay:' + (i * 60) + 'ms'">
            <div class="flex items-center gap-2 mb-2">
              <div class="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-xs font-bold shrink-0">
                {{ r.prenomApprenant.charAt(0) }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-900 truncate">{{ r.prenomApprenant }}</p>
                <p class="text-xs text-slate-400 truncate">{{ r.titrDevoir }}</p>
              </div>
              @if (r.note !== null) {
                <span class="badge-green shrink-0">{{ r.note }}/20</span>
              } @else {
                <span class="badge-amber shrink-0">À corriger</span>
              }
            </div>
            <p class="text-xs text-slate-500 line-clamp-2 mb-3 leading-relaxed">{{ r.contenu }}</p>
            @if (r.note === null) {
              <a routerLink="/instructor/correction" class="btn-primary btn-sm w-full justify-center">
                Corriger
              </a>
            }
          </div>
        }

        @if (rendusAttente.length === 0) {
          <div class="card p-8 text-center">
            <div class="text-3xl mb-2" aria-hidden="true">✅</div>
            <p class="text-sm font-semibold text-slate-900">Tout est corrigé !</p>
            <p class="text-xs text-slate-500 mt-1">Aucun rendu en attente.</p>
          </div>
        }
      </div>
    </div>
  </div>
</div>
  `,
})
export class InstructorDashboardComponent implements OnInit {
  readonly #auth       = inject(AuthService);
  readonly #courseSvc  = inject(CourseService);
  readonly #sessionSvc = inject(SessionService);

  readonly cours    = signal<CoursResponse[]>(MOCK_COURS.slice(0, 3));
  readonly sessions = signal<SessionResponse[]>(MOCK_SESSIONS);

  readonly prenom = computed(() => this.#auth.currentUser()?.prenom ?? 'Formateur');

  readonly rendusAttente = MOCK_RENDUS_ATTENTE.filter(r => r.note === null);

  readonly kpis = [
    { icon: '📚', label: 'Cours publiés',       value: 3,    bg: 'bg-blue-100' },
    { icon: '👥', label: 'Apprenants formés',   value: 142,  bg: 'bg-green-100' },
    { icon: '📝', label: 'Devoirs à corriger',  value: 2,    bg: 'bg-amber-100' },
    { icon: '⭐', label: 'Note moyenne',         value: '4.7',bg: 'bg-purple-100' },
  ];

  ngOnInit(): void {
    this.#courseSvc.getAll({ size: 6 }).subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.cours.set(r.data.content); },
    });
    this.#sessionSvc.getByCours('c-001').subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.sessions.set(r.data.content); },
    });
  }

  levelBg(n: string): string { return { DEBUTANT: 'bg-green-100', INTERMEDIAIRE: 'bg-blue-100', AVANCE: 'bg-purple-100' }[n] ?? 'bg-slate-100'; }
  levelEmoji(n: string): string { return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚'; }
  levelLabel(n: string): string { return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n; }
  modaliteBg(m: string): string { return { MEET: 'bg-blue-100', PRESENTIEL: 'bg-green-100', HYBRIDE: 'bg-purple-100' }[m] ?? 'bg-slate-100'; }
  modaliteEmoji(m: string): string { return { MEET: '💻', PRESENTIEL: '📍', HYBRIDE: '🔀' }[m] ?? '📅'; }
  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
  }
}
EOF
ok "instructor-dashboard.component.ts"

# ============================================================
# 2. COURSE EDITOR — S19
# ============================================================
sec "2/4 — course-editor.component.ts (S19)"

cat > src/app/features/instructor/course-editor/course-editor.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, input, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink, Router } from '@angular/router';
import { AdminService }  from '../../../core/services/admin.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { NiveauCours } from '../../../core/models';

@Component({
  selector: 'app-course-editor',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/instructor" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
          {{ isEdit() ? 'Modifier le cours' : 'Créer un nouveau cours' }}
        </h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl">
    <div class="card p-8 animate-fade-up">

      <form [formGroup]="form" (ngSubmit)="save()" novalidate class="space-y-6">

        <!-- Titre -->
        <div>
          <label for="titre" class="label">Titre du cours <span class="text-red-500">*</span></label>
          <input id="titre" type="text" formControlName="titre"
                 placeholder="Ex : Développement Web avec React & Node.js"
                 [class]="'input ' + (sub && form.get('titre')?.invalid ? 'input-error' : '')">
          @if (sub && form.get('titre')?.hasError('required')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Titre requis
            </p>
          }
          @if (sub && form.get('titre')?.hasError('minlength')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              10 caractères minimum
            </p>
          }
        </div>

        <!-- Description -->
        <div>
          <label for="desc" class="label">Description <span class="text-red-500">*</span></label>
          <textarea id="desc" formControlName="description" rows="4"
                    placeholder="Décrivez ce que l'apprenant apprendra, le public cible, les prérequis…"
                    [class]="'input resize-none ' + (sub && form.get('description')?.invalid ? 'input-error' : '')">
          </textarea>
          @if (sub && form.get('description')?.hasError('minlength')) {
            <p class="field-error" role="alert">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              50 caractères minimum
            </p>
          }
        </div>

        <!-- Niveau + Prix -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label for="niveau" class="label">Niveau <span class="text-red-500">*</span></label>
            <select id="niveau" formControlName="niveau"
                    [class]="'input ' + (sub && form.get('niveau')?.invalid ? 'input-error' : '')">
              <option value="">Sélectionnez un niveau</option>
              @for (n of niveaux; track n.value) {
                <option [value]="n.value">{{ n.label }}</option>
              }
            </select>
          </div>
          <div>
            <label for="prix" class="label">Prix (FCFA) <span class="text-red-500">*</span></label>
            <input id="prix" type="number" formControlName="prixFcfa"
                   placeholder="25000" min="0" step="1000"
                   [class]="'input ' + (sub && form.get('prixFcfa')?.invalid ? 'input-error' : '')">
          </div>
        </div>

        <!-- Seuil accès gratuit -->
        <div>
          <label class="label">
            Seuil d'accès gratuit
            <span class="text-slate-400 font-normal">
              — {{ seuilPct() }}% du contenu accessible gratuitement
            </span>
          </label>
          <input type="range" formControlName="seuilPaiement"
                 min="0.10" max="0.60" step="0.05"
                 class="w-full accent-blue-600">
          <div class="flex justify-between text-xs text-slate-400 mt-1">
            <span>10% (minimum)</span>
            <span class="font-semibold text-blue-600">{{ seuilPct() }}%</span>
            <span>60% (maximum)</span>
          </div>
          <div class="progress mt-2">
            <div class="progress-bar bg-green-500" [style.width.%]="seuilPct()"></div>
          </div>
          <p class="text-xs text-slate-500 mt-1.5">
            💡 Les plateformes avec 25–35% de contenu gratuit ont les meilleurs taux de conversion.
          </p>
        </div>

        <!-- Info publication -->
        <div class="bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-3">
          <svg class="shrink-0 mt-0.5" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <p class="text-sm text-blue-800 leading-relaxed">
            Le cours sera créé en <strong>brouillon</strong>. Un administrateur le publiera après révision.
            Vous pourrez ajouter les modules et leçons une fois créé.
          </p>
        </div>

        <!-- Boutons -->
        <div class="flex gap-3 pt-2">
          <a routerLink="/instructor" class="btn-secondary flex-1 justify-center">Annuler</a>
          <button type="submit" [disabled]="saving()" class="btn-primary flex-1">
            @if (saving()) {
              <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
              Enregistrement…
            } @else {
              {{ isEdit() ? 'Mettre à jour' : 'Créer le cours' }}
            }
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
  `,
})
export class CourseEditorComponent implements OnInit {
  readonly id = input<string>('');

  readonly #adminSvc = inject(AdminService);
  readonly #toast    = inject(ToastService);
  readonly #router   = inject(Router);
  readonly #fb       = inject(FormBuilder);

  readonly saving = signal(false);
  readonly isEdit = () => !!this.id();
  sub = false;

  readonly form = this.#fb.nonNullable.group({
    titre:         ['', [Validators.required, Validators.minLength(10)]],
    description:   ['', [Validators.required, Validators.minLength(50)]],
    niveau:        ['', Validators.required],
    prixFcfa:      [25000, [Validators.required, Validators.min(0)]],
    seuilPaiement: [0.30],
  });

  readonly niveaux = [
    { value: 'DEBUTANT',      label: '🌱 Débutant' },
    { value: 'INTERMEDIAIRE', label: '⚡ Intermédiaire' },
    { value: 'AVANCE',        label: '🚀 Avancé' },
  ];

  seuilPct(): number {
    return Math.round((this.form.get('seuilPaiement')?.value ?? 0.30) * 100);
  }

  ngOnInit(): void {
    // Si édition : charger les données existantes
    // En mock : pré-remplir avec des données exemple
    if (this.isEdit()) {
      this.form.patchValue({
        titre: 'Développement Web : HTML, CSS & JavaScript',
        description: 'Maîtrisez les fondamentaux du web. Créez vos premiers sites interactifs avec des projets pratiques adaptés au contexte camerounais.',
        niveau: 'DEBUTANT',
        prixFcfa: 25000,
        seuilPaiement: 0.30,
      });
    }
  }

  save(): void {
    this.sub = true;
    if (this.form.invalid) return;
    this.saving.set(true);

    const { titre, description, niveau, prixFcfa, seuilPaiement } = this.form.getRawValue();

    this.#adminSvc.creerCours({
      titre, description,
      niveau: niveau as NiveauCours,
      prixFcfa, seuilPaiement,
    }).subscribe({
      next: r => {
        this.saving.set(false);
        this.#toast.success(
          this.isEdit() ? 'Cours mis à jour !' : 'Cours créé en brouillon !',
          'Un administrateur le publiera après révision.'
        );
        this.#router.navigate(['/instructor']);
      },
      error: () => { this.saving.set(false); },
    });
  }
}
EOF
ok "course-editor.component.ts"

# ============================================================
# 3. SESSION MANAGER — S20
# ============================================================
sec "3/4 — session-manager.component.ts (S20)"

cat > src/app/features/instructor/session-manager/session-manager.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { SessionService } from '../../../core/services/session.service';
import { ToastService }   from '../../../core/services/toast.service';
import type { SessionResponse, Modalite } from '../../../core/models';
import { MOCK_SESSIONS, MOCK_COURS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-session-manager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <a routerLink="/instructor" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
          </a>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Gestion des sessions</h1>
        </div>
        <button (click)="showCreate.set(true)" class="btn-primary shrink-0">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Nouvelle session
        </button>
      </div>
    </div>
  </div>

  <div class="container py-6 space-y-4">

    @if (loading()) {
      @for (_ of [1,2]; track $_) {
        <div class="card p-5">
          <div class="shimmer h-16 rounded-xl mb-3"></div>
          <div class="shimmer h-8 rounded-lg w-1/3"></div>
        </div>
      }
    }

    @if (!loading() && sessions().length === 0) {
      <div class="card p-12 text-center">
        <div class="text-4xl mb-3" aria-hidden="true">📅</div>
        <p class="font-semibold text-slate-900 mb-1">Aucune session créée</p>
        <p class="text-sm text-slate-500 mb-5">Planifiez votre première session avec des apprenants.</p>
        <button (click)="showCreate.set(true)" class="btn-primary">Créer une session</button>
      </div>
    }

    @for (s of sessions(); track s.id; let i = $index) {
      <div class="card p-5 animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">
        <div class="flex items-start gap-4">
          <div [class]="'w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0 '
                        + modaliteBg(s.modalite)" aria-hidden="true">
            {{ modaliteEmoji(s.modalite) }}
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap mb-1">
              <h2 class="font-bold text-slate-900">{{ s.titre }}</h2>
              <span [class]="modaliteBadge(s.modalite)">{{ s.modalite }}</span>
              @if (!s.estActive) { <span class="badge-slate">Inactive</span> }
            </div>
            <div class="flex flex-wrap gap-3 text-xs text-slate-400 mb-3">
              <span>Du {{ formatDate(s.dateDebut) }} au {{ formatDate(s.dateFin) }}</span>
              <span>{{ s.nbInscrits }}/{{ s.capaciteMax }} inscrits</span>
              @if (s.lieu) { <span>📍 {{ s.lieu }}</span> }
              @if (s.lienReunion) {
                <a [href]="s.lienReunion" target="_blank" rel="noopener"
                   class="text-blue-600 hover:text-blue-700 transition-colors">
                  Lien Meet
                </a>
              }
            </div>
            <!-- Barre places -->
            <div class="flex items-center gap-2 mb-3">
              <div class="flex-1 progress h-1.5">
                <div class="progress-bar"
                     [class]="s.placesRestantes === 0 ? 'bg-red-400' : 'bg-blue-500'"
                     [style.width.%]="(s.nbInscrits / s.capaciteMax) * 100"></div>
              </div>
              <span class="text-xs font-medium"
                    [class]="s.placesRestantes === 0 ? 'text-red-600' : 'text-slate-500'">
                {{ s.placesRestantes === 0 ? 'Complet' : s.placesRestantes + ' places libres' }}
              </span>
            </div>
            <div class="flex gap-2">
              <a routerLink="/instructor/correction" class="btn-secondary btn-sm">
                Voir les rendus
              </a>
            </div>
          </div>
        </div>
      </div>
    }
  </div>

  <!-- Modal création session -->
  @if (showCreate()) {
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
         role="dialog" aria-modal="true" aria-labelledby="session-title">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" (click)="showCreate.set(false)"></div>

      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg animate-scale-in overflow-hidden">
        <div class="p-6 border-b border-slate-100">
          <div class="flex items-center justify-between">
            <h2 id="session-title" class="font-bold text-slate-900">Nouvelle session</h2>
            <button (click)="showCreate.set(false)" class="btn-icon text-slate-400 hover:text-slate-600" aria-label="Fermer">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
        </div>

        <div class="p-6">
          <form [formGroup]="sessionForm" (ngSubmit)="createSession()" novalidate class="space-y-4">

            <!-- Cours associé -->
            <div>
              <label for="coursId" class="label">Cours associé <span class="text-red-500">*</span></label>
              <select id="coursId" formControlName="coursId" class="input">
                <option value="">Sélectionnez un cours</option>
                @for (c of cours; track c.id) {
                  <option [value]="c.id">{{ c.titre }}</option>
                }
              </select>
            </div>

            <!-- Titre -->
            <div>
              <label for="sTitre" class="label">Titre de la session <span class="text-red-500">*</span></label>
              <input id="sTitre" type="text" formControlName="titre"
                     placeholder="Ex : Dev Web — Session Juillet 2025"
                     class="input">
            </div>

            <!-- Modalité -->
            <div>
              <label class="label">Modalité <span class="text-red-500">*</span></label>
              <div class="grid grid-cols-3 gap-2">
                @for (m of modalites; track m.value) {
                  <button type="button" (click)="sessionForm.patchValue({ modalite: m.value })"
                          [class]="'flex flex-col items-center gap-1 p-3 rounded-xl border-2 transition-all text-sm '
                                   + (sessionForm.get('modalite')?.value === m.value
                                   ? 'border-blue-500 bg-blue-50 text-blue-700 font-semibold'
                                   : 'border-slate-200 hover:border-blue-300')">
                    <span class="text-xl" aria-hidden="true">{{ m.icon }}</span>
                    {{ m.label }}
                  </button>
                }
              </div>
            </div>

            <!-- Dates -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label for="dateDebut" class="label">Date de début <span class="text-red-500">*</span></label>
                <input id="dateDebut" type="date" formControlName="dateDebut" class="input">
              </div>
              <div>
                <label for="dateFin" class="label">Date de fin <span class="text-red-500">*</span></label>
                <input id="dateFin" type="date" formControlName="dateFin" class="input">
              </div>
            </div>

            <!-- Capacité -->
            <div>
              <label for="capacite" class="label">Capacité maximum</label>
              <input id="capacite" type="number" formControlName="capaciteMax"
                     min="1" max="100" class="input">
            </div>

            <!-- Lieu ou lien Meet -->
            @if (sessionForm.get('modalite')?.value === 'PRESENTIEL' || sessionForm.get('modalite')?.value === 'HYBRIDE') {
              <div>
                <label for="lieu" class="label">Lieu</label>
                <input id="lieu" type="text" formControlName="lieu"
                       placeholder="Centre MbemNova, Akwa — Douala" class="input">
              </div>
            }
            @if (sessionForm.get('modalite')?.value === 'MEET' || sessionForm.get('modalite')?.value === 'HYBRIDE') {
              <div>
                <label for="lienMeet" class="label">Lien Google Meet</label>
                <input id="lienMeet" type="url" formControlName="lienReunion"
                       placeholder="https://meet.google.com/..." class="input">
              </div>
            }

            <div class="flex gap-3 pt-2">
              <button type="button" (click)="showCreate.set(false)" class="btn-secondary flex-1">Annuler</button>
              <button type="submit" [disabled]="creating()" class="btn-primary flex-1">
                @if (creating()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                }
                Créer la session
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
export class SessionManagerComponent implements OnInit {
  readonly #sessionSvc = inject(SessionService);
  readonly #toast      = inject(ToastService);
  readonly #fb         = inject(FormBuilder);

  readonly sessions   = signal<SessionResponse[]>(MOCK_SESSIONS);
  readonly loading    = signal(true);
  readonly showCreate = signal(false);
  readonly creating   = signal(false);

  readonly cours = MOCK_COURS.slice(0, 4);

  readonly modalites = [
    { value: 'MEET',       label: 'En ligne', icon: '💻' },
    { value: 'PRESENTIEL', label: 'Présentiel', icon: '📍' },
    { value: 'HYBRIDE',    label: 'Hybride', icon: '🔀' },
  ];

  readonly sessionForm = this.#fb.nonNullable.group({
    coursId:      ['', Validators.required],
    titre:        ['', Validators.required],
    modalite:     ['MEET', Validators.required],
    dateDebut:    ['', Validators.required],
    dateFin:      ['', Validators.required],
    capaciteMax:  [20],
    lieu:         [''],
    lienReunion:  [''],
  });

  ngOnInit(): void {
    this.#sessionSvc.getByCours('c-001').subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.sessions.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  createSession(): void {
    if (this.sessionForm.invalid) return;
    this.creating.set(true);
    // Simulation création (inscrire un apprenant fictif)
    setTimeout(() => {
      this.creating.set(false);
      this.showCreate.set(false);
      this.#toast.success('Session créée !', 'Les apprenants peuvent maintenant s\'inscrire.');
      this.sessionForm.reset({ modalite: 'MEET', capaciteMax: 20 });
    }, 800);
  }

  modaliteBg(m: string): string { return { MEET: 'bg-blue-100', PRESENTIEL: 'bg-green-100', HYBRIDE: 'bg-purple-100' }[m] ?? 'bg-slate-100'; }
  modaliteEmoji(m: string): string { return { MEET: '💻', PRESENTIEL: '📍', HYBRIDE: '🔀' }[m] ?? '📅'; }
  modaliteBadge(m: string): string { return { MEET: 'badge-blue', PRESENTIEL: 'badge-green', HYBRIDE: 'badge-purple' }[m] ?? 'badge-slate'; }
  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
  }
}
EOF
ok "session-manager.component.ts"

# ============================================================
# 4. GRADING — S22 · S23
# ============================================================
sec "4/4 — grading.component.ts (S22 S23)"

cat > src/app/features/instructor/grading/grading.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed,
} from '@angular/core';
import {
  ReactiveFormsModule, FormBuilder, Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AssignmentService } from '../../../core/services/assignment.service';
import { ToastService }      from '../../../core/services/toast.service';

interface RenduVue {
  id: string; devoirId: string; apprenantId: string;
  prenomApprenant: string; titrDevoir: string;
  contenu: string; lienFichier: string | null;
  soumisLe: string; note: number | null; commentaire: string | null; corrigeLe: string | null;
}

const MOCK_RENDUS: RenduVue[] = [
  { id: 'r-001', devoirId: 'd-001', apprenantId: 'u-002', prenomApprenant: 'Diane K.', titrDevoir: 'TP1 — Page de profil responsive', contenu: 'Voici ma page HTML responsive avec flexbox et media queries. Lien GitHub : https://github.com/diane/profil-web - J\'ai utilisé CSS Grid pour la mise en page principale et Flexbox pour les composants. Le site est responsive à partir de 320px.', lienFichier: 'https://github.com/diane/profil-web', soumisLe: new Date(Date.now() - 86_400_000).toISOString(), note: null, commentaire: null, corrigeLe: null },
  { id: 'r-002', devoirId: 'd-001', apprenantId: 'u-003', prenomApprenant: 'Patrick N.', titrDevoir: 'TP1 — Page de profil responsive', contenu: 'J\'ai créé ma page avec CSS Grid. Voici le résultat : j\'ai eu du mal avec le responsive mais j\'ai réussi. La page s\'adapte sur mobile. J\'aurais aimé ajouter des animations mais je manque encore de pratique.', lienFichier: null, soumisLe: new Date(Date.now() - 2 * 86_400_000).toISOString(), note: null, commentaire: null, corrigeLe: null },
  { id: 'r-003', devoirId: 'd-001', apprenantId: 'u-004', prenomApprenant: 'Yvonne B.', titrDevoir: 'TP1 — Page de profil responsive', contenu: 'Page disponible sur : https://yvonne-portfolio.netlify.app Design moderne avec animations CSS et dark mode. Code propre et commenté.', lienFichier: 'https://yvonne-portfolio.netlify.app', soumisLe: new Date(Date.now() - 3 * 86_400_000).toISOString(), note: 18, commentaire: 'Excellent travail Yvonne ! Design soigné, responsive parfait et le dark mode est un plus. Continuez ainsi !', corrigeLe: new Date(Date.now() - 86_400_000).toISOString() },
];

@Component({
  selector: 'app-grading',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/instructor" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Correction des devoirs</h1>
        <span class="badge-amber">{{ enAttente() }} à corriger</span>
      </div>
    </div>
  </div>

  <div class="container py-6 max-w-3xl space-y-5">

    <!-- Filtre -->
    <div class="flex gap-2">
      @for (f of filtres; track f.value) {
        <button (click)="filtre.set(f.value)"
                [class]="'btn-sm rounded-lg px-4 py-2 text-sm font-medium transition-colors '
                         + (filtre() === f.value ? 'bg-blue-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50')">
          {{ f.label }}
          @if (f.value === 'attente') { <span class="ml-1 bg-amber-500 text-white text-xs rounded-full px-1.5">{{ enAttente() }}</span> }
        </button>
      }
    </div>

    @for (r of rendusAffiches(); track r.id; let i = $index) {
      <div class="card overflow-hidden animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">

        <!-- En-tête rendu -->
        <div class="p-5 border-b border-slate-100">
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold shrink-0">
              {{ r.prenomApprenant.charAt(0) }}
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap mb-0.5">
                <p class="font-semibold text-slate-900">{{ r.prenomApprenant }}</p>
                @if (r.note !== null) {
                  <span [class]="noteBadge(r.note)">{{ r.note }}/20 — {{ noteLabel(r.note) }}</span>
                } @else {
                  <span class="badge-amber">En attente de correction</span>
                }
              </div>
              <p class="text-xs text-slate-400">
                {{ r.titrDevoir }} · Soumis {{ timeAgo(r.soumisLe) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Contenu rendu -->
        <div class="p-5">
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Rendu de l'apprenant</p>
          <div class="bg-slate-50 rounded-xl p-4 mb-4">
            <p class="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">{{ r.contenu }}</p>
            @if (r.lienFichier) {
              <a [href]="r.lienFichier" target="_blank" rel="noopener"
                 class="inline-flex items-center gap-1.5 mt-3 text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                Voir le fichier / projet
              </a>
            }
          </div>

          <!-- Correction existante -->
          @if (r.note !== null) {
            <div class="bg-green-50 border border-green-200 rounded-xl p-4">
              <div class="flex items-center justify-between mb-2">
                <p class="text-sm font-bold text-green-900">Votre correction</p>
                <span [class]="noteBadge(r.note)">{{ r.note }}/20</span>
              </div>
              <div class="progress mb-2">
                <div class="progress-bar"
                     [class]="r.note >= 14 ? 'bg-green-500' : r.note >= 10 ? 'bg-amber-400' : 'bg-red-400'"
                     [style.width.%]="(r.note / 20) * 100"></div>
              </div>
              @if (r.commentaire) {
                <p class="text-sm text-green-800 italic">"{{ r.commentaire }}"</p>
              }
            </div>
          }

          <!-- Formulaire correction -->
          @if (r.note === null) {
            <div class="border border-slate-200 rounded-xl p-4">
              <p class="text-sm font-semibold text-slate-900 mb-4">Corriger ce rendu</p>

              @if (activeGrade() === r.id) {
                <form [formGroup]="gradeForm" (ngSubmit)="submitGrade(r)" novalidate class="space-y-4">

                  <!-- Note -->
                  <div>
                    <label class="label">
                      Note /20
                      <span class="ml-2 text-lg font-black"
                            [class]="noteColor(gradeForm.get('note')?.value ?? 0)">
                        {{ gradeForm.get('note')?.value ?? 0 }}/20
                      </span>
                    </label>
                    <input type="range" formControlName="note"
                           min="0" max="20" step="0.5"
                           class="w-full accent-blue-600">
                    <div class="flex justify-between text-xs text-slate-400 mt-1">
                      <span>0</span>
                      <span [class]="noteColor(gradeForm.get('note')?.value ?? 0)">
                        {{ noteLabel(gradeForm.get('note')?.value ?? 0) }}
                      </span>
                      <span>20</span>
                    </div>
                  </div>

                  <!-- Commentaire -->
                  <div>
                    <label for="commentaire-{{r.id}}" class="label">Commentaire pour l'apprenant</label>
                    <textarea [id]="'commentaire-' + r.id" formControlName="commentaire"
                              rows="3"
                              placeholder="Points forts, axes d'amélioration, encouragements…"
                              [class]="'input resize-none ' + (gradeSubmitted && gradeForm.get('commentaire')?.invalid ? 'input-error' : '')">
                    </textarea>
                    @if (gradeSubmitted && gradeForm.get('commentaire')?.hasError('required')) {
                      <p class="field-error" role="alert">Commentaire requis — aidez l'apprenant à progresser.</p>
                    }
                  </div>

                  <div class="flex gap-3">
                    <button type="button" (click)="activeGrade.set(null)" class="btn-secondary flex-1">Annuler</button>
                    <button type="submit" [disabled]="grading()" class="btn-primary flex-1">
                      @if (grading()) {
                        <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                      }
                      Valider la correction
                    </button>
                  </div>
                </form>
              } @else {
                <button (click)="startGrade(r.id)"
                        class="btn-primary w-full justify-center">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                  Commencer la correction
                </button>
              }
            </div>
          }
        </div>
      </div>
    }
  </div>
</div>
  `,
})
export class GradingComponent {
  readonly #assignSvc = inject(AssignmentService);
  readonly #toast     = inject(ToastService);
  readonly #fb        = inject(FormBuilder);

  readonly rendus     = signal<RenduVue[]>(MOCK_RENDUS);
  readonly filtre     = signal<'tous' | 'attente' | 'corriges'>('attente');
  readonly activeGrade= signal<string | null>(null);
  readonly grading    = signal(false);
  gradeSubmitted      = false;

  readonly enAttente    = computed(() => this.rendus().filter(r => r.note === null).length);
  readonly rendusAffiches = computed(() => {
    const f = this.filtre();
    if (f === 'attente')  return this.rendus().filter(r => r.note === null);
    if (f === 'corriges') return this.rendus().filter(r => r.note !== null);
    return this.rendus();
  });

  readonly filtres = [
    { value: 'attente',  label: 'À corriger' },
    { value: 'corriges', label: 'Corrigés' },
    { value: 'tous',     label: 'Tous' },
  ] as const;

  readonly gradeForm = this.#fb.nonNullable.group({
    note:        [12],
    commentaire: ['', Validators.required],
  });

  startGrade(id: string): void {
    this.activeGrade.set(id);
    this.gradeForm.reset({ note: 12, commentaire: '' });
    this.gradeSubmitted = false;
  }

  submitGrade(r: RenduVue): void {
    this.gradeSubmitted = true;
    if (this.gradeForm.invalid) return;
    this.grading.set(true);

    const { note, commentaire } = this.gradeForm.getRawValue();

    this.#assignSvc.corriger(r.id, {
      renduId: r.id, note, commentaire,
    }).subscribe({
      next: () => {
        this.grading.set(false);
        this.activeGrade.set(null);
        this.rendus.update(list => list.map(rv =>
          rv.id === r.id ? { ...rv, note, commentaire, corrigeLe: new Date().toISOString() } : rv
        ));
        this.#toast.success(
          `Correction enregistrée — ${note}/20`,
          `${r.prenomApprenant} sera notifié(e) par notification.`
        );
      },
      error: () => { this.grading.set(false); },
    });
  }

  noteBadge(note: number): string {
    if (note >= 16) return 'badge-green'; if (note >= 12) return 'badge-blue';
    if (note >= 10) return 'badge-amber'; return 'badge-red';
  }
  noteLabel(note: number): string {
    if (note >= 16) return 'Excellent'; if (note >= 14) return 'Très bien';
    if (note >= 12) return 'Bien'; if (note >= 10) return 'Passable'; return 'Insuffisant';
  }
  noteColor(note: number): string {
    if (note >= 14) return 'text-green-600'; if (note >= 10) return 'text-amber-600'; return 'text-red-600';
  }
  timeAgo(iso: string): string {
    const d = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
    const h = Math.floor((Date.now() - new Date(iso).getTime()) / 3_600_000);
    if (d >= 1) return `il y a ${d}j`; if (h >= 1) return `il y a ${h}h`; return "récemment";
  }
}
EOF
ok "grading.component.ts"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 11 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  instructor-dashboard.component.ts"
echo -e "       · KPIs formateur (cours, apprenants, devoirs, note)"
echo -e "       · Liste cours avec statuts · Sessions actives · Rendus à corriger"
echo ""
echo -e "  ${G}✓${N}  course-editor.component.ts (S19)"
echo -e "       · Formulaire création/édition cours"
echo -e "       · Slider seuil accès gratuit avec preview visuel"
echo -e "       · Validation reactive forms + info publication"
echo ""
echo -e "  ${G}✓${N}  session-manager.component.ts (S20)"
echo -e "       · Liste sessions avec barre places"
echo -e "       · Modal création session : cours, modalité, dates, capacité"
echo -e "       · Champs conditionnels (lieu / lien Meet selon modalité)"
echo ""
echo -e "  ${G}✓${N}  grading.component.ts (S22 S23)"
echo -e "       · Filtre : à corriger / corrigés / tous"
echo -e "       · Contenu rendu apprenant + lien fichier"
echo -e "       · Slider note /20 + label appréciation coloré"
echo -e "       · Barre visuelle note · Commentaire requis"
echo -e "       · Notification apprenant après correction"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng12_admin_dashboard.sh${N}"
echo ""
