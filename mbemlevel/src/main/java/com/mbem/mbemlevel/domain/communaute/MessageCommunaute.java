package com.mbem.mbemlevel.domain.communaute;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Message de la communauté Q&R — question ou réponse dans le contexte d'un cours. */
public class MessageCommunaute extends AggregateRoot {
    private UUID    coursId;
    private UUID    auteurId;
    private UUID    parentId;       // null = question racine, non-null = réponse
    private String  contenu;
    private boolean estQuestion;
    private boolean estResolu;
    private boolean estModere;
    private int     nbLikes;

    protected MessageCommunaute() {
        super();
    }

    public static MessageCommunaute poserQuestion(UUID coursId, UUID auteurId,
                                                   String contenu) {
        if (contenu == null || contenu.isBlank())
            throw new IllegalArgumentException("Contenu obligatoire");
        MessageCommunaute m = new MessageCommunaute();
        m.coursId = coursId; m.auteurId = auteurId;
        m.contenu = contenu.trim(); m.estQuestion = true;
        m.estResolu = false; m.estModere = false; m.nbLikes = 0;
        return m;
    }
    public static MessageCommunaute repondre(UUID coursId, UUID auteurId,
                                              UUID parentId, String contenu) {
        MessageCommunaute m = poserQuestion(coursId, auteurId, contenu);
        m.parentId = parentId; m.estQuestion = false;
        return m;
    }
    public MessageCommunaute(UUID id, UUID coursId, UUID auteurId, UUID parentId,
                              String contenu, boolean estQuestion, boolean estResolu,
                              boolean estModere, int nbLikes,
                              LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.coursId = coursId; this.auteurId = auteurId; this.parentId = parentId;
        this.contenu = contenu; this.estQuestion = estQuestion; this.estResolu = estResolu;
        this.estModere = estModere; this.nbLikes = nbLikes;
    }
    public void marquerResolu()  { this.estResolu = true;  markUpdated(); }
    public void moderer()        { this.estModere = true;  markUpdated(); }
    public void liker()          { this.nbLikes++;          markUpdated(); }

    public UUID    getCoursId()     { return coursId; }
    public UUID    getAuteurId()    { return auteurId; }
    public UUID    getParentId()    { return parentId; }
    public String  getContenu()     { return contenu; }
    public boolean isEstQuestion()  { return estQuestion; }
    public boolean isEstResolu()    { return estResolu; }
    public boolean isEstModere()    { return estModere; }
    public int     getNbLikes()     { return nbLikes; }
}
