package com.mbem.mbemlevel.domain.certificat;
import com.mbem.mbemlevel.domain.event.CertificatObtenuEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.UUID;
/**
 * Agrégat Certificat — émis après validation complète d'un cours payant.
 * Le codeVerification est public : n'importe qui peut vérifier l'authenticité
 * sur mbemnova.com/verify/{code}
 */
public class Certificat extends AggregateRoot {
    private UUID   apprenantId;
    private UUID   coursId;
    /** Code unique URL-safe — affiché sur le certificat PDF, vérifiable publiquement. */
    private String codeVerification;
    private String lienPdf;
    private LocalDateTime dateEmission;

    private static final SecureRandom RANDOM = new SecureRandom();

    protected Certificat() {
        super();
    }

    public static Certificat emettre(UUID apprenantId, UUID coursId,
                                      String prenomApprenant, String emailApprenant,
                                      String telephoneApprenant, String nomCours) {
        Certificat c = new Certificat();
        c.apprenantId     = apprenantId;
        c.coursId         = coursId;
        c.codeVerification = genererCode();
        c.dateEmission    = LocalDateTime.now();
        // Event → génère le PDF + email + WhatsApp
        c.registerEvent(new CertificatObtenuEvent(
            c.getId(), apprenantId, coursId,
            prenomApprenant, emailApprenant, telephoneApprenant,
            nomCours, c.codeVerification));
        return c;
    }
    public Certificat(UUID id, UUID apprenantId, UUID coursId,
                      String codeVerification, String lienPdf,
                      LocalDateTime dateEmission,
                      LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId      = apprenantId;
        this.coursId          = coursId;
        this.codeVerification = codeVerification;
        this.lienPdf          = lienPdf;
        this.dateEmission     = dateEmission;
    }
    public void setLienPdf(String lien) { this.lienPdf = lien; markUpdated(); }

    private static String genererCode() {
        byte[] bytes = new byte[9]; // 12 chars base64
        RANDOM.nextBytes(bytes);
        return "MBN-" + Base64.getUrlEncoder().withoutPadding()
            .encodeToString(bytes).toUpperCase().substring(0, 8);
    }

    public UUID          getApprenantId()     { return apprenantId; }
    public UUID          getCoursId()         { return coursId; }
    public String        getCodeVerification(){ return codeVerification; }
    public String        getLienPdf()         { return lienPdf; }
    public LocalDateTime getDateEmission()    { return dateEmission; }
}
