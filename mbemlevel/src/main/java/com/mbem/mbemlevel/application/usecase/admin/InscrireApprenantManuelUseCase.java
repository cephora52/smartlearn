package com.mbem.mbemlevel.application.usecase.admin;
import com.mbem.mbemlevel.application.dto.request.InscriptionCommand;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.application.usecase.auth.InscrireApprenantUseCase;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
/**
 * S21 — L'admin inscrit manuellement un apprenant.
 * Cas A : apprenant avec compte existant → assigner formation.
 * Cas B : nouveau compte → créer profil minimal et assigner.
 */
@Service @RequiredArgsConstructor @Slf4j
public class InscrireApprenantManuelUseCase {
    private final UtilisateurRepository    utilisateurRepo;
    private final InscrireApprenantUseCase inscrireUC;
    private final AuditLogRepository       auditRepo;

    public record Commande(String prenom, String email, String motDePasse,
                            UUID adminId, String ipAdmin) {}

    @Transactional
    public Utilisateur executer(Commande cmd) {
        // Cas A : compte existant
        if (utilisateurRepo.existsByEmail(cmd.email())) {
            Utilisateur u = utilisateurRepo.findByEmail(cmd.email())
                .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
            auditRepo.enregistrer(cmd.adminId(), null, "MANUAL_REGISTRATION_EXISTING",
                "UTILISATEUR", u.getId().toString(),
                Map.of("email", cmd.email()), "SUCCESS", cmd.ipAdmin(), null);
            log.info("[ADMIN] Apprenant existant trouvé: {}", cmd.email());
            return u;
        }
        // Cas B : nouveau compte
        AuthResultDto result = inscrireUC.executer(
            new InscriptionCommand(cmd.prenom(), cmd.email(),
                cmd.motDePasse(), cmd.ipAdmin(), "AdminBackoffice"));
        Utilisateur u = utilisateurRepo.findById(result.utilisateurId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        auditRepo.enregistrer(cmd.adminId(), null, "MANUAL_REGISTRATION_NEW",
            "UTILISATEUR", u.getId().toString(),
            Map.of("email", cmd.email()), "SUCCESS", cmd.ipAdmin(), null);
        log.info("[ADMIN] Apprenant créé manuellement: {}", cmd.email());
        return u;
    }
}
