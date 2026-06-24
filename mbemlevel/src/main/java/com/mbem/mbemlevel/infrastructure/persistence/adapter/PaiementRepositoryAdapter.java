package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.domain.paiement.*;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class PaiementRepositoryAdapter implements PaiementRepository {
    private final PaiementJpaRepository paiementRepo;
    private final TrancheJpaRepository trancheRepo;

    @Override
    @Transactional(readOnly = true)
    public Optional<Paiement> findById(UUID id) {
        return paiementRepo.findById(id).map(this::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Paiement> findByIdAndApprenantId(UUID paiementId, UUID apprenantId) {
        return paiementRepo.findByIdAndApprenantId(paiementId, apprenantId).map(this::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Paiement> findByApprenantIdAndCoursId(UUID aid, UUID cid) {
        return paiementRepo.findByApprenantIdAndCoursId(aid, cid).map(this::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Paiement> findByApprenantId(UUID aid) {
        return paiementRepo.findByApprenantId(aid).stream().map(this::toDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Paiement> findPaiementsEnCours() {
        return paiementRepo.findPaiementsEnCours().stream().map(this::toDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public Paiement save(Paiement p) {
        return toDomain(paiementRepo.save(paiementRepo.findById(p.getId())
                .map(e -> updateEntity(p, e)).orElseGet(() -> toEntity(p))));
    }

    @Override
    @Transactional
    public void saveTranches(List<Tranche> tranches) {
        trancheRepo.saveAll(tranches.stream().map(this::trancheToEntity).collect(Collectors.toList()));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Tranche> findTranchesParPaiement(UUID pid) {
        return trancheRepo.findByPaiementId(pid).stream().map(this::trancheToDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Tranche> findTranchesEnRetard() {
        return trancheRepo.findTranchesEnRetard(LocalDate.now()).stream().map(this::trancheToDomain)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Tranche> findTranchesEcheantEntre(LocalDate d, LocalDate f) {
        return trancheRepo.findTranchesEcheantEntre(d, f).stream().map(this::trancheToDomain)
                .collect(Collectors.toList());
    }

    // ── Mappers ───────────────────────────────────────────────────────────────
    private Paiement toDomain(PaiementJpaEntity e) {
        return new Paiement(e.getId(), e.getApprenantId(), e.getCoursId(),
                e.getMontantTotal(), e.getMontantPaye(), e.getModePaiement(),
                e.getStatut(), e.getAdminId(), e.isAccesActive(), e.getDateActivation(),
                e.getNotesAdmin(), e.getCreatedAt(), e.getUpdatedAt());
    }

    private PaiementJpaEntity toEntity(Paiement p) {
        return PaiementJpaEntity.builder().id(p.getId())
                .apprenantId(p.getApprenantId()).coursId(p.getCoursId())
                .montantTotal(p.getMontantTotal().toLong()).montantPaye(p.getMontantPaye().toLong())
                .modePaiement(p.getModePaiement()).statut(p.getStatut())
                .accesActive(p.isAccesActive()).dateActivation(p.getDateActivation()).notesAdmin(p.getNotesAdmin())
                .build();
    }

    private PaiementJpaEntity updateEntity(Paiement p, PaiementJpaEntity e) {
        e.setMontantPaye(p.getMontantPaye().toLong());
        e.setStatut(p.getStatut());
        e.setAdminId(p.getAdminId());
        e.setNotesAdmin(p.getNotesAdmin());
        e.setAccesActive(p.isAccesActive());
        e.setDateActivation(p.getDateActivation());
        return e;
    }

    private Tranche trancheToDomain(TrancheJpaEntity e) {
        return new Tranche(e.getId(), e.getPaiementId(), e.getNumero(), e.getMontant(),
                e.getDateEcheance(), e.getDateReglement(), e.getStatut(), e.getCreatedAt(), e.getUpdatedAt());
    }

    private TrancheJpaEntity trancheToEntity(Tranche t) {
        return TrancheJpaEntity.builder().id(t.getId() != null ? t.getId() : UUID.randomUUID())
                .paiementId(t.getPaiementId()).numero(t.getNumero())
                .montant(t.getMontant().toLong()).dateEcheance(t.getDateEcheance())
                .dateReglement(t.getDateReglement()).statut(t.getStatut()).build();
    }
}
