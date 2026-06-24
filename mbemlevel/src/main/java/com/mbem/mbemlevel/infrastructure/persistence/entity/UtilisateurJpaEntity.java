// =============================================================================
// MbemNova — infrastructure/persistence/entity/UtilisateurJpaEntity.java
//
// Entité JPA pour la table `utilisateurs`.
// SÉPARÉE intentionnellement de l'agrégat Utilisateur (domain).
// La conversion Domain ↔ JPA est réalisée par UtilisateurJpaMapper.
//
// RÈGLES :
//   - Ne jamais exposer cette classe hors de la couche Infrastructure
//   - Pas de logique métier ici — uniquement mapping colonnes ↔ champs
//   - @EntityListeners gère automatiquement createdAt / updatedAt
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import jakarta.persistence.Id; 
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entité JPA table {@code utilisateurs}.
 */
@Entity
@Table(
    name = "utilisateurs",
    uniqueConstraints = @UniqueConstraint(name = "uq_utilisateurs_email", columnNames = "email")
)
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class UtilisateurJpaEntity {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    // ── Identité ──────────────────────────────────────────────────────────────
    @Column(nullable = false, length = 50)
    private String prenom;

    @Column(length = 50)
    private String nom;

    @Column(nullable = false, length = 255)
    private String email;

    /** BCrypt hash max 72 chars effectifs. JAMAIS le MDP en clair. */
    @Column(name = "mot_de_passe_hache", nullable = false, length = 72)
    private String motDePasseHache;

    @Column(name = "email_verifie", nullable = false)
    private boolean emailVerifie;

    @Column(name = "token_verification_email", length = 255)
    private String tokenVerificationEmail;

    @Column(name = "token_verification_email_expire_at")
    private LocalDateTime tokenVerificationEmailExpireAt;

    @Column(length = 25)
    private String telephone;

    // ── Rôle et statut ────────────────────────────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutApprenant statut;

    // ── Protection brute-force ────────────────────────────────────────────────
    @Column(name = "tentatives_connexion_echouees", nullable = false)
    private int tentativesEchouees;

    @Column(name = "bloque_jusqu_au")
    private LocalDateTime bloqueJusquAu;

    @Column(name = "derniere_connexion")
    private LocalDateTime derniereConnexion;

    // ── Apprenant ─────────────────────────────────────────────────────────────
    @Column(length = 100)
    private String ville;

    @Column(name = "xp_total", nullable = false)
    private int xpTotal;

    @Column(name = "streak_jours", nullable = false)
    private int streakJours;

    @Column(name = "rang_plateforme")
    private Integer rangPlateforme;

    @Column(name = "disponible_pour_emploi", nullable = false)
    private boolean disponiblePourEmploi;

    @Column(name = "lien_portfolio", length = 500)
    private String lienPortfolio;

    @Column(name = "lien_cv", length = 500)
    private String lienCv;

    @Column(name = "lien_linkedin", length = 500)
    private String lienLinkedin;

    @Column(name = "lien_github", length = 500)
    private String lienGithub;

    @Column(length = 1000)
    private String bio;

    @Column(name = "code_parrainage", length = 20, unique = true)
    private String codeParrainage;

    @Column(name = "parrain_id")
    private UUID parrainId;

    // ── Formateur ─────────────────────────────────────────────────────────────
    @Column(length = 200)
    private String specialite;

    @Column(columnDefinition = "TEXT")
    private String biographie;

    @Column(name = "note_globale")
    private BigDecimal  noteGlobale;

    // ── Admin ─────────────────────────────────────────────────────────────────
    @Column(name = "niveau_acces", length = 20)
    private String niveauAcces;

    // ── Audit automatique via @EntityListeners ────────────────────────────────
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
