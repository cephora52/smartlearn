package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.gamification.Parrainage;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ParrainageRepository {
    Parrainage save(Parrainage parrainage);
    Optional<Parrainage> findByCode(String code);
    Optional<Parrainage> findByFilleulId(UUID filleulId);
    List<Parrainage> findByParrainId(UUID parrainId);
    long countActifsByParrainId(UUID parrainId);
}
