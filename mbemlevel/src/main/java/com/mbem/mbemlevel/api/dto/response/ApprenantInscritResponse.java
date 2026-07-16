package com.mbem.mbemlevel.api.dto.response;

import java.time.LocalDateTime;

public record ApprenantInscritResponse(
    String photoUrl,
    String nom,
    String prenom,
    String email,
    LocalDateTime dateInscription,
    double progression,
    String statut
) {}
