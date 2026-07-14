package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.api.dto.response.CoursResponse;
import com.mbem.mbemlevel.application.port.out.StoragePort;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

/**
 * S19 — Récupérer les cours en attente de publication pour l'admin.
 * Cours avec statut BROUILLON ou EN_REVISION.
 */
@Service
@RequiredArgsConstructor
public class GetCoursEnAttenteUseCase {

    private final CoursJpaRepository coursRepo;
    private final StoragePort storagePort;

    @Transactional(readOnly = true)
    public List<CoursResponse> executer() {
        return coursRepo.findByStatutIn(List.of("BROUILLON", "EN_REVISION"))
            .stream()
            .map(e -> CoursResponse.fromEntity(e, storagePort))
            .toList();
    }
}
