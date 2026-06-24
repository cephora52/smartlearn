import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { RouterLink, RouterModule } from '@angular/router';



export interface Stat {
  value: string;
  label: string;
}
 
export interface Avatar {
  initial: string;
  color: string;
}


@Component({
  selector: 'app-hero',
 imports: [CommonModule, RouterModule],
  templateUrl: './hero.html',
  styleUrl: './hero.css',
})



 
export class Hero {

    imageLoading = true;

 // ── Stats — can be fetched from API ────────────────────────────────────────
  // Inject a StatsService here and call it in ngOnInit if data comes from API
stats = [
  { value: "+200", label: "accèdent à une opportunité en < 6 mois" },
  // { value: "500+", label: "apprenants accompagnés par des mentors" },
  { value: "3-8 mois", label: "pour devenir opérationnel" },
  { value: "Flexible", label: "présentiel + en ligne selon tes disponibilités" }
];
 
  // ── Avatar stack for social proof badge ────────────────────────────────────
  readonly avatars: Avatar[] = [
    { initial: 'J', color: 'bg-indigo-500' },
    { initial: 'D', color: 'bg-emerald-500' },
    { initial: 'S', color: 'bg-violet-500' },
    { initial: 'P', color: 'bg-amber-500' },
  ];
 
  constructor(private cdr: ChangeDetectorRef) {}
 
  ngOnInit(): void {
    // Example: fetch stats from API
    // this.statsService.getHeroStats().subscribe(data => {
    //   this.stats = data;
    //   this.cdr.markForCheck();
    // });
  }
 
  onImageLoad(): void {
    this.imageLoading = false;
    this.cdr.markForCheck();
  }
 
  onImageError(): void {
    // Image failed to load — hide skeleton, show nothing (or a fallback)
    this.imageLoading = false;
    this.cdr.markForCheck();
  }
}
 