import { HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { of, delay } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  MOCK_AUTH, MOCK_COURS, MOCK_COURS_DETAIL, MOCK_PROGRESSION,
  MOCK_PAIEMENTS, MOCK_SESSIONS, MOCK_DEVOIRS_SUIVI, MOCK_MESSAGES,
  MOCK_AVIS, MOCK_NOTIFICATIONS, MOCK_PROFIL, MOCK_LEADERBOARD,
  MOCK_DRAW, MOCK_REFERRAL, MOCK_STATS, MOCK_APPRENANTS, MOCK_QCM,
} from '../services/mock.data';

const D = 350; // délai réseau simulé (ms)
const ok = <T>(data: T, msg = 'OK') => ({ success: true, data, message: msg, timestamp: new Date().toISOString() });
const page = <T>(items: T[], total?: number) => ok({ content: items, page: 0, size: items.length, totalElements: total ?? items.length, totalPages: 1, first: true, last: true });

/**
 * MockInterceptor
 *
 * BASCULE AUTOMATIQUE :
 *   environment.useMock = true  → toutes les requêtes retournent les données mock
 *   environment.useMock = false → les requêtes passent vers l'API Spring Boot
 *
 * Pour changer : modifier src/environments/environment.ts
 *   useMock: false → npm start → connecté à l'API réelle
 */
