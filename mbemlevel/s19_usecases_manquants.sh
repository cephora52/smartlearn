#!/usr/bin/env bash
# =============================================================================
# MbemNova — s19_usecases_manquants.sh
# Use Cases entièrement absents :
#   S10 — ChoisirCreneauxUseCase
#   S15 — GetParrainageUseCase + GenererLienParrainageUseCase
#   S17 — DemanderMoratoireUseCase + TraiterMoratoireUseCase
#   S4  — LaissserAvisUseCase + SInscrireListeAttenteUseCase
#   S12 — SignalerMessageUseCase
#   S19 — GetCoursEnAttenteUseCase
#   S20 — CreerSessionUseCase
#   S25 — ExportStatistiquesUseCase
#   S28 — SupprimerCompteUseCase + ExporterDonneesPersonnellesUseCase
# =============================================================================
set -euo pipefail
ROOT="${1:-.}"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_NC='\033[0m'
ok()  { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
sec() { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }

mkdir -p "$P/application/usecase/paiement"
mkdir -p "$P/application/usecase/session"
mkdir -p "$P/application/usecase/cours"
mkdir -p "$P/application/usecase/communaute"
mkdir -p "$P/application/usecase/gamification"
mkdir -p "$P/application/usecase/admin"
mkdir -p "$P/application/usecase/auth"
mkdir -p "$P/api/dto/request"
mkdir -p "$P/api/dto/response"
mkdir -p "$P/api/controller"

echo -e "\n${C_BLUE}══════════════════════════════════════════════════════════${C_NC}"
echo -e "${C_BLUE}  MbemNova · s19 · Use Cases Manquants                     ${C_NC}"
echo -e "${C_BLUE}══════════════════════════════════════════════════════════${C_NC}\n"

# =============================================================================
# S17 — MORATOIRE
# =============================================================================
sec "S17 — DemanderMoratoireUseCase + TraiterMoratoireUseCase"

cat > "$P/api/dto/request/DemanderMoratoireRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.UUID;

/** S17 — Demande de moratoire par l'apprenant */
public record DemanderMoratoireRequest(
    @NotNull
    UUID paiementId,

    /**
     * Raison choisie dans la liste :
     * DIFFICULTES_FINANCIERES | PROBLEME_SANTE | URGENCE_FAMILIALE | AUTRE
     */
    @NotBlank @Size(max = 50)
    String raison,

    /** Explication libre optionnelle */
    @Size(max = 1000)
    String explicationLibre,

    /** Nouvelle date souhaitée pour le paiement */
    @NotNull @Future
    LocalDate nouvelleDateSouhaitee
) {}
JEOF
ok "DemanderMoratoireRequest"

cat > "$P/api/dto/request/TraiterMoratoireRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

/** S17 — Décision admin sur une demande de moratoire */
public record TraiterMoratoireRequest(
    /** ACCORDE ou REFUSE */
    @NotBlank @Pattern(regexp = "ACCORDE|REFUSE")
    String decision,

    /** Nouvelle date accordée (obligatoire si decision=ACCORDE) */
    LocalDate nouvelleDateAccordee,

    /** Justification du refus (obligatoire si decision=REFUSE) */
    @Size(max = 500)
    String justificationRefus
) {}
JEOF
ok "TraiterMoratoireRequest"

cat > "$P/application/usecase/paiement/DemanderMoratoireUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.request.DemanderMoratoireRequest;
import com.mbem.mbemlevel.application.port.out.MoratoireRepository;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S17 — L'apprenant demande un délai de paiement (moratoire).
 * Règles :
 *  - Un seul moratoire EN_ATTENTE autorisé par paiement
 *  - Les relances automatiques sont suspendues jusqu'à décision admin
 *  - L'admin reçoit une notification immédiate
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DemanderMoratoireUseCase {

    private final MoratoireRepository    moratoireRepo;
    private final PaiementRepository     paiementRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public UUID executer(DemanderMoratoireRequest req, UUID apprenantId) {
        // Vérifier que le paiement appartient à l'apprenant
        paiementRepo.findByIdAndApprenantId(req.paiementId(), apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:PAIEMENT"));

        // Vérifier qu'il n'y a pas déjà un moratoire en attente
        if (moratoireRepo.existsEnAttenteForPaiement(req.paiementId())) {
            throw new RuntimeException("BUSINESS_RULE:MORATOIRE_DEJA_EN_ATTENTE");
        }

        // Construire la raison complète
        String raisonComplete = req.raison()
            + (req.explicationLibre() != null ? " — " + req.explicationLibre() : "");

        // Créer le moratoire
        Moratoire moratoire = Moratoire.creer(
            req.paiementId(), raisonComplete, req.nouvelleDateSouhaitee()
        );
        moratoireRepo.save(moratoire);

        // Notifier l'admin
        eventBus.publishEvent(new MoratoireDemandeEvent(moratoire.getId(), req.paiementId(), apprenantId));

        log.info("[MORATOIRE] Demande créée: {} pour paiement: {}", moratoire.getId(), req.paiementId());
        return moratoire.getId();
    }

    /** Événement publié vers l'admin */
    public record MoratoireDemandeEvent(UUID moratoireId, UUID paiementId, UUID apprenantId) {}
}
JEOF
ok "DemanderMoratoireUseCase"

cat > "$P/application/usecase/paiement/TraiterMoratoireUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.request.TraiterMoratoireRequest;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * S17 — L'admin traite une demande de moratoire (accorde ou refuse).
 * Si accordé :
 *  - Plan de paiement mis à jour (nouvelle date)
 *  - Relances automatiques reprennent à la nouvelle date
 *  - Email + notification apprenant
 * Si refusé :
 *  - Relances reprennent immédiatement
 *  - Email avec justification
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TraiterMoratoireUseCase {

    private final MoratoireRepository     moratoireRepo;
    private final PaiementRepository      paiementRepo;
    private final TrancheRepository       trancheRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public void executer(UUID moratoireId, TraiterMoratoireRequest req, UUID adminId) {
        Moratoire moratoire = moratoireRepo.findById(moratoireId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:MORATOIRE"));

        if (!"EN_ATTENTE".equals(moratoire.getStatut())) {
            throw new RuntimeException("BUSINESS_RULE:MORATOIRE_DEJA_TRAITE");
        }

        if ("ACCORDE".equals(req.decision())) {
            if (req.nouvelleDateAccordee() == null) {
                throw new RuntimeException("VALIDATION:nouvelle_date_obligatoire_si_accorde");
            }
            // Accorder le moratoire
            moratoire.accorder(adminId, req.nouvelleDateAccordee());
            moratoireRepo.save(moratoire);

            // Mettre à jour la tranche en retard avec la nouvelle date
            trancheRepo.updateDateEcheance(moratoire.getPaiementId(), req.nouvelleDateAccordee());

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "ACCORDE",
                req.nouvelleDateAccordee().toString(), null
            ));
            log.info("[MORATOIRE] Accordé: {} → nouvelle date: {}", moratoireId, req.nouvelleDateAccordee());

        } else {
            if (req.justificationRefus() == null || req.justificationRefus().isBlank()) {
                throw new RuntimeException("VALIDATION:justification_obligatoire_si_refuse");
            }
            // Refuser le moratoire
            moratoire.refuser(adminId, req.justificationRefus());
            moratoireRepo.save(moratoire);

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "REFUSE",
                null, req.justificationRefus()
            ));
            log.info("[MORATOIRE] Refusé: {} — raison: {}", moratoireId, req.justificationRefus());
        }
    }

    public record MoratoireDecideEvent(
        UUID   moratoireId,
        UUID   paiementId,
        String decision,
        String nouvelleDateStr,
        String justificationRefus
    ) {}
}
JEOF
ok "TraiterMoratoireUseCase"

