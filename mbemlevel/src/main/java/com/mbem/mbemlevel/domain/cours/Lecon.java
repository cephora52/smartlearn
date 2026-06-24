package com.mbem.mbemlevel.domain.cours;

import java.time.LocalDateTime;
import java.util.UUID;

import com.mbem.mbemlevel.domain.shared.AggregateRoot;

/** Leçon — unité pédagogique élémentaire d'un module. */
public class Lecon extends AggregateRoot {
    private UUID moduleId;
    private String titre;
    private String contenuTexte;
    private String lienPdf;
    private String lienVideo;
    private int ordre;
    private int dureeMinutes;
    private int xpValeur;

    public static Lecon creer(UUID moduleId, String titre, int ordre, int xpValeur) {
        Lecon l = new Lecon();
        l.moduleId = moduleId;
        l.titre = titre.trim();
        l.ordre = ordre;
        l.xpValeur = xpValeur;
        return l;
    }

    public Lecon(UUID id, UUID moduleId, String titre, String contenuTexte,
            String lienPdf, String lienVideo, int ordre, int dureeMinutes,
            int xpValeur, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.moduleId = moduleId;
        this.titre = titre;
        this.contenuTexte = contenuTexte;
        this.lienPdf = lienPdf;
        this.lienVideo = lienVideo;
        this.ordre = ordre;
        this.dureeMinutes = dureeMinutes;
        this.xpValeur = xpValeur;
    }

    public Lecon() {
        super();
    }

    public UUID getModuleId() {
        return moduleId;
    }

    public String getTitre() {
        return titre;
    }

    public String getContenuTexte() {
        return contenuTexte;
    }

    public String getLienPdf() {
        return lienPdf;
    }

    public String getLienVideo() {
        return lienVideo;
    }

    public int getOrdre() {
        return ordre;
    }

    public int getDureeMinutes() {
        return dureeMinutes;
    }

    public int getXpValeur() {
        return xpValeur;
    }
}
