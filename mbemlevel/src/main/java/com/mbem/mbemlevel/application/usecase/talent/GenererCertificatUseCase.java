package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.certificat.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S13 — Génère et émet un certificat après validation complète du cours.
 * Règle : cours payé + 100% de progression.
 */
@Service @RequiredArgsConstructor @Slf4j
public class GenererCertificatUseCase {
    private final CertificatRepository   certificatRepo;
    private final ProgressionRepository  progressionRepo;
    private final UtilisateurRepository  utilisateurRepo;
    private final CoursRepository        coursRepo;
    private final AuditLogRepository     auditRepo;
    private final ApplicationEventPublisher publisher;
    private final CertificatDomainService domainService;

    @Transactional
    public Certificat executer(UUID apprenantId, UUID coursId) {
        // Vérifier si déjà généré
        if (certificatRepo.findByApprenantAndCours(apprenantId, coursId).isPresent()) {
            return certificatRepo.findByApprenantAndCours(apprenantId, coursId).get();
        }
        var cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        Progression prog = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        
        boolean canGetCert = domainService.peutObtenirCertificat(prog) || (cours.getPrixFcfa() == 0 && prog.estTermine());
        if (!canGetCert)
            throw new RuntimeException("CERTIFICATE_CONDITIONS_NOT_MET");

        Utilisateur user = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));

        Certificat cert = Certificat.emettre(apprenantId, coursId,
            user.getPrenom(), user.getEmail(),
            user.getTelephone(), cours.getTitre());
        Certificat saved = certificatRepo.save(cert);

        // Publier → email félicitations + WhatsApp + profil talent mis à jour
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();

        auditRepo.enregistrer(apprenantId, user.getEmail(), "CERTIFICAT_EMIS",
            "CERTIFICAT", saved.getId().toString(), null, "SUCCESS", null, null);
        log.info("[CERT] Certificat émis: apprenant={} cours={}", apprenantId, coursId);
        return saved;
    }
}
