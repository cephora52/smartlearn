package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.TerminerLeconRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.progression.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.repository.PaiementJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.MoratoireJpaRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
/**
 * API Progression — S05 (commencer), S06 (leçon+QCM), S07 (seuil).
 * Tous les endpoints nécessitent une authentification.
 */
@RestController
@RequestMapping("/api/v1/progression")
@Tag(name="Progression", description="Avancement dans les cours")
@PreAuthorize("hasRole('APPRENANT')")
@RequiredArgsConstructor
public class ProgressionController {
    private final CommencerCoursUseCase  commencerUC;
    private final TerminerLeconUseCase   terminerLeconUC;
    private final GetProgressionUseCase  getUC;
    private final PaiementJpaRepository  paiementRepo;
    private final MoratoireJpaRepository moratoireRepo;
    private final ValiderQuizFinalXpUseCase validerQuizFinalXpUC;

    private ProgressionResponse mapToResponse(Progression p, UUID apprenantId) {
        boolean aMor = paiementRepo.findByApprenantIdAndCoursId(apprenantId, p.getCoursId())
            .map(pay -> moratoireRepo.existsByPaiementIdAndStatut(pay.getId(), "APPROUVE")
                   || moratoireRepo.existsByPaiementIdAndStatut(pay.getId(), "ACCORDE"))
            .orElse(false);
        return new ProgressionResponse(p.getId(), p.getCoursId(), p.getPourcentage(),
            p.isEstPaye(), p.getXpGagne(), p.seuilAtteint() && !aMor, p.estTermine(),
            p.getDateDebut(), p.getDateCompletion());
    }

    /** POST /api/v1/progression/cours/{coursId}/commencer — S05 */
    @PostMapping("/cours/{coursId}/commencer")
    @Operation(summary="Commencer ou reprendre un cours (S05)")
    public ResponseEntity<ApiResponse<ProgressionResponse>> commencer(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        Progression p = commencerUC.executer(UUID.fromString(userId), coursId);
        return ResponseEntity.ok(ApiResponse.ok(mapToResponse(p, UUID.fromString(userId)), "Cours commencé !"));
    }

    /** POST /api/v1/progression/cours/{coursId}/terminer-lecon — S06 */
    @PostMapping("/cours/{coursId}/terminer-lecon")
    @Operation(summary="Marquer une leçon terminée — calcule XP et progression (S06)")
    public ResponseEntity<ApiResponse<ProgressionResponse>> terminerLecon(
            @PathVariable UUID coursId,
            @Valid @RequestBody TerminerLeconRequest req,
            @AuthenticationPrincipal String userId,
            @RequestHeader(value="X-User-Prenom", defaultValue="Apprenant") String prenom,
            @RequestHeader(value="X-User-Email",  defaultValue="") String email) {
        Progression p = terminerLeconUC.executer(
            UUID.fromString(userId), coursId, req.leconId(),
            req.nbLeconsTotales(), req.nbLeconsTerminees(), req.xpLecon(),
            prenom, email, req.telephone(), req.nomCours());
        boolean aMor = paiementRepo.findByApprenantIdAndCoursId(UUID.fromString(userId), coursId)
            .map(pay -> moratoireRepo.existsByPaiementIdAndStatut(pay.getId(), "APPROUVE")
                   || moratoireRepo.existsByPaiementIdAndStatut(pay.getId(), "ACCORDE"))
            .orElse(false);
        String msg = p.seuilAtteint() && !p.isEstPaye() && !aMor
            ? "Seuil atteint ! Débloquez la suite." : "+"+req.xpLecon()+" XP gagnés !";
        return ResponseEntity.ok(ApiResponse.ok(mapToResponse(p, UUID.fromString(userId)), msg));
    }

    /** GET /api/v1/progression — Toutes les progressions de l'apprenant */
    @GetMapping
    @Operation(summary="Toutes les progressions de l'apprenant connecté")
    public ResponseEntity<ApiResponse<List<ProgressionResponse>>> mesPrgressions(
            @AuthenticationPrincipal String userId) {
        List<ProgressionResponse> list = getUC.toutesParApprenant(UUID.fromString(userId))
            .stream().map(p -> mapToResponse(p, UUID.fromString(userId))).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    /** GET /api/v1/progression/cours/{coursId} — Progression sur un cours */
    @GetMapping("/cours/{coursId}")
    @Operation(summary="Progression sur un cours spécifique")
    public ResponseEntity<ApiResponse<ProgressionResponse>> parCours(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        return getUC.parCoursId(UUID.fromString(userId), coursId)
            .map(p -> ResponseEntity.ok(ApiResponse.ok(mapToResponse(p, UUID.fromString(userId)))))
            .orElse(ResponseEntity.notFound().build());
    }

    /** POST /api/v1/progression/cours/{coursId}/final-quiz-xp */
    @PostMapping("/cours/{coursId}/final-quiz-xp")
    @Operation(summary="Valider le quiz final et attribuer les 50 XP")
    public ResponseEntity<ApiResponse<ProgressionResponse>> validerQuizFinalXp(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        Progression p = validerQuizFinalXpUC.executer(UUID.fromString(userId), coursId);
        return ResponseEntity.ok(ApiResponse.ok(mapToResponse(p, UUID.fromString(userId)), "Quiz final validé, +50 XP !"));
    }
}
