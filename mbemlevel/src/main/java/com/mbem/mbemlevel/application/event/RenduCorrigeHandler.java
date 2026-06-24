package com.mbem.mbemlevel.application.event;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.RenduCorrigeEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
/** Notifie l'apprenant quand son rendu est corrigé (S23). */
@Component @RequiredArgsConstructor @Slf4j
public class RenduCorrigeHandler {
    private final EmailPort emailPort;
    @EventListener @Async
    public void handle(RenduCorrigeEvent e) {
        try { emailPort.envoyerRenduCorrige(e.email(), e.prenom(), "Votre devoir", e.note(), ""); }
        catch (Exception ex) { log.error("[EVENT] Erreur notif rendu: {}", ex.getMessage()); }
    }
}
