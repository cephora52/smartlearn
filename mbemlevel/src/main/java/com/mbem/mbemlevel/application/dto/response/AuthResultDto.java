// MbemNova — application/dto/response/AuthResultDto.java
package com.mbem.mbemlevel.application.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Résultat d'une authentification réussie (inscription ou connexion).
 * Contient le JWT (access token) + le refresh token brut.
 *
 * @param utilisateurId UUID de l'utilisateur
 * @param prenom        Prénom pour la personnalisation UI
 * @param email         Email de l'utilisateur
 * @param role          Rôle pour le routage frontend
 * @param accessToken   JWT signé HS256 — durée de vie 24h
 * @param refreshToken  Token brut (non haché) — stocker en HttpOnly cookie
 * @param expiresAt     Date d'expiration de l'access token
 * @param estSuspendu   true si le compte est suspendu (peut se connecter mais accès cours bloqué)
 */
public record AuthResultDto(
    UUID          utilisateurId,
    String        prenom,
    String        email,
    String        role,
    String        accessToken,
    String        refreshToken,
    LocalDateTime expiresAt,
    boolean       estSuspendu
) {}
