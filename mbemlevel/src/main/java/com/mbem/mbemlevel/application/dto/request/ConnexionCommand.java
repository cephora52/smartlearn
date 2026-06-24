// MbemNova — application/dto/request/ConnexionCommand.java
package com.mbem.mbemlevel.application.dto.request;

/**
 * Commande de connexion.
 *
 * @param email       Email (insensible à la casse)
 * @param motDePasse  Mot de passe EN CLAIR — comparé au hash BCrypt
 * @param rememberMe  Si true, refresh token TTL 30j (sinon 24h)
 * @param ipAdresse   IP client pour l'audit et le refresh token
 * @param userAgent   User-Agent pour la traçabilité
 */
public record ConnexionCommand(
    String email,
    String motDePasse,
    boolean rememberMe,
    String ipAdresse,
    String userAgent
) {}
