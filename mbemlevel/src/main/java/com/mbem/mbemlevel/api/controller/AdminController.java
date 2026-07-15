package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.admin.*;
import com.mbem.mbemlevel.application.usecase.gamification.EffectuerTirageAuSortUseCase;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import com.mbem.mbemlevel.application.port.out.StoragePort;
import com.mbem.mbemlevel.api.dto.response.PageResponse;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
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
    private final UtilisateurJpaRepository       utilisateurJpaRepo;
    private final CoursJpaRepository             coursJpaRepo;
    private final StoragePort                    storagePort;

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
            s.formateursActifs(), s.totalFormations(),
            s.paiementsEnAttente())));
    }

    /** S24 — Déclencher manuellement un tirage au sort */
    @PostMapping("/tirage")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @Operation(summary="Effectuer le tirage au sort (S24)")
    public ResponseEntity<ApiResponse<Void>> tirage(
            @RequestParam(defaultValue="Réduction 50% sur le prochain cours") String prix,
            @AuthenticationPrincipal String adminId) {
        tirageUC.executer(prix, UUID.fromString(adminId));
        return ResponseEntity.ok(ApiResponse.ok("Tirage effectué."));
    }

    /** Lister tous les apprenants (S21) */
    @GetMapping("/apprenants")
    @Operation(summary="Lister tous les apprenants (S21)")
    public ResponseEntity<ApiResponse<PageResponse<AdminUtilisateurResponse>>> getApprenants() {
        var all = utilisateurJpaRepo.findAll().stream()
            .filter(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.APPRENANT)
            .toList();
        var content = all.stream()
            .map(u -> new AdminUtilisateurResponse(
                u.getId(), u.getPrenom(), u.getNom(), u.getEmail(),
                u.getTelephone(), u.getStatut().name(), u.getXpTotal(),
                u.getCreatedAt().toString()))
            .toList();
        var page = new PageResponse<>(content, 0, 100, content.size(), 1, true);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    /** Lister tous les formateurs */
    @GetMapping("/formateurs")
    @Operation(summary="Lister tous les formateurs")
    public ResponseEntity<ApiResponse<PageResponse<AdminUtilisateurResponse>>> getFormateurs() {
        var all = utilisateurJpaRepo.findAll().stream()
            .filter(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.FORMATEUR)
            .toList();
        var content = all.stream()
            .map(u -> new AdminUtilisateurResponse(
                u.getId(), u.getPrenom(), u.getNom(), u.getEmail(),
                u.getTelephone(), u.getStatut().name(), u.getXpTotal(),
                u.getCreatedAt().toString()))
            .toList();
        var page = new PageResponse<>(content, 0, 100, content.size(), 1, true);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    /** Lister toutes les formations */
    @GetMapping("/formations")
    @Operation(summary="Lister toutes les formations")
    public ResponseEntity<ApiResponse<PageResponse<CoursResponse>>> getFormations() {
        var all = coursJpaRepo.findAll();
        var content = all.stream()
            .map(e -> CoursResponse.fromEntity(e, storagePort))
            .toList();
        var page = new PageResponse<>(content, 0, 100, content.size(), 1, true);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    public record AdminUtilisateurResponse(
        UUID id,
        String prenom,
        String nom,
        String email,
        String telephone,
        String statut,
        long xpTotal,
        String inscritLe
    ) {}
}
