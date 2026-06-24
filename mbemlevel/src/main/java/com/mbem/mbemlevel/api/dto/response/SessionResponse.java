package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.session.Session;
import com.mbem.mbemlevel.domain.shared.enums.Modalite;
import java.time.LocalDate;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record SessionResponse(
    UUID id, UUID coursId, String titre, Modalite modalite,
    LocalDate dateDebut, LocalDate dateFin,
    int capaciteMax, int nbInscrits, int placesRestantes,
    String lienReunion, String lieu, boolean estActive
) {
    public static SessionResponse from(Session s) {
        return new SessionResponse(s.getId(), s.getCoursId(), s.getTitre(),
            s.getModalite(), s.getDateDebut(), s.getDateFin(),
            s.getCapaciteMax(), s.getNbInscrits(), s.getPlacesRestantes(),
            s.getLienReunion(), s.getLieu(), s.isEstActive());
    }
}
