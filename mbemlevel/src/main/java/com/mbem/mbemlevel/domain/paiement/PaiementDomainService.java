package com.mbem.mbemlevel.domain.paiement;

import com.mbem.mbemlevel.domain.shared.Money;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** Règles métier plan de paiement et calcul des tranches. */
public class PaiementDomainService {
    /** Génère un plan de tranches mensuelles. */
    public List<Tranche> genererPlan(Paiement paiement, int nbTranches,
            long montantPremiereTranche) {
        List<Tranche> plan = new ArrayList<>();
        long reste = paiement.getMontantTotal().toLong() - montantPremiereTranche;
        long parTranche = nbTranches > 1 ? reste / (nbTranches - 1) : 0;
        plan.add(Tranche.creer(paiement.getId(), 1, montantPremiereTranche, LocalDate.now()));
        for (int i = 2; i <= nbTranches; i++) {
            long m = (i == nbTranches) ? (reste - parTranche * (nbTranches - 2)) : parTranche;
            plan.add(Tranche.creer(paiement.getId(), i, m, LocalDate.now().plusMonths(i - 1)));
        }
        return plan;
    }

    public PaiementDomainService() {
        super();
    }

    /** Calcule les jours de retard d'une tranche. */
    public int joursDeRetard(Tranche tranche) {
        if (!tranche.estEnRetard())
            return 0;
        return (int) java.time.temporal.ChronoUnit.DAYS.between(tranche.getDateEcheance(), LocalDate.now());
    }
}
