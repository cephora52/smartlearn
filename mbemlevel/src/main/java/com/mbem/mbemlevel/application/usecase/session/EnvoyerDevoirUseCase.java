package com.mbem.mbemlevel.application.usecase.session;
import com.mbem.mbemlevel.application.port.out.SessionRepository;
import com.mbem.mbemlevel.domain.session.Devoir;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;
/**
 * S11 — Formateur publie un devoir → event → notifications apprenants.
 */
@Service @RequiredArgsConstructor @Slf4j
public class EnvoyerDevoirUseCase {
    private final SessionRepository    sessionRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public Devoir executer(UUID sessionId, UUID moduleId, String titre,
                            String consignes, LocalDateTime dateRemise) {
        Devoir devoir = Devoir.creer(sessionId, moduleId, titre, consignes, dateRemise);
        String dateStr = dateRemise.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
        devoir.publier(titre, dateStr);
        Devoir saved = sessionRepo.saveDevoir(devoir);
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();
        log.info("[DEVOIR] Devoir '{}' publié pour session {}", titre, sessionId);
        return saved;
    }
}
