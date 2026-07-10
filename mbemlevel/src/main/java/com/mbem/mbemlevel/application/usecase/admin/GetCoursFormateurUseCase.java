package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.api.dto.response.CoursResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/**
 * Récupérer les cours d'un formateur donné.
 */
@Service
@RequiredArgsConstructor
public class GetCoursFormateurUseCase {

    private final CoursJpaRepository coursRepo;

    @Transactional(readOnly = true)
    public List<CoursResponse> executer(UUID formateurId) {
        return coursRepo.findByFormateurId(formateurId)
            .stream()
            .map(CoursResponse::fromEntity)
            .toList();
    }
}
