import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, ProfilTalentResponse, MettreAJourProfilRequest, CertificatResponse, LeaderboardEntry, DrawResponse, TicketResponse, ParrainageMonLienResponse, FilleulResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class TalentService {
  readonly #api = inject(ApiService);
  // GET /api/v1/talents/me
  getMe(): Observable<ApiResponse<ProfilTalentResponse>> { return this.#api.get<ProfilTalentResponse>('/talents/me'); }
  // GET /api/v1/talents/{apprenantId}
  getPublic(id: string): Observable<ApiResponse<ProfilTalentResponse>> { return this.#api.get<ProfilTalentResponse>(`/talents/${id}`); }
  // PUT /api/v1/talents/me  (S14 — PUT pas PATCH dans s21)
  update(req: MettreAJourProfilRequest): Observable<ApiResponse<ProfilTalentResponse>> { return this.#api.put<ProfilTalentResponse>('/talents/me', req); }
  // POST /api/v1/certificats/cours/{coursId}/generer  (S13)
  genererCertificat(coursId: string): Observable<ApiResponse<CertificatResponse>> { return this.#api.post<CertificatResponse>(`/certificats/cours/${coursId}/generer`, {}); }
  // GET /api/v1/certificats/verify/{code}
  verifierCertificat(code: string): Observable<ApiResponse<any>> { return this.#api.get<any>(`/certificats/verify/${code}`); }
  // GET /api/v1/classement
  getLeaderboard(p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<LeaderboardEntry>>> { return this.#api.getPage<LeaderboardEntry>('/classement', p); }
  // GET /api/v1/tirage
  getTirage(): Observable<ApiResponse<DrawResponse>> { return this.#api.get<DrawResponse>('/tirage'); }
  // POST /api/v1/tirage
  acheterTicket(drawId: string): Observable<ApiResponse<TicketResponse>> { return this.#api.post<TicketResponse>('/tirage', { drawId }); }
  // GET /api/v1/parrainage/mon-lien  (S15)
  getMonLien(): Observable<ApiResponse<ParrainageMonLienResponse>> { return this.#api.get<ParrainageMonLienResponse>('/parrainage/mon-lien'); }
  // GET /api/v1/parrainage/mes-filleuls  (S15)
  getMesFilleuls(): Observable<ApiResponse<FilleulResponse[]>> { return this.#api.get<FilleulResponse[]>('/parrainage/mes-filleuls'); }
}
