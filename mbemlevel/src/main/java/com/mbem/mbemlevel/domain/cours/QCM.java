package com.mbem.mbemlevel.domain.cours;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.mbem.mbemlevel.domain.shared.AggregateRoot;

/** QCM d'une leçon — obligatoire si configuré, score min 70%. */
public class QCM extends AggregateRoot {
    private UUID leconId;
    private String question;
    /** Options : [{id:"A",texte:"..."},{id:"B",texte:"..."}] */
    private List<Map<String, String>> options;
    private String bonneReponse;
    private boolean estObligatoire;
    private int scoreMinPct;

    public static QCM creer(UUID leconId, String question,
            List<Map<String, String>> options, String bonneReponse) {
        if (options == null || options.size() < 2)
            throw new IllegalArgumentException("Min 2 options");
        QCM q = new QCM();
        q.leconId = leconId;
        q.question = question;
        q.options = options;
        q.bonneReponse = bonneReponse;
        q.estObligatoire = true;
        q.scoreMinPct = 70;
        return q;
    }

    public QCM() {
        super();
    }

    public QCM(UUID id, UUID leconId, String question, List<Map<String, String>> options,
            String bonneReponse, boolean estObligatoire, int scoreMinPct,
            LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.leconId = leconId;
        this.question = question;
        this.options = options;
        this.bonneReponse = bonneReponse;
        this.estObligatoire = estObligatoire;
        this.scoreMinPct = scoreMinPct;
    }

    public boolean verifierReponse(String reponse) {
        return bonneReponse != null && bonneReponse.equalsIgnoreCase(reponse);
    }

    public UUID getLeconId() {
        return leconId;
    }

    public String getQuestion() {
        return question;
    }

    public List<Map<String, String>> getOptions() {
        return Collections.unmodifiableList(options);
    }

    public String getBonneReponse() {
        return bonneReponse;
    }

    public boolean isEstObligatoire() {
        return estObligatoire;
    }

    public int getScoreMinPct() {
        return scoreMinPct;
    }
}