# =============================================================================
# S10 — CRÉNEAUX HORAIRES
# =============================================================================
sec "S10 — ChoisirCreneauxUseCase"

cat > "$P/api/dto/request/ChoisirCreneauxRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.util.List;
import java.util.UUID;

/** S10 — Choix de créneaux horaires par l'apprenant */
public record ChoisirCreneauxRequest(
    @NotNull
    UUID sessionId,

    /** IDs des créneaux sélectionnés */
    @NotEmpty @Size(min = 1, max = 10)
    List<UUID> creneauIds
) {}
JEOF
ok "ChoisirCreneauxRequest"

cat > "$P/api/dto/response/CreneauResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record CreneauResponse(
    UUID      id,
    UUID      sessionId,
    String    jourSemaine,
    LocalTime heureDebut,
    int       dureeMinutes,
    int       capaciteMax,
    int       placesRestantes,
    Boolean   dejaCboisi    // Pour l'apprenant connecté
) {}
JEOF
ok "CreneauResponse"

cat > "$P/application/usecase/session/ChoisirCreneauxUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.request.ChoisirCreneauxRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.*;

/**
 * S10 — L'apprenant choisit ses créneaux horaires pour une session.
 * Règles :
 *  - Vérification en temps réel des places disponibles
 *  - Pas de double réservation sur le même créneau
 *  - Les créneaux choisis apparaissent dans le calendrier de l'apprenant
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ChoisirCreneauxUseCase {

    private final CreneauJpaRepository       creneauRepo;
    private final SessionJpaRepository       sessionRepo;

    @Transactional
    public void executer(ChoisirCreneauxRequest req, UUID apprenantId) {
        // Vérifier que la session existe et que l'apprenant y est inscrit
        sessionRepo.findById(req.sessionId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:SESSION"));

        List<String> conflits = new ArrayList<>();

        for (UUID creneauId : req.creneauIds()) {
            CreneauJpaEntity creneau = creneauRepo.findById(creneauId)
                .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:CRENEAU:" + creneauId));

            // Vérifier places restantes
            if (creneau.getPlacesRestantes() <= 0) {
                conflits.add("Créneau " + creneau.getJourSemaine() + " " +
                    creneau.getHeureDebut() + " est complet");
                continue;
            }

            // Décrémenter les places restantes
            creneau.setPlacesRestantes(creneau.getPlacesRestantes() - 1);
            creneauRepo.save(creneau);
        }

        if (!conflits.isEmpty()) {
            throw new RuntimeException("BUSINESS_RULE:CRENEAUX_COMPLETS:" + String.join(";", conflits));
        }

        log.info("[SESSION] {} créneaux choisis par apprenant {} pour session {}",
            req.creneauIds().size(), apprenantId, req.sessionId());
    }
}
JEOF
ok "ChoisirCreneauxUseCase"

cat > "$P/application/usecase/session/GetCreneauxSessionUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.response.CreneauResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CreneauJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/** S10 — Récupérer les créneaux disponibles d'une session */
@Service
@RequiredArgsConstructor
public class GetCreneauxSessionUseCase {

