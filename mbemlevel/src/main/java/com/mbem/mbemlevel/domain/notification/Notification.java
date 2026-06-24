package com.mbem.mbemlevel.domain.notification;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.enums.CanalNotification;
import com.mbem.mbemlevel.domain.shared.enums.TypeNotification;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Notification in-app pour un utilisateur.
 * Les canaux EMAIL et WHATSAPP sont gérés par les adaptateurs dédiés.
 * IN_APP : stocké en base, affiché dans la cloche de l'interface.
 */
public class Notification extends AggregateRoot {
    private UUID              utilisateurId;
    private TypeNotification  typeNotif;
    private CanalNotification canal;
    private String            titre;
    private String            contenu;
    private boolean           estLue;
    private LocalDateTime     dateLecture;
    private String            lienAction;

    protected Notification() {
        super();
    }

    public static Notification creer(UUID utilisateurId, TypeNotification type,
                                      CanalNotification canal, String titre,
                                      String contenu, String lienAction) {
        Notification n = new Notification();
        n.utilisateurId = utilisateurId; n.typeNotif = type;
        n.canal = canal; n.titre = titre; n.contenu = contenu;
        n.estLue = false; n.lienAction = lienAction;
        return n;
    }
    public Notification(UUID id, UUID userId, TypeNotification type,
                        CanalNotification canal, String titre, String contenu,
                        boolean estLue, LocalDateTime dateLecture, String lienAction,
                        LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.utilisateurId = userId; this.typeNotif = type; this.canal = canal;
        this.titre = titre; this.contenu = contenu; this.estLue = estLue;
        this.dateLecture = dateLecture; this.lienAction = lienAction;
    }
    public void marquerLue() {
        this.estLue = true; this.dateLecture = LocalDateTime.now(); markUpdated();
    }
    public UUID              getUtilisateurId() { return utilisateurId; }
    public TypeNotification  getTypeNotif()     { return typeNotif; }
    public CanalNotification getCanal()         { return canal; }
    public String            getTitre()         { return titre; }
    public String            getContenu()       { return contenu; }
    public boolean           isEstLue()         { return estLue; }
    public LocalDateTime     getDateLecture()   { return dateLecture; }
    public String            getLienAction()    { return lienAction; }
}
