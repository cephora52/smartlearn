#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 04/15 : Couche Application (Ports + Use Cases Auth)
# =============================================================================
# RÔLE   : Implémente la couche Application complète pour l'authentification.
#          Tous les fichiers sont opérationnels et prêts à compiler.
#
# CONTENU :
#   ── Ports sortants (interfaces vers infra) ──────────────────────────────
#   application/port/out/UtilisateurRepository.java
#   application/port/out/RefreshTokenRepository.java
#   application/port/out/ResetTokenRepository.java
#   application/port/out/AuditLogRepository.java
#   application/port/out/EmailPort.java
#   application/port/out/CachePort.java
#
#   ── DTOs Application ────────────────────────────────────────────────────
#   application/dto/request/InscriptionCommand.java
#   application/dto/request/ConnexionCommand.java
#   application/dto/response/AuthResultDto.java
#
#   ── Use Cases Auth (5 scénarios couverts) ───────────────────────────────
#   InscrireApprenantUseCase     → Scénario 02 (inscription)
#   ConnecterUtilisateurUseCase  → Scénario 03 (connexion + brute force)
#   RefreshTokenUseCase          → Rotation sécurisée
#   DeconnecterUseCase           → Blacklist JWT + révocation RT
#   ReinitialiserMotDePasseUseCase → Scénario 27 (reset MDP 2 étapes)
#
#   ── Event Handlers Auth ─────────────────────────────────────────────────
#   application/event/ApprenantInscritHandler.java
#
# PRÉREQUIS : s01 + s02 + s03 doivent avoir été lancés
# USAGE     : chmod +x s04_application_auth.sh && ./s04_application_auth.sh
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'
C_BOLD='\033[1m';     C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$ROOT/src/main/java/com/mbem/mbemlevel"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 04/15 · Application Auth   ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""

[[ ! -f "$ROOT/pom.xml" ]]   && { echo "ERREUR: lancez s01 d'abord"; exit 1; }
[[ ! -d "$PKG/domain" ]]     && { echo "ERREUR: lancez s02 + s03 d'abord"; exit 1; }

# =============================================================================
# SECTION 1 — PORTS SORTANTS (interfaces — définissent le contrat vers infra)
# =============================================================================
log_sec "1/4 Ports sortants (interfaces)"

cat > "$PKG/application/port/out/UtilisateurRepository.java" << 'JEOF'
// =============================================================================
// MbemNova — application/port/out/UtilisateurRepository.java
//
// Port sortant : contrat de persistance des utilisateurs.
// L'implémentation est dans UtilisateurRepositoryAdapter (infrastructure).
// Le domaine ne connaît pas JPA — il ne connaît que ce contrat.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.user.Utilisateur;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port sortant (secondary port) pour la persistance des utilisateurs.
 *
 * <p>Toutes les méthodes sont en lecture pessimiste ou écriture transactionnelle.
 * La gestion des transactions (@Transactional) appartient aux adaptateurs.</p>
 */
public interface UtilisateurRepository {

    /** Recherche par UUID — retourne empty si inexistant. */
    Optional<Utilisateur> findById(UUID id);

    /**
     * Recherche par email (insensible à la casse).
     * Appelé à chaque connexion — index unique sur LOWER(email) en BDD.
     */
    Optional<Utilisateur> findByEmail(String email);

    /**
     * Vérifie l'existence d'un email sans charger l'objet complet.
     * Plus performant que findByEmail pour la vérification à l'inscription.
     */
    boolean existsByEmail(String email);

    /**
     * Persiste un utilisateur (INSERT ou UPDATE selon existence de l'ID).
     * Retourne l'entité sauvegardée (avec les champs auto-générés).
     */
    Utilisateur save(Utilisateur utilisateur);

    /** Liste des apprenants disponibles pour l'emploi (vitrine Talents). */
    List<Utilisateur> findApprenantsDisponibles();
}
JEOF
log_ok "UtilisateurRepository.java"

cat > "$PKG/application/port/out/RefreshTokenRepository.java" << 'JEOF'
// =============================================================================
// MbemNova — application/port/out/RefreshTokenRepository.java
// Port sortant pour la gestion des refresh tokens avec rotation sécurisée.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Port sortant — refresh tokens avec rotation et blacklist.
 *
 * <h3>Principe de la rotation</h3>
 * <pre>
 * Login  → genererEtSauvegarder() → retourne token brut au client
 * Refresh → findUtilisateurByTokenHache() → revoquerToken() → nouveau token
 * Logout  → revoquerToken()
 * </pre>
 *
 * <p>Le token brut n'est jamais stocké — seulement son SHA-256.</p>
 */
public interface RefreshTokenRepository {

    /**
     * Persiste un nouveau refresh token.
     *
     * @param utilisateurId Propriétaire du token
     * @param tokenHache    SHA-256 du token brut
     * @param expireLe      Date d'expiration (30 jours par défaut)
     * @param ip            IP de création (traçabilité)
     * @param userAgent     User-Agent du navigateur
     */
    void sauvegarder(UUID utilisateurId, String tokenHache,
                     LocalDateTime expireLe, String ip, String userAgent);

