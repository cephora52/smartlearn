package com.mbem.mbemlevel.application.usecase.admin;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S19 — Formateur ou Admin crée un nouveau cours.
 * Le cours est créé en mode BROUILLON (estActif=false).
 * La publication est une action séparée (PublierCoursUseCase).
 */
@Service @RequiredArgsConstructor @Slf4j
public class CreerCoursUseCase {
    private final CoursRepository  coursRepo;
    private final AuditLogRepository auditRepo;

    public record Commande(String titre, String description, NiveauCours niveau,
                            UUID categorieId, UUID formateurId, double seuilPaiement,
                            long prixFcfa, UUID creePar) {}

    @Transactional
    public Cours executer(Commande cmd) {
        Cours cours = Cours.creer(cmd.titre(), cmd.description(), cmd.niveau(),
            cmd.categorieId(), cmd.formateurId(), cmd.seuilPaiement(), cmd.prixFcfa());
        Cours saved = coursRepo.save(cours);
        auditRepo.enregistrer(cmd.creePar(), null, "COURS_CREATED",
            "COURS", saved.getId().toString(), null, "SUCCESS", null, null);
        log.info("[ADMIN] Cours créé (brouillon): {}", saved.getTitre());
        return saved;
    }
}
