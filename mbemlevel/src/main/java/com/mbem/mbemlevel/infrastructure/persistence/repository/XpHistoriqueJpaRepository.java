package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.XpHistoriqueJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface XpHistoriqueJpaRepository extends JpaRepository<XpHistoriqueJpaEntity, UUID> {
    List<XpHistoriqueJpaEntity> findByApprenantIdAndDateGainAfter(UUID apprenantId, LocalDateTime dateLimit);
}
