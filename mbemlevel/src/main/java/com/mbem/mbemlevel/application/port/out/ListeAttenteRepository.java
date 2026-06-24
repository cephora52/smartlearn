package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ListeAttenteJpaEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ListeAttenteRepository {
    ListeAttenteJpaEntity save(ListeAttenteJpaEntity entry);
    Optional<ListeAttenteJpaEntity> findByApprenantAndCours(UUID apprenantId, UUID coursId);
    List<ListeAttenteJpaEntity> findEnAttenteForCours(UUID coursId);
    boolean existsByApprenantAndCours(UUID apprenantId, UUID coursId);
}
