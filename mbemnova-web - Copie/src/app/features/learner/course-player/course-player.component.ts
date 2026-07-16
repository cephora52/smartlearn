import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, input, OnInit, OnDestroy, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { ThemeService }       from '../../../core/services/theme.service';
import { ThemeToggleComponent }from '../../../shared/components/theme-toggle/theme-toggle.component';
import { CourseService }      from '../../../core/services/course.service';
import { ProgressionService } from '../../../core/services/progression.service';
import { QcmService }         from '../../../core/services/qcm.service';
import { ToastService }       from '../../../core/services/toast.service';
import type {
  CoursDetailResponse, LeconDetail,
} from '../../../core/models';
import { MOCK_COURS_DETAIL, MOCK_QCM } from '../../../core/services/mock.data';

@Component({
  selector: 'app-course-player',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, ThemeToggleComponent, FormsModule],
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
    :host-context(.dark) .lesson-body h2 { color:#f1f5f9; }
    :host-context(.dark) .lesson-body h3 { color:#cbd5e1; }
    :host-context(.dark) .lesson-body p  { color:#94a3b8; }
    :host-context(.dark) .lesson-body ul,
    :host-context(.dark) .lesson-body ol { color:#94a3b8; }
    :host-context(.dark) .lesson-body strong { color:#f1f5f9; }
    :host-context(.dark) .lesson-body code  { background:#1e293b; color:#7dd3fc; }
    :host-context(.dark) .lesson-body pre   { background:#020617; border-color:#0f172a; }
    :host-context(.dark) .lesson-body .tip  { background:#1e293b; border-color:#3b82f6; color:#93c5fd; }
    .lesson-body ul { list-style-type: disc !important; }
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
            {{ formatDuration(detail()!.dureeTotaleMinutes) }}
          </p>
        }
      </div>

      <!-- Leçons -->
      <nav class="flex-1 py-2 overflow-y-auto space-y-0.5" aria-label="Leçons du cours">
        @for (lecon of detail()?.lecons ?? []; track lecon.id; let li = $index) {
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

            <span class="flex-1 text-left leading-snug line-clamp-2">{{ li + 1 }}. {{ lecon.titre }}</span>

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
              <a routerLink="/app/paiements" [queryParams]="{ action: 'moratoire', coursId: detail()?.id }" class="btn-secondary w-full justify-center py-3 text-base font-semibold">
                Demander un moratoire
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

        <!-- ── Assistant SmartLearn ────────────────────── -->
        @if (!showXP()) {
          <div [class]="'rounded-2xl p-6 mb-8 border transition-all '
                        + (dark() ? 'bg-slate-900/60 border-slate-800' : 'bg-slate-50 border-slate-200')">
            <div class="flex items-center gap-2.5 mb-4">
              <div [class]="'w-8 h-8 rounded-lg flex items-center justify-center '
                            + (dark() ? 'bg-indigo-500/20 text-indigo-300' : 'bg-indigo-100 text-indigo-700')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
                </svg>
              </div>
              <h3 [class]="'font-bold text-sm tracking-tight ' + (dark() ? 'text-slate-200' : 'text-slate-900')">
                Assistant SmartLearn
              </h3>
              <span class="inline-flex items-center text-[10px] font-black uppercase tracking-wider px-1.5 py-0.5 rounded bg-indigo-500 text-white leading-none">
                IA
              </span>
            </div>

            <p [class]="'text-xs mb-5 leading-relaxed ' + (dark() ? 'text-slate-400' : 'text-slate-500')">
              Optimisez votre apprentissage grâce à notre intelligence artificielle. Générez un résumé pédagogique complet et structuré de cette leçon en un clic.
            </p>

            <div class="flex flex-wrap gap-3">
              <button (click)="genererResume()"
                      [disabled]="summaryLoading()"
                      [class]="'btn btn-sm flex items-center gap-2 font-semibold shadow-sm '
                               + (dark() ? 'bg-indigo-600 hover:bg-indigo-700 text-white' : 'bg-indigo-600 hover:bg-indigo-700 text-white')
                               + (summaryLoading() ? ' opacity-75 cursor-not-allowed' : '')">
                @if (summaryLoading()) {
                  <svg class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  Génération en cours...
                } @else {
                  📄 Générer un résumé
                }
              </button>

              <button (click)="ouvrirChat()"
                      [class]="'btn btn-sm flex items-center gap-2 border font-semibold shadow-sm transition-all '
                               + (dark() ? 'border-slate-700 hover:bg-slate-800 text-slate-300' : 'border-slate-200 hover:bg-slate-100 text-slate-700')">
                💬 Poser une question
              </button>

              @if (progression()?.pourcentage === 100) {
                <button (click)="ouvrirFinalQuiz()"
                        [class]="'btn btn-sm flex items-center gap-2 font-bold shadow-sm transition-all '
                                 + (dark() ? 'bg-amber-600 hover:bg-amber-700 text-white' : 'bg-amber-500 hover:bg-amber-600 text-slate-900')">
                  🏆 Quiz Final
                </button>
              }
            </div>

            @if (summaryError()) {
              <div class="mt-4 p-3 rounded-lg border border-red-500/20 bg-red-500/10 text-red-500 text-xs flex items-start gap-2">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0 mt-0.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                <span>{{ summaryError() }}</span>
              </div>
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

    <!-- ── PANNEAU LATÉRAL RÉSUMÉ IA ────────────────────── -->
    @if (summaryVisible()) {
      <aside [class]="'w-full lg:w-[400px] xl:w-[460px] flex flex-col shrink-0 border-l transition-all duration-300 '
                     + 'fixed inset-y-14 right-0 z-20 lg:static lg:inset-auto '
                     + (dark() ? 'bg-slate-900 border-slate-800 text-slate-100' : 'bg-slate-50 border-slate-200 text-slate-900')"
             aria-label="Résumé de la leçon par l'IA">
        
        <!-- Header Panneau -->
        <div [class]="'p-4 border-b flex items-center justify-between shrink-0 sticky top-0 z-10 '
                      + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
          <div class="flex items-center gap-2">
            <span class="text-sm font-bold tracking-tight">Résumé de la leçon</span>
            <span class="inline-flex items-center text-[9px] font-black uppercase tracking-wider px-1.5 py-0.5 rounded bg-indigo-500 text-white leading-none">
              IA
            </span>
          </div>
          <button (click)="summaryVisible.set(false)"
                  [class]="'p-1.5 rounded-lg transition-colors ' + (dark() ? 'text-slate-400 hover:bg-slate-800 hover:text-white' : 'text-slate-500 hover:bg-slate-200 hover:text-slate-900')"
                  aria-label="Fermer le résumé">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <!-- Contenu du Résumé -->
        <div class="flex-1 p-6 overflow-y-auto lesson-body">
          <div [innerHTML]="formattedSummary()"></div>
        </div>
      </aside>
    }

    <!-- ── PANNEAU LATÉRAL CHAT IA ────────────────────── -->
    @if (chatVisible()) {
      <aside [class]="'w-full lg:w-[400px] xl:w-[460px] flex flex-col shrink-0 border-l transition-all duration-300 '
                     + 'fixed inset-y-14 right-0 z-20 lg:static lg:inset-auto '
                     + (dark() ? 'bg-slate-900 border-slate-800 text-slate-100' : 'bg-slate-50 border-slate-200 text-slate-900')"
             aria-label="Assistant IA SmartLearn">
        
        <!-- Header Panneau -->
        <div [class]="'p-4 border-b flex items-center justify-between shrink-0 sticky top-0 z-10 '
                      + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
          <div class="flex items-center gap-2">
            <span class="text-sm font-bold tracking-tight">Assistant IA SmartLearn</span>
            <span class="inline-flex items-center text-[9px] font-black uppercase tracking-wider px-1.5 py-0.5 rounded bg-indigo-500 text-white leading-none">
              IA
            </span>
          </div>
          <button (click)="chatVisible.set(false)"
                  [class]="'p-1.5 rounded-lg transition-colors ' + (dark() ? 'text-slate-400 hover:bg-slate-800 hover:text-white' : 'text-slate-500 hover:bg-slate-200 hover:text-slate-900')"
                  aria-label="Fermer le chat">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <!-- Messages Log -->
        <div class="flex-1 p-6 overflow-y-auto space-y-4 scroll-smooth" id="chat-messages-log">
          <!-- Initial Welcome message -->
          @if (chatHistory().length === 0) {
            <div [class]="'p-4 rounded-xl text-xs leading-relaxed border '
                          + (dark() ? 'bg-slate-800/40 border-slate-800 text-slate-400' : 'bg-white border-slate-100 text-slate-500')">
              <p class="font-bold mb-1">Posez une question sur cette leçon !</p>
              <p>SmartLearn AI répondra en se basant sur le contenu officiel de la leçon.</p>
            </div>
          }

          <!-- Messages List -->
          @for (msg of chatHistory(); track msg) {
            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1.5 text-[10px] font-bold">
                @if (msg.sender === 'user') {
                  <span [class]="dark() ? 'text-indigo-400' : 'text-indigo-600'">Vous</span>
                } @else {
                  <span [class]="dark() ? 'text-green-400' : 'text-green-600'">SmartLearn AI</span>
                }
              </div>
              <div [class]="'p-4 rounded-xl text-sm leading-relaxed border max-w-full '
                            + (msg.sender === 'user'
                              ? dark() ? 'bg-indigo-600/10 border-indigo-500/20 text-indigo-100' : 'bg-indigo-50 border-indigo-100 text-indigo-900'
                              : dark() ? 'bg-slate-800/50 border-slate-700/60 text-slate-200' : 'bg-white border-slate-100 text-slate-800')">
                <div [innerHTML]="formatChatMessage(msg.content)"></div>
              </div>
            </div>
          }

          <!-- Loading state -->
          @if (chatLoading()) {
            <div class="flex flex-col gap-1">
              <div class="text-[10px] font-bold text-slate-400 animate-pulse">SmartLearn AI réfléchit...</div>
              <div [class]="'p-4 rounded-xl border flex items-center gap-2.5 '
                            + (dark() ? 'bg-slate-800/30 border-slate-800 text-slate-400' : 'bg-slate-50/50 border-slate-100 text-slate-500')">
                <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                </svg>
                <span class="text-xs">Recherche des explications pédagogiques...</span>
              </div>
            </div>
          }

          <!-- Error state -->
          @if (chatError()) {
            <div class="p-3 rounded-lg border border-red-500/20 bg-red-500/10 text-red-500 text-xs flex items-start gap-2">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0 mt-0.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  <span>{{ chatError() }}</span>
            </div>
          }
        </div>

        <!-- Saisie et Bouton Envoyer -->
        <div [class]="'p-4 border-t sticky bottom-0 z-10 '
                      + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
          <form (submit)="envoyerQuestion($event)" class="flex flex-col gap-2">
            <textarea
              name="question"
              [(ngModel)]="rawQuestion"
              [disabled]="chatLoading()"
              placeholder="Posez une question concernant cette leçon..."
              rows="2"
              [class]="'w-full text-xs p-2.5 rounded-xl border outline-none resize-none transition-all '
                       + (dark()
                         ? 'bg-slate-800 border-slate-700 text-white placeholder-slate-500 focus:border-indigo-500'
                         : 'bg-white border-slate-200 text-slate-900 placeholder-slate-400 focus:border-indigo-400')">
            </textarea>
            <button
              type="submit"
              [disabled]="chatLoading() || !rawQuestion.trim()"
              class="btn btn-sm flex items-center justify-center gap-1.5 font-semibold text-white transition-opacity hover:opacity-90 w-full"
              style="background: linear-gradient(135deg,#4f46e5,#312e81)">
              <span>Envoyer</span>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
            </button>
          </form>
        </div>
      </aside>
    }

    <!-- ── PANNEAU LATÉRAL QUIZ FINAL ───────────────────── -->
    @if (finalQuizVisible()) {
      <aside [class]="'w-full lg:w-[400px] xl:w-[460px] flex flex-col shrink-0 border-l transition-all duration-300 '
                     + 'fixed inset-y-14 right-0 z-20 lg:static lg:inset-auto '
                     + (dark() ? 'bg-slate-900 border-slate-800 text-slate-100' : 'bg-slate-50 border-slate-200 text-slate-900')"
             aria-label="Quiz final de la formation">
        
        <!-- Header Panneau -->
        <div [class]="'p-4 border-b flex items-center justify-between shrink-0 sticky top-0 z-10 '
                      + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
          <div class="flex items-center gap-2">
            <span class="text-sm font-bold tracking-tight">Quiz final de la formation</span>
            <span class="inline-flex items-center text-[9px] font-black uppercase tracking-wider px-1.5 py-0.5 rounded bg-indigo-500 text-white leading-none">
              EXAMEN
            </span>
          </div>
          <button (click)="finalQuizVisible.set(false)"
                  [class]="'p-1.5 rounded-lg transition-colors ' + (dark() ? 'text-slate-400 hover:bg-slate-800 hover:text-white' : 'text-slate-500 hover:bg-slate-200 hover:text-slate-900')"
                  aria-label="Fermer le quiz">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <!-- Contenu du Quiz -->
        <div class="flex-1 p-6 overflow-y-auto space-y-6 scroll-smooth" id="final-quiz-scroll-container">
          
          <!-- Welcome Header -->
          <div class="text-center pb-4 border-b border-dashed border-slate-700/30">
            <h4 class="text-base font-bold text-indigo-500">🏆 Félicitations !</h4>
            <p [class]="'text-xs mt-1 ' + (dark() ? 'text-slate-400' : 'text-slate-500')">
              Vous avez terminé cette formation.
            </p>
            <p class="text-xs font-semibold mt-2 text-amber-500">
              Répondez correctement aux 5 questions pour obtenir vos points XP.
            </p>
          </div>

          <!-- Loading spinner -->
          @if (finalQuizLoading()) {
            <div class="py-12 flex flex-col items-center justify-center gap-3">
              <svg class="animate-spin h-8 w-8 text-indigo-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
              </svg>
              <p class="text-xs font-medium text-slate-400 animate-pulse">SmartLearn AI prépare votre quiz final...</p>
            </div>
          }

          <!-- Error block -->
          @if (finalQuizError()) {
            <div class="p-4 rounded-xl border border-red-500/20 bg-red-500/10 text-red-500 text-xs flex flex-col gap-3">
              <div class="flex items-start gap-2">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0 mt-0.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                <span>{{ finalQuizError() }}</span>
              </div>
              <button (click)="genererQuizFinal()" class="btn btn-sm bg-red-600 hover:bg-red-700 text-white font-bold w-full">
                Réessayer
              </button>
            </div>
          }

          <!-- Results Block -->
          @if (finalQuizCorrected() && finalQuizResult()) {
            <div [class]="'p-5 rounded-2xl border text-center '
                          + (finalQuizResult()!.validated
                            ? 'bg-green-500/10 border-green-500/20 text-green-500'
                            : 'bg-red-500/10 border-red-500/20 text-red-500')">
              
              @if (finalQuizResult()!.validated) {
                <p class="text-2xl font-black mb-1">5 / 5</p>
                <p class="text-sm font-bold text-green-500">✅ Félicitations !</p>
                <p class="text-xs mt-1">Vous avez réussi le Quiz Final.</p>
                <p class="text-xs font-semibold mt-2 text-green-500">Les 50 XP de cette formation vous ont été attribués.</p>
              } @else {
                <p class="text-2xl font-black mb-1">{{ finalQuizResult()!.score }} / 5</p>
                <p class="text-xs">Vous devez obtenir 5/5 pour valider cette formation et recevoir les points XP.</p>
                <p class="text-xs font-semibold mt-2 text-amber-500">Les XP ne sont donc pas attribués.</p>
              }
            </div>
          }

          <!-- Questions List -->
          @if (!finalQuizLoading() && finalQuizQuestions().length > 0) {
            <div class="space-y-6">
              @for (q of finalQuizQuestions(); track q; let qi = $index) {
                <div [class]="'p-4 rounded-xl border '
                              + (dark() ? 'bg-slate-800/20 border-slate-800' : 'bg-white border-slate-100')">
                  
                  <!-- Question Title -->
                  <p class="text-xs font-bold mb-3">
                    <span class="text-indigo-500">Q{{ qi + 1 }}.</span> {{ q.question }}
                  </p>

                  <!-- Options List -->
                  <div class="space-y-2">
                    @for (opt of q.options; track opt; let oi = $index) {
                      <label [class]="'flex items-start gap-3 p-3 rounded-lg border text-xs cursor-pointer transition-all '
                                     + (finalQuizAnswers()[qi] === oi
                                       ? 'border-indigo-500 bg-indigo-500/5'
                                       : dark() ? 'border-slate-700/60 hover:bg-slate-800/40' : 'border-slate-200 hover:bg-slate-50')
                                     + (finalQuizCorrected() ? ' pointer-events-none' : '')">
                        <input
                          type="radio"
                          [name]="'final-q-' + qi"
                          [value]="oi"
                          [(ngModel)]="finalQuizAnswers()[qi]"
                          [disabled]="finalQuizCorrected()"
                          class="mt-0.5 accent-indigo-500">
                        
                        <span>{{ opt }}</span>
                      </label>
                    }
                  </div>

                  <!-- Corrections explanations -->
                  @if (finalQuizCorrected()) {
                    <div class="mt-4 pt-3 border-t border-slate-700/20 text-[11px] space-y-2">
                      <div class="flex items-center gap-1.5 font-bold">
                        @if (finalQuizAnswers()[qi] === q.correctAnswer) {
                          <span class="text-green-500">✅ Réponse correcte</span>
                        } @else {
                          <span class="text-red-500">❌ Votre réponse : {{ q.options[finalQuizAnswers()[qi]] || 'Aucune' }}</span>
                        }
                      </div>
                      @if (finalQuizAnswers()[qi] !== q.correctAnswer) {
                        <div class="text-green-500 font-bold">
                          ✅ Bonne réponse : {{ q.options[q.correctAnswer] }}
                        </div>
                      }
                      <div [class]="'p-3 rounded bg-blue-500/5 border border-blue-500/10 text-xs '
                                    + (dark() ? 'text-slate-400' : 'text-slate-600')">
                        <strong class="text-blue-500">📘 Explication :</strong> {{ q.explanation }}
                      </div>
                    </div>
                  }
                </div>
              }
            </div>
          }

        </div>

        <!-- Footer Action Button -->
        @if (!finalQuizLoading() && finalQuizQuestions().length > 0) {
          <div [class]="'p-4 border-t sticky bottom-0 z-10 '
                        + (dark() ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200')">
            
            @if (!finalQuizCorrected()) {
              <button
                (click)="corrigerQuiz()"
                [disabled]="!allQuestionsAnswered()"
                class="btn btn-sm font-semibold text-white transition-opacity hover:opacity-90 w-full disabled:opacity-50 disabled:cursor-not-allowed"
                style="background: linear-gradient(135deg,#4f46e5,#312e81)">
                Corriger mon quiz
              </button>
            } @else {
              <button
                (click)="recommencerQuiz()"
                class="btn btn-sm border font-semibold w-full transition-all"
                [class]="dark() ? 'border-slate-700 hover:bg-slate-800 text-slate-300' : 'border-slate-200 hover:bg-slate-100 text-slate-700'">
                🔄 Recommencer le quiz
              </button>
            }
          </div>
        }
      </aside>
    }
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

  readonly detail      = signal<CoursDetailResponse | null>(null);
  readonly progression = signal<{ pourcentage: number; xpGagne: number } | null>(null);
  readonly activeLecon = signal<LeconDetail | null>(null);
  readonly sidebarOpen = signal(false);

  // Assistant SmartLearn / Résumé
  readonly summaryVisible = signal(false);
  readonly summaryLoading = signal(false);
  readonly summaryContent = signal<string | null>(null);
  readonly summaryError = signal<string | null>(null);

  // Chat
  readonly chatVisible = signal(false);
  readonly chatLoading = signal(false);
  readonly chatHistory = signal<{ sender: 'user' | 'ai'; content: string }[]>([]);
  readonly chatError = signal<string | null>(null);
  rawQuestion = '';

  // Quiz Final
  readonly finalQuizVisible = signal(false);
  readonly finalQuizLoading = signal(false);
  readonly finalQuizError = signal<string | null>(null);
  readonly finalQuizQuestions = signal<any[]>([]);
  readonly finalQuizAnswers = signal<number[]>([]);
  readonly finalQuizCorrected = signal(false);
  readonly finalQuizResult = signal<{ score: number; validated: boolean } | null>(null);
  readonly finalQuizXPGained = signal(false);
  readonly openModules = signal<Set<string>>(new Set());
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
  readonly formattedSummary = computed((): SafeHtml => {
    const raw = this.summaryContent();
    if (!raw) return '';
    
    // Parse markdown to HTML
    let html = raw
      .replace(/^### (.*$)/gim, '<h3 style="font-size:1.2rem; font-weight:600; margin:1.5rem 0 0.625rem; color:#1e293b;">$1</h3>')
      .replace(/^## (.*$)/gim, '<h2 style="font-size:1.5rem; font-weight:700; margin:1.75rem 0 0.875rem; color:#0f172a;">$1</h2>')
      .replace(/^# (.*$)/gim, '<h1 style="font-size:1.8rem; font-weight:800; margin:2rem 0 1rem; color:#0f172a;">$1</h1>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/^\s*[-*]\s+(.*$)/gim, '<li style="margin-bottom:0.375rem;">$1</li>')
      .replace(/(<li>.*<\/li>)/gim, '<ul style="list-style-type:disc; padding-left:1.5rem; margin-bottom:1rem;">$1</ul>')
      .replace(/<\/ul>\s*<ul style="list-style-type:disc; padding-left:1.5rem; margin-bottom:1rem;">/g, '')
      .replace(/\n\n/g, '</p><p style="margin-bottom:1rem;">')
      .replace(/\n/g, '<br>');

    if (!html.startsWith('<h') && !html.startsWith('<p')) {
      html = '<p style="margin-bottom:1rem;">' + html + '</p>';
    }

    return this.#sanitizer.bypassSecurityTrustHtml(html);
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
  readonly activeModuleTitle = computed(() => {
    return 'Programme';
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
            this.detail.set(r.data);
            this.startFirstLecon();
            this.#progressSvc.commencer(r.data.id).subscribe({
              next: pr => {
                if (pr.success && pr.data) {
                  this.progression.set({ pourcentage: pr.data.pourcentage, xpGagne: pr.data.xpGagne });
                  if (pr.data.seuilAtteint && !pr.data.estPaye && (this.detail()?.prixFcfa ?? 0) > 0) this.showPaywall.set(true);
                }
              },
            });
          }
        },
      });
    }
  }

  ngOnDestroy(): void {
    if (this.#xpTimer) clearTimeout(this.#xpTimer);
  }

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
              estTerminee: !!l.estTerminee,
              estVerrouille: !!l.estVerrouille,
              qcm: fullLecon.qcm
            };
            this.activeLecon.set(mappedLecon);
          } else {
            this.activeLecon.set(l);
          }
        },
        error: (err: any) => {
          if (err?.status === 403 || err?.error?.code === 'ACCESS_DENIED') {
            this.showPaywall.set(true);
          } else {
            this.activeLecon.set(l);
          }
        }
      });
    } else {
      this.activeLecon.set(l);
    }
    this.sidebarOpen.set(false);
    this.selectedAnswer.set(null);
    this.qcmResult.set(null);
    this.summaryVisible.set(false);
    this.summaryContent.set(null);
    this.summaryError.set(null);
    this.chatVisible.set(false);
    this.chatHistory.set([]);
    this.chatError.set(null);
    this.rawQuestion = '';
    this.finalQuizVisible.set(false);
    if (isPlatformBrowser(this.#platform)) {
      document.getElementById('lesson-scroll')?.scrollTo({ top: 0, behavior: 'smooth' });
    }
  }

  startFirstLecon(): void {
    const first = this.detail()?.lecons[0];
    if (first && !first.estVerrouille) this.selectLecon(first);
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
    const lecons  = this.detail()?.lecons ?? [];
    const total = lecons.length;
    const done  = lecons.filter(l => l.estTerminee).length;
    const coursId = this.detail()?.id;
    if (!coursId) return;
    this.#progressSvc.terminerLecon(coursId, {
      leconId: lecon.id, nbLeconsTotales: total,
      nbLeconsTerminees: done + 1, xpLecon: lecon.xpReward,
    }).subscribe({
      next: r => {
        this.completing.set(false);
        // Mise à jour locale
        this.detail.update(d => d ? {
          ...d, lecons: d.lecons.map(l => l.id === lecon.id ? { ...l, estTerminee: true } : l)
        } : d);
        this.activeLecon.update(l => l ? { ...l, estTerminee: true } : l);
        if (r.success && r.data) {
          this.progression.set({ pourcentage: r.data.pourcentage, xpGagne: r.data.xpGagne });
          if (r.data.seuilAtteint && !r.data.estPaye && (this.detail()?.prixFcfa ?? 0) > 0) { this.showPaywall.set(true); return; }
        }
        this.lastXP.set(lecon.xpReward);
        this.showXP.set(true);
        this.#xpTimer = setTimeout(() => this.showXP.set(false), 2000);
        this.#toast.success(`+${lecon.xpReward} XP`, 'Leçon terminée !');
        
        if (this.progression()?.pourcentage === 100) {
          setTimeout(() => this.ouvrirFinalQuiz(), 2200);
        } else if (this.hasNext()) {
          setTimeout(() => this.nextLecon(), 1000);
        }
      },
      error: () => { this.completing.set(false); },
    });
  }

  prevLecon(): void {
    const idx = this.activeLeconIndex();
    const lecons = this.detail()?.lecons ?? [];
    if (idx > 0) this.selectLecon(lecons[idx - 1]);
  }
  nextLecon(): void {
    const idx = this.activeLeconIndex();
    const lecons = this.detail()?.lecons ?? [];
    if (idx >= 0 && idx < lecons.length - 1) {
      const nextL = lecons[idx + 1];
      if (nextL.estVerrouille) {
        this.showPaywall.set(true);
      } else {
        this.selectLecon(nextL);
      }
    }
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

  formatDuration(minutes: number): string {
    if (!minutes) return '0 min';
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    if (h > 0) {
      return `${h}h${m > 0 ? m + 'm' : ''}`;
    }
    return `${m} min`;
  }

  ouvrirChat(): void {
    this.summaryVisible.set(false);
    this.chatVisible.set(true);
    this.chatError.set(null);
  }

  envoyerQuestion(event: Event): void {
    event.preventDefault();
    const questionText = this.rawQuestion.trim();
    if (!questionText || this.chatLoading()) return;

    this.chatError.set(null);
    this.chatLoading.set(true);
    
    // Add user message to history
    this.chatHistory.update(history => [...history, { sender: 'user', content: questionText }]);
    this.rawQuestion = '';

    // Scroll to bottom
    this.scrollToBottom();

    const lessonText = this.getLessonTextContent();

    this.#courseSvc.poserQuestionLecon(lessonText, questionText).subscribe({
      next: r => {
        this.chatLoading.set(false);
        if (r.success && r.data?.answer) {
          this.chatHistory.update(history => [...history, { sender: 'ai', content: r.data!.answer }]);
          this.scrollToBottom();
        } else {
          this.chatError.set("Impossible d'obtenir une réponse pour le moment. Veuillez réessayer dans quelques instants.");
          this.scrollToBottom();
        }
      },
      error: () => {
        this.chatLoading.set(false);
        this.chatError.set("Impossible d'obtenir une réponse pour le moment. Veuillez réessayer dans quelques instants.");
        this.scrollToBottom();
      }
    });
  }

  scrollToBottom(): void {
    setTimeout(() => {
      const container = document.getElementById('chat-messages-log');
      if (container) {
        container.scrollTop = container.scrollHeight;
      }
    }, 50);
  }

  getLessonTextContent(): string {
    const lecon = this.activeLecon();
    if (!lecon) return '';
    const rawHtml = lecon.contenu || '';
    return rawHtml.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
  }

  formatChatMessage(content: string): SafeHtml {
    const raw = content || '';
    let html = raw
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/^### (.*$)/gim, '<h3 class="font-bold text-sm my-1">$1</h3>')
      .replace(/^## (.*$)/gim, '<h2 class="font-bold text-base my-2">$1</h2>')
      .replace(/^\s*[-*]\s+(.*$)/gim, '<li style="margin-left: 1rem; list-style-type: disc;">$1</li>')
      .replace(/\n/g, '<br>');
    return this.#sanitizer.bypassSecurityTrustHtml(html);
  }

  ouvrirFinalQuiz(): void {
    this.summaryVisible.set(false);
    this.chatVisible.set(false);
    this.finalQuizVisible.set(true);
    this.finalQuizError.set(null);
    if (this.finalQuizQuestions().length === 0) {
      this.genererQuizFinal();
    }
  }

  genererQuizFinal(): void {
    const lecons = this.detail()?.lecons || [];
    const coursId = this.detail()?.id;
    if (!coursId) return;

    this.finalQuizLoading.set(true);
    this.finalQuizError.set(null);

    // Fetch all lessons details in parallel!
    const requests = lecons.map(l => this.#courseSvc.getLecon(coursId, l.id));
    forkJoin(requests).subscribe({
      next: responses => {
        // Compile the lesson contents
        const contents = responses.map(r => {
          if (r.success && r.data) {
            // Find text blocks or raw content
            const textBloc = r.data.blocs?.find((b: any) => b.typeBloc === 'TEXTE_HTML');
            let content = textBloc ? textBloc.contenuHtml : '';
            // Strip HTML simple regex
            return content.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
          }
          return '';
        }).filter(c => c.length > 0);

        // Now call the AI endpoint
        const title = this.detail()?.titre || 'Formation';
        this.#courseSvc.genererQuizFinal(title, contents).subscribe({
          next: quizRes => {
            this.finalQuizLoading.set(false);
            if (quizRes.success && quizRes.data?.questions) {
              this.finalQuizQuestions.set(quizRes.data.questions);
              this.finalQuizAnswers.set(new Array(quizRes.data.questions.length).fill(-1));
              this.finalQuizCorrected.set(false);
              this.finalQuizResult.set(null);
            } else {
              this.finalQuizError.set("Impossible de générer le quiz final. Veuillez réessayer.");
            }
          },
          error: () => {
            this.finalQuizLoading.set(false);
            this.finalQuizError.set("Impossible de générer le quiz final. Veuillez réessayer.");
          }
        });
      },
      error: () => {
        this.finalQuizLoading.set(false);
        this.finalQuizError.set("Impossible de générer le quiz final. Veuillez réessayer.");
      }
    });
  }

  allQuestionsAnswered(): boolean {
    const answers = this.finalQuizAnswers();
    if (answers.length === 0) return false;
    return answers.every(a => a >= 0);
  }

  corrigerQuiz(): void {
    const questions = this.finalQuizQuestions();
    const answers = this.finalQuizAnswers();
    let score = 0;
    for (let i = 0; i < questions.length; i++) {
      if (answers[i] === questions[i].correctAnswer) {
        score++;
      }
    }
    const validated = (score === 5);
    this.finalQuizResult.set({ score, validated });
    this.finalQuizCorrected.set(true);

    if (validated && !this.finalQuizXPGained()) {
      const coursId = this.detail()?.id;
      if (coursId) {
        this.#progressSvc.validerQuizFinalXp(coursId).subscribe({
          next: r => {
            if (r.success && r.data) {
              this.progression.set({ pourcentage: r.data.pourcentage, xpGagne: r.data.xpGagne });
              this.finalQuizXPGained.set(true);
              this.#toast.success("+50 XP", "Quiz Final réussi !");
            }
          }
        });
      }
    }

    setTimeout(() => {
      const container = document.getElementById('final-quiz-scroll-container');
      if (container) {
        container.scrollTop = 0;
      }
    }, 50);
  }

  recommencerQuiz(): void {
    this.genererQuizFinal();
  }

  genererResume(): void {
    const lecon = this.activeLecon();
    if (!lecon || this.summaryLoading()) return;

    this.summaryLoading.set(true);
    this.summaryError.set(null);

    this.#courseSvc.genererResumeLecon(lecon.id).subscribe({
      next: r => {
        this.summaryLoading.set(false);
        if (r.success && r.data?.response) {
          this.summaryContent.set(r.data.response);
          this.summaryVisible.set(true);
        } else {
          this.summaryError.set("Une erreur inconnue est survenue lors de la génération du résumé.");
        }
      },
      error: err => {
        this.summaryLoading.set(false);
        const msg = err?.error?.message || "Impossible de se connecter au service d'intelligence artificielle.";
        this.summaryError.set(msg);
        this.#toast.error(msg, "Erreur de génération");
      }
    });
  }
}
