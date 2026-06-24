import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-appel-action',
 imports: [CommonModule, RouterModule],
  templateUrl: './appel-action.html',
  styleUrl: './appel-action.css',
})
export class AppelAction {


    // Stats — peut être branché sur un service API
  readonly stats = [
    { value: '247+',   label: 'apprenants actifs en Afrique Centrale' },
    { value: '2 000+', label: 'diplômés depuis notre lancement' },
    { value: '4.1/5',  label: 'note moyenne sur Trustpilot' },
    { value: '87%',    label: 'trouvent un emploi en 6 mois' },
  ];

}
