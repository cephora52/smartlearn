package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.paiement.Moratoire;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MoratoireRepository {
    Moratoire save(Moratoire moratoire);
    Optional<Moratoire> findById(UUID id);
    List<Moratoire> findEnAttente();
    Optional<Moratoire> findEnAttenteByPaiementId(UUID paiementId);
    boolean existsEnAttenteForPaiement(UUID paiementId);
    List<Moratoire> findAll();
}
