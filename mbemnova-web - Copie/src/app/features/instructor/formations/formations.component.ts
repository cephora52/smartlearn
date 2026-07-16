import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AdminService } from '../../../core/services/admin.service';
import { AuthService } from '../../../core/services/auth.service';
import { ToastService } from '../../../core/services/toast.service';
import type { CoursResponse } from '../../../core/models';

@Component({
  selector: 'app-formations',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './formations.html',
})
export class FormationsComponent implements OnInit {
  readonly #adminSvc = inject(AdminService);
  readonly #auth = inject(AuthService);
  readonly #toast = inject(ToastService);

  readonly cours = signal<CoursResponse[]>([]);
  readonly isLoading = signal(true);

  // Filters state
  readonly selectedDomaine = signal<string>('');
  readonly selectedNiveau = signal<string>('');
  readonly selectedStatut = signal<string>('');
  readonly searchTerm = signal<string>('');

  readonly domains = [
    { value: '', label: 'Tous les domaines' },
    { value: '11111111-1111-1111-1111-111111111111', label: 'Bureautique & Productivité' },
    { value: '22222222-2222-2222-2222-222222222222', label: 'Data et IA' },
    { value: '33333333-3333-3333-3333-333333333333', label: 'Design Graphique et UI/UX' },
    { value: '44444444-4444-4444-4444-444444444444', label: 'Développement Web et Mobile' },
    { value: '55555555-5555-5555-5555-555555555555', label: 'Marketing et Communication' },
    { value: '66666666-6666-6666-6666-666666666666', label: 'Réseaux Système et Sécurité' }
  ];

  readonly niveaux = [
    { value: '', label: 'Tous les niveaux' },
    { value: 'DEBUTANT', label: 'Débutant' },
    { value: 'INTERMEDIAIRE', label: 'Intermédiaire' },
    { value: 'AVANCE', label: 'Avancé' }
  ];

  readonly statuts = [
    { value: '', label: 'Tous les statuts' },
    { value: 'PUBLIE', label: 'Publié' },
    { value: 'BROUILLON', label: 'Brouillon' }
  ];

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.isLoading.set(true);
    this.#adminSvc.getMesCours({
      domaine: this.selectedDomaine() || undefined,
      niveau: this.selectedNiveau() || undefined,
      statut: this.selectedStatut() || undefined,
      q: this.searchTerm() || undefined
    }).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.cours.set(r.data);
        }
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  // ── Helpers ──
  levelBg(n: string): string {
    return { DEBUTANT: 'bg-emerald-50 text-emerald-700', INTERMEDIAIRE: 'bg-blue-50 text-blue-700', AVANCE: 'bg-violet-50 text-violet-700' }[n] ?? 'bg-slate-50 text-slate-700';
  }
  levelDot(n: string): string {
    return { DEBUTANT: 'bg-emerald-500', INTERMEDIAIRE: 'bg-blue-500', AVANCE: 'bg-violet-500' }[n] ?? 'bg-slate-400';
  }
  levelLabel(n: string): string {
    return { DEBUTANT: 'Débutant', INTERMEDIAIRE: 'Intermédiaire', AVANCE: 'Avancé' }[n] ?? n;
  }

  supprimerCours(c: CoursResponse): void {
    if (confirm("Êtes-vous sûr de vouloir supprimer cette formation ? Cette action est irréversible.")) {
      this.#adminSvc.supprimerCours(c.id).subscribe({
        next: () => {
          this.#toast.success("Succès", "La formation a été supprimée avec succès.");
          this.load();
        },
        error: (err) => {
          this.#toast.error("Erreur de suppression", err?.error?.message || "Une erreur est survenue.");
        }
      });
    }
  }
}
