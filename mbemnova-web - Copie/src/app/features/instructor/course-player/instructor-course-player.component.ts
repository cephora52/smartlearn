import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, input, OnInit, OnDestroy, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { ThemeService }       from '../../../core/services/theme.service';
import { ThemeToggleComponent }from '../../../shared/components/theme-toggle/theme-toggle.component';
import { CourseService }      from '../../../core/services/course.service';
import { QcmService }         from '../../../core/services/qcm.service';
import { ToastService }       from '../../../core/services/toast.service';
import type {
  CoursDetailResponse, LeconDetail,
} from '../../../core/models';

@Component({
  selector: 'app-instructor-course-player',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, ThemeToggleComponent],
  styles: [`
    /* ── Contenu leçon — s'adapte au thème ───────────────── */
    :host { display: contents; }

    .lesson-body { line-height: 1.8; }

    /* Mode clair */
    .lesson-body h2 { font-size:1.5rem; font-weight:700; margin:1.75rem 0 0.875rem; color:#0f172a; }
    .lesson-body h3 { font-size:1.2rem; font-weight:600; margin:1.5rem 0 0.625rem; color:#1e293b; }
    .lesson-body p  { color:#475569; margin-bottom:1rem; }
    .lesson-body ul,
    .lesson-body ol { color:#475569; padding-left:1.5rem; margin-bottom:1rem; }
    .lesson-body li { margin-bottom:0.375rem; }
    .lesson-body strong { color:#0f172a; font-weight:600; }
    .lesson-body code {
      background:#f1f5f9; color:#0284c7;
      padding:.15rem .45rem; border-radius:5px;
      font-family:'JetBrains Mono',monospace; font-size:.875em;
    }
    .lesson-body pre {
      background:#0f172a; color:#e2e8f0;
      border-radius:12px; padding:1.375rem 1.5rem;
      overflow-x:auto; margin:1.375rem 0;
      border:1px solid #1e293b;
    }
    .lesson-body pre code { background:none; color:#7dd3fc; padding:0; font-size:.9em; }
    .lesson-body .tip {
      background:#eff6ff; border-left:4px solid #2563eb;
      padding:.875rem 1.125rem; border-radius:0 10px 10px 0;
      color:#1e40af; margin:1.375rem 0; font-size:.9rem;
    }

    /* Mode sombre */
    .dark .lesson-body h2 { color:#f1f5f9; }
    .dark .lesson-body h3 { color:#cbd5e1; }
    .dark .lesson-body p  { color:#94a3b8; }
    .dark .lesson-body ul,
    .dark .lesson-body ol { color:#94a3b8; }
    .dark .lesson-body strong { color:#f1f5f9; }
    .dark .lesson-body code  { background:#1e293b; color:#7dd3fc; }
    .dark .lesson-body pre   { background:#020617; border-color:#0f172a; }
    .dark .lesson-body .tip  { background:#1e293b; border-color:#3b82f6; color:#93c5fd; }
  `],
  template: `
<div [class]="'flex flex-col h-screen transition-colors duration-200 '
              + (dark() ? 'bg-slate-950 text-slate-100' : 'bg-white text-slate-900')"
     [attr.data-theme]="dark() ? 'dark' : 'light'">

  <!-- ════════════════════════════════════════════════════ -->
  <!--  TOP BAR                                            -->
  <!-- ════════════════════════════════════════════════════ -->
  <header [class]="'h-14 flex items-center px-4 gap-3 shrink-0 z-30 border-b '
                   + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200')">

    <!-- Retour -->
    <a routerLink="/instructor/formations"
       [class]="'flex items-center gap-1.5 text-sm shrink-0 transition-colors '
                + (dark() ? 'text-slate-400 hover:text-white' : 'text-slate-500 hover:text-slate-900')">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
      <span class="hidden sm:inline">Mes formations</span>
    </a>

    <div [class]="'w-px h-5 ' + (dark() ? 'bg-slate-700' : 'bg-slate-200')" aria-hidden="true"></div>

    <!-- Titre -->
    <h1 [class]="'text-sm font-semibold flex-1 truncate '
                 + (dark() ? 'text-slate-200' : 'text-slate-900')">
      @if (detail()) { {{ detail()!.titre }} }
    </h1>

    <span [class]="'text-xs font-semibold px-2.5 py-1 rounded-full '
                   + (dark() ? 'bg-purple-500/20 text-purple-300' : 'bg-purple-100 text-purple-700')">
      Mode Formateur
    </span>

    <!-- Toggle thème -->
    <app-theme-toggle />

    <!-- Burger sidebar mobile -->
    <button (click)="sidebarOpen.set(!sidebarOpen())"
            [class]="'lg:hidden p-1.5 rounded-lg transition-colors ' + (dark() ? 'text-slate-400 hover:bg-slate-800' : 'text-slate-500 hover:bg-slate-100')"
            [attr.aria-expanded]="sidebarOpen()" aria-label="Sommaire">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
        <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
      </svg>
    </button>
  </header>

  <!-- ════════════════════════════════════════════════════ -->
  <!--  CORPS (sidebar + contenu)                          -->
  <!-- ════════════════════════════════════════════════════ -->
  <div class="flex flex-1 overflow-hidden">

    <!-- ── SIDEBAR SOMMAIRE ─────────────────────────────── -->
    <aside [class]="'w-72 xl:w-80 flex flex-col overflow-y-auto shrink-0 border-r transition-all duration-300 '
                   + 'fixed inset-y-14 left-0 z-20 lg:static lg:inset-auto lg:translate-x-0 '
                   + (sidebarOpen() ? 'translate-x-0 shadow-2xl' : '-translate-x-full')
                   + ' ' + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')"
           aria-label="Sommaire du cours">

      <!-- Header sidebar -->
      <div [class]="'p-4 border-b shrink-0 sticky top-0 z-10 '
                    + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
        <p [class]="'text-xs font-semibold uppercase tracking-wide ' + (dark() ? 'text-slate-400' : 'text-slate-500')">
          Sommaire du cours
        </p>
        @if (detail()) {
          <p [class]="'text-xs mt-0.5 ' + (dark() ? 'text-slate-600' : 'text-slate-400')">
            {{ detail()!.nbLecons }} leçons ·
            {{ formatDuration(detail()!.dureeTotaleMinutes) }}
          </p>
        }
      </div>

      <!-- Leçons -->
      <nav class="flex-1 py-2 overflow-y-auto space-y-0.5" aria-label="Leçons du cours">
        @for (lecon of detail()?.lecons ?? []; track lecon.id; let li = $index) {
          <button (click)="selectLecon(lecon)"
                  [class]="leconClass(lecon)"
                  [attr.aria-current]="activeLecon()?.id === lecon.id ? 'true' : null">

            <!-- Icône état -->
            <div class="shrink-0 w-4 flex items-center justify-center">
              @if (activeLecon()?.id === lecon.id) {
                <div class="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
              } @else if (lecon.typeContenu === 'VIDEO') {
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><polygon points="5 3 19 12 5 21 5 3"/></svg>
              } @else if (lecon.typeContenu === 'QCM') {
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/></svg>
              } @else {
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16h16V8z"/><polyline points="14 2 14 8 20 8"/></svg>
              }
            </div>

            <span class="flex-1 text-left leading-snug line-clamp-2">{{ li + 1 }}. {{ lecon.titre }}</span>

            <div class="flex items-center gap-1.5 shrink-0">
              <span [class]="'text-xs ' + (dark() ? 'text-slate-600' : 'text-slate-400')">
                {{ lecon.dureeMinutes }}m
              </span>
            </div>
          </button>
        }
      </nav>
    </aside>

    <!-- Backdrop mobile -->
    @if (sidebarOpen()) {
      <div class="fixed inset-0 bg-black/50 z-10 lg:hidden"
           (click)="sidebarOpen.set(false)" aria-hidden="true"></div>
    }

    <!-- ── ZONE CONTENU PRINCIPALE ───────────────────────── -->
    <main [class]="'flex-1 overflow-y-auto min-w-0 transition-colors duration-200 '
                   + (dark() ? 'bg-slate-950' : 'bg-white')"
          id="lesson-scroll">

      <!-- ── WELCOME SCREEN ────────────────────────────── -->
      @if (!activeLecon()) {
        <div class="flex items-center justify-center min-h-full p-6">
          <div class="text-center max-w-md animate-fade-up">
            <div [class]="'w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-5 border '
                          + (dark() ? 'bg-blue-600/10 border-blue-500/20' : 'bg-blue-50 border-blue-200')">
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="1.5" aria-hidden="true">
                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
              </svg>
            </div>
            <h2 [class]="'text-xl font-bold mb-2 ' + (dark() ? 'text-white' : 'text-slate-900')">
              Consultation de cours
            </h2>
            <p [class]="'text-sm mb-6 ' + (dark() ? 'text-slate-400' : 'text-slate-500')">
              Sélectionnez une leçon dans le sommaire pour commencer la lecture.
            </p>
            <button (click)="startFirstLecon()" class="btn-primary px-6 py-2.5">
              Commencer la lecture
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </button>
          </div>
        </div>
      }

      <!-- ── CONTENU LEÇON ─────────────────────────────── -->
      @if (activeLecon()) {
        <div class="max-w-3xl mx-auto px-5 sm:px-8 py-8 pb-24">

          <!-- Breadcrumb -->
          <div [class]="'flex items-center gap-2 text-xs mb-5 ' + (dark() ? 'text-slate-500' : 'text-slate-400')">
            <span>Programme</span>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
            <span [class]="dark() ? 'text-slate-300' : 'text-slate-500'">Leçon {{ activeLeconIndex() + 1 }}</span>
            <div class="ml-auto flex items-center gap-3">
              <span class="flex items-center gap-1">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                {{ activeLecon()!.dureeMinutes }}min
              </span>
            </div>
          </div>

          <!-- Titre leçon -->
          <h2 [class]="'text-2xl md:text-3xl font-black mb-8 leading-tight ' + (dark() ? 'text-white' : 'text-slate-900')">
            {{ activeLecon()!.titre }}
          </h2>

          <!-- Type badge -->
          <div class="flex items-center gap-2 mb-6">
            @if (activeLecon()!.typeContenu === 'VIDEO') {
              <span [class]="'inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full '
                             + (dark() ? 'bg-purple-500/20 text-purple-300' : 'bg-purple-100 text-purple-700')">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                Vidéo
              </span>
            } @else if (activeLecon()!.typeContenu === 'QCM') {
              <span [class]="'inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full '
                             + (dark() ? 'bg-blue-500/20 text-blue-300' : 'bg-blue-100 text-blue-700')">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/></svg>
                Quiz interactif
              </span>
            } @else {
              <span [class]="'inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full '
                             + (dark() ? 'bg-green-500/20 text-green-300' : 'bg-green-100 text-green-700')">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16h16V8z"/></svg>
                Lecture
              </span>
            }
          </div>

          <!-- Séparateur -->
          <div [class]="'h-px mb-8 ' + (dark() ? 'bg-slate-800' : 'bg-slate-100')"></div>

          <!-- ── CONTENU TEXTE ──────────────────────────── -->
          @if (activeLecon()!.contenu && activeLecon()!.typeContenu !== 'QCM') {
            <div class="lesson-body mb-10" [innerHTML]="safeContent()"></div>
          }

          <!-- ── VIDÉO EMBED ────────────────────────────── -->
          @if (activeLecon()!.videoUrl) {
            <div [class]="'rounded-2xl overflow-hidden mb-10 border '
                          + (dark() ? 'bg-black border-slate-800' : 'bg-slate-900 border-slate-200')">
              <div class="aspect-video">
                <iframe [src]="safeVideoUrl()"
                        class="w-full h-full"
                        allowfullscreen
                        [title]="activeLecon()!.titre"
                        loading="lazy">
                </iframe>
              </div>
            </div>
          }

          <!-- ── PDF ───────────────────────────────────── -->
          @if (activeLecon()!.pdfUrl) {
            <div [class]="'rounded-2xl p-5 mb-10 border flex items-center gap-4 '
                          + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
              <div class="w-12 h-12 rounded-xl bg-red-100 flex items-center justify-center shrink-0">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
              </div>
              <div class="flex-1">
                <p [class]="'font-semibold text-sm ' + (dark() ? 'text-slate-200' : 'text-slate-900')">Ressource PDF</p>
                <p [class]="'text-xs ' + (dark() ? 'text-slate-500' : 'text-slate-400')">{{ activeLecon()!.titre }}</p>
              </div>
              <a [href]="activeLecon()!.pdfUrl" target="_blank" rel="noopener"
                 class="btn-secondary btn-sm shrink-0">
                Ouvrir
              </a>
            </div>
          }

          <!-- ── QCM INTERACTIF ────────────────────────── -->
          @if (activeLecon()!.aQuiz && currentQCM()) {
            <div [class]="'rounded-2xl p-6 mb-10 border '
                          + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">

              <!-- En-tête quiz -->
              <div class="flex items-center gap-2.5 mb-6">
                <div [class]="'w-8 h-8 rounded-lg flex items-center justify-center '
                              + (dark() ? 'bg-blue-500/20' : 'bg-blue-100')">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                       [attr.stroke]="dark() ? '#60a5fa' : '#2563eb'"
                       stroke-width="2" aria-hidden="true">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
                    <line x1="12" y1="17" x2="12.01" y2="17"/>
                  </svg>
                </div>
                <span [class]="'font-bold ' + (dark() ? 'text-slate-200' : 'text-slate-900')">
                  Quiz de validation (Aperçu)
                </span>
                @if (qcmResult()) {
                  <span [class]="'ml-auto badge ' + (qcmResult()!.estCorrect ? 'badge-green' : 'badge-red')">
                    {{ qcmResult()!.estCorrect ? '✓ Correct' : '✗ Incorrect' }}
                  </span>
                }
              </div>

              <!-- Question -->
              <p [class]="'text-base font-semibold mb-6 leading-relaxed ' + (dark() ? 'text-white' : 'text-slate-900')">
                {{ currentQCM()!.question }}
              </p>

              <!-- Options -->
              <div class="space-y-3" role="radiogroup" aria-label="Options de réponse">
                @for (entry of qcmOptions(); track entry.key) {
                  <button (click)="!selectedAnswer() && submitQCM(entry.key)"
                          [disabled]="!!selectedAnswer()"
                          [class]="optionClass(entry.key)"
                          [attr.aria-pressed]="selectedAnswer() === entry.key">
                    <!-- Lettre -->
                    <div [class]="optionLetterClass(entry.key)">{{ entry.key }}</div>
                    <span class="flex-1 text-left">{{ entry.value }}</span>
                    <!-- Icône résultat -->
                    @if (selectedAnswer() && qcmResult()) {
                      @if (entry.key === qcmResult()!.bonneReponse) {
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                      } @else if (entry.key === selectedAnswer() && !qcmResult()!.estCorrect) {
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                      }
                    }
                  </button>
                }
              </div>

              <!-- Explication après réponse -->
              @if (qcmResult()) {
                <div [class]="'mt-5 p-4 rounded-xl text-sm leading-relaxed border '
                              + (qcmResult()!.estCorrect
                              ? dark() ? 'bg-green-500/10 border-green-500/30 text-green-300' : 'bg-green-50 border-green-200 text-green-800'
                              : dark() ? 'bg-red-500/10 border-red-500/30 text-red-300' : 'bg-red-50 border-red-200 text-red-800')">
                  <p class="font-bold mb-1.5">
                    {{ qcmResult()!.estCorrect ? '✓ Bonne réponse !' : '✗ Pas tout à fait.' }}
                  </p>
                  <p [class]="dark() ? 'text-slate-400' : 'opacity-80'">{{ qcmResult()!.explication }}</p>
                </div>

                @if (!qcmResult()!.estCorrect) {
                  <button (click)="retryQCM()"
                          [class]="'text-sm font-medium mt-4 transition-colors ' + (dark() ? 'text-blue-400 hover:text-blue-300' : 'text-blue-600 hover:text-blue-700')">
                    ↺ Réessayer le quiz
                  </button>
                }
              }
            </div>
          }

          <!-- ── NAVIGATION ─────────────────────────────── -->
          <div [class]="'flex items-center justify-between gap-4 pt-8 border-t '
                        + (dark() ? 'border-slate-800' : 'border-slate-100')">
            <button (click)="prevLecon()" [disabled]="!hasPrev()"
                    [class]="'btn border btn-sm ' + (dark()
                      ? 'bg-slate-800 hover:bg-slate-700 text-slate-300 border-slate-700'
                      : 'bg-white hover:bg-slate-50 text-slate-600 border-slate-200')
                      + (hasPrev() ? '' : ' opacity-30 cursor-not-allowed')">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
              Précédent
            </button>

            <button (click)="nextLecon()" [disabled]="!hasNext()"
                    [class]="'btn border btn-sm ' + (dark()
                      ? 'bg-slate-800 hover:bg-slate-700 text-slate-300 border-slate-700'
                      : 'bg-white hover:bg-slate-50 text-slate-600 border-slate-200')
                      + (hasNext() ? '' : ' opacity-30 cursor-not-allowed')">
              Suivante
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </button>
          </div>

        </div>
      }
    </main>
  </div>
</div>
  `,
})
export class InstructorCoursePlayerComponent implements OnInit, OnDestroy {
  readonly slug = input<string>('');

