package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.*;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.*;
/**
 * S08 — L'admin enregistre un paiement cash et active l'accès au cours.
 * Flux : créer Paiement → générer tranches → confirmer → publier events.
 */
@Service @RequiredArgsConstructor @Slf4j
public class EnregistrerPaiementCashUseCase {
    private final PaiementRepository       paiementRepo;
    private final ProgressionRepository    progressionRepo;
    private final UtilisateurRepository    utilisateurRepo;
    private final AuditLogRepository       auditRepo;
    private final ApplicationEventPublisher publisher;
    private final PaiementDomainService    domainService;

    public record Commande(
        UUID apprenantId, UUID coursId, long montantTotal,
        long montantPremiereTranche, int nbTranches,
        ModePaiement mode, UUID adminId,
        String prenomApprenant, String emailApprenant,
        String telephoneApprenant, String nomCours
    ) {}

    @Transactional
    public Paiement executer(Commande cmd) {
        // Créer ou retrouver le paiement
        Paiement paiement = paiementRepo
            .findByApprenantIdAndCoursId(cmd.apprenantId(), cmd.coursId())
            .orElseGet(() -> Paiement.creer(cmd.apprenantId(), cmd.coursId(),
                cmd.montantTotal(), cmd.mode()));

        // Confirmer et activer l'accès
        paiement.confirmerEtActiverAcces(cmd.adminId(), cmd.montantPremiereTranche(),
            cmd.prenomApprenant(), cmd.emailApprenant(),
            cmd.telephoneApprenant(), cmd.nomCours());
        Paiement saved = paiementRepo.save(paiement);

        // Générer le plan de tranches
        List<Tranche> tranches = domainService.genererPlan(
            saved, cmd.nbTranches(), cmd.montantPremiereTranche());
        paiementRepo.saveTranches(tranches);

        // Activer la progression (déverrouiller les modules)
        progressionRepo.activerPaiement(cmd.apprenantId(), cmd.coursId());

        // Publier les events (email + WhatsApp confirmation)
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();

        auditRepo.enregistrer(cmd.adminId(), null, "PAYMENT_ACTIVATED", "PAIEMENT",
            saved.getId().toString(), Map.of("apprenant", cmd.emailApprenant(),
            "montant", cmd.montantPremiereTranche()), "SUCCESS", null, null);

        log.info("[PAIEMENT] Accès activé: apprenant={} cours={}", cmd.apprenantId(), cmd.coursId());
        return saved;
    }
}
