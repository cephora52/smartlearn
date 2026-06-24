package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CertificatJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface CertificatJpaRepository extends JpaRepository<CertificatJpaEntity, UUID> {
    Optional<CertificatJpaEntity> findByCodeVerification(String code);
    Optional<CertificatJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<CertificatJpaEntity> findByApprenantId(UUID apprenantId);
}
