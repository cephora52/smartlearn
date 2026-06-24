package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Facture PDF générée après confirmation paiement. */
public class Facture extends AggregateRoot {
    private UUID   paiementId;
    private String codeVerification;
    private String lienPdf;
    private LocalDateTime dateEmission;

    public static Facture generer(UUID paiementId, String codeVerif) {
        Facture f = new Facture(); f.paiementId = paiementId;
        f.codeVerification = codeVerif; f.dateEmission = LocalDateTime.now(); return f;
    }
    public Facture(UUID id, UUID paiementId, String codeVerif, String lienPdf,
                   LocalDateTime emission, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.paiementId = paiementId; this.codeVerification = codeVerif;
        this.lienPdf = lienPdf; this.dateEmission = emission;
    }

       public Facture() {
        super();
    }

    public void setLienPdf(String lien) { this.lienPdf = lien; markUpdated(); }
    public UUID   getPaiementId()       { return paiementId; }
    public String getCodeVerification() { return codeVerification; }
    public String getLienPdf()          { return lienPdf; }
    public LocalDateTime getDateEmission() { return dateEmission; }
}
