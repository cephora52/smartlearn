package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.QCMJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface QCMJpaRepository extends JpaRepository<QCMJpaEntity, UUID> {
    /** QCM d'une leçon (une leçon peut avoir plusieurs questions) */
    List<QCMJpaEntity> findByLeconIdOrderByOrdreAsc(UUID leconId);

    /** Premier QCM d'une leçon (cas simple : une question par leçon) */
    Optional<QCMJpaEntity> findByLeconId(UUID leconId);

    boolean existsByLeconId(UUID leconId);
}
