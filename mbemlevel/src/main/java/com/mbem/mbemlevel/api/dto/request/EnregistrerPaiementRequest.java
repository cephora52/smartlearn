package com.mbem.mbemlevel.api.dto.request;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record EnregistrerPaiementRequest(
    @NotNull UUID apprenantId,
    @NotNull UUID coursId,
    @Min(1) long montantTotal,
    @Min(1) long montantPremiereTranche,
    @Min(1) @Max(12) int nbTranches,
    @NotNull ModePaiement mode,
    @NotBlank String prenomApprenant,
    @NotBlank String emailApprenant,
    String telephoneApprenant,
    @NotBlank String nomCours
) {}
