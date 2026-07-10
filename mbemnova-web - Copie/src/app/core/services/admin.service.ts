import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse,
  PageResponse,
  StatistiquesResponse,
  ApprenantAdminView,
  InscriptionManuelleRequest,
  AssignerRoleRequest,
  DrawResponse,
  CoursResponse,
} from '../models';

@Injectable({ providedIn: 'root' })
export class AdminService {
  readonly #api = inject(ApiService);
  getStats(): Observable<ApiResponse<StatistiquesResponse>> {
    return this.#api.get<StatistiquesResponse>('/admin/statistiques');
  }
  getApprenants(
    p?: Record<string, string | number>,
  ): Observable<ApiResponse<PageResponse<ApprenantAdminView>>> {
    return this.#api.getPage<ApprenantAdminView>('/admin/apprenants', p);
  }
  inscrire(req: InscriptionManuelleRequest): Observable<ApiResponse<ApprenantAdminView>> {
    return this.#api.post<ApprenantAdminView>('/admin/apprenants', req);
  }
  assignerRole(req: AssignerRoleRequest): Observable<ApiResponse<null>> {
    return this.#api.post<null>('/admin/utilisateurs/role', req);
  }
  creerCours(req: any): Observable<ApiResponse<{ id: string }>> {
    return this.#api.post<{ id: string }>('/admin/cours', req);
  }
  getMesCours(): Observable<ApiResponse<CoursResponse[]>> {
    return this.#api.get<CoursResponse[]>('/admin/cours');
  }
  publierCours(id: string): Observable<ApiResponse<null>> {
    return this.#api.post<null>(`/admin/cours/${id}/publier`, {});
  }
  configurerTirage(config: Partial<DrawResponse>): Observable<ApiResponse<DrawResponse>> {
    return this.#api.post<DrawResponse>('/admin/tirage', config);
  }
  // DELETE /api/v1/utilisateurs/me
  supprimerMonCompte(): Observable<ApiResponse<null>> {
    return this.#api.delete<null>('/utilisateurs/me');
  }
  // GET /api/v1/utilisateurs/me/export
  exporterMesDonnees(): Observable<ApiResponse<unknown>> {
    return this.#api.get<unknown>('/utilisateurs/me/export');
  }
}