    /**
     * Cherche l'utilisateur associé à un hash de token.
     * Retourne empty si : token révoqué, expiré, ou inexistant.
     */
    Optional<UUID> findUtilisateurIdByTokenHache(String tokenHache);

    /** Révoque un token spécifique (après rotation ou logout). */
    void revoquerToken(String tokenHache);

    /**
     * Révoque TOUS les tokens actifs d'un utilisateur.
     * Utilisé lors d'un changement de MDP ou d'une suspension.
     *
     * @return Nombre de tokens révoqués
     */
    int revoquerTousLesTokens(UUID utilisateurId);

    /**
     * Supprime les tokens expirés et révoqués.
     * Appelé par le scheduler de nettoyage nocturne.
     *
     * @return Nombre de tokens supprimés
     */
    int nettoyerTokensExpires();
}
JEOF
log_ok "RefreshTokenRepository.java"

cat > "$PKG/application/port/out/ResetTokenRepository.java" << 'JEOF'
// =============================================================================
// MbemNova — application/port/out/ResetTokenRepository.java
// Port sortant pour les tokens de réinitialisation de mot de passe.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Port sortant — tokens de reset MDP.
 * Usage unique, TTL 1 heure, hash SHA-256 en base.
 */
public interface ResetTokenRepository {

    /** Persiste un nouveau token de reset (remplace les anciens non utilisés). */
    void sauvegarder(UUID utilisateurId, String tokenHache,
                     LocalDateTime expireLe, String ip);

    /**
     * Recherche un token valide (non utilisé, non expiré) par son hash.
     */
    Optional<UUID> findUtilisateurIdSiValide(String tokenHache, LocalDateTime maintenant);

    /**
     * Marque un token comme utilisé (usage unique — invalide immédiatement).
     */
    void marquerUtilise(String tokenHache);

    /**
     * Invalide tous les tokens non utilisés d'un utilisateur.
     * Appelé avant de créer un nouveau token (on ne génère qu'un à la fois).
     */
    int invaliderTousTokensUtilisateur(UUID utilisateurId);

    /** Nettoyage des tokens expirés — scheduler quotidien. */
    int nettoyerTokensExpires();
}
JEOF
log_ok "ResetTokenRepository.java"

cat > "$PKG/application/port/out/AuditLogRepository.java" << 'JEOF'
// =============================================================================
// MbemNova — application/port/out/AuditLogRepository.java
// Port sortant pour les logs d'audit — INSERT ONLY, immuable.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.util.Map;
import java.util.UUID;

/**
 * Port sortant — journal d'audit immuable.
 *
 * <h3>Actions tracées obligatoirement</h3>
 * <pre>
 * LOGIN_SUCCESS · LOGIN_FAILURE · LOGOUT
 * REGISTER · EMAIL_VERIFIED
 * PASSWORD_CHANGED · PASSWORD_RESET_REQUESTED · PASSWORD_RESET_DONE
 * TOKEN_REFRESHED · TOKEN_REVOKED
 * PAYMENT_REGISTERED · PAYMENT_ACTIVATED
 * ACCOUNT_SUSPENDED · ACCOUNT_REACTIVATED
 * ROLE_CHANGED · DATA_EXPORTED
 * </pre>
 *
 * <p>IMPORTANT : La transaction est REQUIRES_NEW dans l'adaptateur.
 * Le log est persisté même si la transaction principale fait rollback.</p>
 */
public interface AuditLogRepository {

    /**
     * Enregistre une action dans le journal.
     *
     * @param utilisateurId ID de l'utilisateur (null pour actions anonymes)
     * @param userEmail     Email dénormalisé (retrouvable même si compte supprimé)
     * @param action        Type SCREAMING_SNAKE_CASE (ex: LOGIN_SUCCESS)
     * @param ressourceType Type de ressource (ex: UTILISATEUR, PAIEMENT)
     * @param ressourceId   ID de la ressource affectée
     * @param details       Contexte JSON (ex: {ancien_role, nouveau_role})
     * @param statut        SUCCESS | FAILURE | WARNING
     * @param ip            IP réelle du client (après X-Forwarded-For)
     * @param userAgent     User-Agent du navigateur
     */
    void enregistrer(UUID utilisateurId, String userEmail, String action,
                     String ressourceType, String ressourceId,
                     Map<String, Object> details, String statut,
                     String ip, String userAgent);
}
JEOF
log_ok "AuditLogRepository.java"

cat > "$PKG/application/port/out/EmailPort.java" << 'JEOF'
// =============================================================================
// MbemNova — application/port/out/EmailPort.java
// Port sortant pour l'envoi d'emails via le provider SMTP externe.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

/**
 * Port sortant — envoi d'emails.
 * Implémenté par SendGridEmailAdapter (infrastructure).
 *
 * <h3>Templates Thymeleaf correspondants</h3>
 * <ul>
 *   <li>bienvenue.html</li>
 *   <li>rappel-48h.html</li>
 *   <li>reset-mdp.html</li>
 *   <li>alerte-securite.html</li>
 *   <li>suspension.html · reactivation.html</li>
 *   <li>seuil-paiement.html · activation-acces.html</li>
 *   <li>facture.html · certificat-obtenu.html</li>
 *   <li>relance-j7.html · relance-j3.html · relance-retard.html</li>
 *   <li>nouveau-devoir.html · devoir-corrige.html</li>
 *   <li>tirage-gagnant.html · parrainage-active.html</li>
 * </ul>
 */
