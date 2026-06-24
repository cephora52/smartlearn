import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { ReactiveFormsModule, FormBuilder } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TalentService } from '../../../core/services/talent.service';
import { ToastService } from '../../../core/services/toast.service';
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
            <a
              routerLink="/app"
              class="text-slate-400 hover:text-slate-600 transition-colors"
              aria-label="Retour"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
                aria-hidden="true"
              >
                <path d="M19 12H5M12 5l-7 7 7 7" />
              </svg>
            </a>
            <h1 class="text-2xl font-black text-slate-900" style="font-family:var(--font);">
              Mon profil talent
            </h1>
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
              <div
                class="w-20 h-20 rounded-2xl bg-blue-600 flex items-center justify-center
                      text-white text-3xl font-black shrink-0"
                aria-hidden="true"
              >
                {{ profil()!.prenom.charAt(0) }}
              </div>
              <div class="flex-1">
                <h2 class="text-xl font-black text-slate-900">
                  {{ profil()!.prenom }} {{ profil()!.nom }}
                </h2>
                <div class="flex flex-wrap gap-2 mt-2">
                  <span class="badge-blue">🏅 Rang #{{ profil()!.rang ?? '—' }}</span>
                  <span class="badge-gold">⭐ {{ profil()!.xpTotal }} XP</span>
                  <!-- <span class="badge-gold">⭐ {{ profil()!.xpTotal | number: '1.0-0' }} XP</span> -->
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
                  <svg
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    aria-hidden="true"
                  >
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                  </svg>
                  Modifier
                </button>
              }
            </div>

            <form [formGroup]="form" (ngSubmit)="save()" novalidate class="space-y-4">
              <!-- Bio -->
              <div>
                <label for="bio" class="label">Bio</label>
                @if (editing()) {
                  <textarea
                    id="bio"
                    formControlName="bio"
                    rows="3"
                    placeholder="Parlez de vous, vos objectifs, vos compétences…"
                    class="input resize-none"
                  ></textarea>
                } @else {
                  <p class="text-sm text-slate-700 leading-relaxed min-h-12">
                    {{ profil()!.bio ?? 'Aucune bio renseignée.' }}
                  </p>
                }
              </div>

              <!-- Disponibilité -->
              @if (editing()) {
                <label class="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    formControlName="disponiblePourEmploi"
                    class="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500"
                  />
                  <div>
                    <p class="text-sm font-medium text-slate-900">Disponible pour un emploi</p>
                    <p class="text-xs text-slate-400">
                      Les recruteurs pourront vous contacter via MbemNova.
                    </p>
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
                    <input
                      [id]="field.key"
                      type="url"
                      [formControlName]="field.key"
                      [placeholder]="field.placeholder"
                      class="input"
                    />
                  } @else {
                    @if (isFieldValid(field.key)) {
                      <a
                        [href]="getFieldValue(field.key)"
                        target="_blank"
                        rel="noopener"
                        class="text-sm text-blue-600 hover:text-blue-700 transition-colors flex items-center gap-1.5"
                      >
                        <svg
                          width="13"
                          height="13"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          aria-hidden="true"
                        >
                          <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                          <polyline points="15 3 21 3 21 9" />
                          <line x1="10" y1="14" x2="21" y2="3" />
                        </svg>
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
                  <button type="button" (click)="cancelEdit()" class="btn-secondary flex-1">
                    Annuler
                  </button>
                  <button type="submit" [disabled]="saving()" class="btn-primary flex-1">
                    @if (saving()) {
                      <svg
                        class="animate-spin"
                        width="16"
                        height="16"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        aria-hidden="true"
                      >
                        <path d="M21 12a9 9 0 1 1-6.219-8.56" />
                      </svg>
                    } @else {
                      Enregistrer
                    }
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
                    <div
                      class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0"
                    >
                      <svg
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="#d97706"
                        stroke-width="2"
                        aria-hidden="true"
                      >
                        <circle cx="12" cy="8" r="6" />
                        <path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11" />
                      </svg>
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-semibold text-slate-900 truncate">
                        {{ cert.coursTitre ?? 'Certification MbemNova' }}
                      </p>
                      <p class="text-xs text-slate-400">
                        {{ formatDate(cert.dateEmission) }}
                      </p>
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
  readonly #svc = inject(TalentService);
  readonly #toast = inject(ToastService);
  readonly #fb = inject(FormBuilder);

  readonly profil = signal<ProfilTalentResponse | null>(MOCK_PROFIL);
  readonly loading = signal(true);
  readonly editing = signal(false);
  readonly saving = signal(false);
  readonly new = Date;

  readonly form = this.#fb.nonNullable.group({
    bio: [MOCK_PROFIL.bio ?? ''],
    disponiblePourEmploi: [MOCK_PROFIL.disponiblePourEmploi],
    lienPortfolio: [MOCK_PROFIL.lienPortfolio ?? ''],
    lienLinkedin: [MOCK_PROFIL.lienLinkedin ?? ''],
    lienGithub: [MOCK_PROFIL.lienGithub ?? ''],
  });

  readonly linkFields = [
    {
      key: 'lienPortfolio',
      label: 'Portfolio',
      icon: '🌐',
      placeholder: 'https://monportfolio.com',
    },
    {
      key: 'lienLinkedin',
      label: 'LinkedIn',
      icon: '💼',
      placeholder: 'https://linkedin.com/in/...',
    },
    { key: 'lienGithub', label: 'GitHub', icon: '⌨️', placeholder: 'https://github.com/...' },
  ];

  formatDate(dateString: string | Date): string {
    if (!dateString) return 'Date inconnue';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR');
  }

  ngOnInit(): void {
    this.#svc.getMe().subscribe({
      next: (r) => {
        if (r.success && r.data) {
          this.profil.set(r.data);
          this.form.patchValue({
            bio: r.data.bio ?? '',
            disponiblePourEmploi: r.data.disponiblePourEmploi,
            lienPortfolio: r.data.lienPortfolio ?? '',
            lienLinkedin: r.data.lienLinkedin ?? '',
            lienGithub: r.data.lienGithub ?? '',
          });
        }
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
      },
    });
  }

  cancelEdit(): void {
    this.editing.set(false);
  }

  save(): void {
    this.saving.set(true);
    this.#svc.update(this.form.getRawValue()).subscribe({
      next: (r) => {
        this.saving.set(false);
        if (r.success && r.data) this.profil.set(r.data);
        this.editing.set(false);
        this.#toast.success('Profil mis à jour !');
      },
      error: () => {
        this.saving.set(false);
      },
    });
  }

  getFieldValue(key: string): unknown {
    const profil = this.profil();
    return profil?.[key as keyof ProfilTalentResponse] ?? null;
  }

  isFieldValid(key: string): boolean {
    const profil = this.profil();
    return !!profil?.[key as keyof ProfilTalentResponse];
  }
}
