// =============================================================================
// MbemNova — application/port/out/EmailPort.java
// Port sortant pour l'envoi d'emails via le provider SMTP externe.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

/**
 * Port sortant — envoi d'emails.
 * Implémenté par SendGridEmailAdapter (infrastructure).
 *
 * <h3>Templates Thymeleaf correspondants</h3>
 * <ul>
 *   <li>bienvenue.html</li>
 *   <li>rappel-48h.html</li>
 *   <li>reset-mdp.html</li>
 *   <li>alerte-securite.html</li>
 *   <li>suspension.html · reactivation.html</li>
 *   <li>seuil-paiement.html · activation-acces.html</li>
 *   <li>facture.html · certificat-obtenu.html</li>
 *   <li>relance-j7.html · relance-j3.html · relance-retard.html</li>
 *   <li>nouveau-devoir.html · devoir-corrige.html</li>
 *   <li>tirage-gagnant.html · parrainage-active.html</li>
 * </ul>
 */
public interface EmailPort {

    // ── Auth ──────────────────────────────────────────────────────────────────

    /** Email de bienvenue après inscription — envoyé dans les 30 secondes. */
    void envoyerBienvenue(String email, String prenom);
    /** Email de vérification de compte avec lien signé par token. */
    void envoyerVerificationEmail(String email, String prenom, String lienVerification);

    /** Rappel 48h si aucun cours commencé depuis l'inscription. 
     * @param string */
    void envoyerRappel48h(String email, String prenom);

    /**
     * Lien de réinitialisation de mot de passe.
     * Le lien contient le token brut — expire en 1 heure.
     */
    void envoyerResetMotDePasse(String email, String prenom, String lienReset);

    /**
     * Alerte de tentatives de connexion suspectes.
     * Envoyé après N échecs consécutifs (configurable).
     */
    void envoyerAlerteTentativesSuspectes(String email, String prenom,
                                          int nbTentatives, String ip);

    // ── Paiement ─────────────────────────────────────────────────────────────

    /** Email nurturing après atteinte du seuil de conversion (scénario 07). */
    void envoyerNurturingSeuilAtteint(String email, String prenom, String nomCours);

    /** Confirmation d'activation de l'accès complet après paiement (scénario 08). */
    void envoyerActivationAcces(String email, String prenom,
                                String nomCours, String lienFacturePdf);

    /** Relance paiement — J-7, J-3, J0, J+3, J+7 (scénario 16). */
    void envoyerRelancePaiement(String email, String prenom,
                                String nomCours, int joursAvantEcheance);

    /** Email de suspension de compte (scénario 18). */
    void envoyerSuspension(String email, String prenom, String messageAdmin);

    /** Email de réactivation après régularisation. */
    void envoyerReactivation(String email, String prenom, String nomCours);

    // ── Certificat / Talent ───────────────────────────────────────────────────

    /** Félicitations + lien vers le certificat PDF (scénario 13). */
    void envoyerCertificatObtenu(String email, String prenom,
                                 String nomCours, String lienCertificatPdf,
                                 String codeVerification);

    // ── Session / Devoirs ────────────────────────────────────────────────────

    /** Notification d'un nouveau devoir disponible (scénario 11). */
    void envoyerNouveauDevoir(String email, String prenom,
                              String nomDevoir, String dateRemise);

    /** Notification de correction du rendu avec la note (scénario 23). */
    void envoyerRenduCorrige(String email, String prenom,
                             String nomDevoir, int note, String commentaire);

    // ── Gamification ─────────────────────────────────────────────────────────

    /** Félicitations au gagnant du tirage au sort mensuel (scénario 24). */
    void envoyerGagnantTirage(String email, String prenom, String prix);

    /** Récompense de parrainage activée (scénario 15). */
    void envoyerRecomparainageActive(String emailParrain, String prenomParrain,
                                     String prenomFilleul);
}
