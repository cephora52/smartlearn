package com.mbem.mbemlevel.api.config;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class AdminInitializer implements CommandLineRunner {

    private final UtilisateurJpaRepository repository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        boolean hasAdmin = repository.existsByRole(Role.ADMIN) || repository.existsByRole(Role.SUPER_ADMIN);
        boolean emailExists = repository.existsByEmailIgnoreCase("admin@mbemnova.com");

        if (!hasAdmin && !emailExists) {
            log.info("[INIT] Aucun administrateur détecté. Création du compte administrateur par défaut...");
            
            UtilisateurJpaEntity admin = UtilisateurJpaEntity.builder()
                .id(UUID.randomUUID())
                .nom("Administrateur")
                .prenom("Système")
                .email("admin@mbemnova.com")
                .motDePasseHache(passwordEncoder.encode("Admin@123"))
                .emailVerifie(true)
                .role(Role.ADMIN)
                .statut(StatutApprenant.ACTIF)
                .tentativesEchouees(0)
                .xpTotal(0)
                .streakJours(0)
                .disponiblePourEmploi(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

            repository.save(admin);
            log.info("[INIT] Compte administrateur par défaut créé avec succès : admin@mbemnova.com / Admin@123");
        } else {
            log.info("[INIT] Un ou plusieurs administrateurs existent déjà en base de données. Pas d'initialisation requise.");
        }
    }
}
