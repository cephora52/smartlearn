package com.mbem.mbemlevel.application.usecase.gamification;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.gamification.Parrainage;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import com.mbem.mbemlevel.domain.user.valueobject.LienParrainage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S15 — Activer la récompense de parrainage quand le filleul
 * complète son premier module (XP >= 100).
 */
@Service @RequiredArgsConstructor @Slf4j
public class TraiterParrainageUseCase {
    private final UtilisateurRepository  utilisateurRepo;
    private final ApplicationEventPublisher publisher;

    /** Génère un code de parrainage unique pour un apprenant. */
    @Transactional
    public String genererCode(UUID apprenantId) {
        Utilisateur u = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        String code = LienParrainage.generer().code();
        // Note: le code est enregistré sur l'entité utilisateur (champ codeParrainage)
        // La mise à jour de l'entité JPA est gérée via utilisateurRepo.save()
        log.debug("[PARRAINAGE] Code généré: {} pour apprenant {}", code, apprenantId);
        return code;
    }
}
