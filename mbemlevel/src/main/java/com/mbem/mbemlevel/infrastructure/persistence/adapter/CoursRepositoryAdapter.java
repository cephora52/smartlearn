package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.CoursRepository;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Component @RequiredArgsConstructor
public class CoursRepositoryAdapter implements CoursRepository {

    private final CoursJpaRepository repo;

    @Override @Transactional(readOnly=true)
    public Optional<Cours> findById(UUID id) { return repo.findById(id).map(this::toDomain); }

    @Override @Transactional(readOnly=true)
    public Optional<Cours> findBySlug(String slug) { return repo.findBySlug(slug).map(this::toDomain); }

    @Override @Transactional(readOnly=true)
    public Page<Cours> findCatalogue(NiveauCours niveau, UUID catId, Pageable p) {
        return repo.findCatalogue(niveau, catId, p).map(this::toDomain);
    }

    @Override @Transactional(readOnly=true)
    public boolean existsBySlug(String slug) { return repo.existsBySlug(slug); }

    @Override @Transactional
    public Cours save(Cours c) {
        return toDomain(repo.save(repo.findById(c.getId())
            .map(e -> update(c, e))
            .orElseGet(() -> toEntity(c))));
    }

    private CoursJpaEntity update(Cours c, CoursJpaEntity e) {
        e.setTitre(c.getTitre());
        e.setDescriptionCourte(c.getDescriptionCourte()); // ← corrigé
        e.setNiveau(c.getNiveau());
        e.setEstActif(c.isEstActif());
        e.setNbApprenants(c.getNbApprenants());
        return e;
    }

    private CoursJpaEntity toEntity(Cours c) {
        return CoursJpaEntity.builder()
            .id(c.getId())
            .titre(c.getTitre())
            .descriptionCourte(c.getDescriptionCourte())       // ← corrigé
            .descriptionLongue(c.getDescriptionLongue())
            .niveau(c.getNiveau())
            .categorieId(c.getCategorieId())
            .formateurId(c.getFormateurId())
            .seuilPaiement(c.getSeuilPaiement())               // ← corrigé : déjà BigDecimal
            .prixFcfa(c.getPrixFcfa())                         // ← corrigé : getPrixFcfa()
            .estActif(c.isEstActif())
            .slug(c.getSlug())
            .imageCouverture(c.getImageCouverture())
            .imageCouvertureThumbnail(c.getImageCouvertureThumbnail())
            .langue(c.getLangue() != null ? c.getLangue() : "fr")
            .statut(c.getStatut())
            .nbApprenants(c.getNbApprenants())
            .nbModules(c.getNbModules())
            .nbLecons(c.getNbLecons())
            .dureeTotaleMinutes(c.getDureeTotaleMinutes())
            .nbAvis(c.getNbAvis())
            .noteMoyenne(c.getNoteMoyenne())
            .build();
    }

    private Cours toDomain(CoursJpaEntity e) {
        return new Cours(
            e.getId(), e.getTitre(),
            e.getDescriptionCourte(),                          // ← corrigé
            e.getDescriptionLongue(),
            e.getNiveau(), e.getCategorieId(), e.getFormateurId(),
            e.getSlug(), e.getImageCouverture(), e.getImageCouvertureThumbnail(),
            e.getLangue(),
            e.getNbModules(), e.getNbLecons(), e.getDureeTotaleMinutes(),
            e.getNbApprenants(), e.getNoteMoyenne(), e.getNbAvis(),
            e.getSeuilPaiement(), e.getPrixFcfa(),             // ← corrigé
            e.getStatut(), e.isEstActif(),
            e.getCreatedAt(), e.getUpdatedAt());
    }
}