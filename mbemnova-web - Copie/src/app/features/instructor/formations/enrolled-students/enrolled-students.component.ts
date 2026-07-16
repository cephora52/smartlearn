import { ChangeDetectionStrategy, Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { AdminService } from '../../../../core/services/admin.service';
import type { ApprenantInscritResponse } from '../../../../core/models';

@Component({
  selector: 'app-enrolled-students',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, RouterLink],
  templateUrl: './enrolled-students.html',
})
export class EnrolledStudentsComponent implements OnInit {
  readonly #adminSvc = inject(AdminService);
  readonly #route = inject(ActivatedRoute);

  readonly coursId = this.#route.snapshot.paramMap.get('id') ?? '';
  readonly apprenants = signal<ApprenantInscritResponse[]>([]);
  readonly isLoading = signal(true);
  readonly errorMsg = signal<string | null>(null);

  ngOnInit(): void {
    if (!this.coursId) {
      this.errorMsg.set('Identifiant du cours manquant.');
      this.isLoading.set(false);
      return;
    }
    this.load();
  }

  load(): void {
    this.isLoading.set(true);
    this.errorMsg.set(null);
    this.#adminSvc.getApprenantsInscrits(this.coursId).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.apprenants.set(r.data);
        } else {
          this.errorMsg.set('Impossible de charger les apprenants.');
        }
        this.isLoading.set(false);
      },
      error: (err) => {
        this.errorMsg.set(err?.error?.message || 'Une erreur est survenue lors du chargement des apprenants.');
        this.isLoading.set(false);
      }
    });
  }

  // Returns avatar initials
  getInitials(prenom: string, nom: string): string {
    const p = prenom ? prenom.charAt(0).toUpperCase() : '';
    const n = nom ? nom.charAt(0).toUpperCase() : '';
    return p + n;
  }
}
