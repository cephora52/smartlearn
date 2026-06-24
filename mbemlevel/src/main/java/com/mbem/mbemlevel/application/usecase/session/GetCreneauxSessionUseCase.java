package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.response.CreneauResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CreneauJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/** S10 — Récupérer les créneaux disponibles d'une session */
@Service
@RequiredArgsConstructor
public class GetCreneauxSessionUseCase {

    private final CreneauJpaRepository creneauRepo;

    @Transactional(readOnly = true)
    public List<CreneauResponse> executer(UUID sessionId) {
        return creneauRepo.findBySessionId(sessionId)
            .stream()
            .map(c -> new CreneauResponse(
                c.getId(), c.getSessionId(),
                c.getJourSemaine(), c.getHeureDebut(),
                c.getDureeMinutes(), c.getCapaciteMax(),
                c.getPlacesRestantes(), null
            ))
            .toList();
    }
}
