package com.mbem.mbemlevel.application.usecase.communaute;

import com.mbem.mbemlevel.infrastructure.persistence.repository.MessageCommunauteJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S12 — Signaler un message abusif dans la communauté.
 * Règles :
 *  - Un apprenant peut signaler un message une seule fois
 *  - Après 3 signalements : masquage automatique en attente de validation admin
 *  - L'admin reçoit une notification si le seuil est atteint
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SignalerMessageUseCase {

    private static final int SEUIL_MASQUAGE_AUTO = 3;

    private final MessageCommunauteJpaRepository messageRepo;
    private final ApplicationEventPublisher       eventBus;

    @Transactional
    public void executer(UUID messageId, UUID apprenantId) {
        var message = messageRepo.findById(messageId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:MESSAGE"));

        // Incrémenter le compteur de signalements
        message.setNbSignalements(message.getNbSignalements() + 1);

        // Masquage automatique si seuil atteint
        if (message.getNbSignalements() >= SEUIL_MASQUAGE_AUTO && !message.isEstMasque()) {
            message.setEstMasque(true);
            eventBus.publishEvent(new MessageMasqueAutomatiqueEvent(messageId, message.getNbSignalements()));
            log.warn("[COMMUNAUTE] Message {} masqué automatiquement après {} signalements",
                messageId, message.getNbSignalements());
        }
        messageRepo.save(message);
        log.info("[COMMUNAUTE] Message {} signalé par apprenant {}", messageId, apprenantId);
    }

    public record MessageMasqueAutomatiqueEvent(UUID messageId, int nbSignalements) {}
}