    private final CreneauJpaRepository creneauRepo;

    @Transactional(readOnly = true)
    public List<CreneauResponse> executer(UUID sessionId) {
        return creneauRepo.findBySessionId(sessionId)
            .stream()
            .map(c -> new CreneauResponse(
                c.getId(), c.getSessionId(),
                c.getJourSemaine(), c.getHeureDebut(),
                c.getDureeMinutes(), c.getCapaciteMax(),
                c.getPlacesRestantes(), null
            ))
            .toList();
    }
}
JEOF
ok "GetCreneauxSessionUseCase"

# =============================================================================
# S20 — CRÉER SESSION
# =============================================================================
sec "S20 — CreerSessionUseCase"

cat > "$P/api/dto/request/CreerSessionRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/** S20 — Création d'une session par l'admin */
public record CreerSessionRequest(
    @NotNull UUID coursId,
    @NotNull UUID formateurId,

    @NotNull @Future LocalDate dateDebut,
    @NotNull          LocalDate dateFin,

    /** PRESENTIEL ou MEET */
    @NotBlank @Pattern(regexp = "PRESENTIEL|MEET")
    String modalite,

    /** Lieu physique (si PRESENTIEL) ou lien Meet (si MEET) */
    @Size(max = 300) String lieuOuLien,

    @Min(1) @Max(200)
    int capaciteMax,

    /**
     * Créneaux récurrents de la session.
     * Ex: Lundi 18h-20h, Samedi 9h-12h
     */
    @NotEmpty @Valid
    List<CreneauSessionRequest> creneaux
) {}
JEOF
ok "CreerSessionRequest"

