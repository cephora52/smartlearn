package com.mbem.mbemlevel.domain.gamification;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
/** Tirage au sort mensuel — 1er du mois, parmi les apprenants actifs. */
public class TirageAuSort extends AggregateRoot {
    private LocalDate mois;         // Premier jour du mois (ex: 2025-01-01)
    private UUID      gagnantId;
    private int       nbParticipants;
    private String    prixDescription;

    protected TirageAuSort() {
        super();
    }

    public static TirageAuSort creer(LocalDate mois, int nbParticipants, String prix) {
        TirageAuSort t = new TirageAuSort();
        t.mois = mois; t.nbParticipants = nbParticipants; t.prixDescription = prix;
        return t;
    }
    public TirageAuSort(UUID id, LocalDate mois, UUID gagnantId, int nbParticipants,
                        String prixDescription, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.mois = mois; this.gagnantId = gagnantId;
        this.nbParticipants = nbParticipants; this.prixDescription = prixDescription;
    }
    public void designerGagnant(UUID gagnantId) {
        this.gagnantId = gagnantId; markUpdated();
    }
    public LocalDate getMois()           { return mois; }
    public UUID      getGagnantId()      { return gagnantId; }
    public int       getNbParticipants() { return nbParticipants; }
    public String    getPrixDescription(){ return prixDescription; }
}
