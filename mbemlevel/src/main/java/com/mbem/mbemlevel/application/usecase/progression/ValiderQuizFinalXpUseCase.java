package com.mbem.mbemlevel.application.usecase.progression;

import com.mbem.mbemlevel.application.port.out.ProgressionRepository;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.XpHistoriqueJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.XpHistoriqueJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ValiderQuizFinalXpUseCase {

    private final ProgressionRepository progressionRepo;
    private final UtilisateurJpaRepository utilisateurRepo;
    private final XpHistoriqueJpaRepository xpHistoriqueRepo;

    @Transactional
    public Progression executer(UUID apprenantId, UUID coursId) {
        Progression p = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:PROGRESSION:" + coursId));

        if (p.getPourcentage() < 100.0) {
            throw new RuntimeException("La formation doit être terminée à 100% pour valider le quiz final.");
        }

        if (p.isFinalQuizDone()) {
            return p; // Déjà validé, pas de double gain d'XP
        }

        p.setFinalQuizDone(true);
        p.avancer(100.0, 50, null, null, null, null);

        Progression saved = progressionRepo.save(p);

        // Enregistrer l'historique de gain XP
        xpHistoriqueRepo.save(XpHistoriqueJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(apprenantId)
            .xpGagne(50)
            .dateGain(LocalDateTime.now())
            .build());

        // Mettre à jour l'XP total dans la base de données
        utilisateurRepo.findById(apprenantId).ifPresent(userEntity -> {
            int totalXp = progressionRepo.findByApprenantId(apprenantId).stream()
                .mapToInt(Progression::getXpGagne)
                .sum();
            userEntity.setXpTotal(totalXp);
            utilisateurRepo.save(userEntity);
        });

        return saved;
    }
}
