import { ChangeDetectionStrategy, Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CourseService } from '../../../core/services/course.service';
import { AdminService } from '../../../core/services/admin.service';
import { ToastService } from '../../../core/services/toast.service';
import type { CoursResponse } from '../../../core/models';

@Component({
  selector: 'app-course-mgr',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true,
  imports: [CommonModule],
  template: `
<div class="min-h-screen bg-slate-50/50 py-10">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

    <!-- ── HEADER ── -->
    <div class="mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">Gestion des Formations</h1>
        <p class="text-sm text-slate-500 mt-1">Supervisez l'intégralité du catalogue des formations disponibles, vérifiez leurs statistiques d'inscriptions et publiez les cours en attente.</p>
      </div>
    </div>

    <!-- ── TABLE CARD ── -->
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">
      
      <!-- Filters and Search -->
      <div class="px-6 py-5 border-b border-slate-100 flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4 bg-slate-50/30">
        <div class="relative flex-1 max-w-md">
          <input type="text"
                 (input)="searchQuery.set(searchInput.value)"
                 #searchInput
                 placeholder="Rechercher par titre ou domaine..."
                 class="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl text-sm focus:outline-none focus:border-blue-500 transition-colors" />
          <svg class="absolute left-3.5 top-3 text-slate-400" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-xs text-slate-400 font-bold uppercase tracking-wider">
            Total : {{ filteredCourses().length }} formations
          </span>
        </div>
      </div>

      <!-- Loading State -->
      @if (loading()) {
        <div class="p-12 text-center">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent mb-3"></div>
          <p class="text-sm text-slate-500">Chargement des formations...</p>
        </div>
      } @else {
        <!-- Empty State -->
        @if (filteredCourses().length === 0) {
          <div class="p-16 text-center">
            <p class="text-4xl mb-3">📚</p>
            <h3 class="text-lg font-bold text-slate-900 mb-1">Aucune formation trouvée</h3>
            <p class="text-sm text-slate-500">Aucun cours ne correspond à vos critères de recherche.</p>
          </div>
        } @else {
          <!-- Table -->
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold uppercase text-slate-400 tracking-wider">
                  <th class="px-6 py-4">Formation</th>
                  <th class="px-6 py-4">Domaine / Niveau</th>
                  <th class="px-6 py-4">Tarif</th>
                  <th class="px-6 py-4">Apprenants Inscrits</th>
                  <th class="px-6 py-4">Note Moyenne</th>
                  <th class="px-6 py-4">Statut</th>
                  <th class="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 text-sm">
                @for (c of filteredCourses(); track c.id) {
                  <tr class="hover:bg-slate-50/50 transition-colors">
                    <!-- Title -->
                    <td class="px-6 py-4">
                      <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-lg flex items-center justify-center font-bold text-lg"
                             [class]="levelBg(c.niveau)">
                          📚
                        </div>
                        <div>
                          <p class="font-bold text-slate-900">{{ c.titre }}</p>
                          <p class="text-xs text-slate-400">Slug: {{ c.slug }}</p>
                        </div>
                      </div>
                    </td>

                    <!-- Domaine / Niveau -->
                    <td class="px-6 py-4">
                      <p class="text-slate-700 font-medium">{{ c.domaine || 'Non spécifié' }}</p>
                      <p class="text-xs text-slate-400 mt-0.5">{{ levelLabel(c.niveau) }}</p>
                    </td>

                    <!-- Tarif -->
                    <td class="px-6 py-4 font-semibold text-slate-700 tabular-nums">
                      {{ c.prixAffichage || (c.prixFcfa ? (c.prixFcfa | number) + ' FCFA' : 'Gratuit') }}
                    </td>

                    <!-- Apprenants -->
                    <td class="px-6 py-4 font-bold text-slate-900 tabular-nums">
                      {{ c.nbApprenants || 0 }} inscrits
                    </td>

                    <!-- Note -->
                    <td class="px-6 py-4">
                      @if (c.noteMoyenne) {
                        <div class="flex items-center gap-1">
                          <svg class="w-3.5 h-3.5 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                          <span class="font-bold text-slate-700">{{ c.noteMoyenne }}</span>
                          <span class="text-xs text-slate-400">({{ c.nbAvis || 0 }})</span>
                        </div>
                      } @else {
                        <span class="text-xs text-slate-400">Aucun avis</span>
                      }
                    </td>

                    <!-- Status -->
                    <td class="px-6 py-4">
                      <span [class]="'badge inline-flex ' + (c.statut === 'PUBLIE' ? 'badge-green' : 'badge-amber')">
                        {{ c.statut }}
                      </span>
                    </td>

                    <!-- Actions -->
                    <td class="px-6 py-4 text-right">
                      <div class="flex justify-end gap-2">
                        @if (c.statut !== 'PUBLIE') {
                          <button (click)="publishCourse(c)"
                                  class="px-3 py-1.5 rounded-lg border border-green-200 text-green-600 text-xs font-bold hover:bg-green-50 transition-colors">
                            Publier
                          </button>
                        } @else {
                          <span class="text-xs text-slate-400 font-semibold px-3 py-1.5">En Ligne</span>
                        }
                      </div>
                    </td>
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
      }
    </div>
  </div>
</div>
  `,
})
export class CourseManagerComponent implements OnInit {
  readonly #courseSvc = inject(CourseService);
  readonly #adminSvc  = inject(AdminService);
  readonly #toast     = inject(ToastService);

  readonly listCourses = signal<CoursResponse[]>([]);
  readonly loading     = signal(true);
  readonly searchQuery = signal('');

  readonly filteredCourses = computed(() => {
    const q = this.searchQuery().toLowerCase().trim();
    const all = this.listCourses();
    if (!q) return all;
    return all.filter(c =>
      c.titre.toLowerCase().includes(q) ||
      (c.domaine || '').toLowerCase().includes(q)
    );
  });

  ngOnInit(): void {
    this.loadCourses();
  }

  loadCourses(): void {
    this.loading.set(true);
    this.#adminSvc.getAllCourses().subscribe({
      next: res => {
        if (res.success && res.data) {
          this.listCourses.set((res.data as any).content || res.data || []);
        }
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.#toast.error('Impossible de charger la liste des formations');
      }
    });
  }

  publishCourse(c: CoursResponse): void {
    if (confirm(`Êtes-vous sûr de vouloir valider et publier la formation "${c.titre}" dans le catalogue ?`)) {
      this.#adminSvc.publierCours(c.id).subscribe({
        next: res => {
          if (res.success) {
            this.#toast.success('La formation a été publiée dans le catalogue');
            this.loadCourses();
          }
        },
        error: () => {
          this.#toast.error('Erreur lors de la publication de la formation');
        }
      });
    }
  }

  levelBg(n: string): string {
    return { DEBUTANT: 'bg-emerald-50 text-emerald-700', INTERMEDIAIRE: 'bg-blue-50 text-blue-700', AVANCE: 'bg-violet-50 text-violet-700' }[n] ?? 'bg-slate-50 text-slate-700';
  }
  levelLabel(n: string): string {
    return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n;
  }
}
