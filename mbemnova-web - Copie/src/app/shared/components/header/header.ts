import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, HostListener, OnDestroy, OnInit, inject, computed } from '@angular/core';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';


// ── Data interfaces ──────────────────────────────────────────────────────────
 
export interface BootcampCategory {
  id: string;
  label: string;
  count: string;
}
 
export interface Bootcamp {
  categoryId: string;
  title: string;
  duration: string;
  price: string;
}
 
export interface NavItem {
  icon: string;
  label: string;
  desc: string;
}
 
export interface Resource {
  icon: string;
  tag: string;
  label: string;
  desc: string;
}

@Component({
  selector: 'app-header',
  imports: [CommonModule, RouterModule],
  templateUrl: './header.html',
  styleUrl: './header.css',
})
export class Header implements OnInit, OnDestroy {
  readonly #auth = inject(AuthService);
  readonly isAuth = this.#auth.isAuthenticated;
  readonly role = this.#auth.userRole;
  readonly user = this.#auth.currentUser;
  readonly dashboardLink = computed(() => {
    const r = this.role();
    if (r === 'APPRENANT') return '/app';
    if (r === 'FORMATEUR') return '/instructor';
    if (r === 'ADMIN' || r === 'SUPER_ADMIN') return '/admin';
    return '/auth/connexion';
  });
  readonly dashboardLabel = computed(() => {
    const r = this.role();
    if (r === 'APPRENANT') return 'Mon dashboard';
    if (r === 'FORMATEUR') return 'Dashboard formateur';
    if (r === 'ADMIN' || r === 'SUPER_ADMIN') return 'Dashboard admin';
    return 'Se connecter';
  });

  // ── State ──
  isScrolled = false;
  activeDropdown: string | null = null;
  mobileOpen = false;
  mobileSection: string | null = null;
 
  /** Tracks which bootcamp category is hovered in the mega-menu */
  activeCat = 'marketing';
 
  private closeTimer: ReturnType<typeof setTimeout> | null = null;
 
  // ── Data ──
 
  readonly bootcampCategories: BootcampCategory[] = [
    { id: 'bureautique', label: 'Bureautique & Productivité', count: '1' },
    { id: 'data',        label: 'Data et IA',                 count: '4' },
    { id: 'design',      label: 'Design Graphique et UI/UX',  count: '2' },
    { id: 'dev',         label: 'Développement Web et Mobile', count: '3' },
    { id: 'marketing',   label: 'Marketing et Communication', count: '4' },
    { id: 'reseaux',     label: 'Réseaux Système et Sécurité', count: '2' },
  ];

  getCategoryId(catId: string): string {
    const ids: Record<string, string> = {
      'bureautique': '11111111-1111-1111-1111-111111111111',
      'data': '22222222-2222-2222-2222-222222222222',
      'design': '33333333-3333-3333-3333-333333333333',
      'dev': '44444444-4444-4444-4444-444444444444',
      'marketing': '55555555-5555-5555-5555-555555555555',
      'reseaux': '66666666-6666-6666-6666-666666666666',
    };
    return ids[catId] ?? '';
  }

  forceClose(): void {
    this.activeDropdown = null;
    this.mobileOpen = false;
  }
 
  readonly bootcamps: Bootcamp[] = [
    // Marketing
    { categoryId: 'marketing', title: 'Création de Contenus & Publicité sur les Réseaux Sociaux', duration: '6 semaines',  price: '79 000 F CFA' },
    { categoryId: 'marketing', title: 'Introduction au Marketing Digital',                         duration: '6 semaines',  price: '79 000 F CFA' },
    { categoryId: 'marketing', title: 'Social Media Manager (Gestion des Réseaux Sociaux)',        duration: '12 semaines', price: '149 000 F CFA' },
    { categoryId: 'marketing', title: 'Responsable Marketing Digital',                             duration: '20 semaines', price: '399 000 F CFA' },
    // Data
    { categoryId: 'data', title: 'Python pour la Data Science',      duration: '8 semaines',  price: '99 000 F CFA' },
    { categoryId: 'data', title: 'Machine Learning Fondamentaux',     duration: '10 semaines', price: '149 000 F CFA' },
    { categoryId: 'data', title: 'Power BI & Visualisation',          duration: '6 semaines',  price: '79 000 F CFA' },
    { categoryId: 'data', title: 'IA Générative & ChatGPT en pratique', duration: '4 semaines', price: '59 000 F CFA' },
    // Dev
    { categoryId: 'dev', title: 'Développeur Web Full Stack',      duration: '20 semaines', price: '399 000 F CFA' },
    { categoryId: 'dev', title: 'Développement Mobile (Flutter)',  duration: '16 semaines', price: '299 000 F CFA' },
    { categoryId: 'dev', title: 'React JS Avancé',                 duration: '12 semaines', price: '199 000 F CFA' },
    // Design
    { categoryId: 'design', title: 'UI/UX Design avec Figma', duration: '10 semaines', price: '149 000 F CFA' },
    { categoryId: 'design', title: 'Identité Visuelle & Branding', duration: '8 semaines', price: '99 000 F CFA' },
    // Bureautique
    { categoryId: 'bureautique', title: 'Pack Office & Productivité', duration: '4 semaines', price: '49 000 F CFA' },
    // Réseaux
    { categoryId: 'reseaux', title: 'Cybersécurité Fondamentaux', duration: '10 semaines', price: '149 000 F CFA' },
    { categoryId: 'reseaux', title: 'Administration Réseaux',     duration: '12 semaines', price: '199 000 F CFA' },
  ];
 
