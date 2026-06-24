package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
/** S14 — Récupère le profil public (talent) d'un apprenant avec ses certificats. */
@Service @RequiredArgsConstructor
public class GetProfilTalentUseCase {
    private final UtilisateurRepository  utilisateurRepo;
    private final CertificatRepository   certificatRepo;
    public record ProfilAvecCertificats(Utilisateur utilisateur, List<Certificat> certificats) {}
    @Transactional(readOnly=true)
    public ProfilAvecCertificats executer(UUID apprenantId) {
        Utilisateur u = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        List<Certificat> certs = certificatRepo.findByApprenant(apprenantId);
        return new ProfilAvecCertificats(u, certs);
    }
}
