#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 10/16 · Social Apprenant
# ============================================================
# Contenu :
#   community.component.ts     (S12) — Q&R par cours
#   certificate.component.ts   (S13) — certificats + célébration
#   profile.component.ts       (S14) — profil talent éditable
#   referral.component.ts      (S15) — parrainage + filleuls
#   draw.component.ts          (S24) — achat ticket tirage
#   leaderboard.component.ts         — classement global
#   notifications.component.ts       — liste + marquer lu
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
  src/app/features/learner/community \
  src/app/features/learner/certificate \
  src/app/features/learner/profile \
  src/app/features/learner/referral \
  src/app/features/learner/draw \
  src/app/features/learner/leaderboard \
  src/app/features/learner/notifications

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 10 · Social Apprenant        ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. COMMUNITY — S12
# ============================================================
sec "1/7 — community.component.ts (S12)"

cat > src/app/features/learner/community/community.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, input, OnInit,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { CommunityService } from '../../../core/services/community.service';
import { ToastService }     from '../../../core/services/toast.service';
import { AuthService }      from '../../../core/services/auth.service';
import type { MessageResponse } from '../../../core/models';
import { MOCK_MESSAGES } from '../../../core/services/mock.data';

@Component({
  selector: 'app-community',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">

  <!-- En-tête -->
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3 mb-1">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Communauté</h1>
      </div>
      <p class="text-slate-500 text-sm ml-8">Posez vos questions, aidez les autres apprenants.</p>
    </div>
  </div>

  <div class="container py-6 max-w-3xl space-y-5">

    <!-- Formulaire nouvelle question -->
    <div class="card p-5">
      <h2 class="font-semibold text-slate-900 mb-3 flex items-center gap-2">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
        Poser une question
      </h2>
      <form [formGroup]="questionForm" (ngSubmit)="submitQuestion()" novalidate class="space-y-3">
        <textarea formControlName="contenu" rows="3"
                  placeholder="Décrivez votre question avec le plus de détails possible…"
                  [class]="'input resize-none ' + (qSubmitted && questionForm.get('contenu')?.invalid ? 'input-error' : '')">
        </textarea>
        @if (qSubmitted && questionForm.get('contenu')?.hasError('minlength')) {
          <p class="field-error" role="alert">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            10 caractères minimum
          </p>
        }
        <div class="flex justify-end">
          <button type="submit" [disabled]="qLoading()" class="btn-primary btn-sm">
            @if (qLoading()) {
              <svg class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            }
            Publier la question
          </button>
        </div>
      </form>
    </div>

    <!-- Skeleton -->
    @if (loading()) {
      @for (_ of [1,2]; track $_) {
        <div class="card p-5 space-y-3">
          <div class="flex gap-3">
            <div class="shimmer w-9 h-9 rounded-full shrink-0"></div>
            <div class="flex-1 space-y-2">
              <div class="shimmer h-4 rounded w-3/4"></div>
              <div class="shimmer h-3 rounded w-full"></div>
            </div>
          </div>
        </div>
      }
    }

    <!-- Empty state -->
    @if (!loading() && messages().length === 0) {
      <div class="card p-12 text-center">
        <div class="text-5xl mb-3" aria-hidden="true">💬</div>
        <p class="font-semibold text-slate-900 mb-1">Aucune question pour le moment</p>
        <p class="text-sm text-slate-500">Soyez le premier à poser une question !</p>
      </div>
    }

    <!-- Messages -->
    @if (!loading()) {
      @for (msg of messages(); track msg.id; let i = $index) {
        <div class="card p-5 animate-fade-up" [style]="'animation-delay:' + (i * 50) + 'ms'">

          <!-- Question -->
          <div class="flex gap-3 mb-4">
            <div class="w-9 h-9 rounded-full bg-blue-600 flex items-center justify-center
                        text-white text-sm font-bold shrink-0">
              {{ (msg.auteurPrenom ?? '?').charAt(0) }}
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1 flex-wrap">
                <span class="text-sm font-semibold text-slate-900">{{ msg.auteurPrenom ?? 'Apprenant' }}</span>
                @if (msg.estResolu) {
                  <span class="badge-green text-xs">✓ Résolu</span>
                }
                <span class="text-xs text-slate-400 ml-auto">{{ timeAgo(msg.createdAt) }}</span>
              </div>
              <p class="text-sm text-slate-700 leading-relaxed">{{ msg.contenu }}</p>
              <div class="flex items-center gap-4 mt-2">
                <span class="text-xs text-slate-400 flex items-center gap-1">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg>
                  {{ msg.nbLikes }}
                </span>
                <button (click)="toggleReply(msg.id)"
                        class="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors">
                  {{ activeReply() === msg.id ? 'Annuler' : 'Répondre' }}
                </button>
              </div>
            </div>
          </div>

          <!-- Réponses -->
          @if (msg.reponses && msg.reponses.length > 0) {
            <div class="ml-12 space-y-3 border-l-2 border-slate-100 pl-4">
              @for (rep of msg.reponses; track rep.id) {
                <div class="flex gap-2.5">
                  <div class="w-7 h-7 rounded-full bg-green-600 flex items-center justify-center
                              text-white text-xs font-bold shrink-0">
                    {{ (rep.auteurPrenom ?? '?').charAt(0) }}
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-0.5">
                      <span class="text-xs font-semibold text-slate-900">{{ rep.auteurPrenom ?? 'Apprenant' }}</span>
                      <span class="text-xs text-slate-400">{{ timeAgo(rep.createdAt) }}</span>
                    </div>
                    <p class="text-sm text-slate-700 leading-relaxed">{{ rep.contenu }}</p>
                  </div>
                </div>
              }
            </div>
          }

          <!-- Formulaire réponse -->
          @if (activeReply() === msg.id) {
            <div class="ml-12 mt-3 animate-fade-up">
              <form [formGroup]="replyForm" (ngSubmit)="submitReply(msg)" novalidate class="flex gap-2">
                <input type="text" formControlName="contenu"
                       placeholder="Votre réponse…"
                       class="input flex-1 py-2 text-sm">
                <button type="submit" [disabled]="rLoading()" class="btn-primary btn-sm shrink-0">
                  @if (rLoading()) {
                    <svg class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  } @else { Envoyer }
                </button>
              </form>
            </div>
          }
        </div>
      }
    }
  </div>
</div>
  `,
})
export class CommunityComponent implements OnInit {
  readonly coursId = input<string>('c-001');
  readonly #svc    = inject(CommunityService);
  readonly #toast  = inject(ToastService);
  readonly #auth   = inject(AuthService);
  readonly #fb     = inject(FormBuilder);

  readonly messages    = signal<MessageResponse[]>(MOCK_MESSAGES);
  readonly loading     = signal(true);
  readonly activeReply = signal<string | null>(null);
  readonly qLoading    = signal(false);
  readonly rLoading    = signal(false);
  qSubmitted = false;

  readonly questionForm = this.#fb.nonNullable.group({
    contenu: ['', [Validators.required, Validators.minLength(10)]],
  });
  readonly replyForm = this.#fb.nonNullable.group({
    contenu: ['', Validators.required],
  });

  ngOnInit(): void {
    this.#svc.getQuestions(this.coursId()).subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) this.messages.set(r.data.content);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  toggleReply(id: string): void {
    this.activeReply.set(this.activeReply() === id ? null : id);
    this.replyForm.reset();
  }

  submitQuestion(): void {
    this.qSubmitted = true;
    if (this.questionForm.invalid) return;
    this.qLoading.set(true);
    this.#svc.publier(this.coursId(), {
      coursId: this.coursId(),
      contenu: this.questionForm.getRawValue().contenu,
      estQuestion: true,
    }).subscribe({
      next: r => {
        this.qLoading.set(false);
        this.questionForm.reset(); this.qSubmitted = false;
        if (r.success && r.data) {
          this.messages.update(list => [r.data!, ...list]);
          this.#toast.success('Question publiée !', 'Les apprenants et le formateur ont été notifiés.');
        }
      },
      error: () => { this.qLoading.set(false); },
    });
  }

  submitReply(parent: MessageResponse): void {
    if (this.replyForm.invalid) return;
    this.rLoading.set(true);
    this.#svc.publier(this.coursId(), {
      coursId: this.coursId(),
      contenu: this.replyForm.getRawValue().contenu,
      parentId: parent.id,
      estQuestion: false,
    }).subscribe({
      next: r => {
        this.rLoading.set(false);
        if (r.success && r.data) {
          const user = this.#auth.currentUser();
          const rep: MessageResponse = {
            ...r.data,
            auteurPrenom: user?.prenom ?? 'Moi',
          };
          this.messages.update(list => list.map(m =>
            m.id === parent.id ? { ...m, reponses: [...(m.reponses ?? []), rep] } : m
          ));
          this.replyForm.reset();
          this.activeReply.set(null);
          this.#toast.success('Réponse publiée !');
        }
      },
      error: () => { this.rLoading.set(false); },
    });
  }

  timeAgo(iso: string): string {
    const d = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
    const h = Math.floor((Date.now() - new Date(iso).getTime()) / 3_600_000);
    const m = Math.floor((Date.now() - new Date(iso).getTime()) / 60_000);
    if (d >= 1) return `il y a ${d}j`; if (h >= 1) return `il y a ${h}h`; return `il y a ${m}min`;
  }
}
EOF
ok "community.component.ts"

# ============================================================
# 2. CERTIFICATE — S13
# ============================================================
sec "2/7 — certificate.component.ts (S13)"

cat > src/app/features/learner/certificate/certificate.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { CertificatResponse } from '../../../core/models';
import { MOCK_PROFIL } from '../../../core/services/mock.data';

@Component({
  selector: 'app-certificate',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Mes certificats</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-3xl">

    @if (loading()) {
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
        @for (_ of [1,2]; track $_) {
          <div class="card p-6">
            <div class="shimmer h-32 rounded-xl mb-4"></div>
            <div class="shimmer h-4 rounded w-3/4 mb-2"></div>
            <div class="shimmer h-3 rounded w-1/2"></div>
          </div>
        }
      </div>
    }

    @if (!loading() && certs().length === 0) {
      <div class="card p-14 text-center">
        <div class="flex justify-center mb-5">
          <svg width="100" height="100" viewBox="0 0 100 100" fill="none" aria-hidden="true">
            <circle cx="50" cy="50" r="50" fill="#fffbeb"/>
            <circle cx="50" cy="42" r="22" fill="#fde68a"/>
            <circle cx="50" cy="42" r="16" fill="#fbbf24"/>
            <path d="M42 42l6 6 12-12" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M35 66l-6 14 21-7 21 7-6-14" fill="#f59e0b" opacity="0.7"/>
          </svg>
        </div>
        <h2 class="font-bold text-slate-900 text-lg mb-2">Aucun certificat pour l'instant</h2>
        <p class="text-sm text-slate-500 mb-6 max-w-xs mx-auto leading-relaxed">
          Terminez un cours complet pour obtenir votre certificat officiel MbemNova.
        </p>
        <a routerLink="/catalogue" class="btn-primary">Découvrir les formations</a>
      </div>
    }

    @if (!loading() && certs().length > 0) {
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
        @for (cert of certs(); track cert.id; let i = $index) {
          <div class="card overflow-hidden group animate-fade-up"
               [style]="'animation-delay:' + (i * 80) + 'ms'">
            <!-- Bannière certificat -->
            <div class="bg-gradient-to-br from-amber-400 to-orange-500 p-6 text-center relative overflow-hidden">
              <div class="absolute inset-0 opacity-10"
                   style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px" aria-hidden="true"></div>
              <svg width="56" height="56" viewBox="0 0 56 56" fill="none" class="mx-auto mb-2" aria-hidden="true">
                <circle cx="28" cy="28" r="28" fill="rgba(255,255,255,0.2)"/>
                <circle cx="28" cy="22" r="14" fill="white" opacity="0.9"/>
                <path d="M22 22l5 5 9-9" stroke="#d97706" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M18 40l-4 10 14-5 14 5-4-10" fill="white" opacity="0.6"/>
              </svg>
              <p class="text-white font-bold text-xs uppercase tracking-wide">Certificat MbemNova</p>
            </div>

            <!-- Détails -->
            <div class="p-5">
              <h3 class="font-bold text-slate-900 mb-1 leading-snug">
                {{ cert.coursTitre ?? 'Formation MbemNova' }}
              </h3>
              <p class="text-xs text-slate-400 mb-4">
                Obtenu le {{ formatDate(cert.dateEmission) }}
              </p>
              <div class="flex items-center gap-2 p-2.5 bg-slate-50 rounded-lg mb-4">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                <code class="text-xs font-mono text-slate-600 flex-1">{{ cert.codeVerification }}</code>
              </div>
              <div class="flex gap-2">
                <a [href]="cert.lienPdf" target="_blank" rel="noopener" class="btn-primary btn-sm flex-1 justify-center">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                  PDF
                </a>
                <a [routerLink]="['/certificat/verifier', cert.codeVerification]"
                   class="btn-secondary btn-sm flex-1 justify-center">
                  Vérifier
                </a>
                <button (click)="share(cert)"
                        class="btn-ghost btn-sm px-3"
                        aria-label="Partager">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
                </button>
              </div>
            </div>
          </div>
        }
      </div>
    }
  </div>
</div>
  `,
})
export class CertificateComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);

  readonly certs   = signal<CertificatResponse[]>(MOCK_PROFIL.certificats);
  readonly loading = signal(true);

  ngOnInit(): void {
    this.#svc.getMe().subscribe({
      next: r => {
        if (r.success && r.data?.certificats?.length) this.certs.set(r.data.certificats);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  share(cert: CertificatResponse): void {
    const url = `${window.location.origin}/certificat/verifier/${cert.codeVerification}`;
    const text = `🏆 J'ai obtenu ma certification "${cert.coursTitre ?? 'MbemNova'}" ! Vérifiez ici : ${url}`;
    if (navigator.share) {
      navigator.share({ title: 'Mon certificat MbemNova', text, url }).catch(() => {});
    } else {
      navigator.clipboard.writeText(text).then(() =>
        this.#toast.success('Lien copié !', 'Partagez votre certificat sur WhatsApp ou LinkedIn.')
      );
    }
  }

  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
  }
}
EOF
ok "certificate.component.ts"

