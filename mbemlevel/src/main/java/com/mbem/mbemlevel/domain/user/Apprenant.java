// MbemNova — domain/user/Apprenant.java
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Extension de {@link Utilisateur} avec les données spécifiques
 * à un apprenant : XP, streak, rang, profil talent.
 */
public class Apprenant extends Utilisateur {

    private int xpTotal;
    private int streakJours;
    private Integer rangPlateforme;
    private boolean disponiblePourEmploi;

    /** Constructeur de reconstitution JPA. */
    public Apprenant(UUID id, String prenom, String nom, String email,
                     String motDePasseHache, StatutApprenant statut,
                     int tentativesEchouees, LocalDateTime bloqueJusquAu,
                     LocalDateTime derniereConnexion, boolean emailVerifie,
                     String tokenVerif, LocalDateTime tokenVerificationEmailExpireAt, String telephone,
                     LocalDateTime createdAt, LocalDateTime updatedAt,
                     int xpTotal, int streakJours, Integer rangPlateforme,
                     boolean disponiblePourEmploi) {
        super(id, prenom, nom, email, motDePasseHache, Role.APPRENANT, statut,
              tentativesEchouees, bloqueJusquAu, derniereConnexion, emailVerifie,
              tokenVerif, tokenVerificationEmailExpireAt, telephone, createdAt, updatedAt);
        this.xpTotal              = xpTotal;
        this.streakJours          = streakJours;
        this.rangPlateforme       = rangPlateforme;
        this.disponiblePourEmploi = disponiblePourEmploi;
    }

    /** Ajoute des XP et met à jour le streak. */
    public void ajouterXP(int xp) {
        if (xp < 0) throw new IllegalArgumentException("XP ne peut pas être négatif");
        this.xpTotal += xp;
        markUpdated();
    }

    public void incrementerStreak() { this.streakJours++; markUpdated(); }
    public void resetStreak()       { this.streakJours = 0; markUpdated(); }

    public void setDisponible(boolean disponible) {
        this.disponiblePourEmploi = disponible;
        markUpdated();
    }

    public int     getXpTotal()              { return xpTotal; }
    public int     getStreakJours()          { return streakJours; }
    public Integer getRangPlateforme()       { return rangPlateforme; }
    public boolean isDisponiblePourEmploi()  { return disponiblePourEmploi; }
}
