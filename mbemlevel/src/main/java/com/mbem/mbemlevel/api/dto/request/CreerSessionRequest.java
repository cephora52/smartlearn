package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/** S20 — Création d'une session par l'admin */
public record CreerSessionRequest(
    @NotNull UUID coursId,
    @NotNull UUID formateurId,

    @NotNull @Future LocalDate dateDebut,
    @NotNull          LocalDate dateFin,

    /** PRESENTIEL ou MEET */
    @NotBlank @Pattern(regexp = "PRESENTIEL|MEET")
    String modalite,

    /** Lieu physique (si PRESENTIEL) ou lien Meet (si MEET) */
    @Size(max = 300) String lieuOuLien,

    @Min(1) @Max(200)
    int capaciteMax,

    /**
     * Créneaux récurrents de la session.
     * Ex: Lundi 18h-20h, Samedi 9h-12h
     */
    @NotEmpty @Valid
    List<CreneauSessionRequest> creneaux
) {}
