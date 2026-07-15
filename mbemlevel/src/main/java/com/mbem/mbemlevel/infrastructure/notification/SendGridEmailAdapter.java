// =============================================================================
// MbemNova — com.mbem.mbemlevel.infrastructure.notification.SendGridEmailAdapter
// @Component — implémente EmailPort via SMTP/SendGrid
// TODO: Implémenté par script 0X/15
// =============================================================================
package com.mbem.mbemlevel.infrastructure.notification;

import org.springframework.stereotype.Component;

import com.mbem.mbemlevel.application.port.out.EmailPort;

import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class SendGridEmailAdapter implements EmailPort {
    // TODO
  @Override
    public void envoyerBienvenue(String email, String prenom) {
        log.info("Email bienvenue à {}: {}", email, prenom);
    }
    @Override
    public void envoyerVerificationEmail(String email, String prenom, String lienVerification) {
        log.info("Email vérification à {}: {} - lien: {}", email, prenom, lienVerification);
    }

    @Override
    public void envoyerRappel48h(String email, String prenom) {
        log.info("Email rappel 48h à {}: {}", email, prenom);
    }

    @Override
    public void envoyerResetMotDePasse(String email, String prenom, String lienReset) {
        log.info("Email reset MDP à {}: {} - lien: {}", email, prenom, lienReset);
    }

    @Override
    public void envoyerAlerteTentativesSuspectes(String email, String prenom, int nbTentatives, String ip) {
        log.info("Email alerte sécurite à {}: {} - {} tentatives depuis {}", email, prenom, nbTentatives, ip);
    }

    @Override
    public void envoyerNurturingSeuilAtteint(String email, String prenom, String nomCours) {
        log.info("Email nurturing seuil à {}: {} - cours: {}", email, prenom, nomCours);
    }

    @Override
    public void envoyerActivationAcces(String email, String prenom, String nomCours, String lienFacturePdf) {
        log.info("Email activation accès à {}: {} - cours: {}", email, prenom, nomCours);
    }

    @Override
    public void envoyerRelancePaiement(String email, String prenom, String nomCours, int joursAvantEcheance) {
        log.info("Email relance paiement à {}: {} - cours: {} - J{}", email, prenom, nomCours, joursAvantEcheance);
    }

    @Override
    public void envoyerSuspension(String email, String prenom, String messageAdmin) {
        log.info("Email suspension à {}: {} - message: {}", email, prenom, messageAdmin);
    }

    @Override
    public void envoyerReactivation(String email, String prenom, String nomCours) {
        log.info("Email réactivation à {}: {} - cours: {}", email, prenom, nomCours);
    }

    @Override
    public void envoyerCertificatObtenu(String email, String prenom, String nomCours, String lienCertificatPdf, String codeVerification) {
        log.info("Email certificat à {}: {} - cours: {}", email, prenom, nomCours);
    }

    @Override
    public void envoyerNouveauDevoir(String email, String prenom, String nomDevoir, String dateRemise) {
        log.info("Email nouveau devoir à {}: {} - devoir: {}", email, prenom, nomDevoir);
    }

    @Override
    public void envoyerRenduCorrige(String email, String prenom, String nomDevoir, int note, String commentaire) {
        log.info("Email rendu corrigé à {}: {} - devoir: {} - note: {}", email, prenom, nomDevoir, note);
    }

    @Override
    public void envoyerGagnantTirage(String email, String prenom, String prix) {
        log.info("Email gagnant tirage à {}: {} - prix: {}", email, prenom, prix);
    }

    @Override
    public void envoyerRecomparainageActive(String emailParrain, String prenomParrain, String prenomFilleul) {
        log.info("Email parrainage à {}: {} - filleul: {}", emailParrain, prenomParrain, prenomFilleul);
    }

    @Override
    public void envoyerMoratoireApprouve(String email, String prenom, String nomCours, String nouvelleDate) {
        log.info("Email moratoire approuvé à {}: {} - cours: {} - nouvelle date: {}", email, prenom, nomCours, nouvelleDate);
    }

    @Override
    public void envoyerMoratoireRefuse(String email, String prenom, String nomCours, String justification) {
        log.info("Email moratoire refusé à {}: {} - cours: {} - justification: {}", email, prenom, nomCours, justification);
    }
}
