package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ModuleJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ModuleJpaRepository extends JpaRepository<ModuleJpaEntity, UUID> {
    List<ModuleJpaEntity> findByCoursIdOrderByOrdreAsc(UUID coursId);
    int countByCoursId(UUID coursId);
}
