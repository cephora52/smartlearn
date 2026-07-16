package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.response.ApprenantInscritResponse;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetApprenantsInscritsUseCase {

    private final CoursJpaRepository coursRepo;
    private final ProgressionJpaRepository progressionRepo;

    @Transactional(readOnly = true)
    public List<ApprenantInscritResponse> executer(UUID coursId, UUID formateurId) {
        CoursJpaEntity cours = coursRepo.findById(coursId)
                .orElseThrow(() -> new IllegalArgumentException("Cours introuvable."));

        // Only the formateur who owns the course can see the enrolled learners
        if (!cours.getFormateurId().equals(formateurId)) {
            throw new AccessDeniedException("Accès refusé.");
        }

        List<Object[]> queryResults = progressionRepo.findApprenantsByCoursId(coursId);

        return queryResults.stream().map(row -> {
            ProgressionJpaEntity p = (ProgressionJpaEntity) row[0];
            UtilisateurJpaEntity u = (UtilisateurJpaEntity) row[1];

            double pct = p.getPourcentage();
            String statut = (pct >= 100.0 || p.getDateCompletion() != null) ? "Terminée" : "En cours";
            
            // Photo URL is not stored on UtilisateurJpaEntity, so we set to null
            String photoUrl = null;

            return new ApprenantInscritResponse(
                photoUrl,
                u.getNom(),
                u.getPrenom(),
                u.getEmail(),
                p.getCreatedAt() != null ? p.getCreatedAt() : p.getDateDebut(),
                pct,
                statut
            );
        }).toList();
    }
}
