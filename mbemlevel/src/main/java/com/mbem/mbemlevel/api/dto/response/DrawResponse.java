package com.mbem.mbemlevel.api.dto.response;

public record DrawResponse(
    String id,
    long prixTicketFcfa,
    String dateDrawFormatee,
    String formationGagnanteTitre,
    String formationGagnantePrix,
    int nbTicketsVendus,
    String statut,
    String gagnantPrenom
) {}