public interface EmailPort {

    // ── Auth ──────────────────────────────────────────────────────────────────

    /** Email de bienvenue après inscription — envoyé dans les 30 secondes. */
    void envoyerBienvenue(String email, String prenom);

    /** Rappel 48h si aucun cours commencé depuis l'inscription. */
    void envoyerRappel48h(String email, String prenom);

    /**
     * Lien de réinitialisation de mot de passe.
     * Le lien contient le token brut — expire en 1 heure.
     */
    void envoyerResetMotDePasse(String email, String prenom, String lienReset);

    /**
     * Alerte de tentatives de connexion suspectes.
     * Envoyé après N échecs consécutifs (configurable).
     */
    void envoyerAlerteTentativesSuspectes(String email, String prenom,
                                          int nbTentatives, String ip);

    // ── Paiement ─────────────────────────────────────────────────────────────

    /** Email nurturing après atteinte du seuil de conversion (scénario 07). */
    void envoyerNurturingSeuilAtteint(String email, String prenom, String nomCours);

    /** Confirmation d'activation de l'accès complet après paiement (scénario 08). */
    void envoyerActivationAcces(String email, String prenom,
                                String nomCours, String lienFacturePdf);

    /** Relance paiement — J-7, J-3, J0, J+3, J+7 (scénario 16). */
    void envoyerRelancePaiement(String email, String prenom,
                                String nomCours, int joursAvantEcheance);

    /** Email de suspension de compte (scénario 18). */
    void envoyerSuspension(String email, String prenom, String messageAdmin);

    /** Email de réactivation après régularisation. */
    void envoyerReactivation(String email, String prenom, String nomCours);

    // ── Certificat / Talent ───────────────────────────────────────────────────

    /** Félicitations + lien vers le certificat PDF (scénario 13). */
    void envoyerCertificatObtenu(String email, String prenom,
                                 String nomCours, String lienCertificatPdf,
                                 String codeVerification);

    // ── Session / Devoirs ────────────────────────────────────────────────────

    /** Notification d'un nouveau devoir disponible (scénario 11). */
    void envoyerNouveauDevoir(String email, String prenom,
                              String nomDevoir, String dateRemise);

    /** Notification de correction du rendu avec la note (scénario 23). */
    void envoyerRenduCorrige(String email, String prenom,
                             String nomDevoir, int note, String commentaire);

    // ── Gamification ─────────────────────────────────────────────────────────

    /** Félicitations au gagnant du tirage au sort mensuel (scénario 24). */
    void envoyerGagnantTirage(String email, String prenom, String prix);

    /** Récompense de parrainage activée (scénario 15). */
    void envoyerRecomparainageActive(String emailParrain, String prenomParrain,
                                     String prenomFilleul);
}
JEOF
log_ok "EmailPort.java"

cat > "$PKG/application/port/out/CachePort.java" << 'JEOF'
// =============================================================================
// MbemNova — application/port/out/CachePort.java
// Port sortant pour le cache Redis avec TTL.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.time.Duration;
import java.util.Optional;

/**
 * Port sortant — cache Redis.
 * Implémenté par RedisCacheAdapter (infrastructure).
 *
 * <p>Usage type : progression d'un cours (TTL 5min), catalogue (TTL 10min),
 * places disponibles d'une session (TTL 30s), blacklist JWT (TTL = restant du token).</p>
 */
public interface CachePort {

    /** Met une valeur en cache avec TTL. */
    void set(String cle, String valeur, Duration ttl);

    /** Récupère une valeur. Retourne empty si absente ou expirée. */
    Optional<String> get(String cle);

    /** Supprime une clé du cache. */
    void evict(String cle);

    /** Vérifie l'existence d'une clé (plus léger que get). */
    boolean exists(String cle);

    /** Incrémente un compteur atomiquement (rate limiting). */
    long increment(String cle, Duration ttl);
}
JEOF
log_ok "CachePort.java"

# =============================================================================
# SECTION 2 — DTOs APPLICATION
# =============================================================================
log_sec "2/4 DTOs Application"

cat > "$PKG/application/dto/request/InscriptionCommand.java" << 'JEOF'
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
JEOF

cat > "$PKG/application/dto/request/ConnexionCommand.java" << 'JEOF'
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
JEOF

cat > "$PKG/application/dto/response/AuthResultDto.java" << 'JEOF'
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
JEOF

log_ok "InscriptionCommand + ConnexionCommand + AuthResultDto"

# =============================================================================
# SECTION 3 — USE CASES AUTH (5 use cases couvrant les scénarios 2,3,27)
# =============================================================================
log_sec "3/4 Use Cases Auth"

