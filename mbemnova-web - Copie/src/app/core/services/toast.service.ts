import { Injectable, signal } from '@angular/core';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

export interface Toast {
  id:       string;
  type:     ToastType;
  title:    string;
  message?: string;
  duration: number;
}

/**
 * ToastService — notifications non-intrusives.
 * Max 3 toasts simultanés. Auto-dismiss configurable.
 * Compatible SSR (signal côté serveur retourne []).
 */
@Injectable({ providedIn: 'root' })
export class ToastService {
  readonly toasts = signal<Toast[]>([]);

  show(type: ToastType, title: string, message?: string, duration = 4000): void {
    const id = Math.random().toString(36).slice(2, 9);
    this.toasts.update(list => [...list.slice(-2), { id, type, title, message, duration }]);
    if (duration > 0) setTimeout(() => this.dismiss(id), duration);
  }

  success(title: string, message?: string): void { this.show('success', title, message); }
  error(title: string, message?: string):   void { this.show('error', title, message, 6000); }
  warning(title: string, message?: string): void { this.show('warning', title, message); }
  info(title: string, message?: string):    void { this.show('info', title, message); }

  dismiss(id: string): void { this.toasts.update(l => l.filter(t => t.id !== id)); }
}
