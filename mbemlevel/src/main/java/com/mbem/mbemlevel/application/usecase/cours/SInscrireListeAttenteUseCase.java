package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ListeAttenteJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ListeAttenteJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * S4 — S'inscrire sur la liste d'attente quand toutes les sessions sont complètes.
 * L'apprenant est notifié dès qu'une place se libère.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SInscrireListeAttenteUseCase {

    private final ListeAttenteJpaRepository listeAttenteRepo;

    @Transactional
    public void executer(UUID coursId, UUID apprenantId, UUID sessionId) {
        // Vérifier pas déjà inscrit
        if (listeAttenteRepo.existsByApprenantIdAndCoursId(apprenantId, coursId)) {
            throw new RuntimeException("BUSINESS_RULE:DEJA_SUR_LISTE_ATTENTE");
        }

        ListeAttenteJpaEntity entry = ListeAttenteJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(apprenantId)
            .coursId(coursId)
            .sessionId(sessionId)
            .statut("EN_ATTENTE")
            .dateInscription(LocalDateTime.now())
            .build();
        listeAttenteRepo.save(entry);
        log.info("[LISTE_ATTENTE] Apprenant {} inscrit sur liste pour cours {}", apprenantId, coursId);
    }
}
