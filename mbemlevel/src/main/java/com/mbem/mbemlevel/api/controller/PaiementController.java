package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.EnregistrerPaiementRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.paiement.*;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import java.util.List;
import java.util.UUID;
/**
 * API Paiement — S08 (paiement cash), S18 (suspension).
 * POST /api/v1/paiements          → Admin enregistre paiement
 * POST /api/v1/paiements/{id}/suspendre → Suspension
 * POST /api/v1/paiements/{id}/reactiver → Réactivation
 */
@RestController
@RequestMapping("/api/v1/paiements")
@Tag(name="Paiement", description="Gestion des paiements et accès aux cours")
@RequiredArgsConstructor
public class PaiementController {
    private final EnregistrerPaiementCashUseCase enregistrerUC;
    private final SuspendreCompteUseCase         suspendreUC;
    private final ReactiverCompteUseCase         reactiverUC;
    private final GetPaiementsEnRetardUseCase    enRetardUC;
    private final PaiementRepository             paiementRepo;

    /** POST /api/v1/paiements — Admin enregistre paiement cash (S08) */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Enregistrer un paiement et activer l'accès (S08)")
    public ResponseEntity<ApiResponse<PaiementResponse>> enregistrer(
            @Valid @RequestBody EnregistrerPaiementRequest req,
            @AuthenticationPrincipal String adminId) {
        var cmd = new EnregistrerPaiementCashUseCase.Commande(
            req.apprenantId(), req.coursId(), req.montantTotal(),
            req.montantPremiereTranche(), req.nbTranches(), req.mode(),
            UUID.fromString(adminId), req.prenomApprenant(),
            req.emailApprenant(), req.telephoneApprenant(), req.nomCours());
        Paiement p = enregistrerUC.executer(cmd);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(PaiementResponse.from(p), "Paiement enregistré. Accès activé."));
    }

    /** POST /api/v1/paiements/apprenants/{id}/suspendre */
    @PostMapping("/apprenants/{apprenantId}/suspendre")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Suspendre un compte apprenant (S18)")
    public ResponseEntity<ApiResponse<Void>> suspendre(
            @PathVariable UUID apprenantId,
            @RequestParam(defaultValue="Retard de paiement.") String message,
            @AuthenticationPrincipal String adminId) {
        suspendreUC.executer(apprenantId, UUID.fromString(adminId), message);
        return ResponseEntity.ok(ApiResponse.ok("Compte suspendu."));
    }

    /** POST /api/v1/paiements/apprenants/{id}/reactiver */
    @PostMapping("/apprenants/{apprenantId}/reactiver")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Réactiver un compte après paiement régularisé")
    public ResponseEntity<ApiResponse<Void>> reactiver(
            @PathVariable UUID apprenantId,
            @AuthenticationPrincipal String adminId) {
        reactiverUC.executer(apprenantId, UUID.fromString(adminId));
        return ResponseEntity.ok(ApiResponse.ok("Compte réactivé."));
    }

    /** GET /api/v1/paiements — Admin consulte tous les paiements */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Lister tous les paiements (admin)")
    public ResponseEntity<ApiResponse<List<PaiementResponse>>> obtenirTous() {
        List<PaiementResponse> list = paiementRepo.findAll().stream()
            .map(PaiementResponse::from)
            .toList();
        return ResponseEntity.ok(ApiResponse.ok(list));
    }
}
