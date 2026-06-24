// =============================================================================
// MbemNova — application/event/ApprenantInscritHandler.java
//
// Handler réagissant à ApprenantInscritEvent.
// Déclenché APRÈS la persistance de l'utilisateur.
//
// Actions :
//   1. Envoyer l'email de bienvenue immédiatement
//   2. (Future) Programmer le rappel 48h via le scheduler
// =============================================================================
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.ApprenantInscritEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Réagit à {@link ApprenantInscritEvent}.
 * {@code @Async} : l'email est envoyé dans un thread séparé pour ne pas
 * bloquer la réponse HTTP de l'inscription.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ApprenantInscritHandler {

    private final EmailPort emailPort;

    /**
     * Envoie l'email de bienvenue après l'inscription.
     * L'annotation @Async évite de bloquer la transaction principale.
     */
    @EventListener
    @Async
    public void handleApprenantInscrit(ApprenantInscritEvent event) {
        try {
            emailPort.envoyerBienvenue(event.email(), event.prenom());
            log.debug("[EVENT] Email bienvenue envoyé à: {}", event.email());
        } catch (Exception e) {
            // Ne jamais faire échouer l'inscription à cause de l'email
            log.error("[EVENT] Erreur envoi email bienvenue pour {}: {}",
                event.email(), e.getMessage());
        }
    }
}
