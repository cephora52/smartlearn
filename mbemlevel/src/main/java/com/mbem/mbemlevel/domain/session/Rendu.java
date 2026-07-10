package com.mbem.mbemlevel.domain.session;

import com.mbem.mbemlevel.domain.event.RenduCorrigeEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Agrégat Rendu — soumission d'un apprenant pour un devoir.
 * Correction → note + commentaire → event → notification apprenant.
 */
public class Rendu extends AggregateRoot {
    private UUID devoirId;
    private UUID apprenantId;
    private String contenu;
    private String lienFichier;
    private Integer note; // 0-20, null si pas encore corrigé
    private String commentaire;
    private LocalDateTime dateSoumission;
    private LocalDateTime dateCorrection;
    private boolean enRetard;

    public static Rendu soumettre(UUID devoirId, UUID apprenantId,
            String contenu, String lienFichier) {
        Rendu r = new Rendu();
        r.devoirId = devoirId;
        r.apprenantId = apprenantId;
        r.contenu = contenu;
        r.lienFichier = lienFichier;
        r.dateSoumission = LocalDateTime.now();
        return r;
    }

    public Rendu() {
        super();
    }

    public Rendu(UUID id, UUID devoirId, UUID apprenantId, String contenu,
            String lienFichier, Integer note, String commentaire,
            LocalDateTime soumission, LocalDateTime correction,
            boolean enRetard,
            LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.devoirId = devoirId;
        this.apprenantId = apprenantId;
        this.contenu = contenu;
        this.lienFichier = lienFichier;
        this.note = note;
        this.commentaire = commentaire;
        this.dateSoumission = soumission;
        this.dateCorrection = correction;
        this.enRetard = enRetard;
    }

    /** Le formateur corrige le rendu — publie RenduCorrigeEvent. */
    public void corriger(int note, String commentaire,
            String prenom, String email) {
        if (note < 0 || note > 20)
            throw new IllegalArgumentException("Note 0-20");
        this.note = note;
        this.commentaire = commentaire;
        this.dateCorrection = LocalDateTime.now();
        markUpdated();
        registerEvent(new RenduCorrigeEvent(getId(), apprenantId, prenom, email, note));
    }

    public boolean estCorrige() {
        return note != null;
    }

    public UUID getDevoirId() {
        return devoirId;
    }

    public UUID getApprenantId() {
        return apprenantId;
    }

    public String getContenu() {
        return contenu;
    }

    public String getLienFichier() {
        return lienFichier;
    }

    public Integer getNote() {
        return note;
    }

    public String getCommentaire() {
        return commentaire;
    }

    public LocalDateTime getDateSoumission() {
        return dateSoumission;
    }

    public LocalDateTime getDateCorrection() {
        return dateCorrection;
    }

    public boolean isEnRetard() {
        return enRetard;
    }

    public void setEnRetard(boolean enRetard) {
        this.enRetard = enRetard;
    }
}
