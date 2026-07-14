import {
  ChangeDetectionStrategy,
  Component,
  inject,
  signal,
  computed,
  OnInit,
} from '@angular/core';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { CourseService } from '../../../core/services/course.service';
import type { CoursResponse, NiveauCours } from '../../../core/models';
import { CourseCardComponent } from '../../../shared/components/course-card/course-card.component';

@Component({
  selector: 'app-catalog',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, FormsModule, CommonModule, CourseCardComponent],
  template: `
    <div class="min-h-screen bg-white">
      <!-- Header section sombre -->
      <div class="bg-gradient-to-br from-slate-900 to-blue-950 py-14">
        <div class="container">
          <h1 class="h2 text-white mb-3 text-center animate-fade-up">Catalogue des formations</h1>
          <p class="text-slate-300 text-center max-w-xl mx-auto mb-8 animate-fade-up delay-75">
            {{ total() }} formations disponibles. Commencez gratuitement, payez à votre rythme.
          </p>

          <!-- Barre recherche -->
          <div class="max-w-lg mx-auto animate-fade-up delay-100">
            <div class="relative">
              <svg
                class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none"
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                aria-hidden="true"
              >
                <circle cx="11" cy="11" r="8" />
                <path d="M21 21l-4.35-4.35" />
              </svg>
              <input
                type="search"
                [(ngModel)]="search"
                (ngModelChange)="onSearch()"
                placeholder="Rechercher une formation…"
                class="w-full pl-10 pr-4 py-3.5 rounded-xl bg-white/10 border border-white/20
                        text-white placeholder-slate-400 focus:outline-none focus:ring-2
                        focus:ring-blue-400 text-sm backdrop-blur-sm"
                aria-label="Rechercher une formation"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Contenu principal -->
      <div class="container py-10">
        <div class="flex flex-col lg:flex-row gap-8">
          <!-- Filtres sidebar -->
          <aside class="lg:w-56 xl:w-64 shrink-0" aria-label="Filtres">
            <div class="card p-5 sticky top-20">
              <h2 class="font-semibold text-slate-900 mb-4">Filtres</h2>

              <!-- Domaine -->
              <div class="mb-5">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">
                  Domaine
                </p>
                <div class="space-y-2">
                  @for (dom of domains; track dom.value) {
                    <label class="flex items-center gap-2.5 cursor-pointer group">
                      <input
                        type="radio"
                        name="domaine"
                        [value]="dom.value"
                        [(ngModel)]="selectedCategory"
                        (change)="load()"
                        class="w-4 h-4 text-blue-600 border-slate-300 focus:ring-blue-500"
                      />
                      <span
                        class="text-sm text-slate-700 group-hover:text-slate-900 transition-colors flex items-center gap-2"
                      >
                        @switch (dom.value) {
                          @case ('') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
                          }
                          @case ('11111111-1111-1111-1111-111111111111') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="2" y1="20" x2="22" y2="20"/><line x1="12" y1="17" x2="12" y2="20"/></svg>
                          }
                          @case ('22222222-2222-2222-2222-222222222222') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96-.44 2.5 2.5 0 0 1 0-3.12 3 3 0 0 1 0-4.88 2.5 2.5 0 0 1 0-3.12A2.5 2.5 0 0 1 9.5 2Z"/><path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96-.44 2.5 2.5 0 0 0 0-3.12 3 3 0 0 0 0-4.88 2.5 2.5 0 0 0 0-3.12A2.5 2.5 0 0 0 14.5 2Z"/></svg>
                          }
                          @case ('33333333-3333-3333-3333-333333333333') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><path d="M12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 14.7255 3.09032 17.1962 4.85857 19C5.03345 19.177 5.14143 19.4189 5.14143 19.6735C5.14143 20.9584 6.18306 22 7.46794 22H12Z"/><circle cx="7.5" cy="10.5" r="1.5" fill="currentColor"/><circle cx="11.5" cy="7.5" r="1.5" fill="currentColor"/><circle cx="16.5" cy="9.5" r="1.5" fill="currentColor"/></svg>
                          }
                          @case ('44444444-4444-4444-4444-444444444444') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
                          }
                          @case ('55555555-5555-5555-5555-555555555555') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>
                          }
                          @case ('66666666-6666-6666-6666-666666666666') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                          }
                        }
                        {{ dom.label }}
                      </span>
                    </label>
                  }
                </div>
              </div>

              <!-- Niveau -->
              <div class="mb-5">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">
                  Niveau
                </p>
                <div class="space-y-2">
                  @for (n of niveaux; track n.value) {
                    <label class="flex items-center gap-2.5 cursor-pointer group">
                      <input
                        type="radio"
                        name="niveau"
                        [value]="n.value"
                        [(ngModel)]="selectedNiveau"
                        (change)="load()"
                        class="w-4 h-4 text-blue-600 border-slate-300 focus:ring-blue-500"
                      />
                      <span
                        class="text-sm text-slate-700 group-hover:text-slate-900 transition-colors flex items-center gap-2"
                      >
                        @switch (n.value) {
                          @case ('') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
                          }
                          @case ('DEBUTANT') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 3.5 1 9.8A7 7 0 0 1 11 20z"/><path d="M9 22V12"/></svg>
                          }
                          @case ('INTERMEDIAIRE') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
                          }
                          @case ('AVANCE') {
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-slate-400 group-hover:text-blue-600 transition-colors"><path d="M4.5 16.5c-1.5 1.26-2.5 3.5-2.5 3.5s2.24-1 3.5-2.5L18 5l-8.5 8.5-5 3z"/><path d="M12 9l6-6 3 3-6 6-3-3z"/></svg>
                          }
                        }
                        {{ n.label }}
                      </span>
                    </label>
                  }
                </div>
              </div>

              <!-- Accès -->
              <div class="mb-5">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2.5">
                  Accès
                </p>
                <label class="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    [(ngModel)]="onlyFree"
                    (change)="load()"
                    class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500"
                  />
                  <span class="text-sm text-slate-700">Partiellement gratuit</span>
                </label>
              </div>

              @if (hasFilter()) {
                <button
                  (click)="resetFilters()"
                  class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors"
                >
                  ✕ Effacer les filtres
                </button>
              }
            </div>
          </aside>

          <!-- Grille -->
          <div class="flex-1 min-w-0">
            @if (errorMessage()) {
              <div class="bg-red-50 text-red-800 p-4 rounded-xl mb-6 border border-red-200 text-sm flex items-center justify-between animate-fade-in">
                <span class="font-medium">⚠️ {{ errorMessage() }}</span>
                <button (click)="errorMessage.set(null)" class="text-red-500 hover:text-red-700 font-bold text-lg select-none px-2">×</button>
              </div>
            }

            <div class="flex items-center justify-between mb-6">
              @if (!loading()) {
                <p class="text-sm text-slate-500">
                  <strong class="text-slate-900">{{ total() }}</strong>
                  formation{{ total() > 1 ? 's' : '' }}
                </p>
              }
            </div>

            <!-- Skeleton -->
            @if (loading()) {
              <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                @for (item of [1, 2, 3, 4, 5, 6]; track item) {
                  <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
                    <div class="shimmer h-40 w-full"></div>
                    <div class="p-4 space-y-3">
                      <div class="shimmer h-4 rounded w-3/4"></div>
                      <div class="shimmer h-3 rounded w-full"></div>
                      <div class="shimmer h-3 rounded w-2/3"></div>
                      <div class="shimmer h-1.5 rounded-full w-full mt-4"></div>
                    </div>
                  </div>
                }
              </div>
            }

            <!-- Empty state -->
            @if (!loading() && cours().length === 0) {
              <div class="text-center py-20">
                <div class="text-5xl mb-4" aria-hidden="true">🔍</div>
                <h3 class="font-bold text-slate-900 text-lg mb-2">Aucune formation trouvée</h3>
                <p class="text-slate-500 text-sm mb-5">
                  Essayez d'autres mots-clés ou effacez les filtres.
                </p>
                <button (click)="resetFilters()" class="btn-secondary btn-sm">
                  Effacer les filtres
                </button>
              </div>
            }

            <!-- Grille cours -->
            @if (!loading() && cours().length > 0) {
              <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                @for (c of cours(); track c.id; let i = $index) {
                  <app-course-card
                    [course]="c"
                    [delay]="i * 40"
                  ></app-course-card>
                }
              </div>

              <!-- Pagination -->
              @if (totalPages() > 1) {
                <div class="flex items-center justify-center gap-3 mt-10">
                  <button
                    (click)="prevPage()"
                    [disabled]="page() === 0"
                    class="btn-secondary btn-sm"
                    [class.opacity-40]="page() === 0"
                  >
                    <svg
                      width="14"
                      height="14"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      aria-hidden="true"
                    >
                      <path d="M15 18l-6-6 6-6" />
                    </svg>
                  </button>
                  <span class="text-sm text-slate-600">{{ page() + 1 }} / {{ totalPages() }}</span>
                  <button
                    (click)="nextPage()"
                    [disabled]="page() + 1 >= totalPages()"
                    class="btn-secondary btn-sm"
                    [class.opacity-40]="page() + 1 >= totalPages()"
                  >
                    <svg
                      width="14"
                      height="14"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      aria-hidden="true"
                    >
                      <path d="M9 18l6-6-6-6" />
                    </svg>
                  </button>
                </div>
              }
            }
          </div>
        </div>
      </div>
    </div>
  `,
})
export class CatalogComponent implements OnInit {
  readonly #svc = inject(CourseService);
  readonly #route = inject(ActivatedRoute);
  readonly Math = Math;