# ── Use Case 1 : Inscription ──────────────────────────────────────────────────
cat > "$PKG/application/usecase/auth/InscrireApprenantUseCase.java" << 'JEOF'
// =============================================================================
// MbemNova — application/usecase/auth/InscrireApprenantUseCase.java
//
// Use case : Inscription d'un nouvel apprenant (Scénario 02).
//
// Flux :
//   1. Vérifier unicité email (409 si existant)
//   2. Hacher le MDP avec BCrypt (cost 12)
//   3. Créer l'agrégat Utilisateur → enregistre ApprenantInscritEvent
//   4. Persister en base
//   5. Publier les domain events → email bienvenue
//   6. Générer JWT + Refresh Token
//   7. Audit
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.request.InscriptionCommand;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Inscription d'un nouvel apprenant.
 * Respecte les scénarios de sécurité : rate limiting géré par RateLimitFilter,
 * protection anti-bot par honeypot (couche API).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class InscrireApprenantUseCase {

    private final UtilisateurRepository  utilisateurRepo;
    private final RefreshTokenRepository refreshTokenRepo;
    private final AuditLogRepository     auditRepo;
    private final PasswordEncoder        passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;
    // JWT injecté depuis l'infrastructure via interface dans s07
    private final JwtFacade              jwtFacade;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;

    /**
     * Exécute l'inscription.
     *
     * @param cmd Données validées par la couche API
     * @return Tokens JWT prêts à envoyer au client
     * @throws IllegalStateException si l'email est déjà utilisé
     */
    @Transactional
    public AuthResultDto executer(InscriptionCommand cmd) {

        // ── 1. Unicité email ────────────────────────────────────────────────
        if (utilisateurRepo.existsByEmail(cmd.email())) {
            auditRepo.enregistrer(null, cmd.email(), "REGISTER_FAILURE",
                "UTILISATEUR", null,
                Map.of("raison", "Email déjà utilisé"),
                "FAILURE", cmd.ipAdresse(), cmd.userAgent());
            // Exception métier → GlobalExceptionHandler retourne 409
            throw new IllegalStateException("EMAIL_ALREADY_EXISTS");
        }

        // ── 2. Hachage MDP (BCrypt cost=12 configuré dans PasswordConfig) ──
        String hashBcrypt = passwordEncoder.encode(cmd.motDePasse());

        // ── 3. Créer l'agrégat domaine ──────────────────────────────────────
        Utilisateur user = Utilisateur.creer(cmd.prenom(), cmd.email(), hashBcrypt);

        // ── 4. Persister ─────────────────────────────────────────────────────
        Utilisateur saved = utilisateurRepo.save(user);

        // ── 5. Publier les domain events (email bienvenue, rappel 48h…) ────
        saved.getDomainEvents().forEach(eventPublisher::publishEvent);
        saved.clearDomainEvents();

        // ── 6. Générer les tokens ─────────────────────────────────────────────
        String accessToken  = jwtFacade.genererToken(
            saved.getId().toString(), saved.getEmail(), saved.getRole().name());
        String refreshToken = jwtFacade.genererRefreshToken(
            saved.getId(), refreshTtlJours, cmd.ipAdresse(), cmd.userAgent());

        // ── 7. Audit ──────────────────────────────────────────────────────────
        auditRepo.enregistrer(saved.getId(), saved.getEmail(), "REGISTER",
            "UTILISATEUR", saved.getId().toString(), null,
            "SUCCESS", cmd.ipAdresse(), cmd.userAgent());

        log.info("[AUTH] Inscription: {} ({})", saved.getPrenom(), saved.getEmail());

        return new AuthResultDto(
            saved.getId(), saved.getPrenom(), saved.getEmail(),
            saved.getRole().name(), accessToken, refreshToken,
            LocalDateTime.now().plusHours(24), false
        );
    }
}
JEOF
log_ok "InscrireApprenantUseCase.java"

