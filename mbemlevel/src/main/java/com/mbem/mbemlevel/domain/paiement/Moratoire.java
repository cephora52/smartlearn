package com.mbem.mbemlevel.domain.paiement;

import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Aggregate Moratoire — demande de délai de paiement (S17).
 *
 * CORRECTION s23 :
 *   accorder(UUID adminId, LocalDate nouvelleDateAccordee)
 *   refuser(UUID adminId, String justificationRefus)
 */
public class Moratoire extends AggregateRoot {

    private UUID      id;
    private UUID      paiementId;
    private String    raison;
    private LocalDate nouvelleDateSouhaitee;
    private LocalDate nouvelleDateAccordee;    // Remplie si accordé
    private String    statut;                  // EN_ATTENTE | APPROUVE | REFUSE
    private UUID      adminId;
    private String    justificationRefus;
    private LocalDateTime dateDecision;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ── Factory ──────────────────────────────────────────────────────────────

    public static Moratoire creer(UUID paiementId, String raison,
                                   LocalDate nouvelleDateSouhaitee) {
        Moratoire m = new Moratoire();
        m.id = UUID.randomUUID();
        m.paiementId = paiementId;
        m.raison = raison;
        m.nouvelleDateSouhaitee = nouvelleDateSouhaitee;
        m.statut = "EN_ATTENTE";
        m.createdAt = LocalDateTime.now();
        m.updatedAt = LocalDateTime.now();
        return m;
    }

    // ── Comportements domaine ─────────────────────────────────────────────────

    /**
     * L'admin accorde le moratoire avec une nouvelle date d'échéance.
     *
     * @param adminId               Admin qui prend la décision
     * @param nouvelleDateAccordee  Nouvelle date d'échéance accordée
     */
    public void accorder(UUID adminId, LocalDate nouvelleDateAccordee) {
        if (!"EN_ATTENTE".equals(this.statut)) {
            throw new IllegalStateException("Moratoire déjà traité : " + this.statut);
        }
        this.statut = "APPROUVE";
        this.adminId = adminId;
        this.nouvelleDateAccordee = nouvelleDateAccordee;
        this.dateDecision = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    /**
     * L'admin refuse le moratoire avec une justification.
     *
     * @param adminId              Admin qui prend la décision
     * @param justificationRefus   Raison du refus communiquée à l'apprenant
     */
    public void refuser(UUID adminId, String justificationRefus) {
        if (!"EN_ATTENTE".equals(this.statut)) {
            throw new IllegalStateException("Moratoire déjà traité : " + this.statut);
        }
        this.statut = "REFUSE";
        this.adminId = adminId;
        this.justificationRefus = justificationRefus;
        this.dateDecision = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    // ── Reconstitution ────────────────────────────────────────────────────────

    public Moratoire(UUID id, UUID paiementId, String raison,
                     LocalDate nouvelleDateSouhaitee, LocalDate nouvelleDateAccordee,
                     String statut, UUID adminId, String justificationRefus,
                     LocalDateTime dateDecision,
                     LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id; this.paiementId = paiementId; this.raison = raison;
        this.nouvelleDateSouhaitee = nouvelleDateSouhaitee;
        this.nouvelleDateAccordee = nouvelleDateAccordee;
        this.statut = statut; this.adminId = adminId;
        this.justificationRefus = justificationRefus;
        this.dateDecision = dateDecision;
        this.createdAt = createdAt; this.updatedAt = updatedAt;
    }

    public Moratoire() {}

    // ── Getters ───────────────────────────────────────────────────────────────
    public UUID      getId()                    { return id; }
    public UUID      getPaiementId()            { return paiementId; }
    public String    getRaison()                { return raison; }
    public LocalDate getNouvelleDate()          { return nouvelleDateSouhaitee; }
    public LocalDate getNouvelledateSouhaitee() { return nouvelleDateSouhaitee; }
    public LocalDate getNouvelledateAccordee()  { return nouvelleDateAccordee; }
    public String    getStatut()                { return statut; }
    public UUID      getAdminId()               { return adminId; }
    public String    getJustificationRefus()    { return justificationRefus; }
    public LocalDateTime getDateDecision()      { return dateDecision; }
    public LocalDateTime getCreatedAt()         { return createdAt; }
    public LocalDateTime getUpdatedAt()         { return updatedAt; }
}