  readonly cours = signal<CoursResponse[]>([]);
  readonly loading = signal(true);
  readonly total = signal(0);
  readonly page = signal(0);
  readonly totalPages = signal(0);
  readonly errorMessage = signal<string | null>(null);

  search = '';
  selectedNiveau: NiveauCours | '' = '';
  onlyFree = false;
  selectedCategory = '';

  readonly domains = [
    { value: '', label: 'Tous', icon: '📁' },
    { value: '11111111-1111-1111-1111-111111111111', label: 'Bureautique & Productivité', icon: '💻' },
    { value: '22222222-2222-2222-2222-222222222222', label: 'Data et IA', icon: '🧠' },
    { value: '33333333-3333-3333-3333-333333333333', label: 'Design Graphique et UI/UX', icon: '🎨' },
    { value: '44444444-4444-4444-4444-444444444444', label: 'Développement Web et Mobile', icon: '🚀' },
    { value: '55555555-5555-5555-5555-555555555555', label: 'Marketing et Communication', icon: '📢' },
    { value: '66666666-6666-6666-6666-666666666666', label: 'Réseaux Système et Sécurité', icon: '🛡️' }
  ];

  readonly hasFilter = computed(() => !!this.search || !!this.selectedNiveau || this.onlyFree || !!this.selectedCategory);

