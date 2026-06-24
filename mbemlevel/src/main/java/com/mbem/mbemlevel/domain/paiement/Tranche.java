package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
/** Tranche d'un plan de paiement échelonné. */
public class Tranche extends AggregateRoot {
    private UUID          paiementId;
    private int           numero;
    private Money         montant;
    private LocalDate     dateEcheance;
    private LocalDate     dateReglement;
    private StatutPaiement statut;

    public static Tranche creer(UUID paiementId, int numero, long montantFcfa,
                                 LocalDate dateEcheance) {
        Tranche t = new Tranche(); t.paiementId = paiementId; t.numero = numero;
        t.montant = Money.of(montantFcfa); t.dateEcheance = dateEcheance;
        t.statut = StatutPaiement.EN_ATTENTE; return t;
    }

     public Tranche() {
        super();
    }

    public Tranche(UUID id, UUID paiementId, int numero, long montantFcfa,
                   LocalDate echeance, LocalDate reglement, StatutPaiement statut,
                   LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.paiementId = paiementId; this.numero = numero;
        this.montant = Money.of(montantFcfa); this.dateEcheance = echeance;
        this.dateReglement = reglement; this.statut = statut;
    }
    public void marquerPaye() {
        this.statut = StatutPaiement.PAYE; this.dateReglement = LocalDate.now(); markUpdated();
    }
    public void marquerEnRetard() { this.statut = StatutPaiement.EN_RETARD; markUpdated(); }
    public void marquerMoratoire() { this.statut = StatutPaiement.MORATOIRE; markUpdated(); }
    public boolean estEnRetard() {
        return statut == StatutPaiement.EN_ATTENTE && LocalDate.now().isAfter(dateEcheance);
    }

    public UUID          getPaiementId()   { return paiementId; }
    public int           getNumero()       { return numero; }
    public Money         getMontant()      { return montant; }
    public LocalDate     getDateEcheance() { return dateEcheance; }
    public LocalDate     getDateReglement(){ return dateReglement; }
    public StatutPaiement getStatut()      { return statut; }
}
