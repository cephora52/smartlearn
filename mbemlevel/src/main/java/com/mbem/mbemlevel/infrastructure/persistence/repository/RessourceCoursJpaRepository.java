package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.RessourceCoursJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface RessourceCoursJpaRepository extends JpaRepository<RessourceCoursJpaEntity, UUID> {
    List<RessourceCoursJpaEntity> findByCoursId(UUID coursId);
    List<RessourceCoursJpaEntity> findByLeconId(UUID leconId);
    List<RessourceCoursJpaEntity> findByCoursIdAndEstPublicTrue(UUID coursId);
}
