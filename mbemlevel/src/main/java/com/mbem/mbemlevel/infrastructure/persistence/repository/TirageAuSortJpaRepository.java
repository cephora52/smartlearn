package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.TirageAuSortJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.GagnantTirageJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TirageAuSortJpaRepository extends JpaRepository<TirageAuSortJpaEntity, UUID> {
    boolean existsByMois(String mois);
    Optional<TirageAuSortJpaEntity> findByMois(String mois);
}