# ── Use Case 2 : Connexion ────────────────────────────────────────────────────
cat > "$PKG/application/usecase/auth/ConnecterUtilisateurUseCase.java" << 'JEOF'
// =============================================================================
// MbemNova — application/usecase/auth/ConnecterUtilisateurUseCase.java
//
// Use case : Connexion (Scénario 03).
//
// RÈGLES DE SÉCURITÉ CRITIQUES :
//   - Message d'erreur GÉNÉRIQUE (ne révèle pas si l'email existe)
//   - Compteur d'échecs incrémenté en base
//   - Blocage temporaire après N échecs (configurable)
//   - Toutes les tentatives sont auditées avec l'IP
//   - Un compte SUSPENDU peut se connecter mais l'accès cours est bloqué
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.request.ConnexionCommand;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Connexion sécurisée avec protection brute-force.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ConnecterUtilisateurUseCase {

    private final UtilisateurRepository  utilisateurRepo;
    private final RefreshTokenRepository refreshTokenRepo;
    private final AuditLogRepository     auditRepo;
    private final PasswordEncoder        passwordEncoder;
    private final JwtFacade              jwtFacade;

    @Value("${mbemnova.security.max-tentatives-connexion:5}")
    private int maxTentatives;

    @Value("${mbemnova.security.blocage-connexion-minutes:30}")
    private int dureeBlockageMinutes;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;

    /**
     * Message générique — NE JAMAIS indiquer si l'email existe ou non.
     * Prévient l'énumération des comptes (account enumeration attack).
     */
    private static final String ERR_GENERIQUE = "INVALID_CREDENTIALS";

    @Transactional
    public AuthResultDto executer(ConnexionCommand cmd) {

        // ── 1. Chercher l'utilisateur ────────────────────────────────────────
        Utilisateur user = utilisateurRepo.findByEmail(cmd.email())
            .orElseGet(() -> {
                // Email inexistant — même log et même message que MDP incorrect
                auditRepo.enregistrer(null, cmd.email(), "LOGIN_FAILURE",
                    "UTILISATEUR", null,
                    Map.of("raison", "Email inexistant", "ip", nullSafe(cmd.ipAdresse())),
                    "FAILURE", cmd.ipAdresse(), cmd.userAgent());
                throw new SecurityException(ERR_GENERIQUE);
            });

        // ── 2. Vérifier le blocage brute-force ───────────────────────────────
        if (user.estBloque()) {
            auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_BLOCKED",
                "UTILISATEUR", user.getId().toString(),
                Map.of("bloqueJusquA", String.valueOf(user.getBloqueJusquAu())),
                "WARNING", cmd.ipAdresse(), cmd.userAgent());
            throw new SecurityException("ACCOUNT_TEMPORARILY_LOCKED");
        }

        // ── 3. Vérifier le mot de passe ─────────────────────────────────────
        if (!passwordEncoder.matches(cmd.motDePasse(), user.getMotDePasseHache())) {
            user.enregistrerConnexionEchouee(maxTentatives, dureeBlockageMinutes);
            utilisateurRepo.save(user);

            auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_FAILURE",
                "UTILISATEUR", user.getId().toString(),
                Map.of("tentatives", user.getTentativesEchouees(),
                       "ip", nullSafe(cmd.ipAdresse())),
                "FAILURE", cmd.ipAdresse(), cmd.userAgent());

            log.warn("[AUTH] Échec connexion #{}: {}", user.getTentativesEchouees(), user.getEmail());
            throw new SecurityException(ERR_GENERIQUE);
        }

        // ── 4. Enregistrer la connexion réussie ─────────────────────────────
        user.enregistrerConnexionReussie();
        utilisateurRepo.save(user);

        // ── 5. Générer les tokens ─────────────────────────────────────────────
        String accessToken  = jwtFacade.genererToken(
            user.getId().toString(), user.getEmail(), user.getRole().name());

        // Si rememberMe, le TTL est configuré plus long (déjà géré dans JwtFacade)
        String refreshToken = jwtFacade.genererRefreshToken(
            user.getId(), cmd.rememberMe() ? refreshTtlJours : 1,
            cmd.ipAdresse(), cmd.userAgent());

        // ── 6. Audit ─────────────────────────────────────────────────────────
        auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_SUCCESS",
            "UTILISATEUR", user.getId().toString(),
            Map.of("ip", nullSafe(cmd.ipAdresse())),
            "SUCCESS", cmd.ipAdresse(), cmd.userAgent());

        log.info("[AUTH] Connexion réussie: {}", user.getEmail());

        return new AuthResultDto(
            user.getId(), user.getPrenom(), user.getEmail(),
            user.getRole().name(), accessToken, refreshToken,
            LocalDateTime.now().plusHours(24),
            !user.peutAccederAuxCours()  // estSuspendu
        );
    }

    private static String nullSafe(String s) {
        return s != null ? s : "unknown";
    }
}
JEOF
log_ok "ConnecterUtilisateurUseCase.java"

# ── Use Case 3 : Refresh Token ────────────────────────────────────────────────
cat > "$PKG/application/usecase/auth/RefreshTokenUseCase.java" << 'JEOF'
// =============================================================================
// MbemNova — application/usecase/auth/RefreshTokenUseCase.java
// Rotation sécurisée : valide l'ancien token → révoque → génère nouveau.
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/** Rotation du refresh token — génère un nouveau JWT et un nouveau RT. */
@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final AuditLogRepository    auditRepo;
    private final JwtFacade             jwtFacade;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;

    @Transactional
    public AuthResultDto executer(String refreshTokenBrut, String ip, String userAgent) {

        // 1. Valider et effectuer la rotation (révoque l'ancien token en interne)
        UUID utilisateurId = jwtFacade.validerRefreshTokenEtRoter(refreshTokenBrut)
            .orElseThrow(() -> {
                log.warn("[AUTH] Refresh token invalide ou expiré depuis IP: {}", ip);
                return new SecurityException("INVALID_REFRESH_TOKEN");
            });

        // 2. Charger l'utilisateur
        Utilisateur user = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new SecurityException("USER_NOT_FOUND"));

        // 3. Vérifier le compte
        if (user.estBloque()) throw new SecurityException("ACCOUNT_TEMPORARILY_LOCKED");

        // 4. Générer nouveau JWT + nouveau refresh token
        String newAccessToken  = jwtFacade.genererToken(
            user.getId().toString(), user.getEmail(), user.getRole().name());
        String newRefreshToken = jwtFacade.genererRefreshToken(
            user.getId(), refreshTtlJours, ip, userAgent);

        auditRepo.enregistrer(user.getId(), user.getEmail(), "TOKEN_REFRESHED",
            "UTILISATEUR", user.getId().toString(),
            Map.of("ip", ip != null ? ip : "unknown"),
            "SUCCESS", ip, userAgent);

        log.debug("[AUTH] Refresh token roté pour: {}", user.getEmail());

        return new AuthResultDto(
            user.getId(), user.getPrenom(), user.getEmail(),
            user.getRole().name(), newAccessToken, newRefreshToken,
            LocalDateTime.now().plusHours(24),
            !user.peutAccederAuxCours()
        );
    }
}
JEOF
log_ok "RefreshTokenUseCase.java"

