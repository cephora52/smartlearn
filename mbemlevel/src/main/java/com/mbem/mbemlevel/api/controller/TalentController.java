package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.stream.Collectors;
/**
 * API Talent — S14 (profil apprenant public pour recruteurs).
 * GET /api/v1/talents        → liste apprenants disponibles
 * GET /api/v1/talents/{id}   → profil public d'un apprenant
 * GET /api/v1/talents/me     → mon profil
 */
@RestController
@RequestMapping("/api/v1/talents")
@Tag(name="Talent", description="Profils publics des apprenants pour recruteurs")
@RequiredArgsConstructor
public class TalentController {
    private final GetProfilTalentUseCase getProfilUC;
    private final UtilisateurListAdapter utilisateurAdapter;

    @GetMapping("/{apprenantId}")
    @Operation(summary="Profil talent d'un apprenant (S14)")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> profil(
            @PathVariable UUID apprenantId) {
        var data = getProfilUC.executer(apprenantId);
        List<CertificatResponse> certs = data.certificats().stream()
            .map(CertificatResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(
            ProfilTalentResponse.from(data.utilisateur(), certs)));
    }

    @GetMapping("/me")
    @Operation(summary="Mon profil talent")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> monProfil(
            @AuthenticationPrincipal String userId) {
        var data = getProfilUC.executer(UUID.fromString(userId));
        List<CertificatResponse> certs = data.certificats().stream()
            .map(CertificatResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(
            ProfilTalentResponse.from(data.utilisateur(), certs)));
    }
}