# ============================================================
# 3. PROFILE — S14
# ============================================================
sec "3/7 — profile.component.ts (S14)"

cat > src/app/features/learner/profile/profile.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { ProfilTalentResponse } from '../../../core/models';
import { MOCK_PROFIL } from '../../../core/services/mock.data';

@Component({
  selector: 'app-profile',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Mon profil talent</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl space-y-6">

    @if (loading()) {
      <div class="card p-6 space-y-4">
        <div class="flex gap-4">
          <div class="shimmer w-20 h-20 rounded-2xl shrink-0"></div>
          <div class="flex-1 space-y-2 pt-2">
            <div class="shimmer h-5 rounded w-1/2"></div>
            <div class="shimmer h-4 rounded w-1/3"></div>
          </div>
        </div>
      </div>
    }

    @if (!loading() && profil()) {

      <!-- Carte identité -->
      <div class="card p-6 animate-fade-up">
        <div class="flex items-start gap-5">
          <!-- Avatar -->
          <div class="w-20 h-20 rounded-2xl bg-blue-600 flex items-center justify-center
                      text-white text-3xl font-black shrink-0" aria-hidden="true">
            {{ profil()!.prenom.charAt(0) }}
          </div>
          <div class="flex-1">
            <h2 class="text-xl font-black text-slate-900">
              {{ profil()!.prenom }} {{ profil()!.nom }}
            </h2>
            <div class="flex flex-wrap gap-2 mt-2">
              <span class="badge-blue">🏅 Rang #{{ profil()!.rang ?? '—' }}</span>
              <span class="badge-gold">⭐ {{ profil()!.xpTotal | number:'1.0-0' }} XP</span>
              <span class="badge-amber">🔥 {{ profil()!.streakJours }}j</span>
              @if (profil()!.disponiblePourEmploi) {
                <span class="badge-green">🟢 Disponible pour emploi</span>
              }
            </div>
          </div>
        </div>
      </div>

      <!-- Formulaire édition -->
      <div class="card p-6 animate-fade-up delay-75">
        <div class="flex items-center justify-between mb-5">
          <h3 class="font-semibold text-slate-900">Informations publiques</h3>
          @if (!editing()) {
            <button (click)="editing.set(true)" class="btn-secondary btn-sm">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              Modifier
            </button>
          }
        </div>

        <form [formGroup]="form" (ngSubmit)="save()" novalidate class="space-y-4">
          <!-- Bio -->
          <div>
            <label for="bio" class="label">Bio</label>
            @if (editing()) {
              <textarea id="bio" formControlName="bio" rows="3"
                        placeholder="Parlez de vous, vos objectifs, vos compétences…"
                        class="input resize-none"></textarea>
            } @else {
              <p class="text-sm text-slate-700 leading-relaxed min-h-12">
                {{ profil()!.bio ?? 'Aucune bio renseignée.' }}
              </p>
            }
          </div>

          <!-- Disponibilité -->
          @if (editing()) {
            <label class="flex items-center gap-3 cursor-pointer">
              <input type="checkbox" formControlName="disponiblePourEmploi"
                     class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500">
              <div>
                <p class="text-sm font-medium text-slate-900">Disponible pour un emploi</p>
                <p class="text-xs text-slate-400">Les recruteurs pourront vous contacter via MbemNova.</p>
              </div>
            </label>
          }

          <!-- Liens -->
          @for (field of linkFields; track field.key) {
            <div>
              <label [for]="field.key" class="label flex items-center gap-1.5">
                <span>{{ field.icon }}</span> {{ field.label }}
              </label>
              @if (editing()) {
                <input [id]="field.key" type="url" [formControlName]="field.key"
                       [placeholder]="field.placeholder" class="input">
              } @else {
                @if (profil()![field.key as keyof ProfilTalentResponse]) {
                  <a [href]="profil()![field.key as keyof ProfilTalentResponse] as string"
                     target="_blank" rel="noopener"
                     class="text-sm text-blue-600 hover:text-blue-700 transition-colors flex items-center gap-1.5">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                    Voir le lien
                  </a>
                } @else {
                  <p class="text-sm text-slate-400 italic">Non renseigné</p>
                }
              }
            </div>
          }

          @if (editing()) {
            <div class="flex gap-3 pt-2">
              <button type="button" (click)="cancelEdit()" class="btn-secondary flex-1">Annuler</button>
              <button type="submit" [disabled]="saving()" class="btn-primary flex-1">
                @if (saving()) {
                  <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                } @else { Enregistrer }
              </button>
            </div>
          }
        </form>
      </div>

      <!-- Certificats -->
      @if (profil()!.certificats.length > 0) {
        <div class="card p-5 animate-fade-up delay-100">
          <h3 class="font-semibold text-slate-900 mb-4">Certifications obtenues</h3>
          <div class="space-y-3">
            @for (cert of profil()!.certificats; track cert.id) {
              <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-semibold text-slate-900 truncate">{{ cert.coursTitre ?? 'Certification MbemNova' }}</p>
                  <p class="text-xs text-slate-400">{{ new Date(cert.dateEmission).toLocaleDateString('fr-FR') }}</p>
                </div>
                <span class="badge-green shrink-0">Vérifié</span>
              </div>
            }
          </div>
        </div>
      }
    }
  </div>
</div>
  `,
})
export class ProfileComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);
  readonly #fb    = inject(FormBuilder);

  readonly profil  = signal<ProfilTalentResponse | null>(MOCK_PROFIL);
  readonly loading = signal(true);
  readonly editing = signal(false);
  readonly saving  = signal(false);
  readonly new     = Date;

  readonly form = this.#fb.nonNullable.group({
    bio:                   [MOCK_PROFIL.bio ?? ''],
    disponiblePourEmploi:  [MOCK_PROFIL.disponiblePourEmploi],
    lienPortfolio:         [MOCK_PROFIL.lienPortfolio ?? ''],
    lienLinkedin:          [MOCK_PROFIL.lienLinkedin ?? ''],
    lienGithub:            [MOCK_PROFIL.lienGithub ?? ''],
  });

  readonly linkFields = [
    { key: 'lienPortfolio', label: 'Portfolio', icon: '🌐', placeholder: 'https://monportfolio.com' },
    { key: 'lienLinkedin',  label: 'LinkedIn',  icon: '💼', placeholder: 'https://linkedin.com/in/...' },
    { key: 'lienGithub',    label: 'GitHub',    icon: '⌨️', placeholder: 'https://github.com/...' },
  ];

  ngOnInit(): void {
    this.#svc.getMe().subscribe({
      next: r => {
        if (r.success && r.data) {
          this.profil.set(r.data);
          this.form.patchValue({
            bio: r.data.bio ?? '',
            disponiblePourEmploi: r.data.disponiblePourEmploi,
            lienPortfolio: r.data.lienPortfolio ?? '',
            lienLinkedin:  r.data.lienLinkedin  ?? '',
            lienGithub:    r.data.lienGithub    ?? '',
          });
        }
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  cancelEdit(): void { this.editing.set(false); }

  save(): void {
    this.saving.set(true);
    this.#svc.update(this.form.getRawValue()).subscribe({
      next: r => {
        this.saving.set(false);
        if (r.success && r.data) this.profil.set(r.data);
        this.editing.set(false);
        this.#toast.success('Profil mis à jour !');
      },
      error: () => { this.saving.set(false); },
    });
  }
}
EOF
ok "profile.component.ts"

# ============================================================
# 4. REFERRAL — S15
# ============================================================
sec "4/7 — referral.component.ts (S15)"

cat > src/app/features/learner/referral/referral.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { ReferralResponse } from '../../../core/models';
import { MOCK_REFERRAL } from '../../../core/services/mock.data';

@Component({
  selector: 'app-referral',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Parrainer un ami</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl space-y-6">

    @if (loading()) {
      <div class="card p-8"><div class="shimmer h-40 rounded-xl"></div></div>
    }

    @if (!loading() && referral()) {

      <!-- Hero parrainage -->
      <div class="card bg-gradient-to-br from-purple-600 to-blue-600 p-8 text-white overflow-hidden relative animate-fade-up">
        <div class="absolute inset-0 opacity-10"
             style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:24px 24px" aria-hidden="true"></div>
        <div class="relative">
          <div class="text-4xl mb-3" aria-hidden="true">🤝</div>
          <h2 class="text-xl font-black mb-2">Invitez vos amis, gagnez ensemble</h2>
          <p class="text-purple-100 text-sm leading-relaxed mb-6">
            Quand votre ami termine son premier module,
            vous recevez tous les deux <strong>200 XP</strong> bonus.
          </p>

          <!-- Lien parrainage -->
          <div class="bg-white/15 backdrop-blur-sm rounded-xl p-4 mb-4">
            <p class="text-xs text-purple-200 mb-2 font-medium uppercase tracking-wide">Votre lien unique</p>
            <div class="flex items-center gap-2">
              <code class="text-sm font-mono text-white flex-1 truncate">
                {{ referral()!.lienParrainage }}
              </code>
              <button (click)="copyLink()" class="btn bg-white/20 hover:bg-white/30 text-white border border-white/30 btn-sm shrink-0">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                Copier
              </button>
            </div>
          </div>

          <!-- Partage WhatsApp -->
          <a [href]="whatsappUrl()" target="_blank" rel="noopener"
             class="btn bg-green-500 hover:bg-green-400 text-white w-full justify-center">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="white" aria-hidden="true">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
              <path d="M11.999 2C6.477 2 2 6.477 2 11.999c0 1.873.518 3.623 1.418 5.12L2 22l5.064-1.387A10 10 0 0 0 12 22c5.523 0 10-4.477 10-10S17.523 2 11.999 2z"/>
            </svg>
            Partager sur WhatsApp
          </a>
        </div>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-3 gap-4 animate-fade-up delay-75">
        @for (stat of stats(); track stat.label) {
          <div class="card p-4 text-center">
            <p class="text-2xl font-black text-slate-900">{{ stat.value }}</p>
            <p class="text-xs text-slate-500 mt-0.5">{{ stat.label }}</p>
          </div>
        }
      </div>

      <!-- Filleuls -->
      @if (referral()!.filleuls.length > 0) {
        <div class="card p-5 animate-fade-up delay-100">
          <h3 class="font-semibold text-slate-900 mb-4">Mes filleuls</h3>
          <div class="space-y-3">
            @for (f of referral()!.filleuls; track f.email) {
              <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                <div class="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0"
                     [class]="f.estActif ? 'bg-green-600' : 'bg-slate-400'">
                  {{ f.prenom.charAt(0) }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-slate-900">{{ f.prenom }}</p>
                  <p class="text-xs text-slate-400">{{ f.email }} · Rejoint {{ formatDate(f.rejointLe) }}</p>
                </div>
                <span [class]="f.estActif ? 'badge-green' : 'badge-slate'">
                  {{ f.estActif ? '✓ Actif' : 'En attente' }}
                </span>
              </div>
            }
          </div>
        </div>
      }

      <!-- Comment ça marche -->
      <div class="card p-5 animate-fade-up delay-150">
        <h3 class="font-semibold text-slate-900 mb-4">Comment ça marche ?</h3>
        <div class="space-y-4">
          @for (step of steps; track step.n) {
            <div class="flex gap-3">
              <div class="w-7 h-7 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">{{ step.n }}</div>
              <div>
                <p class="text-sm font-medium text-slate-900">{{ step.title }}</p>
                <p class="text-xs text-slate-500 leading-relaxed">{{ step.desc }}</p>
              </div>
            </div>
          }
        </div>
      </div>
    }
  </div>
</div>
  `,
})
export class ReferralComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);

  readonly referral = signal<ReferralResponse | null>(MOCK_REFERRAL);
  readonly loading  = signal(true);

  readonly steps = [
    { n: 1, title: 'Partagez votre lien', desc: 'Envoyez votre lien unique par WhatsApp, email ou réseaux sociaux.' },
    { n: 2, title: 'Votre ami s\'inscrit', desc: 'Il crée son compte gratuitement en cliquant sur votre lien.' },
    { n: 3, title: 'Il termine un module', desc: 'Dès qu\'il complète son premier module, la récompense se déclenche.' },
    { n: 4, title: 'Vous gagnez tous les deux', desc: 'Vous recevez chacun 200 XP bonus crédités automatiquement.' },
  ];

  readonly stats = () => [
    { value: this.referral()?.nbFilleulsInvites ?? 0,   label: 'invités' },
    { value: this.referral()?.nbFilleulsActifs ?? 0,    label: 'actifs' },
    { value: (this.referral()?.xpGagneParrainage ?? 0) + ' XP', label: 'gagnés' },
  ];

  ngOnInit(): void {
    this.#svc.getParrainage().subscribe({
      next: r => { if (r.success && r.data) this.referral.set(r.data); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  copyLink(): void {
    const link = this.referral()?.lienParrainage ?? '';
    navigator.clipboard.writeText(link).then(() =>
      this.#toast.success('Lien copié !', 'Collez-le sur WhatsApp pour inviter vos amis.')
    );
  }

  whatsappUrl(): string {
    const link = this.referral()?.lienParrainage ?? '';
    const text = encodeURIComponent(`Je me forme à la tech avec MbemNova 🚀 Commence avec moi et on débloque tous les deux un bonus : ${link}`);
    return `https://wa.me/?text=${text}`;
  }

  formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  }
}
EOF
ok "referral.component.ts"

