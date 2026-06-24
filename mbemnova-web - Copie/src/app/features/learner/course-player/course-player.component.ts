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
import { ProgressionService } from '../../../core/services/progression.service';
import { QcmService }         from '../../../core/services/qcm.service';
import { ToastService }       from '../../../core/services/toast.service';
import type {
  CoursDetailResponse, ModuleDetail, LeconDetail,
} from '../../../core/models';
import { MOCK_COURS_DETAIL, MOCK_QCM } from '../../../core/services/mock.data';

@Component({
  selector: 'app-course-player',
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
    /* Numérotation ordonnée -->
    .lesson-body ol { list-style:decimal; }
    .lesson-body ol li::marker { color:#2563eb; font-weight:600; }

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
<!-- Le player prend TOUT l'écran — pas de navbar globale visible -->
<div [class]="'flex flex-col h-screen transition-colors duration-200 '
              + (dark() ? 'bg-slate-950 text-slate-100' : 'bg-white text-slate-900')"
     [attr.data-theme]="dark() ? 'dark' : 'light'">

  <!-- ════════════════════════════════════════════════════ -->
  <!--  TOP BAR                                            -->
  <!-- ════════════════════════════════════════════════════ -->
  <header [class]="'h-14 flex items-center px-4 gap-3 shrink-0 z-30 border-b '
                   + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200')">

    <!-- Retour -->
    <a routerLink="/catalogue"
       [class]="'flex items-center gap-1.5 text-sm shrink-0 transition-colors '
                + (dark() ? 'text-slate-400 hover:text-white' : 'text-slate-500 hover:text-slate-900')">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
      <span class="hidden sm:inline">Catalogue</span>
    </a>

    <div [class]="'w-px h-5 ' + (dark() ? 'bg-slate-700' : 'bg-slate-200')" aria-hidden="true"></div>

    <!-- Titre -->
    <h1 [class]="'text-sm font-semibold flex-1 truncate '
                 + (dark() ? 'text-slate-200' : 'text-slate-900')">
      @if (detail()) { {{ detail()!.titre }} }
    </h1>

    <!-- Progression -->
    @if (progression()) {
      <div class="hidden sm:flex items-center gap-2.5 shrink-0">
        <div [class]="'w-32 h-1.5 rounded-full overflow-hidden ' + (dark() ? 'bg-slate-700' : 'bg-slate-200')">
          <div class="h-full bg-blue-500 rounded-full transition-all duration-500"
               [style.width.%]="progression()!.pourcentage"></div>
        </div>
        <span class="text-xs font-bold text-blue-500">{{ progression()!.pourcentage }}%</span>
      </div>
    }

    <!-- XP Badge -->
    @if (totalXP() > 0) {
      <div [class]="'hidden sm:flex items-center gap-1.5 rounded-lg px-2.5 py-1 border shrink-0 '
                    + (dark()
                    ? 'bg-amber-500/10 border-amber-500/20'
                    : 'bg-amber-50 border-amber-200')">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
        <span [class]="'text-xs font-bold ' + (dark() ? 'text-amber-400' : 'text-amber-600')">
          {{ totalXP() }} XP
        </span>
      </div>
    }

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
            {{ Math.floor(detail()!.dureeTotaleMinutes / 60) }}h{{ detail()!.dureeTotaleMinutes % 60 ? detail()!.dureeTotaleMinutes % 60 + 'min' : '' }}
          </p>
        }
      </div>

      <!-- Modules et leçons -->
      <nav class="flex-1 py-2 overflow-y-auto" aria-label="Modules et leçons">
        @for (mod of detail()?.modules ?? []; track mod.id; let mi = $index) {
          <div class="mb-0.5">
            <!-- En-tête module -->
            <button (click)="toggleModule(mod.id)"
                    [class]="'flex items-center gap-2.5 w-full px-4 py-3 text-left transition-colors '
                             + (dark() ? 'hover:bg-slate-800/60' : 'hover:bg-white')"
                    [attr.aria-expanded]="isModuleOpen(mod.id)">
              <!-- Indicateur complété -->
              <div [class]="'w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors '
                            + (isModuleComplete(mod)
                            ? 'bg-green-500 border-green-500'
                            : dark() ? 'border-slate-600' : 'border-slate-300')">
                @if (isModuleComplete(mod)) {
                  <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                }
              </div>
              <span [class]="'text-xs font-semibold flex-1 leading-snug '
                             + (dark() ? 'text-slate-300' : 'text-slate-700')">
                {{ mi + 1 }}. {{ mod.titre }}
              </span>
              <span [class]="'text-xs shrink-0 ' + (dark() ? 'text-slate-600' : 'text-slate-400')">
                {{ mod.lecons.filter(l => l.estTerminee).length }}/{{ mod.lecons.length }}
              </span>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                   [attr.stroke]="dark() ? '#475569' : '#94a3b8'"
                   stroke-width="2" class="shrink-0 transition-transform"
                   [class.rotate-180]="isModuleOpen(mod.id)" aria-hidden="true">
                <polyline points="6 9 12 15 18 9"/>
              </svg>
            </button>

            <!-- Leçons -->
            @if (isModuleOpen(mod.id)) {
              <div [class]="'border-l-2 ml-[1.625rem] ' + (dark() ? 'border-slate-800' : 'border-slate-200')">
                @for (lecon of mod.lecons; track lecon.id) {
                  <button (click)="!lecon.estVerrouille && selectLecon(lecon)"
                          [disabled]="lecon.estVerrouille"
                          [class]="leconClass(lecon)"
                          [attr.aria-current]="activeLecon()?.id === lecon.id ? 'true' : null">

                    <!-- Icône état -->
                    <div class="shrink-0 w-4 flex items-center justify-center">
                      @if (lecon.estTerminee) {
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                      } @else if (activeLecon()?.id === lecon.id) {
                        <div class="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                      } @else if (lecon.estVerrouille) {
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                      } @else if (lecon.typeContenu === 'VIDEO') {
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                      } @else if (lecon.typeContenu === 'QCM') {
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/></svg>
                      } @else {
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16h16V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                      }
                    </div>

                    <span class="flex-1 text-left leading-snug line-clamp-2">{{ lecon.titre }}</span>

                    <div class="flex items-center gap-1.5 shrink-0">
                      @if (!lecon.estVerrouille && !lecon.estTerminee) {
                        <span [class]="'text-xs font-medium px-1.5 py-0.5 rounded '
                                       + (dark() ? 'bg-green-500/20 text-green-400' : 'bg-green-100 text-green-600')">
                          Gratuit
                        </span>
                      }
                      <span [class]="'text-xs ' + (dark() ? 'text-slate-600' : 'text-slate-400')">
                        {{ lecon.dureeMinutes }}m
                      </span>
                    </div>
                  </button>
                }
              </div>
            }
          </div>
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

      <!-- ── MUR DE PAIEMENT (S7) ──────────────────────── -->
      @if (showPaywall()) {
        <div class="flex items-center justify-center min-h-full p-6">
          <div class="max-w-lg w-full text-center animate-scale-in">
            <div [class]="'w-24 h-24 rounded-3xl flex items-center justify-center mx-auto mb-6 '
                          + (dark() ? 'bg-blue-600/10 border border-blue-500/20' : 'bg-blue-50 border border-blue-200')">
              <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="1.5" aria-hidden="true">
                <rect x="3" y="11" width="18" height="11" rx="2"/>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                <circle cx="12" cy="16" r="1.5" fill="#3b82f6"/>
              </svg>
            </div>
            <h2 [class]="'text-2xl font-black mb-3 ' + (dark() ? 'text-white' : 'text-slate-900')">
              Continuez votre apprentissage !
            </h2>
            <p [class]="'mb-2 ' + (dark() ? 'text-slate-400' : 'text-slate-600')">
              Vous avez complété
              <span class="text-blue-500 font-bold">{{ progression()?.pourcentage ?? 0 }}%</span>
              gratuitement.
            </p>
            <p [class]="'text-sm mb-8 ' + (dark() ? 'text-slate-500' : 'text-slate-500')">
              Débloquez l'accès complet pour obtenir votre certificat.
            </p>

            <div [class]="'rounded-2xl p-6 mb-6 text-left border '
                          + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm')">
              <div class="flex items-center justify-between mb-4">
                <div>
                  <p [class]="'text-2xl font-black ' + (dark() ? 'text-white' : 'text-slate-900')">
                    {{ (detail()?.prixFcfa ?? 0)   }} FCFA
                    <!-- {{ (detail()?.prixFcfa ?? 0) | number:'1.0-0' }} FCFA -->
                  </p>
                  <p [class]="'text-xs ' + (dark() ? 'text-slate-500' : 'text-slate-400')">Accès à vie</p>
                </div>
                <span class="badge-green">Certifiant</span>
              </div>
              <ul class="space-y-2">
                @for (av of paywallAvantages; track av) {
                  <li [class]="'flex items-center gap-2 text-sm '
                               + (dark() ? 'text-slate-400' : 'text-slate-600')">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                    {{ av }}
                  </li>
                }
              </ul>
            </div>

            <div class="flex flex-col gap-3">
              <a routerLink="/app/paiements" class="btn-primary w-full justify-center py-3 text-base font-semibold">
                Débloquer l'accès complet
              </a>
              <button (click)="showPaywall.set(false)"
                      [class]="'text-sm transition-colors ' + (dark() ? 'text-slate-500 hover:text-slate-300' : 'text-slate-400 hover:text-slate-600')">
                Revoir les leçons gratuites
              </button>
            </div>
          </div>
        </div>
      }

      <!-- ── WELCOME SCREEN ────────────────────────────── -->
      @if (!showPaywall() && !activeLecon()) {
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
              Prêt à apprendre ?
            </h2>
            <p [class]="'text-sm mb-6 ' + (dark() ? 'text-slate-400' : 'text-slate-500')">
              Sélectionnez une leçon dans le sommaire.
            </p>
            <button (click)="startFirstLecon()" class="btn-primary px-6 py-2.5">
              Commencer la première leçon
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </button>
          </div>
        </div>
      }

      <!-- ── CONTENU LEÇON ─────────────────────────────── -->
      @if (!showPaywall() && activeLecon()) {
        <div class="max-w-3xl mx-auto px-5 sm:px-8 py-8 pb-24">

          <!-- Breadcrumb -->
          <div [class]="'flex items-center gap-2 text-xs mb-5 ' + (dark() ? 'text-slate-500' : 'text-slate-400')">
            <span>{{ activeModuleTitle() }}</span>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
            <span [class]="dark() ? 'text-slate-300' : 'text-slate-500'">Leçon {{ activeLeconIndex() + 1 }}</span>
            <div class="ml-auto flex items-center gap-3">
              <span class="flex items-center gap-1">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                {{ activeLecon()!.dureeMinutes }}min
              </span>
              <span [class]="'flex items-center gap-1 ' + (dark() ? 'text-amber-400' : 'text-amber-600')">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                +{{ activeLecon()!.xpReward }} XP
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
            @if (activeLecon()!.estTerminee) {
              <span [class]="'inline-flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full '
                             + (dark() ? 'bg-green-500/20 text-green-400' : 'bg-green-100 text-green-700')">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                Terminée
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

          <!-- ── QCM INTERACTIF (S6) ───────────────────── -->
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
                  Quiz de validation
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
          @if (!activeLecon()!.aQuiz || qcmResult()?.leconValidee || !currentQCM()) {
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

              <!-- Marquer terminée -->
              @if (!activeLecon()!.estTerminee) {
                <button (click)="marquerTerminee()" [disabled]="completing()"
                        [class]="'btn-primary px-6 ' + (completing() ? 'opacity-70' : '')">
                  @if (completing()) {
                    <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  }
                  Marquer comme terminée
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                </button>
              } @else {
                <span class="flex items-center gap-1.5 text-sm font-semibold text-green-500">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  Terminée
                </span>
              }

              @if (hasNext()) {
                <button (click)="nextLecon()"
                        [class]="'btn border btn-sm ' + (dark()
                          ? 'bg-slate-800 hover:bg-slate-700 text-slate-300 border-slate-700'
                          : 'bg-white hover:bg-slate-50 text-slate-600 border-slate-200')">
                  Suivante
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                </button>
              }
            </div>
          }
        </div>
      }
    </main>
  </div>

  <!-- XP Burst -->
  @if (showXP()) {
    <div class="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2
                pointer-events-none z-50 animate-scale-in"
         role="status" aria-live="polite">
      <div class="bg-amber-500 text-slate-900 rounded-2xl px-8 py-5 shadow-2xl text-center font-black">
        <p class="text-4xl mb-1">+{{ lastXP() }} XP</p>
        <p class="text-sm opacity-80">Leçon terminée ! 🎉</p>
      </div>
    </div>
  }
</div>
  `,
})
export class CoursePlayerComponent implements OnInit, OnDestroy {
  readonly slug = input<string>('');

  readonly #courseSvc   = inject(CourseService);
  readonly #progressSvc = inject(ProgressionService);
  readonly #qcmSvc      = inject(QcmService);
  readonly #toast       = inject(ToastService);
  readonly #sanitizer   = inject(DomSanitizer);
  readonly #platform    = inject(PLATFORM_ID);
  readonly themeSvc     = inject(ThemeService);
  readonly Math         = Math;

  readonly dark = this.themeSvc.isDark;

  readonly detail      = signal<CoursDetailResponse | null>(MOCK_COURS_DETAIL);
  readonly progression = signal<{ pourcentage: number; xpGagne: number } | null>({ pourcentage: 37, xpGagne: 120 });
  readonly activeLecon = signal<LeconDetail | null>(null);
  readonly sidebarOpen = signal(false);
  readonly openModules = signal<Set<string>>(new Set(['mod-01']));
  readonly showPaywall = signal(false);
  readonly completing  = signal(false);
  readonly showXP      = signal(false);
  readonly lastXP      = signal(0);
  readonly totalXP     = computed(() => this.progression()?.xpGagne ?? 0);

  // QCM
  readonly selectedAnswer = signal<string | null>(null);
  readonly qcmResult = signal<{
    estCorrect: boolean; bonneReponse: string; explication: string; leconValidee: boolean;
  } | null>(null);

  #xpTimer?: ReturnType<typeof setTimeout>;

  readonly paywallAvantages = [
    'Accès à toutes les leçons et modules',
    'Certificat officiel MbemNova',
    'Communauté d\'entraide & correction formateur',
    'Accès à vie — aucune limite de temps',
  ];

  readonly safeContent = computed((): SafeHtml => {
    return this.#sanitizer.bypassSecurityTrustHtml(this.activeLecon()?.contenu ?? '');
  });
  readonly safeVideoUrl = computed(() => {
    return this.#sanitizer.bypassSecurityTrustResourceUrl(this.activeLecon()?.videoUrl ?? '');
  });
  readonly currentQCM = computed(() => {
    const id = this.activeLecon()?.id;
    return id ? MOCK_QCM[id] ?? null : null;
  });
  readonly qcmOptions = computed(() => {
    const q = this.currentQCM();
    return q ? Object.entries(q.options).map(([key, value]) => ({ key, value })) : [];
  });
  readonly activeModuleTitle = computed(() => {
    const l = this.activeLecon();
    return l ? this.detail()?.modules.find(m => m.id === l.moduleId)?.titre ?? '' : '';
  });
  readonly activeLeconIndex = computed(() => {
    const l = this.activeLecon();
    if (!l) return 0;
    const mod = this.detail()?.modules.find(m => m.id === l.moduleId);
    return mod?.lecons.findIndex(x => x.id === l.id) ?? 0;
  });
  readonly hasPrev = computed(() => { const { mi, li } = this.#pos(); return li > 0 || mi > 0; });
  readonly hasNext = computed(() => {
    const mods = this.detail()?.modules ?? [];
    const { mi, li } = this.#pos();
    return li < (mods[mi]?.lecons.length ?? 0) - 1 || mi < mods.length - 1;
  });

  ngOnInit(): void {
    const s = this.slug();
    if (s) {
      this.#courseSvc.getBySlug(s).subscribe({
        next: r => { if (r.success && r.data) this.detail.set(r.data); },
      });
      this.#progressSvc.commencer(this.detail()?.id ?? 'c-001').subscribe({
        next: r => {
          if (r.success && r.data) {
            this.progression.set({ pourcentage: r.data.pourcentage, xpGagne: r.data.xpGagne });
            if (r.data.seuilAtteint && !r.data.estPaye) this.showPaywall.set(true);
          }
        },
      });
    }
  }

  ngOnDestroy(): void {
    if (this.#xpTimer) clearTimeout(this.#xpTimer);
  }

  selectLecon(l: LeconDetail): void {
    this.activeLecon.set(l);
    this.sidebarOpen.set(false);
    this.selectedAnswer.set(null);
    this.qcmResult.set(null);
    if (isPlatformBrowser(this.#platform)) {
      document.getElementById('lesson-scroll')?.scrollTo({ top: 0, behavior: 'smooth' });
    }
  }

  startFirstLecon(): void {
    const first = this.detail()?.modules[0]?.lecons[0];
    if (first && !first.estVerrouille) this.selectLecon(first);
  }

  toggleModule(id: string): void {
    this.openModules.update(s => {
      const n = new Set(s);
      n.has(id) ? n.delete(id) : n.add(id);
      return n;
    });
  }
  isModuleOpen(id: string): boolean { return this.openModules().has(id); }
  isModuleComplete(mod: ModuleDetail): boolean {
    return mod.lecons.length > 0 && mod.lecons.every(l => l.estTerminee);
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

  marquerTerminee(): void {
    const lecon = this.activeLecon();
    if (!lecon || lecon.estTerminee || this.completing()) return;
    this.completing.set(true);
    const mods  = this.detail()?.modules ?? [];
    const total = mods.reduce((s, m) => s + m.lecons.length, 0);
    const done  = mods.reduce((s, m) => s + m.lecons.filter(l => l.estTerminee).length, 0);
    this.#progressSvc.terminerLecon(this.detail()?.id ?? 'c-001', {
      leconId: lecon.id, nbLeconsTotales: total,
      nbLeconsTerminees: done + 1, xpLecon: lecon.xpReward,
    }).subscribe({
      next: r => {
        this.completing.set(false);
        // Mise à jour locale
        this.detail.update(d => d ? {
          ...d, modules: d.modules.map(m => ({
            ...m, lecons: m.lecons.map(l => l.id === lecon.id ? { ...l, estTerminee: true } : l)
          }))
        } : d);
        this.activeLecon.update(l => l ? { ...l, estTerminee: true } : l);
        if (r.success && r.data) {
          this.progression.set({ pourcentage: r.data.pourcentage, xpGagne: r.data.xpGagne });
          if (r.data.seuilAtteint && !r.data.estPaye) { this.showPaywall.set(true); return; }
        }
        this.lastXP.set(lecon.xpReward);
        this.showXP.set(true);
        this.#xpTimer = setTimeout(() => this.showXP.set(false), 2000);
        this.#toast.success(`+${lecon.xpReward} XP`, 'Leçon terminée !');
        if (this.hasNext()) setTimeout(() => this.nextLecon(), 1000);
      },
      error: () => { this.completing.set(false); },
    });
  }

  prevLecon(): void {
    const { mi, li } = this.#pos(); const mods = this.detail()?.modules ?? [];
    if (li > 0) this.selectLecon(mods[mi].lecons[li - 1]);
    else if (mi > 0) { const prev = mods[mi - 1]; this.selectLecon(prev.lecons[prev.lecons.length - 1]); }
  }
  nextLecon(): void {
    const { mi, li } = this.#pos(); const mods = this.detail()?.modules ?? [];
    if (li < mods[mi].lecons.length - 1) this.selectLecon(mods[mi].lecons[li + 1]);
    else if (mi < mods.length - 1) this.selectLecon(mods[mi + 1].lecons[0]);
  }

  #pos(): { mi: number; li: number } {
    const l = this.activeLecon(); if (!l) return { mi: 0, li: 0 };
    const mods = this.detail()?.modules ?? [];
    const mi = mods.findIndex(m => m.id === l.moduleId);
    const li = mods[Math.max(0, mi)]?.lecons.findIndex(x => x.id === l.id) ?? 0;
    return { mi: Math.max(0, mi), li };
  }

  leconClass(lecon: LeconDetail): string {
    const active = this.activeLecon()?.id === lecon.id;
    const d = this.dark();
    if (active) return `flex items-center gap-2.5 w-full pl-4 pr-3 py-2.5 text-xs transition-colors text-left
      ${d ? 'bg-blue-600/20 text-blue-300' : 'bg-blue-50 text-blue-700 font-semibold'} border-r-2 border-blue-500`;
    if (lecon.estVerrouille) return `flex items-center gap-2.5 w-full pl-4 pr-3 py-2.5 text-xs cursor-not-allowed
      ${d ? 'text-slate-700' : 'text-slate-300'}`;
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
}
