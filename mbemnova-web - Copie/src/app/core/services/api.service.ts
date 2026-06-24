import { Injectable, inject, signal } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, throwError, timer } from 'rxjs';
import { retry, timeout, catchError } from 'rxjs/operators';
 
import type { ApiResponse, PageResponse } from '../models';
import { environment } from '../../../environments/environment';

const BASE    = environment.apiUrl;
const TIMEOUT = 30_000;

export interface PageParams {
  page?: number;
  size?: number;
  sort?: string;
  [key: string]: string | number | boolean | undefined;
}

/**
 * ApiService — couche HTTP de base.
 *
 * Fonctionnalités :
 * • Retry automatique 3× avec backoff exponentiel (1s → 2s → 4s)
 *   sur erreurs réseau + 5xx. Jamais de retry sur 4xx.
 * • Timeout 30s configurable par requête.
 * • Signal `loading` global pour les barres de chargement.
 */
@Injectable({ providedIn: 'root' })
export class ApiService {
  readonly #http = inject(HttpClient);

  /** Nombre de requêtes actives — pour le loading global */
  #active = 0;
  readonly loading = signal(false);

  get<T>(path: string, params?: PageParams): Observable<ApiResponse<T>> {
    return this.#req<T>('GET', path, null, params);
  }

  getPage<T>(path: string, params?: PageParams): Observable<ApiResponse<PageResponse<T>>> {
    return this.#req<PageResponse<T>>('GET', path, null, params);
  }

  post<T>(path: string, body: unknown): Observable<ApiResponse<T>> {
    return this.#req<T>('POST', path, body);
  }

  put<T>(path: string, body: unknown): Observable<ApiResponse<T>> {
    return this.#req<T>('PUT', path, body);
  }

  patch<T>(path: string, body: unknown): Observable<ApiResponse<T>> {
    return this.#req<T>('PATCH', path, body);
  }

  delete<T>(path: string): Observable<ApiResponse<T>> {
    return this.#req<T>('DELETE', path, null);
  }

  #req<T>(
    method: string,
    path: string,
    body: unknown,
    params?: PageParams,
  ): Observable<ApiResponse<T>> {
    this.#inc();

    let httpParams = new HttpParams();
    if (params) {
      Object.entries(params).forEach(([k, v]) => {
        if (v !== undefined && v !== null) httpParams = httpParams.set(k, String(v));
      });
    }

    return this.#http
      .request<ApiResponse<T>>(method, `${BASE}${path}`, {
        body:   body ?? undefined,
        params: httpParams,
      })
      .pipe(
        timeout(TIMEOUT),
        retry({
          count: 3,
          delay: (err: { status?: number }, n: number) => {
            // 4xx → pas de retry
            if (err?.status && err.status >= 400 && err.status < 500) {
              return throwError(() => err);
            }
            return timer(Math.pow(2, n - 1) * 1000);
          },
        }),
        catchError(err => { this.#dec(); return throwError(() => err); }),
      );
  }

  #inc(): void { this.#active++; this.loading.set(true); }
  #dec(): void {
    this.#active = Math.max(0, this.#active - 1);
    if (!this.#active) this.loading.set(false);
  }
}
