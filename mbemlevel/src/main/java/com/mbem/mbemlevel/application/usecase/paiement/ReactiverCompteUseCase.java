package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** Réactiver un compte après régularisation du paiement. */
@Service @RequiredArgsConstructor
public class ReactiverCompteUseCase {
    private final UtilisateurRepository    utilisateurRepo;
    private final AuditLogRepository       auditRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public void executer(UUID apprenantId, UUID adminId) {
        Utilisateur user = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        user.reactiver();
        utilisateurRepo.save(user);
        auditRepo.enregistrer(adminId, null, "ACCOUNT_REACTIVATED", "UTILISATEUR",
            apprenantId.toString(), null, "SUCCESS", null, null);
    }
}
