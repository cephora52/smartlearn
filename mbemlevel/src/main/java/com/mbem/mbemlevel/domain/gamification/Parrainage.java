package com.mbem.mbemlevel.domain.gamification;
import com.mbem.mbemlevel.domain.event.ParrainageActiveEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Parrainage — lien parrain/filleul.
 * La récompense est activée quand le filleul complète son premier module.
 */
public class Parrainage extends AggregateRoot {
    private UUID   parrainId;
    private UUID   filleulId;
    private String codeUtilise;
    private String statut;               // EN_ATTENTE | ACTIF | RECOMPENSE
    private boolean recomparainageActivee;

    protected Parrainage() {
        super();
    }

    public static Parrainage creer(UUID parrainId, UUID filleulId, String code) {
        Parrainage p = new Parrainage();
        p.parrainId = parrainId; p.filleulId = filleulId;
        p.codeUtilise = code; p.statut = "EN_ATTENTE";
        p.recomparainageActivee = false;
        return p;
    }
    public Parrainage(UUID id, UUID parrainId, UUID filleulId, String code,
                      String statut, boolean recompense,
                      LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.parrainId = parrainId; this.filleulId = filleulId;
        this.codeUtilise = code; this.statut = statut;
        this.recomparainageActivee = recompense;
    }
    /** Filleul a complété son premier module → déclenche la récompense parrain. */
    public void activerRecompense(String emailParrain) {
        if (recomparainageActivee) return;
        this.statut = "RECOMPENSE"; this.recomparainageActivee = true; markUpdated();
        registerEvent(new ParrainageActiveEvent(parrainId, filleulId, emailParrain));
    }
    public UUID    getParrainId()             { return parrainId; }
    public UUID    getFilleulId()             { return filleulId; }
    public String  getCodeUtilise()           { return codeUtilise; }
    public String  getStatut()                { return statut; }
    public boolean isRecomparainageActivee()  { return recomparainageActivee; }
}
