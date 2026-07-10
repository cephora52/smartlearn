import { ChangeDetectionStrategy, Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AdminService } from '../../../core/services/admin.service';
import { ToastService } from '../../../core/services/toast.service';
import { CourseBuilderDraftService } from './course-builder-draft.service';

@Component({
  selector: 'app-course-setup',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
<div class="min-h-screen bg-[#f8f9fb]">
  <header class="bg-white border-b border-slate-100">
    <div class="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
      <div>
        <h1 class="text-base font-black text-slate-900">Creation formation/cours</h1>
        <p class="text-xs text-slate-500">Etape 1/3 · infos + apercu temps reel</p>
      </div>
      <div class="flex items-center gap-2">
        <button (click)="saveDraft(false)" class="px-3 py-2 text-xs rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50">Enregistrer brouillon</button>
        <button (click)="continueModules()" class="px-3 py-2 text-xs rounded-lg bg-blue-600 text-white hover:bg-blue-700">Continuer</button>
      </div>
    </div>
  </header>

  <main class="max-w-6xl mx-auto px-4 py-6 grid grid-cols-1 xl:grid-cols-2 gap-4">
    <form [formGroup]="form" class="bg-white border border-slate-100 rounded-xl p-5 space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="text-xs font-semibold text-slate-600">Type</label>
          <select formControlName="kind" (change)="onKindChanged()" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm">
            <option value="FORMATION">Formation</option>
            <option value="COURS">Cours</option>
          </select>
        </div>
        <div>
          <label class="text-xs font-semibold text-slate-600">Niveau</label>
          <select formControlName="level" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm">
            <option value="DEBUTANT">Debutant</option>
            <option value="INTERMEDIAIRE">Intermediaire</option>
            <option value="AVANCE">Avance</option>
          </select>
        </div>
      </div>

      <div>
        <label class="text-xs font-semibold text-slate-600">Titre</label>
        <input formControlName="title"
               maxlength="200"
               [class.border-red-500]="form.controls.title.invalid && form.controls.title.touched"
               class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" placeholder="Titre">
        @if (form.controls.title.invalid && (form.controls.title.dirty || form.controls.title.touched)) {
          <p class="text-[11px] text-red-500 mt-1">
            @if (form.controls.title.errors?.['required']) { Le titre est requis. }
            @if (form.controls.title.errors?.['minlength']) { Le titre doit faire au moins 5 caractères. }
          </p>
        }
      </div>

      <div>
        <label class="text-xs font-semibold text-slate-600">Description</label>
        <textarea rows="4" formControlName="description"
                  maxlength="500"
                  [class.border-red-500]="form.controls.description.invalid && form.controls.description.touched"
                  class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" placeholder="Description"></textarea>
        @if (form.controls.description.invalid && (form.controls.description.dirty || form.controls.description.touched)) {
          <p class="text-[11px] text-red-500 mt-1">
            @if (form.controls.description.errors?.['required']) { La description est requise. }
            @if (form.controls.description.errors?.['minlength']) { La description doit faire au moins 10 caractères. }
          </p>
        }
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="text-xs font-semibold text-slate-600">Prix (FCFA)</label>
          <input type="number" min="0" formControlName="priceFcfa"
                 [class.border-red-500]="form.controls.priceFcfa.invalid && form.controls.priceFcfa.touched"
                 class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm">
          @if (form.controls.priceFcfa.invalid && (form.controls.priceFcfa.dirty || form.controls.priceFcfa.touched)) {
            <p class="text-[11px] text-red-500 mt-1">
              @if (form.controls.priceFcfa.errors?.['required']) { Le prix est requis. }
              @if (form.controls.priceFcfa.errors?.['min']) { Le prix ne peut pas être négatif. }
            </p>
          }
        </div>
        @if (form.value.kind === 'FORMATION') {
          <div>
            <label class="text-xs font-semibold text-slate-600">Pourcentage gratuit ({{ form.value.freePercent }}%)</label>
            <input type="range" min="5" max="90" step="5" formControlName="freePercent" class="mt-2 w-full">
          </div>
        } @else {
          <div class="text-xs text-slate-500 bg-emerald-50 border border-emerald-200 rounded-lg px-3 py-2 mt-6">
            Type cours: 100% gratuit, pas de pourcentage payant.
          </div>
        }
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="text-xs font-semibold text-slate-600">Banniere URL</label>
          <input formControlName="bannerUrl" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm" placeholder="https://...">
        </div>
        <div>
          <label class="text-xs font-semibold text-slate-600">Ou upload banniere</label>
          <input type="file" accept="image/*" (change)="onBannerUpload($event)" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm">
          @if (form.value.bannerFileName) { <p class="text-[11px] text-slate-500 mt-1">{{ form.value.bannerFileName }}</p> }
        </div>
      </div>

      <div class="flex items-center justify-between pt-2">
        <span class="text-xs text-slate-500">Brouillon persistant (reprise apres fermeture)</span>
        <div class="flex gap-2">
          <button type="button" (click)="createRemote()" [disabled]="creating()" class="px-3 py-2 text-xs rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-60">
            {{ creating() ? 'Creation...' : hasRemoteId() ? 'Mettre a jour sur l\'API' : 'Creer brouillon API' }}
          </button>
          @if (hasRemoteId()) {
            <button type="button" (click)="continueModules()" class="px-3 py-2 text-xs rounded-lg bg-blue-600 text-white hover:bg-blue-700">
              Continuer (Etape 2)
            </button>
          }
        </div>
      </div>
    </form>

    <section class="bg-white border border-slate-100 rounded-xl p-5">
      <p class="text-sm font-bold text-slate-900 mb-3">Apercu public en temps reel</p>
      <article class="overflow-hidden rounded-xl border border-slate-200 mb-4">
        <img [src]="bannerPreview()" class="w-full h-44 object-cover" alt="banniere">
        <div class="p-4">
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-slate-900">{{ form.value.title || 'Titre de la formation' }}</h3>
            <span class="text-[10px] px-2 py-1 rounded-full bg-blue-50 text-blue-700">{{ form.value.level }}</span>
          </div>
          <p class="text-sm text-slate-600 mt-2 line-clamp-2">{{ form.value.description || 'Description de presentation...' }}</p>
          <div class="mt-3 flex items-center justify-between">
            <span class="font-black text-slate-900">{{ (form.value.priceFcfa || 0).toLocaleString('fr-FR') }} FCFA</span>
            <span class="text-xs text-slate-500">{{ form.value.kind === 'COURS' ? 'Gratuit' : (form.value.freePercent + '% gratuit') }}</span>
          </div>
        </div>
      </article>

      <article class="rounded-xl border border-slate-200 p-4">
        <p class="text-xs text-slate-400 mb-1">Vue detail formation</p>
        <h4 class="font-black text-slate-900">{{ form.value.title || 'Titre detail' }}</h4>
        <p class="text-sm text-slate-600 mt-2 whitespace-pre-wrap">{{ form.value.description || 'Description detail complete...' }}</p>
      </article>
    </section>
  </main>
</div>
  `,
})
export class CourseSetupComponent implements OnInit {
  readonly #route = inject(ActivatedRoute);
  readonly #router = inject(Router);
  readonly #fb = inject(FormBuilder);
  readonly #draftSvc = inject(CourseBuilderDraftService);
  readonly #adminSvc = inject(AdminService);
  readonly #toast = inject(ToastService);

  readonly creating = signal(false);
  readonly courseId = signal('');
  readonly bannerPreview = computed(() => this.form.value.bannerUrl || '/hero.png');
  readonly draft = computed(() => this.#draftSvc.courses()[this.courseId()]);
  readonly hasRemoteId = computed(() => !!this.draft()?.remoteId);

  readonly form = this.#fb.nonNullable.group({
    kind: ['FORMATION' as 'FORMATION' | 'COURS', Validators.required],
    title: ['', [Validators.required, Validators.minLength(5)]],
    description: ['', [Validators.required, Validators.minLength(10)]],
    level: ['DEBUTANT' as 'DEBUTANT' | 'INTERMEDIAIRE' | 'AVANCE', Validators.required],
    priceFcfa: [25000, [Validators.required, Validators.min(0)]],
    freePercent: [30, [Validators.required, Validators.min(5), Validators.max(90)]],
    bannerUrl: [''],
    bannerFileName: [''],
  });

  ngOnInit(): void {
    const routeId = this.#route.snapshot.paramMap.get('id') || undefined;
    const draft = this.#draftSvc.getOrCreate(routeId);
    this.courseId.set(draft.id);
    this.form.patchValue({
      kind: draft.kind, title: draft.title, description: draft.description, level: draft.level,
      priceFcfa: draft.priceFcfa, freePercent: draft.freePercent, bannerUrl: draft.bannerUrl, bannerFileName: draft.bannerFileName,
    });
    if (draft.kind === 'COURS') {
      this.form.controls.priceFcfa.disable();
      this.form.controls.freePercent.disable();
    } else {
      this.form.controls.priceFcfa.enable();
      this.form.controls.freePercent.enable();
    }
  }

  onKindChanged(): void {
    if (this.form.value.kind === 'COURS') {
      this.form.patchValue({ priceFcfa: 0, freePercent: 100 });
      this.form.controls.priceFcfa.disable();
      this.form.controls.freePercent.disable();
    } else {
      this.form.controls.priceFcfa.enable();
      this.form.controls.freePercent.enable();
    }
  }

  onBannerUpload(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    this.form.patchValue({ bannerFileName: file.name, bannerUrl: `/uploads/${file.name}` });
    this.saveDraft(false);
  }

  saveDraft(showToast = true): void {
    const raw = this.form.getRawValue();
    this.#draftSvc.patch(this.courseId(), {
      kind: raw.kind, title: raw.title, description: raw.description, level: raw.level, priceFcfa: raw.priceFcfa,
      freePercent: raw.kind === 'COURS' ? 100 : raw.freePercent, bannerUrl: raw.bannerUrl, bannerFileName: raw.bannerFileName,
    });
    if (showToast) this.#toast.success('Brouillon enregistre', 'Reprise possible.');
  }

  continueModules(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.#toast.error('Formulaire invalide', 'Veuillez remplir correctement les champs requis avant de continuer.');
      return;
    }
    this.saveDraft(false);
    this.#router.navigate(['/instructor/cours', this.courseId(), 'modules']);
  }

  createRemote(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.#toast.error('Formulaire invalide', 'Veuillez remplir correctement les champs requis.');
      return;
    }
    this.creating.set(true);
    const v = this.form.getRawValue();
    this.#adminSvc.creerCours({
      titre: v.title,
      description: v.description,
      niveau: v.level,
      prixFcfa: v.priceFcfa,
      seuilPaiement: v.kind === 'COURS' ? 1 : (v.freePercent / 100),
    }).subscribe({
      next: r => {
        this.creating.set(false);
        const remoteId = typeof r.data === 'string' ? r.data : r.data?.id;
        if (remoteId) {
          this.#draftSvc.patch(this.courseId(), { remoteId });
          this.#toast.success('Brouillon API cree', 'Redirection vers l\'etape 2...');
          this.#router.navigate(['/instructor/cours', this.courseId(), 'modules']);
        }
      },
      error: () => this.creating.set(false),
    });
  }
}

