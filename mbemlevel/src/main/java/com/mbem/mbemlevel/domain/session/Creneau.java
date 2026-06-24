package com.mbem.mbemlevel.domain.session;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.*;
/** Créneau hebdomadaire d'une session — jour + heure. */
public class Creneau extends AggregateRoot {
    private java.util.UUID sessionId;
    private int    jourSemaine; // 1=Lun…7=Dim
    private LocalTime heureDebut;
    private LocalTime heureFin;

    public static Creneau creer(java.util.UUID sessionId, int jour,
                                 LocalTime debut, LocalTime fin) {
        if (jour < 1 || jour > 7) throw new IllegalArgumentException("Jour 1-7");
        if (!fin.isAfter(debut))  throw new IllegalArgumentException("heureFin > heureDebut");
        Creneau c = new Creneau(); c.sessionId = sessionId;
        c.jourSemaine = jour; c.heureDebut = debut; c.heureFin = fin; return c;
    }
      public Creneau() {
                super();
            }


    public Creneau(java.util.UUID id, java.util.UUID sessionId, int jour,
                   LocalTime debut, LocalTime fin,
                   LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.sessionId = sessionId; this.jourSemaine = jour;
        this.heureDebut = debut; this.heureFin = fin;
    }
    public java.util.UUID getSessionId()  { return sessionId; }
    public int            getJourSemaine(){ return jourSemaine; }
    public LocalTime      getHeureDebut() { return heureDebut; }
    public LocalTime      getHeureFin()   { return heureFin; }
}
