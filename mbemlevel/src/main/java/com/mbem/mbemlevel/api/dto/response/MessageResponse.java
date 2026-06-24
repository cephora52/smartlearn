package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record MessageResponse(
    UUID id, UUID auteurId, UUID parentId,
    String contenu, boolean estQuestion, boolean estResolu,
    int nbLikes, LocalDateTime createdAt
) {
    public static MessageResponse from(MessageCommunaute m) {
        return new MessageResponse(m.getId(), m.getAuteurId(), m.getParentId(),
            m.getContenu(), m.isEstQuestion(), m.isEstResolu(),
            m.getNbLikes(), m.getCreatedAt());
    }
}
