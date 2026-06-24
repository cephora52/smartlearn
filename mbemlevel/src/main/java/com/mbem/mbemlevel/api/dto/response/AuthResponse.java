package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.UUID;
/** Réponse auth : JWT + refresh token + infos utilisateur. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record AuthResponse(
    UUID userId, String prenom, String email, String role,
    String accessToken, String refreshToken,
    LocalDateTime expiresAt, Boolean suspended
) {}
