package com.mbem.mbemlevel.infrastructure.persistence.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import com.mbem.mbemlevel.domain.cours.TypeBloc;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "blocs_contenu")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BlocContenuJpaEntity {

    @Id
    private UUID id;

    @Column(name = "lecon_id", nullable = false)
    private UUID leconId;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_bloc", nullable = false, length = 30)
    private TypeBloc typeBloc;

    @Column(nullable = false)
    private int ordre;

    // ── TEXTE_HTML ──────────────────────────────────
    @Column(name = "contenu_html", columnDefinition = "TEXT")
    private String contenuHtml;

    // ── IMAGE ───────────────────────────────────────
    @Column(name = "url_image", length = 500)
    private String urlImage;

    @Column(name = "alt_image", length = 200)
    private String altImage;

    @Column(name = "legende_image", length = 300)
    private String legendeImage;

    // ── VIDEO ───────────────────────────────────────
    @Column(name = "url_video", length = 500)
    private String urlVideo;

    @Column(name = "duree_video_sec")
    private Integer dureeVideoSec;

    // ── PDF ─────────────────────────────────────────
    @Column(name = "url_pdf", length = 500)
    private String urlPdf;

    @Column(name = "nom_pdf", length = 200)
    private String nomPdf;

    // ── CODE ─────────────────────────────────────────
    @Column(name = "langage_code", length = 30)
    private String langageCode;

    @Column(name = "code_source", columnDefinition = "TEXT")
    private String codeSource;

    // ── CALLOUT ──────────────────────────────────────
    @Column(name = "type_callout", length = 20)
    private String typeCallout;

    @Column(name = "texte_callout", columnDefinition = "TEXT")
    private String texteCallout;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
