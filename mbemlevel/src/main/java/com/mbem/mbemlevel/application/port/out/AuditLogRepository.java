// =============================================================================
// MbemNova — application/port/out/AuditLogRepository.java
// Port sortant pour les logs d'audit — INSERT ONLY, immuable.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.util.Map;
import java.util.UUID;

/**
 * Port sortant — journal d'audit immuable.
 *
 * <h3>Actions tracées obligatoirement</h3>
 * <pre>
 * LOGIN_SUCCESS · LOGIN_FAILURE · LOGOUT
 * REGISTER · EMAIL_VERIFIED
 * PASSWORD_CHANGED · PASSWORD_RESET_REQUESTED · PASSWORD_RESET_DONE
 * TOKEN_REFRESHED · TOKEN_REVOKED
 * PAYMENT_REGISTERED · PAYMENT_ACTIVATED
 * ACCOUNT_SUSPENDED · ACCOUNT_REACTIVATED
 * ROLE_CHANGED · DATA_EXPORTED
 * </pre>
 *
 * <p>IMPORTANT : La transaction est REQUIRES_NEW dans l'adaptateur.
 * Le log est persisté même si la transaction principale fait rollback.</p>
 */
public interface AuditLogRepository {

    /**
     * Enregistre une action dans le journal.
     *
     * @param utilisateurId ID de l'utilisateur (null pour actions anonymes)
     * @param userEmail     Email dénormalisé (retrouvable même si compte supprimé)
     * @param action        Type SCREAMING_SNAKE_CASE (ex: LOGIN_SUCCESS)
     * @param ressourceType Type de ressource (ex: UTILISATEUR, PAIEMENT)
     * @param ressourceId   ID de la ressource affectée
     * @param details       Contexte JSON (ex: {ancien_role, nouveau_role})
     * @param statut        SUCCESS | FAILURE | WARNING
     * @param ip            IP réelle du client (après X-Forwarded-For)
     * @param userAgent     User-Agent du navigateur
     */
    void enregistrer(UUID utilisateurId, String userEmail, String action,
                     String ressourceType, String ressourceId,
                     Map<String, Object> details, String statut,
                     String ip, String userAgent);
}
