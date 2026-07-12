package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.gamification.TirageAuSort;
import java.util.Optional;
import java.util.UUID;

public interface TirageAuSortRepository {
    void sauvegarder(TirageAuSort tirage, UUID adminId);
    Optional<TirageAuSort> findLatest();
    Optional<String> findGagnantPrenom(UUID tirageId);
}
