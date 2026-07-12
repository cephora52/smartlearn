import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, SessionResponse, CreneauResponse, ChoisirCreneauxRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class SessionService {
  readonly #api = inject(ApiService);
  getByCours(coursId: string): Observable<ApiResponse<SessionResponse[]>> { return this.#api.get<SessionResponse[]>(`/sessions/cours/${coursId}`); }
  inscrire(sessionId: string, req: { coursId: string }): Observable<ApiResponse<SessionResponse>> { return this.#api.post<SessionResponse>(`/sessions/${sessionId}/inscrire`, req); }
  // GET /api/v1/sessions/{sessionId}/creneaux  (S10)
  getCreneaux(sessionId: string): Observable<ApiResponse<CreneauResponse[]>> { return this.#api.get<CreneauResponse[]>(`/sessions/${sessionId}/creneaux`); }
  // POST /api/v1/sessions/{sessionId}/creneaux  (S10)
  choisirCreneaux(sessionId: string, req: ChoisirCreneauxRequest): Observable<ApiResponse<null>> { return this.#api.post<null>(`/sessions/${sessionId}/creneaux`, req); }
}
