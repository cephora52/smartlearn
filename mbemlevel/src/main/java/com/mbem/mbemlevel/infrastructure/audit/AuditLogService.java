// =============================================================================
// MbemNova — infrastructure/audit/AuditLogService.java
//
// Service d'audit centralisé — façade sur AuditLogRepository.
// Simplifie les appels depuis les use cases et les aspects AOP.
// Extrait automatiquement l'IP depuis la requête HTTP courante.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.audit;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Map;
import java.util.UUID;

/**
 * Service d'audit centralisé pour MbemNova.
 *
 * <h3>Usage dans les use cases</h3>
 * <pre>{@code
 * // Action réussie
 * auditService.succes(userId, email, "LOGIN_SUCCESS", "UTILISATEUR", userId.toString(), null);
 *
 * // Échec
 * auditService.echec(null, email, "LOGIN_FAILURE", "UTILISATEUR", null,
 *     Map.of("raison", "Email inexistant"));
 * }</pre>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuditLogService {

    private final AuditLogRepository repository;

    /** Journalise une action réussie. */
    public void succes(UUID userId, String email, String action,
                       String ressourceType, String ressourceId,
                       Map<String, Object> details) {
        enregistrer(userId, email, action, ressourceType, ressourceId, details, "SUCCESS");
    }

    /** Journalise un échec. */
    public void echec(UUID userId, String email, String action,
                      String ressourceType, String ressourceId,
                      Map<String, Object> details) {
        enregistrer(userId, email, action, ressourceType, ressourceId, details, "FAILURE");
    }

    /** Journalise un avertissement. */
    public void avertissement(UUID userId, String email, String action,
                               String ressourceType, String ressourceId,
                               Map<String, Object> details) {
        enregistrer(userId, email, action, ressourceType, ressourceId, details, "WARNING");
    }

    private void enregistrer(UUID userId, String email, String action,
                              String ressourceType, String ressourceId,
                              Map<String, Object> details, String statut) {
        String ip        = null;
        String userAgent = null;

        // Récupérer IP et User-Agent depuis la requête HTTP courante (si disponible)
        try {
            ServletRequestAttributes attrs =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs != null) {
                HttpServletRequest req = attrs.getRequest();
                ip        = extraireIpReelle(req);
                userAgent = req.getHeader("User-Agent");
            }
        } catch (Exception ignored) {
            // Hors contexte HTTP (scheduler, test) — IP null
        }

        repository.enregistrer(userId, email, action, ressourceType,
            ressourceId, details, statut, ip, userAgent);
    }

    /**
     * Extrait l'IP réelle en tenant compte du reverse proxy Nginx.
     * Nginx ajoute X-Forwarded-For avec l'IP originale du client.
     */
    private String extraireIpReelle(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            // Format : "ip-client, ip-proxy1, ip-proxy2" → prendre la première
            return forwarded.split(",")[0].trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) {
            return realIp.trim();
        }
        return request.getRemoteAddr();
    }
}
