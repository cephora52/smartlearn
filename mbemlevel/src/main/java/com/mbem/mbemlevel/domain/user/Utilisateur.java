// =============================================================================
// MbemNova — domain/user/Utilisateur.java
//
// Agrégat racine de tous les utilisateurs de la plateforme.
// ZÉRO annotation Spring/JPA — Java 21 pur.
//
// Toutes les règles métier liées aux utilisateurs sont ici.
// Les services ne contiennent que de l'orchestration.
// =============================================================================
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.event.ApprenantInscritEvent;
import com.mbem.mbemlevel.domain.event.CompteSuspenduEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Agrégat racine Utilisateur.
 *
 * <h3>Règles métier encapsulées</h3>
 * <ul>
 *   <li>Un compte bloqué (brute force) ne peut pas se connecter</li>
 *   <li>Un compte suspendu peut se connecter mais pas accéder aux cours</li>
 *   <li>Un SUPER_ADMIN ne peut être modifié que par un autre SUPER_ADMIN</li>
 *   <li>L'email est immuable après création</li>
 *   <li>Le mot de passe est TOUJOURS haché — jamais en clair dans cet objet</li>
 * </ul>
 *
 * <h3>Pattern Factory Method</h3>
 * <p>Utiliser {@link #creer(String, String, String)} pour créer un nouvel utilisateur.
 * Le constructeur public de reconstitution est réservé aux mappers JPA.</p>
 */
public class Utilisateur extends AggregateRoot {

    /** Prénom affiché dans l'interface et les emails. */
    private String prenom;
    /** Nom de famille (optionnel à l'inscription). */
    private String nom;
    /**
     * Email — identifiant unique et immuable.
     * Un changement d'email nécessite un processus dédié avec vérification.
     */
    private final String email;
    /**
     * Hash BCrypt du mot de passe (cost=12).
     * JAMAIS stocker en clair. JAMAIS logger.
     */
    private String motDePasseHache;
    private Role role;
    private StatutApprenant statut;

    // ── Sécurité connexion ────────────────────────────────────────────────────
    /** Réinitialisé à 0 après chaque connexion réussie. */
    private int tentativesEchouees;
    /** Non null = blocage temporaire actif (brute force). */
    private LocalDateTime bloqueJusquAu;
    /** Mise à jour après chaque connexion réussie. */
    private LocalDateTime derniereConnexion;

    // ── Vérification email ────────────────────────────────────────────────────
    private boolean emailVerifie;
    /** Token envoyé par email, nullifié après vérification. */
    private String tokenVerificationEmail;
    /** Expiration du token de vérification email (24h par défaut). */
    private LocalDateTime tokenVerificationEmailExpireAt;

    // ── Téléphone (optionnel) ─────────────────────────────────────────────────
    private String telephone;

    // =========================================================================
    // FACTORY METHOD — Point d'entrée unique pour créer un utilisateur
    // =========================================================================

    /**
     * Crée un nouvel apprenant avec profil minimal.
     *
     * <p>Garantit que :
     * <ul>
     *   <li>Les données sont validées avant création</li>
     *   <li>Le rôle est APPRENANT et le statut INSCRIT</li>
     *   <li>L'event ApprenantInscritEvent est enregistré</li>
     * </ul>
     *
     * @param prenom          Prénom (2–50 chars)
     * @param email           Email unique en minuscules
     * @param motDePasseHache Hash BCrypt — JAMAIS le mot de passe en clair
     */
    public static Utilisateur creer(String prenom, String email, String motDePasseHache) {
        validatePrenom(prenom);
        validateEmail(email);
        Objects.requireNonNull(motDePasseHache, "Le hash du mot de passe est obligatoire");

        Utilisateur u = new Utilisateur(email.trim().toLowerCase());
        u.prenom             = prenom.trim();
        u.motDePasseHache    = motDePasseHache;
        u.role               = Role.APPRENANT;
        u.statut             = StatutApprenant.INSCRIT;
        u.emailVerifie       = false;
        u.tentativesEchouees = 0;

        // Event publié après persistance → déclenche email bienvenue
        u.registerEvent(new ApprenantInscritEvent(u.getId(), u.prenom, u.email));
        return u;
    }

    /**
     * Constructeur de reconstitution depuis la persistance.
     * RÉSERVÉ aux mappers JPA — ne pas appeler dans le code métier.
     */
    public Utilisateur(UUID id, String prenom, String nom, String email,
                       String motDePasseHache, Role role, StatutApprenant statut,
                       int tentativesEchouees, LocalDateTime bloqueJusquAu,
                       LocalDateTime derniereConnexion, boolean emailVerifie,
                       String tokenVerificationEmail, LocalDateTime tokenVerificationEmailExpireAt,
                       String telephone,
                       LocalDateTime createdAt, LocalDateTime updatedAt) {
        super(id, createdAt, updatedAt);
        this.prenom                         = prenom;
        this.nom                            = nom;
        this.email                          = email;
        this.motDePasseHache                = motDePasseHache;
        this.role                           = role;
        this.statut                         = statut;
        this.tentativesEchouees             = tentativesEchouees;
        this.bloqueJusquAu                  = bloqueJusquAu;
        this.derniereConnexion              = derniereConnexion;
        this.emailVerifie                   = emailVerifie;
        this.tokenVerificationEmail         = tokenVerificationEmail;
        this.tokenVerificationEmailExpireAt = tokenVerificationEmailExpireAt;
        this.telephone                      = telephone;
    }

    /** Constructeur privé utilisé par la factory method. */
    private Utilisateur(String email) {
        super();
        this.email = email;
    }

    // =========================================================================
    // COMPORTEMENTS MÉTIER
    // =========================================================================

    /**
     * Enregistre une connexion réussie.
     * Réinitialise le compteur d'échecs et lève le blocage éventuel.
     */
    public void enregistrerConnexionReussie() {
        this.derniereConnexion  = LocalDateTime.now();
        this.tentativesEchouees = 0;
        this.bloqueJusquAu      = null;
        // Première connexion après inscription → passer INSCRIT → ACTIF
        if (this.statut == StatutApprenant.INSCRIT) {
            this.statut = StatutApprenant.ACTIF;
        }
        markUpdated();
    }

    /**
     * Enregistre une tentative de connexion échouée.
     * Bloque temporairement le compte après {@code maxTentatives} échecs.
     *
     * @param maxTentatives       Seuil avant blocage (ex: 5)
     * @param dureeBlockageMinutes Durée du blocage temporaire (ex: 30)
     */
    public void enregistrerConnexionEchouee(int maxTentatives, int dureeBlockageMinutes) {
        this.tentativesEchouees++;
        if (this.tentativesEchouees >= maxTentatives) {
            this.bloqueJusquAu = LocalDateTime.now().plusMinutes(dureeBlockageMinutes);
        }
        markUpdated();
    }

    /**
     * Vérifie si le compte est temporairement bloqué (brute force).
     * Le blocage expire automatiquement.
     */
    public boolean estBloque() {
        if (bloqueJusquAu == null) return false;
        boolean encoreBloque = LocalDateTime.now().isBefore(bloqueJusquAu);
        if (!encoreBloque) {
            // Auto-expiration silencieuse
            this.bloqueJusquAu      = null;
            this.tentativesEchouees = 0;
        }
        return encoreBloque;
    }

    /**
     * L'utilisateur peut-il se connecter ?
     * Note : un compte SUSPENDU peut se connecter (pour voir le message de suspension),
     * mais ne peut pas accéder aux cours ({@link #peutAccederAuxCours()}).
     */
    public boolean peutSeConnecter() {
        return !estBloque();
    }

    /** L'utilisateur peut-il accéder au contenu des cours ? */
    public boolean peutAccederAuxCours() {
        return this.statut != StatutApprenant.SUSPENDU && !estBloque();
    }

    /**
     * Suspend le compte pour retard de paiement.
     * La progression est intégralement préservée.
     *
     * @param messageAdmin Message personnalisé pour l'apprenant (peut être null)
     */
    public void suspendre(String messageAdmin) {
        if (this.statut == StatutApprenant.SUSPENDU) {
            throw new IllegalStateException("Le compte " + getId() + " est déjà suspendu");
        }
        this.statut = StatutApprenant.SUSPENDU;
        markUpdated();

        String msg = messageAdmin != null ? messageAdmin
            : "Votre accès a été suspendu suite à un retard de paiement.";
        registerEvent(new CompteSuspenduEvent(getId(), prenom, email, msg));
    }

    /** Réactive le compte après régularisation du paiement. */
    public void reactiver() {
        this.statut        = StatutApprenant.ACTIF;
        this.bloqueJusquAu = null;
        markUpdated();
    }

    /** Marque l'email comme vérifié (après clic sur le lien de confirmation). */
    public void verifierEmail() {
        this.emailVerifie                   = true;
        this.tokenVerificationEmail         = null;
        this.tokenVerificationEmailExpireAt = null;
        markUpdated();
    }

    /**
     * Change le rôle de cet utilisateur.
     *
     * @param nouveauRole    Rôle à attribuer
     * @param roleExecutant  Rôle de l'admin qui effectue l'opération
     * @throws IllegalArgumentException si les droits sont insuffisants
     */
    public void changerRole(Role nouveauRole, Role roleExecutant) {
        Objects.requireNonNull(nouveauRole,   "Le nouveau rôle est obligatoire");
        Objects.requireNonNull(roleExecutant, "Le rôle exécutant est obligatoire");

        // Modifier un SUPER_ADMIN requiert d'être SUPER_ADMIN
        if (this.role == Role.SUPER_ADMIN && roleExecutant != Role.SUPER_ADMIN) {
            throw new IllegalArgumentException(
                "Seul un SUPER_ADMIN peut modifier le rôle d'un SUPER_ADMIN");
        }
        // Attribuer SUPER_ADMIN requiert d'être SUPER_ADMIN
        if (nouveauRole == Role.SUPER_ADMIN && roleExecutant != Role.SUPER_ADMIN) {
            throw new IllegalArgumentException(
                "Seul un SUPER_ADMIN peut attribuer le rôle SUPER_ADMIN");
        }
        this.role = nouveauRole;
        markUpdated();
    }

    /**
     * Met à jour le mot de passe haché.
     * Appeler {@code refreshTokenService.revokerTous()} après cet appel.
     *
     * @param nouveauHashBcrypt Nouveau hash BCrypt — JAMAIS le mot de passe en clair
     */
    public void changerMotDePasse(String nouveauHashBcrypt) {
        if (nouveauHashBcrypt == null || nouveauHashBcrypt.isBlank()) {
            throw new IllegalArgumentException("Le nouveau hash est obligatoire");
        }
        this.motDePasseHache = nouveauHashBcrypt;
        markUpdated();
    }

    /** Met à jour le prénom et/ou le nom. L'email n'est pas modifiable ici. */
    public void mettreAJourProfil(String prenom, String nom, String telephone) {
        if (prenom != null && !prenom.isBlank()) {
            validatePrenom(prenom);
            this.prenom = prenom.trim();
        }
        if (nom != null)       this.nom       = nom.trim().isEmpty() ? null : nom.trim();
        if (telephone != null) this.telephone = telephone.trim().isEmpty() ? null : telephone.trim();
        markUpdated();
    }

    // =========================================================================
    // VALIDATIONS PRIVÉES
    // =========================================================================

    private static void validatePrenom(String prenom) {
        if (prenom == null || prenom.isBlank()) {
            throw new IllegalArgumentException("Le prénom est obligatoire");
        }
        if (prenom.trim().length() < 2) {
            throw new IllegalArgumentException("Le prénom doit contenir au moins 2 caractères");
        }
        if (prenom.trim().length() > 50) {
            throw new IllegalArgumentException("Le prénom ne peut pas dépasser 50 caractères");
        }
    }


/**
 * RGPD — anonymise les données personnelles.
 * Appelé par SupprimerCompteUseCase.
 */
public void anonymiser() {
    this.prenom                 = "Utilisateur";
    this.nom                    = "Supprimé";
    this.telephone              = null;
    this.tokenVerificationEmail = null;
    this.statut                 = StatutApprenant.SUPPRIME; // ajouter dans l'enum si absent
    markUpdated();
}
    private static void validateEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("L'email est obligatoire");
        }
        String t = email.trim().toLowerCase();
        if (!t.contains("@") || !t.contains(".")) {
            throw new IllegalArgumentException("Format d'email invalide : " + email);
        }
        if (t.length() > 255) {
            throw new IllegalArgumentException("L'email ne peut pas dépasser 255 caractères");
        }
    }

    // =========================================================================
    // ACCESSEURS — Pas de setters publics : tout passe par les méthodes métier
    // =========================================================================

    public String          getPrenom()                    { return prenom; }
    public String          getNom()                       { return nom; }
    public String          getNomComplet()                { return prenom + (nom != null ? " " + nom : ""); }
    public String          getEmail()                     { return email; }
    public String          getMotDePasseHache()           { return motDePasseHache; }
    public Role            getRole()                      { return role; }
    public StatutApprenant getStatut()                    { return statut; }
    public int             getTentativesEchouees()        { return tentativesEchouees; }
    public LocalDateTime   getBloqueJusquAu()             { return bloqueJusquAu; }
    public LocalDateTime   getDerniereConnexion()         { return derniereConnexion; }
    public boolean         isEmailVerifie()                        { return emailVerifie; }
    public String          getTokenVerificationEmail()             { return tokenVerificationEmail; }
    public LocalDateTime   getTokenVerificationEmailExpireAt()     { return tokenVerificationEmailExpireAt; }
    public String          getTelephone()                          { return telephone; }

    /** Setter limité pour le token de vérification email (appelé par le use case). */
    public void setTokenVerificationEmail(String token) {
        this.tokenVerificationEmail = token;
    }

    /** Définit le token de vérification email avec expiration (24h par défaut). */
    public void setTokenVerificationEmailAvecExpiration(String token, LocalDateTime expireAt) {
        this.tokenVerificationEmail         = token;
        this.tokenVerificationEmailExpireAt = expireAt;
    }

    /** Régénère un nouveau token de vérification email avec expiration. */
    public String regenererTokenVerificationEmail() {
        String nouveauToken = UUID.randomUUID().toString();
        LocalDateTime expireAt = LocalDateTime.now().plusHours(24);
        setTokenVerificationEmailAvecExpiration(nouveauToken, expireAt);
        return nouveauToken;
    }
}
