// MbemNova — application/dto/request/InscriptionCommand.java
package com.mbem.mbemlevel.application.dto.request;

/**
 * Commande d'inscription — données déjà validées par la couche API.
 * Record immuable Java 21.
 *
 * @param prenom         Prénom (2-50 chars, déjà nettoyé)
 * @param email          Email en minuscules (format validé)
 * @param motDePasse     Mot de passe EN CLAIR — sera haché dans le use case
 * @param ipAdresse      IP du client (pour l'audit et le refresh token)
 * @param userAgent      User-Agent du navigateur
 */
public record InscriptionCommand(
    String prenom,
    String email,
    String motDePasse,
    String ipAdresse,
    String userAgent
) {}
