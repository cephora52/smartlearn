package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S14 — Apprenant met à jour son profil talent (vitrine recruteurs).
 * Champs : ville, bio, liens portfolio/CV/LinkedIn/GitHub, disponibilité emploi.
 */
@Service @RequiredArgsConstructor
public class MettreAJourProfilUseCase {
    private final UtilisateurRepository repo;
    public record Commande(UUID userId, String prenom, String nom, String telephone,
                            boolean disponiblePourEmploi) {}
    @Transactional
    public Utilisateur executer(Commande cmd) {
        Utilisateur u = repo.findById(cmd.userId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        u.mettreAJourProfil(cmd.prenom(), cmd.nom(), cmd.telephone());
        return repo.save(u);
    }
}
