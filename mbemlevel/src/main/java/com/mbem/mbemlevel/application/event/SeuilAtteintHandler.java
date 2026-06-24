// MbemNova — application/event/SeuilAtteintHandler.java
// Handler : seuil de conversion atteint → email nurturing (Scénario 07)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.SeuilPaiementAtteintEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Réagit au seuil de paiement atteint — déclenche l'email de nurturing. */
@Component
@RequiredArgsConstructor
@Slf4j
public class SeuilAtteintHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handleSeuilAtteint(SeuilPaiementAtteintEvent event) {
        try {
            emailPort.envoyerNurturingSeuilAtteint(
                event.email(), event.prenom(), event.nomCours());
            log.debug("[EVENT] Email nurturing envoyé à: {}", event.email());
        } catch (Exception e) {
            log.error("[EVENT] Erreur nurturing pour {}: {}", event.email(), e.getMessage());
        }
    }
}
