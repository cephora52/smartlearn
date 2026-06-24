package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.BlocContenuJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface BlocContenuJpaRepository extends JpaRepository<BlocContenuJpaEntity, UUID> {
    /** Blocs d'une leçon dans l'ordre d'affichage */
    List<BlocContenuJpaEntity> findByLeconIdOrderByOrdreAsc(UUID leconId);

    /** Supprimer tous les blocs d'une leçon (pour recréer depuis 0) */
    void deleteByLeconId(UUID leconId);

    /** Nombre de blocs d'une leçon */
    int countByLeconId(UUID leconId);
}
