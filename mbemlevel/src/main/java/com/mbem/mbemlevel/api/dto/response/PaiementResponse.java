package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record PaiementResponse(
    UUID id, UUID apprenantId, UUID coursId,
    String coursTitre,
    String montantTotal, String montantPaye,
    ModePaiement mode, StatutPaiement statut,
    boolean accesActive, LocalDateTime dateActivation,
    List<TrancheResponse> tranches
) {
    public static PaiementResponse from(Paiement p) {
        return new PaiementResponse(p.getId(), p.getApprenantId(), p.getCoursId(),
            null,
            p.getMontantTotal().toDisplay(), p.getMontantPaye().toDisplay(),
            p.getModePaiement(), p.getStatut(), p.isAccesActive(), p.getDateActivation(),
            null);
    }
}