# ============================================================
# 5. DRAW — S24
# ============================================================
sec "5/7 — draw.component.ts (S24)"

cat > src/app/features/learner/draw/draw.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, OnInit, OnDestroy,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService }  from '../../../core/services/toast.service';
import type { DrawResponse, TicketResponse } from '../../../core/models';
import { MOCK_DRAW } from '../../../core/services/mock.data';

@Component({
  selector: 'app-draw',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Tirage au sort</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-xl space-y-6">

    @if (!loading() && draw()) {

      <!-- Carte principale tirage -->
      <div class="card overflow-hidden animate-fade-up">
        <div class="bg-gradient-to-br from-amber-400 to-orange-600 p-8 text-center relative overflow-hidden">
          <div class="absolute inset-0 opacity-10"
               style="background-image:radial-gradient(circle,white 1px,transparent 1px);background-size:20px 20px" aria-hidden="true"></div>
          <div class="relative">
            <div class="text-5xl mb-3" aria-hidden="true">🎟️</div>
            <h2 class="text-2xl font-black text-white mb-1">Tirage du mois</h2>
            <p class="text-amber-100 text-sm">{{ draw()!.dateDrawFormatee }}</p>
          </div>
        </div>

        <div class="p-6">
          <!-- Formation à gagner -->
          <div class="bg-slate-50 rounded-2xl p-5 mb-6">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Formation à gagner</p>
            <div class="flex items-center gap-4">
              <div class="w-14 h-14 rounded-xl bg-blue-100 flex items-center justify-center text-2xl shrink-0" aria-hidden="true">🏆</div>
              <div>
                <h3 class="font-bold text-slate-900">{{ draw()!.formationGagnanteTitre }}</h3>
                <p class="text-sm text-slate-500">Valeur : <span class="font-bold text-green-600">{{ draw()!.formationGagnantePrix }}</span></p>
              </div>
            </div>
          </div>

          <!-- Stats tirage -->
          <div class="grid grid-cols-2 gap-4 mb-6">
            <div class="bg-slate-50 rounded-xl p-4 text-center">
              <p class="text-2xl font-black text-slate-900">{{ draw()!.nbTicketsVendus }}</p>
              <p class="text-xs text-slate-500">participants</p>
            </div>
            <div class="bg-slate-50 rounded-xl p-4 text-center">
              <p class="text-2xl font-black text-amber-600">{{ draw()!.prixTicketFcfa | number:'1.0-0' }} FCFA</p>
              <p class="text-xs text-slate-500">par ticket</p>
            </div>
          </div>

          <!-- Ticket acheté -->
          @if (monTicket()) {
            <div class="bg-green-50 border border-green-200 rounded-2xl p-5 mb-4 text-center animate-scale-in">
              <p class="text-3xl mb-2" aria-hidden="true">🎟️</p>
              <p class="font-bold text-green-900 mb-1">Ticket acheté !</p>
              <code class="text-xl font-black font-mono text-green-700">{{ monTicket()!.numero }}</code>
              <p class="text-xs text-green-600 mt-1">Votre numéro de participation</p>
            </div>
          }

          <!-- CTA achat -->
          @if (!monTicket() && draw()!.statut === 'OUVERT') {
            <button (click)="acheterTicket()" [disabled]="buying()"
                    class="btn-primary w-full justify-center py-3.5 text-base font-semibold">
              @if (buying()) {
                <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                Achat en cours…
              } @else {
                Acheter un ticket — {{ draw()!.prixTicketFcfa | number:'1.0-0' }} FCFA
              }
            </button>
            <p class="text-xs text-slate-400 text-center mt-2">
              Paiement sécurisé · Ticket immédiatement disponible
            </p>
          }

          @if (draw()!.statut === 'CLOTURE') {
            <div class="bg-slate-100 rounded-xl p-4 text-center">
              <p class="text-sm font-medium text-slate-600">Les inscriptions sont clôturées. Le tirage est en cours.</p>
            </div>
          }

          @if (draw()!.statut === 'GAGNANT_SELECTIONNE') {
            <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 text-center">
              <p class="text-2xl mb-1" aria-hidden="true">🎉</p>
              <p class="font-bold text-amber-900">Gagnant : {{ draw()!.gagnantPrenom }}</p>
              <p class="text-xs text-amber-600 mt-1">Le prochain tirage sera annoncé bientôt !</p>
            </div>
          }
        </div>
      </div>

      <!-- Comment ça marche -->
      <div class="card p-5 animate-fade-up delay-75">
        <h3 class="font-semibold text-slate-900 mb-4">Comment ça marche ?</h3>
        <div class="space-y-3">
          @for (s of steps; track s.n) {
            <div class="flex gap-3">
              <div class="w-6 h-6 rounded-full bg-amber-500 text-white text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">{{ s.n }}</div>
              <p class="text-sm text-slate-700 leading-relaxed">{{ s.text }}</p>
            </div>
          }
        </div>
      </div>
    }
  </div>
</div>
  `,
})
export class DrawComponent implements OnInit {
  readonly #svc   = inject(TalentService);
  readonly #toast = inject(ToastService);

  readonly draw     = signal<DrawResponse | null>(MOCK_DRAW);
  readonly monTicket= signal<TicketResponse | null>(null);
  readonly loading  = signal(true);
  readonly buying   = signal(false);

  readonly steps = [
    { n: 1, text: 'Achetez un ticket au prix indiqué par paiement sécurisé.' },
    { n: 2, text: 'Vous recevez un numéro unique de participation.' },
    { n: 3, text: 'Le tirage a lieu le 1er du mois. 1 gagnant principal + 2 consolations.' },
    { n: 4, text: 'Le gagnant reçoit sa formation gratuitement et est annoncé sur la plateforme.' },
  ];

  ngOnInit(): void {
    this.#svc.getTirage().subscribe({
      next: r => { if (r.success && r.data) this.draw.set(r.data); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  acheterTicket(): void {
    const d = this.draw();
    if (!d) return;
    this.buying.set(true);
    this.#svc.acheterTicket(d.id).subscribe({
      next: r => {
        this.buying.set(false);
        if (r.success && r.data) {
          this.monTicket.set(r.data);
          this.draw.update(dr => dr ? { ...dr, nbTicketsVendus: dr.nbTicketsVendus + 1 } : dr);
          this.#toast.success(`Ticket acheté ! N° ${r.data.numero}`, 'Bonne chance pour le tirage !');
        }
      },
      error: () => { this.buying.set(false); },
    });
  }
}
EOF
ok "draw.component.ts"

# ============================================================
# 6. LEADERBOARD
# ============================================================
sec "6/7 — leaderboard.component.ts"

cat > src/app/features/learner/leaderboard/leaderboard.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import type { LeaderboardEntry } from '../../../core/models';
import { MOCK_LEADERBOARD } from '../../../core/services/mock.data';

@Component({
  selector: 'app-leaderboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center gap-3">
        <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </a>
        <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Classement</h1>
      </div>
    </div>
  </div>

  <div class="container py-8 max-w-2xl">

    <!-- Podium top 3 -->
    @if (!loading() && entries().length >= 3) {
      <div class="flex items-end justify-center gap-4 mb-10 animate-fade-up">
        <!-- 2ème -->
        <div class="text-center">
          <div class="w-16 h-16 rounded-2xl bg-slate-100 border-2 border-slate-300 flex items-center justify-center text-2xl font-black text-slate-500 mx-auto mb-2">
            {{ entries()[1].prenom.charAt(0) }}
          </div>
          <p class="text-xs font-semibold text-slate-700 truncate max-w-16">{{ entries()[1].prenom }}</p>
          <p class="text-xs text-slate-400">{{ entries()[1].xpTotal | number:'1.0-0' }} XP</p>
          <div class="w-16 h-16 bg-slate-200 rounded-t-xl flex items-end justify-center pb-1 mt-2">
            <span class="text-2xl">🥈</span>
          </div>
        </div>
        <!-- 1er -->
        <div class="text-center -mb-2">
          <div class="w-20 h-20 rounded-2xl bg-amber-100 border-2 border-amber-400 flex items-center justify-center text-3xl font-black text-amber-600 mx-auto mb-2 relative">
            {{ entries()[0].prenom.charAt(0) }}
            <div class="absolute -top-3 left-1/2 -translate-x-1/2 text-xl">👑</div>
          </div>
          <p class="text-sm font-bold text-slate-900 truncate max-w-20">{{ entries()[0].prenom }}</p>
          <p class="text-xs text-amber-600 font-semibold">{{ entries()[0].xpTotal | number:'1.0-0' }} XP</p>
          <div class="w-20 h-24 bg-amber-200 rounded-t-xl flex items-end justify-center pb-1 mt-2">
            <span class="text-3xl">🥇</span>
          </div>
        </div>
        <!-- 3ème -->
        <div class="text-center">
          <div class="w-16 h-16 rounded-2xl bg-orange-50 border-2 border-orange-300 flex items-center justify-center text-2xl font-black text-orange-500 mx-auto mb-2">
            {{ entries()[2].prenom.charAt(0) }}
          </div>
          <p class="text-xs font-semibold text-slate-700 truncate max-w-16">{{ entries()[2].prenom }}</p>
          <p class="text-xs text-slate-400">{{ entries()[2].xpTotal | number:'1.0-0' }} XP</p>
          <div class="w-16 h-10 bg-orange-100 rounded-t-xl flex items-end justify-center pb-1 mt-2">
            <span class="text-xl">🥉</span>
          </div>
        </div>
      </div>
    }

    <!-- Liste complète -->
    @if (loading()) {
      <div class="space-y-2">
        @for (_ of [1,2,3,4,5]; track $_) {
          <div class="card p-4 flex items-center gap-3">
            <div class="shimmer w-8 h-8 rounded-lg shrink-0"></div>
            <div class="shimmer w-10 h-10 rounded-full shrink-0"></div>
            <div class="flex-1 space-y-1.5">
              <div class="shimmer h-4 rounded w-1/3"></div>
              <div class="shimmer h-3 rounded w-1/4"></div>
            </div>
            <div class="shimmer h-5 rounded w-16 shrink-0"></div>
          </div>
        }
      </div>
    }

    @if (!loading()) {
      <div class="space-y-2">
        @for (e of entries(); track e.userId; let i = $index) {
          <div [class]="'card p-4 flex items-center gap-3 animate-fade-up '
                        + (e.estMoi ? 'border-blue-200 bg-blue-50' : '')"
               [style]="'animation-delay:' + (i * 30) + 'ms'">
            <!-- Rang -->
            <div [class]="'w-9 h-9 rounded-xl flex items-center justify-center text-sm font-black shrink-0 '
                          + rankBg(i)"
                 [attr.aria-label]="'Rang ' + e.rang">
              {{ rankEmoji(i) }}
            </div>
            <!-- Avatar -->
            <div [class]="'w-10 h-10 rounded-full flex items-center justify-center text-white font-bold shrink-0 '
                          + (e.estMoi ? 'bg-blue-600' : 'bg-slate-500')">
              {{ e.prenom.charAt(0) }}
            </div>
            <!-- Infos -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <p class="text-sm font-semibold text-slate-900 truncate">{{ e.prenom }}</p>
                @if (e.estMoi) { <span class="badge-blue text-xs">Moi</span> }
              </div>
              <p class="text-xs text-slate-400">🔥 {{ e.streakJours }} jours de suite</p>
            </div>
            <!-- XP -->
            <div class="text-right shrink-0">
              <p class="text-sm font-black" [class]="e.estMoi ? 'text-blue-700' : 'text-slate-900'">
                {{ e.xpTotal | number:'1.0-0' }}
              </p>
              <p class="text-xs text-slate-400">XP</p>
            </div>
          </div>
        }
      </div>
    }
  </div>
</div>
  `,
})
export class LeaderboardComponent implements OnInit {
  readonly #svc    = inject(TalentService);
  readonly entries = signal<LeaderboardEntry[]>(MOCK_LEADERBOARD);
  readonly loading = signal(true);

