package com.mbem.mbemlevel.application.usecase.gamification;

import com.mbem.mbemlevel.application.port.out.TirageAuSortRepository;
import com.mbem.mbemlevel.api.dto.response.DrawResponse;
import com.mbem.mbemlevel.domain.gamification.TirageAuSort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ObtenirTirageAuSortUseCase {

    private final TirageAuSortRepository tirageRepository;

    @Transactional(readOnly = true)
    public Optional<DrawResponse> executer() {
        return tirageRepository.findLatest().map(tirage -> {
            String dateDrawFormatee = formaterDate(tirage.getMois());
            String gagnantPrenom = tirage.getGagnantId() != null
                ? tirageRepository.findGagnantPrenom(tirage.getId()).orElse(null)
                : null;

            return new DrawResponse(
                tirage.getId().toString(),
                2000L, // Prix ticket indicatif (FCFA)
                dateDrawFormatee,
                tirage.getPrixDescription(),
                "Offert", // Valeur du lot
                tirage.getNbParticipants(),
                "GAGNANT_SELECTIONNE",
                gagnantPrenom
            );
        });
    }

    private String formaterDate(LocalDate date) {
        if (date == null) return "";
        String[] moisFr = {
            "janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"
        };
        int index = date.getMonthValue() - 1;
        String nomMois = (index >= 0 && index < 12) ? moisFr[index] : "";
        return "1er " + nomMois + " " + date.getYear();
    }
}
