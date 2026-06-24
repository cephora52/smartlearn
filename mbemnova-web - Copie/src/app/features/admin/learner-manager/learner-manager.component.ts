import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

/** Placeholder — sera remplacé dans le script correspondant */
@Component({
  selector: 'app-learner-mgr',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="container py-16 text-center">
  <div class="text-5xl mb-4">👥</div>
  <h1 class="h2 mb-2">Apprenants</h1>
  <p class="text-slate-500 mb-6">Cette page est en cours de développement.</p>
  <a routerLink="/" class="btn-secondary">Retour à l'accueil</a>
</div>`
})
export class LearnerManagerComponent {}
