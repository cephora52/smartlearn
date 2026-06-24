package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.notification.Notification;
import java.util.*;
public interface NotificationRepository {
    Notification         save(Notification notification);
    List<Notification>   findByUtilisateur(UUID utilisateurId);
    List<Notification>   findNonLues(UUID utilisateurId);
    int                  marquerToutesLues(UUID utilisateurId);
    Optional<Notification> findById(UUID id);
}
