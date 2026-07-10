package com.mbem.mbemlevel.application.dto.request;

/**
 * Commande d'inscription — données déjà validées par la couche API.
 * Record immuable Java 21.
 *
 * @param nom            Nom (déjà nettoyé)
 * @param prenom         Prénom (2-50 chars, déjà nettoyé)
 * @param email          Email en minuscules (format validé)
 * @param telephone      Téléphone
 * @param motDePasse     Mot de passe EN CLAIR — sera haché dans le use case
 * @param role           Rôle choisi (APPRENANT | FORMATEUR)
 * @param ipAdresse      IP du client (pour l'audit et le refresh token)
 * @param userAgent      User-Agent du navigateur
 */
public record InscriptionCommand(
    String nom,
    String prenom,
    String email,
    String telephone,
    String motDePasse,
    String role,
    String ipAdresse,
    String userAgent
) {}
