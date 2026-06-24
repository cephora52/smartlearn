package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ParrainageResponse(
    String        codeParrainage,
    String        lienParrainage,    // mbemnova.com/ref/{code}
    String        messageWhatsApp,   // Message pré-rempli prêt à partager
    int           nbFilleulsInvites,
    int           nbFilleulsActifs,
    int           xpTotalGagne,
    List<FilleulSommaireResponse> filleuls
) {}
