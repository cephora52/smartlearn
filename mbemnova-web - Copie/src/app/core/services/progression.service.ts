import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, ProgressionResponse, TerminerLeconRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class ProgressionService {
  readonly #api = inject(ApiService);
  // POST /api/v1/progression/cours/{coursId}/commencer  (S5)
  commencer(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/commencer`, {});
  }
  // POST /api/v1/progression/cours/{coursId}/terminer-lecon  (S6)
  terminerLecon(coursId: string, req: TerminerLeconRequest): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/terminer-lecon`, req);
  }
  // GET /api/v1/progression
  getAll(): Observable<ApiResponse<PageResponse<ProgressionResponse>>> {
    return this.#api.getPage<ProgressionResponse>('/progression');
  }
  // GET /api/v1/progression/cours/{coursId}
  getByCours(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.get<ProgressionResponse>(`/progression/cours/${coursId}`);
  }

  // POST /api/v1/progression/cours/{coursId}/final-quiz-xp
  validerQuizFinalXp(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/final-quiz-xp`, {});
  }
}
