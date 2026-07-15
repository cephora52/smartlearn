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
    private final ProgressionJpaRepository progressionRepo;
    private final com.mbem.mbemlevel.infrastructure.persistence.repository.XpHistoriqueJpaRepository xpHistoriqueRepo;

    private boolean checkEstPaye(UUID apprenantId, UUID coursId) {
        return progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .map(ProgressionJpaEntity::isEstPaye)
            .orElse(false);
    }

    private List<Integer> getXpParJour(UUID apprenantId) {
        java.time.LocalDateTime limit = java.time.LocalDate.now().minusDays(6).atStartOfDay();
        List<com.mbem.mbemlevel.infrastructure.persistence.entity.XpHistoriqueJpaEntity> logs = 
            xpHistoriqueRepo.findByApprenantIdAndDateGainAfter(apprenantId, limit);
        
        List<Integer> result = new ArrayList<>();
        java.time.LocalDate today = java.time.LocalDate.now();
        for (int i = 6; i >= 0; i--) {
            java.time.LocalDate targetDate = today.minusDays(i);
            int sum = logs.stream()
                .filter(log -> log.getDateGain().toLocalDate().isEqual(targetDate))
                .mapToInt(com.mbem.mbemlevel.infrastructure.persistence.entity.XpHistoriqueJpaEntity::getXpGagne)
                .sum();
            result.add(sum);
        }
        return result;
    }

    @GetMapping("/{apprenantId}")
    @Operation(summary="Profil talent d'un apprenant (S14)")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> profil(
            @PathVariable UUID apprenantId) {
        var data = getProfilUC.executer(apprenantId);
        List<CertificatResponse> certs = data.certificats().stream()
            .map(c -> {
                boolean estPaye = checkEstPaye(apprenantId, c.getCoursId());
                return CertificatResponse.from(c, estPaye);
            }).collect(Collectors.toList());
        List<Integer> xpParJour = getXpParJour(apprenantId);
        return ResponseEntity.ok(ApiResponse.ok(
            ProfilTalentResponse.from(data.utilisateur(), certs, xpParJour)));
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary="Mon profil talent")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> monProfil(
            @AuthenticationPrincipal String userId) {
        var data = getProfilUC.executer(UUID.fromString(userId));
        List<CertificatResponse> certs = data.certificats().stream()
            .map(c -> {
                boolean estPaye = checkEstPaye(UUID.fromString(userId), c.getCoursId());
                return CertificatResponse.from(c, estPaye);
            }).collect(Collectors.toList());
        List<Integer> xpParJour = getXpParJour(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(
            ProfilTalentResponse.from(data.utilisateur(), certs, xpParJour)));
    }
}
