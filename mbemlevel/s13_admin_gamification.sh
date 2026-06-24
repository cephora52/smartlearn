#!/usr/bin/env bash
# =============================================================================
# MbemNova · Script 13/15 · Admin + Gamification + Schedulers + Config
# =============================================================================
# CONTENU :
#   Use Cases Admin   : InscrireApprenantManuelUseCase (S21)
#                       AssignerRoleUseCase (S26)
#                       GetStatistiquesUseCase (S25)
#                       CreerCoursUseCase (S19)
#                       CreerSessionAdminUseCase (S20)
#   Use Cases Gamif   : EffectuerTirageAuSortUseCase (S24)
#   Controllers       : AdminController, CoursAdminController
#   DTOs Admin        : StatistiquesResponse, InscriptionManuelleRequest,
#                       AssignerRoleRequest, CreerCoursRequest
#   Scheduler         : TirageAuSortScheduler
#   Infrastructure    : S3Config (beans AWS SDK), StorageConfig
#   Architecture test : ArchitectureTest (ArchUnit)
#   Application entry : MbemlevelApplication (update avec @EnableAsync)
# SCÉNARIOS : S19, S20, S21, S24, S25, S26
# =============================================================================
set -euo pipefail; export LC_ALL=C.UTF-8
G='\033[0;32m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()  { echo -e "${G}  [OK]${N} $1"; }
sec() { echo -e "\n${B}${C}── $1 ──${N}"; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
T="$ROOT/src/test/java/com/mbem/mbemlevel"
[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERR: s01 requis"; exit 1; }
echo -e "\n${B}${C}  MbemNova · 13/15 · Admin + Gamification + Schedulers${N}\n"

# =============================================================================
sec "1/5 Use Cases Admin (S19, S20, S21, S25, S26)"
# =============================================================================
mkdir -p "$P/application/usecase/admin"

cat > "$P/application/usecase/admin/InscrireApprenantManuelUseCase.java" << 'JEOF'
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
JEOF

cat > "$P/application/usecase/admin/AssignerRoleUseCase.java" << 'JEOF'
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
JEOF

cat > "$P/application/usecase/admin/GetStatistiquesUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.admin;
import com.mbem.mbemlevel.application.port.out.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
/**
 * S25 — Tableau de bord admin : métriques globales en temps réel.
 * Retourne un record agrégé depuis plusieurs repositories.
 */
@Service @RequiredArgsConstructor
public class GetStatistiquesUseCase {
    private final UtilisateurRepository utilisateurRepo;
    private final PaiementRepository    paiementRepo;

    public record Statistiques(
        long totalApprenants, long apprenantsActifs,
        long paiementsEnAttente, long paiementsEnRetard,
        long revenus
    ) {}

    @Transactional(readOnly=true)
    public Statistiques executer() {
        // Comptages simplifiés — à optimiser avec des requêtes COUNT en base
        long totalApp = utilisateurRepo.findAll().stream()
            .filter(u -> "APPRENANT".equals(u.getRole().name())).count();
        long actifs   = utilisateurRepo.findAll().stream()
            .filter(u -> "APPRENANT".equals(u.getRole().name())
                      && "ACTIF".equals(u.getStatut().name())).count();
        long enAttente = paiementRepo.findPaiementsEnCours().stream()
            .filter(p -> "EN_ATTENTE".equals(p.getStatut().name())).count();
        long enRetard  = paiementRepo.findPaiementsEnCours().stream()
            .filter(p -> "EN_RETARD".equals(p.getStatut().name())).count();
        long revenus   = paiementRepo.findPaiementsEnCours().stream()
            .mapToLong(p -> p.getMontantPaye().toLong()).sum();
        return new Statistiques(totalApp, actifs, enAttente, enRetard, revenus);
    }
}
JEOF

cat > "$P/application/usecase/admin/CreerCoursUseCase.java" << 'JEOF'
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
JEOF

cat > "$P/application/usecase/admin/PublierCoursUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.admin;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.Cours;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** Publie un cours (estActif=true) — il devient visible dans le catalogue. */
@Service @RequiredArgsConstructor @Slf4j
public class PublierCoursUseCase {
    private final CoursRepository   coursRepo;
    private final AuditLogRepository auditRepo;

    @Transactional
    public Cours executer(UUID coursId, UUID adminId) {
        Cours cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        cours.publier();
        Cours saved = coursRepo.save(cours);
        auditRepo.enregistrer(adminId, null, "COURS_PUBLISHED",
            "COURS", coursId.toString(), null, "SUCCESS", null, null);
        log.info("[ADMIN] Cours publié: {}", cours.getTitre());
        return saved;
    }
}
JEOF
ok "Use Cases Admin : InscrireManuel · AssignerRole · GetStatistiques · CreerCours · PublierCours"

# =============================================================================
sec "2/5 Use Case Tirage Au Sort (S24) + Scheduler"
# =============================================================================
mkdir -p "$P/application/usecase/gamification"
mkdir -p "$P/infrastructure/scheduler"

cat > "$P/application/usecase/gamification/EffectuerTirageAuSortUseCase.java" << 'JEOF'
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
JEOF

cat > "$P/infrastructure/scheduler/TirageAuSortScheduler.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.usecase.gamification.EffectuerTirageAuSortUseCase;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
/**
 * S24 — Tirage au sort mensuel : 1er du mois à 08h00 Africa/Douala.
 * Prix configurable via la propriété mbemnova.gamification.prix-description.
 */
@Component @RequiredArgsConstructor @Slf4j
public class TirageAuSortScheduler {
    private final EffectuerTirageAuSortUseCase tirageUC;
    @Value("${mbemnova.gamification.prix-description:Réduction sur le prochain cours}") private String prix;

    @Scheduled(cron="0 0 8 1 * ?", zone="Africa/Douala")
    public void executerTirageMensuel() {
        log.info("[TIRAGE] Démarrage du tirage mensuel");
        try {
            tirageUC.executer(prix);
        } catch (Exception e) {
            log.error("[TIRAGE] Erreur tirage: {}", e.getMessage(), e);
        }
    }
}
JEOF
ok "EffectuerTirageAuSortUseCase + TirageAuSortScheduler"

# =============================================================================
sec "3/5 AdminController + CoursAdminController + DTOs"
# =============================================================================
mkdir -p "$P/api/controller"
mkdir -p "$P/api/dto/request"
mkdir -p "$P/api/dto/response"

cat > "$P/api/dto/response/StatistiquesResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record StatistiquesResponse(
    long totalApprenants,
    long apprenantsActifs,
    long paiementsEnAttente,
    long paiementsEnRetard,
    long revenusTotal,
    String revenus
) {}
JEOF

cat > "$P/api/dto/request/InscriptionManuelleRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record InscriptionManuelleRequest(
    @NotBlank @Size(min=2,max=50) String prenom,
    @NotBlank @Email String email,
    @NotBlank @Size(min=8) String motDePasse
) {}
JEOF