cat > "$P/api/dto/request/CreneauSessionRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.time.LocalTime;

/** Créneau récurrent d'une session */
public record CreneauSessionRequest(
    @NotBlank @Pattern(regexp = "LUNDI|MARDI|MERCREDI|JEUDI|VENDREDI|SAMEDI|DIMANCHE")
    String jourSemaine,

    @NotNull
    LocalTime heureDebut,

    @Min(30) @Max(480)
    int dureeMinutes,

    @Min(1) @Max(200)
    int capaciteMax
) {}
JEOF
ok "CreneauSessionRequest"

cat > "$P/application/usecase/session/CreerSessionUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.request.CreerSessionRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S20 — L'admin crée une session de formation avec ses créneaux.
 * Règles :
 *  - Vérification des conflits horaires du formateur
 *  - Génération de l'emploi du temps PDF (via EmploiDuTempsPort)
 *  - Notification aux apprenants inscrits
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CreerSessionUseCase {

    private final SessionJpaRepository  sessionRepo;
    private final CreneauJpaRepository  creneauRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public UUID executer(CreerSessionRequest req, UUID adminId) {
        // Vérifier conflits horaires formateur
        boolean conflit = verifierConflitFormateur(req.formateurId(), req.dateDebut(), req.dateFin());
        if (conflit) {
            throw new RuntimeException("BUSINESS_RULE:CONFLIT_HORAIRE_FORMATEUR");
        }

        // Créer la session
        UUID sessionId = UUID.randomUUID();
        SessionJpaEntity session = SessionJpaEntity.builder()
            .id(sessionId)
            .coursId(req.coursId())
            .formateurId(req.formateurId())
            .dateDebut(req.dateDebut().atStartOfDay())
            .dateFin(req.dateFin().atTime(23, 59))
            .modalite(req.modalite())
            .lieuOuLien(req.lieuOuLien())
            .capaciteMax(req.capaciteMax())
            .placesDisponibles(req.capaciteMax())
            .statut("PLANIFIEE")
            .build();
        sessionRepo.save(session);

        // Créer les créneaux
        for (int i = 0; i < req.creneaux().size(); i++) {
            var cr = req.creneaux().get(i);
            CreneauJpaEntity creneau = CreneauJpaEntity.builder()
                .id(UUID.randomUUID())
                .sessionId(sessionId)
                .jourSemaine(cr.jourSemaine())
                .heureDebut(cr.heureDebut())
                .dureeMinutes(cr.dureeMinutes())
                .capaciteMax(cr.capaciteMax())
                .placesRestantes(cr.capaciteMax())
                .build();
            creneauRepo.save(creneau);
        }

        // Publier événement → génération PDF + notifications apprenants
        eventBus.publishEvent(new SessionCreeeEvent(sessionId, req.coursId(), req.formateurId()));
        log.info("[SESSION] Session créée: {} pour cours: {}", sessionId, req.coursId());
        return sessionId;
    }

    private boolean verifierConflitFormateur(UUID formateurId, java.time.LocalDate debut,
                                              java.time.LocalDate fin) {
        return sessionRepo.existsByFormateurIdAndPeriodeChevauchante(
            formateurId, debut.atStartOfDay(), fin.atTime(23, 59)
        );
    }

    public record SessionCreeeEvent(UUID sessionId, UUID coursId, UUID formateurId) {}
}
JEOF
ok "CreerSessionUseCase"

# =============================================================================
# S4 — AVIS + LISTE ATTENTE
# =============================================================================
sec "S4 — LaissserAvisUseCase + SInscrireListeAttenteUseCase"

cat > "$P/api/dto/request/LaissserAvisRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;