  readonly freeCourses: NavItem[] = [
    { icon: '💻', label: 'HTML & CSS',         desc: 'Construire des pages web' },
    { icon: '🐍', label: 'Python Bases',        desc: 'Premiers pas en programmation' },
    { icon: '📊', label: 'Excel Essentiel',     desc: 'Maîtriser les tableurs' },
    { icon: '🎨', label: 'Canva Design',        desc: 'Créer des visuels pro' },
    { icon: '📱', label: 'Réseaux Sociaux',     desc: 'Stratégie & contenu' },
    { icon: '🤖', label: 'ChatGPT & IA',        desc: 'Utiliser l\'IA au quotidien' },
  ];
 
  readonly resources: Resource[] = [
    { icon: '🎙️', tag: 'Masterclass',  label: 'Webinaire',  desc: 'Rejoignez nos séries de masterclass avec des experts' },
    { icon: '✍️', tag: 'Articles',     label: 'Blog',       desc: 'Restez informé sur les tendances du numérique' },
    { icon: '📖', tag: 'Revues',       label: 'Ebook',      desc: 'Recevez nos revues mensuelles sur le Digital' },
    { icon: '🗂️', tag: 'Ressources',   label: 'Nos Outils', desc: 'Apprenez plus avec nos ressources gratuites' },
  ];
 
  constructor(private cdr: ChangeDetectorRef) {}
 
  ngOnInit(): void {}
  ngOnDestroy(): void {
    if (this.closeTimer) clearTimeout(this.closeTimer);
  }
 
  // ── Scroll detection ──────────────────────────────────────────────────────
 
  @HostListener('window:scroll', [])
  onWindowScroll(): void {
    const scrolled = window.scrollY > 20;
    if (scrolled !== this.isScrolled) {
      this.isScrolled = scrolled;
      this.cdr.markForCheck();
    }
  }
 
  // ── Desktop dropdown logic ────────────────────────────────────────────────
 
  openDropdown(name: string): void {
    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }
    if (this.activeDropdown !== name) {
      this.activeDropdown = name;
      // Reset to first category of bootcamps on open
      if (name === 'bootcamps') this.activeCat = 'marketing';
      this.cdr.markForCheck();
    }
  }
 
  closeDropdown(): void {
    // Small delay so cursor can travel to dropdown without it closing
    this.closeTimer = setTimeout(() => {
      this.activeDropdown = null;
      this.cdr.markForCheck();
    }, 150);
  }
 
  // ── Mobile menu logic ─────────────────────────────────────────────────────
 
  toggleMobileMenu(): void {
    this.mobileOpen = !this.mobileOpen;
    if (!this.mobileOpen) this.mobileSection = null;
    this.cdr.markForCheck();
  }
 
  toggleMobileSection(section: string): void {
    this.mobileSection = this.mobileSection === section ? null : section;
    this.cdr.markForCheck();
  }
 
  // ── Helpers ───────────────────────────────────────────────────────────────
 
  getActiveBootcamps(): Bootcamp[] {
    return this.bootcamps.filter(b => b.categoryId === this.activeCat);
  }
 
  getActiveCatLabel(): string {
    return this.bootcampCategories.find(c => c.id === this.activeCat)?.label ?? '';
  }

  logout(): void {
    this.#auth.logout();
  }
}
