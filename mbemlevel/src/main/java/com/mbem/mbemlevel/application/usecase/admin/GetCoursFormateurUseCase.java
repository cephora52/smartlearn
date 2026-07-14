package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.api.dto.response.CoursResponse;
import com.mbem.mbemlevel.application.port.out.StoragePort;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/**
 * Récupérer les cours d'un formateur donné avec filtres, tri et limite.
 */
@Service
@RequiredArgsConstructor
public class GetCoursFormateurUseCase {

    private final CoursJpaRepository coursRepo;
    private final ProgressionJpaRepository progressionRepo;
    private final StoragePort storagePort;

    @Transactional(readOnly = true)
    public List<CoursResponse> executer(
            UUID formateurId,
            Integer limit,
            String sortBy,
            String sortDir,
            String domaine,
            String niveau,
            String statut,
            String q) {

        Sort.Direction direction = "ASC".equalsIgnoreCase(sortDir) ? Sort.Direction.ASC : Sort.Direction.DESC;

        // Check if sorting is by completionRate
        if ("completionRate".equalsIgnoreCase(sortBy)) {
            int pageSize = (limit != null && limit > 0) ? limit : Integer.MAX_VALUE;
            Pageable pageable = PageRequest.of(0, pageSize);
            List<Object[]> results = coursRepo.findTopCoursesByCompletionRate(formateurId, pageable);
            
            return results.stream().map(row -> {
                CoursJpaEntity entity = (CoursJpaEntity) row[0];
                Double avgCompletion = (Double) row[1];
                long enrollCount = progressionRepo.countByCoursId(entity.getId());
                return new CoursResponse(
                    entity.getId(), entity.getTitre(), entity.getDescriptionCourte(),
                    entity.getNiveau(), entity.getLangue(),
                    entity.getImageCouvertureThumbnail() != null && !entity.getImageCouvertureThumbnail().isBlank()
                        ? storagePort.presignedUrl(entity.getImageCouvertureThumbnail())
                        : null,
                    (int) enrollCount,
                    entity.getNoteMoyenne(),
                    entity.getNbLecons(), entity.getDureeTotaleMinutes(),
                    entity.getPrixFcfa(), entity.getSeuilPaiement(),
                    entity.getStatut(), entity.getSlug(),
                    null, null,
                    avgCompletion
                );
            }).toList();
        }

        // Check if sorting is by nbApprenants
        if ("nbApprenants".equalsIgnoreCase(sortBy)) {
            int pageSize = (limit != null && limit > 0) ? limit : Integer.MAX_VALUE;
            Pageable pageable = PageRequest.of(0, pageSize);
            List<Object[]> results = coursRepo.findTopCoursesByEnrollments(formateurId, pageable);
            
            return results.stream().map(row -> {
                CoursJpaEntity entity = (CoursJpaEntity) row[0];
                Long enrollCount = (Long) row[1];
                Double completionRate = progressionRepo.getAverageCompletionRateByCoursId(entity.getId());
                return new CoursResponse(
                    entity.getId(), entity.getTitre(), entity.getDescriptionCourte(),
                    entity.getNiveau(), entity.getLangue(),
                    entity.getImageCouvertureThumbnail() != null && !entity.getImageCouvertureThumbnail().isBlank()
                        ? storagePort.presignedUrl(entity.getImageCouvertureThumbnail())
                        : null,
                    enrollCount.intValue(),
                    entity.getNoteMoyenne(),
                    entity.getNbLecons(), entity.getDureeTotaleMinutes(),
                    entity.getPrixFcfa(), entity.getSeuilPaiement(),
                    entity.getStatut(), entity.getSlug(),
                    null, null,
                    completionRate
                );
            }).toList();
        }

        // Parse level filter
        NiveauCours niveauEnum = null;
        if (niveau != null && !niveau.isBlank()) {
            try {
                niveauEnum = NiveauCours.valueOf(niveau.toUpperCase());
            } catch (IllegalArgumentException ignored) {}
        }

        // Parse category filter UUID
        UUID categoryId = null;
        if (domaine != null && !domaine.isBlank()) {
            try {
                categoryId = UUID.fromString(domaine);
            } catch (IllegalArgumentException ignored) {}
        }

        // Build sorting and pageable
        String sortField = sortBy != null && !sortBy.isBlank() ? sortBy : "id";
        Sort sort = Sort.by(direction, sortField);
        int pageSize = (limit != null && limit > 0) ? limit : Integer.MAX_VALUE;
        Pageable pageable = PageRequest.of(0, pageSize, sort);

        // Pre-format search query for LIKE pattern
        String searchPattern = null;
        if (q != null && !q.isBlank()) {
            searchPattern = "%" + q.trim().toLowerCase() + "%";
        }

        // Fetch courses with filters
        Page<CoursJpaEntity> pageResult = coursRepo.findByFormateurIdWithFilters(
            formateurId,
            (statut != null && !statut.isBlank()) ? statut.toUpperCase() : null,
            niveauEnum,
            categoryId,
            searchPattern,
            pageable
        );

        return pageResult.getContent().stream().map(e -> {
            Double completionRate = progressionRepo.getAverageCompletionRateByCoursId(e.getId());
            long enrollCount = progressionRepo.countByCoursId(e.getId());
            return new CoursResponse(
                e.getId(), e.getTitre(), e.getDescriptionCourte(),
                e.getNiveau(), e.getLangue(),
                e.getImageCouvertureThumbnail() != null && !e.getImageCouvertureThumbnail().isBlank()
                    ? storagePort.presignedUrl(e.getImageCouvertureThumbnail())
                    : null,
                (int) enrollCount,
                e.getNoteMoyenne(),
                e.getNbLecons(), e.getDureeTotaleMinutes(),
                e.getPrixFcfa(), e.getSeuilPaiement(),
                e.getStatut(), e.getSlug(),
                null, null,
                completionRate
            );
        }).toList();
    }
}
