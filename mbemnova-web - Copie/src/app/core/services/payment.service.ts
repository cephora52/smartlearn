import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, PaiementResponse, EnregistrerPaiementRequest, DemanderMoratoireRequest, TraiterMoratoireRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class PaymentService {
  readonly #api = inject(ApiService);
  getMes(): Observable<ApiResponse<PageResponse<PaiementResponse>>> { return this.#api.getPage<PaiementResponse>('/paiements'); }
  getAll(): Observable<ApiResponse<PaiementResponse[]>> { return this.#api.get<PaiementResponse[]>('/paiements'); }
  enregistrer(req: EnregistrerPaiementRequest): Observable<ApiResponse<PaiementResponse>> { return this.#api.post<PaiementResponse>('/paiements', req); }
  suspendre(id: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/paiements/apprenants/${id}/suspendre`, {}); }
  reactiver(id: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/paiements/apprenants/${id}/reactiver`, {}); }
  // POST /api/v1/moratoires  (S17)
  demanderMoratoire(req: DemanderMoratoireRequest): Observable<ApiResponse<string>> { return this.#api.post<string>('/moratoires', req); }
  // PATCH /api/v1/moratoires/{id}/decider  (S17 admin)
  deciderMoratoire(id: string, req: TraiterMoratoireRequest): Observable<ApiResponse<null>> { return this.#api.patch<null>(`/moratoires/${id}/decider`, req); }
  // GET /api/v1/moratoires  (S17 admin)
  getMoratoires(): Observable<ApiResponse<any[]>> { return this.#api.get<any[]>('/moratoires'); }
}
