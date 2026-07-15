package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import java.util.List;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfilTalentResponse(
    UUID id, String prenom, String nom, String telephone,
    boolean disponiblePourEmploi,
    String lienPortfolio, String lienLinkedin, String lienGithub, String lienCv,
    String bio, int xpTotal, int streakJours,
    List<CertificatResponse> certificats,
    List<Integer> xpParJour
) {
    public static ProfilTalentResponse from(Utilisateur u, List<CertificatResponse> certs, List<Integer> xpParJour) {
        int xp = 0;
        int streak = 0;
        boolean dispos = false;
        if (u instanceof com.mbem.mbemlevel.domain.user.Apprenant app) {
            xp = app.getXpTotal();
            streak = app.getStreakJours();
            dispos = app.isDisponiblePourEmploi();
        }
        return new ProfilTalentResponse(u.getId(), u.getPrenom(), u.getNom(),
            u.getTelephone(), dispos,
            null, null, null, null,
            null, xp, streak, certs, xpParJour);
    }

    public static ProfilTalentResponse from(Utilisateur u, List<CertificatResponse> certs) {
        return from(u, certs, null);
    }
}