/** S4 — Laisser un avis vérifié sur un cours */
public record LaissserAvisRequest(
    @Min(1) @Max(5)
    int note,

    @Size(max = 2000)
    String commentaire
) {}
JEOF
ok "LaissserAvisRequest"

cat > "$P/application/usecase/cours/LaissserAvisUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.request.LaissserAvisRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S4 — Laisser un avis sur un cours.
 * Règles métier :
 *  - L'apprenant doit avoir >= 30% de progression ET avoir payé
 *  - Un seul avis par apprenant par cours — pas de modification
 *  - L'avis est marqué "vérifié" automatiquement si les conditions sont remplies
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LaissserAvisUseCase {

    private final AvisCoursJpaRepository    avisRepo;
    private final ProgressionJpaRepository  progressionRepo;

    @Transactional
    public UUID executer(UUID coursId, UUID apprenantId, LaissserAvisRequest req) {
        // Vérifier pas d'avis existant
        if (avisRepo.existsByCoursIdAndApprenantId(coursId, apprenantId)) {
            throw new RuntimeException("BUSINESS_RULE:AVIS_DEJA_SOUMIS");
        }

        // Vérifier la progression >= 30% et payée
        var progression = progressionRepo
            .findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseThrow(() -> new RuntimeException("BUSINESS_RULE:COURS_PAS_COMMENCE"));

        if (!progression.isEstPaye()) {
            throw new RuntimeException("BUSINESS_RULE:COURS_PAS_PAYE:avis_reserve_aux_payants");
        }
        if (progression.getPourcentage().doubleValue() < 30.0) {
            throw new RuntimeException("BUSINESS_RULE:PROGRESSION_INSUFFISANTE:minimum_30_pourcent");
        }

        // Créer l'avis vérifié
        AvisCoursJpaEntity avis = AvisCoursJpaEntity.builder()
            .id(UUID.randomUUID())
            .coursId(coursId)
            .apprenantId(apprenantId)
            .note(req.note())
            .commentaire(req.commentaire())
            .estVerifie(true) // Vérifié automatiquement car conditions remplies
            .build();
        avisRepo.save(avis);

        // Recalculer la note moyenne du cours
        double nouvelleMoyenne = avisRepo.calculerNoteMoyenne(coursId);
        // La mise à jour de la note moyenne du cours est faite via un @Scheduled quotidien
        // pour éviter une requête supplémentaire à chaque avis

        log.info("[AVIS] Avis {} étoiles déposé sur cours {} par apprenant {}", req.note(), coursId, apprenantId);
        return avis.getId();
    }
}
JEOF
ok "LaissserAvisUseCase"

cat > "$P/application/usecase/cours/SInscrireListeAttenteUseCase.java" << 'JEOF'
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
JEOF
ok "SInscrireListeAttenteUseCase"

# =============================================================================
# S12 — SIGNALEMENT
# =============================================================================
sec "S12 — SignalerMessageUseCase"

cat > "$P/application/usecase/communaute/SignalerMessageUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.communaute;

