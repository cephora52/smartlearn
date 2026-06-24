package com.mbem.mbemlevel.application.usecase.gamification;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.gamification.TirageAuSort;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.util.*;
/**
 * S24 — Tirage au sort mensuel parmi les apprenants actifs du mois.
 * Éligibles : apprenants ayant avancé dans au moins un cours ce mois.
 */
@Service @RequiredArgsConstructor @Slf4j
public class EffectuerTirageAuSortUseCase {
    private final UtilisateurRepository utilisateurRepo;
    private final EmailPort             emailPort;
    private static final SecureRandom   RANDOM = new SecureRandom();

    @Transactional
    public TirageAuSort executer(String prixDescription) {
        // Participants : tous les apprenants actifs
        List<Utilisateur> eligibles = utilisateurRepo.findAll().stream()
            .filter(u -> "APPRENANT".equals(u.getRole().name())
                      && "ACTIF".equals(u.getStatut().name()))
            .toList();

        if (eligibles.isEmpty()) {
            log.warn("[TIRAGE] Aucun participant éligible ce mois");
            return TirageAuSort.creer(LocalDate.now().withDayOfMonth(1), 0, prixDescription);
        }

        // Tirage aléatoire cryptographiquement sécurisé
        Utilisateur gagnant = eligibles.get(RANDOM.nextInt(eligibles.size()));
        TirageAuSort tirage = TirageAuSort.creer(
            LocalDate.now().withDayOfMonth(1), eligibles.size(), prixDescription);
        tirage.designerGagnant(gagnant.getId());

        // Notifier le gagnant
        emailPort.envoyerGagnantTirage(gagnant.getEmail(), gagnant.getPrenom(), prixDescription);

        log.info("[TIRAGE] Gagnant du mois {}: {} (parmi {} éligibles)",
            LocalDate.now().getMonth(), gagnant.getEmail(), eligibles.size());
        return tirage;
    }
}
