package com.mbem.mbemlevel.domain.session;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.enums.Modalite;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Agrégat Session de formation.
 * Règles : capacite_max respectée, apprenant != formateur, dates cohérentes.
 * S09 : préinscription → admin confirme → inscription officielle.
 */
public class Session extends AggregateRoot {
    private UUID      coursId;
    private UUID      formateurId;
    private String    titre;
    private Modalite  modalite;
    private LocalDate dateDebut;
    private LocalDate dateFin;
    private int       capaciteMax;
    private int       nbInscrits;
    private String    lienReunion;  // Google Meet / Zoom
    private String    lieu;         // Adresse présentiel
    private boolean   estActive;

    public static Session creer(UUID coursId, UUID formateurId, String titre,
                                 Modalite modalite, LocalDate debut, LocalDate fin,
                                 int capaciteMax) {
        if (debut == null || fin == null || fin.isBefore(debut))
            throw new IllegalArgumentException("Dates de session invalides");
        if (capaciteMax < 1) throw new IllegalArgumentException("Capacité min 1");
        Session s = new Session(); s.coursId = coursId; s.formateurId = formateurId;
        s.titre = titre.trim(); s.modalite = modalite; s.dateDebut = debut;
        s.dateFin = fin; s.capaciteMax = capaciteMax; s.nbInscrits = 0;
        s.estActive = true; return s;
    }
    public Session(UUID id, UUID coursId, UUID formateurId, String titre,
                   Modalite modalite, LocalDate debut, LocalDate fin,
                   int capaciteMax, int nbInscrits, String lienReunion,
                   String lieu, boolean estActive,
                   LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.coursId = coursId; this.formateurId = formateurId; this.titre = titre;
        this.modalite = modalite; this.dateDebut = debut; this.dateFin = fin;
        this.capaciteMax = capaciteMax; this.nbInscrits = nbInscrits;
        this.lienReunion = lienReunion; this.lieu = lieu; this.estActive = estActive;
    }

      public Session() {
                super();
     }

    public void inscrireApprenant(UUID apprenantId) {
        if (apprenantId.equals(formateurId))
            throw new IllegalArgumentException("Le formateur ne peut pas s'inscrire à sa propre session");
        if (nbInscrits >= capaciteMax)
            throw new IllegalStateException("SESSION_FULL");
        this.nbInscrits++; markUpdated();
    }
    public void desinscrireApprenant() {
        if (nbInscrits > 0) { this.nbInscrits--; markUpdated(); }
    }
    public boolean hasPlacesDisponibles() { return nbInscrits < capaciteMax; }
    public int     getPlacesRestantes()   { return capaciteMax - nbInscrits; }

    public UUID     getCoursId()       { return coursId; }
    public UUID     getFormateurId()   { return formateurId; }
    public String   getTitre()         { return titre; }
    public Modalite getModalite()      { return modalite; }
    public LocalDate getDateDebut()    { return dateDebut; }
    public LocalDate getDateFin()      { return dateFin; }
    public int      getCapaciteMax()   { return capaciteMax; }
    public int      getNbInscrits()    { return nbInscrits; }
    public String   getLienReunion()   { return lienReunion; }
    public String   getLieu()          { return lieu; }
    public boolean  isEstActive()      { return estActive; }
    public void     setLienReunion(String l) { this.lienReunion = l; markUpdated(); }
}
