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
import java.time.LocalDateTime;

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

    @Override @Transactional(readOnly=true)
    public long count() { return repo.count(); }

    private String resolveUniqueSlug(String baseSlug, UUID id) {
        if (baseSlug == null || baseSlug.isEmpty()) {
            return UUID.randomUUID().toString();
        }
        String slug = baseSlug;
        int count = 1;
        while (true) {
            Optional<CoursJpaEntity> existing = repo.findBySlug(slug);
            if (existing.isEmpty() || existing.get().getId().equals(id)) {
                return slug;
            }
            slug = baseSlug + "-" + count;
            count++;
        }
    }

    @Override @Transactional
    public Cours save(Cours c) {
        return toDomain(repo.save(repo.findById(c.getId())
            .map(e -> update(c, e))
            .orElseGet(() -> toEntity(c))));
    }

    private String toJson(List<String> list) {
        if (list == null) return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append("\"").append(list.get(i).replace("\"", "\\\"")).append("\"");
        }
        sb.append("]");
        return sb.toString();
    }

    private List<String> fromJson(String json) {
        if (json == null || json.isEmpty() || "[]".equals(json)) return new ArrayList<>();
        List<String> list = new ArrayList<>();
        String content = json.trim();
        if (content.startsWith("[") && content.endsWith("]")) {
            content = content.substring(1, content.length() - 1);
            if (!content.isEmpty()) {
                String[] items = content.split("\",\"");
                for (String item : items) {
                    list.add(item.replace("\"", ""));
                }
            }
        }
        return list;
    }

    private CoursJpaEntity update(Cours c, CoursJpaEntity e) {
        e.setTitre(c.getTitre());
        e.setDescriptionCourte(c.getDescriptionCourte());
        e.setDescriptionLongue(c.getDescriptionLongue());
        e.setNiveau(c.getNiveau());
        e.setCategorieId(c.getCategorieId());
        e.setFormateurId(c.getFormateurId());
        e.setSeuilPaiement(c.getSeuilPaiement());
        e.setPrixFcfa(c.getPrixFcfa());
        e.setEstActif(c.isEstActif());
        e.setSlug(resolveUniqueSlug(c.getSlug(), c.getId()));
        e.setImageCouverture(c.getImageCouverture());
        e.setImageCouvertureThumbnail(c.getImageCouvertureThumbnail());
        e.setStatut(c.getStatut());
        e.setNbApprenants(c.getNbApprenants());
        e.setNbModules(c.getNbModules());
        e.setNbLecons(c.getNbLecons());
        e.setDureeTotaleMinutes(c.getDureeTotaleMinutes());
        e.setNbAvis(c.getNbAvis());
        e.setNoteMoyenne(c.getNoteMoyenne());
        e.setObjectifsApprentissageJson(toJson(c.getObjectifsApprentissage()));
        e.setPrerequis(c.getPrerequis());
        e.setPublicCible(c.getPublicCible());
        e.setDebouchesJson(c.getDebouchesJson());
        e.setUpdatedAt(c.getUpdatedAt() != null ? c.getUpdatedAt() : LocalDateTime.now());
        return e;
    }

    private CoursJpaEntity toEntity(Cours c) {
        return CoursJpaEntity.builder()
            .id(c.getId())
            .titre(c.getTitre())
            .descriptionCourte(c.getDescriptionCourte())
            .descriptionLongue(c.getDescriptionLongue())
            .niveau(c.getNiveau())
            .categorieId(c.getCategorieId())
            .formateurId(c.getFormateurId())
            .seuilPaiement(c.getSeuilPaiement())
            .prixFcfa(c.getPrixFcfa())
            .estActif(c.isEstActif())
            .slug(resolveUniqueSlug(c.getSlug(), c.getId()))
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
            .objectifsApprentissageJson(toJson(c.getObjectifsApprentissage()))
            .prerequis(c.getPrerequis())
            .publicCible(c.getPublicCible())
            .debouchesJson(c.getDebouchesJson())
            .createdAt(c.getCreatedAt() != null ? c.getCreatedAt() : LocalDateTime.now())
            .updatedAt(c.getUpdatedAt() != null ? c.getUpdatedAt() : LocalDateTime.now())
            .build();
    }

    private Cours toDomain(CoursJpaEntity e) {
        Cours c = new Cours(
            e.getId(), e.getTitre(),
            e.getDescriptionCourte(),
            e.getDescriptionLongue(),
            e.getNiveau(), e.getCategorieId(), e.getFormateurId(),
            e.getSlug(), e.getImageCouverture(), e.getImageCouvertureThumbnail(),
            e.getLangue(),
            e.getNbModules(), e.getNbLecons(), e.getDureeTotaleMinutes(),
            e.getNbApprenants(), e.getNoteMoyenne(), e.getNbAvis(),
            e.getSeuilPaiement(), e.getPrixFcfa(),
            e.getStatut(), e.isEstActif(),
            e.getCreatedAt(), e.getUpdatedAt());
        c.setObjectifsApprentissage(fromJson(e.getObjectifsApprentissageJson()));
        c.setPrerequisEtPublicCible(e.getPrerequis(), e.getPublicCible());
        c.setDebouchesJson(e.getDebouchesJson());
        return c;
    }
}