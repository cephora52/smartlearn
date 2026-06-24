package com.mbem.mbemlevel.infrastructure.persistence.entity;

import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entité JPA du cours — enrichie avec tous les champs LMS.
 * Correspond à la page détail Udemy/OpenClassrooms :
 * titre, objectifs, prérequis, public cible, débouchés, modules, leçons.
 */
@Entity
@Table(name = "cours")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CoursJpaEntity {

    @Id
    private UUID id;

    // ── Infos générales ───────────────────────────────────────────────────────

    @Column(nullable = false, length = 200)
    private String titre;

    /** Description courte pour les cartes catalogue (max 500 chars) */
    @Column(name = "description_courte", length = 500)
    private String descriptionCourte;

    /** Description longue HTML pour la page détail */
    @Column(name = "description_longue", columnDefinition = "TEXT")
    private String descriptionLongue;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NiveauCours niveau;

    @Column(name = "categorie_id")
    private UUID categorieId;

    @Column(name = "formateur_id")
    private UUID formateurId;

    @Column(length = 250, unique = true)
    private String slug;

    @Column(name = "image_couverture", length = 500)
    private String imageCouverture;

    @Column(name = "image_couverture_thumbnail", length = 500)
    private String imageCouvertureThumbnail;

    @Column(name = "langue", nullable = false, length = 10)
    private String langue;

    // ── Contenu pédagogique ───────────────────────────────────────────────────

    /**
     * JSON array : ["Créer une API REST", "Déployer sur Railway"]
     * Stocké en TEXT, parsé côté applicatif.
     */
    @Column(name = "objectifs_apprentissage", columnDefinition = "TEXT")
    private String objectifsApprentissageJson;

    /** Prérequis avant de commencer ce cours */
    @Column(columnDefinition = "TEXT")
    private String prerequis;

    /** À qui s'adresse ce cours */
    @Column(name = "public_cible", length = 500)
    private String publicCible;

    /**
     * Débouchés professionnels avec chiffres en FCFA.
     * JSON : {"freelance":"300000-600000 FCFA/mois","emploi":"Développeur Backend"}
     * C'est le principal déclencheur émotionnel d'inscription (S4).
     */
    @Column(name = "debouches_json", columnDefinition = "TEXT")
    private String debouchesJson;

    // ── Stats dénormalisées ───────────────────────────────────────────────────

    @Column(name = "nb_modules", nullable = false)
    private int nbModules;

    @Column(name = "nb_lecons", nullable = false)
    private int nbLecons;

    @Column(name = "duree_totale_minutes", nullable = false)
    private int dureeTotaleMinutes;

    @Column(name = "nb_apprenants", nullable = false)
    private int nbApprenants;

    @Column(name = "note_moyenne")
    private Double noteMoyenne;

    @Column(name = "nb_avis", nullable = false)
    private int nbAvis;

    // ── Tarification ─────────────────────────────────────────────────────────

    @Column(name = "seuil_paiement", nullable = false)
    private BigDecimal seuilPaiement;

    @Column(name = "prix_fcfa", nullable = false)
    private long prixFcfa;

    // ── Statut ────────────────────────────────────────────────────────────────

    /**
     * BROUILLON   → créé par le formateur, non visible
     * EN_REVISION → soumis pour publication, en attente de validation admin
     * PUBLIE      → visible dans le catalogue
     * ARCHIVE     → retiré du catalogue, toujours accessible aux inscrits
     */
    @Column(nullable = false, length = 20)
    private String statut;

    @Column(name = "est_actif", nullable = false)
    private boolean estActif;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