  readonly niveaux = [
    { value: '' as NiveauCours | '', label: 'Tous', icon: '🎯' },
    { value: 'DEBUTANT' as NiveauCours, label: 'Débutant', icon: '🌱' },
    { value: 'INTERMEDIAIRE' as NiveauCours, label: 'Intermédiaire', icon: '⚡' },
    { value: 'AVANCE' as NiveauCours, label: 'Avancé', icon: '🚀' },
  ];

  ngOnInit(): void {
    this.#route.queryParams.subscribe((p) => {
      if (p['niveau']) this.selectedNiveau = p['niveau'] as NiveauCours;
      if (p['categoryId']) {
        this.selectedCategory = p['categoryId'];
      } else if (p['q']) {
        const found = this.domains.find(d => d.label.toLowerCase() === p['q'].toLowerCase());
        if (found) {
          this.selectedCategory = found.value;
          this.search = '';
        } else {
          this.search = p['q'];
        }
      }
      this.load();
    });
  }

  load(): void {
    this.loading.set(true);
    this.errorMessage.set(null);
    const params: Record<string, string | number> = { page: this.page(), size: 9 };
    if (this.search) params['q'] = this.search;
    if (this.selectedNiveau) params['niveau'] = this.selectedNiveau;
    if (this.onlyFree) params['gratuit'] = 'true';
    if (this.selectedCategory) params['categorieId'] = this.selectedCategory;
    this.#svc.getAll(params).subscribe({
      next: (r) => {
        if (r.success && r.data) {
          this.cours.set(r.data.content);
          this.total.set(r.data.totalElements);
          this.totalPages.set(r.data.totalPages);
        }
        this.loading.set(false);
      },
      error: () => {
        this.errorMessage.set("Une erreur réseau ou serveur est survenue lors de la mise à jour du catalogue. Les formations affichées peuvent ne pas être à jour.");
        this.loading.set(false);
      },
    });
  }

  onSearch(): void {
    this.page.set(0);
    this.load();
  }
  prevPage(): void {
    if (this.page() > 0) {
      this.page.update((p) => p - 1);
      this.load();
    }
  }
  nextPage(): void {
    if (this.page() + 1 < this.totalPages()) {
      this.page.update((p) => p + 1);
      this.load();
    }
  }
  resetFilters(): void {
    this.search = '';
    this.selectedNiveau = '';
    this.onlyFree = false;
    this.selectedCategory = '';
    this.page.set(0);
    this.load();
  }


}
