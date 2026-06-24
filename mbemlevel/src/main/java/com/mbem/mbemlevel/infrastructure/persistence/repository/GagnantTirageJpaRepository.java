package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.GagnantTirageJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface GagnantTirageJpaRepository extends JpaRepository<GagnantTirageJpaEntity, UUID> {
    List<GagnantTirageJpaEntity> findByTirageIdOrderByRangAsc(UUID tirageId);
}
