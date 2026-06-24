package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record PaiementResponse(
    UUID id, UUID apprenantId, UUID coursId,
    String montantTotal, String montantPaye,
    ModePaiement mode, StatutPaiement statut,
    boolean accesActive, LocalDateTime dateActivation
) {
    public static PaiementResponse from(Paiement p) {
        return new PaiementResponse(p.getId(), p.getApprenantId(), p.getCoursId(),
            p.getMontantTotal().toDisplay(), p.getMontantPaye().toDisplay(),
            p.getModePaiement(), p.getStatut(), p.isAccesActive(), p.getDateActivation());
    }
}
