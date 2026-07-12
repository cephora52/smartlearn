package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.*;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S19 — Création complète d'un cours par le formateur.
 *
 * Persiste dans l'ordre :
 *   1. Le cours (statut BROUILLON)
 *   2. Les modules (dans l'ordre)
 *   3. Les leçons de chaque module (dans l'ordre)
 *   4. Les blocs de contenu de chaque leçon (dans l'ordre)
 *   5. Les QCM de chaque leçon (si présent)
 *
 * Le cours reste en BROUILLON jusqu'à validation admin (PublierCoursUseCase).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CreerCoursCompletUseCase {

    private final CoursRepository            coursRepo;
    private final CoursJpaRepository         coursJpaRepo;
    private final ModuleJpaRepository        moduleRepo;
    private final LeconJpaRepository         leconRepo;
    private final BlocContenuJpaRepository   blocRepo;
    private final QCMJpaRepository           qcmRepo;

    @Transactional
    @CacheEvict(value = "catalogue", allEntries = true)
    public UUID executer(CreerCoursCompletRequest req, UUID formateurId) {
        // Supprimer tout brouillon vide existant (sans modules) pour le même formateur avec le même titre
        List<CoursJpaEntity> duplicates = coursJpaRepo.findByFormateurIdAndTitre(formateurId, req.titre());
        if (duplicates != null && !duplicates.isEmpty()) {
            for (CoursJpaEntity dup : duplicates) {
                if (dup.getNbModules() == 0) {
                    coursJpaRepo.delete(dup);
                    log.info("[COURS] Brouillon vide doublon supprimé: {}", dup.getId());
                }
            }
        }

        // 1. Créer le cours
        String descCourte = req.descriptionCourte() != null ? req.descriptionCourte() : (req.description() != null ? req.description() : "");
        Cours cours = Cours.creer(
            req.titre(), descCourte,
            req.niveau(), req.categorieId(),
            formateurId, req.seuilPaiement(), req.prixFcfa()
        );
        cours.setDescriptionLongue(req.descriptionLongue());
        cours.setImageCouverture(req.imageCouverture());
        if (req.imageCouverture() != null && req.imageCouverture().contains("/banniere/original/")) {
            cours.setImageCouvertureThumbnail(req.imageCouverture().replace("/banniere/original/", "/banniere/thumbnail/"));
        } else {
            cours.setImageCouvertureThumbnail(req.imageCouverture());
        }
        cours.setObjectifsApprentissage(req.objectifsApprentissage());
        cours.setPrerequisEtPublicCible(req.prerequis(), req.publicCible());
        
        // Auto-publier dès la création pour garantir la visibilité côté apprenant
        cours.publier();
        
        coursRepo.save(cours);
        log.info("[COURS] Cours créé en brouillon: {} par formateur: {}", cours.getId(), formateurId);

        // 2. Créer les modules
        int totalDuree = 0;
        int nbModules = 0;
        if (req.modules() != null) {
            nbModules = req.modules().size();
            for (CreerModuleRequest mr : req.modules()) {
                UUID moduleId = UUID.randomUUID();
                int nbLecons = mr.lecons() != null ? mr.lecons().size() : 0;
                ModuleJpaEntity module = ModuleJpaEntity.builder()
                    .id(moduleId)
                    .coursId(cours.getId())
                    .titre(mr.titre())
                    .description(mr.description())
                    .ordre(mr.ordre())
                    .xpBonus(mr.xpBonus())
                    .estGratuit(mr.estGratuit())
                    .estVerrouille(true)
                    .nbLecons(nbLecons)
                    .build();
                moduleRepo.save(module);

                // 3. Créer les leçons du module
                int dureeTotaleModule = 0;
                if (mr.lecons() != null) {
                    for (CreerLeconRequest lr : mr.lecons()) {
                        UUID leconId = UUID.randomUUID();
                        LeconJpaEntity lecon = LeconJpaEntity.builder()
                            .id(leconId)
                            .moduleId(moduleId)
                            .titre(lr.titre())
                            .descriptionCourte(lr.descriptionCourte())
                            .ordre(lr.ordre())
                            .dureeMinutes(lr.dureeMinutes())
                            .xpValeur(lr.xpValeur())
                            .estPreview(lr.estPreview())
                            .aQCM(lr.aQCM())
                            .build();
                        leconRepo.save(lecon);
                        dureeTotaleModule += lr.dureeMinutes();

                        // 4. Créer les blocs de contenu
                        if (lr.blocs() != null) {
                            for (BlocContenuRequest br : lr.blocs()) {
                                BlocContenuJpaEntity bloc = creerBloc(leconId, br);
                                blocRepo.save(bloc);
                            }
                        }

                        // 5. Créer le QCM si présent
                        if (lr.aQCM() && lr.qcm() != null) {
                            creerQCM(leconId, lr.qcm(), qcmRepo);
                        }
                    }
                }
                totalDuree += dureeTotaleModule;

                // Mettre à jour la durée totale du module
                module.setDureeTotaleMinutes(dureeTotaleModule);
                moduleRepo.save(module);
            }
        }

        // Mettre à jour stats du cours
        cours.setNbModules(nbModules);
        cours.setDureeTotaleMinutes(
            req.dureeTotaleMinutes() != null ? req.dureeTotaleMinutes() : totalDuree
        );

        coursRepo.save(cours);

        log.info("[COURS] Cours complet persisté: {} modules, {} minutes, statut: {}",
            nbModules, totalDuree, cours.getStatut());
        return cours.getId();
    }

    private BlocContenuJpaEntity creerBloc(UUID leconId, BlocContenuRequest r) {
        return BlocContenuJpaEntity.builder()
            .id(UUID.randomUUID())
            .leconId(leconId)
            .typeBloc(r.typeBloc())
            .ordre(r.ordre())
            .contenuHtml(r.contenuHtml())
            .urlImage(r.urlImage())
            .altImage(r.altImage())
            .legendeImage(r.legendeImage())
            .urlVideo(r.urlVideo())
            .dureeVideoSec(r.dureeVideoSec())
            .urlPdf(r.urlPdf())
            .nomPdf(r.nomPdf())
            .langageCode(r.langageCode())
            .codeSource(r.codeSource())
            .typeCallout(r.typeCallout())
            .texteCallout(r.texteCallout())
            .build();
    }

    private void creerQCM(UUID leconId, QCMRequest r, QCMJpaRepository qcmRepo) {
        List<Map<String,String>> options = r.options().stream()
            .map(o -> Map.of("id", o.id(), "texte", o.texte()))
            .toList();
        QCMJpaEntity qcm = QCMJpaEntity.builder()
            .id(UUID.randomUUID())
            .leconId(leconId)
            .question(r.question())
            .optionsJson(options.toString()) // sérialisé en JSONB via @Convert ou String
            .bonneReponse(r.bonneReponse())
            .explication(r.explication())
            .scorePoints(r.scorePoints())
            .ordre(1)
            .build();
        qcmRepo.save(qcm);
    }
}
