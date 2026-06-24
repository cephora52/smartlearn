package com.mbem.mbemlevel.domain.cours;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Bloc de contenu pédagogique d'une leçon — Value Object.
 *
 * Une leçon est composée d'une liste ordonnée de BlocContenu.
 * Chaque bloc a un type et des données spécifiques à ce type.
 *
 * Exemples d'utilisation :
 *   - Bloc TEXTE_HTML : introduction du cours
 *   - Bloc CODE       : exemple Java
 *   - Bloc IMAGE      : schéma explicatif
 *   - Bloc CALLOUT    : "Attention à bien valider les entrées !"
 *   - Bloc PDF_EMBED  : support de cours PDF
 *   - Bloc VIDEO_YOUTUBE : vidéo explicative
 */
public class BlocContenu {

    private UUID      id;
    private UUID      leconId;
    private TypeBloc  typeBloc;
    private int       ordre;

    // ── TEXTE_HTML ──────────────────────────────────────────────
    /** Contenu HTML sanitisé (DOMPurify) */
    private String contenuHtml;

    // ── IMAGE ────────────────────────────────────────────────────
    private String urlImage;
    private String altImage;
    private String legendeImage;

    // ── VIDEO ────────────────────────────────────────────────────
    private String urlVideo;
    private Integer dureeVideoSec;

    // ── PDF ──────────────────────────────────────────────────────
    private String urlPdf;
    private String nomPdf;

    // ── CODE ─────────────────────────────────────────────────────
    private String langageCode; // java, python, javascript, sql, bash...
    private String codeSource;

    // ── CALLOUT ──────────────────────────────────────────────────
    private String typeCallout; // INFO, ASTUCE, ATTENTION, IMPORTANT
    private String texteCallout;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ── Constructeurs factory par type ───────────────────────────

    public static BlocContenu texteHtml(UUID leconId, int ordre, String html) {
        BlocContenu b = nouveau(leconId, TypeBloc.TEXTE_HTML, ordre);
        b.contenuHtml = html;
        return b;
    }

    public static BlocContenu image(UUID leconId, int ordre,
                                     String urlImage, String alt, String legende) {
        BlocContenu b = nouveau(leconId, TypeBloc.IMAGE, ordre);
        b.urlImage = urlImage;
        b.altImage = alt;
        b.legendeImage = legende;
        return b;
    }

    public static BlocContenu videoYoutube(UUID leconId, int ordre,
                                            String urlVideo, int dureeSec) {
        BlocContenu b = nouveau(leconId, TypeBloc.VIDEO_YOUTUBE, ordre);
        b.urlVideo = urlVideo;
        b.dureeVideoSec = dureeSec;
        return b;
    }

    public static BlocContenu videoVimeo(UUID leconId, int ordre,
                                          String urlVideo, int dureeSec) {
        BlocContenu b = nouveau(leconId, TypeBloc.VIDEO_VIMEO, ordre);
        b.urlVideo = urlVideo;
        b.dureeVideoSec = dureeSec;
        return b;
    }

    public static BlocContenu pdfEmbed(UUID leconId, int ordre,
                                        String urlPdf, String nomPdf) {
        BlocContenu b = nouveau(leconId, TypeBloc.PDF_EMBED, ordre);
        b.urlPdf = urlPdf;
        b.nomPdf = nomPdf;
        return b;
    }

    public static BlocContenu code(UUID leconId, int ordre,
                                    String langage, String source) {
        BlocContenu b = nouveau(leconId, TypeBloc.CODE, ordre);
        b.langageCode = langage;
        b.codeSource  = source;
        return b;
    }

    public static BlocContenu callout(UUID leconId, int ordre,
                                       String typeCallout, String texte) {
        if (!typeCallout.matches("INFO|ASTUCE|ATTENTION|IMPORTANT")) {
            throw new IllegalArgumentException("typeCallout invalide : " + typeCallout);
        }
        BlocContenu b = nouveau(leconId, TypeBloc.CALLOUT, ordre);
        b.typeCallout = typeCallout;
        b.texteCallout = texte;
        return b;
    }

    private static BlocContenu nouveau(UUID leconId, TypeBloc type, int ordre) {
        if (ordre < 1) throw new IllegalArgumentException("Ordre >= 1");
        BlocContenu b = new BlocContenu();
        b.id       = UUID.randomUUID();
        b.leconId  = leconId;
        b.typeBloc = type;
        b.ordre    = ordre;
        b.createdAt = LocalDateTime.now();
        b.updatedAt = LocalDateTime.now();
        return b;
    }

    /** Constructeur de reconstitution depuis la persistence */
    public BlocContenu(UUID id, UUID leconId, TypeBloc typeBloc, int ordre,
                        String contenuHtml, String urlImage, String altImage,
                        String legendeImage, String urlVideo, Integer dureeVideoSec,
                        String urlPdf, String nomPdf, String langageCode,
                        String codeSource, String typeCallout, String texteCallout,
                        LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id; this.leconId = leconId; this.typeBloc = typeBloc;
        this.ordre = ordre; this.contenuHtml = contenuHtml;
        this.urlImage = urlImage; this.altImage = altImage;
        this.legendeImage = legendeImage; this.urlVideo = urlVideo;
        this.dureeVideoSec = dureeVideoSec; this.urlPdf = urlPdf;
        this.nomPdf = nomPdf; this.langageCode = langageCode;
        this.codeSource = codeSource; this.typeCallout = typeCallout;
        this.texteCallout = texteCallout; this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public BlocContenu() {}

    // ── Getters ──────────────────────────────────────────────────
    public UUID      getId()            { return id; }
    public UUID      getLeconId()       { return leconId; }
    public TypeBloc  getTypeBloc()      { return typeBloc; }
    public int       getOrdre()         { return ordre; }
    public String    getContenuHtml()   { return contenuHtml; }
    public String    getUrlImage()      { return urlImage; }
    public String    getAltImage()      { return altImage; }
    public String    getLégendeImage()  { return legendeImage; }
    public String    getUrlVideo()      { return urlVideo; }
    public Integer   getDureeVideoSec() { return dureeVideoSec; }
    public String    getUrlPdf()        { return urlPdf; }
    public String    getNomPdf()        { return nomPdf; }
    public String    getLangageCode()   { return langageCode; }
    public String    getCodeSource()    { return codeSource; }
    public String    getTypeCallout()   { return typeCallout; }
    public String    getTexteCallout()  { return texteCallout; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
