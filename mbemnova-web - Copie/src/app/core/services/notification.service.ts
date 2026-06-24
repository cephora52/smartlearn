import { Injectable, inject, signal, computed } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, NotificationResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  readonly #api = inject(ApiService);
  readonly unreadCount = signal(0);
  readonly hasUnread   = computed(() => this.unreadCount() > 0);

  // GET /api/v1/notifications
  getAll(): Observable<ApiResponse<PageResponse<NotificationResponse>>> { return this.#api.getPage<NotificationResponse>('/notifications'); }
  // GET /api/v1/notifications/unread
  getUnreadCount(): Observable<ApiResponse<{count:number}>> { return this.#api.get<{count:number}>('/notifications/unread'); }
  // PATCH /api/v1/notifications/read-all
  markAllRead(): Observable<ApiResponse<null>> { return this.#api.patch<null>('/notifications/read-all', {}); }
}
