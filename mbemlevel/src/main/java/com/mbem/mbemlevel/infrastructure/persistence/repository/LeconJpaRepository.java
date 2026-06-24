package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.LeconJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface LeconJpaRepository extends JpaRepository<LeconJpaEntity, UUID> {
    List<LeconJpaEntity> findByModuleIdOrderByOrdreAsc(UUID moduleId);
    int countByModuleId(UUID moduleId);

    @Query("SELECT COUNT(l) FROM LeconJpaEntity l " +
           "JOIN ModuleJpaEntity m ON l.moduleId = m.id " +
           "WHERE m.coursId = :coursId")
    int countByCoursId(UUID coursId);
}
