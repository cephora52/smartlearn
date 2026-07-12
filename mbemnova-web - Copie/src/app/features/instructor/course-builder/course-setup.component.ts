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
  <header class="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
    <div class="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
      <div>
        <h1 class="text-base font-black text-slate-900">Création formation / cours</h1>
        <p class="text-xs text-slate-500">Étape 1/2 · Informations générales</p>
      </div>
      <div class="flex items-center gap-2">
        <button (click)="saveDraft(false)" class="px-3 py-2 text-xs rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors font-medium">Enregistrer brouillon</button>
        <button (click)="continueModules()" [disabled]="creating()" class="px-4 py-2 text-xs font-bold rounded-lg bg-blue-600 text-white hover:bg-blue-700 transition-colors shadow-sm">
          {{ creating() ? 'Sauvegarde...' : 'Continuer' }}
        </button>
      </div>
    </div>
  </header>

  <main class="max-w-6xl mx-auto px-4 py-6 grid grid-cols-1 xl:grid-cols-2 gap-6">
    <form [formGroup]="form" class="bg-white border border-slate-200 rounded-2xl p-6 space-y-5 shadow-sm">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="text-xs font-semibold text-slate-600">Type</label>
          <select formControlName="kind" (change)="onKindChanged()" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none bg-white">
            <option value="FORMATION">Formation</option>
            <option value="COURS">Cours</option>
          </select>
        </div>
        <div>
          <label class="text-xs font-semibold text-slate-600">Niveau</label>
          <select formControlName="level" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none bg-white">
            <option value="DEBUTANT">Débutant</option>
            <option value="INTERMEDIAIRE">Intermédiaire</option>
            <option value="AVANCE">Avancé</option>
          </select>
        </div>
      </div>

      <div>
        <label class="text-xs font-semibold text-slate-600">Domaine *</label>
        <select formControlName="category" class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none bg-white">
          <option *ngFor="let dom of domains" [value]="dom.value">{{ dom.label }}</option>
        </select>
      </div>

      <div>
        <label class="text-xs font-semibold text-slate-600">Titre</label>
        <input formControlName="title"
               maxlength="200"
               [class.border-red-500]="form.controls.title.invalid && form.controls.title.touched"
               class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none" placeholder="Ex: Apprendre TypeScript de zéro">
        @if (form.controls.title.invalid && (form.controls.title.dirty || form.controls.title.touched)) {
          <p class="text-[11px] text-red-500 mt-1">
            @if (form.controls.title.errors?.['required']) { Le titre est requis. }
          </p>
        }
      </div>

      <div>
        <label class="text-xs font-semibold text-slate-600">Description</label>
        <textarea rows="4" formControlName="description"
                  maxlength="500"
                  [class.border-red-500]="form.controls.description.invalid && form.controls.description.touched"
                  class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none" placeholder="Présentation rapide du cours..."></textarea>
        @if (form.controls.description.invalid && (form.controls.description.dirty || form.controls.description.touched)) {
          <p class="text-[11px] text-red-500 mt-1">
            @if (form.controls.description.errors?.['required']) { La description est requise. }
          </p>
        }
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="text-xs font-semibold text-slate-600">Prix (FCFA)</label>
          <input type="number" min="0" formControlName="priceFcfa"
                 [class.border-red-500]="form.controls.priceFcfa.invalid && form.controls.priceFcfa.touched"
                 class="mt-1 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none">
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
            <input type="range" min="0" max="100" step="10" formControlName="freePercent" class="mt-2 w-full accent-blue-600">
          </div>
        } @else {
          <div class="text-xs text-slate-500 bg-emerald-50 border border-emerald-200 rounded-lg px-3 py-2 mt-6">
            Type cours: 100% gratuit, pas de pourcentage payant.
          </div>
        }
      </div>

      <!-- Zone Upload Image visible immédiatement -->
      <div class="bg-slate-50 p-4 rounded-xl border border-slate-200">
        <label class="text-xs font-bold text-slate-700 block mb-1">Image de couverture du cours</label>
        <p class="text-[10px] text-slate-400 mb-3">Formats acceptés : JPG, JPEG, PNG, WEBP (max 10 Mo).</p>
        
        <div class="flex items-center gap-3">
          <input type="file" 
                 id="bannerFileInput"
                 accept="image/jpeg,image/png,image/webp" 
                 (change)="onBannerUpload($event)" 
                 class="hidden">
          <label for="bannerFileInput" 
                 class="px-4 py-2 bg-white border border-slate-300 rounded-lg text-xs text-slate-700 hover:bg-slate-50 cursor-pointer font-semibold shadow-sm transition-colors">
            Ajouter une image de couverture
          </label>
          @if (form.value.bannerFileName) { 
            <p class="text-[11px] text-emerald-600 font-bold truncate max-w-[200px]">✓ Image active : {{ form.value.bannerFileName }}</p> 
          } @else {
            <p class="text-[11px] text-slate-400">Aucune image sélectionnée</p>
          }
        </div>
      </div>

      <div class="flex items-center justify-between pt-4 border-t border-slate-100">
        <span class="text-xs text-slate-500 font-medium text-slate-400">Sauvegarde automatique</span>
        <button type="button" 
                (click)="continueModules()" 
                [disabled]="creating()" 
                class="px-5 py-2.5 text-xs font-bold rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:bg-slate-200 disabled:text-slate-400 disabled:cursor-not-allowed transition-colors shadow-sm">
          {{ creating() ? 'Sauvegarde...' : 'Continuer' }}
        </button>
      </div>
    </form>

    <section class="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
      <p class="text-sm font-bold text-slate-900 mb-1">Aperçu public en temps réel</p>
      <article class="overflow-hidden rounded-xl border border-slate-200 shadow-sm">
        <img [src]="bannerPreview()" class="w-full h-44 object-cover" alt="Bannière de couverture">
        <div class="p-4">
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-slate-900 truncate max-w-[240px]">{{ form.value.title || 'Titre de la formation' }}</h3>
            <span class="text-[10px] px-2 py-1 rounded-full bg-blue-50 text-blue-700 font-semibold">{{ form.value.level }}</span>
          </div>
          <p class="text-sm text-slate-600 mt-2 line-clamp-2">{{ form.value.description || 'Description de présentation...' }}</p>
          <div class="mt-3 flex items-center justify-between">
            <span class="font-black text-slate-900">{{ (form.value.priceFcfa || 0).toLocaleString('fr-FR') }} FCFA</span>
            <span class="text-xs text-slate-500">{{ form.value.kind === 'COURS' ? 'Gratuit' : (form.value.freePercent + '% gratuit') }}</span>
          </div>
        </div>
      </article>

      <article class="rounded-xl border border-slate-200 p-4 bg-slate-50">
        <p class="text-[10px] text-slate-400 mb-1 font-bold">Vue détail formation</p>
        <h4 class="font-black text-slate-900">{{ form.value.title || 'Titre détail' }}</h4>
        <p class="text-sm text-slate-600 mt-2 whitespace-pre-wrap leading-relaxed">{{ form.value.description || 'Description détail complète...' }}</p>
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
  readonly draft = computed(() => this.#draftSvc.courses()[this.courseId()]);
  readonly hasRemoteId = computed(() => !!this.draft()?.remoteId);

  readonly selectedFile = signal<File | null>(null);
  readonly selectedFileUrl = signal<string | null>(null);

  readonly bannerPreview = computed(() => {
    if (this.selectedFileUrl()) return this.selectedFileUrl()!;
    return this.form.value.bannerUrl || '/hero.png';
  });

  readonly domains = [
    { value: '11111111-1111-1111-1111-111111111111', label: 'Bureautique & Productivité' },
    { value: '22222222-2222-2222-2222-222222222222', label: 'Data et IA' },
    { value: '33333333-3333-3333-3333-333333333333', label: 'Design Graphique et UI/UX' },
    { value: '44444444-4444-4444-4444-444444444444', label: 'Développement Web et Mobile' },
    { value: '55555555-5555-5555-5555-555555555555', label: 'Marketing et Communication' },
    { value: '66666666-6666-6666-6666-666666666666', label: 'Réseaux Système et Sécurité' }
  ];

  readonly form = this.#fb.nonNullable.group({
    kind: ['FORMATION' as 'FORMATION' | 'COURS', Validators.required],
    title: ['', Validators.required],
    description: ['', Validators.required],
    level: ['DEBUTANT' as 'DEBUTANT' | 'INTERMEDIAIRE' | 'AVANCE', Validators.required],
    category: ['44444444-4444-4444-4444-444444444444', Validators.required],
    priceFcfa: [25000, [Validators.required, Validators.min(0)]],
    freePercent: [30, [Validators.required, Validators.min(0), Validators.max(100)]],
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
      category: draft.category || '44444444-4444-4444-4444-444444444444',
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

    // Check extensions
    const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    const ext = file.name.split('.').pop()?.toLowerCase();
    if (!ext || !validExtensions.includes(ext)) {
      this.#toast.error('Format non valide', 'Seuls les formats JPG, JPEG, PNG et WEBP sont autorisés.');
      return;
    }

    this.selectedFile.set(file);
    const objectUrl = URL.createObjectURL(file);
    this.selectedFileUrl.set(objectUrl);

    this.form.patchValue({
      bannerFileName: file.name
    });
    this.saveDraft(false);
  }

  saveDraft(showToast = true): void {
    const raw = this.form.getRawValue();
    this.#draftSvc.patch(this.courseId(), {
      kind: raw.kind, title: raw.title, description: raw.description, level: raw.level, priceFcfa: raw.priceFcfa,
      freePercent: raw.kind === 'COURS' ? 100 : raw.freePercent, bannerUrl: raw.bannerUrl, bannerFileName: raw.bannerFileName,
      category: raw.category,
    });
    if (showToast) this.#toast.success('Brouillon enregistré', 'Reprise possible.');
  }

  continueModules(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.#toast.error('Formulaire invalide', 'Veuillez remplir correctement les champs requis avant de continuer.');
      return;
    }
    this.saveDraft(false);

    this.creating.set(true);
    const v = this.form.getRawValue();
    const payload = {
      titre: v.title,
      description: v.description,
      niveau: v.level,
      prixFcfa: v.priceFcfa,
      seuilPaiement: v.kind === 'COURS' ? 1 : (v.freePercent / 100),
      categorieId: v.category,
    };

    const remoteId = this.draft()?.remoteId;
    
    if (remoteId) {
      const fileToUpload = this.selectedFile();
      if (fileToUpload) {
        this.#adminSvc.uploadBanniere(remoteId, fileToUpload).subscribe({
          next: r => {
            this.creating.set(false);
            if (r.success && r.data) {
              const data = r.data as any;
              this.form.patchValue({
                bannerUrl: data.urlOriginal,
                bannerFileName: fileToUpload.name
              });
              this.saveDraft(false);
            }
            this.#router.navigate(['/instructor/cours', this.courseId(), 'modules']);
          },
          error: () => {
            this.creating.set(false);
            this.#toast.error('Erreur', 'Impossible d\'uploader l\'image de couverture.');
          }
        });
      } else {
        this.creating.set(false);
        this.#router.navigate(['/instructor/cours', this.courseId(), 'modules']);
      }
    } else {
      this.#adminSvc.creerCours(payload).subscribe({
        next: r => {
          const rId = typeof r.data === 'string' ? r.data : (r.data as any)?.id;
          if (rId) {
            this.#draftSvc.patch(this.courseId(), { remoteId: rId });
            
            const fileToUpload = this.selectedFile();
            if (fileToUpload) {
              this.#adminSvc.uploadBanniere(rId, fileToUpload).subscribe({
                next: uploadRes => {
                  this.creating.set(false);
                  if (uploadRes.success && uploadRes.data) {
                    const data = uploadRes.data as any;
                    this.form.patchValue({
                      bannerUrl: data.urlOriginal,
                      bannerFileName: fileToUpload.name
                    });
                    this.saveDraft(false);
                  }
                  this.#router.navigate(['/instructor/cours', this.courseId(), 'modules']);
                },
                error: () => {
                  this.creating.set(false);
                  this.#toast.error('Erreur', 'Impossible d\'uploader l\'image de couverture.');
                }
              });
            } else {
              this.creating.set(false);
              this.#router.navigate(['/instructor/cours', this.courseId(), 'modules']);
            }
          } else {
            this.creating.set(false);
            this.#toast.error('Erreur', 'Impossible de générer le brouillon sur le serveur.');
          }
        },
        error: err => {
          this.creating.set(false);
          const errMsg = err.error?.error?.details?.join(', ') || err.error?.message || 'Une erreur est survenue lors de la création du brouillon.';
          this.#toast.error('Erreur', errMsg);
        }
      });
    }
  }
}
