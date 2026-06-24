package com.mbem.mbemlevel.domain.communaute;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Signalement d'un message inapproprié — traité par l'admin. */
public class Signalement extends AggregateRoot {
    private UUID   messageId;
    private UUID   auteurId;
    private String raison;
    private String statut;   // EN_ATTENTE | TRAITE | IGNORE
    private UUID   adminId;

    protected Signalement() {
        super();
    }

    public static Signalement creer(UUID messageId, UUID auteurId, String raison) {
        Signalement s = new Signalement();
        s.messageId = messageId; s.auteurId = auteurId;
        s.raison = raison; s.statut = "EN_ATTENTE";
        return s;
    }
    public Signalement(UUID id, UUID messageId, UUID auteurId, String raison,
                       String statut, UUID adminId, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.messageId = messageId; this.auteurId = auteurId;
        this.raison = raison; this.statut = statut; this.adminId = adminId;
    }
    public void traiter(UUID adminId) { this.statut = "TRAITE"; this.adminId = adminId; markUpdated(); }
    public void ignorer(UUID adminId) { this.statut = "IGNORE"; this.adminId = adminId; markUpdated(); }

    public UUID   getMessageId() { return messageId; }
    public UUID   getAuteurId()  { return auteurId; }
    public String getRaison()    { return raison; }
    public String getStatut()    { return statut; }
}
