package com.mbem.mbemlevel.api.exception;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.WebRequest;
import java.util.List;
import java.util.stream.Collectors;
/**
 * Gestionnaire global d'exceptions — toutes les erreurs → JSON cohérent.
 * NE JAMAIS exposer les stack traces ou messages techniques en réponse.
 */
@RestControllerAdvice @Slf4j
public class GlobalExceptionHandler {

    /** Exceptions métier MbemNova — code HTTP et code machine précis. */
    @ExceptionHandler(MbemNovaException.class)
    public ResponseEntity<ApiResponse<Void>> handle(MbemNovaException e) {
        log.debug("[EX] {}: {}", e.getCode(), e.getMessage());
        return ResponseEntity.status(e.getStatus())
            .body(ApiResponse.err(e.getMessage(), e.getCode()));
    }

    /** Bean Validation (@Valid) — retourne la liste des champs invalides. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handle(MethodArgumentNotValidException e) {
        List<String> details = e.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage).collect(Collectors.toList());
        return ResponseEntity.unprocessableEntity()
            .body(ApiResponse.validation("Données invalides.", details));
    }

    /** Tentative de connexion avec mauvais identifiants — message générique. */
    @ExceptionHandler(SecurityException.class)
    public ResponseEntity<ApiResponse<Void>> handle(SecurityException e) {
        String code = e.getMessage();
        return switch (code) {
            case "EMAIL_ALREADY_EXISTS"     -> ResponseEntity.status(409).body(ApiResponse.err("Email déjà utilisé.", code));
            case "ACCOUNT_TEMPORARILY_LOCKED" -> ResponseEntity.status(403).body(ApiResponse.err("Compte temporairement bloqué.", code));
            case "ACCOUNT_SUSPENDED"        -> ResponseEntity.status(403).body(ApiResponse.err("Compte suspendu.", code));
            case "INVALID_REFRESH_TOKEN"    -> ResponseEntity.status(401).body(ApiResponse.err("Token de rafraîchissement invalide.", code));
            case "INVALID_OR_EXPIRED_RESET_TOKEN" -> ResponseEntity.status(400).body(ApiResponse.err("Lien de réinitialisation invalide ou expiré.", code));
            default -> ResponseEntity.status(401).body(ApiResponse.err("Email ou mot de passe incorrect.", "INVALID_CREDENTIALS"));
        };
    }

    /** Spring Security 401 */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Void>> handle(AuthenticationException e) {
        return ResponseEntity.status(401).body(ApiResponse.err("Authentification requise.", "UNAUTHORIZED"));
    }

    /** Spring Security 403 */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handle(AccessDeniedException e) {
        return ResponseEntity.status(403).body(ApiResponse.err("Accès refusé.", "ACCESS_DENIED"));
    }

    /** IllegalStateException — souvent email déjà utilisé depuis le use case. */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ApiResponse<Void>> handle(IllegalStateException e) {
        if ("EMAIL_ALREADY_EXISTS".equals(e.getMessage())) {
            return ResponseEntity.status(409).body(ApiResponse.err("Email déjà utilisé.", "EMAIL_ALREADY_EXISTS"));
        }
        if ("PASSWORDS_DO_NOT_MATCH".equals(e.getMessage())) {
            return ResponseEntity.status(400).body(ApiResponse.err("Les mots de passe ne correspondent pas.", "PASSWORDS_DO_NOT_MATCH"));
        }
        log.warn("[EX] IllegalState: {}", e.getMessage());
        return ResponseEntity.badRequest().body(ApiResponse.err("Opération impossible.", "BAD_REQUEST"));
    }

    /** Toute exception non gérée → 500 générique sans détail technique. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handle(Exception e, WebRequest req) {
        log.error("[EX] Erreur interne: {} — {}", e.getClass().getSimpleName(), e.getMessage(), e);
        String details = e.getClass().getSimpleName() + ": " + e.getMessage();
        return ResponseEntity.internalServerError()
            .body(ApiResponse.err("Erreur interne: " + details, "INTERNAL_ERROR"));
    }
}
