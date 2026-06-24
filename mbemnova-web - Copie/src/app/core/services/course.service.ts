import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, CoursResponse, CoursDetailResponse, AvisCoursResponse, LaissserAvisRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class CourseService {
  readonly #api = inject(ApiService);

  // GET /api/v1/cours
  getAll(p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<CoursResponse>>> {
    return this.#api.getPage<CoursResponse>('/cours', p);
  }
  // GET /api/v1/cours/{coursId}
  getById(id: string): Observable<ApiResponse<CoursDetailResponse>> {
    return this.#api.get<CoursDetailResponse>(`/cours/${id}`);
  }
  // GET /api/v1/cours/slug/{slug}
  getBySlug(slug: string): Observable<ApiResponse<CoursDetailResponse>> {
    return this.#api.get<CoursDetailResponse>(`/cours/slug/${slug}`);
  }
  // GET /api/v1/cours/{coursId}/avis  (S4)
  getAvis(coursId: string): Observable<ApiResponse<AvisCoursResponse[]>> {
    return this.#api.get<AvisCoursResponse[]>(`/cours/${coursId}/avis`);
  }
  // POST /api/v1/cours/{coursId}/avis  (S4)
  laisserAvis(coursId: string, req: LaissserAvisRequest): Observable<ApiResponse<string>> {
    return this.#api.post<string>(`/cours/${coursId}/avis`, req);
  }
  // POST /api/v1/cours/{coursId}/liste-attente  (S4)
  rejoindreListeAttente(coursId: string, sessionId?: string): Observable<ApiResponse<null>> {
    const params = sessionId ? `?sessionId=${sessionId}` : '';
    return this.#api.post<null>(`/cours/${coursId}/liste-attente${params}`, {});
  }
}
