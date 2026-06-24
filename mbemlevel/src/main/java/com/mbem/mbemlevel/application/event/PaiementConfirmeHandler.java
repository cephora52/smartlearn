// MbemNova — application/event/PaiementConfirmeHandler.java
// Handler : paiement confirmé → active accès + génère facture (Scénario 08)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.PaiementConfirmeEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Paiement confirmé — email confirmation + lien facture PDF. */
@Component
@RequiredArgsConstructor
@Slf4j
public class PaiementConfirmeHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handlePaiementConfirme(PaiementConfirmeEvent event) {
        try {
            // La génération PDF et l'activation accès sont dans PaiementUseCase
            // Ce handler gère uniquement la notification email
            emailPort.envoyerActivationAcces(
                event.email(), event.prenom(), event.nomCours(), null);
        } catch (Exception e) {
            log.error("[EVENT] Erreur email paiement confirmé pour {}: {}",
                event.email(), e.getMessage());
        }
    }
}
