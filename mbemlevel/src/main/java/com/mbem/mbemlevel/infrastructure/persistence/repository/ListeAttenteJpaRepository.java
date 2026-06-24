package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ListeAttenteJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ListeAttenteJpaRepository extends JpaRepository<ListeAttenteJpaEntity, UUID> {
    Optional<ListeAttenteJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<ListeAttenteJpaEntity> findByCoursIdAndStatutOrderByDateInscriptionAsc(UUID coursId, String statut);
    boolean existsByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
}
