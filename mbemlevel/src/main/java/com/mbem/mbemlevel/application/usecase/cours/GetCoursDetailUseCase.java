package com.mbem.mbemlevel.application.usecase.cours;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S4 — Récupère le détail complet d'un cours pour la page de présentation.
 *
 * Retourne l'arbre complet :
 *   Cours → objectifs, débouchés, stats
 *     └── Modules (ordonnés)
 *           └── Leçons (ordonnées, avec état de verrouillage)
 *   + Sessions disponibles
 *   + Avis récents
 *   + Progression de l'apprenant (si connecté)
 *
 * Verrouillage progressif :
 *   - Leçons des modules gratuits → DÉVERROUILLÉES pour tous
 *   - Leçons marquées estPreview → DÉVERROUILLÉES pour tous (aperçu)
 *   - Leçons au-delà du seuil → VERROUILLÉES si non payé
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GetCoursDetailUseCase {

    private final CoursJpaRepository        coursRepo;
    private final ModuleJpaRepository       moduleRepo;
    private final LeconJpaRepository        leconRepo;
    private final SessionJpaRepository      sessionRepo;
    private final AvisCoursJpaRepository    avisRepo;
    private final ProgressionJpaRepository  progressionRepo;
    private final UtilisateurJpaRepository  utilisateurRepo;
    private final CategorieJpaRepository    categorieRepo;
    private final ObjectMapper              objectMapper;

    @Transactional(readOnly = true)
    public CoursDetailResponse executer(UUID coursId, UUID apprenantId) {
        CoursJpaEntity cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));
        return executerPourCours(cours, apprenantId);
    }

    @Transactional(readOnly = true)
    public CoursDetailResponse executerParSlug(String slug, UUID apprenantId) {
        CoursJpaEntity cours = coursRepo.findBySlug(slug)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:SLUG:" + slug));
        return executerPourCours(cours, apprenantId);
    }

    private CoursDetailResponse executerPourCours(CoursJpaEntity cours, UUID apprenantId) {
        UUID coursId = cours.getId();

        if (!"PUBLIE".equals(cours.getStatut())) {
            boolean isFormateur = apprenantId != null && apprenantId.equals(cours.getFormateurId());
            boolean isAdmin = false;
            if (apprenantId != null) {
                isAdmin = utilisateurRepo.findById(apprenantId)
                    .map(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.ADMIN || u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.SUPER_ADMIN)
                    .orElse(false);
            }
            if (!isFormateur && !isAdmin) {
                throw new RuntimeException("ACCESS_DENIED: Ce cours n'est pas accessible.");
            }
        }

        // ── 2. Progression de l'apprenant ────────────────────────────────────
        ProgressionJpaEntity progression = null;
        if (apprenantId != null) {
            progression = progressionRepo
                .findByApprenantIdAndCoursId(apprenantId, coursId)
                .orElse(null);
        }
        final boolean estPaye = progression != null && progression.isEstPaye();

        // ── 3. Modules et leçons ─────────────────────────────────────────────
        List<ModuleJpaEntity> modules = moduleRepo.findByCoursIdOrderByOrdreAsc(coursId);

        // Compter les leçons terminées par l'apprenant
        Set<UUID> leconsTerminees = progression != null
            ? getLeconIdsTerminees(apprenantId, coursId)
            : Set.of();

        List<ModuleResponse> modulesResp = modules.stream().map(m -> {
            List<LeconJpaEntity> lecons = leconRepo.findByModuleIdOrderByOrdreAsc(m.getId());

            // Un module est verrouillé si l'apprenant n'a pas payé ET le module n'est pas gratuit
            boolean moduleVerrouille = !estPaye && !m.isEstGratuit();

            List<LeconSommaireResponse> leconsResp = lecons.stream().map(l -> {
                // Une leçon est accessible si :
                // - le module est gratuit
                // - ou la leçon est marquée preview
                // - ou l'apprenant a payé
                boolean accessible = m.isEstGratuit() || l.isEstPreview() || estPaye;
                boolean estVerrouille = !accessible;

                String typeContenu = "TEXTE";
                if (l.isAQCM()) {
                    typeContenu = "QCM";
                } else if (l.getLienVideo() != null && !l.getLienVideo().isBlank()) {
                    typeContenu = "VIDEO";
                } else if (l.getLienPdf() != null && !l.getLienPdf().isBlank()) {
                    typeContenu = "PDF";
                }

                return new LeconSommaireResponse(
                    l.getId(), l.getTitre(), l.getOrdre(),
                    l.getDureeMinutes(), l.getXpValeur(),
                    l.isEstPreview(), l.isAQCM(),
                    apprenantId != null ? leconsTerminees.contains(l.getId()) : null,
                    estVerrouille,
                    typeContenu
                );
            }).toList();

            return new ModuleResponse(
                m.getId(), m.getTitre(), m.getDescription(),
                m.getOrdre(), m.getXpBonus(), m.isEstGratuit(),
                moduleVerrouille,
                m.getNbLecons(), m.getDureeTotaleMinutes(),
                leconsResp
            );
        }).toList();

        // ── 4. Sessions disponibles ───────────────────────────────────────────
        List<CoursDetailResponse.SessionSommaireResponse> sessions =
            sessionRepo.findSessionsDisponibles(coursId).stream()
                .map(s -> new CoursDetailResponse.SessionSommaireResponse(
                    s.getId(),
                    s.getDateDebut() != null ? s.getDateDebut().toLocalDate().toString() : null,
                    s.getDateFin()   != null ? s.getDateFin().toLocalDate().toString()   : null,
                    s.getModalite(), s.getLieuOuLien(),
                    s.getPlacesDisponibles(), s.getCapaciteMax()
                ))
                .toList();

        // ── 5. Avis récents ───────────────────────────────────────────────────
        List<AvisCoursJpaEntity> avisEntities = avisRepo.findByCoursId(coursId);
        List<AvisCoursResponse> avisRecents = avisEntities.stream()
            .filter(AvisCoursJpaEntity::isEstVerifie)
            .limit(5)
            .map(a -> new AvisCoursResponse(
                a.getId(), a.getApprenantId(), a.getNote(),
                a.getCommentaire(), a.getCreatedAt()))
            .toList();

        CoursDetailResponse.DistributionNotes dist = calculerDistribution(avisEntities);

        // ── 6. Objectifs et débouchés depuis JSON ─────────────────────────────
        List<String> objectifs = parseJsonList(cours.getObjectifsApprentissageJson());
        CoursDetailResponse.DebouchesInfo debouches = parseDebouches(cours.getDebouchesJson());

        // ── 7. Progression apprenant ──────────────────────────────────────────
        CoursDetailResponse.ProgressionApprenanteResponse progResp = null;
        if (progression != null) {
            progResp = new CoursDetailResponse.ProgressionApprenanteResponse(
                progression.getPourcentage(),
                progression.isEstPaye(),
                cours.getSeuilPaiement().doubleValue() < 1.0 && (progression.getPourcentage() >= cours.getSeuilPaiement().doubleValue() * 100),
                progression.getXpGagne(),
                null // derniereLeconTitre — à enrichir si besoin
            );
        }

        // ── 8. Formateur et Catégorie / Domaine ──────────────────────────────
        String formateurNom = "Formateur Inconnu";
        if (cours.getFormateurId() != null) {
            formateurNom = utilisateurRepo.findById(cours.getFormateurId())
                .map(u -> (u.getPrenom() != null ? u.getPrenom() : "") + " " + (u.getNom() != null ? u.getNom() : ""))
                .orElse("Formateur Inconnu");
        }

        String categorieNom = "Non spécifié";
        if (cours.getCategorieId() != null) {
            categorieNom = categorieRepo.findById(cours.getCategorieId())
                .map(CategorieJpaEntity::getNom)
                .orElse("Non spécifié");
        }

        return new CoursDetailResponse(
            cours.getId(), cours.getTitre(),
            cours.getDescriptionCourte(), cours.getDescriptionLongue(),
            cours.getNiveau(), cours.getLangue(),
            cours.getImageCouverture(), cours.getImageCouvertureThumbnail(),
            cours.getSlug(),
            formateurNom, categorieNom,
            cours.getNbModules(), cours.getNbLecons(), cours.getDureeTotaleMinutes(),
            cours.getNbApprenants(), cours.getNoteMoyenne(), cours.getNbAvis(),
            cours.getPrixFcfa(), cours.getSeuilPaiement().doubleValue(),
            objectifs, cours.getPrerequis(), cours.getPublicCible(),
            debouches, modulesResp, sessions, dist, avisRecents,
            progResp, cours.getStatut()
        );
    }

    private Set<UUID> getLeconIdsTerminees(UUID apprenantId, UUID coursId) {
        // TODO: à implémenter avec une table lecons_terminees
        return Set.of();
    }

    private CoursDetailResponse.DistributionNotes calculerDistribution(
            List<AvisCoursJpaEntity> avis) {
        int[] counts = new int[6]; // index 1 à 5
        avis.forEach(a -> { if (a.getNote() >= 1 && a.getNote() <= 5) counts[a.getNote()]++; });
        return new CoursDetailResponse.DistributionNotes(
            counts[5], counts[4], counts[3], counts[2], counts[1]);
    }

    private List<String> parseJsonList(String json) {
        if (json == null || json.isBlank()) return List.of();
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return List.of();
        }
    }

    private CoursDetailResponse.DebouchesInfo parseDebouches(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, CoursDetailResponse.DebouchesInfo.class);
        } catch (Exception e) {
            return null;
        }
    }
}
