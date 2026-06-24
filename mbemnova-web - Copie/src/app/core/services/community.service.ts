import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, MessageResponse, PostMessageRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class CommunityService {
  readonly #api = inject(ApiService);
  // GET /api/v1/communaute/cours/{coursId}/questions
  getQuestions(coursId: string, p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<MessageResponse>>> { return this.#api.getPage<MessageResponse>(`/communaute/cours/${coursId}/questions`, p); }
  // GET /api/v1/communaute/messages/{parentId}/reponses
  getReponses(parentId: string): Observable<ApiResponse<MessageResponse[]>> { return this.#api.get<MessageResponse[]>(`/communaute/messages/${parentId}/reponses`); }
  // POST /api/v1/communaute/cours/{coursId}/messages
  publier(coursId: string, req: PostMessageRequest): Observable<ApiResponse<MessageResponse>> { return this.#api.post<MessageResponse>(`/communaute/cours/${coursId}/messages`, req); }
  // POST /api/v1/communaute/messages/{messageId}/signaler
  signaler(messageId: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/communaute/messages/${messageId}/signaler`, {}); }
}