  readonly #courseSvc   = inject(CourseService);
  readonly #qcmSvc      = inject(QcmService);
  readonly #sanitizer   = inject(DomSanitizer);
  readonly #platform    = inject(PLATFORM_ID);
  readonly themeSvc     = inject(ThemeService);

  readonly dark = this.themeSvc.isDark;

  readonly detail      = signal<CoursDetailResponse | null>(null);
  readonly activeLecon = signal<LeconDetail | null>(null);
  readonly sidebarOpen = signal(false);

  // QCM
  readonly selectedAnswer = signal<string | null>(null);
  readonly qcmResult = signal<{
    estCorrect: boolean; bonneReponse: string; explication: string; leconValidee: boolean;
  } | null>(null);

  readonly safeContent = computed((): SafeHtml => {
    return this.#sanitizer.bypassSecurityTrustHtml(this.activeLecon()?.contenu ?? '');
  });
  readonly safeVideoUrl = computed(() => {
    return this.#sanitizer.bypassSecurityTrustResourceUrl(this.activeLecon()?.videoUrl ?? '');
  });
  readonly currentQCM = computed(() => {
    return (this.activeLecon() as any)?.qcm ?? null;
  });
  readonly qcmOptions = computed(() => {
    const q = this.currentQCM();
    if (!q) return [];
    if (Array.isArray(q.options)) {
      return q.options.map((opt: any) => ({
        key: opt.id || opt.key,
        value: opt.texte || opt.value
      }));
    }
    return Object.entries(q.options || {}).map(([key, value]) => ({ key, value }));
  });
  readonly activeLeconIndex = computed(() => {
    const l = this.activeLecon();
    if (!l) return -1;
    return this.detail()?.lecons.findIndex(x => x.id === l.id) ?? -1;
  });
  readonly hasPrev = computed(() => this.activeLeconIndex() > 0);
  readonly hasNext = computed(() => {
    const index = this.activeLeconIndex();
    const lecons = this.detail()?.lecons ?? [];
    return index >= 0 && index < lecons.length - 1;
  });

