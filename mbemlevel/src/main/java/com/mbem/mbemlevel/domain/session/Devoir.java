package com.mbem.mbemlevel.domain.session;
import com.mbem.mbemlevel.domain.event.DevoirPublieEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Agrégat Devoir — publié par le formateur pour une session.
 * Publication → event → notification des apprenants.
 */
public class Devoir extends AggregateRoot {
    private UUID          sessionId;
    private String        titre;
    private String        consignes;
    private LocalDateTime dateRemise;
    private boolean       estVerrouille;
    private String        lienRessources;
    

    public static Devoir creer(UUID sessionId, String titre,
                                String consignes, LocalDateTime dateRemise) {
        Devoir d = new Devoir(); d.sessionId = sessionId;
        d.titre = titre.trim(); d.consignes = consignes;
        d.dateRemise = dateRemise; d.estVerrouille = false; return d;
    }

      public Devoir() {
                super();
            }


    public Devoir(UUID id, UUID sessionId, String titre,
                  String consignes, LocalDateTime dateRemise, boolean verrouille,
                  String lienRessources, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.sessionId = sessionId; this.titre = titre;
        this.consignes = consignes; this.dateRemise = dateRemise;
        this.estVerrouille = verrouille; this.lienRessources = lienRessources;
    }

    /** Publie le devoir → event → notifications apprenants. */
    public void publier(String nomDevoir, String dateRemiseStr) {
        this.estVerrouille = false; markUpdated();
        registerEvent(new DevoirPublieEvent(getId(), sessionId, nomDevoir, dateRemiseStr));
    }
    public boolean estEnRetard(LocalDateTime maintenant) {
        return maintenant.isAfter(dateRemise);
    }
    public UUID          getSessionId()      { return sessionId; }
    public String        getTitre()          { return titre; }
    public String        getConsignes()      { return consignes; }
    public LocalDateTime getDateRemise()     { return dateRemise; }
    public boolean       isEstVerrouille()   { return estVerrouille; }
    public String        getLienRessources() { return lienRessources; }
}
