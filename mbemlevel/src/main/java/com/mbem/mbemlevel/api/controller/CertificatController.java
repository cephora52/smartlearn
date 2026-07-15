package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Certificats — S13 (émission), vérification publique.
 * POST /api/v1/certificats/cours/{coursId}/generer → génère le certificat
 * GET  /api/v1/certificats/verify/{code}           → vérification publique
 */
@RestController
@RequestMapping("/api/v1/certificats")
@Tag(name="Certificat", description="Émission et vérification de certificats")
@RequiredArgsConstructor
public class CertificatController {
    private final GenererCertificatUseCase  genererUC;
    private final VerifierCertificatUseCase verifierUC;
    private final ProgressionJpaRepository  progressionRepo;
    private final com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository coursJpaRepo;

    private boolean checkEstPaye(UUID apprenantId, UUID coursId) {
        boolean isGratuit = coursJpaRepo.findById(coursId)
            .map(c -> c.getPrixFcfa() == 0)
            .orElse(false);
        if (isGratuit) {
            return true;
        }
        return progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .map(ProgressionJpaEntity::isEstPaye)
            .orElse(false);
    }

    @PostMapping("/cours/{coursId}/generer")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary="Générer mon certificat pour un cours (S13)")
    public ResponseEntity<ApiResponse<CertificatResponse>> generer(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        var cert = genererUC.executer(UUID.fromString(userId), coursId);
        boolean estPaye = checkEstPaye(UUID.fromString(userId), coursId);
        return ResponseEntity.ok(ApiResponse.ok(
            CertificatResponse.from(cert, estPaye), "Certificat généré !"));
    }

    @GetMapping("/verify/{code}")
    @Operation(summary="Vérifier l'authenticité d'un certificat (public)")
    public ResponseEntity<ApiResponse<CertificatResponse>> verifier(
            @PathVariable String code) {
        return verifierUC.executer(code)
            .map(c -> {
                boolean estPaye = checkEstPaye(c.getApprenantId(), c.getCoursId());
                return ResponseEntity.ok(ApiResponse.ok(CertificatResponse.from(c, estPaye),
                    "Certificat authentique."));
            })
            .orElse(ResponseEntity.ok(ApiResponse.err(
                "Certificat non trouvé.", "CERT_NOT_FOUND")));
    }
}
