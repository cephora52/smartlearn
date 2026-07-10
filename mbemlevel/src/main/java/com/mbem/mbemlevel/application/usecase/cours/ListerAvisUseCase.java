package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.response.AvisCoursResponse;
import com.mbem.mbemlevel.application.port.out.AvisCoursRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ListerAvisUseCase {
    private final AvisCoursRepository avisRepo;

    @Transactional(readOnly = true)
    public List<AvisCoursResponse> executer(UUID coursId) {
        return avisRepo.findByCours(coursId)
            .stream()
            .filter(AvisCoursJpaEntity::isEstVerifie)
            .map(a -> new AvisCoursResponse(
                a.getId(), a.getApprenantId(), a.getNote(),
                a.getCommentaire(), a.getCreatedAt()
            ))
            .toList();
    }
}
