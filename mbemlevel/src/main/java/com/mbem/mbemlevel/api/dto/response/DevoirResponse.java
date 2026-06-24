package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.session.Devoir;
import com.mbem.mbemlevel.infrastructure.persistence.entity.DevoirJpaEntity;
import java.time.LocalDateTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record DevoirResponse(
    UUID          id,
    UUID          sessionId,
    String        titre,
    String        consignes,
    LocalDateTime dateRemise,
    boolean       estVerrouille,
    LocalDateTime createdAt
) {
    public static DevoirResponse from(Devoir devoir) {
        return new DevoirResponse(
            devoir.getId(),
            devoir.getSessionId(),
            devoir.getTitre(),
            devoir.getConsignes(),
            devoir.getDateRemise(),
            devoir.isEstVerrouille(),
            devoir.getCreatedAt()
        );
    }
}