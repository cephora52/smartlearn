package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.application.port.out.StoragePort;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S6 — Récupère le contenu complet d'une leçon pour l'affichage.
 * Inclut : blocs de contenu ordonnés, QCM (sans la bonne réponse), ressources.
 */
@Service
@RequiredArgsConstructor
public class GetLeconDetailUseCase {

    private final LeconJpaRepository       leconRepo;
    private final BlocContenuJpaRepository blocRepo;
    private final QCMJpaRepository         qcmRepo;
    private final RessourceCoursJpaRepository ressourceRepo;
    private final ProgressionJpaRepository progressionRepo;
    private final StoragePort              storagePort;
    private final CoursJpaRepository       coursRepo;
    private final UtilisateurJpaRepository  utilisateurRepo;
    private final PaiementJpaRepository    paiementRepo;
    private final MoratoireJpaRepository   moratoireRepo;

    @Transactional(readOnly = true)
    public LeconDetailResponse executer(UUID leconId, UUID apprenantId) {
        LeconJpaEntity lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        UUID coursId = lecon.getCoursId();
        CoursJpaEntity cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));

        boolean isFormateur = apprenantId != null && apprenantId.equals(cours.getFormateurId());
        boolean isAdmin = false;
        if (apprenantId != null) {
            isAdmin = utilisateurRepo.findById(apprenantId)
                .map(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.ADMIN || u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.SUPER_ADMIN)
                .orElse(false);
        }

        boolean aMoratoireApprouve = false;
        if (apprenantId != null) {
            var paiementOpt = paiementRepo.findByApprenantIdAndCoursId(apprenantId, coursId);
            if (paiementOpt.isPresent()) {
                aMoratoireApprouve = moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "APPROUVE")
                                  || moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "ACCORDE");
            }
        }

        boolean estPaye = (cours.getPrixFcfa() == 0)
            || (apprenantId != null && progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
                .map(ProgressionJpaEntity::isEstPaye).orElse(false))
            || isFormateur || isAdmin;

        List<LeconJpaEntity> lecons = leconRepo.findByCoursIdOrderByOrdreAsc(coursId);
        int totalLecons = lecons.size();
        double seuilVal = cours.getSeuilPaiement().doubleValue();
        int maxLeconsGratuites = (int) Math.ceil(totalLecons * seuilVal);

        int leconIndex = -1;
        for (int i = 0; i < totalLecons; i++) {
            if (lecons.get(i).getId().equals(leconId)) {
                leconIndex = i;
                break;
            }
        }

        boolean estDansSeuilGratuit = (leconIndex >= 0 && leconIndex < maxLeconsGratuites);
        boolean accessible = lecon.isEstPreview() || estDansSeuilGratuit || estPaye || aMoratoireApprouve;

        if (!accessible) {
            throw new com.mbem.mbemlevel.api.exception.AccesInterditException("Cette leçon est verrouillée. Veuillez payer ou demander un moratoire.");
        }

        // Blocs de contenu dans l'ordre
        List<BlocContenuResponse> blocs = blocRepo
            .findByLeconIdOrderByOrdreAsc(leconId)
            .stream()
            .map(b -> new BlocContenuResponse(
                b.getId(), b.getTypeBloc(), b.getOrdre(),
                b.getContenuHtml(),
                b.getUrlImage() != null && !b.getUrlImage().isBlank() ? (b.getUrlImage().startsWith("http") ? b.getUrlImage() : storagePort.presignedUrl(b.getUrlImage())) : null,
                b.getAltImage(), b.getLegendeImage(),
                b.getUrlVideo() != null && !b.getUrlVideo().isBlank() ? (b.getUrlVideo().startsWith("http") ? b.getUrlVideo() : storagePort.presignedUrl(b.getUrlVideo())) : null,
                b.getDureeVideoSec(),
                b.getUrlPdf() != null && !b.getUrlPdf().isBlank() ? (b.getUrlPdf().startsWith("http") ? b.getUrlPdf() : storagePort.presignedUrl(b.getUrlPdf())) : null,
                b.getNomPdf(),
                b.getLangageCode(), b.getCodeSource(),
                b.getTypeCallout(), b.getTexteCallout()
            ))
            .toList();

        // QCM sans la bonne réponse (sécurité)
        QCMResponse qcmResp = qcmRepo.findByLeconId(leconId)
            .map(q -> new QCMResponse(
                q.getId(),
                q.getQuestion(),
                parseOptions(q.getOptionsJson()),
                q.getScorePoints(),
                q.getOrdre()
                // bonneReponse NON incluse ici
            ))
            .orElse(null);

        // Ressources de la leçon
        List<RessourceResponse> ressources = ressourceRepo
            .findByLeconId(leconId)
            .stream()
            .map(r -> new RessourceResponse(
                r.getId(), r.getTypeRessource(), r.getNom(),
                r.getUrlStockage(), r.getTailleOctets(), r.getMimeType()
            ))
            .toList();

        return new LeconDetailResponse(
            lecon.getId(), lecon.getCoursId(),
            lecon.getTitre(), lecon.getDescriptionCourte(),
            lecon.getOrdre(), lecon.getDureeMinutes(), lecon.getXpValeur(),
            lecon.isEstPreview(), lecon.isAQCM(),
            blocs, qcmResp, ressources
        );
    }

    @SuppressWarnings("unchecked")
    private List<Map<String,String>> parseOptions(String json) {
        // Simplifié — en production utiliser ObjectMapper
        return List.of();
    }
}
