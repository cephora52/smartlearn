package com.mbem.mbemlevel.domain.progression;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Réponse d'un apprenant à un QCM — résultat et tentative. */
public class ReponseQCM extends AggregateRoot {
    private UUID    progressionId;
    private UUID    qcmId;
    private String  reponseDonnee;
    private boolean estCorrecte;
    private int     score;
    private int     tentative;

    public static ReponseQCM creer(UUID progressionId, UUID qcmId,
                                    String reponse, boolean correcte, int score) {
        ReponseQCM r = new ReponseQCM();
        r.progressionId = progressionId; r.qcmId = qcmId;
        r.reponseDonnee = reponse; r.estCorrecte = correcte;
        r.score = score; r.tentative = 1; return r;
    }

            public ReponseQCM() {
                super();
            }

    public ReponseQCM(UUID id, UUID progressionId, UUID qcmId, String reponse,
                      boolean correcte, int score, int tentative,
                      LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.progressionId = progressionId; this.qcmId = qcmId;
        this.reponseDonnee = reponse; this.estCorrecte = correcte;
        this.score = score; this.tentative = tentative;
    }
    public UUID    getProgressionId()  { return progressionId; }
    public UUID    getQcmId()          { return qcmId; }
    public String  getReponseDonnee()  { return reponseDonnee; }
    public boolean isEstCorrecte()     { return estCorrecte; }
    public int     getScore()          { return score; }
    public int     getTentative()      { return tentative; }
}