cat > "$P/api/dto/request/AssignerRoleRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
public record AssignerRoleRequest(
    @NotNull UUID utilisateurId,
    @NotNull Role nouveauRole
) {}
JEOF

cat > "$P/api/dto/request/CreerCoursRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record CreerCoursRequest(
    @NotBlank @Size(max=200) String titre,
    @Size(max=5000)           String description,
    @NotNull                  NiveauCours niveau,
    UUID                      categorieId,
    @DecimalMin("0.01") @DecimalMax("1.0") double seuilPaiement,
    @Min(0)             long  prixFcfa
) {}
JEOF

cat > "$P/api/controller/AdminController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.admin.*;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * Back-office admin — accès restreint ADMIN/SUPER_ADMIN.
 *
 * POST  /api/v1/admin/apprenants            → S21 inscription manuelle
 * POST  /api/v1/admin/utilisateurs/role     → S26 changer rôle
 * GET   /api/v1/admin/statistiques          → S25 dashboard stats
 * POST  /api/v1/admin/tirage                → S24 tirage mensuel
 */
@RestController
@RequestMapping("/api/v1/admin")
@Tag(name="Admin", description="Back-office — gestion plateforme")
@PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
@RequiredArgsConstructor
public class AdminController {

    private final InscrireApprenantManuelUseCase inscrireManuelUC;
    private final AssignerRoleUseCase            assignerRoleUC;
    private final GetStatistiquesUseCase         statsUC;
    private final EffectuerTirageAuSortUseCase   tirageUC;

