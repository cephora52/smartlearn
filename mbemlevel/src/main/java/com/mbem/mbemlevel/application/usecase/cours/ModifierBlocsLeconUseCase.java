package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.request.BlocContenuRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.BlocContenuJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.LeconJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ModuleJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/**
 * S19 — Modifier/remplacer les blocs de contenu d'une leçon existante.
 * Supprime tous les blocs existants et recrée depuis la liste fournie.
 * Utilisé lors de l'édition du cours par le formateur.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ModifierBlocsLeconUseCase {

    private final BlocContenuJpaRepository blocRepo;
    private final LeconJpaRepository       leconRepo;
    private final CoursJpaRepository       coursRepo;
    private final UtilisateurJpaRepository utilisateurRepo;

    @Transactional
    public void executer(UUID leconId, List<BlocContenuRequest> nouveauxBlocs, UUID formateurId) {
        // Vérifier que la leçon existe
        LeconJpaEntity lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        // Trouver le cours
        CoursJpaEntity cours = coursRepo.findById(lecon.getCoursId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + lecon.getCoursId()));

        // Vérifier la propriété (le formateur du cours doit être formateurId, sauf si admin/super_admin)
        boolean isAdmin = utilisateurRepo.findById(formateurId)
            .map(u -> u.getRole() == Role.ADMIN || u.getRole() == Role.SUPER_ADMIN)
            .orElse(false);

        if (!cours.getFormateurId().equals(formateurId) && !isAdmin) {
            throw new RuntimeException("ACCESS_DENIED: Le cours ne vous appartient pas.");
        }

        // Supprimer tous les blocs existants
        blocRepo.deleteByLeconId(leconId);

        // Recréer depuis la liste
        for (BlocContenuRequest br : nouveauxBlocs) {
            BlocContenuJpaEntity bloc = BlocContenuJpaEntity.builder()
                .id(UUID.randomUUID())
                .leconId(leconId)
                .typeBloc(br.typeBloc())
                .ordre(br.ordre())
                .contenuHtml(br.contenuHtml())
                .urlImage(br.urlImage()).altImage(br.altImage()).legendeImage(br.legendeImage())
                .urlVideo(br.urlVideo()).dureeVideoSec(br.dureeVideoSec())
                .urlPdf(br.urlPdf()).nomPdf(br.nomPdf())
                .langageCode(br.langageCode()).codeSource(br.codeSource())
                .typeCallout(br.typeCallout()).texteCallout(br.texteCallout())
                .build();
            blocRepo.save(bloc);
        }
        log.info("[COURS] Blocs mis à jour pour leçon {} : {} blocs", leconId, nouveauxBlocs.size());
    }
}
