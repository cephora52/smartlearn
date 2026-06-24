// =============================================================================
// MbemNova — infrastructure/persistence/adapter/AuditLogRepositoryAdapter.java
//
// Implémente AuditLogRepository via JPA.
// PROPAGATION.REQUIRES_NEW : persiste le log même si la transaction
// principale fait rollback. Essentiel pour tracer les échecs.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.AuditLogJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

/**
 * Adaptateur audit — toujours persiste dans sa propre transaction.
 * Ne jamais faire échouer l'action principale à cause du log d'audit.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AuditLogRepositoryAdapter implements AuditLogRepository {

    private final AuditLogJpaRepository jpaRepository;

    /**
     * REQUIRES_NEW : le log est persisté dans une transaction indépendante.
     * Même si la transaction principale est en rollback, le log est sauvegardé.
     */
    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void enregistrer(UUID utilisateurId, String userEmail, String action,
                            String ressourceType, String ressourceId,
                            Map<String, Object> details, String statut,
                            String ip, String userAgent) {
        try {
            jpaRepository.save(AuditLogJpaEntity.builder()
                .utilisateurId(utilisateurId)
                .userEmail(userEmail)
                .action(action)
                .ressourceType(ressourceType)
                .ressourceId(ressourceId)
                .details(details)
                .statut(statut != null ? statut : "SUCCESS")
                .ipAdresse(ip)
                .userAgent(userAgent)
                .build());
        } catch (Exception e) {
            // Log en erreur mais ne pas propager — l'audit ne doit pas bloquer le métier
            log.error("[AUDIT-FAIL] action={} user={} err={}", action, userEmail, e.getMessage());
        }
    }
}
