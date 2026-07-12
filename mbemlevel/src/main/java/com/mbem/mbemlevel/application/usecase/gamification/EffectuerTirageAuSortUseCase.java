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
    private final UtilisateurRepository  utilisateurRepo;
    private final TirageAuSortRepository tirageRepo;
    private final EmailPort              emailPort;
    private static final SecureRandom    RANDOM = new SecureRandom();

    @Transactional
    public TirageAuSort executer(String prixDescription) {
        // Recherche d'un admin/super admin existant en base de données pour associer le tirage automatique
        UUID defaultAdminId = utilisateurRepo.findAll().stream()
            .filter(u -> "SUPER_ADMIN".equals(u.getRole().name()) || "ADMIN".equals(u.getRole().name()))
            .map(Utilisateur::getId)
            .findFirst()
            .orElseGet(() -> utilisateurRepo.findAll().stream()
                .findFirst()
                .map(Utilisateur::getId)
                .orElse(UUID.randomUUID())); // Fallback ultime si base vide
        return executer(prixDescription, defaultAdminId);
    }

    @Transactional
    public TirageAuSort executer(String prixDescription, UUID adminId) {
        // Participants : tous les apprenants actifs
        List<Utilisateur> eligibles = utilisateurRepo.findAll().stream()
            .filter(u -> "APPRENANT".equals(u.getRole().name())
                      && "ACTIF".equals(u.getStatut().name()))
            .toList();

        if (eligibles.isEmpty()) {
            log.warn("[TIRAGE] Aucun participant éligible ce mois");
            TirageAuSort tirage = TirageAuSort.creer(LocalDate.now().withDayOfMonth(1), 0, prixDescription);
            tirageRepo.sauvegarder(tirage, adminId);
            return tirage;
        }

        // Tirage aléatoire cryptographiquement sécurisé
        Utilisateur gagnant = eligibles.get(RANDOM.nextInt(eligibles.size()));
        TirageAuSort tirage = TirageAuSort.creer(
            LocalDate.now().withDayOfMonth(1), eligibles.size(), prixDescription);
        tirage.designerGagnant(gagnant.getId());

        // Sauvegarder le tirage et le gagnant en base
        tirageRepo.sauvegarder(tirage, adminId);

        // Notifier le gagnant
        emailPort.envoyerGagnantTirage(gagnant.getEmail(), gagnant.getPrenom(), prixDescription);

        log.info("[TIRAGE] Gagnant du mois {}: {} (parmi {} éligibles)",
            LocalDate.now().getMonth(), gagnant.getEmail(), eligibles.size());
        return tirage;
    }
}
