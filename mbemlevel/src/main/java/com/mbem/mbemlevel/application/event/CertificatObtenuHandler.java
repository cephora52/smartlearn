// MbemNova — application/event/CertificatObtenuHandler.java
// Handler : certificat obtenu → email félicitations + PDF (Scénario 13)
package com.mbem.mbemlevel.application.event;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.CertificatObtenuEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Certificat obtenu — email félicitations avec lien PDF. */
@Component
@RequiredArgsConstructor
@Slf4j
public class CertificatObtenuHandler {

    private final EmailPort emailPort;

    @EventListener
    @Async
    public void handleCertificatObtenu(CertificatObtenuEvent event) {
        try {
            emailPort.envoyerCertificatObtenu(
                event.email(), event.prenom(), event.nomCours(),
                null, event.codeVerif());
        } catch (Exception e) {
            log.error("[EVENT] Erreur email certificat pour {}: {}", event.email(), e.getMessage());
        }
    }
}
