package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.Cours;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Caching;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S19 — L'admin publie un cours.
 *
 * CACHE : Invalide le catalogue + le détail du cours publié.
 * Le prochain appel rechargera depuis PostgreSQL et re-cachera.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PublierCoursUseCase {

    private final CoursRepository        coursRepo;
    private final ApplicationEventPublisher eventBus;

    /**
     * Invalide TOUS les caches concernés par la publication :
     *   - catalogue (toutes les pages — un nouveau cours y apparaît)
     *   - cours-detail de ce cours spécifique (statut passe à PUBLIE)
     *   - cours-modules (structure du cours)
     */
    @Caching(evict = {
        @CacheEvict(value = "catalogue",     allEntries = true),
        @CacheEvict(value = "cours-detail",  key = "#coursId"),
        @CacheEvict(value = "cours-modules", key = "#coursId")
    })
    @Transactional
    public void executer(UUID coursId, UUID adminId) {
        Cours cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));

        if ("PUBLIE".equals(cours.getStatut())) {
            throw new RuntimeException("BUSINESS_RULE:COURS_DEJA_PUBLIE");
        }

        cours.publier();
        coursRepo.save(cours);

        eventBus.publishEvent(new CoursPublieEvent(coursId, cours.getFormateurId()));
        log.info("[COURS] Cours {} publié par admin {}. Cache catalogue invalidé.", coursId, adminId);
    }

    public record CoursPublieEvent(UUID coursId, UUID formateurId) {}
}
