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
            @RequestParam(defaultValue="Réduction 50% sur le prochain cours") String prix,
            @AuthenticationPrincipal String adminId) {
        tirageUC.executer(prix, UUID.fromString(adminId));
        return ResponseEntity.ok(ApiResponse.ok("Tirage effectué."));
    }
}