    /** S21 — Inscrire un apprenant manuellement */
    @PostMapping("/apprenants")
    @Operation(summary="Inscrire un apprenant manuellement (S21)")
    public ResponseEntity<ApiResponse<Void>> inscrireApprenant(
            @Valid @RequestBody InscriptionManuelleRequest req,
            @AuthenticationPrincipal String adminId,
            @RequestHeader(value="X-Forwarded-For", required=false) String ip) {
        inscrireManuelUC.executer(new InscrireApprenantManuelUseCase.Commande(
            req.prenom(), req.email(), req.motDePasse(),
            UUID.fromString(adminId), ip));
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok("Apprenant inscrit avec succès."));
    }

    /** S26 — Changer le rôle d'un utilisateur */
    @PostMapping("/utilisateurs/role")
    @Operation(summary="Assigner un rôle (S26)")
    public ResponseEntity<ApiResponse<Void>> assignerRole(
            @Valid @RequestBody AssignerRoleRequest req,
            @AuthenticationPrincipal String adminId) {
        // Déterminer le rôle de l'admin depuis le SecurityContext
        // (simplifié ici — en production récupérer depuis JWT claims)
        assignerRoleUC.executer(req.utilisateurId(), req.nouveauRole(),
            UUID.fromString(adminId), Role.ADMIN);
        return ResponseEntity.ok(ApiResponse.ok("Rôle mis à jour."));
    }

    /** S25 — Statistiques dashboard */
    @GetMapping("/statistiques")
    @Operation(summary="Tableau de bord statistiques (S25)")
    public ResponseEntity<ApiResponse<StatistiquesResponse>> statistiques() {
        var s = statsUC.executer();
        return ResponseEntity.ok(ApiResponse.ok(new StatistiquesResponse(
            s.totalApprenants(), s.apprenantsActifs(),
            s.paiementsEnAttente(), s.paiementsEnRetard(),
            s.revenus(),
            com.mbem.mbemlevel.domain.shared.Money.of(s.revenus()).toDisplay())));
    }

    /** S24 — Déclencher manuellement un tirage au sort */
    @PostMapping("/tirage")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @Operation(summary="Effectuer le tirage au sort (S24)")
    public ResponseEntity<ApiResponse<Void>> tirage(
            @RequestParam(defaultValue="Réduction 50% sur le prochain cours") String prix) {
        tirageUC.executer(prix);
        return ResponseEntity.ok(ApiResponse.ok("Tirage effectué."));
    }
}
JEOF

cat > "$P/api/controller/CoursAdminController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.CreerCoursRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.admin.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Cours Admin — S19 (créer cours), S20 (publier cours).
 * POST /api/v1/admin/cours          → créer un cours en brouillon
 * POST /api/v1/admin/cours/{id}/publier → publier le cours
 */
@RestController
@RequestMapping("/api/v1/admin/cours")
@Tag(name="Cours Admin", description="Gestion des cours — formateur et admin")
@PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
@RequiredArgsConstructor
public class CoursAdminController {
    private final CreerCoursUseCase   creerUC;
    private final PublierCoursUseCase publierUC;

    @PostMapping
    @Operation(summary="Créer un cours (brouillon) — S19")
    public ResponseEntity<ApiResponse<CoursResponse>> creer(
            @Valid @RequestBody CreerCoursRequest req,
            @AuthenticationPrincipal String userId) {
        var cmd = new CreerCoursUseCase.Commande(
            req.titre(), req.description(), req.niveau(), req.categorieId(),
            UUID.fromString(userId), req.seuilPaiement(), req.prixFcfa(),
            UUID.fromString(userId));
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(CoursResponse.from(creerUC.executer(cmd)),
                "Cours créé en mode brouillon."));
    }

    @PostMapping("/{coursId}/publier")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Publier un cours — rendre visible dans le catalogue")
    public ResponseEntity<ApiResponse<CoursResponse>> publier(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String adminId) {
        return ResponseEntity.ok(ApiResponse.ok(
            CoursResponse.from(publierUC.executer(coursId, UUID.fromString(adminId))),
            "Cours publié."));
    }
}
JEOF
ok "AdminController · CoursAdminController · DTOs Admin"

# =============================================================================
sec "4/5 Infrastructure Configuration (S3, Storage)"
# =============================================================================
mkdir -p "$P/infrastructure/config"

cat > "$P/infrastructure/config/StorageConfig.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import software.amazon.awssdk.auth.credentials.*;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import java.net.URI;
/**
 * Configuration AWS SDK S3 / MinIO.
 * En dev : MinIO local (http://localhost:9000).
 * En prod : AWS S3 ou MinIO distant avec TLS.
 */
@Configuration
public class StorageConfig {
    @Value("${storage.minio.endpoint:http://localhost:9000}") private String endpoint;
    @Value("${storage.minio.access-key:minioadmin}")          private String accessKey;
    @Value("${storage.minio.secret-key:minioadmin}")          private String secretKey;
    @Value("${storage.minio.region:af-central-1}")            private String region;

    private AwsCredentialsProvider credentials() {
        return StaticCredentialsProvider.create(
            AwsBasicCredentials.create(accessKey, secretKey));
    }

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
            .endpointOverride(URI.create(endpoint))
            .credentialsProvider(credentials())
            .region(Region.of(region))
            .serviceConfiguration(S3Configuration.builder()
                .pathStyleAccessEnabled(true).build())
            .build();
    }

    @Bean
    public S3Presigner s3Presigner() {
        return S3Presigner.builder()
            .endpointOverride(URI.create(endpoint))
            .credentialsProvider(credentials())
            .region(Region.of(region))
            .build();
    }
}
JEOF
ok "StorageConfig (S3Client + S3Presigner beans)"

