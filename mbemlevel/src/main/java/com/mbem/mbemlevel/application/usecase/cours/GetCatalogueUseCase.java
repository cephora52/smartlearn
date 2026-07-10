package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.projection.CoursCatalogueProjection;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S4 — Catalogue des formations.
 *
 * PERFORMANCE :
 * - @Cacheable : résultat mis en cache Redis 10 min
 * - Projection légère : ne charge PAS description_longue, objectifs, débouchés
 * - Pagination : max 20 items/page
 * - Index idx_cours_catalogue utilisé automatiquement
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GetCatalogueUseCase {

    private final CoursJpaRepository coursRepo;

    /**
     * Cache clé : niveau-categorieId-page-size
     * Ex: "DEBUTANT-null-0-12" ou "null-uuid-1-12"
     * TTL : 10 min (configuré dans CacheConfig)
     * Invalidé par : @CacheEvict dans PublierCoursUseCase
     */
    @Cacheable(
        value   = "catalogue",
        key     = "(#niveau ?: 'null') + '-' + (#categorieId ?: 'null') + '-' + #page + '-' + #size",
        unless  = "#result == null"
    )
    @Transactional(readOnly = true)
    public Page<CoursResponse> executer(NiveauCours niveau, UUID categorieId, int page, int size) {
        int pageSize = Math.min(size, 20); // Max 20 items par page
        Pageable pageable = PageRequest.of(page, pageSize,
            Sort.by(Sort.Direction.DESC, "nbApprenants")); // Les plus populaires en premier

        log.debug("[CATALOGUE] Cache miss — chargement depuis PostgreSQL: niveau={}, cat={}, page={}",
            niveau, categorieId, page);

        // Projection légère (pas de description_longue, objectifs, etc.)
        return coursRepo.findCatalogueProjection(niveau, categorieId, pageable)
          .map(p -> new CoursResponse(
    p.getId(), p.getTitre(), p.getDescriptionCourte(),
    p.getNiveau(), p.getLangue(),
    p.getImageCouvertureThumbnail(),
    p.getNbApprenants(), p.getNoteMoyenne(), p.getNbLecons(),
    p.getDureeTotaleMinutes(), p.getPrixFcfa(), p.getSeuilPaiement(),
    null,   // slug — ajouter à CoursCatalogueProjection si nécessaire
    null    // statut — toujours "PUBLIE" dans ce contexte
));
    }
}