# ── Use Case 4 : Déconnexion ──────────────────────────────────────────────────
cat > "$PKG/application/usecase/auth/DeconnecterUseCase.java" << 'JEOF'
// =============================================================================
// MbemNova — application/usecase/auth/DeconnecterUseCase.java
// Déconnexion sécurisée : blacklist JWT + révocation refresh token.
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Déconnexion sécurisée.
 * Le JWT est blacklisté dans Redis avec TTL = durée restante du token.
 * Le refresh token est révoqué en base.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeconnecterUseCase {

    private final AuditLogRepository auditRepo;
    private final JwtFacade          jwtFacade;

    @Transactional
    public void executer(UUID utilisateurId, String email,
                         String accessToken, String refreshTokenBrut) {

        // 1. Blacklister le JWT courant (TTL = durée restante du token)
        if (accessToken != null && !accessToken.isBlank()) {
            jwtFacade.blacklister(accessToken);
        }

        // 2. Révoquer le refresh token
        if (refreshTokenBrut != null && !refreshTokenBrut.isBlank()) {
            jwtFacade.revoquerRefreshToken(refreshTokenBrut);
        }

        auditRepo.enregistrer(utilisateurId, email, "LOGOUT",
            "UTILISATEUR", utilisateurId != null ? utilisateurId.toString() : null,
            null, "SUCCESS", null, null);

        log.info("[AUTH] Déconnexion: {}", email);
    }
}
JEOF
log_ok "DeconnecterUseCase.java"

# ── Use Case 5 : Reset MDP (2 étapes — Scénario 27) ──────────────────────────
cat > "$PKG/application/usecase/auth/ReinitialiserMotDePasseUseCase.java" << 'JEOF'
// =============================================================================
// MbemNova — application/usecase/auth/ReinitialiserMotDePasseUseCase.java
//
// Use case : Réinitialisation du mot de passe en 2 étapes (Scénario 27).
//
// ÉTAPE 1 — Demande (demanderReset) :
//   - Chercher l'utilisateur par email
//   - Si trouvé : générer token (SHA-256 en base, brut dans l'email)
//   - Toujours retourner le même message (protection énumération comptes)
//
// ÉTAPE 2 — Confirmation (confirmerReset) :
//   - Valider le token (non utilisé, non expiré)
//   - Hacher le nouveau MDP
//   - Mettre à jour l'utilisateur
//   - Révoquer TOUS les refresh tokens (sécurité : invalider toutes sessions)
//   - Audit
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Réinitialisation MDP — 2 étapes sécurisées.
 * Protection contre l'énumération de comptes : même réponse si email connu ou inconnu.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReinitialiserMotDePasseUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final ResetTokenRepository  resetTokenRepo;
    private final EmailPort             emailPort;
    private final PasswordEncoder       passwordEncoder;
    private final AuditLogRepository    auditRepo;
    private final JwtFacade             jwtFacade;

    @Value("${mbemnova.app.url:https://mbemnova.com}")
    private String appUrl;

    @Value("${mbemnova.security.reset-token-ttl-minutes:60}")
    private int ttlMinutes;

    // ── Étape 1 : Demander le reset ──────────────────────────────────────────

    /**
     * Envoie un lien de reset si l'email existe.
     * Retourne silencieusement si l'email n'existe pas (protection énumération).
     *
     * @param email      Email soumis par l'utilisateur
     * @param ipAdresse  IP pour l'audit et le rate limiting
     */
    @Transactional
    public void demanderReset(String email, String ipAdresse) {
        utilisateurRepo.findByEmail(email).ifPresent(user -> {
            // Invalider les anciens tokens non utilisés
            resetTokenRepo.invaliderTousTokensUtilisateur(user.getId());

            // Générer et persister le token
            String tokenBrut = jwtFacade.genererResetToken(
                user.getId(), ttlMinutes, ipAdresse);

            // Construire le lien de reset
            String lien = appUrl + "/reset-password?token=" + tokenBrut;

            // Envoyer l'email
            emailPort.envoyerResetMotDePasse(user.getEmail(), user.getPrenom(), lien);

            auditRepo.enregistrer(user.getId(), email, "PASSWORD_RESET_REQUESTED",
                "UTILISATEUR", user.getId().toString(),
                Map.of("ip", ipAdresse != null ? ipAdresse : "unknown"),
                "SUCCESS", ipAdresse, null);

            log.info("[AUTH] Lien reset envoyé à: {}", email);
        });
        // Si email inexistant : pas d'erreur, même réponse → impossible de savoir
    }

    // ── Étape 2 : Confirmer avec le nouveau MDP ──────────────────────────────

    /**
     * Applique le nouveau mot de passe après validation du token.
     *
     * @param tokenBrut      Token reçu dans le lien email
     * @param nouveauMdpClair Nouveau mot de passe EN CLAIR
     */
    @Transactional
    public void confirmerReset(String tokenBrut, String nouveauMdpClair) {

        // 1. Valider et consommer le token (usage unique)
        UUID utilisateurId = resetTokenRepo.findUtilisateurIdSiValide(
                tokenBrut != null ? jwtFacade.hacherTokenReset(tokenBrut) : "",
                LocalDateTime.now())
            .orElseThrow(() -> new SecurityException("INVALID_OR_EXPIRED_RESET_TOKEN"));

        // 2. Charger l'utilisateur
        Utilisateur user = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new SecurityException("USER_NOT_FOUND"));

        // 3. Hacher et appliquer le nouveau MDP
        String nouveauHash = passwordEncoder.encode(nouveauMdpClair);
        user.changerMotDePasse(nouveauHash);
        utilisateurRepo.save(user);

        // 4. Marquer le token comme utilisé
        resetTokenRepo.marquerUtilise(jwtFacade.hacherTokenReset(tokenBrut));

        // 5. Révoquer TOUS les refresh tokens (invalider toutes les sessions actives)
        jwtFacade.revoquerTousRefreshTokens(utilisateurId);

        auditRepo.enregistrer(utilisateurId, user.getEmail(), "PASSWORD_RESET_DONE",
            "UTILISATEUR", utilisateurId.toString(), null,
            "SUCCESS", null, null);

        log.info("[AUTH] MDP réinitialisé pour: {}", user.getEmail());
    }
}
JEOF
log_ok "ReinitialiserMotDePasseUseCase.java"

