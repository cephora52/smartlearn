package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.LeconJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface LeconJpaRepository extends JpaRepository<LeconJpaEntity, UUID> {
    List<LeconJpaEntity> findByCoursIdOrderByOrdreAsc(UUID coursId);
    int countByCoursId(UUID coursId);
}