export const mockInterceptor: HttpInterceptorFn = (req, next) => {
  if (!environment.useMock) return next(req);

  const p = req.url.split('/api/v1')[1] ?? '';
  const m = req.method;

  // ── Auth ──────────────────────────────────────────────────
  if (m === 'POST' && p.includes('/auth/login'))          return r(ok(MOCK_AUTH, 'Connexion réussie'));
  if (m === 'POST' && p.includes('/auth/register'))       return r(ok(MOCK_AUTH, 'Compte créé'));
  if (m === 'POST' && p.includes('/auth/refresh'))        return r(ok({ accessToken: 'mock.refreshed' }));
  if (m === 'POST' && p.includes('/auth/logout'))         return r(ok(null, 'Déconnecté'));
  if (m === 'POST' && p.includes('/auth/reset-password')) return r(ok(null, 'Email envoyé si compte existant'));
  if (m === 'POST' && p.includes('/auth/new-password'))   return r(ok(null, 'Mot de passe mis à jour'));
  if (m === 'GET'  && p === '/auth/me')                   return r(ok({ userId: MOCK_AUTH.userId, prenom: MOCK_AUTH.prenom, email: MOCK_AUTH.email, role: MOCK_AUTH.role, photoUrl: null, statut: 'ACTIF' }));

  // ── Cours ──────────────────────────────────────────────────
  // if (m === 'GET' && (p === '/cours' || p.startsWith('/cours?')))         return r(page(MOCK_COURS, 6));
  // if (m === 'GET' && p.startsWith('/cours/slug/'))                        return r(ok(MOCK_COURS_DETAIL));
  // if (m === 'GET' && p.match(/^\/cours\/[^/]+$/) && !p.includes('/avis') && !p.includes('/liste')) return r(ok(MOCK_COURS_DETAIL));
  if (m === 'GET' && p.includes('/avis'))                                 return r(ok(MOCK_AVIS));
  if (m === 'POST' && p.includes('/avis'))                                return r(ok('av-new', 'Merci pour ton avis !'));
  if (m === 'POST' && p.includes('/liste-attente'))                       return r(ok(null, 'Tu es sur la liste d\'attente.'));

  // ── Progression ────────────────────────────────────────────
  if (m === 'POST' && p.includes('/commencer'))           return r(ok({ ...MOCK_PROGRESSION, pourcentage: 0 }, 'Progression initialisée'));
  if (m === 'POST' && p.includes('/terminer-lecon'))      return r(ok({ ...MOCK_PROGRESSION, pourcentage: MOCK_PROGRESSION.pourcentage + 12, xpGagne: MOCK_PROGRESSION.xpGagne + 10 }, '+10 XP !'));
  if (m === 'GET'  && p.startsWith('/progression/cours')) return r(ok(MOCK_PROGRESSION));
  if (m === 'GET'  && p.startsWith('/progression'))       return r(page([MOCK_PROGRESSION]));

  // ── QCM ───────────────────────────────────────────────────
  if (m === 'POST' && p.includes('/qcm/lecons/')) {
    const body = req.body as { leconId: string; reponse: string } | null;
    const leconId = p.split('/lecons/')[1]?.split('/')[0] ?? '';
    const qcm = MOCK_QCM[leconId];
    if (qcm && body) {
      const estCorrect = body.reponse === qcm.bonneReponse;
      return r(ok({ estCorrect, scoreObtenu: estCorrect ? 100 : 0, bonneReponse: qcm.bonneReponse, explication: qcm.explication, leconValidee: estCorrect }, estCorrect ? '✓ Bonne réponse !' : '✗ Pas tout à fait.'));
    }
    return r(ok({ estCorrect: true, scoreObtenu: 100, bonneReponse: 'A', explication: 'Mock réponse.', leconValidee: true }));
  }

  // ── Paiements ──────────────────────────────────────────────
  if (m === 'GET'  && (p === '/paiements' || p.startsWith('/paiements?'))) return r(page(MOCK_PAIEMENTS));
  if (m === 'POST' && p === '/paiements')                                   return r(ok(MOCK_PAIEMENTS[0], 'Paiement enregistré. Accès activé.'));
  if (m === 'POST' && p.includes('/suspendre'))                             return r(ok(null, 'Compte suspendu'));
  if (m === 'POST' && p.includes('/reactiver'))                             return r(ok(null, 'Compte réactivé'));
  // Moratoires
  if (m === 'POST' && p === '/moratoires')                                  return r(ok('mor-new', 'Demande soumise. L\'équipe te répondra rapidement.'));
  if (m === 'PATCH' && p.includes('/moratoires/') && p.includes('/decider')) return r(ok(null, 'Décision enregistrée'));

  // ── Sessions + Créneaux ────────────────────────────────────
  if (m === 'GET'  && p.startsWith('/sessions'))                           return r(page(MOCK_SESSIONS));
  if (m === 'POST' && p.includes('/inscrire'))                             return r(ok(MOCK_SESSIONS[0], 'Inscription confirmée'));
  if (m === 'GET'  && p.includes('/creneaux'))                             return r(ok([
    { id: 'cr-1', sessionId: 's-001', jourSemaine: 'LUNDI',    heureDebut: '09:00', dureeMinutes: 120, capaciteMax: 10, placesRestantes: 5 },
    { id: 'cr-2', sessionId: 's-001', jourSemaine: 'MERCREDI', heureDebut: '14:00', dureeMinutes: 120, capaciteMax: 10, placesRestantes: 3 },
    { id: 'cr-3', sessionId: 's-001', jourSemaine: 'SAMEDI',   heureDebut: '10:00', dureeMinutes: 120, capaciteMax: 10, placesRestantes: 0 },
  ]));
  if (m === 'POST' && p.includes('/creneaux'))                             return r(ok(null, 'Créneaux enregistrés. Rappel J-1 activé.'));

  // ── Devoirs ────────────────────────────────────────────────
  if (m === 'GET'  && p.includes('/mes-devoirs'))                          return r(page(MOCK_DEVOIRS_SUIVI));
  if (m === 'POST' && p === '/devoirs/soumettre')                          return r(ok(null, 'Rendu soumis'));
  if (m === 'PATCH' && p.includes('/corriger'))                            return r(ok(null, 'Correction enregistrée'));
  if (m === 'GET'  && p.includes('/tableau-bord'))                         return r(ok({ total: 5, corriges: 3, enAttente: 2 }));

  // ── Communauté ─────────────────────────────────────────────
  if (m === 'GET'  && p.includes('/communaute') && p.includes('/questions')) return r(page(MOCK_MESSAGES));
  if (m === 'GET'  && p.includes('/reponses'))                               return r(ok(MOCK_MESSAGES[0].reponses ?? []));
  if (m === 'POST' && p.includes('/communaute'))                             return r(ok(MOCK_MESSAGES[1], 'Message publié'));
  if (m === 'POST' && p.includes('/signaler'))                               return r(ok(null, 'Message signalé'));

  // ── Notifications ──────────────────────────────────────────
  if (m === 'GET'  && p === '/notifications')                               return r(page(MOCK_NOTIFICATIONS));
  if (m === 'GET'  && p === '/notifications/unread')                        return r(ok({ count: MOCK_NOTIFICATIONS.filter(n => !n.estLue).length }));
  if (m === 'PATCH' && p === '/notifications/read-all')                     return r(ok(null, 'Lu'));

  // ── Talents + Certificats + Classement ────────────────────
  if (m === 'GET'  && p === '/talents/me')                                  return r(ok(MOCK_PROFIL));
  if (m === 'GET'  && p.match(/^\/talents\/.+$/))                          return r(ok(MOCK_PROFIL));
  if (m === 'PUT'  && p === '/talents/me')                                  return r(ok(MOCK_PROFIL, 'Profil mis à jour'));
  if (m === 'POST' && p.includes('/certificats/cours/'))                    return r(ok(MOCK_PROFIL.certificats[0], 'Félicitations ! Certificat généré.'));
  if (m === 'GET'  && p.includes('/certificats/verify/'))                   return r(ok({ ...MOCK_PROFIL.certificats[0], prenomApprenant: 'Jean-Paul', nomApprenant: 'Mbemba' }));
  if (m === 'GET'  && p === '/classement')                                  return r(page(MOCK_LEADERBOARD, 247));

  // ── Tirage + Parrainage ─────────────────────────────────────
  if (m === 'GET'  && p === '/tirage')                                       return r(ok(MOCK_DRAW));
  if (m === 'POST' && p === '/tirage')                                       return r(ok({ id: 'ticket-new', drawId: 'draw-001', numero: 'MB-0048', acheteLe: new Date().toISOString() }, 'Ticket acheté ! N° MB-0048'));
  if (m === 'GET'  && p === '/parrainage/mon-lien')                          return r(ok({ lienParrainage: MOCK_REFERRAL.lienParrainage, codeParrainage: MOCK_REFERRAL.codeParrainage }));
  if (m === 'GET'  && p === '/parrainage/mes-filleuls')                      return r(ok(MOCK_REFERRAL.filleuls));

  // ── Admin ──────────────────────────────────────────────────
  if (m === 'GET'  && p === '/admin/statistiques')                          return r(ok(MOCK_STATS));
  if (m === 'GET'  && p.startsWith('/admin/apprenants'))                    return r(page(MOCK_APPRENANTS, 247));
  if (m === 'POST' && p === '/admin/apprenants')                            return r(ok(MOCK_APPRENANTS[0], 'Apprenant inscrit'));
  if (m === 'POST' && p === '/admin/utilisateurs/role')                     return r(ok(null, 'Rôle mis à jour'));
  if (m === 'POST' && p === '/admin/cours')                                 return r(ok({ id: 'c-new' }, 'Cours créé en brouillon'));
  if (m === 'POST' && p.includes('/publier'))                               return r(ok(null, 'Cours publié'));
  if (m === 'POST' && p === '/admin/tirage')                                return r(ok(MOCK_DRAW, 'Tirage configuré'));

  // ── Utilisateurs (RGPD) ────────────────────────────────────
  if (m === 'DELETE' && p === '/utilisateurs/me')                           return r(ok(null, 'Compte supprimé'));
  if (m === 'GET'    && p === '/utilisateurs/me/export')                    return r(ok({ message: 'Export en cours, tu recevras un email.' }));

  // Fallback → passer à l'API réelle
  return next(req);
};

function r<T>(body: T) {
  return of(new HttpResponse({ status: 200, body })).pipe(delay(D));
}
