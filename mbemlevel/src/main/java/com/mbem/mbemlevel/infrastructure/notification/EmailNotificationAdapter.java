package com.mbem.mbemlevel.infrastructure.notification;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import java.util.Map;
/**
 * Adaptateur email via SMTP (SendGrid en production, MailHog en dev).
 * Tous les envois sont asynchrones (@Async) pour ne pas bloquer les requêtes HTTP.
 */
@Component @Primary @RequiredArgsConstructor @Slf4j
public class EmailNotificationAdapter implements EmailPort {
    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;
    private static final String FROM = "noreply@mbemnova.com";

    private void envoyerHtml(String to, String subject, String template,
                              Map<String, Object> vars) {
        try {
            Context ctx = new Context(); ctx.setVariables(vars);
            String html = templateEngine.process(template, ctx);
            var msg = mailSender.createMimeMessage();
            var helper = new MimeMessageHelper(msg, true, "UTF-8");
            helper.setFrom(FROM, "MbemNova"); helper.setTo(to);
            helper.setSubject(subject); helper.setText(html, true);
            mailSender.send(msg);
            log.debug("[EMAIL] Envoyé: template={} to={}", template, to);
        } catch (Exception e) {
            log.error("[EMAIL] Erreur envoi {} vers {}: {}", template, to, e.getMessage());
        }
    }

    @Override @Async public void envoyerBienvenue(String email, String prenom) {
        envoyerHtml(email, "Bienvenue sur MbemNova !", "bienvenue",
            Map.of("prenom", prenom)); }
    @Override @Async public void envoyerVerificationEmail(String email, String prenom, String lienVerification) {
        envoyerHtml(email, "Vérification de ton adresse email", "verification-email",
            Map.of("prenom", prenom, "lienVerification", lienVerification)); }
    @Override @Async public void envoyerRappel48h(String email, String prenom) {
        envoyerHtml(email, "Tu n'as pas encore commencé...", "rappel-48h",
            Map.of("prenom", prenom)); }
    @Override @Async public void envoyerResetMotDePasse(String email, String prenom, String lien) {
        envoyerHtml(email, "Réinitialisation de ton mot de passe", "reset-mdp",
            Map.of("prenom", prenom, "lien", lien, "ttlMinutes", 60)); }
    @Override @Async public void envoyerAlerteTentativesSuspectes(String email, String prenom, int nb, String ip) {
        envoyerHtml(email, "Activité suspecte sur ton compte", "alerte-securite",
            Map.of("prenom", prenom, "nbTentatives", nb, "ip", ip)); }
    @Override @Async public void envoyerNurturingSeuilAtteint(String email, String prenom, String cours) {
        envoyerHtml(email, "Tu progresses vite ! Continue...", "seuil-paiement",
            Map.of("prenom", prenom, "nomCours", cours)); }
    @Override @Async public void envoyerActivationAcces(String email, String prenom, String cours, String facture) {
        envoyerHtml(email, "Accès complet activé — " + cours, "activation-acces",
            Map.of("prenom", prenom, "nomCours", cours,
                   "lienFacture", facture != null ? facture : "")); }
    @Override @Async public void envoyerRelancePaiement(String email, String prenom, String cours, int jours) {
        String template = jours > 0 ? "relance-j7" : "relance-retard";
        envoyerHtml(email, "Rappel paiement — " + cours, template,
            Map.of("prenom", prenom, "nomCours", cours, "joursAvantEcheance", jours)); }
    @Override @Async public void envoyerSuspension(String email, String prenom, String msg) {
        envoyerHtml(email, "Accès temporairement suspendu", "suspension",
            Map.of("prenom", prenom, "messageAdmin", msg)); }
    @Override @Async public void envoyerReactivation(String email, String prenom, String cours) {
        envoyerHtml(email, "Ton accès est rétabli !", "reactivation",
            Map.of("prenom", prenom, "nomCours", cours)); }
    @Override @Async public void envoyerCertificatObtenu(String email, String prenom,
            String cours, String pdf, String code) {
        envoyerHtml(email, "Félicitations ! Ton certificat " + cours, "certificat-obtenu",
            Map.of("prenom", prenom, "nomCours", cours,
                   "codeVerif", code, "lienPdf", pdf != null ? pdf : "")); }
    @Override @Async public void envoyerNouveauDevoir(String email, String prenom, String nom, String date) {
        envoyerHtml(email, "Nouveau devoir : " + nom, "nouveau-devoir",
            Map.of("prenom", prenom, "nomDevoir", nom, "dateRemise", date)); }
    @Override @Async public void envoyerRenduCorrige(String email, String prenom, String nom, int note, String cmt) {
        envoyerHtml(email, "Ton devoir a été corrigé — Note : " + note + "/20", "devoir-corrige",
            Map.of("prenom", prenom, "nomDevoir", nom, "note", note, "commentaire", cmt)); }
    @Override @Async public void envoyerGagnantTirage(String email, String prenom, String prix) {
        envoyerHtml(email, "Tu as gagné le tirage du mois !", "tirage-gagnant",
            Map.of("prenom", prenom, "prix", prix)); }
    @Override @Async public void envoyerRecomparainageActive(String emailParrain, String prenomParrain, String prenomFilleul) {
        envoyerHtml(emailParrain, "Ton filleul vient de commencer sa formation !", "parrainage-active",
            Map.of("prenomParrain", prenomParrain, "prenomFilleul", prenomFilleul)); }
}
