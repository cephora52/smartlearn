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
import { CourseService } from '../../../core/services/course.service';
import type { CoursResponse, NiveauCours } from '../../../core/models';
import { MOCK_COURS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-catalog',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, FormsModule],
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
                        class="text-sm text-slate-700 group-hover:text-slate-900 transition-colors flex items-center gap-1.5"
                      >
                        <span aria-hidden="true">{{ n.icon }}</span
                        >{{ n.label }}
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
                  <a
                    [routerLink]="['/cours', c.slug]"
                    class="group flex flex-col bg-white rounded-2xl border border-slate-200
                        hover:border-blue-200 hover:shadow-lg transition-all duration-200 overflow-hidden animate-fade-up"
                    [style]="'animation-delay:' + i * 40 + 'ms'"
                    [attr.aria-label]="c.titre"
                  >
                    <div [class]="'h-36 relative overflow-hidden ' + levelGradient(c.niveau)">
                      <div
                        class="absolute inset-0 opacity-10"
                        style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px"
                        aria-hidden="true"
                      ></div>
                      <div class="absolute top-3 left-3">
                        <span
                          class="bg-black/25 backdrop-blur-sm text-white text-xs font-semibold px-2.5 py-1 rounded-full"
                        >
                          {{ levelEmoji(c.niveau) }} {{ levelLabel(c.niveau) }}
                        </span>
                      </div>
                      @if (c.noteMoyenne) {
                        <div
                          class="absolute bottom-3 right-3 flex items-center gap-1 bg-black/25 backdrop-blur-sm rounded-full px-2 py-0.5"
                        >
                          <svg
                            width="10"
                            height="10"
                            viewBox="0 0 24 24"
                            fill="#fbbf24"
                            aria-hidden="true"
                          >
                            <polygon
                              points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"
                            />
                          </svg>
                          <span class="text-white text-xs font-bold">{{ c.noteMoyenne }}</span>
                        </div>
                      }
                    </div>

                    <div class="flex-1 flex flex-col p-4">
                      <h3
                        class="font-bold text-slate-900 text-sm leading-snug mb-2 line-clamp-2 group-hover:text-blue-700 transition-colors"
                      >
                        {{ c.titre }}
                      </h3>
                      <p class="text-xs text-slate-500 line-clamp-2 mb-3 flex-1 leading-relaxed">
                        {{ c.descriptionCourte }}
                      </p>

                      <div class="flex items-center gap-3 text-xs text-slate-400 mb-3">
                        <span>{{ c.nbLecons }} leçons</span>
                        <span>·</span>
                        <span>{{ Math.floor(c.dureeTotaleMinutes / 60) }}h</span>
                        <span class="ml-auto font-bold text-slate-700">
                          {{ c.prixFcfa   }} FCFA
                        </span>
                          <!-- {{ c.prixFcfa | number: '1.0-0' }} FCFA</span> -->
                      </div>

                      <div class="h-1.5 bg-slate-100 rounded-full overflow-hidden mb-1.5">
                        <div
                          class="h-full bg-green-500 rounded-full"
                          [style.width.%]="c.seuilPaiement * 100"
                        ></div>
                      </div>
                      <p class="text-xs text-green-600 font-medium">
                        {{ c.seuilPaiement * 100  }}% gratuit
                        <!-- {{ c.seuilPaiement * 100 | number: '1.0-0' }}% gratuit -->
                      </p>
                    </div>
                  </a>
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

  search = '';
  selectedNiveau: NiveauCours | '' = '';
  onlyFree = false;

  readonly hasFilter = computed(() => !!this.search || !!this.selectedNiveau || this.onlyFree);

  readonly niveaux = [
    { value: '' as NiveauCours | '', label: 'Tous', icon: '🎯' },
    { value: 'DEBUTANT' as NiveauCours, label: 'Débutant', icon: '🌱' },
    { value: 'INTERMEDIAIRE' as NiveauCours, label: 'Intermédiaire', icon: '⚡' },
    { value: 'AVANCE' as NiveauCours, label: 'Avancé', icon: '🚀' },
  ];

  ngOnInit(): void {
    this.#route.queryParams.subscribe((p) => {
      if (p['niveau']) this.selectedNiveau = p['niveau'] as NiveauCours;
      if (p['q']) this.search = p['q'];
      this.load();
    });
  }

  load(): void {
    this.loading.set(true);
    const params: Record<string, string | number> = { page: this.page(), size: 9 };
    if (this.search) params['q'] = this.search;
    if (this.selectedNiveau) params['niveau'] = this.selectedNiveau;
    if (this.onlyFree) params['gratuit'] = 'true';
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
        this.cours.set([]);
        this.total.set(0);
        this.totalPages.set(0);
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
    this.page.set(0);
    this.load();
  }

  levelGradient(n: string): string {
    return (
      {
        DEBUTANT: 'bg-gradient-to-br from-emerald-500 to-green-700',
        INTERMEDIAIRE: 'bg-gradient-to-br from-blue-500 to-indigo-700',
        AVANCE: 'bg-gradient-to-br from-purple-600 to-violet-700',
      }[n] ?? 'bg-blue-700'
    );
  }
  levelEmoji(n: string): string {
    return { DEBUTANT: '🌱', INTERMEDIAIRE: '⚡', AVANCE: '🚀' }[n] ?? '📚';
  }
  levelLabel(n: string): string {
    return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n;
  }
}
