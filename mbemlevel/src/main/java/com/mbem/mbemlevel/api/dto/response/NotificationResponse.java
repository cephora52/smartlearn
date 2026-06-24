package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.notification.Notification;
import com.mbem.mbemlevel.domain.shared.enums.TypeNotification;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record NotificationResponse(
    UUID id, TypeNotification type, String titre,
    String contenu, boolean estLue,
    LocalDateTime createdAt, String lienAction
) {
    public static NotificationResponse from(Notification n) {
        return new NotificationResponse(n.getId(), n.getTypeNotif(), n.getTitre(),
            n.getContenu(), n.isEstLue(), n.getCreatedAt(), n.getLienAction());
    }
}
