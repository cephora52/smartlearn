// MbemNova — application/event/CompteSuspenduHandler.java
// Handler : compte suspendu → email suspension (Scénario 18)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.CompteSuspenduEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Réagit à la suspension de compte — email empathique avec instructions. */
@Component
@RequiredArgsConstructor
@Slf4j
public class CompteSuspenduHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handleCompteSuspendu(CompteSuspenduEvent event) {
        try {
            emailPort.envoyerSuspension(
                event.email(), event.prenom(), event.messagePersonnalise());
        } catch (Exception e) {
            log.error("[EVENT] Erreur email suspension pour {}: {}", event.email(), e.getMessage());
        }
    }
}
