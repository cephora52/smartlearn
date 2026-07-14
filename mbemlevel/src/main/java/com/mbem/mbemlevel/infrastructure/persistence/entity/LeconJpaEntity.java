package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "lecons")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LeconJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(nullable = false, length = 200)
    private String titre;

    @Column(name = "description_courte", length = 500)
    private String descriptionCourte;

    /** Contenu texte simple (legacy — remplacé par blocs_contenu) */
    @Column(name = "contenu_texte", columnDefinition = "TEXT")
    private String contenuTexte;

    /** Lien PDF direct (legacy — remplacé par blocs_contenu type PDF_EMBED) */
    @Column(name = "lien_pdf", length = 500)
    private String lienPdf;

    /** Lien vidéo (legacy — remplacé par blocs_contenu type VIDEO_YOUTUBE) */
    @Column(name = "lien_video", length = 500)
    private String lienVideo;

    @Column(nullable = false)
    private int ordre;

    @Column(name = "duree_minutes")
    private int dureeMinutes;

    @Column(name = "xp_valeur", nullable = false)
    private int xpValeur;

    /**
     * Leçon accessible sans payer — aperçu gratuit avant le seuil.
     */
    @Column(name = "est_preview", nullable = false)
    private boolean estPreview;

    /**
     * Indique si cette leçon a un QCM associé.
     * Dénormalisation pour éviter un JOIN sur qcm à chaque affichage de liste.
     */
    @Column(name = "a_qcm", nullable = false)
    private boolean aQCM;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
