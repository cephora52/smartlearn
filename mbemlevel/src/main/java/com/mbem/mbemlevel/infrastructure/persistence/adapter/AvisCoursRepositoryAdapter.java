package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.AvisCoursRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.AvisCoursJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class AvisCoursRepositoryAdapter implements AvisCoursRepository {

    private final AvisCoursJpaRepository repo;

    @Override
    public AvisCoursJpaEntity save(AvisCoursJpaEntity avis) {
        return repo.save(avis);
    }

    @Override
    public List<AvisCoursJpaEntity> findByCours(UUID coursId) {
        return repo.findByCoursId(coursId);
    }

    @Override
    public Optional<AvisCoursJpaEntity> findByCoursAndApprenant(UUID coursId, UUID apprenantId) {
        return repo.findByCoursIdAndApprenantId(coursId, apprenantId);
    }

    @Override
    public int compterAvisVerifies(UUID coursId) {
        return repo.compterAvisVerifies(coursId);
    }

    @Override
    public boolean existsByCoursAndApprenant(UUID coursId, UUID apprenantId) {
        return repo.existsByCoursIdAndApprenantId(coursId, apprenantId);
    }

    @Override
    public double calculerNoteMoyenne(UUID coursId) {
        return repo.calculerNoteMoyenne(coursId).orElse(0.0);
    }
}
