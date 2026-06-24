package com.mbem.mbemlevel.application.usecase.session;
import com.mbem.mbemlevel.application.port.out.SessionRepository;
import com.mbem.mbemlevel.domain.session.Devoir;
import com.mbem.mbemlevel.domain.session.Rendu;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S11 — Apprenant soumet son rendu avant la date limite.
 * Un seul rendu par apprenant par devoir (UNIQUE en BDD).
 */
@Service @RequiredArgsConstructor @Slf4j
public class SoumettreRenduUseCase {
    private final SessionRepository sessionRepo;

    @Transactional
    public Rendu executer(UUID devoirId, UUID apprenantId,
                           String contenu, String lienFichier) {
        Devoir devoir = sessionRepo.findDevoirById(devoirId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        // Vérifier la date limite
        if (devoir.estEnRetard(java.time.LocalDateTime.now())) {
            throw new RuntimeException("DEVOIR_DEADLINE_PASSED");
        }
        Rendu rendu = Rendu.soumettre(devoirId, apprenantId, contenu, lienFichier);
        Rendu saved = sessionRepo.saveRendu(rendu);
        log.info("[DEVOIR] Rendu soumis: devoir={} apprenant={}", devoirId, apprenantId);
        return saved;
    }
}
