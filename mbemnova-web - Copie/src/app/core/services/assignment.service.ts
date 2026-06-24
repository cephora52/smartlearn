import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, DevoirSuiviResponse, SoumettreRenduRequest, CorrigerRenduRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class AssignmentService {
  readonly #api = inject(ApiService);
  // GET /api/v1/devoirs/mes-devoirs  (S11)
  getMes(): Observable<ApiResponse<PageResponse<DevoirSuiviResponse>>> { return this.#api.getPage<DevoirSuiviResponse>('/devoirs/mes-devoirs'); }
  // POST /api/v1/devoirs/soumettre  (S11)
  soumettre(req: SoumettreRenduRequest): Observable<ApiResponse<null>> { return this.#api.post<null>('/devoirs/soumettre', req); }
  // PATCH /api/v1/devoirs/rendus/{id}/corriger  (S23)
  corriger(renduId: string, req: CorrigerRenduRequest): Observable<ApiResponse<null>> { return this.#api.patch<null>(`/devoirs/rendus/${renduId}/corriger`, req); }
  // GET /api/v1/devoirs/sessions/{sessionId}/tableau-bord  (S23 formateur)
  getTableauBord(sessionId: string): Observable<ApiResponse<any>> { return this.#api.get<any>(`/devoirs/sessions/${sessionId}/tableau-bord`); }
}
