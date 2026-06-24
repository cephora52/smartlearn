package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S18 — Suspendre un compte apprenant après J+10 sans paiement. */
@Service @RequiredArgsConstructor @Slf4j
public class SuspendreCompteUseCase {
    private final UtilisateurRepository    utilisateurRepo;
    private final AuditLogRepository       auditRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public void executer(UUID apprenantId, UUID adminId, String message) {
        Utilisateur user = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        user.suspendre(message);
        utilisateurRepo.save(user);
        user.getDomainEvents().forEach(publisher::publishEvent);
        user.clearDomainEvents();
        auditRepo.enregistrer(adminId, null, "ACCOUNT_SUSPENDED", "UTILISATEUR",
            apprenantId.toString(), null, "SUCCESS", null, null);
        log.info("[PAIEMENT] Compte suspendu: {}", apprenantId);
    }
}
