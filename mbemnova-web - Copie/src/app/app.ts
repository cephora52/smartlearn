import {
  ChangeDetectionStrategy, Component, inject,
  computed, signal, OnInit, OnDestroy, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterOutlet, RouterLink, Router, NavigationEnd } from '@angular/router';
import { Subscription } from 'rxjs';
import { AuthService } from './core/services/auth.service';
import { ToastService, Toast } from './core/services/toast.service';
import { ApiService } from './core/services/api.service';
import { NotificationService } from './core/services/notification.service';
import { MockSwitcherComponent } from './shared/components/mock-switcher/mock-switcher.component';
import { Header } from './shared/components/header/header';
import { LearnerHeaderComponent } from './shared/components/role-headers/learner-header.component';
import { InstructorHeaderComponent } from './shared/components/role-headers/instructor-header.component';
import { AdminHeaderComponent } from './shared/components/role-headers/admin-header.component';

@Component({
  selector: 'app-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    RouterOutlet,
    RouterLink,
    MockSwitcherComponent,
    Header,
    LearnerHeaderComponent,
    InstructorHeaderComponent,
    AdminHeaderComponent,
  ],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit, OnDestroy {
  readonly auth = inject(AuthService);
  readonly toastSvc = inject(ToastService);
  readonly api = inject(ApiService);
  readonly notifSvc = inject(NotificationService);
  readonly router = inject(Router);
  readonly #plat = inject(PLATFORM_ID);

  readonly isAuth = this.auth.isAuthenticated;
  readonly user = this.auth.currentUser;
  readonly role = this.auth.userRole;
  readonly isAdmin = this.auth.isAdmin;
  readonly loading = this.api.loading;
  readonly toasts = this.toastSvc.toasts;
  readonly hasUnread = this.notifSvc.hasUnread;
  readonly menuOpen = signal(false);
  readonly userMenuOpen = signal(false);
  readonly currentUrl = signal(this.router.url);

  readonly isPublicRoute = computed(() => {
    const url = this.currentUrl();
    return !url.startsWith('/app') && !url.startsWith('/instructor') && !url.startsWith('/admin');
  });

  readonly activeHeader = computed<'public' | 'learner' | 'instructor' | 'admin'>(() => {
    if (this.isPublicRoute()) return 'public';
    const r = this.role();
    if (r === 'APPRENANT') return 'learner';
    if (r === 'FORMATEUR') return 'instructor';
    if (r === 'ADMIN' || r === 'SUPER_ADMIN') return 'admin';
    return 'public';
  });

  #routerSub?: Subscription;

  ngOnInit(): void {
    this.#routerSub = this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        this.currentUrl.set(event.urlAfterRedirects);
      }
    });

    if (isPlatformBrowser(this.#plat)) {
      window.addEventListener('mn:error', (e: Event) => {
        this.toastSvc.error(((e as CustomEvent).detail as { message: string }).message);
      });
    }
  }

  ngOnDestroy(): void {
    this.#routerSub?.unsubscribe();
  }

  logout(): void { this.menuOpen.set(false); this.userMenuOpen.set(false); this.auth.logout(); }
  closeAll(): void { this.menuOpen.set(false); this.userMenuOpen.set(false); }
  toggleMenu(): void { this.menuOpen.update(v => !v); this.userMenuOpen.set(false); }
  toggleUserMenu(): void { this.userMenuOpen.update(v => !v); this.menuOpen.set(false); }

  toastBg(t: Toast['type']): string { return { success: 'bg-green-50 border-green-200', error: 'bg-red-50 border-red-200', warning: 'bg-amber-50 border-amber-200', info: 'bg-blue-50 border-blue-200' }[t]; }
  toastIcon(t: Toast['type']): string { return { success: '✓', error: '✕', warning: '⚠', info: 'ℹ' }[t]; }
  toastIconBg(t: Toast['type']): string { return { success: 'bg-green-100 text-green-700', error: 'bg-red-100 text-red-700', warning: 'bg-amber-100 text-amber-700', info: 'bg-blue-100 text-blue-700' }[t]; }
  toastText(t: Toast['type']): string { return { success: 'text-green-900', error: 'text-red-900', warning: 'text-amber-900', info: 'text-blue-900' }[t]; }
}
