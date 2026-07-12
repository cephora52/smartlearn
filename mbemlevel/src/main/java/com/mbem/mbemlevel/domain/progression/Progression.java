package com.mbem.mbemlevel.domain.progression;
import com.mbem.mbemlevel.domain.event.SeuilPaiementAtteintEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Agrégat Progression — état d'avancement d'un apprenant dans un cours.
 * Règle clé : quand pourcentage >= seuilPaiement → publier SeuilPaiementAtteintEvent.
 */
public class Progression extends AggregateRoot {
    private UUID         apprenantId;
    private UUID         coursId;
    private double       pourcentage;    // 0.0 – 100.0
    private boolean      estPaye;
    private int          xpGagne;
    private LocalDateTime dateDebut;
    private LocalDateTime dateCompletion;
    /** Pourcentage du cours après lequel le paiement est demandé (config du cours). */
    private double       seuilPaiementCours;

    public static Progression commencer(UUID apprenantId, UUID coursId,
                                         double seuilPaiementCours) {
        Progression p = new Progression();
        p.apprenantId = apprenantId; p.coursId = coursId;
        p.pourcentage = 0.0; p.estPaye = false; p.xpGagne = 0;
        p.dateDebut = LocalDateTime.now(); p.seuilPaiementCours = seuilPaiementCours;
        return p;
    }
      public Progression() {
        super();
    }

    public Progression(UUID id, UUID apprenantId, UUID coursId, double pourcentage,
                       boolean estPaye, int xpGagne, LocalDateTime dateDebut,
                       LocalDateTime dateCompletion, double seuilPaiementCours,
                       LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId = apprenantId; this.coursId = coursId;
        this.pourcentage = pourcentage; this.estPaye = estPaye; this.xpGagne = xpGagne;
        this.dateDebut = dateDebut; this.dateCompletion = dateCompletion;
        this.seuilPaiementCours = seuilPaiementCours;
    }

    private boolean isSeuilAtteint(double pct) {
        if (seuilPaiementCours >= 1.0) {
            return false;
        }
        return pct >= (seuilPaiementCours * 100);
    }

    /**
     * Avance la progression et publie SeuilPaiementAtteintEvent si seuil franchi.
     * @param nouveauPct    Nouveau pourcentage calculé
     * @param xpLecon       XP gagnés pour cette leçon
     * @param prenom        Pour l'event (email nurturing)
     * @param email         Pour l'event
     * @param telephone     Pour l'event WhatsApp
     * @param nomCours      Pour l'event
     */
    public void avancer(double nouveauPct, int xpLecon, String prenom,
                        String email, String telephone, String nomCours) {
        boolean dejaSeuilAtteint = isSeuilAtteint(this.pourcentage);
        boolean nouveauSeuilAtteint = isSeuilAtteint(nouveauPct);
        this.pourcentage = Math.min(100.0, nouveauPct);
        this.xpGagne += xpLecon;
        // Publier l'event seulement la première fois que le seuil est franchi
        if (!dejaSeuilAtteint && nouveauSeuilAtteint && !estPaye) {
            registerEvent(new SeuilPaiementAtteintEvent(
                apprenantId, coursId, prenom, email, telephone, nomCours, this.pourcentage));
        }
        // Cours terminé à 100%
        if (this.pourcentage >= 100.0 && dateCompletion == null) {
            this.dateCompletion = LocalDateTime.now();
        }
        markUpdated();
    }

    public void activerPaiement() { this.estPaye = true; markUpdated(); }
    public boolean seuilAtteint() { return isSeuilAtteint(this.pourcentage); }
    public boolean estTermine()   { return pourcentage >= 100.0; }
    public boolean peutAccederLeconSuivante() { return estPaye || !seuilAtteint(); }

    public UUID          getApprenantId()   { return apprenantId; }
    public UUID          getCoursId()       { return coursId; }
    public double        getPourcentage()   { return pourcentage; }
    public boolean       isEstPaye()        { return estPaye; }
    public int           getXpGagne()       { return xpGagne; }
    public LocalDateTime getDateDebut()     { return dateDebut; }
    public LocalDateTime getDateCompletion(){ return dateCompletion; }
}
