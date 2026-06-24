package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.TrancheRepository;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import com.mbem.mbemlevel.infrastructure.persistence.entity.TrancheJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.TrancheJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class TrancheRepositoryAdapter implements TrancheRepository {

    private final TrancheJpaRepository repo;

    @Override @Transactional
    public Tranche save(Tranche t) {
        return toDomain(repo.save(toEntity(t)));
    }

    @Override @Transactional
    public List<Tranche> saveAll(List<Tranche> tranches) {
        return repo.saveAll(tranches.stream().map(this::toEntity).collect(Collectors.toList()))
            .stream().map(this::toDomain).collect(Collectors.toList());
    }

    @Override @Transactional(readOnly = true)
    public Optional<Tranche> findById(UUID id) {
        return repo.findById(id).map(this::toDomain);
    }

    @Override @Transactional(readOnly = true)
    public List<Tranche> findByPaiementId(UUID paiementId) {
        return repo.findByPaiementId(paiementId).stream()
            .map(this::toDomain).collect(Collectors.toList());
    }

    @Override @Transactional(readOnly = true)
    public List<Tranche> findEnRetard() {
        return repo.findTranchesEnRetard(LocalDate.now()).stream()
            .map(this::toDomain).collect(Collectors.toList());
    }

    @Override @Transactional(readOnly = true)
    public List<Tranche> findEcheantEntre(LocalDate debut, LocalDate fin) {
        return repo.findTranchesEcheantEntre(debut, fin).stream()
            .map(this::toDomain).collect(Collectors.toList());
    }

    @Override @Transactional
    public void updateDateEcheance(UUID paiementId, LocalDate nouvelleDateEcheance) {
        repo.findByPaiementId(paiementId).stream()
            .filter(t -> "EN_ATTENTE".equals(t.getStatut()))
            .min(Comparator.comparing(TrancheJpaEntity::getDateEcheance))
            .ifPresent(t -> {
                t.setDateEcheance(nouvelleDateEcheance);
                repo.save(t);
            });
    }

    private Tranche toDomain(TrancheJpaEntity e) {
        return new Tranche(e.getId(), e.getPaiementId(), e.getNumero(),
            e.getMontant(), e.getDateEcheance(), e.getDateReglement(),
            e.getStatut(), e.getCreatedAt(), e.getUpdatedAt());
    }

    private TrancheJpaEntity toEntity(Tranche t) {
        return TrancheJpaEntity.builder()
            .id(t.getId() != null ? t.getId() : UUID.randomUUID())
            .paiementId(t.getPaiementId())
            .numero(t.getNumero())
            .montant(t.getMontant().toLong())
            .dateEcheance(t.getDateEcheance())
            .dateReglement(t.getDateReglement())
            .statut(t.getStatut())
            .build();
    }
}
