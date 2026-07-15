package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.MoratoireRepository;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MoratoireJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.MoratoireJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class MoratoireRepositoryAdapter implements MoratoireRepository {

    private final MoratoireJpaRepository repo;

    @Override @Transactional
    public Moratoire save(Moratoire m) {
        return toDomain(repo.save(toEntity(m)));
    }

    @Override @Transactional(readOnly = true)
    public Optional<Moratoire> findById(UUID id) {
        return repo.findById(id).map(this::toDomain);
    }

    @Override @Transactional(readOnly = true)
    public List<Moratoire> findEnAttente() {
        return repo.findByStatut("EN_ATTENTE").stream()
            .map(this::toDomain).collect(Collectors.toList());
    }

    @Override @Transactional(readOnly = true)
    public Optional<Moratoire> findEnAttenteByPaiementId(UUID paiementId) {
        return repo.findByPaiementIdAndStatut(paiementId, "EN_ATTENTE")
            .map(this::toDomain);
    }

    @Override @Transactional(readOnly = true)
    public boolean existsEnAttenteForPaiement(UUID paiementId) {
        return repo.existsByPaiementIdAndStatut(paiementId, "EN_ATTENTE");
    }

    @Override @Transactional(readOnly = true)
    public List<Moratoire> findAll() {
        return repo.findAll().stream()
            .map(this::toDomain).collect(Collectors.toList());
    }

    private Moratoire toDomain(MoratoireJpaEntity e) {
        return new Moratoire(
            e.getId(), e.getPaiementId(), e.getRaison(),
            e.getNouvelleDate(),        // nouvelleDateSouhaitee
            e.getNouvelleDateAccordee(), // nouvelleDateAccordee
            e.getStatut(), e.getAdminId(),
            e.getJustificationRefus(), e.getDateDecision(),
            e.getCreatedAt(), e.getUpdatedAt());
    }

    private MoratoireJpaEntity toEntity(Moratoire m) {
        return MoratoireJpaEntity.builder()
            .id(m.getId() != null ? m.getId() : UUID.randomUUID())
            .paiementId(m.getPaiementId())
            .raison(m.getRaison())
            .nouvelleDate(m.getNouvelleDate())   // getNouvelleDate() → nouvelleDateSouhaitee
            .nouvelleDateAccordee(m.getNouvelledateAccordee())
            .statut(m.getStatut())
            .adminId(m.getAdminId())
            .justificationRefus(m.getJustificationRefus())
            .dateDecision(m.getDateDecision())
            .build();
    }
}