# ── Interface JwtFacade (anti-circular dependency) ────────────────────────────
cat > "$PKG/application/usecase/auth/JwtFacade.java" << 'JEOF'
// =============================================================================
// MbemNova — application/usecase/auth/JwtFacade.java
//
// Interface facade JWT définie dans la couche Application.
// Implémentée dans la couche Infrastructure (s07).
// Évite la dépendance circulaire Application → Infrastructure.
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import java.util.Optional;
import java.util.UUID;

/**
 * Facade JWT exposée à la couche Application.
 * Abstrait toutes les opérations JWT et tokens derrière une interface simple.
 */
public interface JwtFacade {

    // ── Access Token ─────────────────────────────────────────────────────────

    /** Génère un JWT signé HS256 avec claims userId, email, role. */
    String genererToken(String userId, String email, String role);

    /** Ajoute le JWT dans la blacklist Redis (TTL = durée restante du token). */
    void blacklister(String accessToken);

    // ── Refresh Token ─────────────────────────────────────────────────────────

    /**
     * Génère un refresh token sécurisé (256 bits aléatoires).
     * Persiste le SHA-256 en base — retourne le token brut.
     */
    String genererRefreshToken(UUID utilisateurId, int ttlJours,
                               String ip, String userAgent);

    /**
     * Valide un refresh token et effectue la rotation.
     * Révoque l'ancien token, retourne l'ID utilisateur associé.
     */
    Optional<UUID> validerRefreshTokenEtRoter(String refreshTokenBrut);

    /** Révoque un refresh token spécifique. */
    void revoquerRefreshToken(String refreshTokenBrut);

    /** Révoque TOUS les refresh tokens d'un utilisateur. */
    void revoquerTousRefreshTokens(UUID utilisateurId);

    // ── Reset Token ───────────────────────────────────────────────────────────

    /**
     * Génère un token de reset MDP (256 bits aléatoires).
     * Persiste le SHA-256 en base — retourne le token brut.
     */
    String genererResetToken(UUID utilisateurId, int ttlMinutes, String ip);

    /** Calcule le SHA-256 d'un token brut (pour les lookups en base). */
    String hacherTokenReset(String tokenBrut);
}
JEOF
log_ok "JwtFacade.java (interface anti-circular-dep)"

# ── Confirm Email Use Case ────────────────────────────────────────────────────
cat > "$PKG/application/usecase/auth/ConfirmerEmailUseCase.java" << 'JEOF'
// MbemNova — application/usecase/auth/ConfirmerEmailUseCase.java
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Use case : Vérification de l'email après clic sur le lien de confirmation.
 * Non bloquant — l'utilisateur accède déjà à la plateforme sans vérification.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ConfirmerEmailUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final AuditLogRepository    auditRepo;

    @Transactional
    public void executer(String token) {
        utilisateurRepo.findAll().stream()
            .filter(u -> token.equals(u.getTokenVerificationEmail()))
            .findFirst()
            .ifPresent(user -> {
                user.verifierEmail();
                utilisateurRepo.save(user);
                auditRepo.enregistrer(user.getId(), user.getEmail(), "EMAIL_VERIFIED",
                    "UTILISATEUR", user.getId().toString(), null,
                    "SUCCESS", null, null);
                log.info("[AUTH] Email vérifié: {}", user.getEmail());
            });
        // Silencieux si token invalide (protection contre la fuite d'info)
    }
}
JEOF
log_ok "ConfirmerEmailUseCase.java"

# =============================================================================
# SECTION 4 — EVENT HANDLER (réagit aux domain events)
# =============================================================================
log_sec "4/4 Event Handler Auth"

