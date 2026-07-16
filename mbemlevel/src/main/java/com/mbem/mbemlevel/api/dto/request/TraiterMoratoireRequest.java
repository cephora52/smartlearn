package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

/** S17 — Décision admin sur une demande de moratoire */
public record TraiterMoratoireRequest(
    /** ACCORDE, APPROUVE ou REFUSE */
    @NotBlank @Pattern(regexp = "ACCORDE|APPROUVE|REFUSE")
    String decision,

    /** Nouvelle date accordée (obligatoire si decision=ACCORDE) */
    LocalDate nouvelleDateAccordee,

    /** Justification du refus (obligatoire si decision=REFUSE) */
    @Size(max = 500)
    String justificationRefus
) {}
