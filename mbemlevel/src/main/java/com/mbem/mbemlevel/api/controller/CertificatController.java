package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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

    @PostMapping("/cours/{coursId}/generer")
    @Operation(summary="Générer mon certificat pour un cours (S13)")
    public ResponseEntity<ApiResponse<CertificatResponse>> generer(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        var cert = genererUC.executer(UUID.fromString(userId), coursId);
        return ResponseEntity.ok(ApiResponse.ok(
            CertificatResponse.from(cert), "Certificat généré !"));
    }

    @GetMapping("/verify/{code}")
    @Operation(summary="Vérifier l'authenticité d'un certificat (public)")
    public ResponseEntity<ApiResponse<CertificatResponse>> verifier(
            @PathVariable String code) {
        return verifierUC.executer(code)
            .map(c -> ResponseEntity.ok(ApiResponse.ok(CertificatResponse.from(c),
                "Certificat authentique.")))
            .orElse(ResponseEntity.ok(ApiResponse.err(
                "Certificat non trouvé.", "CERT_NOT_FOUND")));
    }
}