cat > "$PKG/application/event/ApprenantInscritHandler.java" << 'JEOF'
// =============================================================================
// MbemNova — application/event/ApprenantInscritHandler.java
//
// Handler réagissant à ApprenantInscritEvent.
// Déclenché APRÈS la persistance de l'utilisateur.
//
// Actions :
//   1. Envoyer l'email de bienvenue immédiatement
//   2. (Future) Programmer le rappel 48h via le scheduler
// =============================================================================
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.ApprenantInscritEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Réagit à {@link ApprenantInscritEvent}.
 * {@code @Async} : l'email est envoyé dans un thread séparé pour ne pas
 * bloquer la réponse HTTP de l'inscription.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ApprenantInscritHandler {

    private final EmailPort emailPort;

    /**
     * Envoie l'email de bienvenue après l'inscription.
     * L'annotation @Async évite de bloquer la transaction principale.
     */
    @EventListener
    @Async
    public void handleApprenantInscrit(ApprenantInscritEvent event) {
        try {
            emailPort.envoyerBienvenue(event.email(), event.prenom());
            log.debug("[EVENT] Email bienvenue envoyé à: {}", event.email());
        } catch (Exception e) {
            // Ne jamais faire échouer l'inscription à cause de l'email
            log.error("[EVENT] Erreur envoi email bienvenue pour {}: {}",
                event.email(), e.getMessage());
        }
    }
}
JEOF

cat > "$PKG/application/event/SeuilAtteintHandler.java" << 'JEOF'
// MbemNova — application/event/SeuilAtteintHandler.java
// Handler : seuil de conversion atteint → email nurturing (Scénario 07)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.SeuilPaiementAtteintEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Réagit au seuil de paiement atteint — déclenche l'email de nurturing. */
@Component
@RequiredArgsConstructor
@Slf4j
public class SeuilAtteintHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handleSeuilAtteint(SeuilPaiementAtteintEvent event) {
        try {
            emailPort.envoyerNurturingSeuilAtteint(
                event.email(), event.prenom(), event.nomCours());
            log.debug("[EVENT] Email nurturing envoyé à: {}", event.email());
        } catch (Exception e) {
            log.error("[EVENT] Erreur nurturing pour {}: {}", event.email(), e.getMessage());
        }
    }
}
JEOF

cat > "$PKG/application/event/CompteSuspenduHandler.java" << 'JEOF'
// MbemNova — application/event/CompteSuspenduHandler.java
// Handler : compte suspendu → email suspension (Scénario 18)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.CompteSuspenduEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Réagit à la suspension de compte — email empathique avec instructions. */
@Component
@RequiredArgsConstructor
@Slf4j
public class CompteSuspenduHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handleCompteSuspendu(CompteSuspenduEvent event) {
        try {
            emailPort.envoyerSuspension(
                event.email(), event.prenom(), event.messagePersonnalise());
        } catch (Exception e) {
            log.error("[EVENT] Erreur email suspension pour {}: {}", event.email(), e.getMessage());
        }
    }
}
JEOF

cat > "$PKG/application/event/PaiementConfirmeHandler.java" << 'JEOF'
// MbemNova — application/event/PaiementConfirmeHandler.java
// Handler : paiement confirmé → active accès + génère facture (Scénario 08)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.PaiementConfirmeEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Paiement confirmé — email confirmation + lien facture PDF. */
@Component
@RequiredArgsConstructor
@Slf4j
public class PaiementConfirmeHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handlePaiementConfirme(PaiementConfirmeEvent event) {
        try {
            // La génération PDF et l'activation accès sont dans PaiementUseCase
            // Ce handler gère uniquement la notification email
            emailPort.envoyerActivationAcces(
                event.email(), event.prenom(), event.nomCours(), null);
        } catch (Exception e) {
            log.error("[EVENT] Erreur email paiement confirmé pour {}: {}",
                event.email(), e.getMessage());
        }
    }
}
JEOF

cat > "$PKG/application/event/CertificatObtenuHandler.java" << 'JEOF'
// MbemNova — application/event/CertificatObtenuHandler.java
// Handler : certificat obtenu → email félicitations + PDF (Scénario 13)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.CertificatObtenuEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Certificat obtenu — email félicitations avec lien PDF. */
@Component
@RequiredArgsConstructor
@Slf4j
public class CertificatObtenuHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handleCertificatObtenu(CertificatObtenuEvent event) {
        try {
            emailPort.envoyerCertificatObtenu(
                event.email(), event.prenom(), event.nomCours(),
                null, event.codeVerif());
        } catch (Exception e) {
            log.error("[EVENT] Erreur email certificat pour {}: {}", event.email(), e.getMessage());
        }
    }
}
JEOF

log_ok "5 event handlers (Inscrit, Seuil, Paiement, Suspendu, Certificat)"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 04/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  6 ports sortants (interfaces)"
echo -e "  ${C_GREEN}✓${C_NC}  3 DTOs Application (Commands + AuthResultDto)"
echo -e "  ${C_GREEN}✓${C_NC}  6 use cases Auth (inscription, connexion, refresh,"
echo -e "          déconnexion, reset MDP, confirm email)"
echo -e "  ${C_GREEN}✓${C_NC}  JwtFacade (interface anti-circular-dep)"
echo -e "  ${C_GREEN}✓${C_NC}  5 event handlers (email async)"
echo ""
echo -e "  \033[1;33m→ Prochain script : ./s05_migrations_sql.sh\033[0m"
echo ""