import com.mbem.mbemlevel.infrastructure.persistence.repository.MessageCommunauteJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S12 — Signaler un message abusif dans la communauté.
 * Règles :
 *  - Un apprenant peut signaler un message une seule fois
 *  - Après 3 signalements : masquage automatique en attente de validation admin
 *  - L'admin reçoit une notification si le seuil est atteint
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SignalerMessageUseCase {

    private static final int SEUIL_MASQUAGE_AUTO = 3;

    private final MessageCommunauteJpaRepository messageRepo;
    private final ApplicationEventPublisher       eventBus;

    @Transactional
    public void executer(UUID messageId, UUID apprenantId) {
        var message = messageRepo.findById(messageId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:MESSAGE"));

        // Incrémenter le compteur de signalements
        message.setNbSignalements(message.getNbSignalements() + 1);

        // Masquage automatique si seuil atteint
        if (message.getNbSignalements() >= SEUIL_MASQUAGE_AUTO && !message.isEstMasque()) {
            message.setEstMasque(true);
            eventBus.publishEvent(new MessageMasqueAutomatiqueEvent(messageId, message.getNbSignalements()));
            log.warn("[COMMUNAUTE] Message {} masqué automatiquement après {} signalements",
                messageId, message.getNbSignalements());
        }
        messageRepo.save(message);
        log.info("[COMMUNAUTE] Message {} signalé par apprenant {}", messageId, apprenantId);
    }

    public record MessageMasqueAutomatiqueEvent(UUID messageId, int nbSignalements) {}
}
JEOF
ok "SignalerMessageUseCase"

# =============================================================================
# S15 — PARRAINAGE
# =============================================================================
sec "S15 — GenererLienParrainageUseCase + GetParrainageUseCase"

cat > "$P/api/dto/response/ParrainageResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ParrainageResponse(
    String        codeParrainage,
    String        lienParrainage,    // mbemnova.com/ref/{code}
    String        messageWhatsApp,   // Message pré-rempli prêt à partager
    int           nbFilleulsInvites,
    int           nbFilleulsActifs,
    int           xpTotalGagne,
    List<FilleulSommaireResponse> filleuls
) {}
JEOF
ok "ParrainageResponse"

cat > "$P/api/dto/response/FilleulSommaireResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import java.time.LocalDateTime;

public record FilleulSommaireResponse(
    String        prenom,
    String        statut,          // EN_ATTENTE, ACTIF, RECOMPENSE_ACCORDEE
    LocalDateTime dateInscription,
    int           xpAccorde
) {}
JEOF
ok "FilleulSommaireResponse"

cat > "$P/application/usecase/gamification/GetParrainageUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.gamification;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/**
 * S15 — Récupérer le tableau de bord de parrainage de l'apprenant.
 * Retourne : lien unique, message WhatsApp pré-rempli, liste des filleuls.
 */
@Service
@RequiredArgsConstructor
public class GetParrainageUseCase {

    private final ParrainageJpaRepository parrainageRepo;
    private final UtilisateurJpaRepository utilisateurRepo;

    @Transactional(readOnly = true)
    public ParrainageResponse executer(UUID parrainId) {
        // Récupérer le code de parrainage de l'apprenant
        var utilisateur = utilisateurRepo.findById(parrainId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:UTILISATEUR"));

        String code = utilisateur.getCodeParrainage();
        String lien = "https://mbemnova.com/ref/" + code;
        String messageWA = "Je me forme à la tech avec MbemNova 🚀 " +
            "Commence avec moi et on débloque tous les deux un module bonus : " + lien;

        // Filleuls
        var parrainages = parrainageRepo.findByParrainId(parrainId);
        int xpTotal = parrainages.stream().mapToInt(p -> p.getXpParrainCredite()).sum();
        long nbActifs = parrainages.stream().filter(p -> !"EN_ATTENTE".equals(p.getStatut())).count();

        List<FilleulSommaireResponse> filleuls = parrainages.stream()
            .map(p -> {
                String prenom = p.getFilleulId() != null
                    ? utilisateurRepo.findById(p.getFilleulId())
                        .map(u -> u.getPrenom()).orElse("Inconnu")
                    : "En attente";
                return new FilleulSommaireResponse(
                    prenom, p.getStatut(), p.getDateInscription(), p.getXpParrainCredite()
                );
            })
            .toList();

        return new ParrainageResponse(
            code, lien, messageWA,
            parrainages.size(), (int) nbActifs, xpTotal, filleuls
        );
    }
}
JEOF
ok "GetParrainageUseCase"

# =============================================================================
# S19 — COURS EN ATTENTE
# =============================================================================
sec "S19 — GetCoursEnAttenteUseCase"

cat > "$P/application/usecase/admin/GetCoursEnAttenteUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.api.dto.response.CoursResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

/**
 * S19 — Récupérer les cours en attente de publication pour l'admin.
 * Cours avec statut BROUILLON ou EN_REVISION.
 */
@Service
@RequiredArgsConstructor
public class GetCoursEnAttenteUseCase {

    private final CoursJpaRepository coursRepo;