  ngOnInit(): void {
    this.#svc.getLeaderboard().subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.entries.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  rankEmoji(i: number): string { return ['🥇','🥈','🥉'][i] ?? '#' + (i + 1); }
  rankBg(i: number): string {
    return ['bg-amber-100','bg-slate-100','bg-orange-100'][i] ?? 'bg-slate-50';
  }
}
EOF
ok "leaderboard.component.ts"

# ============================================================
# 7. NOTIFICATIONS
# ============================================================
sec "7/7 — notifications.component.ts"

cat > src/app/features/learner/notifications/notifications.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, OnInit,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { NotificationService } from '../../../core/services/notification.service';
import { ToastService }        from '../../../core/services/toast.service';
import type { NotificationResponse } from '../../../core/models';
import { MOCK_NOTIFICATIONS } from '../../../core/services/mock.data';

@Component({
  selector: 'app-notifications',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-slate-50">
  <div class="bg-white border-b border-slate-100">
    <div class="container py-6">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <a routerLink="/app" class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Retour">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
          </a>
          <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">Notifications</h1>
          @if (unreadCount() > 0) {
            <span class="badge-red">{{ unreadCount() }}</span>
          }
        </div>
        @if (unreadCount() > 0) {
          <button (click)="markAllRead()" [disabled]="marking()"
                  class="btn-ghost btn-sm text-slate-500">
            @if (marking()) {
              <svg class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            }
            Tout marquer lu
          </button>
        }
      </div>
    </div>
  </div>

  <div class="container py-6 max-w-2xl">

    @if (loading()) {
      <div class="space-y-2">
        @for (_ of [1,2,3]; track $_) {
          <div class="card p-4 flex gap-3">
            <div class="shimmer w-10 h-10 rounded-xl shrink-0"></div>
            <div class="flex-1 space-y-2">
              <div class="shimmer h-4 rounded w-2/3"></div>
              <div class="shimmer h-3 rounded w-full"></div>
              <div class="shimmer h-3 rounded w-1/4"></div>
            </div>
          </div>
        }
      </div>
    }

    @if (!loading() && notifications().length === 0) {
      <div class="card p-14 text-center">
        <div class="text-5xl mb-3" aria-hidden="true">🔔</div>
        <p class="font-semibold text-slate-900 mb-1">Tout est à jour !</p>
        <p class="text-sm text-slate-500">Vous n'avez aucune notification pour le moment.</p>
      </div>
    }

    @if (!loading() && notifications().length > 0) {
      <div class="space-y-2">
        @for (n of notifications(); track n.id; let i = $index) {
          <a [routerLink]="n.lienAction ?? '/app'"
             class="card flex items-start gap-4 p-4 hover:shadow-md transition-shadow animate-fade-up group"
             [class.bg-blue-50]="!n.estLue"
             [class.border-blue-100]="!n.estLue"
             [style]="'animation-delay:' + (i * 40) + 'ms'">

            <!-- Icône type -->
            <div [class]="'w-10 h-10 rounded-xl flex items-center justify-center text-xl shrink-0 '
                          + iconBg(n.type)"
                 aria-hidden="true">
              {{ notifEmoji(n.type) }}
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex items-start gap-2 mb-0.5">
                <p class="text-sm font-semibold text-slate-900 leading-snug flex-1">{{ n.titre }}</p>
                @if (!n.estLue) {
                  <div class="w-2 h-2 bg-blue-500 rounded-full shrink-0 mt-1.5" aria-label="Non lue"></div>
                }
              </div>
              <p class="text-xs text-slate-500 leading-relaxed mb-1.5">{{ n.contenu }}</p>
              <p class="text-xs text-slate-400">{{ timeAgo(n.createdAt) }}</p>
            </div>

            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8"
                 stroke-width="2" class="shrink-0 mt-1 opacity-0 group-hover:opacity-100 transition-opacity" aria-hidden="true">
              <path d="M9 18l6-6-6-6"/>
            </svg>
          </a>
        }
      </div>
    }
  </div>
</div>
  `,
})
export class NotificationsComponent implements OnInit {
  readonly #svc   = inject(NotificationService);
  readonly #toast = inject(ToastService);

  readonly notifications = signal<NotificationResponse[]>(MOCK_NOTIFICATIONS);
  readonly loading       = signal(true);
  readonly marking       = signal(false);
  readonly unreadCount   = computed(() => this.notifications().filter(n => !n.estLue).length);

  ngOnInit(): void {
    this.#svc.getAll().subscribe({
      next: r => { if (r.success && r.data?.content?.length) this.notifications.set(r.data.content); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  markAllRead(): void {
    this.marking.set(true);
    this.#svc.markAllRead().subscribe({
      next: () => {
        this.marking.set(false);
        this.notifications.update(list => list.map(n => ({ ...n, estLue: true })));
        this.#svc.unreadCount.set(0);
        this.#toast.success('Toutes les notifications sont marquées comme lues.');
      },
      error: () => { this.marking.set(false); },
    });
  }

  notifEmoji(type: string): string {
    const m: Record<string, string> = {
      PAIEMENT_ECHEANCE:'💳', PAIEMENT_RETARD:'⚠️', PAIEMENT_RECU:'✅',
      COURS_DEBLOQUE:'🔓', DEVOIR_PUBLIE:'📝', DEVOIR_CORRIGE:'✏️',
      REPONSE_COMMUNAUTE:'💬', PARRAINAGE_ACTIF:'🤝', TIRAGE_RESULTAT:'🎯',
      CERTIFICAT_GENERE:'🏆', COMPTE_SUSPENDU:'🚫', SYSTEME:'ℹ️',
    };
    return m[type] ?? 'ℹ️';
  }

  iconBg(type: string): string {
    if (type.includes('PAIEMENT'))       return 'bg-amber-100';
    if (type.includes('DEVOIR'))         return 'bg-blue-100';
    if (type === 'CERTIFICAT_GENERE')    return 'bg-green-100';
    if (type === 'COMPTE_SUSPENDU')      return 'bg-red-100';
    if (type === 'PARRAINAGE_ACTIF')     return 'bg-purple-100';
    if (type === 'TIRAGE_RESULTAT')      return 'bg-amber-100';
    return 'bg-slate-100';
  }

  timeAgo(iso: string): string {
    const diff = Date.now() - new Date(iso).getTime();
    const m = Math.floor(diff / 60_000);
    const h = Math.floor(diff / 3_600_000);
    const d = Math.floor(diff / 86_400_000);
    if (d >= 1) return `il y a ${d} jour${d > 1 ? 's' : ''}`;
    if (h >= 1) return `il y a ${h}h`;
    return `il y a ${m} min`;
  }
}
EOF
ok "notifications.component.ts"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 10 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  community.component.ts      (S12 · questions + réponses inline)"
echo -e "  ${G}✓${N}  certificate.component.ts    (S13 · téléchargement + partage natif)"
echo -e "  ${G}✓${N}  profile.component.ts        (S14 · édition profil talent)"
echo -e "  ${G}✓${N}  referral.component.ts       (S15 · lien unique + WhatsApp + filleuls)"
echo -e "  ${G}✓${N}  draw.component.ts           (S24 · achat ticket + numéro attribué)"
echo -e "  ${G}✓${N}  leaderboard.component.ts    (podium top3 + liste complète)"
echo -e "  ${G}✓${N}  notifications.component.ts  (liste + marquer tout lu + badges)"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng11_instructor.sh${N}"
echo ""
