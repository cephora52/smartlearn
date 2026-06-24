package com.mbem.mbemlevel.infrastructure.persistence;

import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

@SpringBootTest @ActiveProfiles("test") @Transactional
@DisplayName("ProgressionRepository — Intégration PostgreSQL")
class ProgressionRepositoryIT {

    @Autowired private ProgressionRepository progressionRepo;
    @Autowired private UtilisateurRepository  utilisateurRepo;
    @Autowired private CoursRepository        coursRepo;

    @Test
    @DisplayName("activerPaiement() met estPaye=true")
    void activerPaiement_miseAJourCorrectement() {
        Utilisateur u  = utilisateurRepo.save(Utilisateur.creer("Dave", "dave@t.com", "h"));
        Cours c = coursRepo.save(Cours.creer("Java", "desc", NiveauCours.DEBUTANT,
            null, u.getId(), 0.30, 50_000));
        Progression p  = progressionRepo.save(Progression.commencer(u.getId(), c.getId(), 0.30));
        assertThat(p.isEstPaye()).isFalse();

        progressionRepo.activerPaiement(u.getId(), c.getId());

        var updated = progressionRepo.findByApprenantIdAndCoursId(u.getId(), c.getId());
        assertThat(updated).isPresent();
        assertThat(updated.get().isEstPaye()).isTrue();
    }
}
