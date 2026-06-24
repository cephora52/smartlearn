package com.mbem.mbemlevel.application.event;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.ParrainageActiveEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
/** Notifie le parrain quand son filleul active la récompense. */
@Component @RequiredArgsConstructor @Slf4j
public class ParrainageActiveHandler {
    private final EmailPort emailPort;
    @EventListener @Async
    public void handle(ParrainageActiveEvent e) {
        try { emailPort.envoyerRecomparainageActive(e.emailParrain(), "Parrain", "Filleul"); }
        catch (Exception ex) { log.error("[EVENT] Erreur parrainage: {}", ex.getMessage()); }
    }
}
