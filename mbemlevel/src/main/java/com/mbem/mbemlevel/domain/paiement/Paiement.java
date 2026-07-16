package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.event.PaiementConfirmeEvent;
import com.mbem.mbemlevel.domain.event.PaiementEnRetardEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Agrégat Paiement — racine du contexte financier.
 * Règles : acces_active seulement après confirmation admin.
 * S08 : enregistrerPaiement() → confirmer() → accès activé.
 */
public class Paiement extends AggregateRoot {
    private UUID          apprenantId;
    private UUID          coursId;
    private Money         montantTotal;
    private Money         montantPaye;
    private ModePaiement  modePaiement;
    private StatutPaiement statut;
    private UUID          adminId;
    private boolean       accesActive;
    private LocalDateTime dateActivation;
    private String        notesAdmin;

    public static Paiement creer(UUID apprenantId, UUID coursId,
                                  long montantTotal, ModePaiement mode) {
        Paiement p = new Paiement();
        p.apprenantId = apprenantId; p.coursId = coursId;
        p.montantTotal = Money.of(montantTotal); p.montantPaye = Money.ZERO;
        p.modePaiement = mode; p.statut = StatutPaiement.EN_ATTENTE;
        p.accesActive = false; return p;
    }


     public Paiement() {
        super();
    }

    public Paiement(UUID id, UUID apprenantId, UUID coursId,
                    long montantTotal, long montantPaye, ModePaiement mode,
                    StatutPaiement statut, UUID adminId, boolean accesActive,
                    LocalDateTime dateActivation, String notes,
                    LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId = apprenantId; this.coursId = coursId;
        this.montantTotal = Money.of(montantTotal); this.montantPaye = Money.of(montantPaye);
        this.modePaiement = mode; this.statut = statut; this.adminId = adminId;
        this.accesActive = accesActive; this.dateActivation = dateActivation; this.notesAdmin = notes;
    }

    /**
     * S08 — L'admin confirme le paiement et active l'accès complet au cours.
     * Publie PaiementConfirmeEvent → email + WhatsApp + génération facture.
     */
    public void confirmerEtActiverAcces(UUID adminId, long montantRecu,
                                         String prenom, String email,
                                         String telephone, String nomCours) {
        if (accesActive) throw new IllegalStateException("Accès déjà activé");
        this.adminId = adminId;
        this.montantPaye = this.montantPaye.plus(Money.of(montantRecu));
        this.accesActive = true;
        this.dateActivation = LocalDateTime.now();
        this.statut = montantPaye.isGreaterOrEq(montantTotal)
            ? StatutPaiement.PAYE : StatutPaiement.EN_ATTENTE;
        markUpdated();
        registerEvent(new PaiementConfirmeEvent(
            getId(), apprenantId, coursId, prenom, email, telephone, nomCours));
    }

    public void marquerEnRetard(String prenom, String email, String telephone, int joursRetard) {
        if (this.statut == StatutPaiement.PAYE) return;
        this.statut = StatutPaiement.EN_RETARD; markUpdated();
        registerEvent(new PaiementEnRetardEvent(
            getId(), apprenantId, prenom, email, telephone, joursRetard));
    }

    public void accorderMoratoire() {
        if (this.statut == StatutPaiement.PAYE) return;
        this.statut = StatutPaiement.MORATOIRE;
        markUpdated();
    }

    public UUID          getApprenantId()   { return apprenantId; }
    public UUID          getCoursId()       { return coursId; }
    public Money         getMontantTotal()  { return montantTotal; }
    public Money         getMontantPaye()   { return montantPaye; }
    public ModePaiement  getModePaiement()  { return modePaiement; }
    public StatutPaiement getStatut()       { return statut; }
    public boolean       isAccesActive()    { return accesActive; }
    public LocalDateTime getDateActivation(){ return dateActivation; }
    public UUID getAdminId() {
    return adminId;
}

public String getNotesAdmin() {
    return notesAdmin;
}
}