  ngOnInit(): void {
    const s = this.slug();
    if (s) {
      this.#courseSvc.getBySlug(s).subscribe({
        next: r => {
          if (r.success && r.data) {
            // Force all lessons to be unlocked (estVerrouille = false) for the instructor
            const unlockedCours = {
              ...r.data,
              lecons: r.data.lecons.map(l => ({ ...l, estVerrouille: false }))
            };
            this.detail.set(unlockedCours);
            this.startFirstLecon();
          }
        },
      });
    }
  }

  ngOnDestroy(): void {}

  selectLecon(l: LeconDetail): void {
    const coursId = this.detail()?.id;
    if (coursId) {
      this.#courseSvc.getLecon(coursId, l.id).subscribe({
        next: r => {
          if (r.success && r.data) {
            const fullLecon = r.data;
            const textBloc = fullLecon.blocs?.find((b: any) => b.typeBloc === 'TEXTE_HTML');
            const videoBloc = fullLecon.blocs?.find((b: any) => b.typeBloc === 'VIDEO' || b.typeBloc === 'VIDEO_YOUTUBE' || b.typeBloc === 'VIDEO_VIMEO');
            const pdfBloc = fullLecon.blocs?.find((b: any) => b.typeBloc === 'PDF_EMBED');

            const mappedLecon: any = {
              id: fullLecon.id,
              coursId: fullLecon.coursId,
              titre: fullLecon.titre,
              typeContenu: videoBloc ? 'VIDEO' : (pdfBloc ? 'PDF' : 'TEXTE'),
              contenu: textBloc ? textBloc.contenuHtml : null,
              videoUrl: videoBloc ? (videoBloc.urlVideo || videoBloc.urlVideo) : null,
              pdfUrl: pdfBloc ? pdfBloc.urlPdf : null,
              dureeMinutes: fullLecon.dureeMinutes,
              xpReward: fullLecon.xpValeur,
              estTerminee: false,
              estVerrouille: false,
              qcm: fullLecon.qcm
            };
            this.activeLecon.set(mappedLecon);
          } else {
            this.activeLecon.set({ ...l, estVerrouille: false });
          }
        },
        error: () => {
          this.activeLecon.set({ ...l, estVerrouille: false });
        }
      });
    } else {
      this.activeLecon.set({ ...l, estVerrouille: false });
    }
    this.sidebarOpen.set(false);
    this.selectedAnswer.set(null);
    this.qcmResult.set(null);
    if (isPlatformBrowser(this.#platform)) {
      document.getElementById('lesson-scroll')?.scrollTo({ top: 0, behavior: 'smooth' });
    }
  }

  startFirstLecon(): void {
    const first = this.detail()?.lecons[0];
    if (first) this.selectLecon(first);
  }

  submitQCM(answer: string): void {
    if (this.selectedAnswer()) return;
    this.selectedAnswer.set(answer);
    const lecon = this.activeLecon();
    if (!lecon) return;
    this.#qcmSvc.valider(lecon.id, { leconId: lecon.id, reponse: answer }).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.qcmResult.set({
            estCorrect:   r.data.estCorrect,
            bonneReponse: r.data.bonneReponse,
            explication:  r.data.explication,
            leconValidee: r.data.leconValidee,
          });
        }
      },
    });
  }

  retryQCM(): void { this.selectedAnswer.set(null); this.qcmResult.set(null); }

  prevLecon(): void {
    const idx = this.activeLeconIndex();
    const lecons = this.detail()?.lecons ?? [];
    if (idx > 0) this.selectLecon(lecons[idx - 1]);
  }
  nextLecon(): void {
    const idx = this.activeLeconIndex();
    const lecons = this.detail()?.lecons ?? [];
    if (idx >= 0 && idx < lecons.length - 1) this.selectLecon(lecons[idx + 1]);
  }

  leconClass(lecon: LeconDetail): string {
    const active = this.activeLecon()?.id === lecon.id;
    const d = this.dark();
    if (active) return `flex items-center gap-2.5 w-full pl-4 pr-3 py-2.5 text-xs transition-colors text-left
      ${d ? 'bg-blue-600/20 text-blue-300' : 'bg-blue-50 text-blue-700 font-semibold'} border-r-2 border-blue-500`;
    return `flex items-center gap-2.5 w-full pl-4 pr-3 py-2.5 text-xs transition-colors text-left
      ${d ? 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50' : 'text-slate-600 hover:text-slate-900 hover:bg-white'}`;
  }

  optionClass(key: string): string {
    const sel = this.selectedAnswer(); const res = this.qcmResult(); const d = this.dark();
    if (!sel) return `w-full flex items-center gap-3.5 px-4 py-3.5 rounded-xl border-2 text-sm font-medium transition-all
      ${d ? 'border-slate-700 bg-slate-800/50 text-slate-300 hover:border-blue-500/50 hover:bg-blue-500/10'
          : 'border-slate-200 bg-white text-slate-700 hover:border-blue-300 hover:bg-blue-50'}`;
    if (key === res?.bonneReponse) return `w-full flex items-center gap-3.5 px-4 py-3.5 rounded-xl border-2 text-sm font-medium
      ${d ? 'border-green-500/60 bg-green-500/10 text-green-300' : 'border-green-400 bg-green-50 text-green-800'}`;
    if (key === sel && !res?.estCorrect) return `w-full flex items-center gap-3.5 px-4 py-3.5 rounded-xl border-2 text-sm font-medium
      ${d ? 'border-red-500/60 bg-red-500/10 text-red-300' : 'border-red-400 bg-red-50 text-red-800'}`;
    return `w-full flex items-center gap-3.5 px-4 py-3.5 rounded-xl border-2 text-sm font-medium
      ${d ? 'border-slate-800 bg-slate-900/30 text-slate-600' : 'border-slate-100 bg-slate-50 text-slate-400'}`;
  }

  optionLetterClass(key: string): string {
    const sel = this.selectedAnswer(); const res = this.qcmResult(); const d = this.dark();
    if (!sel) return `w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0
      ${d ? 'bg-slate-700 text-slate-300' : 'bg-slate-200 text-slate-600'}`;
    if (key === res?.bonneReponse) return `w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0
      ${d ? 'bg-green-500/30 text-green-400' : 'bg-green-200 text-green-700'}`;
    if (key === sel && !res?.estCorrect) return `w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0
      ${d ? 'bg-red-500/30 text-red-400' : 'bg-red-200 text-red-700'}`;
    return `w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0
      ${d ? 'bg-slate-800 text-slate-600' : 'bg-slate-100 text-slate-400'}`;
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
