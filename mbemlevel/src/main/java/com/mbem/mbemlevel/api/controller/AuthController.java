package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.dto.request.*;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.usecase.auth.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * Endpoints d'authentification MbemNova.
 * Scénarios couverts : 02 (inscription), 03 (connexion), 27 (reset MDP).
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentification", description = "Inscription, connexion, tokens, reset MDP")
@RequiredArgsConstructor
public class AuthController {

    private final InscrireApprenantUseCase       inscrireUC;
    private final ConnecterUtilisateurUseCase    connecterUC;
    private final RefreshTokenUseCase            refreshUC;
    private final DeconnecterUseCase             deconnecterUC;
    private final ReinitialiserMotDePasseUseCase resetMdpUC;
    private final ConfirmerEmailUseCase          confirmerEmailUC;
    private final RenouvellerConfirmationEmailUseCase renouvellerConfirmationUC;

    /** POST /api/v1/auth/register — Scénario 02 */
    @PostMapping("/register")
    @Operation(summary = "Créer un compte apprenant")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody InscriptionRequest req, HttpServletRequest httpReq) {
        AuthResultDto result = inscrireUC.executer(
            new InscriptionCommand(req.prenom(), req.email(), req.motDePasse(),
                getIp(httpReq), httpReq.getHeader("User-Agent")));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(toAuthResponse(result), "Compte créé ! Vérifiez votre email pour activer votre accès."));
    }

    /** POST /api/v1/auth/login — Scénario 03 */
    @PostMapping("/login")
    @Operation(summary = "Se connecter")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody ConnexionRequest req, HttpServletRequest httpReq) {
        AuthResultDto result = connecterUC.executer(
            new ConnexionCommand(req.email(), req.motDePasse(), req.rememberMe(),
                getIp(httpReq), httpReq.getHeader("User-Agent")));
        return ResponseEntity.ok(ApiResponse.ok(toAuthResponse(result), "Connexion réussie."));
    }

    /** POST /api/v1/auth/refresh */
    @PostMapping("/refresh")
    @Operation(summary = "Rafraîchir le JWT")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshTokenRequest req, HttpServletRequest httpReq) {
        AuthResultDto result = refreshUC.executer(req.refreshToken(),
            getIp(httpReq), httpReq.getHeader("User-Agent"));
        return ResponseEntity.ok(ApiResponse.ok(toAuthResponse(result)));
    }

    /** POST /api/v1/auth/logout */
    @PostMapping("/logout")
    @Operation(summary = "Se déconnecter")
    public ResponseEntity<ApiResponse<Void>> logout(
            HttpServletRequest httpReq,
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) RefreshTokenRequest body,
            @AuthenticationPrincipal String userId) {
        String accessToken  = authHeader != null && authHeader.startsWith("Bearer ")
            ? authHeader.substring(7) : null;
        String refreshToken = body != null ? body.refreshToken() : null;
        String email        = httpReq.getUserPrincipal() != null ? httpReq.getUserPrincipal().getName() : "";
        deconnecterUC.executer(
            userId != null ? UUID.fromString(userId) : null,
            email, accessToken, refreshToken);
        return ResponseEntity.ok(ApiResponse.ok("Déconnexion réussie."));
    }

    /** POST /api/v1/auth/reset-password — Étape 1 : demander le lien (Scénario 27) */
    @PostMapping("/reset-password")
    @Operation(summary = "Demander la réinitialisation du mot de passe")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest req, HttpServletRequest httpReq) {
        // Toujours retourner 200 même si l'email n'existe pas (anti-énumération)
        resetMdpUC.demanderReset(req.email(), getIp(httpReq));
        return ResponseEntity.ok(ApiResponse.ok(
            "Si cet email est enregistré, vous recevrez un lien sous 5 minutes."));
    }

    /** POST /api/v1/auth/new-password — Étape 2 : confirmer le nouveau MDP */
    @PostMapping("/new-password")
    @Operation(summary = "Définir le nouveau mot de passe")
    public ResponseEntity<ApiResponse<Void>> newPassword(
            @Valid @RequestBody NouveauMotDePasseRequest req) {
        resetMdpUC.confirmerReset(req.token(), req.nouveauMotDePasse());
        return ResponseEntity.ok(ApiResponse.ok("Mot de passe mis à jour. Reconnectez-vous."));
    }

    /** GET /api/v1/auth/confirm-email?token=xxx */
    @GetMapping("/confirm-email")
    @Operation(summary = "Vérifier l'adresse email et authentifier l'utilisateur")
    public ResponseEntity<ApiResponse<AuthResponse>> confirmEmail(@RequestParam String token) {
        AuthResultDto result = confirmerEmailUC.executer(token);
        return ResponseEntity.ok(ApiResponse.ok(toAuthResponse(result), "Email vérifié."));
    }

    /** POST /api/v1/auth/resend-confirmation */
    @PostMapping("/resend-confirmation")
    @Operation(summary = "Renvoyer le lien de confirmation email")
    public ResponseEntity<ApiResponse<Void>> resendConfirmation(@Valid @RequestBody ResendConfirmationRequest req) {
        renouvellerConfirmationUC.executer(req.email());
        return ResponseEntity.ok(ApiResponse.ok("Lien de confirmation renvoyé."));
    }

    /** GET /api/v1/auth/me — Profil utilisateur connecté */
    @GetMapping("/me")
    @Operation(summary = "Profil utilisateur connecté")
    public ResponseEntity<ApiResponse<String>> me(@AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(ApiResponse.ok(userId));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private AuthResponse toAuthResponse(AuthResultDto d) {
        return new AuthResponse(d.utilisateurId(), d.prenom(), d.email(), d.role(),
            d.accessToken(), d.refreshToken(), d.expiresAt(), d.estSuspendu());
    }

    private String getIp(HttpServletRequest r) {
        String h = r.getHeader("X-Forwarded-For");
        return (h != null && !h.isBlank()) ? h.split(",")[0].trim() : r.getRemoteAddr();
    }
}
