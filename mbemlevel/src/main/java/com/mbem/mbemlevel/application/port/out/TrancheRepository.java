package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.paiement.Tranche;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TrancheRepository {
    Tranche save(Tranche tranche);
    List<Tranche> saveAll(List<Tranche> tranches);
    Optional<Tranche> findById(UUID id);
    List<Tranche> findByPaiementId(UUID paiementId);
    List<Tranche> findEnRetard();
    List<Tranche> findEcheantEntre(LocalDate debut, LocalDate fin);

    /**
     * S17 — Mettre à jour la date d'échéance de la prochaine tranche non payée
     * après accord d'un moratoire.
     */
    void updateDateEcheance(UUID paiementId, LocalDate nouvelleDateEcheance);
}
