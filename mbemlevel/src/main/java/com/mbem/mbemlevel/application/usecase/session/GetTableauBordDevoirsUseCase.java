package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.response.DevoirSuiviResponse;
import com.mbem.mbemlevel.application.port.out.SessionRepository;
import com.mbem.mbemlevel.domain.session.Devoir;
import com.mbem.mbemlevel.domain.session.Rendu;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetTableauBordDevoirsUseCase {

    private final SessionRepository sessionRepo;

    @Transactional(readOnly = true)
    public List<DevoirSuiviResponse> executer(UUID sessionId) {
        List<Devoir> devoirs = sessionRepo.findDevoirsParSession(sessionId);
        return devoirs.stream().map(d -> {
            List<Rendu> rendus = sessionRepo.findRendusParDevoir(d.getId());
            int total = rendus.size();
            int aTemps = (int) rendus.stream().filter(r -> !r.isEnRetard()).count();
            int enRetard = (int) rendus.stream().filter(Rendu::isEnRetard).count();
            return new DevoirSuiviResponse(
                d.getId(), d.getTitre(), d.getDateRemise(),
                total, aTemps, enRetard
            );
        }).toList();
    }
}
