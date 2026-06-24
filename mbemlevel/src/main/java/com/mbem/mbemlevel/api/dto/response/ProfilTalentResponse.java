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
    List<CertificatResponse> certificats
) {
    public static ProfilTalentResponse from(Utilisateur u, List<CertificatResponse> certs) {
        return new ProfilTalentResponse(u.getId(), u.getPrenom(), u.getNom(),
            u.getTelephone(), false,
            null, null, null, null,
            null, 0, 0, certs);
    }
}
