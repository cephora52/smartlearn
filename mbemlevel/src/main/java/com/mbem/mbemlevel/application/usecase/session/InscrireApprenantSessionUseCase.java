package com.mbem.mbemlevel.application.usecase.session;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.session.Session;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S09 — Inscrire un apprenant à une session.
 * Vérifie les places disponibles et les droits (paiement activé).
 */
@Service @RequiredArgsConstructor @Slf4j
public class InscrireApprenantSessionUseCase {
    private final SessionRepository    sessionRepo;
    private final PaiementRepository   paiementRepo;

    @Transactional
    public Session executer(UUID sessionId, UUID apprenantId, UUID coursId) {
        // Vérifier que le paiement est activé pour ce cours
        paiementRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .filter(p -> p.isAccesActive())
            .orElseThrow(() -> new RuntimeException("PAYMENT_REQUIRED"));

        Session session = sessionRepo.findById(sessionId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));

        session.inscrireApprenant(apprenantId);
        Session saved = sessionRepo.save(session);
        log.info("[SESSION] Apprenant {} inscrit à session {}", apprenantId, sessionId);
        return saved;
    }
}