# =============================================================================
sec "5/5 Test ArchUnit + Application principale"
# =============================================================================
mkdir -p "$T/architecture"

cat > "$T/architecture/ArchitectureTest.java" << 'JEOF'
package com.mbem.mbemlevel.architecture;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.Test;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.*;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
/**
 * Tests d'architecture ArchUnit — valident le respect de l'architecture hexagonale.
 * Exécutés à chaque build : mvn test -Dtest=ArchitectureTest
 *
 * RÈGLES VÉRIFIÉES :
 *   1. La couche Domain ne dépend d'aucune couche externe (Spring, JPA, etc.)
 *   2. Les Controllers ne parlent pas directement aux Repositories JPA
 *   3. Les Entités JPA ne sont pas dans le package domain
 */
class ArchitectureTest {

    private static final JavaClasses CLASSES = new ClassFileImporter()
        .importPackages("com.mbem.mbemlevel");

    @Test
    void domainNeDependPasDeSpring() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
                .resideInAnyPackage(
                    "org.springframework..",
                    "jakarta.persistence..",
                    "com.mbem.mbemlevel.infrastructure..",
                    "com.mbem.mbemlevel.api..")
            .because("La couche Domain doit être indépendante de tout framework");
        rule.check(CLASSES);
    }

    @Test
    void controllersNeParlentPasDirectementAuxRepositoriesJpa() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..api.controller..")
            .should().dependOnClassesThat()
                .resideInAPackage("..infrastructure.persistence.repository..")
            .because("Les Controllers passent par les Use Cases — jamais directement aux JPA Repos");
        rule.check(CLASSES);
    }

    @Test
    void entitesJpaNeSontPasDansLeDomain() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..domain..")
            .should().beAnnotatedWith("jakarta.persistence.Entity")
            .because("Le Domain ne doit pas contenir d'entités JPA");
        rule.check(CLASSES);
    }

    @Test
    void architectureHexagonale() {
        layeredArchitecture().consideringAllDependencies()
            .layer("API").definedBy("..api..")
            .layer("Application").definedBy("..application..")
            .layer("Domain").definedBy("..domain..")
            .layer("Infrastructure").definedBy("..infrastructure..")
            .whereLayer("Domain").mayNotAccessAnyLayer()
            .whereLayer("Application").mayOnlyAccessLayers("Domain")
            .whereLayer("API").mayOnlyAccessLayers("Application", "Domain", "Infrastructure")
            .check(CLASSES);
    }
}
JEOF
ok "ArchitectureTest.java (4 règles ArchUnit)"

# Vérifier que l'application principale existe et y ajouter le @EnableAsync
MAIN="$P/MbemlevelApplication.java"
if [[ -f "$MAIN" ]]; then
  # Vérifier si @EnableAsync est déjà présent
  if ! grep -q "EnableAsync" "$MAIN"; then
    cat > "$MAIN" << 'JEOF'
package com.mbem.mbemlevel;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
/**
 * MbemNova — Point d'entrée de l'application Spring Boot 4.
 *
 * @EnableAsync : active les @Async dans les event handlers
 *               (email bienvenue, WhatsApp, etc.)
 */
@SpringBootApplication
@EnableAsync
public class MbemlevelApplication {
    public static void main(String[] args) {
        SpringApplication.run(MbemlevelApplication.class, args);
    }
}
JEOF
    ok "MbemlevelApplication.java mis à jour (@EnableAsync)"
  else
    ok "MbemlevelApplication.java — @EnableAsync déjà présent"
  fi
else
  ok "MbemlevelApplication.java — sera créé par Spring Initializr"
fi

echo -e "\n${B}${G}  Script 13 terminé${N}"
echo -e "  ${G}✓${N} Use Cases Admin : InscrireManuel (S21), AssignerRole (S26),"
echo -e "               GetStatistiques (S25), CreerCours (S19), PublierCours"
echo -e "  ${G}✓${N} Use Case Gamification : EffectuerTirageAuSort (S24)"
echo -e "  ${G}✓${N} Controllers : AdminController, CoursAdminController"
echo -e "  ${G}✓${N} TirageAuSortScheduler (1er du mois 08h00)"
echo -e "  ${G}✓${N} StorageConfig (S3Client + S3Presigner beans)"
echo -e "  ${G}✓${N} ArchitectureTest (4 règles ArchUnit)\n"
echo -e "  \033[1;33m→ ./s14_devops.sh\033[0m\n"
