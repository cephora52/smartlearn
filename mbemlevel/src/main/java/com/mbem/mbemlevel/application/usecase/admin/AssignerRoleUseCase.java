package com.mbem.mbemlevel.application.usecase.admin;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
/**
 * S26 — Un admin change le rôle d'un utilisateur.
 * Règle domaine : seul un SUPER_ADMIN peut attribuer SUPER_ADMIN.
 */
@Service @RequiredArgsConstructor @Slf4j
public class AssignerRoleUseCase {
    private final UtilisateurRepository repo;
    private final AuditLogRepository    auditRepo;

    @Transactional
    public Utilisateur executer(UUID cibleId, Role nouveauRole,
                                 UUID adminId, Role roleAdmin) {
        Utilisateur cible = repo.findById(cibleId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        Role ancienRole = cible.getRole();
        // La règle métier est dans l'agrégat (vérifie SUPER_ADMIN)
        cible.changerRole(nouveauRole, roleAdmin);
        Utilisateur saved = repo.save(cible);
        auditRepo.enregistrer(adminId, null, "ROLE_CHANGED",
            "UTILISATEUR", cibleId.toString(),
            Map.of("ancienRole", ancienRole.name(), "nouveauRole", nouveauRole.name()),
            "SUCCESS", null, null);
        log.info("[ADMIN] Rôle modifié: {} {} → {}", cibleId, ancienRole, nouveauRole);
        return saved;
    }
}
