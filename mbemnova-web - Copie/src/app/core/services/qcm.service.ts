import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, ValiderQCMRequest, ResultatQCMResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class QcmService {
  readonly #api = inject(ApiService);
  // POST /api/v1/qcm/lecons/{leconId}/valider  (S6)
  valider(leconId: string, req: ValiderQCMRequest): Observable<ApiResponse<ResultatQCMResponse>> {
    return this.#api.post<ResultatQCMResponse>(`/qcm/lecons/${leconId}/valider`, req);
  }
}
