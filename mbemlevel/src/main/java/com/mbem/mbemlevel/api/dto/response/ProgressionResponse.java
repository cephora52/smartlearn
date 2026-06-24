package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.progression.Progression;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProgressionResponse(
    UUID id, UUID coursId, double pourcentage, boolean estPaye,
    int xpGagne, boolean seuilAtteint, boolean estTermine,
    LocalDateTime dateDebut, LocalDateTime dateCompletion
) {
    public static ProgressionResponse from(Progression p) {
        return new ProgressionResponse(p.getId(), p.getCoursId(), p.getPourcentage(),
            p.isEstPaye(), p.getXpGagne(), p.seuilAtteint(), p.estTermine(),
            p.getDateDebut(), p.getDateCompletion());
    }
}