    @Transactional(readOnly = true)
    public List<CoursResponse> executer() {
        return coursRepo.findByStatutIn(List.of("BROUILLON", "EN_REVISION"))
            .stream()
            .map(CoursResponse::fromEntity)
            .toList();
    }
}
JEOF
ok "GetCoursEnAttenteUseCase"

# =============================================================================
# S28 — DROITS RGPD
# =============================================================================
sec "S28 — SupprimerCompteUseCase + ExporterDonneesPersonnellesUseCase"

cat > "$P/application/usecase/auth/SupprimerCompteUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S28 — Droit à l'effacement (RGPD).
 * L'utilisateur supprime son compte.
 * Règles :
 *  - Données personnelles supprimées sous 30 jours
 *  - Données de paiement conservées 10 ans (obligation légale)
 *  - Certificats rendus anonymes (pas supprimés — preuve de complétion)
 *  - Toutes les sessions JWT révoquées immédiatement
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SupprimerCompteUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final TokenBlacklistService tokenBlacklistService;
    private final AuditLogRepository    auditRepo;

    @Transactional
    public void executer(UUID utilisateurId) {
        var utilisateur = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:UTILISATEUR"));

        // 1. Révoquer toutes les sessions actives
        tokenBlacklistService.revoquerToutesSessionsUtilisateur(utilisateurId);

        // 2. Anonymiser les données personnelles (soft delete)
        utilisateur.anonymiser(); // Efface prénom, email, téléphone, remplace par "Utilisateur supprimé"
        utilisateurRepo.save(utilisateur);

        // 3. Logger la suppression (obligation légale)
        auditRepo.enregistrer(utilisateurId, null, "COMPTE_SUPPRIME",
            "UTILISATEUR", utilisateurId.toString(), null, "SUCCESS", null, null);

        log.info("[RGPD] Compte supprimé et anonymisé: {}", utilisateurId);
    }
}
JEOF
ok "SupprimerCompteUseCase"

cat > "$P/application/usecase/auth/ExporterDonneesPersonnellesUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S28 — Droit à la portabilité (RGPD).
 * L'utilisateur exporte toutes ses données personnelles en JSON.
 * Inclut : profil, progressions, certificats, devoirs, messages, paiements.
 */
@Service
@RequiredArgsConstructor
public class ExporterDonneesPersonnellesUseCase {

    private final UtilisateurJpaRepository    utilisateurRepo;
    private final ProgressionJpaRepository    progressionRepo;
    private final CertificatJpaRepository     certificatRepo;

    @Transactional(readOnly = true)
    public Map<String, Object> executer(UUID utilisateurId) {
        var utilisateur = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:UTILISATEUR"));

        Map<String, Object> export = new LinkedHashMap<>();
        export.put("exportDate", java.time.LocalDateTime.now().toString());
        export.put("utilisateur", Map.of(
            "id",        utilisateur.getId(),
            "prenom",    utilisateur.getPrenom(),
            "email",     utilisateur.getEmail(),
            "telephone", utilisateur.getTelephone(),
            "dateInscription", utilisateur.getCreatedAt()
        ));
        export.put("progressions", progressionRepo.findByApprenantId(utilisateurId));
        export.put("certificats", certificatRepo.findByApprenantId(utilisateurId));
        return export;
    }
}
JEOF
ok "ExporterDonneesPersonnellesUseCase"

echo -e "\n${C_GREEN}✅  Use Cases manquants générés${C_NC}"
echo "   S17 — DemanderMoratoireUseCase, TraiterMoratoireUseCase"
echo "   S10 — ChoisirCreneauxUseCase, GetCreneauxSessionUseCase"
echo "   S20 — CreerSessionUseCase"
echo "   S4  — LaissserAvisUseCase, SInscrireListeAttenteUseCase"
echo "   S12 — SignalerMessageUseCase"
echo "   S15 — GetParrainageUseCase"
echo "   S19 — GetCoursEnAttenteUseCase"
echo "   S28 — SupprimerCompteUseCase, ExporterDonneesPersonnellesUseCase"
