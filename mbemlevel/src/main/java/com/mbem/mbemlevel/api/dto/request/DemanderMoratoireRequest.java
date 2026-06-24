package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.UUID;

/** S17 — Demande de moratoire par l'apprenant */
public record DemanderMoratoireRequest(
    @NotNull
    UUID paiementId,

    /**
     * Raison choisie dans la liste :
     * DIFFICULTES_FINANCIERES | PROBLEME_SANTE | URGENCE_FAMILIALE | AUTRE
     */
    @NotBlank @Size(max = 50)
    String raison,

    /** Explication libre optionnelle */
    @Size(max = 1000)
    String explicationLibre,

    /** Nouvelle date souhaitée pour le paiement */
    @NotNull @Future
    LocalDate nouvelleDateSouhaitee
) {}
