package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.exception.MbemNovaException;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.PaiementJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.SessionJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SupprimerCoursUseCase {

    private final CoursJpaRepository coursRepo;
    private final PaiementJpaRepository paiementRepo;
    private final SessionJpaRepository sessionRepo;
    private final ProgressionJpaRepository progressionRepo;

    @Transactional
    public void executer(UUID coursId, UUID formateurId) {
        CoursJpaEntity cours = coursRepo.findById(coursId)
                .orElseThrow(() -> new IllegalArgumentException("Cours introuvable."));

        // Check ownership
        if (!cours.getFormateurId().equals(formateurId)) {
            throw new AccessDeniedException("Accès refusé.");
        }

        // Verify data integrity rules
        boolean hasSessions = sessionRepo.existsByCoursId(coursId);
        boolean hasPaiements = paiementRepo.existsByCoursId(coursId);
        boolean hasProgressions = progressionRepo.existsByCoursId(coursId);

        if (hasSessions || hasPaiements || hasProgressions) {
            throw new MbemNovaException(
                "Impossible de supprimer cette formation car des apprenants y sont déjà inscrits, elle est associée à des paiements ou possède des sessions actives.",
                HttpStatus.BAD_REQUEST,
                "COURSE_HAS_DEPENDENCIES"
            );
        }

        // Safe to delete
        coursRepo.delete(cours);
    }
}
