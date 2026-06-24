package com.mbem.mbemlevel.api.dto.request;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record CreerCoursRequest(
    @NotBlank @Size(max=200) String titre,
    @Size(max=5000)           String description,
    @NotNull                  NiveauCours niveau,
    UUID                      categorieId,
    @DecimalMin("0.01") @DecimalMax("1.0") double seuilPaiement,
    @Min(0)             long  prixFcfa
) {}
